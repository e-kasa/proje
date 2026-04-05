import '../core/api/api_client.dart';

class SalesReportService {
  final ApiClient _apiClient;
  static const String _base = 'product/api/v1/reports/sales';

  SalesReportService(this._apiClient);

  Future<Map<String, dynamic>?> getSalesSummary({
    required String startDate,
    required String endDate,
    String groupBy = 'day',
  }) async {
    try {
      final resp = await _apiClient.get(
        '$_base/summary',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          'groupBy': groupBy,
        },
      );
      final data = resp.data['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getProductSalesAnalysis({
    required String startDate,
    required String endDate,
    int limit = 20,
  }) async {
    try {
      final resp = await _apiClient.get(
        '$_base/by-product',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          'limit': limit.toString(),
        },
      );
      return List<Map<String, dynamic>>.from(resp.data['data'] ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerSalesAnalysis({
    required String startDate,
    required String endDate,
    int limit = 20,
  }) async {
    try {
      final resp = await _apiClient.get(
        '$_base/by-customer',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          'limit': limit.toString(),
        },
      );
      return List<Map<String, dynamic>>.from(resp.data['data'] ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getProfitOverview({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final resp = await _apiClient.get(
        '$_base/profit-overview',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
      );
      final data = resp.data['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      rethrow;
    }
  }
}
