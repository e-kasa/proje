import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';

class WarehouseService {
  /// Development mode - uses mock data when API is unavailable
  static const bool useMockData = false;
  final ApiClient _apiClient;

  WarehouseService(this._apiClient);

  static const String _base = 'product/api/v1/warehouses';

  // Mock data for warehouses
  static final List<Map<String, dynamic>> _mockWarehouses = [
    {
      'id': 'WH-01',
      'code': 'WH-01',
      'name': 'Ana Depo',
      'storeCode': 'STORE-01',
      'address': 'İstanbul, Türkiye',
      'city': 'İstanbul',
      'district': 'Merkez',
      'phone': '+90 (212) 000-0001',
      'managerName': 'Ahmet Yılmaz',
      'capacity': 5000,
      'currentStock': 3250,
      'isActive': true,
      'type': 'main',
      'createdAt': '2024-01-15',
    },
  ];

  // Get all warehouses
  Future<List<Map<String, dynamic>>> getWarehouses({
    String? search,
    String? storeCode,
    String? type,
    bool? isActive,
    int? page,
    int? limit,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      var warehouses = List<Map<String, dynamic>>.from(_mockWarehouses);

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        warehouses = warehouses.where((w) =>
          w['name'].toString().toLowerCase().contains(searchLower) ||
          w['code'].toString().toLowerCase().contains(searchLower)).toList();
      }

      if (storeCode != null) {
        warehouses = warehouses.where((w) => w['storeCode'] == storeCode).toList();
      }

      if (type != null) {
        warehouses = warehouses.where((w) => w['type'] == type).toList();
      }

      if (isActive != null) {
        warehouses = warehouses.where((w) => w['isActive'] == isActive).toList();
      }

      return warehouses;
    }

    debugPrint('🌐 GET $_base?isActive=$isActive çağrılıyor...');
    try {
      final queryParams = <String, dynamic>{};
      if (storeCode != null) queryParams['storeCode'] = storeCode;
      if (isActive != null) queryParams['isActive'] = isActive;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get(_base, queryParameters: queryParams);
      debugPrint('🌐 GET $_base → status: ${response.statusCode}');
      final list = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      debugPrint('🌐 Depo listesi: ${list.length} kayıt');
      return list;
    } catch (e) {
      debugPrint('❌ getWarehouses hata: $e → mock veriye düşüldü');
      return _mockWarehouses;
    }
  }

  // Get single warehouse by ID
  Future<Map<String, dynamic>> getWarehouseById(String id) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockWarehouses.firstWhere(
        (w) => w['id'] == id,
        orElse: () => {},
      );
    }

    try {
      final response = await _apiClient.get('$_base/$id');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      return _mockWarehouses.firstWhere(
        (w) => w['id'] == id,
        orElse: () => {},
      );
    }
  }

  // Create new warehouse
  Future<Map<String, dynamic>> createWarehouse(Map<String, dynamic> data) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      final newWarehouse = {
        'id': 'WH-${DateTime.now().millisecondsSinceEpoch}',
        ...data,
        'currentStock': 0,
        'createdAt': DateTime.now().toString().split(' ')[0],
      };
      _mockWarehouses.add(newWarehouse);
      return newWarehouse;
    }

    try {
      final response = await _apiClient.post(_base, data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      final newWarehouse = {
        'id': 'WH-${DateTime.now().millisecondsSinceEpoch}',
        ...data,
        'currentStock': 0,
        'createdAt': DateTime.now().toString().split(' ')[0],
      };
      _mockWarehouses.add(newWarehouse);
      return newWarehouse;
    }
  }

  // Update warehouse
  Future<Map<String, dynamic>> updateWarehouse(String id, Map<String, dynamic> data) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      final index = _mockWarehouses.indexWhere((w) => w['id'] == id);
      if (index != -1) {
        _mockWarehouses[index] = {..._mockWarehouses[index], ...data};
        return _mockWarehouses[index];
      }
      return {};
    }

    try {
      final response = await _apiClient.put('$_base/$id', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      final index = _mockWarehouses.indexWhere((w) => w['id'] == id);
      if (index != -1) {
        _mockWarehouses[index] = {..._mockWarehouses[index], ...data};
        return _mockWarehouses[index];
      }
      return {};
    }
  }

  // Delete warehouse
  Future<bool> deleteWarehouse(String id) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      _mockWarehouses.removeWhere((w) => w['id'] == id);
      return true;
    }

    try {
      await _apiClient.delete('$_base/$id');
      return true;
    } catch (e) {
      _mockWarehouses.removeWhere((w) => w['id'] == id);
      return true;
    }
  }

  // Toggle warehouse active status (mock only — backend doesn't support this endpoint)
  Future<bool> toggleWarehouseStatus(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockWarehouses.indexWhere((w) => w['id'] == id);
    if (index != -1) {
      _mockWarehouses[index]['isActive'] = !(_mockWarehouses[index]['isActive'] as bool);
      return true;
    }
    return false;
  }

  // Get warehouse statistics (mock only — backend doesn't support this endpoint)
  Future<Map<String, dynamic>> getWarehouseStats(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final warehouse = _mockWarehouses.firstWhere(
      (w) => w['id'] == id,
      orElse: () => {},
    );

    if (warehouse.isEmpty) return {};

    return {
      'totalProducts': 1250,
      'totalValue': 1250000,
      'lowStockItems': 45,
      'outOfStock': 12,
      'utilizationRate': ((warehouse['currentStock'] as int) / (warehouse['capacity'] as int) * 100).toStringAsFixed(1),
    };
  }
}
