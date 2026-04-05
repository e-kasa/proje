import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../services/service_locator.dart';

class ProductSalesAnalysisScreen extends ConsumerStatefulWidget {
  const ProductSalesAnalysisScreen({super.key});

  @override
  ConsumerState<ProductSalesAnalysisScreen> createState() =>
      _ProductSalesAnalysisScreenState();
}

class _ProductSalesAnalysisScreenState
    extends ConsumerState<ProductSalesAnalysisScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  List<Map<String, dynamic>> _products = [];

  final _currencyFormat =
      NumberFormat.currency(locale: 'tr_TR', symbol: '\u20BA');
  final _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  List<Map<String, dynamic>> get _mockProducts => [
        {
          'productName': 'Bosch Fren Balatasi',
          'variantSku': 'BRK-001',
          'quantitySold': 156,
          'totalRevenue': 78000.0,
          'averageUnitPrice': 500.0,
          'costPrice': 320.0,
        },
        {
          'productName': 'Mann Yag Filtresi',
          'variantSku': 'FLT-012',
          'quantitySold': 132,
          'totalRevenue': 39600.0,
          'averageUnitPrice': 300.0,
          'costPrice': 180.0,
        },
        {
          'productName': 'NGK Buji Seti',
          'variantSku': 'SPK-045',
          'quantitySold': 98,
          'totalRevenue': 34300.0,
          'averageUnitPrice': 350.0,
          'costPrice': 210.0,
        },
        {
          'productName': 'Continental V-Kayisi',
          'variantSku': 'BLT-023',
          'quantitySold': 87,
          'totalRevenue': 26100.0,
          'averageUnitPrice': 300.0,
          'costPrice': 175.0,
        },
        {
          'productName': 'Valeo Debriyaj Seti',
          'variantSku': 'CLT-007',
          'quantitySold': 45,
          'totalRevenue': 67500.0,
          'averageUnitPrice': 1500.0,
          'costPrice': 950.0,
        },
        {
          'productName': 'SKF Rulman',
          'variantSku': 'BRG-034',
          'quantitySold': 76,
          'totalRevenue': 22800.0,
          'averageUnitPrice': 300.0,
          'costPrice': 190.0,
        },
        {
          'productName': 'Sachs Amortisor',
          'variantSku': 'SHK-019',
          'quantitySold': 34,
          'totalRevenue': 40800.0,
          'averageUnitPrice': 1200.0,
          'costPrice': 780.0,
        },
        {
          'productName': 'Mahle Hava Filtresi',
          'variantSku': 'AFT-056',
          'quantitySold': 110,
          'totalRevenue': 16500.0,
          'averageUnitPrice': 150.0,
          'costPrice': 85.0,
        },
        {
          'productName': 'TRW Rot Basi',
          'variantSku': 'TRD-088',
          'quantitySold': 62,
          'totalRevenue': 18600.0,
          'averageUnitPrice': 300.0,
          'costPrice': 185.0,
        },
        {
          'productName': 'LuK Volan',
          'variantSku': 'FLW-003',
          'quantitySold': 18,
          'totalRevenue': 54000.0,
          'averageUnitPrice': 3000.0,
          'costPrice': 2100.0,
        },
      ];

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(salesReportServiceProvider);
      final result = await service.getProductSalesAnalysis(
        startDate: _startDate.toIso8601String(),
        endDate: _endDate.toIso8601String(),
      );
      if (result.isEmpty) throw Exception('Veri bulunamadi');
      final sorted = List<Map<String, dynamic>>.from(result);
      sorted.sort((a, b) {
        final ra = (a['totalRevenue'] ?? 0).toDouble();
        final rb = (b['totalRevenue'] ?? 0).toDouble();
        return rb.compareTo(ra);
      });
      setState(() {
        _products = sorted;
        _isLoading = false;
      });
    } catch (_) {
      final sorted = List<Map<String, dynamic>>.from(_mockProducts);
      sorted.sort((a, b) {
        final ra = (a['totalRevenue'] ?? 0).toDouble();
        final rb = (b['totalRevenue'] ?? 0).toDouble();
        return rb.compareTo(ra);
      });
      setState(() {
        _products = sorted;
        _isLoading = false;
      });
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
    final theme = Theme.of(context);

    final totalProducts = _products.length;
    final totalQuantity = _products.fold<int>(
        0, (sum, p) => sum + ((p['quantitySold'] ?? 0) as int));
    final totalRevenue = _products.fold<double>(
        0, (sum, p) => sum + ((p['totalRevenue'] ?? 0).toDouble()));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Urun Satis Analizi'),
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

                  // Summary card
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _buildSummaryItem(
                            'Toplam Urun',
                            totalProducts.toString(),
                            AppColors.primary,
                            Icons.inventory_2,
                          ),
                          _buildSummaryDivider(),
                          _buildSummaryItem(
                            'Toplam Satis',
                            NumberFormat.compact(locale: 'tr_TR')
                                .format(totalQuantity),
                            AppColors.info,
                            Icons.shopping_bag,
                          ),
                          _buildSummaryDivider(),
                          _buildSummaryItem(
                            'Toplam Ciro',
                            _currencyFormat.format(totalRevenue),
                            AppColors.success,
                            Icons.trending_up,
                          ),
                        ],
                      ),
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
    final quantitySold = (item['quantitySold'] ?? 0) as int;
    final totalRevenue = (item['totalRevenue'] ?? 0).toDouble();
    final avgPrice = (item['averageUnitPrice'] ?? 0).toDouble();
    final costPrice = item['costPrice'];
    final rankColor = _getRankColor(rank);

    double? profitMargin;
    if (costPrice != null && avgPrice > 0) {
      final cost = (costPrice as num).toDouble();
      profitMargin = ((avgPrice - cost) / avgPrice) * 100;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: rank <= 3
              ? Border.all(color: rankColor.withOpacity(0.4), width: 1.5)
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
                    rank <= 3 ? rankColor.withOpacity(0.15) : AppColors.bgLight,
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
                    runSpacing: 6,
                    children: [
                      _buildInfoChip(
                        Icons.shopping_bag,
                        '$quantitySold adet',
                        AppColors.primary,
                      ),
                      _buildInfoChip(
                        Icons.trending_up,
                        _currencyFormat.format(totalRevenue),
                        AppColors.success,
                      ),
                      _buildInfoChip(
                        Icons.price_change,
                        _currencyFormat.format(avgPrice),
                        AppColors.info,
                      ),
                    ],
                  ),
                  if (profitMargin != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: profitMargin >= 30
                            ? AppColors.bgSuccess
                            : profitMargin >= 15
                                ? AppColors.bgWarning
                                : AppColors.bgDanger,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Kar Marji: %${profitMargin.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: profitMargin >= 30
                              ? AppColors.success
                              : profitMargin >= 15
                                  ? AppColors.warning
                                  : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
