import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/database/comprehensive_database.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  final _db = ComprehensiveDatabase.instance;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    final db = await _db.database;
    final products = await db.rawQuery('''
      SELECT p.*, c.name as categoryName
      FROM products p
      LEFT JOIN categories c ON p.categoryId = c.id
      WHERE p.isActive = 1
      ORDER BY p.name ASC
    ''');

    setState(() {
      _allProducts = products;
      _filteredProducts = products;
      _isLoading = false;
    });
  }

  void _filterProducts() {
    var filtered = _allProducts;

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((p) {
        return p['name'].toLowerCase().contains(query) ||
            (p['sku']?.toLowerCase() ?? '').contains(query);
      }).toList();
    }

    // Stock level filter
    if (_filterType == 'low') {
      filtered = filtered
          .where((p) =>
              (p['stock'] as int) <= (p['minStock'] as int? ?? 5) &&
              (p['stock'] as int) > 0)
          .toList();
    } else if (_filterType == 'critical') {
      filtered = filtered
          .where((p) =>
              (p['stock'] as int) <= (p['criticalStock'] as int? ?? 10))
          .toList();
    } else if (_filterType == 'out') {
      filtered = filtered.where((p) => (p['stock'] as int) == 0).toList();
    }

    setState(() => _filteredProducts = filtered);
  }

  Future<void> _showAdjustmentDialog(Map<String, dynamic> product) async {
    final adjustmentTypeController = ValueNotifier<String>('addition');
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stok Düzenleme - ${product['name']}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current Stock
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Mevcut Stok: ',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '${product['stock']} ${product['unit']}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Adjustment Type
              ValueListenableBuilder(
                valueListenable: adjustmentTypeController,
                builder: (context, value, child) {
                  return SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'addition',
                        label: Text('Ekleme'),
                        icon: Icon(Icons.add),
                      ),
                      ButtonSegment(
                        value: 'reduction',
                        label: Text('Azaltma'),
                        icon: Icon(Icons.remove),
                      ),
                    ],
                    selected: {value},
                    onSelectionChanged: (Set<String> newSelection) {
                      adjustmentTypeController.value = newSelection.first;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Quantity
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Miktar',
                  hintText: '0',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Miktar gereklidir';
                  }
                  final qty = int.tryParse(value);
                  if (qty == null || qty <= 0) {
                    return 'Geçerli bir miktar girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Reason
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Sebep (Opsiyonel)',
                  hintText: 'Düzenleme sebebi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final quantity = int.parse(quantityController.text);
              final isAddition = adjustmentTypeController.value == 'addition';
              final reason = reasonController.text.trim();

              final db = await _db.database;
              final now = DateTime.now().toIso8601String();

              final currentStock = product['stock'] as int;
              final newStock = isAddition
                  ? currentStock + quantity
                  : currentStock - quantity;

              if (newStock < 0) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Stok negatif olamaz'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
                return;
              }

              // Update product stock
              await db.update(
                'products',
                {
                  'stock': newStock,
                  'updatedAt': now,
                },
                where: 'id = ?',
                whereArgs: [product['id']],
              );

              // Record stock movement
              await db.insert('stock_movements', {
                'productId': product['id'],
                'movementType': isAddition ? 'addition' : 'reduction',
                'quantity': isAddition ? quantity : -quantity,
                'previousStock': currentStock,
                'newStock': newStock,
                'reason': reason.isEmpty ? null : reason,
                'createdBy': 'Admin',
                'createdAt': now,
              });

              if (context.mounted) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text(
              'Kaydet',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Stok güncellendi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _viewStockHistory(Map<String, dynamic> product) async {
    final db = await _db.database;
    final movements = await db.query(
      'stock_movements',
      where: 'productId = ?',
      whereArgs: [product['id']],
      orderBy: 'createdAt DESC',
      limit: 50,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stok Geçmişi - ${product['name']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: movements.isEmpty
              ? const Center(child: Text('Hareket kaydı yok'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: movements.length,
                  itemBuilder: (context, index) {
                    final movement = movements[index];
                    final quantity = movement['quantity'] as int;
                    final isPositive = quantity > 0;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPositive
                            ? AppColors.bgSuccess
                            : AppColors.bgDanger,
                        child: Icon(
                          isPositive ? Icons.add : Icons.remove,
                          color:
                              isPositive ? AppColors.success : AppColors.danger,
                        ),
                      ),
                      title: Text(
                        '${isPositive ? '+' : ''}$quantity ${product['unit']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              isPositive ? AppColors.success : AppColors.danger,
                        ),
                      ),
                      subtitle: Text(
                        '${movement['movementType']} - ${movement['reason'] ?? 'Sebep belirtilmemiş'}\n'
                        '${movement['previousStock']} → ${movement['newStock']}',
                      ),
                      trailing: Text(
                        DateTime.parse(movement['createdAt'] as String)
                            .toString()
                            .substring(0, 16),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Stok Yönetimi'),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ürün ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterProducts();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => _filterProducts(),
            ),
          ),

          // Filters
          Container(
            height: 50,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('Tümü', 'all'),
                _buildFilterChip('Düşük Stok', 'low'),
                _buildFilterChip('Kritik', 'critical'),
                _buildFilterChip('Tükendi', 'out'),
              ],
            ),
          ),

          // Statistics
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                _buildStatCard(
                  'Toplam Ürün',
                  _allProducts.length.toString(),
                  Icons.inventory_2_outlined,
                  AppColors.primary,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Düşük Stok',
                  _allProducts
                      .where((p) =>
                          (p['stock'] as int) <= (p['minStock'] as int? ?? 5))
                      .length
                      .toString(),
                  Icons.warning_outlined,
                  AppColors.warning,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Tükenen',
                  _allProducts.where((p) => (p['stock'] as int) == 0).length.toString(),
                  Icons.error_outline,
                  AppColors.danger,
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? const Center(child: Text('Ürün bulunamadı'))
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(_filteredProducts[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _filterType == type,
        onSelected: (selected) {
          setState(() => _filterType = type);
          _filterProducts();
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final stock = product['stock'] as int;
    final minStock = product['minStock'] as int? ?? 5;
    final criticalStock = product['criticalStock'] as int? ?? 10;

    Color stockColor;
    String stockLabel;

    if (stock == 0) {
      stockColor = AppColors.danger;
      stockLabel = 'Tükendi';
    } else if (stock <= criticalStock) {
      stockColor = AppColors.danger;
      stockLabel = 'Kritik';
    } else if (stock <= minStock) {
      stockColor = AppColors.warning;
      stockLabel = 'Düşük';
    } else {
      stockColor = AppColors.success;
      stockLabel = 'Normal';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${product['sku']} | ${product['categoryName'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: stockColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  stockLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: stockColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$stock ${product['unit']}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: stockColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Min: $minStock',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showAdjustmentDialog(product),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Düzenle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _viewStockHistory(product),
                      icon: const Icon(Icons.history, size: 16),
                      label: const Text('Geçmiş'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
