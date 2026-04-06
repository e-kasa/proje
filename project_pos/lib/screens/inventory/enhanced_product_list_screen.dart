import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../services/service_locator.dart';
import '../../widgets/quick_add_product_modal.dart';
import '../../core/widgets/widgets.dart';

class EnhancedProductListScreen extends ConsumerStatefulWidget {
  const EnhancedProductListScreen({super.key});

  @override
  ConsumerState<EnhancedProductListScreen> createState() =>
      _EnhancedProductListScreenState();
}

class _EnhancedProductListScreenState extends ConsumerState<EnhancedProductListScreen> {
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  Set<int> _selectedProductIds = {};

  String _selectedCategory = 'Tümü';
  String _selectedFilter = 'Tümü';
  bool _isLoading = true;
  bool _isSelectionMode = false;
  bool _isOemSearching = false; // OEM/Capraz Referans ile arama modu

  List<String> _categories = ['Tümü'];

  final List<String> _filters = [
    'Tümü',
    'Düşük Stok',
    'Stokta Yok',
    'Yeni Eklenenler',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final productService = ref.read(productServiceProvider);
      final products = await productService.getProducts();

      // Kategorileri API'den yükle
      try {
        final cats = await ref.read(categoryServiceProvider).getCategories();
        final catNames = cats.map((c) => c['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList();
        if (mounted) {
          setState(() {
            _categories = ['Tümü', ...catNames];
          });
        }
      } catch (e) {
        AppLogger.warning('Kategoriler yüklenemedi', tag: 'ProductList', error: e);
      }

      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    }
  }

  void _filterProducts() {
    var filtered = _allProducts;

    // Search filter
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((p) {
        final query = _searchController.text.toLowerCase();
        return p['name'].toLowerCase().contains(query) ||
            p['sku'].toLowerCase().contains(query) ||
            (p['barcode']?.toLowerCase() ?? '').contains(query);
      }).toList();
    }

    // Category filter
    if (_selectedCategory != 'Tümü') {
      filtered =
          filtered.where((p) => p['category'] == _selectedCategory).toList();
    }

    // Special filters
    if (_selectedFilter == 'Düşük Stok') {
      filtered = filtered
          .where((p) => p['stock'] <= (p['lowStockThreshold'] ?? 10))
          .toList();
    } else if (_selectedFilter == 'Stokta Yok') {
      filtered = filtered.where((p) => p['stock'] == 0).toList();
    } else if (_selectedFilter == 'Yeni Eklenenler') {
      filtered.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
      filtered = filtered.take(20).toList();
    }

    setState(() => _filteredProducts = filtered);
  }

