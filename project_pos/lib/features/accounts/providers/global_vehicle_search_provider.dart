import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/api/api_client.dart';
import 'package:project_pos/features/accounts/services/global_vehicle_search_service.dart';

/// Sprint 11e — Tenant-wide plaka arama servisi provider'ı.
final globalVehicleSearchServiceProvider =
    Provider<GlobalVehicleSearchService>((ref) {
  return GlobalVehicleSearchService(ref.watch(apiClientProvider));
});

/// Sprint 11e — Plaka prefix arama sonuçları (debounced upstream caller).
///
/// Family parametresi: trim edilmiş query string. Boş string → boş liste
/// (server round-trip yok). autoDispose: kullanıcı arama kutusunu kapatınca
/// cache temizlenir.
///
/// Sonuç item alanları (`Map<String, dynamic>`):
///   - `id` (CustomerVehicle PK)
///   - `customerId`, `customerName`
///   - `plateDisplay`, `plateNormalized`
///   - `make`, `model`
///   - `openSalesCount` (num), `openSalesAmount` (num)
final globalVehicleSearchProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, q) async {
  final query = q.trim();
  if (query.isEmpty) return const [];
  return ref.read(globalVehicleSearchServiceProvider).search(query);
});
