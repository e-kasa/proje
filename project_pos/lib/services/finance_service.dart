import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/utils/app_logger.dart';

/// Finance Service - Gelir/Gider yonetimi
class FinanceService {
  final ApiClient _apiClient;

  FinanceService(this._apiClient);

  // Get all expenses
  Future<List<Map<String, dynamic>>> getExpenses({
    String? category,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get('product/api/v1/finance/expenses', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      AppLogger.error('Failed to fetch expenses', tag: 'FinanceService', error: e);
      rethrow;
    }
  }

  // Get all revenues
  Future<List<Map<String, dynamic>>> getRevenues({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get('product/api/v1/finance/revenues', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      AppLogger.error('Failed to fetch revenues', tag: 'FinanceService', error: e);
      rethrow;
    }
  }

  // Get single expense by ID
  Future<Map<String, dynamic>> getExpenseById(int id) async {
    try {
      final response = await _apiClient.get('product/api/v1/finance/expenses/$id');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to fetch expense by id: $id', tag: 'FinanceService', error: e);
      rethrow;
    }
  }

  // Create new expense
  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('product/api/v1/finance/expenses', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to create expense', tag: 'FinanceService', error: e);
      rethrow;
    }
  }

  // Create new revenue
  Future<Map<String, dynamic>> createRevenue(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('product/api/v1/finance/revenues', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to create revenue', tag: 'FinanceService', error: e);
      rethrow;
    }
  }

  // Update expense
  Future<Map<String, dynamic>> updateExpense(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('product/api/v1/finance/expenses/$id', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to update expense: $id', tag: 'FinanceService', error: e);
      rethrow;
    }
  }

  // Delete expense
  Future<bool> deleteExpense(int id) async {
    try {
      await _apiClient.delete('product/api/v1/finance/expenses/$id');
      return true;
    } catch (e) {
      AppLogger.error('Failed to delete expense: $id', tag: 'FinanceService', error: e);
      rethrow;
    }
  }

  // Delete revenue
  Future<bool> deleteRevenue(int id) async {
    try {
      await _apiClient.delete('product/api/v1/finance/revenues/$id');
      return true;
    } catch (e) {
      AppLogger.error('Failed to delete revenue: $id', tag: 'FinanceService', error: e);
      rethrow;
    }
  }

  // Get financial summary
  Future<Map<String, dynamic>> getSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _apiClient.get('product/api/v1/finance/summary', queryParameters: queryParams);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to fetch finance summary', tag: 'FinanceService', error: e);
      rethrow;
    }
  }

  // Get expense categories
  Future<List<Map<String, dynamic>>> getExpenseCategories() async {
    try {
      final response = await _apiClient.get('product/api/v1/finance/expense-categories');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      AppLogger.error('Failed to fetch expense categories', tag: 'FinanceService', error: e);
      rethrow;
    }
  }
}
