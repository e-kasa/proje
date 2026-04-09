import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';

/// Önerme Servisi
///
/// POS satış ekranında kasiyere ürün önerileri sunar:
/// 1. Satış verisi tabanlı (Frequently Bought Together)
/// 2. Manuel ilişkiler tabanlı (Benzer, Alternatif, Tamamlayıcı)
class RecommendationService {
  final ApiClient _apiClient;

  RecommendationService(this._apiClient);

  static const String _baseUrl = 'product/api/v1/recommendations';

  /// HYBRID RECOMMENDATIONS - Ana method
  ///
  /// Sepette olan ürünlere göre akıllı önerileri getir
  /// 2 kaynaktan (satış verisi + manuel ilişkiler) birleştirerek sunar
  ///
  /// [productIds]: Sepetteki ürün ID'leri
  /// [limit]: Kaç ürün gösterilsin (default: 6)
  /// [excludeIds]: Gösterilmeyecek ürün ID'leri (sepet ürünleri)
  Future<List<Map<String, dynamic>>> getHybridRecommendations({
    required List<String> productIds,
    int limit = 6,
    List<String>? excludeIds,
  }) async {
    try {
      if (productIds.isEmpty) {
        return [];
      }

      final queryParams = <String, dynamic>{
        'productIds': productIds.join(','),
        'limit': limit,
      };

      if (excludeIds != null && excludeIds.isNotEmpty) {
        queryParams['excludeIds'] = excludeIds.join(',');
      }

      final response = await _apiClient.get(
        '$_baseUrl/hybrid',
        queryParameters: queryParams,
      );

      final data = response.data['data'] as List? ?? [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Hybrid öneriler getirme hatası: $e');
      return [];
    }
  }

  /// FREQUENTLY BOUGHT TOGETHER
  ///
  /// Satış verilerinden: "Bu ürünler sıkça birlikte satılır" önerileri
  ///
  /// [variantIds]: Sepetteki varyant ID'leri
  /// [limit]: Kaç ürün (default: 4)
  Future<List<Map<String, dynamic>>> getFrequentlyBoughtTogether({
    required List<String> variantIds,
    int limit = 4,
  }) async {
    try {
      if (variantIds.isEmpty) {
        return [];
      }

      final response = await _apiClient.get(
        '$_baseUrl/frequently-bought',
        queryParameters: {
          'variantIds': variantIds.join(','),
          'limit': limit,
        },
      );

      final data = response.data['data'] as List? ?? [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Frequently bought together hatası: $e');
      return [];
    }
  }

  /// SIMILAR PRODUCTS
  ///
  /// Manuel olarak tanımlanan benzer/alternatif/tamamlayıcı ürünler
  ///
  /// [productIds]: Kaynak ürün ID'leri
  /// [type]: İlişki tipi (SIMILAR, ALTERNATIVE, COMPLEMENTARY)
  /// [limit]: Kaç ürün (default: 4)
  Future<List<Map<String, dynamic>>> getSimilarProducts({
    required List<String> productIds,
    String? type,
    int limit = 4,
  }) async {
    try {
      if (productIds.isEmpty) {
        return [];
      }

      final queryParams = <String, dynamic>{
        'productIds': productIds.join(','),
        'limit': limit,
      };

      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      final response = await _apiClient.get(
        '$_baseUrl/similar',
        queryParameters: queryParams,
      );

      final data = response.data['data'] as List? ?? [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Similar products hatası: $e');
      return [];
    }
  }

  /// ─── ADMIN: Product Relationship YÖNETIMI ───

  /// Yeni ilişki oluştur
  Future<Map<String, dynamic>> createRelationship({
    required String sourceProductId,
    required String targetProductId,
    required String relationType,
    required int weight,
    bool isActive = true,
  }) async {
    try {
      final response = await _apiClient.post(
        '$_baseUrl/relationships',
        data: {
          'sourceProductId': sourceProductId,
          'targetProductId': targetProductId,
          'relationType': relationType,
          'weight': weight,
          'isActive': isActive,
        },
      );

      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('İlişki oluşturma hatası: $e');
      rethrow;
    }
  }

  /// İlişkiyi güncelle
  Future<Map<String, dynamic>> updateRelationship({
    required String id,
    required String relationType,
    required int weight,
    bool isActive = true,
  }) async {
    try {
      final response = await _apiClient.put(
        '$_baseUrl/relationships/$id',
        data: {
          'relationType': relationType,
          'weight': weight,
          'isActive': isActive,
        },
      );

      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('İlişki güncelleme hatası: $e');
      rethrow;
    }
  }

  /// İlişkiyi sil
  Future<void> deleteRelationship(String id) async {
    try {
      await _apiClient.delete('$_baseUrl/relationships/$id');
    } catch (e) {
      debugPrint('İlişki silme hatası: $e');
      rethrow;
    }
  }

  /// Ürüne ait ilişkileri getir (Admin paneli)
  Future<List<Map<String, dynamic>>> getRelationships({
    String? sourceProductId,
    String? type,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (sourceProductId != null && sourceProductId.isNotEmpty) {
        queryParams['sourceProductId'] = sourceProductId;
      }

      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      final response = await _apiClient.get(
        '$_baseUrl/relationships',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = response.data['data'] as List? ?? [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('İlişkiler getirme hatası: $e');
      return [];
    }
  }

  /// Toplu ilişki ekleme
  Future<List<Map<String, dynamic>>> bulkImportRelationships(
    List<Map<String, dynamic>> relationships,
  ) async {
    try {
      final response = await _apiClient.post(
        '$_baseUrl/relationships/bulk-import',
        data: relationships,
      );

      final data = response.data['data'] as List? ?? [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Toplu import hatası: $e');
      rethrow;
    }
  }

  /// Cache temizle
  Future<void> clearCache({String? productId}) async {
    try {
      await _apiClient.post(
        '$_baseUrl/cache/clear',
        queryParameters: productId != null ? {'productId': productId} : null,
      );
    } catch (e) {
      debugPrint('Cache temizleme hatası: $e');
      // Cache temizleme başarısız olsa da devam et
    }
  }

  /// İstatistikler
  Future<Map<String, dynamic>> getStats(String productId) async {
    try {
      final response = await _apiClient.get(
        '$_baseUrl/stats',
        queryParameters: {'productId': productId},
      );

      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('İstatistik getirme hatası: $e');
      return {};
    }
  }
}
