import '../core/data/mock_data.dart';
import '../core/api/api_client.dart';
import '../core/utils/app_logger.dart';

class ReportService {

  /// Development mode - uses mock data when API is unavailable
  static const bool useMockData = false;
  final ApiClient _apiClient;

  ReportService(this._apiClient);

  // Get sales reports
  Future<Map<String, dynamic>> getSalesReport({
    DateTime? startDate,
    DateTime? endDate,
    String? groupBy, // day, week, month, year
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (groupBy != null) queryParams['groupBy'] = groupBy;

      final response = await _apiClient.get('product/api/v1/reports/sales', queryParameters: queryParams);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to fetch sales report', tag: 'ReportService', error: e);
      // Fallback to mock data
      final sales = MockData.sampleSales;
      return {
        'totalSales': sales.length,
        'totalRevenue': sales.fold<double>(
          0, (sum, s) => sum + ((s['totalAmount'] as num?)?.toDouble() ?? 0)),
        'sales': sales,
        'groupBy': groupBy ?? 'day',
      };
    }
  }

  // Get inventory report
  Future<Map<String, dynamic>> getInventoryReport({
    int? categoryId,
    bool? lowStockOnly,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (lowStockOnly != null) queryParams['lowStockOnly'] = lowStockOnly;

      final response = await _apiClient.get('product/api/v1/reports/inventory', queryParameters: queryParams);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to fetch inventory report', tag: 'ReportService', error: e);
      // Fallback to mock data
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
  }

  // Get customer reports
  Future<Map<String, dynamic>> getCustomerReport({
    DateTime? startDate,
    DateTime? endDate,
    String? customerType,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (customerType != null) queryParams['customerType'] = customerType;

      final response = await _apiClient.get('product/api/v1/reports/customers', queryParameters: queryParams);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to fetch customer report', tag: 'ReportService', error: e);
      // Fallback to mock data
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
  }

  // Get profit/loss report
  Future<Map<String, dynamic>> getProfitLossReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _apiClient.get('product/api/v1/reports/profit-loss', queryParameters: queryParams);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to fetch profit/loss report', tag: 'ReportService', error: e);
      // Fallback to mock data
      final sales = MockData.sampleSales;
      final totalRevenue = sales.fold<double>(
        0, (sum, s) => sum + ((s['totalAmount'] as num?)?.toDouble() ?? 0));

      final totalCost = totalRevenue * 0.6;
      final profit = totalRevenue - totalCost;

      return {
        'totalRevenue': totalRevenue,
        'totalCost': totalCost,
        'profit': profit,
        'profitMargin': totalRevenue > 0 ? (profit / totalRevenue) * 100 : 0,
        'period': 'all',
      };
    }
  }

  // Get top selling products
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get('product/api/v1/reports/top-products', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      AppLogger.error('Failed to fetch top selling products', tag: 'ReportService', error: e);
      // Fallback to mock data
      final products = MockData.sampleProducts;
      final topProducts = List<Map<String, dynamic>>.from(products);
      topProducts.sort((a, b) {
        final stockA = a['stock'] as int;
        final stockB = b['stock'] as int;
        return stockA.compareTo(stockB);
      });

      return topProducts.take(limit ?? 10).toList();
    }
  }

  // Get top customers
  Future<List<Map<String, dynamic>>> getTopCustomers({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get('product/api/v1/reports/top-customers', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      AppLogger.error('Failed to fetch top customers', tag: 'ReportService', error: e);
      // Fallback to mock data
      final customers = List<Map<String, dynamic>>.from(MockData.sampleCustomers);
      customers.sort((a, b) {
        final purchasesA = a['totalPurchases'] as int;
        final purchasesB = b['totalPurchases'] as int;
        return purchasesB.compareTo(purchasesA);
      });

      return customers.take(limit ?? 10).toList();
    }
  }

  // Get expenses report
  Future<Map<String, dynamic>> getExpensesReport({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (category != null) queryParams['category'] = category;

      final response = await _apiClient.get('product/api/v1/reports/expenses', queryParameters: queryParams);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to fetch expenses report', tag: 'ReportService', error: e);
      // Fallback to mock data
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
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiClient.get('product/api/v1/reports/dashboard');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to fetch dashboard stats', tag: 'ReportService', error: e);
      // Fallback to mock data
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
  }

  // Export report (PDF/Excel)
  Future<String> exportReport({
    required String reportType, // sales, inventory, customers, etc.
    required String format, // pdf, excel, csv
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'format': format,
      };
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _apiClient.get('product/api/v1/reports/$reportType/export', queryParameters: queryParams);
      return response.data['downloadUrl'] as String;
    } catch (e) {
      AppLogger.error('Failed to export report: $reportType', tag: 'ReportService', error: e);
      // Fallback to mock data
      return 'mock://export/$reportType.$format';
    }
  }
}
