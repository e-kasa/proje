import '../core/data/mock_data.dart';
import '../core/api/api_client.dart';

class ReportService {

  /// Development mode - uses mock data when API is unavailable
  static const bool useMockData = true;
  final ApiClient _apiClient;

  ReportService(this._apiClient);

  // Get sales reports
  Future<Map<String, dynamic>> getSalesReport({
    DateTime? startDate,
    DateTime? endDate,
    String? groupBy, // day, week, month, year
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      final sales = MockData.sampleSales;
      return {
        'totalSales': sales.length,
        'totalRevenue': sales.fold<double>(
          0, (sum, s) => sum + ((s['totalAmount'] as num?)?.toDouble() ?? 0)),
        'sales': sales,
        'groupBy': groupBy ?? 'day',
      };
    }

    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (groupBy != null) queryParams['groupBy'] = groupBy;

      final response = await _apiClient.get('api/reports/sales', queryParameters: queryParams);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Get inventory report
  Future<Map<String, dynamic>> getInventoryReport({
    int? categoryId,
    bool? lowStockOnly,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      var products = List<Map<String, dynamic>>.from(MockData.sampleProducts);

      if (lowStockOnly == true) {
        products = products.where((p) =>
          p['stock'] <= (p['lowStockThreshold'] ?? 10)).toList();
      }

      return {
        'totalProducts': products.length,
        'totalStockValue': products.fold<double>(
          0, (sum, p) => sum + ((p['price'] as num?)?.toDouble() ?? 0) * (p['stock'] as int)),
        'products': products,
        'lowStockCount': products.where((p) =>
          p['stock'] <= (p['lowStockThreshold'] ?? 10) && p['stock'] > 0).length,
        'outOfStockCount': products.where((p) => p['stock'] == 0).length,
      };
    }

    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (lowStockOnly != null) queryParams['lowStockOnly'] = lowStockOnly;

      final response = await _apiClient.get('api/reports/inventory', queryParameters: queryParams);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Get customer reports
  Future<Map<String, dynamic>> getCustomerReport({
    DateTime? startDate,
    DateTime? endDate,
    String? customerType,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      var customers = List<Map<String, dynamic>>.from(MockData.sampleCustomers);

      if (customerType != null) {
        customers = customers.where((c) => c['customerType'] == customerType).toList();
      }

      return {
        'totalCustomers': customers.length,
        'customers': customers,
        'vipCount': customers.where((c) => c['customerType'] == 'vip').length,
        'regularCount': customers.where((c) => c['customerType'] == 'regular').length,
        'totalLoyaltyPoints': customers.fold<int>(
          0, (sum, c) => sum + (c['loyaltyPoints'] as int? ?? 0)),
      };
    }

    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (customerType != null) queryParams['customerType'] = customerType;

      final response = await _apiClient.get('api/reports/customers', queryParameters: queryParams);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Get profit/loss report
  Future<Map<String, dynamic>> getProfitLossReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      final sales = MockData.sampleSales;
      final totalRevenue = sales.fold<double>(
        0, (sum, s) => sum + ((s['totalAmount'] as num?)?.toDouble() ?? 0));

      // Mock costs (would come from purchases/expenses in real app)
      final totalCost = totalRevenue * 0.6; // Assume 60% cost
      final profit = totalRevenue - totalCost;

      return {
        'totalRevenue': totalRevenue,
        'totalCost': totalCost,
        'profit': profit,
        'profitMargin': totalRevenue > 0 ? (profit / totalRevenue) * 100 : 0,
        'period': 'all',
      };
    }

    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _apiClient.get('api/reports/profit-loss', queryParameters: queryParams);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Get top selling products
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final products = MockData.sampleProducts;
      // Return top products based on low stock (simulating high sales)
      final topProducts = List<Map<String, dynamic>>.from(products);
      topProducts.sort((a, b) {
        final stockA = a['stock'] as int;
        final stockB = b['stock'] as int;
        return stockA.compareTo(stockB); // Lower stock = higher sales
      });

      return topProducts.take(limit ?? 10).toList();
    }

    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get('api/reports/top-products', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      return [];
    }
  }

  // Get top customers
  Future<List<Map<String, dynamic>>> getTopCustomers({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final customers = List<Map<String, dynamic>>.from(MockData.sampleCustomers);
      customers.sort((a, b) {
        final purchasesA = a['totalPurchases'] as int;
        final purchasesB = b['totalPurchases'] as int;
        return purchasesB.compareTo(purchasesA); // More purchases = higher rank
      });

      return customers.take(limit ?? 10).toList();
    }

    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get('api/reports/top-customers', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      return [];
    }
  }

  // Get expenses report
  Future<Map<String, dynamic>> getExpensesReport({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      // Mock expenses data
      return {
        'totalExpenses': 15000.0,
        'expenses': [
          {'category': 'Rent', 'amount': 5000.0},
          {'category': 'Utilities', 'amount': 1500.0},
          {'category': 'Salaries', 'amount': 8000.0},
          {'category': 'Other', 'amount': 500.0},
        ],
        'period': 'month',
      };
    }

    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (category != null) queryParams['category'] = category;

      final response = await _apiClient.get('api/reports/expenses', queryParameters: queryParams);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final products = MockData.sampleProducts;
      final sales = MockData.sampleSales;
      final customers = MockData.sampleCustomers;

      return {
        'totalProducts': products.length,
        'activeProducts': products.where((p) => p['isActive'] == true).length,
        'lowStockProducts': products.where((p) =>
          p['stock'] <= (p['lowStockThreshold'] ?? 10)).length,
        'totalSales': sales.length,
        'totalRevenue': sales.fold<double>(
          0, (sum, s) => sum + ((s['totalAmount'] as num?)?.toDouble() ?? 0)),
        'totalCustomers': customers.length,
        'vipCustomers': customers.where((c) => c['customerType'] == 'vip').length,
        'recentSales': sales.take(5).toList(),
        'lowStockItems': products.where((p) =>
          p['stock'] <= (p['lowStockThreshold'] ?? 10)).take(5).toList(),
      };
    }

    try {
      final response = await _apiClient.get('api/reports/dashboard');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Export report (PDF/Excel)
  Future<String> exportReport({
    required String reportType, // sales, inventory, customers, etc.
    required String format, // pdf, excel, csv
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return 'mock://export/$reportType.$format';
    }

    try {
      final queryParams = <String, dynamic>{
        'format': format,
      };
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _apiClient.get('api/reports/$reportType/export', queryParameters: queryParams);
      return response.data['downloadUrl'] as String;
    } catch (e) {
      rethrow;
    }
  }
}
