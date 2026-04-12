import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/widgets/common/base_entity_list_screen.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/services/service_locator.dart';
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
  String Function(String) get t => i18nOf(ref);

  final _baseKey = GlobalKey<BaseEntityListScreenState<Map<String, dynamic>>>();

  // Stats icin filtresiz sayilar
  int _totalCount = 0;
  int _activeCount = 0;
  int _passiveCount = 0;

  // Aktif durum filtresi (backend'e gonderilecek)
  String _statusFilter = 'all';

  static const _statusFilters = ['all', 'active', 'passive'];

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
    final action = isActive ? t('common.deactivate') : t('common.activate');
    final actionColor = isActive ? AppColors.warning : AppColors.success;
    final actionIcon =
        isActive ? Icons.block_outlined : Icons.check_circle_outline;

    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: '$action: ${supplier['name'] ?? ''}',
      message: isActive
          ? t('suppliers.deactivate_message')
          : t('suppliers.activate_message'),
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
            '$name ${isActive ? t('common.deactivated') : t('common.activated')}');
      }
      _baseKey.currentState?.load();
    } catch (e) {
      if (mounted) AppToast.error(context, '${t('common.error')}: $e');
    }
  }

  Future<void> _bulkDeactivate(Set<String> selectedIds) async {
    if (selectedIds.isEmpty) return;
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: t('suppliers.bulk_deactivate'),
      message: t('suppliers.bulk_deactivate_confirm').replaceAll('{count}', selectedIds.length.toString()),
      icon: Icons.block_outlined,
      iconColor: AppColors.warning,
      confirmText: t('common.deactivate'),
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
            context, '${selectedIds.length} ${t('suppliers.bulk_deactivated')}');
      }
    } catch (e) {
      if (mounted) AppToast.error(context, '${t('common.error')}: $e');
    }
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return BaseEntityListScreen<Map<String, dynamic>>(
      key: _baseKey,
      title: t('suppliers.title'),
      searchHint: t('suppliers.search_hint'),
      icon: Icons.business_outlined,
      accentColor: AppColors.primary,
      fabLabel: t('suppliers.add'),
      fabIcon: Icons.add_business,
      emptyTitle: t('suppliers.empty_title'),
      emptyDescription: t('suppliers.empty_description'),
      emptyActionText: t('suppliers.add'),
      bulkActionIcon: Icons.block_outlined,
      bulkActionTooltip: t('suppliers.bulk_deactivate'),
      onAdd: _openAdd,
      onBulkAction: _bulkDeactivate,
      idExtractor: (s) => s['id']?.toString() ?? '',
      serverSideSearch: true,
      fetchItems: (ref, {String? search}) async {
        final status = _statusFilter == 'active'
            ? 'ACTIVE'
            : _statusFilter == 'passive'
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
                label: s == 'all'
                    ? t('common.all')
                    : s == 'active'
                        ? t('common.active')
                        : t('common.passive'),
                color: s == 'active'
                    ? AppColors.success
                    : s == 'passive'
                        ? AppColors.danger
                        : AppColors.primary,
              ))
          .toList(),
      filterMatcher: (item, filter) {
        // Server-side search: filtre degistiginde _statusFilter'i guncelle
        // ve load() cagirilir. filterMatcher burada sadece local fallback.
        if (filter == t('common.all')) {
          _statusFilter = 'all';
          return true;
        }
        if (filter == t('common.active')) {
          _statusFilter = 'active';
          return item['isActive'] == true;
        }
        if (filter == t('common.passive')) {
          _statusFilter = 'passive';
          return item['isActive'] != true;
        }
        return true;
      },
      statsBuilder: (items) {
        final isUnfiltered =
            _statusFilter == 'all' &&
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
            label: t('common.total'),
            icon: Icons.business_outlined,
            color: AppColors.primary,
          ),
          StatPill(
            value: '$active',
            label: t('common.active'),
            icon: Icons.check_circle_outline,
            color: AppColors.success,
          ),
          StatPill(
            value: '$passive',
            label: t('common.passive'),
            icon: Icons.cancel_outlined,
            color: AppColors.textMuted,
          ),
          StatPill(
            value: '$filtered',
            label: t('common.displayed'),
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
    final statusLabel = isActive ? t('common.active') : t('common.passive');
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
                        t('suppliers.balance'),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.account_balance_wallet_outlined,
                                  size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(t('suppliers.account'),
                                  style: const TextStyle(
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
                PopupMenuItem(
                  value: 'account',
                  child: MenuRow(Icons.account_balance_wallet_outlined,
                      t('suppliers.account'), AppColors.success),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: MenuRow(
                      Icons.edit_outlined, t('common.edit'), AppColors.primary),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: isActive
                      ? MenuRow(Icons.block_outlined,
                          t('common.deactivate'), AppColors.warning)
                      : MenuRow(Icons.check_circle_outline,
                          t('common.activate'), AppColors.success),
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
        ? Colors.orange
        : amount < 0
            ? AppColors.success
            : AppColors.textMuted;
    final prefix = isDebt
        ? '${t('suppliers.debt')}: '
        : amount < 0
            ? '${t('suppliers.credit')}: '
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