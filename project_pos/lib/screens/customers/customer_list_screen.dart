import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/common/base_entity_list_screen.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';
import 'add_customer_screen.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

// ---------------------------------------------------------------------------
// Musteri tipi yardimcilari
// ---------------------------------------------------------------------------
const _typeMap = {'Bireysel': 'regular', 'VIP': 'vip', 'Toptan': 'wholesale'};
const _typeFilters = ['Tumu', 'Bireysel', 'VIP', 'Toptan'];

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
  String Function(String) get t => i18nOf(ref);

  final _baseKey = GlobalKey<BaseEntityListScreenState<Map<String, dynamic>>>();

  // Stats (filtresiz, sabit tutulur)
  int _totalCount = 0;
  int _activeCount = 0;
  int _passiveCount = 0;
  int _corporateCount = 0;

  // Sehir filtreleri - dinamik olarak yuklenir
  Set<String> _cities = {'Tumu'};
  String _cityFilter = 'Tumu';

  // -------------------------------------------------------------------------
  // Navigasyon
  // -------------------------------------------------------------------------
  Future<void> _openAdd() async {
    final result = await context.push<bool>('/customers/add');
    if (result == true) _baseKey.currentState?.load();
  }

  Future<void> _openEdit(Map<String, dynamic> customer) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddCustomerScreen(customer: customer),
      ),
    );
    if (result == true) _baseKey.currentState?.load();
  }

  Future<void> _delete(Map<String, dynamic> customer) async {
    final confirmed = await AppConfirmationDialog.showDelete(
      context: context,
      title: t('common.delete'),
      message: t('common.are_you_sure'),
      itemName: customer['name'] as String?,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref
          .read(customerServiceProvider)
          .deleteCustomer(customer['id']);
      if (mounted) AppToast.success(context, '${customer['name']} ${t('common.deleted')}');
      _baseKey.currentState?.load();
    } catch (e) {
      if (mounted) AppToast.error(context, '${t('common.error')}: $e');
    }
  }

  Future<void> _bulkDelete(Set<String> selectedIds) async {
    if (selectedIds.isEmpty) return;
    final confirmed = await AppConfirmationDialog.showDelete(
      context: context,
      title: t('common.delete'),
      message: t('common.are_you_sure'),
    );
    if (!confirmed || !mounted) return;

    try {
      final svc = ref.read(customerServiceProvider);
      for (final id in selectedIds) {
        await svc.deleteCustomer(id);
      }
      if (mounted) {
        AppToast.success(context, '${selectedIds.length} ${t('customers.title')} ${t('common.deleted')}');
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
      title: t('menu.customers'),
      searchHint: t('common.search'),
      icon: Icons.people_outline,
      accentColor: AppColors.primary,
      fabLabel: t('customers.add'),
      fabIcon: Icons.person_add,
      emptyTitle: t('common.no_data'),
      emptyDescription: t('common.no_records'),
      emptyActionText: t('customers.add'),
      bulkActionIcon: Icons.delete_outline,
      bulkActionTooltip: t('common.delete'),
      onAdd: _openAdd,
      onBulkAction: _bulkDelete,
      idExtractor: (c) => c['id']?.toString() ?? '',
      serverSideSearch: false,
      localSearchMatcher: (c, q) {
        return c['name'].toString().toLowerCase().contains(q) ||
            (c['phone']?.toString().toLowerCase() ?? '').contains(q) ||
            (c['email']?.toString().toLowerCase() ?? '').contains(q);
      },
      fetchItems: (ref, {String? search}) async {
        final list = await ref.read(customerServiceProvider).getCustomers();

        // Sehirleri guncelle
        final cities = list
            .where((c) => (c['city']?.toString() ?? '').isNotEmpty)
            .map((c) => c['city'].toString())
            .toSet();
        if (mounted) {
          setState(() {
            _cities = {'Tumu', ...cities};
            // Stats: filtresiz yukleme oldugunda guncelle
            _totalCount = list.length;
            _activeCount = list.where((c) => c['isActive'] == true).length;
            _passiveCount = _totalCount - _activeCount;
            _corporateCount = list
                .where(
                    (c) => c['customerType']?.toString() == 'CORPORATE')
                .length;
          });
        }

        // Sehir filtresi uygula (lokal)
        if (_cityFilter != 'Tumu') {
          return list.where((c) => c['city'] == _cityFilter).toList();
        }
        return list;
      },
      filterOptions: () {
        final chips = <FilterChipData>[
          // Tip filtreleri
          ..._typeFilters.map((t) => FilterChipData(
                label: t,
                color: AppColors.primary,
              )),
          // Sehir filtreleri
          ..._cities.map((c) => FilterChipData(
                label: c,
                color: AppColors.info,
              )),
        ];
        return chips;
      },
      filterMatcher: (item, filter) {
        // "Tumu" her seyi gecir
        if (filter == 'Tumu') return true;

        // Tip filtreleri
        if (_typeMap.containsKey(filter)) {
          return item['customerType'] == _typeMap[filter];
        }

        // Sehir filtreleri
        if (_cities.contains(filter) && filter != 'Tumu') {
          return item['city'] == filter;
        }

        return true;
      },
      statsBuilder: (items) {
        final total = items.length == _totalCount ? items.length : _totalCount;
        final active =
            items.length == _totalCount
                ? items.where((c) => c['isActive'] == true).length
                : _activeCount;
        final passive =
            items.length == _totalCount ? items.length - active : _passiveCount;
        final corporate = items.length == _totalCount
            ? items
                .where(
                    (c) => c['customerType']?.toString() == 'CORPORATE')
                .length
            : _corporateCount;

        return [
          StatPill(
            value: '$total',
            label: 'Toplam', // TODO: i18n
            icon: Icons.people_outline,
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
            value: '$corporate',
            label: 'Kurumsal', // TODO: i18n
            icon: Icons.business_outlined,
            color: AppColors.info,
          ),
        ];
      },
      itemBuilder: (context, customer, isSelected, onTap) {
        return _buildCustomerCard(customer, isSelected, onTap);
      },
    );
  }

  // -------------------------------------------------------------------------
  // Musteri karti
  // -------------------------------------------------------------------------
  Widget _buildCustomerCard(
    Map<String, dynamic> customer,
    bool isSelected,
    VoidCallback onSelectionTap,
  ) {
    final type = customer['customerType'] as String?;
    final color = _typeColor(type);
    final label = _typeLabel(type);
    final points = customer['loyaltyPoints'] ?? 0;
    final total = customer['totalPurchases'] ?? 0;
    final name = customer['name']?.toString() ?? '\u2014';
    final selMode = _baseKey.currentState?.selectionMode ?? false;

    return AppCard(
      onTap: () {
        if (selMode) {
          onSelectionTap();
        } else {
          _openEdit(customer);
        }
      },
      borderColor: isSelected ? AppColors.primary : null,
      borderWidth: isSelected ? 2 : 1,
      child: Row(
        children: [
          // Secim modu
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

          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withValues(alpha: 0.12),
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
                  _iconText(
                      Icons.phone_outlined, customer['phone'].toString()),
                ],
                if ((customer['city']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  _iconText(Icons.location_on_outlined,
                      customer['city'].toString()),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.star_rounded,
                        size: 14, color: AppColors.warning),
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
                      '\u20BA$total',
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

          // Menu
          if (!selMode)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: AppColors.textMuted, size: 20),
              shape: RoundedRectangleBorder(
                borderRadius: AppConstants.borderRadiusMedium,
              ),
              onSelected: (v) {
                if (v == 'account') {
                  final id = customer['id']?.toString() ?? '';
                  if (id.isNotEmpty) context.push('/customers/account/$id');
                }
                if (v == 'edit') _openEdit(customer);
                if (v == 'delete') _delete(customer);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'account',
                  child: MenuRow(Icons.account_balance_wallet,
                      t('menu.accounts'), AppColors.info),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: MenuRow(
                      Icons.edit_outlined, t('common.edit'), AppColors.primary),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: MenuRow(
                      Icons.delete_outline, t('common.delete'), AppColors.danger),
                ),
              ],
            ),
        ],
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
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}