import '../core/api/api_client.dart';

class CustomerService {
  final ApiClient _apiClient;
  static const String _base = 'product/api/v1/customers';

  CustomerService(this._apiClient);

  // Get all customers
  Future<List<Map<String, dynamic>>> getCustomers({
    String? search,
    bool? isActive,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null) queryParams['search'] = search;
      if (isActive != null) queryParams['isActive'] = isActive;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get(_base, queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      rethrow;
    }
  }

  // Get single customer by ID
  Future<Map<String, dynamic>?> getCustomerById(String id) async {
    try {
      final response = await _apiClient.get('$_base/$id');
      final data = response.data['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      rethrow;
    }
  }

  // Create new customer
  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(_base, data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Update customer
  Future<Map<String, dynamic>> updateCustomer(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('$_base/$id', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Delete customer (soft delete)
  Future<void> deleteCustomer(String id) async {
    try {
      await _apiClient.delete('$_base/$id');
    } catch (e) {
      rethrow;
    }
  }

  // Toggle customer status
  Future<Map<String, dynamic>> toggleStatus(String id) async {
    try {
      final response = await _apiClient.patch('$_base/$id/toggle-status');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Get customer statistics
  Future<Map<String, dynamic>> getCustomerStats() async {
    try {
      final response = await _apiClient.get('$_base/stats');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
