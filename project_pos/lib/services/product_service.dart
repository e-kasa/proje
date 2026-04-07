import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/utils/app_logger.dart';

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
    final inventory =
        firstVariant['inventory'] as Map<String, dynamic>? ?? {};

    return {
      // Kimlik
      'id': raw['id'],               // String -- backend UUID
      'name': raw['name'],
      'slug': raw['slug'],
      'sku': firstVariant['sku'] ?? raw['sku'],
      'description': raw['description'],
      'brand': raw['brand'],
      'categoryId': raw['categoryId'],

      // Varyant bilgileri -- satis/stok islemleri icin gerekli
      'variantId': firstVariant['id'],          // backend variantId
      'variants': variants,                      // tum varyant listesi

      // Fiyat -- basePrice ana fiyat, varyant additionalPrice eklenebilir
      'basePrice': raw['basePrice'],
      'sellingPrice': raw['basePrice'],   // ekran uyumu icin alias
      'price': raw['basePrice'],

      // Durum
      'status': raw['status'],
      'isActive': (raw['status'] as String?)?.toUpperCase() == 'ACTIVE',

      // Stok -- variants[0].inventory.physicalQuantity
      'stock': inventory['physicalQuantity'] ?? 0,
      'lowStockThreshold': inventory['minStockLevel'] ?? 10,
      'warehouseCode': inventory['warehouseCode'],
      'warehouseId': inventory['warehouseId'],
      'storeId': inventory['storeId'],

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

  /// Yeni urun olusturur.
  ///
  /// [data] backend `ProductRequest` formatinda olmalidir.
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
    final products = await getProducts();
    return {
      'totalProducts': products.length,
      'activeProducts': products.where((p) => p['isActive'] == true).length,
      'lowStockProducts': products.where((p) {
        final s = p['stock'] as int? ?? 0;
        final t = p['lowStockThreshold'] as int? ?? 10;
        return s <= t && s > 0;
      }).length,
      'outOfStockProducts':
          products.where((p) => (p['stock'] as int? ?? 0) == 0).length,
    };
  }
}
