import '../core/api/api_client.dart';

/// Birim Servisi — /product/api/unit
class UnitService {
  final ApiClient _apiClient;
  UnitService(this._apiClient);

  static const String _base = 'product/api/unit';

  /// Aktif birimleri getir (dropdown için)
  Future<List<Map<String, dynamic>>> getActiveUnits() async {
    try {
      final response = await _apiClient.get(_base);
      final data = response.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Tüm birimleri getir (yönetim ekranı için)
  Future<List<Map<String, dynamic>>> getAllUnits() async {
    try {
      final response = await _apiClient.get('$_base/all');
      final data = response.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Yeni birim oluştur
  Future<Map<String, dynamic>> createUnit(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(_base, data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Birim güncelle
  Future<Map<String, dynamic>> updateUnit(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('$_base/$id', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Birim sil
  Future<void> deleteUnit(String id) async {
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
