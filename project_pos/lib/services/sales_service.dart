import '../core/data/mock_data.dart';
import '../core/api/api_client.dart';

class SalesService {

  /// Development mode - uses mock data when API is unavailable
  static const bool useMockData = false;
  final ApiClient _apiClient;

  SalesService(this._apiClient);

  // Get all sales
  Future<List<Map<String, dynamic>>> getSales({
    DateTime? startDate,
    DateTime? endDate,
    int? customerId,
    String? paymentMethod, // cash, credit_card, debit_card, bank_transfer
    String? paymentStatus, // paid, pending, cancelled
    int? page,
    int? limit,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      var sales = List<Map<String, dynamic>>.from(MockData.sampleSales);

      if (customerId != null) {
        sales = sales.where((s) => s['customerId'] == customerId).toList();
      }

      if (paymentMethod != null) {
        sales = sales.where((s) => s['paymentMethod'] == paymentMethod).toList();
      }

      if (paymentStatus != null) {
        sales = sales.where((s) => s['status'] == paymentStatus).toList();
      }

      return sales;
    }

    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (customerId != null) queryParams['customerId'] = customerId;
      if (paymentMethod != null) queryParams['paymentMethod'] = paymentMethod;
      if (paymentStatus != null) queryParams['paymentStatus'] = paymentStatus;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get('product/api/v1/sales', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      return MockData.sampleSales;
    }
  }

  static const String _base = 'product/api/v1/sales';

  // Get single sale by ID
  Future<Map<String, dynamic>> getSaleById(String id) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return MockData.sampleSales.firstWhere(
        (s) => s['id'] == id,
        orElse: () => {},
      );
    }

    try {
      final response = await _apiClient.get('$_base/$id');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      return MockData.sampleSales.firstWhere(
        (s) => s['id'] == id,
        orElse: () => {},
      );
    }
  }

  // Create new sale (POS)
  Future<Map<String, dynamic>> createSale(Map<String, dynamic> data) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      final newSale = {
        'id': 'SALE-${DateTime.now().millisecondsSinceEpoch}',
        ...data,
        'createdAt': DateTime.now().toIso8601String(),
      };
      MockData.sampleSales.add(newSale);
      return newSale;
    }

    try {
      final response = await _apiClient.post(_base, data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Update sale
  Future<Map<String, dynamic>> updateSale(String id, Map<String, dynamic> data) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      final index = MockData.sampleSales.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        MockData.sampleSales[index] = {
          ...MockData.sampleSales[index],
          ...data,
        };
        return MockData.sampleSales[index];
      }
      throw Exception('Sale not found');
    }

    try {
      final response = await _apiClient.put('$_base/$id', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Cancel sale
  Future<Map<String, dynamic>> cancelSale(String id, String reason) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      final index = MockData.sampleSales.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        MockData.sampleSales[index]['status'] = 'cancelled';
        MockData.sampleSales[index]['cancelReason'] = reason;
        return MockData.sampleSales[index];
      }
      throw Exception('Sale not found');
    }

    try {
      final response = await _apiClient.put('$_base/$id/cancel', data: {'reason': reason});
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Get sale items
  Future<List<Map<String, dynamic>>> getSaleItems(String saleId) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final sale = MockData.sampleSales.firstWhere(
        (s) => s['id'] == saleId,
        orElse: () => {},
      );
      return List<Map<String, dynamic>>.from(sale['items'] ?? []);
    }

    try {
      final response = await _apiClient.get('$_base/$saleId/items');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      return [];
    }
  }

  // Get sales statistics
  Future<Map<String, dynamic>> getSalesStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final sales = MockData.sampleSales;
      return {
        'totalSales': sales.length,
        'totalRevenue': sales.fold<double>(
          0, (sum, s) => sum + ((s['totalAmount'] as num?)?.toDouble() ?? 0)),
        'completedSales': sales.where((s) => s['status'] == 'completed').length,
        'pendingSales': sales.where((s) => s['status'] == 'pending').length,
        'averageOrderValue': sales.isNotEmpty
            ? sales.fold<double>(0, (sum, s) => sum + ((s['totalAmount'] as num?)?.toDouble() ?? 0)) / sales.length
            : 0,
      };
    }

    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _apiClient.get('$_base/stats', queryParameters: queryParams);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Get daily sales report
  Future<List<Map<String, dynamic>>> getDailySalesReport({
    DateTime? date,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return MockData.sampleSales;
    }

    try {
      final queryParams = <String, dynamic>{};
      if (date != null) queryParams['date'] = date.toIso8601String();

      final response = await _apiClient.get('$_base/daily-report', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      return MockData.sampleSales;
    }
  }

  // Print receipt
  Future<Map<String, dynamic>> printReceipt(String saleId) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {'success': true, 'message': 'Receipt printed (mock mode)'};
    }

    try {
      final response = await _apiClient.post('$_base/$saleId/print');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
