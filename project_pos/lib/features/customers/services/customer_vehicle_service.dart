import 'package:project_pos/core/api/api_client.dart';
import 'package:project_pos/core/utils/app_logger.dart';

/// Sprint 10 — CustomerVehicle (parçacı sektör plaka takibi) HTTP servisi.
///
/// Backend endpoint kataloğu (Sprint 9):
///   GET    /customers/{id}/vehicles
///   GET    /customers/{id}/vehicles/search?q=
///   GET    /customers/{id}/vehicles/{vid}
///   POST   /customers/{id}/vehicles                 (idempotent)
///   PUT    /customers/{id}/vehicles/{vid}
///   DELETE /customers/{id}/vehicles/{vid}           (soft-delete)
class CustomerVehicleService {
  final ApiClient _apiClient;

  CustomerVehicleService(this._apiClient);

  static String _base(String customerId) =>
      'product/api/v1/customers/$customerId/vehicles';

  /// Müşterinin aktif plakaları.
  Future<List<Map<String, dynamic>>> listByCustomer(String customerId) async {
    try {
      final response = await _apiClient.get(_base(customerId));
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      AppLogger.error('CustomerVehicle list hatası',
          tag: 'CustomerVehicleService', error: e);
      rethrow;
    }
  }

  /// Plaka prefix arama (autocomplete; backend normalize eder).
  Future<List<Map<String, dynamic>>> search(
      String customerId, String query) async {
    try {
      final response = await _apiClient.get(
        '${_base(customerId)}/search',
        queryParameters: {if (query.isNotEmpty) 'q': query},
      );
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      AppLogger.error('CustomerVehicle search hatası',
          tag: 'CustomerVehicleService', error: e);
      rethrow;
    }
  }

  /// Yeni plaka ekleme — backend idempotent: aynı normalized varsa mevcut döner.
  Future<Map<String, dynamic>> create(
      String customerId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(_base(customerId), data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('CustomerVehicle create hatası',
          tag: 'CustomerVehicleService', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> update(
      String customerId, String vehicleId, Map<String, dynamic> data) async {
    try {
      final response =
          await _apiClient.put('${_base(customerId)}/$vehicleId', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('CustomerVehicle update hatası',
          tag: 'CustomerVehicleService', error: e);
      rethrow;
    }
  }

  /// Soft-delete (isActive=false).
  Future<void> deactivate(String customerId, String vehicleId) async {
    try {
      await _apiClient.delete('${_base(customerId)}/$vehicleId');
    } catch (e) {
      AppLogger.error('CustomerVehicle deactivate hatası',
          tag: 'CustomerVehicleService', error: e);
      rethrow;
    }
  }
}
