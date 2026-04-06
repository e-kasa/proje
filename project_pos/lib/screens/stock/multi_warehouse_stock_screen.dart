import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/stock_management_models.dart';
import '../../services/service_locator.dart';

/// MULTI-WAREHOUSE STOK EKRANI
/// Depo/Magaza/Sube bazinda stok goruntuleme
class MultiWarehouseStockScreen extends ConsumerStatefulWidget {
  const MultiWarehouseStockScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MultiWarehouseStockScreen> createState() =>
      _MultiWarehouseStockScreenState();
}

class _MultiWarehouseStockScreenState extends ConsumerState<MultiWarehouseStockScreen> {
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
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = ref.read(stockServiceProvider);
      final data = await service.getStockMovements();
      final items = (data as List).map((item) {
        return WarehouseStockItem.fromJson(item as Map<String, dynamic>);
      }).toList();
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
        return _products.where((p) {
          return p.locationStocks.any((loc) => loc.isLowStock);
        }).toList();
      case 'KRİTİK':
        return _products.where((p) {
          return p.locationStocks.any((loc) => loc.isCriticalStock);
        }).toList();
      case 'TÜKENDİ':
        return _products.where((p) {
          return p.locationStocks.any((loc) => loc.isOutOfStock);
        }).toList();
      default:
        return _products;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppAppBar.standard(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Depo Bazinda Stok',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
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
          // Filtre Butonları
          _buildFilterButtons(),

          // İstatistikler
          _buildStatistics(),

          // Ürün Listesi
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
                    color: isSelected ? Colors.white : Colors.black87,
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
                selectedColor: Colors.blue[700],
                backgroundColor: Colors.grey[200],
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    final totalProducts = _products.length;
    final totalStock = _products.fold<int>(
      0,
      (sum, product) => sum + product.totalStock,
    );
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
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
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
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _expandedProductId =
                    isExpanded ? null : product.productId;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Ürün İkonu
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: Colors.blue[700],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Ürün Bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKU: ${product.sku} • ${product.brand}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.warehouse,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${product.locationStocks.length} Lokasyon',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Toplam Stok Badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Text(
                          '${product.totalStock} ${product.unit}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Genişletilebilir Alan - Lokasyonlar
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 6),
                        Text(
                          'Depo/Mağaza Detayları',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...product.locationStocks
                      .map((loc) => _buildLocationRow(loc))
                      .toList(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(LocationStock location) {
    Color statusColor = Colors.green;
    String statusText = 'İyi';
    IconData statusIcon = Icons.check_circle;

    if (location.isOutOfStock) {
      statusColor = Colors.red;
      statusText = 'Tükendi';
      statusIcon = Icons.cancel;
    } else if (location.isCriticalStock) {
      statusColor = Colors.orange;
      statusText = 'Kritik';
      statusIcon = Icons.warning;
    } else if (location.isLowStock) {
      statusColor = Colors.orange[300]!;
      statusText = 'Düşük';
      statusIcon = Icons.error_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Lokasyon Tipi İkonu
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              location.locationType == LocationType.WAREHOUSE
                  ? Icons.warehouse
                  : location.locationType == LocationType.STORE
                      ? Icons.store
                      : Icons.business,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Lokasyon Bilgileri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.locationName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                if (location.shelfLocation != null)
                  Text(
                    'Raf: ${location.shelfLocation}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),

          // Stok Miktarı ve Durum
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${location.quantity} Adet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                 