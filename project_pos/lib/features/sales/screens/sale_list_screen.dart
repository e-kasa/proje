import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/widgets/templates/list_screen_template.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/features/sales/di/sales_di.dart';
import 'package:project_pos/features/sales/providers/sale_list_notifier.dart';

class SaleListScreen extends ConsumerStatefulWidget {
  const SaleListScreen({super.key});

  @override
  ConsumerState<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends ConsumerState<SaleListScreen> {
  final _searchCtrl = TextEditingController();
  final _fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  final _dateFmt = DateFormat('dd.MM.yyyy');
  final _dateTimeFmt = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(saleListProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sprint 17 W1: AppScaffold + Column + manual switcher → ListScreenTemplate.
    final state = ref.watch(saleListProvider);
    final theme = Theme.of(context);
    final t = i18nOf(ref);

    return ListScreenTemplate<Map<String, dynamic>>(
      title: t('sales.title'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => ref.read(saleListProvider.notifier).load(),
          tooltip: t('common.refresh'),
        ),
      ],
      items: state.filtered,
      isLoading: state.isLoading,
      error: state.error,
      onErrorRetry: () => ref.read(saleListProvider.notifier).load(),
      onRefresh: () async => ref.read(saleListProvider.notifier).load(),
      searchSlot: _buildSearchAndFilter(state, theme),
      emptyState: AppEmptyState.noData(
        title: t('sales.no_sales'),
        description: t('sales.new_sale_hint'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/pos');
          if (mounted) ref.read(saleListProvider.notifier).load();
        },
        icon: const Icon(Icons.add),
        label: Text(t('sales.new_sale')),
      ),
      itemBuilder: (ctx, sale, idx) => _buildSaleCard(sale, theme),
    );
  }

  // ─── Search & Filter ──────────────────────────────────────────────────────

