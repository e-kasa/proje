import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';

class StoreService {
  /// Development mode - uses mock data when API is unavailable
  static const bool useMockData = false;
  final ApiClient _apiClient;

  StoreService(this._apiClient);

  static const String _base = 'product/api/v1/stores';

  // Mock data for stores
  static final List<Map<String, dynamic>> _mockStores = [
    {
      'id': 'STORE-01',
      'code': 'STORE-01',
      'name': 'Ana Mağaza',
      'address': 'İstanbul, Türkiye',
      'city': 'İstanbul',
      'district': 'Merkez',
      'phone': '0212 000 00 01',
      'email': 'merkez@magaza.com',
      'managerName': 'Zeynep Arslan',
      'openingHours': '09:00 - 22:00',
      'totalArea': 350,
      'salesArea': 280,
      'employeeCount': 12,
      'isActive': true,
      'type': 'flagship',
      'hasWarehouse': true,
      'createdAt': '2024-01-15',
    },
  ];

  // Get all stores
  Future<List<Map<String, dynamic>>> getStores({
    String? search,
    String? type,
    bool? isActive,
    String? city,
    int? page,
    int? limit,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      var stores = List<Map<String, dynamic>>.from(_mockStores);

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        stores = stores.where((s) =>
          s['name'].toString().toLowerCase().contains(searchLower) ||
          s['code'].toString().toLowerCase().contains(searchLower)).toList();
      }

      if (type != null) {
        stores = stores.where((s) => s['type'] == type).toList();
      }

      if (isActive != null) {
        stores = stores.where((s) => s['isActive'] == isActive).toList();
      }

      if (city != null) {
        stores = stores.where((s) => s['city'] == city).toList();
      }

      return stores;
    }

    debugPrint('🌐 GET $_base?isActive=$isActive çağrılıyor...');
    try {
      final queryParams = <String, dynamic>{};
      if (isActive != null) queryParams['isActive'] = isActive;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get(_base, queryParameters: queryParams);
      debugPrint('🌐 GET $_base → status: ${response.statusCode}');
      final list = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      debugPrint('🌐 Mağaza listesi: ${list.length} kayıt');
      return list;
    } catch (e) {
      debugPrint('❌ getStores hata: $e → mock veriye düşüldü');
      return _mockStores;
    }
  }

  // Get single store by ID
  Future<Map<String, dynamic>> getStoreById(String id) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockStores.firstWhere(
        (s) => s['id'] == id,
        orElse: () => {},
      );
    }

    try {
      final response = await _apiClient.get('$_base/$id');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      return _mockStores.firstWhere(
        (s) => s['id'] == id,
        orElse: () => {},
      );
    }
  }

  // Create new store
  Future<Map<String, dynamic>> createStore(Map<String, dynamic> data) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      final newStore = {
        'id': 'STR-${DateTime.now().millisecondsSinceEpoch}',
        ...data,
        'createdAt': DateTime.now().toString().split(' ')[0],
      };
      _mockStores.add(newStore);
      return newStore;
    }

    try {
      final response = await _apiClient.post(_base, data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      final newStore = {
        'id': 'STR-${DateTime.now().millisecondsSinceEpoch}',
        ...data,
        'createdAt': DateTime.now().toString().split(' ')[0],
      };
      _mockStores.add(newStore);
      return newStore;
    }
  }

  // Update store
  Future<Map<String, dynamic>> updateStore(String id, Map<String, dynamic> data) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      final index = _mockStores.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        _mockStores[index] = {..._mockStores[index], ...data};
        return _mockStores[index];
      }
      return {};
    }

    try {
      final response = await _apiClient.put('$_base/$id', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      final index = _mockStores.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        _mockStores[index] = {..._mockStores[index], ...data};
        return _mockStores[index];
      }
      return {};
    }
  }

  // Delete store
  Future<bool> deleteStore(String id) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      _mockStores.removeWhere((s) => s['id'] == id);
      return true;
    }

    try {
      await _apiClient.delete('$_base/$id');
      return true;
    } catch (e) {
      _mockStores.removeWhere((s) => s['id'] == id);
      return true;
    }
  }

  // Toggle store active status (mock only — backend doesn't support this endpoint)
  Future<bool> toggleStoreStatus(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockStores.indexWhere((s) => s['id'] == id);
    if (index != -1) {
      _mockStores[index]['isActive'] = !(_mockStores[index]['isActive'] as bool);
      return true;
    }
    return false;
  }

  // Get store statistics (mock only — backend doesn't support this endpoint)
  Future<Map<String, dynamic>> getStoreStats(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final store = _mockStores.firstWhere(
      (s) => s['id'] == id,
      orElse: () => {},
    );

    if (store.isEmpty) return {};

    return {
      'todaySales': 45000,
      'todayTransactions': 127,
      'monthSales': 1250000,
      'averageTicket': 354.33,
      'topProducts': 5,
      'activeEmployees': store['employeeCount'],
    };
  }

  // Get store performance data (mock only)
  Future<Map<String, dynamic>> getStorePerformance(String id, {String period = 'month'}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      'revenue': [45000, 52000, 48000, 61000, 58000, 63000, 59000],
      'transactions': [120, 145, 132, 168, 155, 172, 164],
      'avgTicket': [375, 358, 363, 362, 374, 366, 359],
      'labels': ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'],
    };
  }
}
