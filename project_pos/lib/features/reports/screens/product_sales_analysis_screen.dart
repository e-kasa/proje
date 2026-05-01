import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/base_scaffold.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/features/reports/di/reports_di.dart';

class ProductSalesAnalysisScreen extends ConsumerStatefulWidget {
  const ProductSalesAnalysisScreen({super.key});

  @override
  ConsumerState<ProductSalesAnalysisScreen> createState() =>
      _ProductSalesAnalysisScreenState();
}

class _ProductSalesAnalysisScreenState
    extends ConsumerState<ProductSalesAnalysisScreen> {
  String Function(String) get t => i18nOf(ref);

  DateTime get _startDate => ref.watch(productSalesAnalysisProvider).startDate;
  DateTime get _endDate => ref.watch(productSalesAnalysisProvider).endDate;
  bool get _isLoading => ref.watch(productSalesAnalysisProvider).isLoading;
  List<Map<String, dynamic>> get _products {
    final items = List<Map<String, dynamic>>.from(
        ref.watch(productSalesAnalysisProvider).items);
    items.sort((a, b) {
      final ra = (a['totalRevenue'] ?? 0).toDouble();
      final rb = (b['totalRevenue'] ?? 0).toDouble();
      return rb.compareTo(ra);
    });
    return items;
  }

  final _currencyFormat =
      NumberFormat.currency(locale: 'tr_TR', symbol: '\u20BA');
  final _dateFormat = DateFormat('dd.MM.yyyy');

  Future<void> _loadData() =>
      ref.read(productSalesAnalysisProvider.notifier).load();

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      ref
          .read(productSalesAnalysisProvider.notifier)
          .setDateRange(picked.start, picked.end);
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalProducts = _products.length;
    final totalQuantity = _products.fold<int>(
        0, (sum, p) => sum + ((p['quantitySold'] ?? 0) as int));
    final totalRevenue = _products.fold<double>(
        0, (sum, p) => sum + ((p['totalRevenue'] ?? 0).toDouble()));

    return BaseScaffold(
      appBar: AppAppBar.standard(
        title: t('reports.product_analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: t('reports.date_range'),
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
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date range indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

                  // Summary card
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _buildSummaryItem(
                          t('reports.total_products'), // TODO: i18n key: reports.total_products
                          totalProducts.toString(),
                          AppColors.primary,
                          Icons.inventory_2,
                        ),
                        _buildSummaryDivider(),
                        _buildSummaryItem(
                          t('reports.total_sales'), // TODO: i18n key: reports.total_sales
                          NumberFormat.compact(locale: 'tr_TR')
                              .format(totalQuantity),
                          AppColors.info,
                          Icons.shopping_bag,
                        ),
                        _buildSummaryDivider(),
                        _buildSummaryItem(
                          t('reports.total_revenue'), // TODO: i18n key: reports.total_revenue
                          _currencyFormat.format(totalRevenue),
                          AppColors.success,
                          Icons.trending_up,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Product list
                  ..._products.asMap().entries.map(
                      (entry) => _buildProductCard(entry.value, entry.key + 1)),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
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

  Widget _buildSummaryDivider() {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.border,
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item, int rank) {
    final productName = item['productName']?.toString() ?? '-';
    final sku = item['variantSku']?.toString() ?? '-';
    final totalRevenue = (item['totalRevenue'] ?? 0).toDouble();
    final avgPrice = (item['averageUnitPrice'] ?? 0).toDouble();
    final costPrice = item['costPrice'];
    final rankColor = _getRankColor(rank);

    double? profitMargin;
    if (costPrice != null && avgPrice > 0) {
      final cost = (costPrice as num).toDouble();
      profitMargin = ((avgPrice - cost) / avgPrice) * 100;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: rank <= 3
              ? Border.all(color: rankColor.withValues(alpha: 0.4), width: 1.5)
              : null,
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color:
                    rank <= 3 ? rankColor.withValues(alpha: 0.15) : AppColors.bgLight,
                shape: BoxShape.circle,
                border:
                    rank <= 3 ? Border.all(color: rankColor, width: 2) : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? rankColor : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      sku,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Stats row
                  Wrap(
                    spacing: 12,
                    children: [
                      _buildStatItem(
                        label: t('menu.sales'),
                        value: _currencyFormat.format(totalRevenue),
                      ),
                      _buildStatItem(
                        label: t('reports.profit_margin'), // TODO: i18n key: reports.profit_margin
                        value: '$profitMargin%',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

}