  Widget _buildSearchAndFilter(SaleListState state, ThemeData theme) {
    final t = i18nOf(ref);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // Arama
          TextField(
            controller: _searchCtrl,
            onChanged: (v) =>
                ref.read(saleListProvider.notifier).setSearch(v),
            decoration: InputDecoration(
              hintText: t('sales.search_hint'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(saleListProvider.notifier).setSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: AppConstants.borderRadiusMedium,
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
          const SizedBox(height: 8),
          // Filtre çipleri + tarih
          Row(
            children: [
              _filterChip(t('common.all'), null, state.statusFilter, theme),
              const SizedBox(width: 8),
              _filterChip(t('sales.paid'), 'paid', state.statusFilter, theme),
              const SizedBox(width: 8),
              _filterChip(t('sales.pending'), 'pending', state.statusFilter, theme),
              const SizedBox(width: 8),
              _filterChip(t('sales.cancelled'), 'cancelled', state.statusFilter, theme),
              const Spacer(),
              // Tarih filtresi
              _buildDateFilterButton(state, theme),
            ],
          ),
          // Tarih aralığı badge
          if (state.startDate != null || state.endDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: AppConstants.borderRadiusSmall,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.date_range,
                            size: 14, color: AppColors.info),
                        const SizedBox(width: 4),
                        Text(
                          '${state.startDate != null ? _dateFmt.format(state.startDate!) : '...'}'
                          ' - '
                          '${state.endDate != null ? _dateFmt.format(state.endDate!) : '...'}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () =>
                              ref.read(saleListProvider.notifier).clearDateRange(),
                          child: Icon(Icons.close,
                              size: 14, color: AppColors.info),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${state.filtered.length} ${t('sales.records')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${state.filtered.length} ${t('sales.records')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(
      String label, String? value, String? current, ThemeData theme) {
    final selected = current == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) =>
          ref.read(saleListProvider.notifier).setStatusFilter(value),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildDateFilterButton(SaleListState state, ThemeData theme) {
    final t = i18nOf(ref);
    final hasFilter = state.startDate != null || state.endDate != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppConstants.borderRadiusSmall,
        onTap: () => _showDateRangePicker(state),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: hasFilter
                ? AppColors.info.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
            borderRadius: AppConstants.borderRadiusSmall,
            border: Border.all(
              color: hasFilter
                  ? AppColors.info.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: hasFilter
                    ? AppColors.info
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                t('common.date'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: hasFilter ? FontWeight.w600 : FontWeight.w400,
                  color: hasFilter
                      ? AppColors.info
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker(SaleListState state) async {
    final t = i18nOf(ref);
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: state.startDate != null && state.endDate != null
          ? DateTimeRange(start: state.startDate!, end: state.endDate!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)), end: now),
      locale: const Locale('tr', 'TR'),
      helpText: t('sales.select_date_range'),
      cancelText: t('common.cancel'),
      confirmText: t('sales.apply'),
      saveText: t('sales.apply'),
    );

    if (picked != null) {
      ref
          .read(saleListProvider.notifier)
          .setDateRange(picked.start, picked.end);
    }
  }

  // ─── Sale Card ────────────────────────────────────────────────────────────

  Widget _buildSaleCard(Map<String, dynamic> s, ThemeData theme) {
    final t = i18nOf(ref);
    final status = s['status']?.toString().toLowerCase() ??
        s['paymentStatus']?.toString().toLowerCase() ??
        '';
    final cancelled = status == 'cancelled' || s['isCancelled'] == true;
    final isPaid = status == 'paid' || status == 'completed';
    final isPending = status == 'pending' || status == 'unpaid';

    final total = (s['totalAmount'] as num?)?.toDouble() ??
        (s['grandTotal'] as num?)?.toDouble() ??
        0;
    final customerName =
        s['customerName']?.toString() ?? s['customer']?.toString();

    final dateStr = s['createdAt']?.toString() ??
        s['saleDate']?.toString() ??
        s['date']?.toString();
    final dateDisplay = dateStr != null
        ? _dateTimeFmt
            .format(DateTime.tryParse(dateStr) ?? DateTime.now())
        : '-';

    final saleNo =
        s['saleNumber']?.toString() ?? s['id']?.toString() ?? '-';
    final paymentMethod = _paymentMethodLabel(
        s['paymentMethod']?.toString() ?? '');
    final itemCount = (s['items'] as List?)?.length ?? s['itemCount'];
    final hasReturn = s['hasReturn'] == true;

    // Satılan ürün/varyant adları
    final items = s['items'] as List?;
    final itemNames = items != null
        ? items
            .take(3)
            .map((i) =>
                (i as Map<String, dynamic>)['variantName']?.toString() ??
                (i)['productName']?.toString() ??
                '')
            .where((n) => n.isNotEmpty)
            .toList()
        : <String>[];
    final moreCount = (items?.length ?? 0) - 3;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () async {
          await context.push('/sales/detail/${s['id']}');
          if (mounted) ref.read(saleListProvider.notifier).load();
        },
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // İkon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cancelled
                          ? AppColors.danger.withValues(alpha: 0.1)
                          : isPending
                              ? AppColors.warning.withValues(alpha: 0.1)
                              : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppConstants.borderRadiusSmall,
                    ),
                    child: Icon(
                      cancelled
                          ? Icons.cancel_outlined
                          : isPending
                              ? Icons.schedule_rounded
                              : Icons.point_of_sale_rounded,
                      color: cancelled
                          ? AppColors.danger
                          : isPending
                              ? AppColors.warning
                              : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Satış bilgisi
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemNames.isNotEmpty
                              ? itemNames.join(', ') + (moreCount > 0 ? ' +$moreCount' : '')
                              : customerName ?? 'Perakende Satış',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: cancelled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (customerName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            customerName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          '#$saleNo  •  $dateDisplay',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tutar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmt.format(total),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cancelled ? AppColors.textMuted : AppColors.primary,
                        ),
                      ),
                      if (paymentMethod.isNotEmpty)
                        Text(
                          paymentMethod,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Alt etiketler
              Row(
                children: [
                  if (itemCount != null)
                    _tag(
                      '$itemCount ${t('sales.items_unit')}',
                      Icons.inventory_2_outlined,
                      theme.colorScheme.onSurfaceVariant,
                      theme,
                    ),
                  if (hasReturn) ...[
                    const SizedBox(width: 6),
                    _tag(t('sales.has_return'), Icons.assignment_return_outlined,
                        AppColors.orange, theme),
                  ],
                  const Spacer(),
                  if (cancelled)
                    _tag(t('sales.cancelled'), Icons.cancel_outlined, AppColors.danger,
                        theme)
                  else if (isPending)
                    _tag(t('sales.pending'), Icons.schedule_rounded, AppColors.warning,
                        theme)
                  else if (isPaid)
                    _tag(t('sales.paid'), Icons.check_circle_outline, AppColors.success,
                        theme)
                  else
                    _tag(t('sales.open'), Icons.hourglass_empty, AppColors.info, theme),
                ],
              ),
            ],
          ),
        ),
    );
  }

  Widget _tag(String label, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppConstants.borderRadiusSmall,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _paymentMethodLabel(String method) {
    final t = i18nOf(ref);
    switch (method.toLowerCase()) {
      case 'cash':
        return t('sales.payment_cash');
      case 'credit_card':
        return t('sales.payment_credit_card');
      case 'bank_transfer':
        return t('sales.payment_bank_transfer');
      case 'mixed':
        return t('sales.payment_mixed');
      default:
        return '';
    }
  }
}