  Future<void> _scanBarcode() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppAppBar.standard(title: const Text('Barkod Okut')),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcode = barcodes.first.rawValue ?? '';
                Navigator.pop(context);
                _searchByBarcode(barcode);
              }
            },
          ),
        ),
      ),
    );
  }

  void _searchByOem(String query) async {
    if (query.length < 3) {
      setState(() => _filteredProducts = []);
      return;
    }
    try {
      final partSearchService = ref.read(partSearchServiceProvider);
      final results = await partSearchService.search(keyword: query);
      setState(() => _filteredProducts = results.map((r) => {
        'id': r['variantId'] ?? r['productId'] ?? '',
        'name': r['productName'] ?? '',
        'sku': r['variantSku'] ?? '',
        'barcode': (r['barcodes'] as List?)?.firstOrNull ?? '',
        'stock': 0,
        'price': r['salePrice'] ?? 0,
        'category': '',
        'unit': 'pcs',
        'lowStockThreshold': 10,
        'isActive': true,
        '_oemNumbers': (r['oemNumbers'] as List?)?.join(', ') ?? '',
        '_crossRefs': (r['crossReferences'] as List?)?.join(', ') ?? '',
      }).toList());
    } catch (e) {
      // Fallback: filtre uygulama
    }
  }

  void _searchByBarcode(String barcode) async {
    try {
      final productService = ref.read(productServiceProvider);
      final products = await productService.getProducts(search: barcode);
      if (products.isNotEmpty) {
        setState(() {
          _filteredProducts = products;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${products.length} ürün bulundu')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ürün bulunamadı')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _exportToCSV() async {
    List<List<dynamic>> rows = [
      ['Ürün Adı', 'SKU', 'Kategori', 'Fiyat', 'Stok', 'Birim']
    ];

    for (var product in _filteredProducts) {
      rows.add([
        product['name'],
        product['sku'],
        product['category'],
        product['price'],
        product['stock'],
        product['unit'],
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/products_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csv);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel dosyası kaydedildi: $path')),
      );
    }
  }

  Future<void> _bulkDelete() async {
    if (_selectedProductIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Toplu Silme'),
        content: Text(
          '${_selectedProductIds.length} ürünü silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final productService = ref.read(productServiceProvider);
        // Delete each product individually
        for (final id in _selectedProductIds) {
          await productService.deleteProduct(id.toString());
        }
        setState(() {
          _selectedProductIds.clear();
          _isSelectionMode = false;
        });
        _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Ürünler silindi'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: ${e.toString()}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppAppBar.standard(
        title: _isSelectionMode
            ? Text('${_selectedProductIds.length} seçili')
            : const Text('Ürünler'),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _bulkDelete,
              tooltip: 'Toplu Sil',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedProductIds.clear();
              }),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: _exportToCSV,
              tooltip: 'Excel İndir',
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _scanBarcode,
              tooltip: 'Barkod Okut',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: AppConstants.pagePadding,
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: _isOemSearching
                          ? 'OEM numarasi veya capraz referans ara...'
                          : 'Urun, SKU veya barkod ara...',
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
                        borderRadius: AppConstants.borderRadiusMedium,
                      ),
                    ),
                    onChanged: (value) {
                      if (_isOemSearching) {
                        _searchByOem(value);
                      } else {
                        _filterProducts();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _isOemSearching ? AppColors.orange.withOpacity(0.15) : AppColors.bgLight,
                    borderRadius: AppConstants.borderRadiusMedium,
                    border: Border.all(
                      color: _isOemSearching ? AppColors.orange : AppColors.border,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.build_circle,
                      color: _isOemSearching ? AppColors.orange : AppColors.textMuted,
                    ),
                    tooltip: 'OEM / Capraz Referans Ara',
                    onPressed: () {
                      setState(() {
                        _isOemSearching = !_isOemSearching;
                        _searchController.clear();
                        if (!_isOemSearching) {
                          _filteredProducts = _allProducts;
                        }
                      });
                    },
                  ),
                ),
              ],
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
                // Category Chips
                ..._categories.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = cat);
                          _filterProducts();
                        },
                        selectedColor: AppColors.primary.withOpacity(0.2),
                      ),
                    )),
                const SizedBox(width: 8),
                // Filter Chips
                ..._filters.map((filter) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: _selectedFilter == filter,
                        onSelected: (selected) {
                          setState(() => _selectedFilter = filter);
                          _filterProducts();
                        },
                        selectedColor: AppColors.warning.withOpacity(0.2),
                      ),
                    )),
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
                          padding: AppConstants.pagePadding,
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final isSelected =
                                _selectedProductIds.contains(product['id']);
                            final isLowStock = product['stock'] <=
                                (product['lowStockThreshold'] ?? 10);

                            return _buildProductCard(
                              product,
                              isSelected,
                              isLowStock,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
        
              onPressed: () async {
                final result = await showQuickAddProductModal(context);
                if (result == true) _loadProducts();
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Hızlı Ekle',
                style: TextStyle(color: Colors.white),
              ),
            ),
    );
  }

  Widget _buildProductCard(
    Map<String, dynamic> product,
    bool isSelected,
    bool isLowStock,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedProductIds.remove(product['id']);
              } else {
                _selectedProductIds.add(product['id']);
              }
            });
          }
        },
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            _selectedProductIds.add(product['id']);
          });
        },
        borderRadius: AppConstants.borderRadiusMedium,
        child: Padding(
          padding: AppConstants.pagePadding,
          child: Row(
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
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
                      'SKU: ${product['sku']}${product['category'] != null && product['category'].toString().isNotEmpty ? ' | ${product['category']}' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    // OEM / Cross Reference bilgisi (OEM arama modunda)
                    if (_isOemSearching && (product['_oemNumbers'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.confirmation_number, size: 12, color: AppColors.orange),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'OEM: ${product['_oemNumbers']}',
                              style: const TextStyle(fontSize: 11, color: AppColors.orange),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_isOemSearching && (product['_crossRefs'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.compare_arrows, size: 12, color: AppColors.info),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Ref: ${product['_crossRefs']}',
                              style: const TextStyle(fontSize: 11, color: AppColors.info),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isLowStock
                                ? AppColors.bgDanger
                                : AppColors.bgSuccess,
                            borderRadius: AppConstants.borderRadiusSmall,
                          ),
                          child: Text(
                            'Stok: ${product['stock']} ${product['unit']}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isLowStock
                                  ? AppColors.danger
                                  : AppColors.success,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${product['price']} ₺',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          