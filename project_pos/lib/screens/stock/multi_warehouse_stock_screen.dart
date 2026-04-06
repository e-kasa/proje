import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/stock_management_models.dart';
import '../../services/service_locator.dart';
import '../../core/widgets/app_app_bar.dart';
import '../../core/theme/app_colors.dart';

/// MULTI-WAREHOUSE STOK EKRANI
/// Depo/Magaza/Sube bazinda stok goruntuleme
class MultiWarehouseStockScreen extends ConsumerStatefulWidget {
  const MultiWarehouseStockScreen({super.key});

  @override
  ConsumerState<MultiWarehouseStockScreen> createState() =>
      _MultiWarehouseStockScreenState();
}

class _MultiWarehouseStockScreenState
    extends ConsumerState<MultiWarehouseStockScreen> {
  List<WarehouseStockItem> _products = [];
  bool _isLoading = true;
  String? _error;
  String _filterType = 'TÜMÜ';
  String? _expandedProductId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(stockServiceProvider);
      final data = await service.getStockMovements();

      final items = (data as List)
          .map((item) =>
          WarehouseStockItem.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _products = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _products = [];
        _error = 'Veri yuklenemedi';
        _isLoading = false;
      });
    }
  }

  List<WarehouseStockItem> get _filteredProducts {
    switch (_filterType) {
      case 'DÜŞÜK STOK':
        return _products
            .where((p) => p.locationStocks.any((loc) => loc.isLowStock))
            .toList();

      case 'KRİTİK':
        return _products
            .where((p) => p.locationStocks.any((loc) => loc.isCriticalStock))
            .toList();

      case 'TÜKENDİ':
        return _products
            .where((p) => p.locationStocks.any((loc) => loc.isOutOfStock))
            .toList();

      default:
        return _products;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppAppBar.standard(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: 'Depo Bazinda Stok',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Column(
        children: [
          _buildFilterButtons(),
          _buildStatistics(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(_filteredProducts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    final filters = ['TÜMÜ', 'DÜŞÜK STOK', 'KRİTİK', 'TÜKENDİ'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _filterType == filter;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _filterType = filter;
                  });
                },
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.bgLight,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    final totalProducts = _products.length;

    final totalStock =
    _products.fold<int>(0, (sum, product) => sum + product.totalStock);

    final lowStockCount = _products
        .where((p) => p.locationStocks.any((loc) => loc.isLowStock))
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Toplam Ürün',
              totalProducts.toString(),
              Icons.inventory_2,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Toplam Stok',
              totalStock.toString(),
              Icons.warehouse,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Düşük Stok',
              lowStockCount.toString(),
              Icons.warning,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(WarehouseStockItem product) {
    final isExpanded = _expandedProductId == product.productId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedProductId = isExpanded ? null : product.productId;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2, color: AppColors.textPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      product.productName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                  Text('${product.totalStock} ${product.unit}', style: const TextStyle(color: AppColors.textPrimary))
                ],
              ),
            ),
          ),
          if (isExpanded)
            Column(
              children: product.locationStocks
                  .map((loc) => _buildLocationRow(loc))
                  .toList(),
            )
        ],
      ),
    );
  }

  Widget _buildLocationRow(LocationStock location) {
    Color statusColor = AppColors.success;
    IconData statusIcon = Icons.check_circle;

    if (location.isOutOfStock) {
      statusColor = AppColors.danger;
      statusIcon = Icons.cancel;
    } else if (location.isCriticalStock) {
      statusColor = AppColors.warning;
      statusIcon = Icons.warning;
    } else if (location.isLowStock) {
      statusColor = AppColors.warning;
      statusIcon = Icons.error_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(location.locationName, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
          Text(
            '${location.quantity} Adet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: statusColor,
              fontSize: 13,
            ),
          )
        ],
      ),
    );
  }
}
