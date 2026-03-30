import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';
import 'add_customer_screen.dart';

// ---------------------------------------------------------------------------
// State enum
// ---------------------------------------------------------------------------
enum _ScreenState { loading, loaded, error }

// ---------------------------------------------------------------------------
// Müşteri tipi yardımcıları
// ---------------------------------------------------------------------------
const _typeMap = {'Bireysel': 'regular', 'VIP': 'vip', 'Toptan': 'wholesale'};
const _typeFilters = ['Tümü', 'Bireysel', 'VIP', 'Toptan'];

String _typeLabel(String? t) => switch (t) {
      'vip' => 'VIP',
      'wholesale' => 'Toptan',
      _ => 'Bireysel',
    };

Color _typeColor(String? t) => switch (t) {
      'vip' => AppColors.warning,
      'wholesale' => AppColors.primary,
      _ => AppColors.textSecondary,
    };

// ===========================================================================
// Screen
// ===========================================================================
class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() =>
      _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  // Controllers & timers
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  // Data
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  Set<String> _selected = {};

  // State
  _ScreenState _state = _ScreenState.loading;
  String _errorMsg = '';
  bool _selectionMode = false;

  // Stats (filtresiz, sabit tutulur)
  int _totalCount = 0;
  int _activeCount = 0;
  int _passiveCount = 0;
  int _corporateCount = 0;

  // Filters
  String _typeFilter = 'Tümü';
  String _cityFilter = 'Tümü';
  Set<String> _cities = {'Tümü'};

  // -------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Arama debounce (400 ms)
  // -------------------------------------------------------------------------
  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _applyFilter);
  }

  // -------------------------------------------------------------------------
  // Veri yükleme
  // -------------------------------------------------------------------------
  Future<void> _load() async {
    setState(() {
      _state = _ScreenState.loading;
      _errorMsg = '';
    });

    try {
      final list = await ref.read(customerServiceProvider).getCustomers();
      final cities = list
          .where((c) => (c['city']?.toString() ?? '').isNotEmpty)
          .map((c) => c['city'].toString())
          .toSet();

      if (!mounted) return;
      setState(() {
        _all = list;
        _cities = {'Tümü', ...cities};
        _state = _ScreenState.loaded;
        _applyFilterSync();
        // Stats: filtresiz yükleme olduğunda güncelle
        if (_typeFilter == 'Tümü' && _cityFilter == 'Tümü' && _searchCtrl.text.isEmpty) {
          _totalCount = list.length;
          _activeCount = list.where((c) => c['isActive'] == true).length;
          _passiveCount = _totalCount - _activeCount;
          _corporateCount = list.where((c) => c['customerType']?.toString() == 'CORPORATE').length;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScreenState.error;
        _errorMsg = e.toString();
      });
    }
  }

  void _applyFilter() {
    if (mounted) setState(_applyFilterSync);
  }

  void _applyFilterSync() {
    var f = _all;
    final q = _searchCtrl.text.trim().toLowerCase();

    if (q.isNotEmpty) {
      f = f.where((c) {
        return c['name'].toString().toLowerCase().contains(q) ||
            (c['phone']?.toString().toLowerCase() ?? '').contains(q) ||
            (c['email']?.toString().toLowerCase() ?? '').contains(q);
      }).toList();
    }

    if (_typeFilter != 'Tümü') {
      f = f.where((c) => c['customerType'] == _typeMap[_typeFilter]).toList();
    }

    if (_cityFilter != 'Tümü') {
      f = f.where((c) => c['city'] == _cityFilter).toList();
    }

    _filtered = f;
  }

  // -------------------------------------------------------------------------
  // Silme
  // -------------------------------------------------------------------------
  Future<void> _delete(Map<String, dynamic> customer) async {
    final confirmed = await AppConfirmationDialog.showDelete(
      context: context,
      title: 'Müşteriyi Sil',
      message: 'Bu işlem geri alınamaz. Satış kayıtları korunacaktır.',
      itemName: customer['name'] as String?,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref
          .read(customerServiceProvider)
          .deleteCustomer(customer['id']);
      AppToast.success(context, '${customer['name']} silindi');
      _load();
    } catch (e) {
      if (mounted) AppToast.error(context, 'Silinemedi: $e');
    }
  }

  Future<void> _bulkDelete() async {
    if (_selected.isEmpty) return;
    final confirmed = await AppConfirmationDialog.showDelete(
      context: context,
      title: 'Toplu Silme',
      message: '${_selected.length} müşteriyi silmek istediğinize emin misiniz?',
    );
    if (!confirmed || !mounted) return;

    try {
      final svc = ref.read(customerServiceProvider);
      for (final id in _selected) {
        await svc.deleteCustomer(id);
      }
      setState(() {
        _selected.clear();
        _selectionMode = false;
      });
      AppToast.success(context, '${_selected.length} müşteri silindi');
      _load();
    } catch (e) {
      if (mounted) AppToast.error(context, 'Hata: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Navigasyon — GoRouter
  // -------------------------------------------------------------------------
  Future<void> _openAdd() async {
    final result = await context.push<bool>('/customers/add');
    if (result == true) _load();
  }

  Future<void> _openEdit(Map<String, dynamic> customer) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddCustomerScreen(customer: customer),
      ),
    );
    if (result == true) _load();
  }

  // =========================================================================
  // Build
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAdd,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text(
                'Yeni Müşteri',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
    );
  }

  // -------------------------------------------------------------------------
  // AppBar
  // -------------------------------------------------------------------------
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      title: _selectionMode
          ? Text(
              '${_selected.length} seçili',
              style: const TextStyle(fontWeight: FontWeight.w600),
            )
          : const Text(
              'Müşteri Yönetimi',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
      actions: [
        if (_selectionMode) ...[
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _bulkDelete,
            tooltip: 'Seçilenleri Sil',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() {
              _selectionMode = false;
              _selected.clear();
            }),
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _load,
            tooltip: 'Yenile',
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Arama + Filtreler
  // -------------------------------------------------------------------------
  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Arama
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AppSearchInput(
              controller: _searchCtrl,
              hint: 'İsim, telefon veya e-posta ara...',
            ),
          ),

          // Filtre chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ..._typeFilters.map((t) => _filterChip(
                      label: t,
                      selected: _typeFilter == t,
                      color: AppColors.primary,
                      onTap: () {
                        setState(() => _typeFilter = t);
                        _applyFilter();
                      },
                    )),
                const SizedBox(width: 8),
                ..._cities.map((c) => _filterChip(
                      label: c,
                      selected: _cityFilter == c,
                      color: AppColors.info,
                      onTap: () {
                        setState(() => _cityFilter = c);
                        _applyFilter();
                      },
                    )),
              ],
            ),
          ),

          // İstatistik çubuğu (sadece yüklendiyse)
          if (_state == _ScreenState.loaded) _buildStatsRow(),

          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppConstants.animationFast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.12) : Colors.transparent,
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: AppConstants.borderRadiusFull,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final total = (_typeFilter == 'Tümü' && _cityFilter == 'Tümü' && _searchCtrl.text.isEmpty)
        ? _all.length
        : _totalCount;
    final active = (_typeFilter == 'Tümü' && _cityFilter == 'Tümü' && _searchCtrl.text.isEmpty)
        ? _all.where((c) => c['isActive'] == true).length
        : _activeCount;
    final passive = (_typeFilter == 'Tümü' && _cityFilter == 'Tümü' && _searchCtrl.text.isEmpty)
        ? _all.length - active
        : _passiveCount;
    final corporate = (_typeFilter == 'Tümü' && _cityFilter == 'Tümü' && _searchCtrl.text.isEmpty)
        ? _all.where((c) => c['customerType']?.toString() == 'CORPORATE').length
        : _corporateCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          _statPill('$total', 'Toplam', Icons.people_outline, AppColors.primary),
          const SizedBox(width: 10),
          _statPill('$active', 'Aktif', Icons.check_circle_outline, AppColors.success),
          const SizedBox(width: 10),
          _statPill('$passive', 'Pasif', Icons.cancel_outlined, AppColors.textMuted),
          const SizedBox(width: 10),
          _statPill('$corporate', 'Kurumsal', Icons.business_outlined, AppColors.info),
        ],
      ),
    );
  }

  Widget _statPill(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: AppConstants.borderRadiusSmall,
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Body
  // -------------------------------------------------------------------------
  Widget _buildBody() {
    return switch (_state) {
      _ScreenState.loading => _buildSkeleton(),
      _ScreenState.error => AppEmptyState.error(
          description: _errorMsg,
          onAction: _load,
        ),
      _ScreenState.loaded => _buildList(),
    };
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: AppSkeletonCard(),
      ),
    );
  }

  Widget _buildList() {
    if (_all.isEmpty) {
      return AppEmptyState.noData(
        title: 'Henüz müşteri yok',
        description: 'Başlamak için yeni bir müşteri ekleyin',
        actionText: 'Müşteri Ekle',
        onAction: _openAdd,
      );
    }

    if (_filtered.isEmpty) {
      return AppEmptyState.search(
        description: 'Farklı filtreler veya arama terimi deneyin',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _buildCustomerCard(_filtered[i]),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Müşteri kartı
  // -------------------------------------------------------------------------
  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final id = customer['id']?.toString() ?? '';
    final isSelected = _selected.contains(id);
    final type = customer['customerType'] as String?;
    final color = _typeColor(type);
    final label = _typeLabel(type);
    final points = customer['loyaltyPoints'] ?? 0;
    final total = customer['totalPurchases'] ?? 0;
    final name = customer['name']?.toString() ?? '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () {
          if (_selectionMode) {
            setState(() => isSelected ? _selected.remove(id) : _selected.add(id));
          } else {
            _openEdit(customer);
          }
        },
        onLongPress: () {
          setState(() {
            _selectionMode = true;
            _selected.add(id);
          });
        },
        borderColor: isSelected ? AppColors.primary : null,
        borderWidth: isSelected ? 2 : 1,
        child: Row(
          children: [
            // Seçim modu
            if (_selectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
              ),

            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withOpacity(0.12),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Bilgiler
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppBadge(text: label, color: color),
                    ],
                  ),
                  if (customer['phone'] != null) ...[
                    const SizedBox(height: 3),
                    _iconText(Icons.phone_outlined, customer['phone'].toString()),
                  ],
                  if ((customer['city']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    _iconText(Icons.location_on_outlined, customer['city'].toString()),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                      const SizedBox(width: 3),
                      Text(
                        '$points puan',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₺$total',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menü
            if (!_selectionMode)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: AppConstants.borderRadiusMedium,
                ),
                onSelected: (v) {
                  if (v == 'edit') _openEdit(customer);
                  if (v == 'delete') _delete(customer);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: _MenuRow(Icons.edit_outlined, 'Düzenle', AppColors.primary),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: _MenuRow(Icons.delete_outline, 'Sil', AppColors.danger),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// PopupMenu satır yardımcısı
// ---------------------------------------------------------------------------
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MenuRow(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
