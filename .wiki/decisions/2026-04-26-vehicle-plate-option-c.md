---
title: ADR — Plaka Takibi Opsiyon C (CustomerVehicle Entity, Sprint 9)
type: decision
date: 2026-04-26
status: accepted
sprint: 9
supersedes: decisions/2026-04-24-vehicle-plate-tracking-option-a
---

# ADR — Plaka Takibi: Opsiyon C (CustomerVehicle Entity)

**Tarih:** 2026-04-26 · Sprint 9 · **Durum:** Kabul edildi (backend tamamlandı, frontend Sprint 10-11)

## Karar

Plaka takibi için **`CustomerVehicle` entity** + **`Sale.customerVehicleId` FK** + **`Sale.vehiclePlateSnapshot` denormalize cache** uygulanır. Sprint 6b'deki [[decisions/2026-04-24-vehicle-plate-tracking-option-a]] Opsiyon A (description prepend) **superseded**.

## Tetikleyici

Kullanıcı senaryosu (2026-04-26):
> Müşteri parçacıdan birden fazla araca parça alır → cari hesap görünümünde plaka bazında satış geçmişi → tahsilatta plaka seç → o plakaya ait açık satışlara ödeme

Sprint 6b ADR'sindeki "Yeniden Değerlendirme Kriterleri" karşılandı:
1. ✅ Müşteriler "plaka ile ödeme geçmişi getir" istiyor
2. ✅ Tek müşteri >5 plakası senaryosu
3. ⚠️ Plaka bazlı vergi/işletme raporu (henüz açık değil; mantıksal sonraki adım)

## Reddedilen Alternatifler

### Opsiyon A — `Payment.description` prepend (Sprint 6b)
- ❌ Plaka arama yok (full-text description LIKE perf zayıf)
- ❌ Multi-plaka per müşteri yapısal değil
- ❌ Tutarlı yazım garantisi yok (kullanıcı her seferinde farklı yazar)

### Opsiyon B — `Payment.vehicle_plate VARCHAR(20)` tek kolon
- ❌ Multi-plaka per müşteri için tablo yapısal yetersiz
- ❌ Ödeme zamanında plaka, satış zamanındaki plakayla eşleşmeyebilir (ödeme bağlamı sonradan girer)

### Opsiyon C ✅ (seçilen)
- Müşteri-plaka **1-N** ilişki
- Sale entity'ye plaka FK + snapshot
- Endpoint katalogu CRUD + autocomplete
- Frontend sektör-aware widget'lar

## Implementasyon (Sprint 9 backend, Maven exit 0 ✅)

### Yeni Java sınıfları (8)
- `customer/entity/CustomerVehicle.java`
- `customer/repository/CustomerVehicleRepository.java`
- `customer/service/CustomerVehicleService.java` (interface)
- `customer/service/impl/CustomerVehicleServiceImpl.java`
- `customer/controller/impl/CustomerVehicleControllerImpl.java`
- `customer/model/CustomerVehicleDto.java`
- `customer/model/CustomerVehicleResponse.java`
- (Yeni controller interface gerekmedi — direct impl)

### Değişen Java sınıfları (3)
- `sales/entity/Sale.java` — `customerVehicle` FK + `vehiclePlateSnapshot` field
- `sales/model/SaleRequest.java` — `customerVehicleId` parametresi
- `sales/service/impl/SaleServiceIntegrated.java` — `createSale()` snapshot logic + müşteri-plaka tutarlılık kontrolü
- `sales/controller/impl/SaleControllerImpl.java` — `?vehiclePlate=Y` filter

## Davranış

**Yeni satış akışı (parçacı sektör + müşteri seçili):**
1. UI plaka picker → mevcut seç veya yeni ekle
2. POST `/sales` request → `customerVehicleId: cv-...`
3. Backend: CustomerVehicle yükle, müşteri tutarlılığı kontrol, `Sale.vehiclePlateSnapshot = cv.plateNormalized`
4. Tutarsızlık (plaka başka müşteriye ait) → `RuntimeException`

**Plaka bazlı satış arama:**
- `GET /sales?customerId=X&vehiclePlate=34A` → `Sale.vehiclePlateSnapshot` LIKE normalize edilmiş plate
- `GET /customers/{id}/vehicles/search?q=34A` → autocomplete dropdown

**Idempotent plaka ekleme:**
- POST `/vehicles` aynı `(customer_id, plate_normalized)` varsa mevcut kaydı döner (404/409 yok, kullanıcı dostu)

## Sektör Awareness

Backend sektör-agnostik (her tenant endpoint çalışır). Frontend `companySettingProvider.sectorType == 'autoParts'` kontrolü ile widget'lar koşullu (Sprint 10 kapsamı).

## Geriye Uyumluluk

- `Sale.customerVehicle` ve `Sale.vehiclePlateSnapshot` **nullable** — peşin satış / butik sektör / plaka seçilmez durumda null
- Sprint 6b `_plateCtrl` (PaymentRecordModal description prepend) Sprint 11'de kaldırılacak (read-only history korunur)

## Sources

- Tasarım sentezi: [[syntheses/vehicle-plate-end-to-end-design-2026-04-26]]
- Önceki ADR: [[decisions/2026-04-24-vehicle-plate-tracking-option-a]] (superseded)
- Implementasyon: [[entities/customer-vehicle]]
- Sprint plan: `C:\Users\Win11\.claude\plans\polymorphic-gathering-flute.md`
- Backend Maven compile: exit 0 (2026-04-26)

## Related

- [[entities/customer-vehicle]]
- [[entities/sale]] — `customerVehicle` FK + `vehiclePlateSnapshot` field
- [[entities/payment-allocation]] (Sprint 7 — plaka filter ile sale picker doğal çalışır)
- [[concepts/sector-agnostic]]
- [[concepts/optimistic-lock-version]]
