import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/api/api_client.dart';
import 'package:project_pos/features/customers/services/customer_vehicle_service.dart';

/// Sprint 10 — CustomerVehicleService Riverpod provider.
final customerVehicleServiceProvider = Provider<CustomerVehicleService>((ref) {
  return CustomerVehicleService(ref.read(apiClientProvider));
});

/// Müşterinin tüm aktif plakaları (UI dropdown — Sprint 10 plate picker).
///
/// `customerId` boş ise boş liste döner. autoDispose +
/// family — modal kapanınca temizlenir, her müşteri için ayrı cache.
final customerVehiclesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, customerId) async {
  if (customerId.isEmpty) return [];
  return ref
      .read(customerVehicleServiceProvider)
      .listByCustomer(customerId);
});

/// Plate prefix arama (autocomplete) — debounce çağıran widget'tan beklenir.
/// Tuple: `(customerId, query)`.
class CustomerVehicleSearchKey {
  final String customerId;
  final String query;
  const CustomerVehicleSearchKey(this.customerId, this.query);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerVehicleSearchKey &&
          customerId == other.customerId &&
          query == other.query;

  @override
  int get hashCode => Object.hash(customerId, query);
}

final customerVehicleSearchProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, CustomerVehicleSearchKey>(
        (ref, key) async {
  if (key.customerId.isEmpty) return [];
  return ref
      .read(customerVehicleServiceProvider)
      .search(key.customerId, key.query);
});
