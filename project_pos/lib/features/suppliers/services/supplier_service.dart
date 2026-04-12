import 'package:flutter/foundation.dart';
import 'package:project_pos/core/api/api_client.dart';

/// Supplier Service - handles all supplier-related API calls
class SupplierService {

  final ApiClient _apiClient;
  static const String _base = 'product/api/v1/suppliers';
  SupplierService(this._apiClient);

  /// Get all suppliers with optional filters
  Future<List<Map<String, dynamic>>> getSuppliers({
    String? search,
    String? status, // ACTIVE, INACTIVE
    int? page,
    int? limit,
  }) async { try {
    final params = <String, dynamic>{};
    if (search != null) params['search'] = search;
    // Backend isActive (boolean) bekliyor, Flutter status string gönderiyor
    if (status != null) {
      if (status == 'ACTIVE') params['isActive'] = true;
      if (status == 'INACTIVE') params['isActive'] = false;
    }

    final response = await _apiClient.get(_base, queryParameters: params);
    final data = response.data['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  } catch (e) {
    throw Exception('Satın alma listesi alınamadı: $e');
  }
  }

  /// Create new supplier
  Future<Map<String, dynamic>> createSupplier(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('product/api/v1/suppliers', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Update supplier
  Future<Map<String, dynamic>> updateSupplier(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('product/api/v1/suppliers/$id', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete supplier (soft delete - set status to INACTIVE)
  Future<void> deleteSupplier(String id) async {
    try {
      await _apiClient.delete('product/api/v1/suppliers/$id');
    } catch (e) {
      debugPrint('deleteSupplier hata: $e');
      rethrow;
    }
  }

  /// Toggle supplier status
  Future<Map<String, dynamic>> toggleStatus(String id) async {
    try {
      final response = await _apiClient.patch('product/api/v1/suppliers/$id/toggle-status');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Get supplier statistics
  Future<Map<String, dynamic>> getSupplierStats() async {
    try {
      final response = await _apiClient.get('product/api/v1/suppliers/stats');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Get suggested suppliers for a specific product variant
  /// (Returns suppliers who previously supplied this variant)
  Future<List<Map<String, dynamic>>> getSuggestedSuppliers(String variantSku) async {

    try {
      final response = await _apiClient.get('product/api/v1/suppliers/suggested/$variantSku');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getSupplierById(String id) async {
    try {
      final response = await _apiClient.get('product/api/v1/suppliers/$id');
      final data = response.data['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getSupplierAccount(String id) async {
    try {
      final response = await _apiClient.get('$_base/$id/account');
      final data = response.data['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      debugPrint('getSupplierAccount hata: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSupplierTransactions(String id) async {
    try {
      final response = await _apiClient.get('$_base/$id/transactions');
      final data = response.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      debugPrint('getSupplierTransactions hata: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> recordPayment(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('$_base/$id/payment', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateCreditLimit(
      String id, double newLimit) async {
    try {
      final response = await _apiClient.put('$_base/$id/credit-limit',
          data: {'creditLimit': newLimit});
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> recordSupplierPayment(String supplierId, Map<String, dynamic> data) async {
    try {
      await _apiClient.post('$_base/$supplierId/payments', data: data);
    } catch (e) {
      debugPrint('recordSupplierPayment hata: $e');
      rethrow;
    }
  }
}
