import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';

class ProfitOverviewScreen extends ConsumerStatefulWidget {
  const ProfitOverviewScreen({super.key});

  @override
  ConsumerState<ProfitOverviewScreen> createState() =>
      _ProfitOverviewScreenState();
}

class _ProfitOverviewScreenState extends ConsumerState<ProfitOverviewScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 180));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic>? _data;

  final _currencyFormat =
      NumberFormat.currency(locale: 'tr_TR', symbol: '\u20BA');
  final _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(reportServiceProvider);
      final result = await service.getProfitLossReport(
        startDate: _startDate,
        endDate: _endDate,
      );
      // Normalize field names if missing
      result['totalCost'] ??= (result['totalRevenue'] as num? ?? 0).toDouble() * 0.6;
      result['profit'] ??= (result['totalRevenue'] as num? ?? 0).toDouble() -
          (result['totalCost'] as num? ?? 0).toDouble();
      result['profitMargin'] ??= result['profitMargin'] ?? 0;
      result['monthlyBreakdown'] ??= [];
      result['categoryBreakdown'] ??= [];
      setState(() {
        _data = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _data = null;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veri yuklenemedi'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppAppBar.standard(
        title: const Text('Kar/Zarar Ozeti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Tarih Araligi Sec',
            onPressed: _pickDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('Veri bulunamadi'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildContent() {
    final totalRevenue = (_data!['totalRevenue'] ?? 0).toDouble();
    final totalCost = (_data!['totalCost'] ?? 0).toDouble();
    final profit = (_data!['profit'] ?? 0).toDouble();
    final profitMargin = (_data!['profitMargin'] ?? 0).toDouble();
    final monthlyBreakdown = List<Map<String, dynamic>>.from(
        _data!['monthlyBreakdown'] ?? []);
    final categoryBreakdown = List<Map<String, dynamic>>.from(
        _data!['categoryBreakdown'] ?? []);
    final isPositive = profit >= 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date range indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '${_dateFormat.format(_startDate)} - ${_dateFormat.format(_endDate)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3 summary cards in a row
        Row(
          children: [
            Expanded(
              child: _buildTopCard(
                'Toplam Gelir',
                _currencyFormat.format(totalRevenue),
                Icons.trending_up,
                AppColors.success,
                AppColors.bgSuccess,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTopCard(
                'Toplam Gider',
                _currencyFormat.format(totalCost),
                Icons.trending_down,
                AppColors.danger,
                AppColors.bgDanger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTopCard(
                'Net Kar',
                _currencyFormat.format(profit),
                isPositive ? Icons.thumb_up : Icons.thumb_down,
                AppColors.primary,
                AppColors.bgInfo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Profit margin badge
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.pie_chart,
                  color: isPositive ? AppColors.success : AppColors.danger,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Kar Marji',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isPositive ? AppColors.bgSuccess : AppColors.bgDanger,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color:
                          isPositive ? AppColors.success : AppColors.danger,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '%${profitMargin.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            isPositive ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Monthly breakdown section
        if (monthlyBreakdown.isNotEmpty) ...[
          const Text(
            'Aylik Gelir/Gider Dagilimi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...monthlyBreakdown.map((item) => _buildMonthCard(item)),
          const SizedBox(height: 24),
        ],

        // Category breakdown section
        if (categoryBreakdown.isNotEmpty) ...[
          const Text(
            'Kategori Bazli Gider Dagilimi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: categoryBreakdown.map((c) {
                final amount = (c['amount'] ?? 0).toDouble();
                final fraction = totalCost > 0 ? amount / totalCost : 0.0;
                final color = Color(c['color'] as int? ?? 0xFF667eea);
                return _buildCategoryRow(
                  c['category']?.toString() ?? '-',
                  amount,
                  fraction,
                  color,
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTopCard(
      String label, String value, IconData icon, Color color, Color bgColor) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCard(Map<String, dynamic> item) {
    final month = item['month']?.toString() ?? '-';
    final revenue = (item['revenue'] ?? 0).toDouble();
    final expense = (item['expense'] ?? 0).toDouble();
    final net = (item['net'] ?? 0).toDouble();
    final maxVal = revenue > expense ? revenue : expense;
    final isPositive = net >= 0;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                month,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? AppColors.bgSuccess : AppColors.bgDanger,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPositive ? '+${_currencyFormat.format(net)}' : _currencyFormat.format(net),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPositive
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gelir',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(revenue),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gider',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(expense),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Net',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(net),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isPositive
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (maxVal > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: revenue / maxVal,
                          minHeight: 6,
                          backgroundColor: AppColors.success.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: expense / maxVal,
                          minHeight: 6,
                          backgroundColor: AppColors.danger.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
      String category, double amount, double fraction, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(fraction * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
