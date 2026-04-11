import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../services/service_locator.dart';
import '../../widgets/quick_add_product_modal.dart';
import '../../core/widgets/widgets.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class EnhancedProductListScreen extends ConsumerStatefulWidget {
  const EnhancedProductListScreen({super.key});

  @override
  ConsumerState<EnhancedProductListScreen> createState() =>
      _EnhancedProductListScreenState();
}

class _EnhancedProductListScreenState
    extends ConsumerState<EnhancedProductListScreen> {
  String Function(String) get t => i18nOf(ref);
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  final Set<int> _selectedProductIds = {};

  String? _selectedCategory;
  String? _selectedStatus;
  bool _isLoading = true;
  bool _isSelectionMode = false;
  bool _isOemSearching = false;

  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final productService = ref.read(productServiceProvider);
      final products = await productService.getProducts();

      try {
        final cats =
            await ref.read(companyCategoryServiceProvider).getMyCategoryList();
        final catNames = cats
            .map((c) => c['categoryName']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
        if (mounted) {
          setState(() => _categories = catNames);
        }
      } catch (e) {
        AppLogger.warning('Kategoriler yüklenemedi',
            tag: 'ProductList', error: e);
      }

      if (mounted) {
        setState(() {
          _allProducts = products;
          _filteredProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, t('common.error'));
      }
    }
  }

  void _filterProducts() {
    var filtered = _allProducts;

    // Search filter
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((p) {
        final query = _searchController.text.toLowerCase();
        return (p['name']?.toString().toLowerCase() ?? '').contains(query) ||
            (p['sku']?.toString().toLowerCase() ?? '').contains(query) ||
            (p['barcode']?.toString().toLowerCase() ?? '').contains(query);
      }).toList();
    }

    // Category filter
    if (_selectedCategory != null) {
      filtered =
          filtered.where((p) => p['category'] == _selectedCategory).toList();
    }

    // Status filter
    if (_selectedStatus != null) {
      filtered =
          filtered.where((p) => p['status'] == _selectedStatus).toList();
    }

    setState(() => _filteredProducts = filtered);
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'DRAFT':
        return t('product.status_draft');
      case 'ACTIVE':
        return t('product.status_active');
      case 'INACTIVE':
        return t('product.status_inactive');
      case 'OUT_OF_STOCK':
        return t('stock.out_of_stock');
      default:
        return status ?? '';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'DRAFT':
        return AppColors.warning;
      case 'ACTIVE':
        return AppColors.success;
      case 'INACTIVE':
        return AppColors.textMuted;
      case 'OUT_OF_STOCK':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  BadgeVariant _getStatusBadgeVariant(String? status) {
    switch (status) {
      case 'DRAFT':
        return BadgeVariant.warning;
      case 'ACTIVE':
        return BadgeVariant.success;
      case 'INACTIVE':
        return BadgeVariant.secondary;
      case 'OUT_OF_STOCK':
        return BadgeVariant.danger;
      default:
        return BadgeVariant.secondary;
    }
  }

  Future<void> _scanBarcode() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppScaffold(
          appBar: AppAppBar.standard(title: t('inventory.scan_barcode')),
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
      if (mounted) {
        setState(() => _filteredProducts = results
            .map((r) => {
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
                  '_oemNumbers':
                      (r['oemNumbers'] as List?)?.join(', ') ?? '',
                  '_crossRefs':
                      (r['crossReferences'] as List?)?.join(', ') ?? '',
                })
            .toList());
      }
    } catch (e) {
      // Fallback
    }
  }

  void _searchByBarcode(String barcode) async {
    try {
      final productService = ref.read(productServiceProvider);
      final products = await productService.getProducts(search: barcode);
      if (mounted) {
        if (products.isNotEmpty) {
          setState(() => _filteredProducts = products);
          AppToast.success(
              context, '${products.length} ${t('common.result_found')}');
        } else {
          AppToast.warning(context, t('common.no_result'));
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, t('common.error'));
      }
    }
  }

  Future<void> _exportToCSV() async {
    List<List<dynamic>> rows = [
      [
        t('product.name'),
        'SKU',
        t('product.category'),
        t('product.price'),
        t('stock.stock'),
        t('product.unit'),
      ]
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
    final path =
        '${directory.path}/products_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csv);

    if (mounted) {
      AppToast.success(context, t('common.export_success'));
    }
  }

  Future<void> _bulkDelete() async {
    if (_selectedProductIds.isEmpty) return;

    final confirmed = await AppConfirmationDialog.showDelete(
      context: context,
      title: t('inventory.bulk_delete'),
      message: t('common.are_you_sure'),
      itemName: '${_selectedProductIds.length} ${t('product.product')}',
    );

    if (!confirmed) return;

    try {
      final productService = ref.read(productServiceProvider);
      for (final id in _selectedProductIds) {
        await productService.deleteProduct(id.toString());
      }
      if (mounted) {
        setState(() {
          _selectedProductIds.clear();
          _isSelectionMode = false;
        });
        _loadProducts();
        AppToast.success(context, t('common.delete_success'));
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, t('common.error'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.standard(
        title: _isSelectionMode
            ? '${_selectedProductIds.length} ${t('inventory.selected')}'
            : t('inventory.products'),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _bulkDelete,
              tooltip: t('inventory.bulk_delete'),
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
              tooltip: t('common.export'),
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _scanBarcode,
              tooltip: t('inventory.scan_barcode'),
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
                          ? t('inventory.search_oem_hint')
                          : t('inventory.search_product_hint'),
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
                    color: _isOemSearching
                        ? AppColors.orange.withValues(alpha: 0.15)
                        : AppColors.bgLight,
                    borderRadius: AppConstants.borderRadiusMedium,
                    border: Border.all(
                      color:
                          _isOemSearching ? AppColors.orange : AppColors.border,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.build_circle,
                      color: _isOemSearching
                          ? AppColors.orange
                          : AppColors.textMuted,
                    ),
                    tooltip: t('inventory.search_oem'),
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
            color: Colors.white,
            child: Column(
              children: [
                // Category chips
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(t('common.all')),
                          selected: _selectedCategory == null,
                          onSelected: (_) {
                            setState(() => _selectedCategory = null);
                            _filterProducts();
                          },
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      ..._categories.map((cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat),
                              selected: _selectedCategory == cat,
                              onSelected: (_) {
                                setState(() => _selectedCategory = cat);
                                _filterProducts();
                              },
                              selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          )),
                    ],
                  ),
                ),
                // Status chips
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(t('common.all')),
                          selected: _selectedStatus == null,
                          onSelected: (_) {
                            setState(() => _selectedStatus = null);
                            _filterProducts();
                          },
                          selectedColor: AppColors.warning.withValues(alpha: 0.2),
                        ),
                      ),
                      ...['DRAFT', 'ACTIVE', 'INACTIVE', 'OUT_OF_STOCK']
                          .map((status) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(_getStatusLabel(status)),
                                  selected: _selectedStatus == status,
                                  onSelected: (_) {
                                    setState(() => _selectedStatus = status);
                                    _filterProducts();
                                  },
                                  selectedColor: _getStatusColor(status)
                                      .withValues(alpha: 0.2),
                                ),
                              )),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // Result count
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.bgLight,
            child: Row(
              children: [
                Text(
                  '${_filteredProducts.length} ${t('product.product')}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_selectedCategory != null || _selectedStatus != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = null;
                        _selectedStatus = null;
                        _searchController.clear();
                      });
                      _filterProducts();
                    },
                    child: Text(
                      t('common.clear_filters'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: _isLoading
                ? const AppSkeletonList(itemCount: 8)
                : _filteredProducts.isEmpty
                    ? AppEmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: t('common.no_result'),
                        actionText: t('inventory.add_product'),
                        onAction: () async {
                          final result =
                              await showQuickAddProductModal(context);
                          if (result == true) _loadProducts();
                        },
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: ListView.builder(
                          padding: AppConstants.pagePadding,
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final idString = product['id']?.toString();
                            final id =
                                int.tryParse(idString ?? '') ?? 0;
                            final isSelected =
                                _selectedProductIds.contains(id);
                            final isLowStock = (product['stock'] ?? 0) <=
                                (product['lowStockThreshold'] ?? 10);

                            return _buildProductCard(
                                product, isSelected, isLowStock);
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
              label: Text(
                t('inventory.quick_add'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
    );
  }

  Widget _buildProductCard(
    Map<String, dynamic> product,
    bool isSelected,
    bool isLowStock,
  ) {
    final idString = product['id']?.toString();
    final id = int.tryParse(idString ?? '') ?? 0;
    final status = product['status']?.toString();
    final imageUrl = product['imageUrl']?.toString();

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
                _selectedProductIds.remove(id);
              } else {
                _selectedProductIds.add(id);
              }
            });
          } else {
            context.go('/inventory/products/$idString');
          }
        },
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            _selectedProductIds.add(id);
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
                    color:
                        isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                ),

              // Product image
              Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: AppConstants.borderRadiusSmall,
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: AppConstants.borderRadiusSmall,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.textMuted,
                            size: 28,
                          ),
                        )
                      : const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.textMuted,
                          size: 28,
                        ),
                ),
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Status badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product['name']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (status != null && status != 'ACTIVE')
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: AppBadge(
                              text: _getStatusLabel(status),
                              variant: _getStatusBadgeVariant(status),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SKU: ${product['sku'] ?? '-'}${product['category'] != null && product['category'].toString().isNotEmpty ? ' | ${product['category']}' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    // OEM info
                    if (_isOemSearching &&
                        (product['_oemNumbers'] ?? '')
                            .toString()
                            .isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.confirmation_number,
                              size: 12, color: AppColors.orange),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'OEM: ${product['_oemNumbers']}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.orange),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_isOemSearching &&
                        (product['_crossRefs'] ?? '')
                            .toString()
                            .isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.compare_arrows,
                              size: 12, color: AppColors.bgInfo,
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Ref: ${product['_crossRefs']}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.bgInfo,
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
                            '${t('stock.stock')}: ${product['stock'] ?? 0} ${product['unit'] ?? ''}',
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
                          _currencyFormat.format(product['price'] ?? 0),
                          style: const TextStyle(
                            fontSize: 14,
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
          ),
        ),
      ),
    );
  }
}
