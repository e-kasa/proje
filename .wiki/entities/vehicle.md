---
title: Vehicle — Araç Kataloğu
type: entity
source: .claude/wiki/entities/vehicle.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Vehicle

## Amaç

**Katalog** — yedek parçaların hangi araç modellerine uyduğunu tanımlamak için referans listesi. Müşterinin aracı veya plakası DEĞİL; bu sadece "Ford Focus 2015 Dizel" gibi model kaydı.

## Alanlar

| Alan | Tip | Anlam |
|---|---|---|
| `make` | String(100), NOT NULL | Marka (Ford, Renault...) |
| `model` | String(100), NOT NULL | Model (Focus, Clio...) |
| `yearStart` / `yearEnd` | Integer | Üretim aralığı (2010–2015 gibi) |
| `engineType` | String(100) | 1.6 TDCI, 2.0 HDI... |
| `fuelType` | String(50) | Benzin / Dizel / Elektrik |
| `bodyType` | String(50) | Sedan / Hatchback |
| `platformCode` | String(50) | Ortak platform (C1, MQB...) — farklı model aynı parçayı paylaşır |
| `isActive` | Boolean | Soft delete |

**Önemli: `plate` (plaka) alanı YOK**. Vehicle = katalog, müşteri aracı değil.

## İlişkiler

```
Vehicle ──< VehicleCompatibility >── ProductVariant
(hangi araç katalog kaydına hangi parçalar uyar)
```

Bu eşleştirme tablosu **tavsiye** mekanizması — satışa konu araç FK'ı değil.

## Plaka / Müşteri Aracı Takibi — Yapı Boşluğu

SEDCORE'da şu an yok:
- `Sale.vehicle_id` FK — yok
- `SaleItem.vehicle_id` FK — yok
- `CustomerVehicle` entity (customer + plate) — yok
- `Vehicle.plate` alanı — yok (ve olamaz, çünkü bu katalog)

Yedek parça sektöründe yaygın ihtiyaç:
> "Ali Bey'in 34 ABC 123 plakalı Ford Focus'una hangi parçalar gitti?"

Bunun için şu seçenekler var (Sprint 6b kapsamı):
- **A**: `Payment.description` içinde "plaka:34ABC123" string — yapısal değil, rapor zor
- **B**: `Sale.vehiclePlate VARCHAR(20)` alan + UI chip — ekstre satırında görünür
- **C**: `CustomerVehicle` entity (customer_id, plate unique, optional vehicle_id FK) + `Sale.customer_vehicle_id` — en temiz, rapor kolaylaşır

Plan `agile-noodling-crown.md` Sprint 6b'de orijinal C notu: "Sale→SaleItem→Vehicle zinciri kullan (varsa) → AccountStatementControllerImpl response'a vehicle_plate zenginleştirme". **Mevcut olmadığı için C aslında B-plus veya yeni şema gerektirir.**

## Sources

- `pos-product-manager/src/main/java/com/sedcore/autoparts/entity/Vehicle.java`
- `pos-product-manager/src/main/java/com/sedcore/autoparts/entity/VehicleCompatibility.java`

## Related

- [[entities/sale]] (sektör notu)
- [[entities/sale-item]]
- [[syntheses/accounts-module-overview]]
- `syntheses/payment-recording-and-vehicle-tracking` (scoped `project_pos/.../accounts/screens/_wiki/`)
