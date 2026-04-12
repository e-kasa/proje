import 'package:project_pos/core/api/api_client.dart';
import 'package:project_pos/core/utils/app_logger.dart';

class PaymentService {
  final ApiClient _apiClient;
  static const String _base = 'product/api/v1/payments';

  PaymentService(this._apiClient);

  Future<List<Map<String, dynamic>>> getPayments({
    String? type, // 'income' or 'expense'
    String? startDate,
    String? endDate,
    String? relatedParty, // customer or supplier name
    int? page,
    int? limit,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (type != null) params['type'] = type;
      if (startDate != null) params['startDate'] = startDate;
      if (endDate != null) params['endDate'] = endDate;
      if (relatedParty != null) params['relatedParty'] = relatedParty;
      if (page != null) params['page'] = page;
      if (limit != null) params['limit'] = limit;
      final response = await _apiClient.get(_base, queryParameters: params);
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      AppLogger.error('Odemeler yuklenemedi', tag: 'PaymentService', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPayment(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(_base, data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Odeme olusturulamadi', tag: 'PaymentService', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCashFlowSummary({String? period, String? startDate, String? endDate}) async {
    try {
      final params = <String, dynamic>{};
      if (period != null) params['period'] = period;
      if (startDate != null) params['startDate'] = startDate;
      if (endDate != null) params['endDate'] = endDate;
      final response = await _apiClient.get('$_base/cash-flow', queryParameters: params);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Nakit akisi yuklenemedi', tag: 'PaymentService', error: e);
      rethrow;
    }
  }
}
