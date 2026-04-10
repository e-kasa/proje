import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';

class StockReportService {
  final ApiClient _apiClient;
  static const String _base = 'product/api/v1/reports/stock';

  StockReportService(this._apiClient);

  Future<Map<String, dynamic>?> getStockValueSummary() async {
    try {
      final resp = await _apiClient.get('$_base/value-summary');
      final data = resp.data['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getMovementSummary({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final resp = await _apiClient.get(
        '$_base/movement-summary',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
      );
      final data = resp.data['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCriticalAlerts() async {
    try {
      final resp = await _apiClient.get('$_base/critical-alerts');
      return List<Map<String, dynamic>>.from(resp.data['data'] ?? []);
    } catch (e) {
      debugPrint('getCriticalAlerts hata: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getWarehouseBreakdown(String warehouseId) async {
    try {
      final resp = await _apiClient.get(
        '$_base/warehouse-breakdown',
        queryParameters: {'warehouseId': warehouseId},
      );
      final data = resp.data['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      rethrow;
    }
  }
}
