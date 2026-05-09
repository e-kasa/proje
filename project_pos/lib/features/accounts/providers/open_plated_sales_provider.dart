import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/services/service_locator.dart';

/// Sprint 11f — Tenant-wide ödenmemiş plakalı satışlar.
///
/// AccountsList plaka modunda input boşken (kullanıcı henüz plaka yazmadı)
/// bu liste otomatik yüklenir → "kim borçlu?" senaryosu için anında cevap.
/// Kullanıcı input'a plaka yazınca arama
/// [globalVehicleSearchProvider]'a düşer (mevcut Sprint 11e davranışı).
///
/// Sonuç item alanları (`Map<String, dynamic>`) — `SaleControllerImpl.toMap`:
///   - `id`, `saleNumber`, `saleDate`, `totalAmount`, `paidAmount`,
///     `remainingAmount`, `customerId`, `customerName`, `vehiclePlate`,
///     `status` ('pending'), `items` (SaleItem array)
final openPlatedSalesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.read(salesServiceProvider).getOpenWithPlate();
});
