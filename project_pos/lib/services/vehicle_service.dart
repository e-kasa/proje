import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';

/// Arac Servisi — /product/api/vehicle
class VehicleService {
  final ApiClient _apiClient;
  VehicleService(this._apiClient);

  static const String _base = 'product/api/vehicle';

  /// Aktif araclari getir
  Future<List<Map<String, dynamic>>> getActiveVehicles() async {
    try {
      final response = await _apiClient.get(_base);
      final data = response.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      debugPrint('getActiveVehicles hata: $e');
      return [];
    }
  }

  /// Tum araclari getir
  Future<List<Map<String, dynamic>>> getAllVehicles() async {
    try {
      final response = await _apiClient.get('$_base/all');
      final data = response.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      debugPrint('getAllVehicles hata: $e');
      return [];
    }
  }

  /// Arac olustur
  Future<Map<String, dynamic>> createVehicle(Map<String, dynamic> data) async {
    final response = await _apiClient.post(_base, data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Arac guncelle
  Future<Map<String, dynamic>> updateVehicle(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('$_base/$id', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Arac sil
  Future<void> deleteVehicle(String id) async {
    await _apiClient.delete('$_base/$id');
  }

  /// Marka listesi (distinct)
  Future<List<String>> getDistinctMakes() async {
    try {
      final response = await _apiClient.get('$_base/makes');
      final data = response.data['data'];
      if (data is List) return data.cast<String>();
      return [];
    } catch (e) {
      debugPrint('getDistinctMakes hata: $e');
      return [];
    }
  }

  /// Markaya gore model listesi
  Future<List<String>> getModelsByMake(String make) async {
    try {
      final response = await _apiClient.get('$_base/models', queryParameters: {'make': make});
      final data = response.data['data'];
      if (data is List) return data.cast<String>();
      return [];
    } catch (e) {
      debugPrint('getModelsByMake hata: $e');
      return [];
    }
  }

  /// Arac ara (marka, model, yil)
  Future<List<Map<String, dynamic>>> searchVehicles({
    String? make,
    String? model,
    int? year,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (make != null) params['make'] = make;
      if (model != null) params['model'] = model;
      if (year != null) params['year'] = year;
      final response = await _apiClient.get('$_base/search', queryParameters: params);
      final data = response.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      debugPrint('searchVehicles hata: $e');
      return [];
    }
  }
}
