import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../services/service_locator.dart';

class StockAlertScreen extends ConsumerStatefulWidget {
  const StockAlertScreen({super.key});

  @override
  ConsumerState<StockAlertScreen> createState() => _StockAlertScreenState();
}

class _StockAlertScreenState extends ConsumerState<StockAlertScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = ref.read(stockReportServiceProvider);
      final data = await service.getCriticalAlerts();
      if (!mounted) return;
      setState(() {
        _alerts = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _filterByLevel(String level) {
    return _alerts.where((a) {
      final alertLevel = a['alertLevel']?.toString() ?? '';
      return alertLevel == level;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final criticalList = _filterByLevel('CRITICAL');
    final lowList = _filterByLevel('LOW');
    final outList = _filterByLevel('OUT_OF_STOCK');

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          title: const Text('Stok Uyarilari'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Kritik (${criticalList.length})'),
              Tab(text: 'Dusuk (${lowList.length})'),
              Tab(text: 'Bitmis (${outList.length})'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.danger, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.danger),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadAlerts,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    children: [
                      _buildAlertList(criticalList, 'CRITICAL'),
                      _buildAlertList(lowList, 'LOW'),
                      _buildAlertList(outList, 'OUT_OF_STOCK'),
                    ],
                  ),
      ),
    );
  }

  Widget _buildAlertList(List<Map<String, dynamic>> items, String level) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Bu kategoride uyari yok',
              style: TextStyle(fontSize: 16, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildAlertCard(items[index], level),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert, String level) {
    final productName = alert['productName']?.toString() ?? '-';
    final variantSku = alert['variantSku']?.toString() ?? '';
    final currentQty = alert['currentQuantity'] as num? ?? 0;
    final minThreshold = alert['minimumThreshold'] as num? ?? 0;
    final warehouseId = alert['warehouseId']?.toString() ?? '-';
    final isOutOfStock = level == 'OUT_OF_STOCK';

    Color qtyColor;
    IconData qtyIcon;
    switch (level) {
      case 'CRITICAL':
        qtyColor = AppColors.danger;
        qtyIcon = Icons.warning_amber;
        break;
      case 'LOW':
        qtyColor = AppColors.warning;
        qtyIcon = Icons.trending_down;
        break;
      case 'OUT_OF_STOCK':
        qtyColor = AppColors.danger;
        qtyIcon = Icons.close;
        break;
      default:
        qtyColor = AppColors.textSecondary;
        qtyIcon = Icons.info_outline;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: isOutOfStock ? AppColors.bgDanger : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOutOfStock
                ? AppColors.danger.withOpacity(0.3)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Quantity indicator
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: qtyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(qtyIcon, color: qtyColor, size: 22),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (variantSku.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          variantSku,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Current quantity
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currentQty',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: qtyColor,
                      ),
                    ),
                    Text(
                      'adet',
                      style: TextStyle(fontSize: 11, color: qtyColor),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Bottom row: threshold, warehouse, action
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Min: $minThreshold',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warehouse_outlined,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        warehouseId,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.push('/purchases/create'),
                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                  label: const Text('Siparis Olustur'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
