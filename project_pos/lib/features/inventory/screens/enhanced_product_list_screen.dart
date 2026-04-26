import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/utils/app_logger.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/widgets/quick_add_product_modal.dart';
import 'package:project_pos/core/widgets/widgets.dart';
// Sprint 12: ortak kart component (W2'de _buildListCard tam migration)
// ignore: unused_import
import 'package:project_pos/core/widgets/product_card.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

// ── Sıralama seçenekleri ──────────────────────────────────────────────────────
enum _SortBy { nameAsc, nameDesc, priceAsc, priceDesc, stockAsc, stockDesc }

// ── Görünüm modu ──────────────────────────────────────────────────────────────
enum _ViewMode { list, grid }

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
  Timer? _debounceTimer;

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  final Set<int> _selectedProductIds = {};
  List<String> _categories = [];

  String? _selectedCategory;
  String? _selectedStatus;
  _SortBy _sortBy = _SortBy.nameAsc;
  _ViewMode _viewMode = _ViewMode.list;

  bool _isLoading = true;
  bool _isSelectionMode = false;
  bool _isOemSearching = false;

  int get _activeFilterCount =>
      (_selectedCategory != null ? 1 : 0) + (_selectedStatus != null ? 1 : 0);

  String get _sortShortLabel {
    switch (_sortBy) {
      case _SortBy.nameAsc:   return 'A→Z';
      case _SortBy.nameDesc:  return 'Z→A';
      case _SortBy.priceAsc:  return '₺↑';
      case _SortBy.priceDesc: return '₺↓';
      case _SortBy.stockAsc:  return '📦↑';
      case _SortBy.stockDesc: return '📦↓';
    }
  }

  int get _lowStockCount => _allProducts.where((p) {
    final s = (p['stock'] as num?)?.toInt() ?? 0;
    final thr = (p['lowStockThreshold'] as num?)?.toInt() ?? 10;
    return s > 0 && s <= thr;
  }).length;

  int get _outOfStockCount =>
      _allProducts.where((p) => (p['stock'] as num?)?.toInt() == 0).length;

  // ── Yaşam döngüsü ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ── Veri yükleme ──────────────────────────────────────────────────────────

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
        if (mounted) setState(() => _categories = catNames);
      } catch (e) {
        AppLogger.warning('Kategoriler yüklenemedi',
            tag: 'ProductList', error: e);
      }

      if (mounted) {
        setState(() {
          _allProducts = products;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, t('common.error'));
      }
    }
  }

  // ── Arama & filtreleme ────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_isOemSearching) {
        if (value.length >= 3) {
          _searchByOem(value);
        } else {
          setState(() => _filteredProducts = _allProducts);
        }
      } else {
        _applyFilters();
      }
    });
  }

  void _applyFilters() {
    var filtered = _allProducts;

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where((p) =>
              (p['name']?.toString().toLowerCase() ?? '').contains(query) ||
              (p['sku']?.toString().toLowerCase() ?? '').contains(query) ||
              (p['barcode']?.toString().toLowerCase() ?? '').contains(query))
          .toList();
    }

    if (_selectedCategory != null) {
      filtered =
          filtered.where((p) => p['category'] == _selectedCategory).toList();
    }

    if (_selectedStatus != null) {
      filtered =
          filtered.where((p) => p['status'] == _selectedStatus).toList();
    }

    // Sıralama
    filtered.sort((a, b) {
      switch (_sortBy) {
        case _SortBy.nameAsc:
          return (a['name'] ?? '').toString().compareTo(
              (b['name'] ?? '').toString());
        case _SortBy.nameDesc:
          return (b['name'] ?? '').toString().compareTo(
              (a['name'] ?? '').toString());
        case _SortBy.priceAsc:
          return ((a['price'] ?? 0) as num)
              .compareTo((b['price'] ?? 0) as num);
        case _SortBy.priceDesc:
          return ((b['price'] ?? 0) as num)
              .compareTo((a['price'] ?? 0) as num);
        case _SortBy.stockAsc:
          return ((a['stock'] ?? 0) as num)
              .compareTo((b['stock'] ?? 0) as num);
        case _SortBy.stockDesc:
          return ((b['stock'] ?? 0) as num)
              .compareTo((a['stock'] ?? 0) as num);
      }
    });

    setState(() => _filteredProducts = filtered);
  }

  // ── Bottom Sheet'ler ──────────────────────────────────────────────────────

  void _showSortSheet() {
    final options = [
      (_SortBy.nameAsc,   t('inventory.sort_name_az')),
      (_SortBy.nameDesc,  t('inventory.sort_name_za')),
      (_SortBy.priceAsc,  t('inventory.sort_price_asc')),
      (_SortBy.priceDesc, t('inventory.sort_price_desc')),
      (_SortBy.stockAsc,  t('inventory.sort_stock_asc')),
      (_SortBy.stockDesc, t('inventory.sort_stock_desc')),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BottomSheetHandle(),
              Text(t('inventory.sort'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 4),
              ...options.map((opt) => _SortTile(
                    label: opt.$2,
                    selected: _sortBy == opt.$1,
                    onTap: () {
                      setState(() => _sortBy = opt.$1);
                      _applyFilters();
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    String? pendingCat = _selectedCategory;
    String? pendingStatus = _selectedStatus;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BottomSheetHandle(),
                Row(
                  children: [
                    Expanded(
                      child: Text(t('common.filter'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          )),
                    ),
                    TextButton(
                      onPressed: () => setSheetState(() {
                        pendingCat = null;
                        pendingStatus = null;
                      }),
                      child: Text(t('common.clear_filters'),
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Kategori
                if (_categories.isNotEmpty) ...[
                  Text(t('product.category'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      )),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _SheetChip(
                        label: t('common.all'),
                        selected: pendingCat == null,
                        onTap: () =>
                            setSheetState(() => pendingCat = null),
                      ),
                      ..._categories.map((cat) => _SheetChip(
                            label: cat,
                            selected: pendingCat == cat,
                            onTap: () => setSheetState(() =>
                                pendingCat = pendingCat == cat ? null : cat),
                          )),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                // Durum
                Text(t('common.status'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    )),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _SheetChip(
                      label: t('common.all'),
                      selected: pendingStatus == null,
                      onTap: () =>
                          setSheetState(() => pendingStatus = null),
                    ),
                    ...['ACTIVE', 'DRAFT', 'INACTIVE', 'OUT_OF_STOCK']
                        .map((s) => _SheetChip(
                              label: _getStatusLabel(s),
                              selected: pendingStatus == s,
                              color: _getStatusColor(s),
                              onTap: () => setSheetState(() => pendingStatus =
                                  pendingStatus == s ? null : s),
                            )),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedCategory = pendingCat;
                        _selectedStatus = pendingStatus;
                      });
                      _applyFilters();
                      Navigator.pop(ctx);
                    },
                    child: Text(t('common.apply'),
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Diğer eylemler ────────────────────────────────────────────────────────

  Future<void> _scanBarcode() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppScaffold(
          appBar: AppAppBar.standard(title: t('inventory.scan_barcode')),
          body: MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
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
                  'unit': 'adet',
                  'lowStockThreshold': 10,
                  'isActive': true,
                  '_oemNumbers':
                      (r['oemNumbers'] as List?)?.join(', ') ?? '',
                  '_crossRefs':
                      (r['crossReferences'] as List?)?.join(', ') ?? '',
                })
            .toList());
      }
    } catch (_) {
      // Sessiz hata — OEM servisi opsiyonel
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
      if (mounted) AppToast.error(context, t('common.error'));
    }
  }

  Future<void> _exportToCSV() async {
    final rows = [
      [
        t('product.name'),
        'SKU',
        t('product.category'),
        t('product.price'),
        t('stock.stock'),
        t('product.unit'),
      ],
      ..._filteredProducts.map((p) => [
            p['name'],
            p['sku'],
            p['category'],
            p['price'],
            p['stock'],
            p['unit'],
          ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/products_${DateTime.now().millisecondsSinceEpoch}.csv';
    await File(path).writeAsString(csv);

    if (mounted) AppToast.success(context, t('common.export_success'));
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
      if (mounted) AppToast.error(context, t('common.error'));
    }
  }

  // ── Yardımcı metodlar ─────────────────────────────────────────────────────

  String _getStatusLabel(String? status) => switch (status) {
        'DRAFT' => t('product.status_draft'),
        'ACTIVE' => t('product.status_active'),
        'INACTIVE' => t('product.status_inactive'),
        'OUT_OF_STOCK' => t('stock.out_of_stock'),
        _ => status ?? '',
      };

  Color _getStatusColor(String? status) => switch (status) {
        'DRAFT' => AppColors.warning,
        'ACTIVE' => AppColors.success,
        'INACTIVE' => AppColors.textMuted,
        'OUT_OF_STOCK' => AppColors.danger,
        _ => AppColors.textMuted,
      };

  BadgeVariant _getStatusBadgeVariant(String? status) => switch (status) {
        'DRAFT' => BadgeVariant.warning,
        'ACTIVE' => BadgeVariant.success,
        'INACTIVE' => BadgeVariant.secondary,
        'OUT_OF_STOCK' => BadgeVariant.danger,
        _ => BadgeVariant.secondary,
      };

  // ── Build ─────────────────────────────────────────────────────────────────

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
          _buildSearchBar(),
          if (!_isLoading && _allProducts.isNotEmpty && !_isOemSearching)
            _buildStatsBar(),
          if (!_isLoading && _categories.isNotEmpty && !_isOemSearching)
            _buildCategoryChips(),
          _buildFilterBar(),
          Expanded(child: _buildContent()),
          if (_isSelectionMode) _buildSelectionBottomBar(),
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
              label: Text(t('inventory.quick_add'),
                  style: const TextStyle(color: Colors.white)),
            ),
    );
  }

  // ── İstatistik bar ────────────────────────────────────────────────────────

  Widget _buildStatsBar() {
    final total    = _allProducts.length;
    final lowStock = _lowStockCount;
    final outStock = _outOfStockCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      color: AppColors.bgWhite,
      child: Row(
        children: [
          _StatPill(
            icon: Icons.inventory_2_rounded,
            count: '$total',
            label: t('product.product'),
            color: AppColors.primary,
          ),
          if (lowStock > 0) ...[
            const SizedBox(width: 8),
            _StatPill(
              icon: Icons.warning_amber_rounded,
              count: '$lowStock',
              label: t('stock.low_stock'),
              color: AppColors.warning,
              onTap: () {
                setState(() {
                  _selectedStatus = null;
                  _selectedCategory = null;
                });
                _searchController.text = '';
                // Düşük stok filtresi — filteredProducts'ı direkt göster
                setState(() {
                  _filteredProducts = _allProducts.where((p) {
                    final s   = (p['stock'] as num?)?.toInt() ?? 0;
                    final thr = (p['lowStockThreshold'] as num?)?.toInt() ?? 10;
                    return s > 0 && s <= thr;
                  }).toList();
                });
              },
            ),
          ],
          if (outStock > 0) ...[
            const SizedBox(width: 8),
            _StatPill(
              icon: Icons.remove_shopping_cart_rounded,
              count: '$outStock',
              label: t('stock.out_of_stock'),
              color: AppColors.danger,
              onTap: () {
                setState(() {
                  _selectedStatus = 'OUT_OF_STOCK';
                  _selectedCategory = null;
                });
                _searchController.text = '';
                _applyFilters();
              },
            ),
          ],
        ],
      ),
    );
  }

  // ── Kategori hızlı chips ──────────────────────────────────────────────────

  Widget _buildCategoryChips() {
    return Container(
      height: 36,
      color: AppColors.bgWhite,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _CategoryChip(
            label: t('common.all'),
            selected: _selectedCategory == null,
            onTap: () {
              if (_selectedCategory != null) {
                setState(() => _selectedCategory = null);
                _applyFilters();
              }
            },
          ),
          const SizedBox(width: 6),
          ..._categories.map((cat) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _CategoryChip(
              label: cat,
              selected: _selectedCategory == cat,
              onTap: () {
                setState(() =>
                    _selectedCategory = _selectedCategory == cat ? null : cat);
                _applyFilters();
              },
            ),
          )),
        ],
      ),
    );
  }

  // ── Seçim modu alt çubuğu ─────────────────────────────────────────────────

  Widget _buildSelectionBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -3)),
        ],
      ),
      child: Row(
        children: [
          // Seçim sayısı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_selectedProductIds.length} ${t('inventory.selected')}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 13),
            ),
          ),
          const Spacer(),
          // Tümünü seç
          TextButton.icon(
            onPressed: () => setState(() {
              if (_selectedProductIds.length == _filteredProducts.length) {
                _selectedProductIds.clear();
              } else {
                _selectedProductIds.addAll(
                  _filteredProducts.map(
                    (p) => int.tryParse(p['id']?.toString() ?? '') ?? 0,
                  ),
                );
              }
            }),
            icon: Icon(
              _selectedProductIds.length == _filteredProducts.length
                  ? Icons.deselect_rounded
                  : Icons.select_all_rounded,
              size: 18,
            ),
            label: Text(
              _selectedProductIds.length == _filteredProducts.length
                  ? t('common.clear')
                  : t('common.select_all'),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          // Sil
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.delete_rounded, color: Colors.white, size: 18),
            label: Text(t('common.delete'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            onPressed: _bulkDelete,
          ),
        ],
      ),
    );
  }

  // ── Arama çubuğu ─────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      padding: AppConstants.pagePadding,
      color: AppColors.bgWhite,
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
                          if (_isOemSearching) {
                            setState(() => _filteredProducts = _allProducts);
                          } else {
                            _applyFilters();
                          }
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: AppConstants.borderRadiusMedium),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(width: 8),
          // OEM toggle
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
              icon: Icon(Icons.build_circle,
                  color: _isOemSearching
                      ? AppColors.orange
                      : AppColors.textMuted),
              tooltip: t('inventory.search_oem'),
              onPressed: () {
                setState(() {
                  _isOemSearching = !_isOemSearching;
                  _searchController.clear();
                  if (!_isOemSearching) {
                    _applyFilters();
                  } else {
                    _filteredProducts = _allProducts;
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Kompakt filtre çubuğu ─────────────────────────────────────────────────

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Sırala (aktif sıralamayı göster)
          _CompactBarButton(
            icon: Icons.sort_rounded,
            label: _sortBy == _SortBy.nameAsc
                ? t('inventory.sort')
                : _sortShortLabel,
            active: _sortBy != _SortBy.nameAsc,
            onTap: _showSortSheet,
          ),
          const SizedBox(width: 6),
          // Filtrele (badge'li)
          Stack(
            clipBehavior: Clip.none,
            children: [
              _CompactBarButton(
                icon: Icons.tune_rounded,
                label: t('common.filter'),
                active: _activeFilterCount > 0,
                onTap: _showFilterSheet,
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_activeFilterCount',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          // Sonuç sayısı
          Expanded(
            child: Text(
              '${_filteredProducts.length} ${t('product.product')}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          // Filtre temizle
          if (_activeFilterCount > 0) ...[
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = null;
                  _selectedStatus = null;
                  _searchController.clear();
                });
                _applyFilters();
              },
              child: const Icon(Icons.filter_alt_off_rounded,
                  size: 18, color: AppColors.danger),
            ),
            const SizedBox(width: 8),
          ],
          // Görünüm toggle
          GestureDetector(
            onTap: () => setState(() => _viewMode =
                _viewMode == _ViewMode.list ? _ViewMode.grid : _ViewMode.list),
            child: Icon(
              _viewMode == _ViewMode.list
                  ? Icons.grid_view_rounded
                  : Icons.view_list_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── İçerik ────────────────────────────────────────────────────────────────

  Widget _buildContent() {
    if (_isLoading) return const AppSkeletonList(itemCount: 8);

    if (_filteredProducts.isEmpty) {
      return AppEmptyState(
        icon: Icons.inventory_2_outlined,
        title: t('common.no_result'),
        actionText: t('inventory.add_product'),
        onAction: () async {
          final result = await showQuickAddProductModal(context);
          if (result == true) _loadProducts();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: _viewMode == _ViewMode.list ? _buildListView() : _buildGridView(),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: AppConstants.pagePadding,
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final id = int.tryParse(product['id']?.toString() ?? '') ?? 0;
        final isSelected = _selectedProductIds.contains(id);
        final stock = (product['stock'] ?? 0) as num;
        final threshold = (product['lowStockThreshold'] ?? 10) as num;
        return _buildListCard(
            product, isSelected, stock > 0 && stock <= threshold);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: AppConstants.pagePadding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final id = int.tryParse(product['id']?.toString() ?? '') ?? 0;
        final isSelected = _selectedProductIds.contains(id);
        final stock = (product['stock'] ?? 0) as num;
        final threshold = (product['lowStockThreshold'] ?? 10) as num;
        return _buildGridCard(
            product, isSelected, stock > 0 && stock <= threshold);
      },
    );
  }

  // ── Liste kartı ───────────────────────────────────────────────────────────

  Widget _buildListCard(
    Map<String, dynamic> product,
    bool isSelected,
    bool isLowStock,
  ) {
    final idString = product['id']?.toString();
    final id       = int.tryParse(idString ?? '') ?? 0;
    final status   = product['status']?.toString();
    final imageUrl = product['imageUrl']?.toString();
    final stock    = (product['stock'] ?? 0) as num;
    final isOutOfStock = stock == 0;
    final price    = product['price'] ?? 0;
    final sku      = product['sku']?.toString() ?? '';
    final category = product['category']?.toString() ?? '';

    final accentColor = isSelected
        ? AppColors.primary
        : isOutOfStock
            ? AppColors.danger
            : isLowStock
                ? AppColors.warning
                : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sol renk aksanı (stok/seçim durumu)
              if (accentColor != null) Container(width: 4, color: accentColor),
              // İçerik
              Expanded(
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
                  onLongPress: () => setState(() {
                    _isSelectionMode = true;
                    _selectedProductIds.add(id);
                  }),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Seçim ikonu
                        if (_isSelectionMode)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              size: 22,
                            ),
                          ),

                        // Ürün görseli
                        Container(
                          width: 68, height: 68,
                          decoration: BoxDecoration(
                            color: AppColors.bgLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.6)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, st) =>
                                        _productIconPlaceholder(),
                                  )
                                : _productIconPlaceholder(),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Bilgiler
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // İsim + fiyat
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      product['name']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        height: 1.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _currencyFormat.format(price),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // SKU · Kategori
                              Row(
                                children: [
                                  if (sku.isNotEmpty)
                                    Text('SKU: $sku',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textMuted)),
                                  if (sku.isNotEmpty && category.isNotEmpty)
                                    const Text(' · ',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textMuted)),
                                  if (category.isNotEmpty)
                                    Expanded(
                                      child: Text(
                                        category,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textMuted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),

                              // OEM satırları (yalnızca OEM modunda)
                              if (_isOemSearching &&
                                  (product['_oemNumbers'] ?? '')
                                      .toString()
                                      .isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(children: [
                                  const Icon(Icons.confirmation_number,
                                      size: 11, color: AppColors.orange),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text('OEM: ${product['_oemNumbers']}',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.orange),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ]),
                              ],
                              if (_isOemSearching &&
                                  (product['_crossRefs'] ?? '')
                                      .toString()
                                      .isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(children: [
                                  const Icon(Icons.compare_arrows,
                                      size: 11, color: AppColors.info),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text('Ref: ${product['_crossRefs']}',
                                        style: const TextStyle(
                                            fontSize: 10, color: AppColors.info),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ]),
                              ],
                              const SizedBox(height: 6),

                              // Stok chip + durum badge
                              Row(
                                children: [
                                  _StockChip(
                                    stock: stock.toInt(),
                                    unit: product['unit']?.toString() ?? '',
                                    isOutOfStock: isOutOfStock,
                                    isLowStock: isLowStock,
                                    stockLabel: t('stock.stock'),
                                  ),
                                  if (status != null && status != 'ACTIVE') ...[
                                    const SizedBox(width: 6),
                                    AppBadge(
                                      text: _getStatusLabel(status),
                                      variant: _getStatusBadgeVariant(status),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productIconPlaceholder() => Container(
    color: AppColors.bgLight,
    child: const Center(
      child: Icon(Icons.inventory_2_outlined, color: AppColors.border, size: 28),
    ),
  );

  // ── Grid kartı ────────────────────────────────────────────────────────────

  Widget _buildGridCard(
    Map<String, dynamic> product,
    bool isSelected,
    bool isLowStock,
  ) {
    final idString = product['id']?.toString();
    final id       = int.tryParse(idString ?? '') ?? 0;
    final status   = product['status']?.toString();
    final imageUrl = product['imageUrl']?.toString();
    final stock    = (product['stock'] ?? 0) as num;
    final isOutOfStock = stock == 0;
    final price    = product['price'] ?? 0;

    return GestureDetector(
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
      onLongPress: () => setState(() {
        _isSelectionMode = true;
        _selectedProductIds.add(id);
      }),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Görsel bölümü ──────────────────────────────────────────
              Expanded(
                flex: 60,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Görsel
                    imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => Container(
                              color: AppColors.bgLight,
                              child: const Center(
                                child: Icon(Icons.inventory_2_outlined,
                                    color: AppColors.border, size: 36),
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.bgLight,
                            child: const Center(
                              child: Icon(Icons.inventory_2_outlined,
                                  color: AppColors.border, size: 36),
                            ),
                          ),
                    // Alt gradient
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 48,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0x33000000)],
                          ),
                        ),
                      ),
                    ),
                    // Durum badge (sağ üst)
                    if (status != null && status != 'ACTIVE')
                      Positioned(
                        top: 6, right: 6,
                        child: AppBadge(
                          text: _getStatusLabel(status),
                          variant: _getStatusBadgeVariant(status),
                        ),
                      ),
                    // Seçim ikonu (sol üst)
                    if (_isSelectionMode)
                      Positioned(
                        top: 6, left: 6,
                        child: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white.withValues(alpha: 0.9),
                          size: 22,
                        ),
                      ),
                    // Tükendi banner
                    if (isOutOfStock)
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          color: AppColors.danger.withValues(alpha: 0.88),
                          child: Text(
                            t('stock.out_of_stock'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Bilgi bölümü ───────────────────────────────────────────
              Expanded(
                flex: 40,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product['name']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Stok rozeti
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: isOutOfStock
                                  ? AppColors.bgDanger
                                  : isLowStock
                                      ? AppColors.bgWarning
                                      : AppColors.bgSuccess,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isLowStock && !isOutOfStock)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 2),
                                    child: Icon(Icons.warning_amber_rounded,
                                        size: 9, color: AppColors.warning),
                                  ),
                                Text(
                                  '${stock.toInt()}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isOutOfStock
                                        ? AppColors.danger
                                        : isLowStock
                                            ? AppColors.warning
                                            : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Fiyat
                          Text(
                            _currencyFormat.format(price),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Yardımcı widget'lar ───────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _StatPill({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(count,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.75))),
            if (onTap != null) ...[
              const SizedBox(width: 3),
              Icon(Icons.chevron_right_rounded, size: 13, color: color.withValues(alpha: 0.6)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _BottomSheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _CompactBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _CompactBarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.bgWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: active ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _SheetChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? activeColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  final int stock;
  final String unit;
  final bool isOutOfStock;
  final bool isLowStock;
  final String stockLabel;

  const _StockChip({
    required this.stock,
    required this.unit,
    required this.isOutOfStock,
    required this.isLowStock,
    required this.stockLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOutOfStock
        ? AppColors.danger
        : isLowStock
            ? AppColors.warning
            : AppColors.success;
    final bg = isOutOfStock
        ? AppColors.bgDanger
        : isLowStock
            ? AppColors.bgWarning
            : AppColors.bgSuccess;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLowStock && !isOutOfStock)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Icon(Icons.warning_amber_rounded, size: 10, color: color),
            ),
          Text(
            '$stockLabel: $stock${unit.isNotEmpty ? ' $unit' : ''}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
