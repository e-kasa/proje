import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/services/service_locator.dart';

/// Sprint 11 — `(customerId, vehiclePlate)` tuple key.
/// vehiclePlate null/empty → o müşterinin tüm açık satışları (Sprint 7 davranışı).
class CustomerOpenSalesKey {
  final String customerId;
  final String? vehiclePlate;

  const CustomerOpenSalesKey(this.customerId, {this.vehiclePlate});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerOpenSalesKey &&
          customerId == other.customerId &&
          vehiclePlate == other.vehiclePlate;

  @override
  int get hashCode => Object.hash(customerId, vehiclePlate);
}

/// Acik bakiyeli satislar — Sprint 7 alisveris bazli odeme picker icin.
/// Sprint 11: `vehiclePlate` opsiyonel filtre — o plakaya ait satislar.
///
/// Kullanim:
/// ```dart
/// final all = ref.watch(customerOpenSalesProvider(
///   const CustomerOpenSalesKey('cus-xyz')));            // tum acik satislar
/// final filtered = ref.watch(customerOpenSalesProvider(
///   const CustomerOpenSalesKey('cus-xyz', vehiclePlate: '34ABC123')));
/// ```
final customerOpenSalesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, CustomerOpenSalesKey>(
        (ref, key) async {
  if (key.customerId.isEmpty) return [];
  return ref.read(salesServiceProvider).getCustomerOpenSales(
        key.customerId,
        vehiclePlate: key.vehiclePlate,
      );
});
