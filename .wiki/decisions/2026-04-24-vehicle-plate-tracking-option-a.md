---
title: ADR — Plaka Takibi Opsiyon A (Description Prepend)
type: decision
date: 2026-04-24
status: accepted
sprint: 6b
source: project_pos/lib/features/accounts/screens/payment_record_modal.dart
related-source: project_pos/lib/features/accounts/screens/_wiki/syntheses/payment-recording-and-vehicle-tracking.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# ADR — Plaka Takibi: Opsiyon A (Pragmatik) [SUPERSEDED]

> ⚠️ **SUPERSEDED 2026-04-26** — Sprint 9 Opsiyon C kabul edildi. Detay: [[decisions/2026-04-26-vehicle-plate-option-c]] + [[syntheses/vehicle-plate-end-to-end-design-2026-04-26]].
> Sprint 11'de PaymentRecordModal `_plateCtrl` (description prepend) kaldırılacak; read-only history korunur.

**Tarih:** 2026-04-24 · Sprint 6b · **Durum:** ~~Kabul edildi (verified)~~ Superseded

## Karar

Yedek parça müşterilerinin araç plakası takibi için **şema değişikliği YAPILMADI**. Plaka, ödeme modalında opsiyonel input olarak alınır ve `Payment.description` alanına `"Plaka: 34ABC123 | <orijinal açıklama>"` formatında prepend edilir. Backend ve veritabanı dokunulmadı.

## Kabul Edilen Kısıtlar

- **Plaka arama yok** — backend'de yapısal alan yok, full-text search description üzerinde olur.
- **Plaka raporlama yok** — agregasyon mümkün değil.
- **Tutarlı yazım garantisi yok** — `_normalizePlate` regex ile `[\s-]+` strip + uppercase ("34 abc-123" → "34ABC123") yapılır, ama önceki kayıtlar normalize edilmemiş olabilir.

## Alternatifler ve Neden Reddedildi

**Opsiyon B — `Payment.vehicle_plate VARCHAR(20)` kolonu:**
- Avantaj: Yapısal alan, query/filter mümkün.
- Dezavantaj: 1 kolon ekleme + migration + repository filter + UI chip render. ~3-5 gün iş.
- Karar: Veri biriktikten sonra (kullanıcı feedback'i gerektirdiğinde) tekrar değerlendirilecek.

**Opsiyon C — `CustomerVehicle` entity (Sale → CustomerVehicle FK):**
- Orijinal plan: Sale → SaleItem → Vehicle zincirini kullan.
- **W2 Sales ingest sonrası iptal** (2026-04-24): `SaleItem.vehicleId` FK YOK, `Vehicle` entity katalog (make/model/year), `plate` alanı YOK, `VehicleCompatibility` parça↔model eşleştirmesi (satışa konu araç değil).
- Yeni şema gerekir: `CustomerVehicle` (`customer_id` + `plate UNIQUE per customer` + opsiyonel `vehicle_id` FK), `Sale.customer_vehicle_id`, POS cart_panel'da plaka dropdown, statement enrichment, vehicle-bazlı endpoint.
- Efor: 5-7 gün.
- Karar: Müşteri feedback'i bunu hak edene kadar ertelendi.

## Implementation

| Bileşen | Değişiklik |
|---|---|
| Frontend | [`payment_record_modal.dart`](../../project_pos/lib/features/accounts/screens/payment_record_modal.dart): `_plateCtrl` TextField (car icon, `textCapitalization.characters`); `_normalizePlate()` regex; `_submit()` plaka boş değilse description'a prepend. |
| i18n | [`security/data.sql`](../../security/src/main/resources/data.sql): `accounts.vehicle_plate_label`, `accounts.vehicle_plate_hint` (TR + EN). |
| Backend | **Sıfır değişiklik** — `Payment.description` zaten var, `AccountTransaction.description` mirror, `_TxRow` description render eder → plaka görünür. |

## Yeniden Değerlendirme Kriterleri

Şunlar olursa Opsiyon B veya C'ye geç:
1. Müşteriler "plaka ile ödeme geçmişi getir" istiyor.
2. Tek bir müşterinin >5 plakası olduğu kayıt sayısı belirgin.
3. Plaka bazlı vergi/işletme raporu zorunluluğu.

## Sources

- Scoped wiki sentezi (detaylı): [`project_pos/lib/features/accounts/screens/_wiki/syntheses/payment-recording-and-vehicle-tracking.md`](../../project_pos/lib/features/accounts/screens/_wiki/syntheses/payment-recording-and-vehicle-tracking.md)
- Commit: `5c2b752` (Sprint 6b)
- Plan ADR: `C:\Users\Win11\.claude\plans\agile-noodling-crown-s6b-adr.md`

## Related

- [[entities/payment]] — description alanı
- [[entities/account-transaction]] — description mirror
- [[entities/vehicle]] — katalog (plate alanı YOK)
- [[entities/customer]] — gelecekte CustomerVehicle FK adayı
