import '../core/api/api_client.dart';
import '../core/utils/app_logger.dart';

class ReportService {
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
      rethrow;
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
      rethrow;
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
      rethrow;
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
      rethrow;
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
      rethrow;
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
      rethrow;
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
      rethrow;
    }
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiClient.get('product/api/v1/reports/dashboard');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to fetch dashboard stats', tag: 'ReportService', error: e);
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
      rethrow;
    }
  }
}
