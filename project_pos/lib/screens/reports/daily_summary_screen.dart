import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../services/service_locator.dart';
import '../../services/finance_service.dart';
import '../../core/api/api_client.dart';
import '../../core/widgets/widgets.dart';
import '../../core/theme/app_constants.dart';

class DailySummaryScreen extends ConsumerStatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  ConsumerState<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends ConsumerState<DailySummaryScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _dailySales = [];
  double _totalExpense = 0.0;
  late final FinanceService _financeService;

  final _currencyFormat =
      NumberFormat.currency(locale: 'tr_TR', symbol: '\u20BA');

  @override
  void initState() {
    super.initState();
    _financeService = FinanceService(ApiClient());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final salesSvc = ref.read(salesServiceProvider);
      final startOfDay = DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));

      final results = await Future.wait([
        salesSvc.getSalesStats(startDate: startOfDay, endDate: endOfDay),
        salesSvc.getDailySalesReport(date: _selectedDate),
        _financeService.getExpenses(startDate: startOfDay, endDate: endOfDay),
      ]);

      final expenses = results[2] as List<Map<String, dynamic>>;
      final expenseTotal = expenses.fold<double>(
        0.0,
        (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0),
      );

      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _dailySales = (results[1] as List<Map<String, dynamic>>?) ?? [];
        _totalExpense = expenseTotal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.standard(
        title: 'Gunluk Ozet',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: AppConstants.pagePadding,
                children: [
                  _buildDateSelector(),
                  const SizedBox(height: 16),
                  _buildSummaryCards(),
                  const SizedBox(height: 16),
                  _buildPaymentMethodSection(),
                  const SizedBox(height: 16),
                  _buildTopProductsSection(),
                  const SizedBox(height: 16),
                  _buildActivityTimeline(),
                ],
              ),
            ),
    );
  }

  // ── Date Selector ──────────────────────────────────────────────────

  Widget _buildDateSelector() {
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    return GestureDetector(
      onTap: _pickDate,
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            const Icon(Icons.calendar_today,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd MMMM yyyy, EEEE', 'tr_TR')
                        .format(_selectedDate),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  if (isToday)
                    const Text('Bugun',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.success)),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          ]),
        ),
      ),
    );
  }

  // ── Summary Cards ──────────────────────────────────────────────────

  Widget _buildSummaryCards() {
    final totalSales = _toD(_stats['totalSales']);
    final totalRevenue = _toD(_stats['totalRevenue']);
    final avgOrder = _toD(_stats['averageOrderValue']);

    final totalExpense = _totalExpense;
    final netProfit = totalRevenue - totalExpense;

    return Column(children: [
      Row(children: [
        Expanded(
            child: _summaryCard('Toplam Satis', totalSales.toInt().toString(),
                AppColors.primary, Icons.shopping_cart,
                isCount: true)),
        const SizedBox(width: 10),
        Expanded(
            child: _summaryCard('Toplam Gelir',
                _currencyFormat.format(totalRevenue), AppColors.success,
                Icons.trending_up)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
            child: _summaryCard('Ort. Siparis',
                _currencyFormat.format(avgOrder), AppColors.info,
                Icons.analytics)),
        const SizedBox(width: 10),
        Expanded(
            child: _summaryCard('Net Kar',
                _currencyFormat.format(netProfit), AppColors.warning,
                Icons.account_balance_wallet)),
      ]),
    ]);
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon,
      {bool isCount = false}) {
    return AppCard(
      child: Padding(
        padding: AppConstants.paddingSmall,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppConstants.borderRadiusSmall,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
      ),
    );
  }

  // ── Payment Method Section ─────────────────────────────────────────

  Widget _buildPaymentMethodSection() {
    final methodCounts = <String, int>{};
    final methodAmounts = <String, double>{};

    for (final s in _dailySales) {
      final method = s['paymentMethod']?.toString() ?? 'other';
      final amount = _toD(s['totalAmount']);
      methodCounts[method] = (methodCounts[method] ?? 0) + 1;
      methodAmounts[method] = (methodAmounts[method] ?? 0) + amount;
    }

    final methods = {
      'cash': {'label': 'Nakit', 'icon': Icons.money, 'color': AppColors.success},
      'credit_card': {
        'label': 'Kart',
        'icon': Icons.credit_card,
        'color': AppColors.info
      },
      'bank_transfer': {
        'label': 'Havale',
        'icon': Icons.account_balance,
        'color': AppColors.warning
      },
    };

    return AppCard(
      child: Padding(
        padding: AppConstants.pagePadding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Odeme Yontemleri',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...methods.entries.map((e) {
            final count = methodCounts[e.key] ?? 0;
            final amount = methodAmounts[e.key] ?? 0;
            final info = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (info['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: AppConstants.borderRadiusSmall,
                  ),
                  child: Icon(info['icon'] as IconData,
                      size: 18, color: info['color'] as Color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(info['label'] as String,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('$count islem',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                      ]),
                ),
                Text(_currencyFormat.format(amount),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: info['color'] as Color)),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  // ── Top Products ───────────────────────────────────────────────────

  Widget _buildTopProductsSection() {
    // Aggregate product sales from daily sales items
    final productMap = <String, double>{};
    for (final sale in _dailySales) {
      final items = sale['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          final name = item['productName']?.toString() ??
              item['variantName']?.toString() ??
              'Urun';
          final qty = _toD(item['quantity']);
          productMap[name] = (productMap[name] ?? 0) + qty;
        }
      }
    }

    final sorted = productMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();

    return AppCard(
      child: Padding(
        padding: AppConstants.pagePadding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('En Cok Satan Urunler',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (top5.isEmpty)
            AppEmptyState.noData(description: 'Veri bulunamadi')
          else
            ...top5.asMap().entries.map((e) {
              final idx = e.key;
              final entry = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: idx < 3
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : AppColors.bgLight,
                      borderRadius: AppConstants.borderRadiusSmall,
                    ),
                    child: Text('${idx + 1}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: idx < 3
                                ? AppColors.warning
                                : AppColors.textMuted)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(entry.key,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                  Text('${entry.value.toInt()} adet',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ]),
              );
            }),
        ]),
      ),
    );
  }

  // ── Activity Timeline ──────────────────────────────────────────────

  Widget _buildActivityTimeline() {
    final recentSales = _dailySales.take(5).toList();

    return AppCard(
      child: Padding(
        padding: AppConstants.pagePadding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Son Islemler',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (recentSales.isEmpty)
            AppEmptyState.noData(description: 'Bugun islem yapilmamis')
          else
            ...recentSales.map((sale) {
              final id = sale['id']?.toString() ?? '-';
              final amount = _toD(sale['totalAmount']);
              final method = sale['paymentMethod']?.toString() ?? '';
              final createdAt = sale['createdAt']?.toString() ?? '';
              String timeStr = '';
              if (createdAt.length >= 16) {
                timeStr = createdAt.substring(11, 16);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Satis #$id',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                          Row(children: [
                            Text(method,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textMuted)),
                            if (timeStr.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(timeStr,
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ]),
                        ]),
                  ),
                  Text(_currencyFormat.format(amount),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success)),
                ]),
              );
            }),
        ]),
      ),
    );
  }

  double _toD(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}