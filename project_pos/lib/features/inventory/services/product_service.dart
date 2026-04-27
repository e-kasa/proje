import 'package:flutter/foundation.dart';
import 'package:project_pos/core/api/api_client.dart';
import 'package:project_pos/core/utils/app_logger.dart';

/// Urun servisi -- Urun CRUD islemleri icin backend API cagrilari yonetir.
///
/// Backend endpoint: `product/api/v1/products`
/// Arama endpoint: `product/api/v1/productssearch`
class ProductService {
  final ApiClient _apiClient;

  ProductService(this._apiClient);

  // --- Response Mappers ------------------------------------------------

  /// Backend `ProductResponse` nesnesini Flutter field adlarina normalize eder.
  ///
  /// Stock ekraninin bekledigi alanlar: `id`, `name`, `stock`, `sellingPrice`,
  /// `isActive`, `sku`, `barcode`, `lowStockThreshold`.
  /// Varyant ve envanter bilgileri ilk varyantten alinir.
  Map<String, dynamic> _mapProduct(Map<String, dynamic> raw) {
    final variants =
        (raw['variants'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final firstVariant =
        variants.isNotEmpty ? variants.first : <String, dynamic>{};
    final firstInventory =
        firstVariant['inventory'] as Map<String, dynamic>? ?? {};

    // Normalize edilmiş varyant listesi — her varyant için stock/sellingPrice set et
    final normalizedVariants = variants.map((v) {
      final vInv = v['inventory'] as Map<String, dynamic>?;
      final vStock = vInv != null
          ? (vInv['physicalQuantity'] as num?)?.toInt() ?? 0
          : (v['stock'] as num?)?.toInt() ?? 0;
      final vPrice = (v['salePrice'] as num?)?.toDouble() ??
          (v['additionalPrice'] as num?)?.toDouble() ?? 0.0;
      // Lokasyon bazlı stok listesi — PosNotifier mağaza filtresi için pass-through
      final vInvList = (v['inventories'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      return {
        ...v,
        'stock': vStock,
        'inventories': vInvList,
        'sellingPrice': vPrice,
        'basePrice': vPrice,
        'price': vPrice,
      };
    }).toList();

    // Toplam stok = tüm varyantların stoğunun toplamı
    // Böylece "Fren Balata" kartı ön aks + arka aks stokunu birlikte gösterir
    final totalStock = normalizedVariants.fold<int>(
      0,
      (sum, v) => sum + ((v['stock'] as num?)?.toInt() ?? 0),
    );

    return {
      // Kimlik
      'id': raw['id'],               // String -- backend UUID
      'name': raw['name'],
      'slug': raw['slug'],
      'sku': firstVariant['sku'] ?? raw['sku'],
      'description': raw['description'],
      'brand': raw['brand'],
      'categoryId': raw['categoryId'],
      'categoryName': raw['categoryName'],

      // Varyant bilgileri -- satis/stok islemleri icin gerekli
      'variantId': firstVariant['id'],          // backend variantId (tek varyantlı için)
      'variants': normalizedVariants,

      // Fiyat -- basePrice ana fiyat, varyant additionalPrice eklenebilir
      'basePrice': raw['basePrice'],
      'sellingPrice': raw['basePrice'],   // ekran uyumu icin alias
      'price': raw['basePrice'],
      'purchasePrice': (firstVariant['purchasePrice'] as num?)?.toDouble(),

      // Durum
      'status': raw['status'],
      'isActive': (raw['status'] as String?)?.toUpperCase() == 'ACTIVE',

      // Stok -- TÜM varyantların toplamı (çok varyantlılar için doğru stok gösterimi)
      'stock': totalStock,
      'lowStockThreshold': firstInventory['minStockLevel'] ?? 10,
      'warehouseCode': firstInventory['warehouseCode'],
      'locationId': firstInventory['locationId'],
      'locationType': firstInventory['locationType'],

      // Barkod -- variants[0].barcodes icindeki primary barkod
      'barcode': _extractBarcode(firstVariant),

      // Vergi oranı -- first variant'ten al
      'taxRate': firstVariant['taxRate'] ?? raw['taxRate'] ?? 18.0,
    };
  }

  String? _extractBarcode(Map<String, dynamic> variant) {
    final barcodes =
        (variant['barcodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (barcodes.isEmpty) return null;
    final primary = barcodes.firstWhere(
      (b) => b['isPrimary'] == true,
      orElse: () => barcodes.first,
    );
    return primary['barcodeCode'] as String?;
  }

  // --- API Methods -----------------------------------------------------

  /// Urunleri listeler.
  ///
  /// [page] ve [size] ile sayfalama, [search] ile arama,
  /// [category] ile kategori filtreleme, [isActive] ile durum filtreleme destekler.
  /// Arama varsa `/productssearch` endpoint'ini kullanir.
  Future<List<Map<String, dynamic>>> getProducts({
    int page = 0,
    int size = 50,
    String? search,
    String? category,
    bool? isActive,
  }) async {
    try {
      if (search != null && search.isNotEmpty) {
        // Arama endpoint'i ayri: /product/api/v1/products/search?keyword=...
        final response = await _apiClient.get(
          'product/api/v1/products/search',
          queryParameters: {
            'keyword': search,
            'page': page,
            'size': size,
          },
        );
        final pageData =
            (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
        final content = (pageData['content'] as List?) ?? [];
        return content
            .cast<Map<String, dynamic>>()
            .map(_mapProduct)
            .toList();
      } else {
        // Standart liste: /api/v1/products?page=0&size=10&sortBy=createTime&sortDir=DESC
        final qp = <String, dynamic>{
          'page': page,
          'size': size,
          'sortBy': 'createTime',
          'sortDir': 'DESC',
        };
        if (isActive != null) {
          qp['status'] = isActive ? 'ACTIVE' : 'PASSIVE';
        }
        final response = await _apiClient.get(
          'product/api/v1/products',
          queryParameters: qp,
        );
        final pageData =
            (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
        final content = (pageData['content'] as List?) ?? [];
        return content
            .cast<Map<String, dynamic>>()
            .map(_mapProduct)
            .toList();
      }
    } catch (e) {
      debugPrint('getProducts hata: $e');
      rethrow;
    }
  }

  /// Sprint 13 W4.2 — paginated liste, backend metadata (totalPages, hasMore)
  /// ile birlikte. UI infinite-scroll için kullanılır.
  ///
  /// `getProducts()` legacy: yalnız content[] döner. Yeni provider'lar bu
  /// metodu tercih etmeli.
  Future<ProductListPage> getProductsPage({
    int page = 0,
    int size = 50,
    String? search,
    bool? isActive,
  }) async {
    try {
      late final Map<String, dynamic> pageData;
      if (search != null && search.isNotEmpty) {
        final response = await _apiClient.get(
          'product/api/v1/products/search',
          queryParameters: {
            'keyword': search,
            'page': page,
            'size': size,
          },
        );
        pageData = (response.data as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
      } else {
        final qp = <String, dynamic>{
          'page': page,
          'size': size,
          'sortBy': 'createTime',
          'sortDir': 'DESC',
        };
        if (isActive != null) {
          qp['status'] = isActive ? 'ACTIVE' : 'PASSIVE';
        }
        final response = await _apiClient.get(
          'product/api/v1/products',
          queryParameters: qp,
        );
        pageData = (response.data as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
      }
      final content = (pageData['content'] as List?) ?? [];
      final items = content
          .cast<Map<String, dynamic>>()
          .map(_mapProduct)
          .toList();
      // Spring Page response: number=current page, totalPages, last=true son sayfa
      final number = (pageData['number'] as num?)?.toInt() ?? page;
      final totalPages = (pageData['totalPages'] as num?)?.toInt() ?? 1;
      final totalElements =
          (pageData['totalElements'] as num?)?.toInt() ?? items.length;
      final isLast = pageData['last'] == true || number >= totalPages - 1;
      return ProductListPage(
        items: items,
        currentPage: number,
        totalPages: totalPages,
        totalElements: totalElements,
        hasMore: !isLast,
      );
    } catch (e) {
      debugPrint('getProductsPage hata: $e');
      rethrow;
    }
  }

  /// Tek bir urunu ID ile getirir.
  ///
  /// Backend: `GET /product/api/v1/products/{id}`
  Future<Map<String, dynamic>> getProductById(String id) async {
    try {
      final response = await _apiClient.get('product/api/v1/products/$id');
      final raw = (response.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      return _mapProduct(raw);
    } catch (e) {
      debugPrint('getProductById hata: $e');
      rethrow;
    }
  }

  /// Yeni urun olusturur (tekil).
  ///
  /// [data] backend `CreateProductRequest` formatinda olmalidir.
  Future<Map<String, dynamic>> createProduct(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _apiClient.post('product/api/v1/products', data: data);
      final raw = (response.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      return _mapProduct(raw);
    } catch (e) {
      rethrow;
    }
  }

  /// Toplu ürün girişi — tek fatura altında N yeni + M mevcut ürün.
  ///
  /// [request] backend `BatchCreateRequest` formatında olmalıdır:
  /// ```dart
  /// {
  ///   'supplierId': '...',
  ///   'invoiceNumber': '...',
  ///   'purchaseDate': 'yyyy-MM-dd',
  ///   'storeId': '...',
  ///   'warehouseId': '...',
  ///   'newProducts': [ { 'tempId', 'product', 'variants', 'oemNumbers', 'crossReferences' } ],
  ///   'existingProducts': [ { 'tempId', 'variantId', 'quantity', 'unitPrice' } ],
  /// }
  /// ```
  /// Dönen [BatchCreateResponse]:
  /// ```dart
  /// {
  ///   'purchaseId': '...',
  ///   'invoiceNumber': '...',
  ///   'successCount': 5,
  ///   'failCount': 1,
  ///   'totalAmount': 1250.00,
  ///   'results': [ { 'tempId', 'success', 'productId', 'variantId', 'message' } ]
  /// }
  /// ```
  Future<Map<String, dynamic>> batchCreate(
      Map<String, dynamic> request) async {
    try {
      final response = await _apiClient.post(
        'product/api/v1/products/batch',
        data: request,
      );
      return (response.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ProductService.batchCreate hata: $e');
      rethrow;
    }
  }

  /// Mevcut urunu gunceller.
  ///
  /// [id] urun UUID'si, [data] guncellenecek alanlari icerir.
  Future<Map<String, dynamic>> updateProduct(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _apiClient.put('product/api/v1/products/$id', data: data);
      final raw = (response.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      return _mapProduct(raw);
    } catch (e) {
      rethrow;
    }
  }

  /// Urunu siler.
  ///
  /// Backend: `DELETE /product/api/v1/products/{id}`
  Future<void> deleteProduct(String id) async {
    try {
      await _apiClient.delete('product/api/v1/products/$id');
    } catch (e) {
      AppLogger.error('Urun silinemedi: $id', tag: 'ProductService', error: e);
      rethrow;
    }
  }

  /// Urun istatistiklerini hesaplar (lokal).
  ///
  /// Toplam, aktif, dusuk stok ve stokta olmayan urun sayilarini doner.
  /// Backend'de ayri bir stats endpoint'i bulunmadigindan lokal hesaplanir.
  Future<Map<String, dynamic>> getProductStats() async {
    final products = await getProducts(size: 9999);
    return {
      'totalProducts': products.length,
      'activeProducts': products.where((p) => p['isActive'] == true).length,
      'lowStockProducts': products.where((p) {
        final s = p['stock'] as int? ?? 0;
        final t = p['lowStockThreshold'] as int? ?? 10;
        return s <= t && s > 0;
      }).length,
      'outOfStockProducts':
          products.where((p) => (p['stock'] as int? ?? 0) <= 0).length,
    };
  }
}

/// Sprint 13 W4.2 — paginated product list response wrapper.
class ProductListPage {
  final List<Map<String, dynamic>> items;
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  const ProductListPage({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });
}
