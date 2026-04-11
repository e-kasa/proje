import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
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
      final service = ref.read(salesReportServiceProvider);

      final result = await service.getProfitOverview(
        startDate: _startDate.toIso8601String(),
        endDate: _endDate.toIso8601String(),
      );

      if (result == null) throw Exception('Veri bulunamadi');

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
        AppToast.error(context, 'Veri yuklenemedi');
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

    return AppScaffold(
      appBar: AppAppBar.standard(
        title: 'Kar/Zarar Ozeti',
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
          ? AppEmptyState.noData(description: 'Veri bulunamadi')
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

    final isPositive = profit >= 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
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

        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.danger.withValues(alpha: 0.1),
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
                  color: isPositive
                      ? AppColors.bgSuccess
                      : AppColors.bgDanger,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '%${profitMargin.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                    isPositive ? AppColors.success : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
        ),
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
}