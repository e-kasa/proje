import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';
import 'add_supplier_screen.dart';

enum _ScreenState { loading, loaded, error }

// ===========================================================================
// Screen
// ===========================================================================
class SupplierListScreen extends ConsumerStatefulWidget {
  const SupplierListScreen({super.key});

  @override
  ConsumerState<SupplierListScreen> createState() =>
      _SupplierListScreenState();
}

class _SupplierListScreenState extends ConsumerState<SupplierListScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  Set<String> _selected = {};

  _ScreenState _state = _ScreenState.loading;
  String _errorMsg = '';
  bool _selectionMode = false;
  String _statusFilter = 'Tümü';

  // Stats için tüm tedarikçilerin sayısı (filtresiz)
  int _totalCount = 0;
  int _activeCount = 0;
  int _passiveCount = 0;

  static const _statusFilters = ['Tümü', 'Aktif', 'Pasif'];

  // -------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    // addPostFrameCallback: widget ağacı kurulduktan sonra yükle
    // context.push() kullanılsa da ek güvence sağlar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch() {
    _debounce?.cancel();
    // Arama değişince backend'e yeni istek at (server-side search)
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  // -------------------------------------------------------------------------
  Future<void> _load() async {
    setState(() {
      _state = _ScreenState.loading;
      _errorMsg = '';
    });

    try {
      // Mevcut arama ve durum filtresini backend'e gönder
      final search = _searchCtrl.text.trim().isEmpty
          ? null
          : _searchCtrl.text.trim();
      final status = _statusFilter == 'Aktif'
          ? 'ACTIVE'
          : _statusFilter == 'Pasif'
              ? 'INACTIVE'
              : null;

      final list = await ref
          .read(supplierServiceProvider)
          .getSuppliers(search: search, status: status);

      if (!mounted) return;

      // Stats için filtresiz sayıları güncelle (sadece filtre yokken)
      setState(() {
        _all = list;
        _filtered = list; // Backend zaten filtreledi
        _state = _ScreenState.loaded;
        if (status == null && search == null) {
          _totalCount = list.length;
          _activeCount = list.where((s) => s['isActive'] == true).length;
          _passiveCount = _totalCount - _activeCount;
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

  // -------------------------------------------------------------------------
  Future<void> _toggleStatus(Map<String, dynamic> supplier) async {
    final isActive = supplier['isActive'] == true;
    final action = isActive ? 'Pasifleştir' : 'Aktifleştir';
    final actionColor = isActive ? AppColors.warning : AppColors.success;
    final actionIcon =
        isActive ? Icons.block_outlined : Icons.check_circle_outline;

    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: '$action: ${supplier['name'] ?? ''}',
      message: isActive
          ? 'Tedarikçi pasifleştirilecek. Kayıtlar korunur.'
          : 'Tedarikçi aktifleştirilecek. Yeniden sipariş verilebilir.',
      itemName: supplier['name'] as String?,
      icon: actionIcon,
      iconColor: actionColor,
      confirmText: action,
      confirmColor: actionColor,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref
          .read(supplierServiceProvider)
          .toggleStatus(supplier['id'].toString());
      final name = supplier['name'] ?? '';
      AppToast.success(
          context, '$name ${isActive ? 'pasifleştirildi' : 'aktifleştirildi'}');
      _load();
    } catch (e) {
      if (mounted) AppToast.error(context, 'Hata: $e');
    }
  }

  Future<void> _bulkDeactivate() async {
    if (_selected.isEmpty) return;
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Toplu Pasifleştirme',
      message: '${_selected.length} tedarikçiyi pasifleştirmek istediğinize emin misiniz?',
      icon: Icons.block_outlined,
      iconColor: AppColors.warning,
      confirmText: 'Pasifleştir',
      confirmColor: AppColors.warning,
    );
    if (!confirmed || !mounted) return;

    try {
      final svc = ref.read(supplierServiceProvider);
      for (final id in _selected) {
        await svc.toggleStatus(id);
      }
      AppToast.success(context, '${_selected.length} tedarikçi pasifleştirildi');
      setState(() {
        _selected.clear();
        _selectionMode = false;
      });
      _load();
    } catch (e) {
      if (mounted) AppToast.error(context, 'Hata: $e');
    }
  }

  Future<void> _openAdd() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddSupplierScreen()),
    );
    if (result == true) _load();
  }

  Future<void> _openEdit(Map<String, dynamic> supplier) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => AddSupplierScreen(supplier: supplier)),
    );
    if (result == true) _load();
  }

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
              icon: const Icon(Icons.add_business, color: Colors.white),
              label: const Text(
                'Yeni Tedarikçi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

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
              'Tedarikçi Yönetimi',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
      actions: [
        if (_selectionMode) ...[
          IconButton(
            icon: const Icon(Icons.block_outlined),
            onPressed: _bulkDeactivate,
            tooltip: 'Toplu Pasifleştir',
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
  Widget _buildSearchAndFilters() {
    // Filtresiz toplam sayılar (stats için sabit tutulur)
    final active = _statusFilter == 'Tümü' && _searchCtrl.text.isEmpty
        ? _all.where((s) => s['isActive'] == true).length
        : _activeCount;
    final passive = _statusFilter == 'Tümü' && _searchCtrl.text.isEmpty
        ? _all.length - active
        : _passiveCount;
    final total = _statusFilter == 'Tümü' && _searchCtrl.text.isEmpty
        ? _all.length
        : _totalCount;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Arama
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AppSearchInput(
              controller: _searchCtrl,
              hint: 'Firma adı, kod, iletişim veya telefon ara...',
            ),
          ),

          // Durum filtreleri
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _statusFilters.map((s) => _filterChip(
                    label: s,
                    selected: _statusFilter == s,
                    color: s == 'Aktif' ? AppColors.success : s == 'Pasif' ? AppColors.danger
                            : AppColors.primary,
                    onTap: () {
                      setState(() => _statusFilter = s);
                      // Filtre değişince backend'e yeni istek at
                      _load();
                    },
                  )).toList(),
            ),
          ),

          // İstatistikler
          if (_state == _ScreenState.loaded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  _statPill(
                      '$total', 'Toplam', Icons.business_outlined, AppColors.primary),
                  const SizedBox(width: 10),
                  _statPill(
                      '$active', 'Aktif', Icons.check_circle_outline, AppColors.success),
                  const SizedBox(width: 10),
                  _statPill(
                      '$passive', 'Pasif', Icons.cancel_outlined, AppColors.textMuted),
                  const SizedBox(width: 10),
                  _statPill(
                      '${_filtered.length}',
                      'Görüntülenen',
                      Icons.filter_list,
                      AppColors.info),
                ],
              ),
            ),

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

  Widget _statPill(String value, String label, IconData icon, Color color) {
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
                  fontSize: 15, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label,
                style: TextStyle(fontSize: 10, color: color),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  Widget _buildBody() {
    return switch (_state) {
      _ScreenState.loading => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: AppSkeletonCard(),
          ),
        ),
      _ScreenState.error => AppEmptyState.error(
          description: _errorMsg,
          onAction: _load,
        ),
      _ScreenState.loaded => _buildList(),
    };
  }

  Widget _buildList() {
    if (_all.isEmpty) {
      return AppEmptyState.noData(
        title: 'Henüz tedarikçi yok',
        description: 'Başlamak için yeni bir tedarikçi ekleyin',
        actionText: 'Tedarikçi Ekle',
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
        itemBuilder: (_, i) => _buildCard(_filtered[i]),
      ),
    );
  }

  // -------------------------------------------------------------------------
  Widget _buildCard(Map<String, dynamic> s) {
    final id = s['id']?.toString() ?? '';
    final isSelected = _selected.contains(id);
    final isActive = s['isActive'] == true;
    final statusColor = isActive ? AppColors.success : AppColors.textSecondary;
    final statusLabel = isActive ? 'Aktif' : 'Pasif';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () {
          if (_selectionMode) {
            setState(() =>
                isSelected ? _selected.remove(id) : _selected.add(id));
          } else {
            _openEdit(s);
          }
        },
        onLongPress: () => setState(() {
          _selectionMode = true;
          _selected.add(id);
        }),
        borderColor: isSelected ? AppColors.primary : null,
        borderWidth: isSelected ? 2 : 1,
        child: Row(
          children: [
            // Seçim
            if (_selectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color:
                      isSelected ? AppColors.primary : AppColors.textMuted,
                ),
              ),

            // İkon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: AppConstants.borderRadiusMedium,
              ),
              child: const Icon(
                Icons.business_outlined,
                color: AppColors.primary,
                size: 24,
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
                          s['name']?.toString() ?? '—',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppBadge(text: statusLabel, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _row(Icons.person_outline, s['contactName']?.toString()),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if ((s['phone']?.toString() ?? '').isNotEmpty)
                        Flexible(
                          child: _row(
                              Icons.phone_outlined, s['phone']?.toString()),
                        ),
                      if ((s['email']?.toString() ?? '').isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: _row(
                              Icons.email_outlined, s['email']?.toString()),
                        ),
                      ],
                    ],
                  ),
                  if ((s['website']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _row(Icons.language_outlined, s['website']?.toString()),
                  ],
                ],
              ),
            ),

            // Menü
            if (!_selectionMode)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    color: AppColors.textMuted, size: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: AppConstants.borderRadiusMedium),
                onSelected: (v) {
                  if (v == 'edit') _openEdit(s);
                  if (v == 'toggle') _toggleStatus(s);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: _MenuRow(
                        Icons.edit_outlined, 'Düzenle', AppColors.primary),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: isActive
                        ? const _MenuRow(Icons.block_outlined, 'Pasifleştir',
                            AppColors.warning)
                        : const _MenuRow(Icons.check_circle_outline,
                            'Aktifleştir', AppColors.success),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String? text, {bool bold = false}) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

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
        Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
