import 'package:flutter/foundation.dart';
import 'package:project_pos/core/api/api_client.dart';

class WarehouseService {
  final ApiClient _apiClient;

  WarehouseService(this._apiClient);

  static const String _base = 'product/api/v1/warehouses';

  // Get all warehouses
  Future<List<Map<String, dynamic>>> getWarehouses({
    String? search,
    String? storeCode,
    String? type,
    bool? isActive,
    int? page,
    int? limit,
  }) async {
    debugPrint('GET $_base?isActive=$isActive');
    try {
      final queryParams = <String, dynamic>{};
      if (search != null) queryParams['search'] = search;
      if (storeCode != null) queryParams['storeCode'] = storeCode;
      if (type != null) queryParams['type'] = type;
      if (isActive != null) queryParams['isActive'] = isActive;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get(_base, queryParameters: queryParams);
      debugPrint('GET $_base -> status: ${response.statusCode}');
      final list = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      debugPrint('Depo listesi: ${list.length} kayit');
      return list;
    } catch (e) {
      debugPrint('getWarehouses hata: $e');
      rethrow;
    }
  }

  // Get single warehouse by ID
  Future<Map<String, dynamic>> getWarehouseById(String id) async {
    try {
      final response = await _apiClient.get('$_base/$id');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getWarehouseById hata: $e');
      rethrow;
    }
  }

  // Create new warehouse
  Future<Map<String, dynamic>> createWarehouse(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(_base, data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('createWarehouse hata: $e');
      rethrow;
    }
  }

  // Update warehouse
  Future<Map<String, dynamic>> updateWarehouse(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('$_base/$id', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('updateWarehouse hata: $e');
      rethrow;
    }
  }

  // Delete warehouse
  Future<bool> deleteWarehouse(String id) async {
    try {
      await _apiClient.delete('$_base/$id');
      return true;
    } catch (e) {
      debugPrint('deleteWarehouse hata: $e');
      rethrow;
    }
  }

  // Toggle warehouse active status
  Future<bool> toggleWarehouseStatus(String id) async {
    try {
      await _apiClient.put('$_base/$id/toggle-status');
      return true;
    } catch (e) {
      debugPrint('toggleWarehouseStatus hata: $e');
      throw UnimplementedError('Backend endpoint not available for toggleWarehouseStatus');
    }
  }

  // Get warehouse statistics
  Future<Map<String, dynamic>> getWarehouseStats(String id) async {
    try {
      final response = await _apiClient.get('$_base/$id/stats');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getWarehouseStats hata: $e');
      throw UnimplementedError('Backend endpoint not available for getWarehouseStats');
    }
  }
}
