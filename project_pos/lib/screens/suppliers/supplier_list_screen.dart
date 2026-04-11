import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/common/base_entity_list_screen.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';
import 'add_supplier_screen.dart';

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
  final _baseKey = GlobalKey<BaseEntityListScreenState<Map<String, dynamic>>>();

  // Stats icin filtresiz sayilar
  int _totalCount = 0;
  int _activeCount = 0;
  int _passiveCount = 0;

  // Aktif durum filtresi (backend'e gonderilecek)
  String _statusFilter = 'Tumu';

  static const _statusFilters = ['Tumu', 'Aktif', 'Pasif'];

  // -------------------------------------------------------------------------
  // Navigasyon
  // -------------------------------------------------------------------------
  Future<void> _openAdd() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddSupplierScreen()),
    );
    if (result == true) _baseKey.currentState?.load();
  }

  Future<void> _openEdit(Map<String, dynamic> supplier) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => AddSupplierScreen(supplier: supplier)),
    );
    if (result == true) _baseKey.currentState?.load();
  }

  Future<void> _toggleStatus(Map<String, dynamic> supplier) async {
    final isActive = supplier['isActive'] == true;
    final action = isActive ? 'Pasiflestir' : 'Aktivlestir';
    final actionColor = isActive ? AppColors.warning : AppColors.success;
    final actionIcon =
        isActive ? Icons.block_outlined : Icons.check_circle_outline;

    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: '$action: ${supplier['name'] ?? ''}',
      message: isActive
          ? 'Tedarikci pasiflestirilecek. Kayitlar korunur.'
          : 'Tedarikci aktiflestirilecek. Yeniden siparis verilebilir.',
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
      if (mounted) {
        AppToast.success(context,
            '$name ${isActive ? 'pasiflestirildi' : 'aktiflestirildi'}');
      }
      _baseKey.currentState?.load();
    } catch (e) {
      if (mounted) AppToast.error(context, 'Hata: $e');
    }
  }

  Future<void> _bulkDeactivate(Set<String> selectedIds) async {
    if (selectedIds.isEmpty) return;
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Toplu Pasiflestirme',
      message:
          '${selectedIds.length} tedarikciyi pasiflestirmek istediginize emin misiniz?',
      icon: Icons.block_outlined,
      iconColor: AppColors.warning,
      confirmText: 'Pasiflestir',
      confirmColor: AppColors.warning,
    );
    if (!confirmed || !mounted) return;

    try {
      final svc = ref.read(supplierServiceProvider);
      for (final id in selectedIds) {
        await svc.toggleStatus(id);
      }
      if (mounted) {
        AppToast.success(
            context, '${selectedIds.length} tedarikci pasiflestirildi');
      }
    } catch (e) {
      if (mounted) AppToast.error(context, 'Hata: $e');
    }
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return BaseEntityListScreen<Map<String, dynamic>>(
      key: _baseKey,
      title: 'Tedarikci Yonetimi',
      searchHint: 'Firma adi, kod, iletisim veya telefon ara...',
      icon: Icons.business_outlined,
      accentColor: AppColors.primary,
      fabLabel: 'Yeni Tedarikci',
      fabIcon: Icons.add_business,
      emptyTitle: 'Henuz tedarikci yok',
      emptyDescription: 'Baslamak icin yeni bir tedarikci ekleyin',
      emptyActionText: 'Tedarikci Ekle',
      bulkActionIcon: Icons.block_outlined,
      bulkActionTooltip: 'Toplu Pasiflestir',
      onAdd: _openAdd,
      onBulkAction: _bulkDeactivate,
      idExtractor: (s) => s['id']?.toString() ?? '',
      serverSideSearch: true,
      fetchItems: (ref, {String? search}) async {
        final status = _statusFilter == 'Aktif'
            ? 'ACTIVE'
            : _statusFilter == 'Pasif'
                ? 'INACTIVE'
                : null;

        final list = await ref
            .read(supplierServiceProvider)
            .getSuppliers(search: search, status: status);

        // Stats guncelle (filtresiz oldugunda)
        if (status == null && search == null && mounted) {
          setState(() {
            _totalCount = list.length;
            _activeCount =
                list.where((s) => s['isActive'] == true).length;
            _passiveCount = _totalCount - _activeCount;
          });
        }

        return list;
      },
      filterOptions: () => _statusFilters
          .map((s) => FilterChipData(
                label: s,
                color: s == 'Aktif'
                    ? AppColors.success
                    : s == 'Pasif'
                        ? AppColors.danger
                        : AppColors.primary,
              ))
          .toList(),
      filterMatcher: (item, filter) {
        // Server-side search: filtre degistiginde _statusFilter'i guncelle
        // ve load() cagirilir. filterMatcher burada sadece local fallback.
        if (filter == 'Tumu') {
          _statusFilter = 'Tumu';
          return true;
        }
        if (filter == 'Aktif') {
          _statusFilter = 'Aktif';
          return item['isActive'] == true;
        }
        if (filter == 'Pasif') {
          _statusFilter = 'Pasif';
          return item['isActive'] != true;
        }
        return true;
      },
      statsBuilder: (items) {
        final isUnfiltered =
            _statusFilter == 'Tumu' &&
            (_baseKey.currentState?.searchCtrl.text.isEmpty ?? true);
        final total = isUnfiltered ? items.length : _totalCount;
        final active = isUnfiltered
            ? items.where((s) => s['isActive'] == true).length
            : _activeCount;
        final passive = isUnfiltered ? items.length - active : _passiveCount;
        final filtered =
            _baseKey.currentState?.filteredItems.length ?? items.length;

        return [
          StatPill(
            value: '$total',
            label: 'Toplam',
            icon: Icons.business_outlined,
            color: AppColors.primary,
          ),
          StatPill(
            value: '$active',
            label: 'Aktif',
            icon: Icons.check_circle_outline,
            color: AppColors.success,
          ),
          StatPill(
            value: '$passive',
            label: 'Pasif',
            icon: Icons.cancel_outlined,
            color: AppColors.textMuted,
          ),
          StatPill(
            value: '$filtered',
            label: 'Goruntulenen',
            icon: Icons.filter_list,
            color: AppColors.info,
          ),
        ];
      },
      itemBuilder: (context, supplier, isSelected, onTap) {
        return _buildCard(supplier, isSelected, onTap);
      },
    );
  }

  // -------------------------------------------------------------------------
  // Tedarikci karti
  // -------------------------------------------------------------------------
  Widget _buildCard(
    Map<String, dynamic> s,
    bool isSelected,
    VoidCallback onSelectionTap,
  ) {
    final id = s['id']?.toString() ?? '';
    final isActive = s['isActive'] == true;
    final statusColor = isActive ? AppColors.success : AppColors.textSecondary;
    final statusLabel = isActive ? 'Aktif' : 'Pasif';
    final selMode = _baseKey.currentState?.selectionMode ?? false;

    return AppCard(
      onTap: () {
        if (selMode) {
          onSelectionTap();
        } else {
          context.push('/suppliers/account/$id');
        }
      },
      borderColor: isSelected ? AppColors.primary : null,
      borderWidth: isSelected ? 2 : 1,
      child: Row(
        children: [
          // Secim
          if (selMode)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                isSelected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),

          // Ikon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
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
                        s['name']?.toString() ?? '\u2014',
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
                // Bakiye bilgisi
                if (s['balance'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _balancePill(
                        'Bakiye',
                        (s['balance'] as num?)?.toDouble() ?? 0,
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () =>
                            context.push('/suppliers/account/$id'),
                        borderRadius: AppConstants.borderRadiusSmall,
                        child: Container(
                          padding: AppConstants.paddingHorizontalSmall,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: AppConstants.borderRadiusSmall,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.account_balance_wallet_outlined,
                                  size: 12, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text('Cari Hesap',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Menu
          if (!selMode)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: AppColors.textMuted, size: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: AppConstants.borderRadiusMedium),
              onSelected: (v) {
                if (v == 'edit') _openEdit(s);
                if (v == 'toggle') _toggleStatus(s);
                if (v == 'account') {
                  context.push('/suppliers/account/$id');
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'account',
                  child: MenuRow(Icons.account_balance_wallet_outlined,
                      'Cari Hesap', AppColors.bgSuccess,
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: MenuRow(
                      Icons.edit_outlined, 'Duzenle', AppColors.primary),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: isActive
                      ? const MenuRow(Icons.block_outlined,
                          'Pasiflestir', AppColors.bgWarning
                      : const MenuRow(Icons.check_circle_outline,
                          'Aktivlestir', AppColors.bgSuccess,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _balancePill(String label, double amount) {
    final isDebt = amount > 0;
    final color = isDebt
        ? AppColors.warning
        : amount < 0
            ? AppColors.success
            : AppColors.textMuted;
    final prefix = isDebt
        ? 'Borc: '
        : amount < 0
            ? 'Alacak: '
            : '';
    final display = amount.abs();

    return Container(
      padding: AppConstants.paddingHorizontalSmall,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppConstants.borderRadiusSmall,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDebt
                ? Icons.arrow_upward
                : amount < 0
                    ? Icons.arrow_downward
                    : Icons.check,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$prefix\u20BA${display.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
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
