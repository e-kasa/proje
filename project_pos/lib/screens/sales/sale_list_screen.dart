import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/i18n_helper.dart';
import '../../services/service_locator.dart';
import '../../services/sales_service.dart';

// ─── State ──────────────────────────────────────────────────────────────────

class SaleListState {
  final List<Map<String, dynamic>> sales;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? statusFilter; // null=tümü, 'paid', 'pending', 'cancelled'
  final DateTime? startDate;
  final DateTime? endDate;

  const SaleListState({
    this.sales = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.statusFilter,
    this.startDate,
    this.endDate,
  });

  List<Map<String, dynamic>> get filtered {
    var list = sales;

    // Durum filtresi
    if (statusFilter != null) {
      list = list.where((s) {
        final status = s['status']?.toString().toLowerCase() ??
            s['paymentStatus']?.toString().toLowerCase() ??
            '';
        if (statusFilter == 'cancelled') {
          return status == 'cancelled' || s['isCancelled'] == true;
        }
        if (statusFilter == 'paid') {
          return status == 'paid' || status == 'completed';
        }
        if (statusFilter == 'pending') {
          return status == 'pending' || status == 'unpaid';
        }
        return true;
      }).toList();
    }

    // Tarih filtresi
    if (startDate != null || endDate != null) {
      list = list.where((s) {
        final dateStr = s['createdAt']?.toString() ??
            s['saleDate']?.toString() ??
            s['date']?.toString();
        if (dateStr == null) return true;
        final date = DateTime.tryParse(dateStr);
        if (date == null) return true;
        if (startDate != null && date.isBefore(startDate!)) return false;
        if (endDate != null &&
            date.isAfter(endDate!.add(const Duration(days: 1)))) return false;
        return true;
      }).toList();
    }

    // Arama
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where((s) =>
              (s['id']?.toString().toLowerCase().contains(q) ?? false) ||
              (s['saleNumber']?.toString().toLowerCase().contains(q) ??
                  false) ||
              (s['customerName']?.toString().toLowerCase().contains(q) ??
                  false))
          .toList();
    }

    return list;
  }

  SaleListState copyWith({
    List<Map<String, dynamic>>? sales,
    bool? isLoading,
    String? error,
    String? searchQuery,
    Object? statusFilter = _sentinel,
    Object? startDate = _sentinel,
    Object? endDate = _sentinel,
  }) {
    return SaleListState(
      sales: sales ?? this.sales,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter == _sentinel
          ? this.statusFilter
          : statusFilter as String?,
      startDate:
          startDate == _sentinel ? this.startDate : startDate as DateTime?,
      endDate: endDate == _sentinel ? this.endDate : endDate as DateTime?,
    );
  }
}

const _sentinel = Object();

// ─── Notifier ───────────────────────────────────────────────────────────────

class SaleListNotifier extends StateNotifier<SaleListState> {
  final SalesService _service;

  SaleListNotifier(this._service) : super(const SaleListState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _service.getSales(
        startDate: state.startDate,
        endDate: state.endDate,
        paymentStatus: state.statusFilter,
      );
      state = state.copyWith(sales: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearch(String q) => state = state.copyWith(searchQuery: q);

  void setStatusFilter(String? val) =>
      state = state.copyWith(statusFilter: val);

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
    load();
  }

  void clearDateRange() {
    state = state.copyWith(
      startDate: null,
      endDate: null,
    );
    load();
  }

  Future<void> cancel(String id, String reason, BuildContext context) async {
    try {
      await _service.cancelSale(id, reason);
      await load();
      if (context.mounted) {
        AppToast.warning(context, 'Satış iptal edildi');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'İptal hatası: $e');
      }
    }
  }
}

final saleListProvider =
    StateNotifierProvider.autoDispose<SaleListNotifier, SaleListState>(
  (ref) => SaleListNotifier(ref.read(salesServiceProvider)),
);

// ─── Screen ─────────────────────────────────────────────────────────────────

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
    final state = ref.watch(saleListProvider);
    final theme = Theme.of(context);
    final t = i18nOf(ref);

    return AppScaffold(
      appBar: AppAppBar.standard(
        title: t('sales.title'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(saleListProvider.notifier).load(),
            tooltip: t('common.refresh'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/pos');
          if (mounted) ref.read(saleListProvider.notifier).load();
        },
        icon: const Icon(Icons.add),
        label: Text(t('sales.new_sale')),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(state, theme),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? _buildError(state.error!)
                    : state.filtered.isEmpty
                        ? _buildEmpty()
                        : _buildList(state.filtered, theme),
          ),
        ],
      ),
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
                            size: 14, color: AppColors.bgInfo,
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
                              size: 14, color: AppColors.bgInfo,
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

  // ─── Sale List ────────────────────────────────────────────────────────────

  Widget _buildList(List<Map<String, dynamic>> items, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final s = items[index];
        return _buildSaleCard(s, theme);
      },
    );
  }

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
                        Colors.deepOrange, theme),
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

  // ─── Error & Empty ────────────────────────────────────────────────────────

  Widget _buildError(String error) {
    final t = i18nOf(ref);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.bgDanger,
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          AppButton.primary(
                        text: t('sales.retry'),
                        icon: Icons.refresh,
                        onPressed: () => ref.read(saleListProvider.notifier).load(),
                      ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final t = i18nOf(ref);
    return AppEmptyState.noData(
      title: t('sales.no_sales'),
      description: t('sales.new_sale_hint'),
    );
  }
}
