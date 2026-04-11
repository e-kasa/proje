import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';

class SalesSummaryScreen extends ConsumerStatefulWidget {
  const SalesSummaryScreen({super.key});

  @override
  ConsumerState<SalesSummaryScreen> createState() => _SalesSummaryScreenState();
}

class _SalesSummaryScreenState extends ConsumerState<SalesSummaryScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  int _selectedPeriod = 0; // 0=Gunluk, 1=Haftalik, 2=Aylik
  bool _isLoading = false;
  Map<String, dynamic>? _data;

  final _currencyFormat =
      NumberFormat.currency(locale: 'tr_TR', symbol: '\u20BA');
  final _dateFormat = DateFormat('dd.MM.yyyy');

  static const _periodLabels = ['Gunluk', 'Haftalik', 'Aylik'];
  static const _periodValues = ['day', 'week', 'month'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(salesReportServiceProvider);
      final result = await service.getSalesSummary(
        startDate: _startDate.toIso8601String(),
        endDate: _endDate.toIso8601String(),
        groupBy: _periodValues[_selectedPeriod],
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
        title: 'Satis Ozeti',
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
              ? AppEmptyState.error(title: 'Veri bulunamadi', onAction: _loadData)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildContent() {
    final totalSalesCount = (_data!['totalSalesCount'] ?? 0).toString();
    final totalRevenue = (_data!['totalRevenue'] ?? 0).toDouble();
    final averageOrderValue = (_data!['averageOrderValue'] ?? 0).toDouble();
    final paymentMethods = List<Map<String, dynamic>>.from(
        _data!['paymentMethods'] ?? []);
    final periodData = List<Map<String, dynamic>>.from(
        _data!['periodData'] ?? []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date range indicator
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

        // Period toggle
        AppCard(
          padding: const EdgeInsets.all(8),
          child: SegmentedButton<int>(
            segments: List.generate(
              3,
              (i) => ButtonSegment<int>(
                value: i,
                label: Text(_periodLabels[i]),
              ),
            ),
            selected: {_selectedPeriod},
            onSelectionChanged: (selected) {
              setState(() => _selectedPeriod = selected.first);
              _loadData();
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return null;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppColors.textSecondary;
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Summary cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Satis Adedi',
                totalSalesCount,
                Icons.receipt_long,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                'Toplam Ciro',
                _currencyFormat.format(totalRevenue),
                Icons.trending_up,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                'Ort. Sepet',
                _currencyFormat.format(averageOrderValue),
                Icons.analytics,
                AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Payment method distribution
        if (paymentMethods.isNotEmpty) ...[
          const Text(
            'Odeme Yontemi Dagilimi',
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
              children: paymentMethods.map((pm) {
                final method = pm['method']?.toString() ?? '-';
                final amount = (pm['amount'] ?? 0).toDouble();
                final percentage = (pm['percentage'] ?? 0).toDouble();
                final color = Color(pm['color'] as int? ?? 0xFF667eea);
                return _buildPaymentMethodRow(
                    method, amount, percentage, color);
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Period data list
        if (periodData.isNotEmpty) ...[
          Text(
            '${_periodLabels[_selectedPeriod]} Veriler',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...periodData.map((item) => _buildPeriodCard(item)),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(
      String label, String value, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
                fontSize: 15,
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

  Widget _buildPaymentMethodRow(
      String method, double amount, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    method,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${_currencyFormat.format(amount)}  (%${percentage.toStringAsFixed(0)})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (percentage / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodCard(Map<String, dynamic> item) {
    final period = item['period']?.toString() ?? '-';
    final revenue = (item['revenue'] ?? 0).toDouble();
    final trend = item['trend']?.toString();

    IconData trendIcon;
    Color trendColor;
    switch (trend) {
      case 'up':
        trendIcon = Icons.trending_up;
        trendColor = AppColors.success;
        break;
      case 'down':
        trendIcon = Icons.trending_down;
        trendColor = AppColors.danger;
        break;
      default:
        trendIcon = Icons.trending_flat;
        trendColor = AppColors.textMuted;
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                period,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Satis: ${(item['salesCount'] ?? 0)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currencyFormat.format(revenue),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: trendColor,
                ),
              ),
              const SizedBox(height: 4),
              Icon(trendIcon, color: trendColor, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}