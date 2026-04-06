import '../core/api/api_client.dart';

/// Müşteri servisi — Müşteri CRUD işlemleri için backend API çağrıları.
///
/// Backend endpoint: `product/api/v1/customers`
class CustomerService {
  final ApiClient _apiClient;
  static const String _base = 'product/api/v1/customers';

  CustomerService(this._apiClient);

  /// Müşteri listesini getirir.
  ///
  /// [search] ile arama, [isActive] ile durum filtreleme, [page] ve [limit] ile sayfalama destekler.
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

  /// Tek bir müşteriyi ID ile getirir.
  Future<Map<String, dynamic>?> getCustomerById(String id) async {
    try {
      final response = await _apiClient.get('$_base/$id');
      final data = response.data['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      rethrow;
    }
  }

  /// Yeni müşteri oluşturur.
  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(_base, data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Müşteri bilgilerini günceller.
  Future<Map<String, dynamic>> updateCustomer(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('$_base/$id', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Müşteriyi siler (soft delete).
  Future<void> deleteCustomer(String id) async {
    try {
      await _apiClient.delete('$_base/$id');
    } catch (e) {
      rethrow;
    }
  }

  /// Müşteri aktif/pasif durumunu değiştirir.
  Future<Map<String, dynamic>> toggleStatus(String id) async {
    try {
      final response = await _apiClient.patch('$_base/$id/toggle-status');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}