---
title: CustomerVehicle — müşteri-plaka N-tane ilişkisi (Sprint 9)
type: entity
date: 2026-04-26
sprint: 9
source: pos-product-manager/src/main/java/com/sedcore/customer/entity/CustomerVehicle.java
last-verified: 2026-04-26
---

# CustomerVehicle

## Tanım

Bir müşterinin sahip olduğu/kayıtlı bir aracı temsil eder. Sprint 9'da Opsiyon C kapsamında eklendi (parçacı sektör senaryosu — bir müşteri birden fazla araca parça satın alabilir, plaka bazlı satış+tahsilat takibi gerekir).

## Kod Konumu

- Entity: `pos-product-manager/src/main/java/com/sedcore/customer/entity/CustomerVehicle.java`
- Repository: `pos-product-manager/.../customer/repository/CustomerVehicleRepository.java`
- Service: `pos-product-manager/.../customer/service/CustomerVehicleService.java` (interface) + `CustomerVehicleServiceImpl.java`
- Controller: `pos-product-manager/.../customer/controller/impl/CustomerVehicleControllerImpl.java`

## Şema

| Alan | Tip | Açıklama |
|---|---|---|
| `id` | varchar(36) | UUID — TOpenSimpleCompanyEntity'den |
| `customer` | ManyToOne LAZY | Customer FK, **NOT NULL** |
| `plateDisplay` | varchar(20) | "34 ABC 123" (kullanıcı girişi) |
| `plateNormalized` | varchar(20) | "34ABC123" (search index) — boşluk/çizgi temizle + uppercase |
| `vehicle` | ManyToOne LAZY (nullable) | Vehicle katalog FK (opsiyonel; freeform fallback için make/model/year) |
| `make` | varchar(50) | "Ford", "Toyota" — vehicle null ise dolu |
| `model` | varchar(100) | |
| `yearOfManufacture` | int | |
| `notes` | TEXT | |
| `isActive` | boolean | soft-delete için (default true) |
| `version` | Long | optimistic lock |
| `companyCode` | varchar(36) | multi-tenant filter |

**Index'ler:** `idx_cv_customer`, `idx_cv_plate_normalized`, `idx_cv_company`.
**Unique:** `(customer_id, plate_normalized, company_code)` — aynı plaka 2 farklı müşteride bağımsız OK.

## Plaka Normalizasyon

`CustomerVehicle.normalize(String)` static helper:
- Regex `[\s\-]+` ile boşluk + kısa çizgileri temizle
- `toUpperCase()` + `trim()`

Örnek: `"34 abc-123"` → `"34ABC123"`. Search ve uniqueness için kullanılır; UI'da `plateDisplay` gösterilir.

## Endpoint Kataloğu

| Method | Path | Amaç |
|---|---|---|
| GET | `/api/v1/customers/{customerId}/vehicles` | Müşterinin aktif plakaları (UI dropdown) |
| GET | `/api/v1/customers/{customerId}/vehicles/search?q=34A` | Autocomplete prefix arama |
| GET | `/api/v1/customers/{customerId}/vehicles/{id}` | Tek kayıt |
| POST | `/api/v1/customers/{customerId}/vehicles` | Yeni plaka (idempotent — aynı normalized varsa mevcut döner) |
| PUT | `/api/v1/customers/{customerId}/vehicles/{id}` | Güncelleme |
| DELETE | `/api/v1/customers/{customerId}/vehicles/{id}` | Soft-delete (`isActive=false`) |

## Sale Entegrasyonu

[`Sale`](entities/sale) entity Sprint 9'da genişletildi:
- `Sale.customerVehicle` (ManyToOne LAZY, nullable) — FK
- `Sale.vehiclePlateSnapshot` (varchar(20)) — denormalize cache, history korur

[`SaleServiceIntegrated.createSale`](pos-product-manager/.../sales/service/impl/SaleServiceIntegrated.java):
- `request.customerVehicleId != null` → CustomerVehicle yüklenir, müşteri tutarlılığı kontrol edilir
- `Sale.customerVehicle` FK + `Sale.vehiclePlateSnapshot = customerVehicle.plateNormalized`

## Sale Filter (Plaka Bazlı Tahsilat)

`GET /api/v1/sales?customerId=X&vehiclePlate=34A` — Sprint 9 yeni parametre. Backend `vehiclePlate` normalize edip `Sale.vehiclePlateSnapshot` LIKE contains.

## Sektör Awareness

Frontend katmanında `companySettingProvider.sectorType == 'autoParts'` kontrolü ile widget'lar koşullu render edilir (Sprint 10 kapsamı). Backend tarafı sektör-agnostik — endpoint her tenant'ta çalışır, UI gösterip göstermemeye karar verir.

## Idempotent Create

`POST /vehicles` aynı `(customer_id, plate_normalized)` zaten varsa **mevcut kaydı döner** (yeni create değil). Bu, frontend "yeni plaka ekle" akışı kullanıcı aynı plakayı 2 kez yazsa bile çift kayıt oluşturmaz.

## Migration (Sprint 11)

Mevcut `Payment.description` "Plaka: XX | ..." prepend'leri (Sprint 6b Opsiyon A) → CustomerVehicle upsert + Sale backfill. One-shot script, idempotent.

## Reconcile Invariant

`Sale.customerVehicle != null → Sale.vehiclePlateSnapshot == customerVehicle.plateNormalized`. Drift → reconcile job log + Slack notify (Sprint 11+).

## Sources

- Tasarım: [[syntheses/vehicle-plate-end-to-end-design-2026-04-26]]
- Önceki ADR (superseded): [[decisions/2026-04-24-vehicle-plate-tracking-option-a]]
- Sprint 9 plan: `C:\Users\Win11\.claude\plans\polymorphic-gathering-flute.md` (Sprint 9-11 bölümü)
- Pattern: [[concepts/optimistic-lock-version]] (`@Version`), [[concepts/multi-tenant]] (companyCode)

## Related

- [[entities/customer]] (parent FK)
- [[entities/sale]] (Sale.customerVehicle FK eklendi)
- [[entities/vehicle]] (opsiyonel katalog FK)
- [[entities/payment-allocation]] (Sprint 7 — plaka filter ile sale picker)
- [[concepts/sector-agnostic]] (sektör-aware UI)
