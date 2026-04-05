import '../core/api/api_client.dart';
import '../core/data/mock_data.dart';
import '../core/utils/app_logger.dart';

/// Ürün servisi — Ürün CRUD işlemleri için backend API çağrıları yönetir.
///
/// Backend endpoint: `product/api/v1/products`
/// Arama endpoint: `product/api/v1/productssearch`
class ProductService {
  final ApiClient _apiClient;

  /// Development mode - mock data kullanmak için true yapın
  static const bool useMockData = false;

  ProductService(this._apiClient);

  // ─── Response Mappers ────────────────────────────────────────────────────

  /// Backend `ProductResponse` nesnesini Flutter field adlarına normalize eder.
  ///
  /// Stock ekranının beklediği alanlar: `id`, `name`, `stock`, `sellingPrice`,
  /// `isActive`, `sku`, `barcode`, `lowStockThreshold`.
  /// Varyant ve envanter bilgileri ilk varyanttan alınır.
  Map<String, dynamic> _mapProduct(Map<String, dynamic> raw) {
    final variants =
        (raw['variants'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final firstVariant =
        variants.isNotEmpty ? variants.first : <String, dynamic>{};
    final inventory =
        firstVariant['inventory'] as Map<String, dynamic>? ?? {};

    return {
      // Kimlik
      'id': raw['id'],               // String — backend UUID
      'name': raw['name'],
      'slug': raw['slug'],
      'sku': firstVariant['sku'] ?? raw['sku'],
      'description': raw['description'],
      'brand': raw['brand'],
      'categoryId': raw['categoryId'],

      // Varyant bilgileri — satış/stok işlemleri için gerekli
      'variantId': firstVariant['id'],          // backend variantId
      'variants': variants,                      // tüm varyant listesi

      // Fiyat — basePrice ana fiyat, varyant additionalPrice eklenebilir
      'basePrice': raw['basePrice'],
      'sellingPrice': raw['basePrice'],   // ekran uyumu için alias
      'price': raw['basePrice'],

      // Durum
      'status': raw['status'],
      'isActive': (raw['status'] as String?)?.toUpperCase() == 'ACTIVE',

      // Stok — variants[0].inventory.physicalQuantity
      'stock': inventory['physicalQuantity'] ?? 0,
      'lowStockThreshold': inventory['minStockLevel'] ?? 10,
      'warehouseCode': inventory['warehouseCode'],
      'warehouseId': inventory['warehouseId'],
      'storeId': inventory['storeId'],

      // Barkod — variants[0].barcodes içindeki primary barkod
      'barcode': _extractBarcode(firstVariant),

      // Ham varyant listesi (detay ekranı için)
      'variants': raw['variants'],
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

  // ─── API Methods ─────────────────────────────────────────────────────────

  /// Ürünleri listeler.
  ///
  /// [page] ve [size] ile sayfalama, [search] ile arama,
  /// [category] ile kategori filtreleme, [isActive] ile durum filtreleme destekler.
  /// Arama varsa `/productssearch` endpoint'ini kullanır.
  Future<List<Map<String, dynamic>>> getProducts({
    int page = 0,
    int size = 50,
    String? search,
    String? category,
    bool? isActive,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      var products = List<Map<String, dynamic>>.from(MockData.sampleProducts);
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        products = products.where((p) {
          return p['name'].toString().toLowerCase().contains(q) ||
              p['sku'].toString().toLowerCase().contains(q) ||
              (p['barcode']?.toString().toLowerCase() ?? '').contains(q);
        }).toList();
      }
      if (category != null && category != 'Tümü') {
        products = products.where((p) => p['category'] == category).toList();
      }
      if (isActive != null) {
        products =
            products.where((p) => p['isActive'] == isActive).toList();
      }
      return products;
    }

    try {
      if (search != null && search.isNotEmpty) {
        // Arama endpoint'i ayrı: /product/api/v1/products/search?keyword=...
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
      return useMockData ? MockData.sampleProducts : [];
    }
  }

  /// Tek bir ürünü ID ile getirir.
  ///
  /// Backend: `GET /product/api/v1/products/{id}`
  Future<Map<String, dynamic>> getProductById(String id) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return MockData.sampleProducts.firstWhere(
        (p) => p['id'].toString() == id,
        orElse: () => {},
      );
    }
    try {
      final response = await _apiClient.get('product/api/v1/products/$id');
      final raw = (response.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      return _mapProduct(raw);
    } catch (e) {
      return {};
    }
  }

  /// Yeni ürün oluşturur.
  ///
  /// [data] backend `ProductRequest` formatında olmalıdır.
  Future<Map<String, dynamic>> createProduct(
      Map<String, dynamic> data) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      final newProduct = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        ...data,
        'createdAt': DateTime.now().toIso8601String(),
      };
      MockData.sampleProducts.add(newProduct);
      return newProduct;
    }
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

  /// Mevcut ürünü günceller.
  ///
  /// [id] ürün UUID'si, [data] güncellenecek alanları içerir.
  Future<Map<String, dynamic>> updateProduct(
      String id, Map<String, dynamic> data) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      final index =
          MockData.sampleProducts.indexWhere((p) => p['id'].toString() == id);
      if (index != -1) {
        MockData.sampleProducts[index] = {
          ...MockData.sampleProducts[index],
          ...data,
        };
        return MockData.sampleProducts[index];
      }
      throw Exception('Product not found');
    }
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

  /// Ürünü siler.
  ///
  /// Backend: `DELETE /product/api/v1/products/{id}`
  Future<void> deleteProduct(String id) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      MockData.sampleProducts.removeWhere((p) => p['id'].toString() == id);
      return;
    }
    try {
      await _apiClient.delete('product/api/v1/products/$id');
    } catch (e) {
      AppLogger.error('Ürün silinemedi: $id', tag: 'ProductService', error: e);
    }
  }

  /// Ürün istatistiklerini hesaplar (lokal).
  ///
  /// Toplam, aktif, düsuk stok ve stokta olmayan ürün sayılarını döner.
  /// Backend'de ayrı bir stats endpoint'i bulunmadığından lokal hesaplanır.
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
