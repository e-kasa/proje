import '../core/data/mock_data.dart';
import '../core/api/api_client.dart';

class StockService {

  /// Development mode - uses mock data when API is unavailable
  static const bool useMockData = false;
  final ApiClient _apiClient;

  StockService(this._apiClient);

  // Get stock movements
  Future<List<Map<String, dynamic>>> getStockMovements({
    int? productId,
    String? movementType, // in, out, adjustment, return
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      // Return empty list for now - would need stock movement mock data
      return [];
    }

    try {
      final queryParams = <String, dynamic>{};
      if (productId != null) queryParams['productId'] = productId;
      if (movementType != null) queryParams['movementType'] = movementType;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get('product/api/v1/stock-movements', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      return [];
    }
  }

  // Create stock movement
  Future<Map<String, dynamic>> createStockMovement(Map<String, dynamic> data) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      // Update product stock based on movement
      final productId = data['productId'];
      final quantity = data['quantity'] as int;
      final movementType = data['movementType'];

      final productIndex = MockData.sampleProducts.indexWhere((p) => p['id'] == productId);
      if (productIndex != -1) {
        final currentStock = MockData.sampleProducts[productIndex]['stock'] as int;
        if (movementType == 'in') {
          MockData.sampleProducts[productIndex]['stock'] = currentStock + quantity;
        } else if (movementType == 'out') {
          MockData.sampleProducts[productIndex]['stock'] = currentStock - quantity;
        } else if (movementType == 'adjustment') {
          MockData.sampleProducts[productIndex]['stock'] = quantity;
        }
      }

      return {
        'id': DateTime.now().millisecondsSinceEpoch,
        ...data,
        'createdAt': DateTime.now().toIso8601String(),
      };
    }

    try {
      final response = await _apiClient.post('product/api/v1/stock-movements', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Get low stock products
  Future<List<Map<String, dynamic>>> getLowStockProducts({
    int? threshold,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final products = MockData.sampleProducts;
      return products.where((p) {
        final stock = p['stock'] as int;
        final lowStockThreshold = p['lowStockThreshold'] as int? ?? 10;
        return stock > 0 && stock <= lowStockThreshold;
      }).toList();
    }

    try {
      final queryParams = <String, dynamic>{};
      if (threshold != null) queryParams['threshold'] = threshold;

      final response = await _apiClient.get('product/api/v1/stock-movements/low-stock', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      return [];
    }
  }

  // Get out of stock products
  Future<List<Map<String, dynamic>>> getOutOfStockProducts() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final products = MockData.sampleProducts;
      return products.where((p) => p['stock'] == 0).toList();
    }

    try {
      final response = await _apiClient.get('product/api/v1/stock-movements/out-of-stock');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      return [];
    }
  }

  // Get critical stock products
  Future<List<Map<String, dynamic>>> getCriticalStockProducts() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final products = MockData.sampleProducts;
      return products.where((p) {
        final stock = p['stock'] as int;
        final lowStockThreshold = p['lowStockThreshold'] as int? ?? 10;
        return stock <= lowStockThreshold;
      }).toList();
    }

    try {
      final response = await _apiClient.get('product/api/v1/stock-movements/critical');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      return [];
    }
  }

  // Adjust stock
  Future<Map<String, dynamic>> adjustStock({
    required int productId,
    required int quantity,
    required String reason,
    String? notes,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      final index = MockData.sampleProducts.indexWhere((p) => p['id'] == productId);
      if (index != -1) {
        MockData.sampleProducts[index]['stock'] = quantity;
        return {
          'success': true,
          'productId': productId,
          'newStock': quantity,
          'reason': reason,
          'notes': notes,
        };
      }
      throw Exception('Product not found');
    }

    try {
      final response = await _apiClient.post('product/api/v1/stock-movements', data: {
        'productId': productId,
        'quantity': quantity,
        'reason': reason,
        'notes': notes,
      });
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Bulk stock update
  Future<List<Map<String, dynamic>>> bulkStockUpdate(List<Map<String, dynamic>> items) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      final results = <Map<String, dynamic>>[];

      for (final item in items) {
        final productId = item['productId'];
        final quantity = item['quantity'];
        final index = MockData.sampleProducts.indexWhere((p) => p['id'] == productId);

        if (index != -1) {
          MockData.sampleProducts[index]['stock'] = quantity;
          results.add({
            'productId': productId,
            'success': true,
            'newStock': quantity,
          });
        }
      }

      return results;
    }

    try {
      final response = await _apiClient.post('product/api/v1/stock-movements/bulk-update', data: {'items': items});
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      rethrow;
    }
  }

  // Get stock statistics
  Future<Map<String, dynamic>> getStockStats() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final products = MockData.sampleProducts;
      return {
        'totalProducts': products.length,
        'lowStockProducts': products.where((p) =>
          p['stock'] <= (p['lowStockThreshold'] ?? 10) && p['stock'] > 0).length,
        'outOfStockProducts': products.where((p) => p['stock'] == 0).length,
        'totalStockValue': products.fold<double>(
          0, (sum, p) => sum + ((p['price'] as num?)?.toDouble() ?? 0) * (p['stock'] as int)),
        'averageStockLevel': products.isNotEmpty
            ? products.fold<int>(0, (sum, p) => sum + (p['stock'] as int)) / products.length
            : 0,
      };
    }

    try {
      final response = await _apiClient.get('product/api/v1/stock-movements/stats');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Stock count/audit
  Future<Map<String, dynamic>> performStockCount(List<Map<String, dynamic>> items) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      final discrepancies = <Map<String, dynamic>>[];

      for (final item in items) {
        final productId = item['productId'];
        final countedQuantity = item['quantity'] as int;
        final product = MockData.sampleProducts.firstWhere(
          (p) => p['id'] == productId,
          orElse: () => {},
        );

        if (product.isNotEmpty) {
          final systemQuantity = product['stock'] as int;
          if (countedQuantity != systemQuantity) {
            discrepancies.add({
              'productId': productId,
              'productName': product['name'],
              'systemQuantity': systemQuantity,
              'countedQuantity': countedQuantity,
              'difference': countedQuantity - systemQuantity,
            });
          }

          // Update stock to counted quantity
          final index = MockData.sampleProducts.indexWhere((p) => p['id'] == productId);
          MockData.sampleProducts[index]['stock'] = countedQuantity;
        }
      }

      return {
        'success': true,
        'totalItems': items.length,
        'discrepancies': discrepancies,
        'discrepancyCount': discrepancies.length,
      };
    }

    try {
      final response = await _apiClient.post('product/api/v1/stock-movements/count', data: {'items': items});
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
