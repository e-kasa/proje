import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/service_locator.dart';
import '../../services/sales_service.dart';
import '../../core/theme/app_colors.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Satış iptal edildi'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İptal hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
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

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Satışlar'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(saleListProvider.notifier).load(),
            tooltip: 'Yenile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/pos');
          if (mounted) ref.read(saleListProvider.notifier).load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Yeni Satış'),
        backgroundColor: AppColors.primary,
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
              hintText: 'Satış no veya müşteri ara...',
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
                  .withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
              _filterChip('Tümü', null, state.statusFilter, theme),
              const SizedBox(width: 8),
              _filterChip('Ödendi', 'paid', state.statusFilter, theme),
              const SizedBox(width: 8),
              _filterChip('Veresiye', 'pending', state.statusFilter, theme),
              const SizedBox(width: 8),
              _filterChip('İptal', 'cancelled', state.statusFilter, theme),
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
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
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
                    '${state.filtered.length} kayıt',
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
                  '${state.filtered.length} kayıt',
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
      selectedColor: AppColors.primary.withOpacity(0.15),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildDateFilterButton(SaleListState state, ThemeData theme) {
    final hasFilter = state.startDate != null || state.endDate != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showDateRangePicker(state),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: hasFilter
                ? AppColors.info.withOpacity(0.1)
                : theme.colorScheme.surfaceContainerHighest
                    .withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasFilter
                  ? AppColors.info.withOpacity(0.3)
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
                'Tarih',
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
      helpText: 'Tarih Aralığı Seçin',
      cancelText: 'İptal',
      confirmText: 'Uygula',
      saveText: 'Uygula',
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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: cancelled
              ? Colors.red.withOpacity(0.3)
              : theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await context.push('/sales/detail/${s['id']}');
          if (mounted) ref.read(saleListProvider.notifier).load();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                          ? Colors.red.withOpacity(0.1)
                          : isPending
                              ? Colors.orange.withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      cancelled
                          ? Icons.cancel_outlined
                          : isPending
                              ? Icons.schedule_rounded
                              : Icons.point_of_sale_rounded,
                      color: cancelled
                          ? Colors.red
                          : isPending
                              ? Colors.orange
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
                          customerName ?? 'Perakende Satış',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: cancelled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
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
                          color: cancelled ? Colors.grey : AppColors.primary,
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
                      '$itemCount kalem',
                      Icons.inventory_2_outlined,
                      theme.colorScheme.onSurfaceVariant,
                      theme,
                    ),
                  const Spacer(),
                  if (cancelled)
                    _tag('İptal Edildi', Icons.cancel_outlined, Colors.red,
                        theme)
                  else if (isPending)
                    _tag('Veresiye', Icons.schedule_rounded, Colors.orange,
                        theme)
                  else if (isPaid)
                    _tag('Ödendi', Icons.check_circle_outline, Colors.green,
                        theme)
                  else
                    _tag('Açık', Icons.hourglass_empty, Colors.blue, theme),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
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
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Nakit';
      case 'credit_card':
        return 'Kredi Kartı';
      case 'bank_transfer':
        return 'Havale/EFT';
      case 'mixed':
        return 'Karma';
      default:
        return '';
    }
  }

  // ─── Error & Empty ────────────────────────────────────────────────────────

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(saleListProvider.notifier).load(),
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.point_of_sale_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Satış kaydı bulunamadı',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '"Yeni Satış" butonuna tıklayarak POS ekranına gidin',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
