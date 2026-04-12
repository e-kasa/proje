import 'package:flutter/foundation.dart';
import 'package:project_pos/core/api/api_client.dart';

/// Capraz Referans Servisi — /product/api/cross-reference
class CrossReferenceService {
  final ApiClient _apiClient;
  CrossReferenceService(this._apiClient);

  static const String _base = 'product/api/cross-reference';

  /// Varyanta ait capraz referanslari getir
  Future<List<Map<String, dynamic>>> getByVariantId(String variantId) async {
    try {
      final response = await _apiClient.get('$_base/variant/$variantId');
      final data = response.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      debugPrint('getByVariantId hata: $e');
      return [];
    }
  }

  /// Capraz referans ekle
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await _apiClient.post(_base, data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Toplu capraz referans ekle
  Future<List<Map<String, dynamic>>> bulkCreate(String variantId, List<Map<String, dynamic>> items) async {
    final response = await _apiClient.post('$_base/bulk/$variantId', data: items);
    final data = response.data['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  /// Capraz referans sil
  Future<void> delete(String id) async {
    await _apiClient.delete('$_base/$id');
  }

  /// Capraz referans ile ara
  Future<List<Map<String, dynamic>>> search(String q) async {
    try {
      final response = await _apiClient.get('$_base/search', queryParameters: {'q': q});
      final data = response.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      debugPrint('CrossRef search hata: $e');
      return [];
    }
  }
}
