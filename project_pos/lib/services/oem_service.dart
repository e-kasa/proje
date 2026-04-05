import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';

/// OEM Numarasi Servisi — /product/api/oem-number
class OemService {
  final ApiClient _apiClient;
  OemService(this._apiClient);

  static const String _base = 'product/api/oem-number';

  /// Varyanta ait OEM numaralarini getir
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

  /// OEM numarasi ekle
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await _apiClient.post(_base, data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Toplu OEM numarasi ekle
  Future<List<Map<String, dynamic>>> bulkCreate(String variantId, List<Map<String, dynamic>> items) async {
    final response = await _apiClient.post('$_base/bulk/$variantId', data: items);
    final data = response.data['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  /// OEM numarasi sil
  Future<void> delete(String id) async {
    await _apiClient.delete('$_base/$id');
  }

  /// OEM numarasi ile ara
  Future<List<Map<String, dynamic>>> search(String q) async {
    try {
      final response = await _apiClient.get('$_base/search', queryParameters: {'q': q});
      final data = response.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      debugPrint('OEM search hata: $e');
      return [];
    }
  }
}
