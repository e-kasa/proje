import 'package:flutter/foundation.dart';
import 'package:project_pos/core/api/api_client.dart';

/// Marka Servisi — /product/api/brand
class BrandService {
  final ApiClient _apiClient;
  BrandService(this._apiClient);

  static const String _base = 'product/api/brand';

  /// Aktif markaları getir (dropdown için)
  Future<List<Map<String, dynamic>>> getActiveBrands() async {
    debugPrint('🌐 GET $_base çağrılıyor...');
    try {
      final response = await _apiClient.get(_base);
      debugPrint('🌐 GET $_base → status: ${response.statusCode}');
      final data = response.data['data'];
      if (data is List) {
        final list = data.cast<Map<String, dynamic>>();
        debugPrint('🌐 Marka listesi: ${list.length} kayıt');
        return list;
      }
      debugPrint('⚠️ Marka verisi beklenen formatta değil: ${response.data}');
      return [];
    } catch (e) {
      debugPrint('getActiveBrands hata: $e');
      rethrow;
    }
  }

  /// Tüm markaları getir (yönetim ekranı için)
  Future<List<Map<String, dynamic>>> getAllBrands() async {
    try {
      final response = await _apiClient.get('$_base/all');
      final data = response.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      debugPrint('getAllBrands hata: $e');
      rethrow;
    }
  }

  /// Yeni marka oluştur
  Future<Map<String, dynamic>> createBrand(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(_base, data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Marka güncelle
  Future<Map<String, dynamic>> updateBrand(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('$_base/$id', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Marka sil
  Future<void> deleteBrand(String id) async {
    try {
      await _apiClient.delete('$_base/$id');
    } catch (e) {
      rethrow;
    }
  }

  /// Durum değiştir (aktif ↔ pasif)
  Future<Map<String, dynamic>> toggleStatus(String id) async {
    try {
      final response = await _apiClient.patch('$_base/$id/toggle-status');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
