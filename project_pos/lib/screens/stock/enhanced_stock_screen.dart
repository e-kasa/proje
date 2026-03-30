import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/data_providers.dart';
import '../../providers/navigation_provider.dart';

class EnhancedStockScreen extends ConsumerStatefulWidget {
  const EnhancedStockScreen({super.key});

  @override
  ConsumerState<EnhancedStockScreen> createState() => _EnhancedStockScreenState();
}

class _EnhancedStockScreenState extends ConsumerState<EnhancedStockScreen> {
  final _searchController = TextEditingController();
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    // Ekrana her dönüşte (navigate-back dahil) veriyi yenile.
    // stockProvider non-autoDispose → constructor tekrar çalışmaz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stockProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> all) {
    var filtered = all;

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((p) {
        return (p['name']?.toString().toLowerCase() ?? '').contains(query) ||
            (p['barcode']?.toString().toLowerCase() ?? '').contains(query);
      }).toList();
    }

    switch (_filterType) {
      case 'critical':
        filtered = filtered.where((p) {
          final s = p['stock'] as num? ?? 0;
          return s > 0 && s <= 5;
        }).toList();
        break;
      case 'low':
        filtered = filtered.where((p) {
          final s = p['stock'] as num? ?? 0;
          return s > 5 && s <= 20;
        }).toList();
        break;
      case 'out':
        filtered = filtered.where((p) => (p['stock'] as num? ?? 0) == 0).toList();
        break;
      case 'good':
        filtered = filtered.where((p) => (p['stock'] as num? ?? 0) > 20).toList();
        break;
    }

    return filtered;
  }

  Color _getStockColor(num stock) {
    if (stock == 0) return AppColors.danger;
    if (stock <= 5) return AppColors.warning;
    if (stock <= 20) return AppColors.info;
    return AppColors.success;
  }

  String _getStockLabel(num stock) {
    if (stock == 0) return 'Tükendi';
    if (stock <= 5) return 'Kritik';
    if (stock <= 20) return 'Düşük';
    return 'İyi';
  }

  void _onQuickSell(Map<String, dynamic> product) {
    context.go('/pos');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} satış ekranına eklendi'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onEditProduct(Map<String, dynamic> product) {
    final stockController = TextEditingController(text: '${product['stock'] ?? 0}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stok Düzenle - ${product['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stockController,
              decoration: const InputDecoration(
                labelText: 'Yeni Stok Miktarı',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newQty = int.tryParse(stockController.text);
              if (newQty == null || newQty < 0) return;
              Navigator.pop(context);

              final productId = product['id']?.toString();
              if (productId == null) return;

              final success = await ref.read(stockProvider.notifier).adjustStock(
                    productId: productId,
                    newQuantity: newQty,
                    reason: 'manual_adjustment',
                  );

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Stok güncellendi' : 'Güncelleme başarısız'),
                  backgroundColor: success ? AppColors.success : AppColors.danger,
                ),
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Aynı menüye ikinci tıklamada yenile
    ref.listen(navigationRefreshProvider, (prev, next) {
      if (next.route == '/stock') ref.read(stockProvider.notifier).load();
    });

    final stockState = ref.watch(stockProvider);
    final filtered = _applyFilters(stockState.products);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Column(
        children: [
          // Header with filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Ürün ara...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    filled: true,
                    fillColor: AppColors.bgLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 12),

                // Quick Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tümü', 'all', Icons.grid_view),
                      const SizedBox(width: 8),
                      _buildFilterChip('Kritik', 'critical', Icons.warning_amber, AppColors.danger),
                      const SizedBox(width: 8),
                      _buildFilterChip('Düşük', 'low', Icons.trending_down, AppColors.warning),
                      const SizedBox(width: 8),
                      _buildFilterChip('Tükenen', 'out', Icons.close, AppColors.danger),
                      const SizedBox(width: 8),
                      _buildFilterChip('İyi', 'good', Icons.check_circle, AppColors.success),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stock Stats Summary
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _buildStatCard(
                  'Toplam',
                  '${stockState.totalCount}',
                  Colors.blue,
                  Icons.inventory_2,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Kritik',
                  '${stockState.criticalCount}',
                  AppColors.danger,
                  Icons.warning_amber,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Düşük',
                  '${stockState.lowCount}',
                  AppColors.warning,
                  Icons.trending_down,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Product List
          Expanded(
            child: stockState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : stockState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              stockState.error!,
                              style: const TextStyle(color: AppColors.danger),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => ref.read(stockProvider.notifier).load(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tekrar Dene'),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted),
                                const SizedBox(height: 16),
                                Text(
                                  'Ürün bulunamadı',
                                  style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref.read(stockProvider.notifier).load(),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) =>
                                  _buildProductCard(filtered[index]),
                            ),
                          ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stok sayım özelliği yakında eklenecek'),
              backgroundColor: AppColors.info,
            ),
          );
        },
        icon: const Icon(Icons.inventory),
        label: const Text('Stok Sayım'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon, [Color? color]) {
    final isSelected = _filterType == value;
    final chipColor = color ?? AppColors.primary;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : chipColor),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterType = value),
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : chipColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(color: chipColor),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(label, style: TextStyle(fontSize: 11, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final stock = product['stock'] as num? ?? 0;
    final stockColor = _getStockColor(stock);
    final stockLabel = _getStockLabel(stock);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(product['id'].toString()),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            _onQuickSell(product);
          } else {
            _onEditProduct(product);
          }
          return false;
        },
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart, color: Colors.white, size: 32),
              SizedBox(height: 4),
              Text('Hızlı Sat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: AppColors.info,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit, color: Colors.white, size: 32),
              SizedBox(height: 4),
              Text('Düzenle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: stockColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.inventory_2, color: stockColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: stockColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              stockLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: stockColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₺${(product['sellingPrice'] as num? ?? product['price'] as num? ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$stock',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: stockColor,
                      ),
                    ),
                    Text('adet', style: TextStyle(fontSize: 11, color: stockColor)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
