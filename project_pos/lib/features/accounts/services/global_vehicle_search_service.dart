import 'package:flutter/foundation.dart';
import 'package:project_pos/core/api/api_client.dart';

/// Sprint 11e — Tenant-wide plaka arama servisi.
///
/// AccountsList plaka modunda kullanılır: müşteri ismi bilinmeden plaka
/// prefix yazılınca müşteri+plaka eşleşmeleri açık satış özeti ile döner.
///
/// Endpoint: `GET /product/api/v1/vehicles/search?q=&limit=20`
/// Response item alanları:
///   - `id` (CustomerVehicle PK)
///   - `customerId`, `customerName`
///   - `plateDisplay`, `plateNormalized`
///   - `make`, `model`
///   - `openSalesCount` (long), `openSalesAmount` (BigDecimal)
class GlobalVehicleSearchService {
  final ApiClient _apiClient;
  static const String _base = 'product/api/v1/vehicles';

  GlobalVehicleSearchService(this._apiClient);

  /// Plaka prefix arama. Boş query → boş liste (server side da kontrol var ama
  /// ekstra round-trip yapmamak için client'ta da filtrele).
  Future<List<Map<String, dynamic>>> search(String q, {int limit = 20}) async {
    if (q.trim().isEmpty) return const [];
    try {
      final resp = await _apiClient.get(
        '$_base/search',
        queryParameters: {
          'q': q.trim(),
          'limit': limit,
        },
      );
      final data = resp.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return const [];
    } catch (e) {
      debugPrint('GlobalVehicleSearch hata: $e');
      rethrow;
    }
  }
}
