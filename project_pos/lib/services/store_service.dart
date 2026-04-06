import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';

class StoreService {
  final ApiClient _apiClient;

  StoreService(this._apiClient);

  static const String _base = 'product/api/v1/stores';

  // Get all stores
  Future<List<Map<String, dynamic>>> getStores({
    String? search,
    String? type,
    bool? isActive,
    String? city,
    int? page,
    int? limit,
  }) async {
    debugPrint('GET $_base?isActive=$isActive');
    try {
      final queryParams = <String, dynamic>{};
      if (isActive != null) queryParams['isActive'] = isActive;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get(_base, queryParameters: queryParams);
      debugPrint('GET $_base -> status: ${response.statusCode}');
      final list = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      debugPrint('Magaza listesi: ${list.length} kayit');
      return list;
    } catch (e) {
      debugPrint('getStores hata: $e');
      rethrow;
    }
  }

  // Get single store by ID
  Future<Map<String, dynamic>> getStoreById(String id) async {
    try {
      final response = await _apiClient.get('$_base/$id');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getStoreById hata: $e');
      rethrow;
    }
  }

  // Create new store
  Future<Map<String, dynamic>> createStore(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(_base, data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('createStore hata: $e');
      rethrow;
    }
  }

  // Update store
  Future<Map<String, dynamic>> updateStore(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('$_base/$id', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('updateStore hata: $e');
      rethrow;
    }
  }

  // Delete store
  Future<bool> deleteStore(String id) async {
    try {
      await _apiClient.delete('$_base/$id');
      return true;
    } catch (e) {
      debugPrint('deleteStore hata: $e');
      rethrow;
    }
  }

  // Toggle store active status
  Future<bool> toggleStoreStatus(String id) async {
    try {
      await _apiClient.put('$_base/$id/toggle-status');
      return true;
    } catch (e) {
      debugPrint('toggleStoreStatus hata: $e');
      throw UnimplementedError('Backend endpoint not available for toggleStoreStatus');
    }
  }

  // Get store statistics
  Future<Map<String, dynamic>> getStoreStats(String id) async {
    try {
      final response = await _apiClient.get('$_base/$id/stats');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getStoreStats hata: $e');
      throw UnimplementedError('Backend endpoint not available for getStoreStats');
    }
  }

  // Get store performance data
  Future<Map<String, dynamic>> getStorePerformance(String id, {String period = 'month'}) async {
    try {
      final response = await _apiClient.get('$_base/$id/performance', queryParameters: {'period': period});
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getStorePerformance hata: $e');
      throw UnimplementedError('Backend endpoint not available for getStorePerformance');
    }
  }
}
