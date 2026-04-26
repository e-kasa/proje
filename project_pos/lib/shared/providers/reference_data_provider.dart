import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/sector_config.dart';

/// Sprint 12 W1.2 — Ürün ekranlarında kullanılan referans verileri için
/// tek hakikat noktası.
///
/// Önceki durum: KDV oranları + birim kodları farklı dosyalarda hardcoded
/// (`edit_product_modal.dart`, wizard step'leri, batch entry). Aynı listenin
/// drift'i (ör. KDV %20 bir yere eklenir, başka yerde unutulur) tutarsızlığa
/// yol açıyordu.
///
/// Bu provider: tüm ekranlar buradan okur. İlk versiyon client-side sabit
/// (Türkiye KDV mevzuatı). Backend endpoint hazır olunca API entegrasyonu
/// için `_fetchVatRates`, `_fetchUnits`, `_fetchProductStatuses` doldurulur.

/// KDV oranı — UI dropdown için.
class VatRate {
  final double rate; // 0, 1, 8, 10, 18, 20
  final String displayLabel; // "%18", "%20", vb.

  const VatRate(this.rate, this.displayLabel);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VatRate && other.rate == rate;

  @override
  int get hashCode => rate.hashCode;
}

/// Birim kodu — sektör-aware filtreleme için.
class UnitCode {
  final String code; // "ADET", "KG", "LT", "MT", "CIFT"
  final String displayLabel; // "Adet", "Kg", "Litre", vb.
  final List<SectorType> preferredFor; // boş ise tüm sektörlerde gösterilir

  const UnitCode({
    required this.code,
    required this.displayLabel,
    this.preferredFor = const [],
  });
}

/// Ürün durum enum'u — UI filter chip + status badge için.
class ProductStatus {
  final String code; // "ACTIVE", "DRAFT", "INACTIVE", "OUT_OF_STOCK"
  final String displayLabel;

  const ProductStatus(this.code, this.displayLabel);
}

/// Tüm referans verisi tek struct.
class ReferenceData {
  final List<VatRate> vatRates;
  final List<UnitCode> units;
  final List<ProductStatus> productStatuses;
  final DateTime fetchedAt;

  const ReferenceData({
    required this.vatRates,
    required this.units,
    required this.productStatuses,
    required this.fetchedAt,
  });

  /// Sektöre özel filtrelenmiş birim listesi. `preferredFor` boş olanlar +
  /// sektörü içerenler döner; boş değilse sırayla preferred'lar üstte.
  List<UnitCode> unitsFor(SectorType sector) {
    final preferred =
        units.where((u) => u.preferredFor.contains(sector)).toList();
    final generic = units.where((u) => u.preferredFor.isEmpty).toList();
    return [...preferred, ...generic];
  }
}

/// Ana provider. İleride `FutureProvider` API çağrısı yapacak — şimdilik
/// senkron hardcoded fallback ile sabit dönüyor (5dk cache TTL irrelevant).
final referenceDataProvider = FutureProvider<ReferenceData>((ref) async {
  // TODO(sprint12-w2): Backend endpoint hazır olunca:
  // final dio = ref.read(apiClientProvider);
  // final res = await dio.get('product/api/v1/reference-data');
  // return ReferenceData.fromMap(res.data);
  return _staticFallback();
});

ReferenceData _staticFallback() {
  return ReferenceData(
    vatRates: const [
      VatRate(0, '%0'),
      VatRate(1, '%1'),
      VatRate(8, '%8'),
      VatRate(10, '%10'),
      VatRate(18, '%18'),
      VatRate(20, '%20'),
    ],
    units: const [
      UnitCode(code: 'ADET', displayLabel: 'Adet'),
      UnitCode(
        code: 'CIFT',
        displayLabel: 'Çift',
        preferredFor: [SectorType.footwear],
      ),
      UnitCode(
        code: 'CIHAZ',
        displayLabel: 'Cihaz',
        preferredFor: [SectorType.technology],
      ),
      UnitCode(code: 'KG', displayLabel: 'Kg'),
      UnitCode(code: 'GR', displayLabel: 'Gram'),
      UnitCode(code: 'LT', displayLabel: 'Litre'),
      UnitCode(code: 'MT', displayLabel: 'Metre'),
      UnitCode(code: 'M2', displayLabel: 'm²'),
      UnitCode(code: 'PAKET', displayLabel: 'Paket'),
      UnitCode(code: 'KUTU', displayLabel: 'Kutu'),
    ],
    productStatuses: const [
      ProductStatus('ACTIVE', 'Aktif'),
      ProductStatus('DRAFT', 'Taslak'),
      ProductStatus('INACTIVE', 'Pasif'),
      ProductStatus('OUT_OF_STOCK', 'Stokta Yok'),
    ],
    fetchedAt: DateTime.now(),
  );
}

/// Convenience provider'lar — tekil select için.
final vatRatesProvider = FutureProvider<List<VatRate>>((ref) async {
  final data = await ref.watch(referenceDataProvider.future);
  return data.vatRates;
});

final productStatusesProvider =
    FutureProvider<List<ProductStatus>>((ref) async {
  final data = await ref.watch(referenceDataProvider.future);
  return data.productStatuses;
});

/// Sektör-aware birim listesi — `unitsForSectorProvider(SectorType.footwear)`.
final unitsForSectorProvider =
    FutureProvider.family<List<UnitCode>, SectorType>((ref, sector) async {
  final data = await ref.watch(referenceDataProvider.future);
  return data.unitsFor(sector);
});
