import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/services/service_locator.dart';

/// Acik bakiyeli satislar — Sprint 7 alisveris bazli odeme picker icin.
///
/// `customerId` verince backend'den o musterinin pending statuslu (kalan bakiye > 0,
/// iptal degil) satislarini getirir. Yeniden eskiye sirali. autoDispose +
/// family — modal kapaninca temizlenir, her musteri icin ayri cache.
///
/// Kullanim:
/// ```dart
/// final salesAsync = ref.watch(customerOpenSalesProvider(customerId));
/// salesAsync.when(
///   data: (list) => ...,
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Hata: $e'),
/// );
/// ```
final customerOpenSalesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, customerId) async {
  if (customerId.isEmpty) return [];
  return ref.read(salesServiceProvider).getCustomerOpenSales(customerId);
});
