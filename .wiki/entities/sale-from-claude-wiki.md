---
title: Sale (detailed merge from .claude/wiki/)
type: entity
source: .claude/wiki/entities/sale.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
note: "MERGE_NEEDED — .wiki/entities/sale.md is brief; this verified version has helper methods, indexes, sektör notu Sprint 6b context."
---

# Sale

## Amaç

Müşteriye yapılan satışın **başı** — tutarlar, ödeme durumu, lokasyon, müşteri ilişkisi. Peşin ya da vadeli olabilir. Vadeli ise [[entities/account-transaction]] `TransactionType.SALE` kaydı tetiklenir ve [[entities/customer-account]] denormalize bakiyesi güncellenir.

## Kritik Alanlar

| Alan | Tip | Anlam |
|---|---|---|
| `saleNumber` | String, unique | POS-yyyyMMdd-XXXXXX (auto) |
| `saleDate` | LocalDateTime | Satış zamanı |
| `customer` | FK Customer, LAZY, nullable | Null = peşin satış (ledger etkisi yok) |
| `subtotalAmount` | BigDecimal(15,2) | İndirim öncesi brüt |
| `totalDiscount` | BigDecimal(15,2) | Kalem indirimleri toplamı |
| `totalTax` | BigDecimal(15,2) | KDV toplamı |
| `totalAmount` | BigDecimal(15,2) | Ödenecek net (subtotal − discount + tax) |
| `paidAmount` | BigDecimal(15,2) | Kasada alınan (kısmi ödeme mümkün) |
| `locationId` / `locationType` | String(50) / String(10) | Kasiyer JWT'den — STORE\|WAREHOUSE |
| `isCancelled` | Boolean | Soft cancel flag |
| `returnedAmount` | BigDecimal | İade tutarı toplamı |
| `hasReturn` | Boolean | İade olduğunu hızlı sorgu için (denormalize) |
| `@Version` | Long | Concurrent cancel/return'u koru |

## Kalıtım

`TOpenSimpleCompanyEntity` → `companyCode` + `@FilterDef filterCompany` otomatik (multi-tenant izolasyon).

## İlişkiler

```
Sale ──< SaleItem (OneToMany cascade ALL + orphanRemoval)
     ──< StockMovement (OneToMany cascade ALL)
     ──> Customer (ManyToOne, nullable = peşin)
     ──< AccountTransaction (sale_id FK, type=SALE|CANCEL|RETURN)
     ──< SaleReturn (OneToMany dolaylı)
```

## Helper Metodlar

```java
BigDecimal getRemainingAmount()  // totalAmount − paidAmount
boolean isOnCredit()             // customer != null && remainingAmount > 0
```

`isOnCredit()` kritik: bu true ise checkout flow cari hesap + ledger güncellemesi tetikler ([[syntheses/flow-sale-checkout]]).

## @Version Pattern

Doğru yerde — `paidAmount`, `returnedAmount`, `hasReturn`, `isCancelled` **mutable**. İki paralel işlem (ör. cancel + return aynı anda) lost update'ten korunur. Bkz. [[concepts/optimistic-lock-version]].

## İndeksler

```sql
idx_sale_customer (customer_id, sale_date)  -- müşteri ekstresi
idx_sale_number   (sale_number)             -- unique lookup
```

## Tuzaklar

- **Peşin satış (`customer = null`)** → ledger/hesap hareket YARATMAZ. Sadece StockMovement + Sale kaydı kalır
- **`paid < total` ama `customer = null`** → `createSale` exception ("Vadeli satış için müşteri zorunludur") — fail-fast guard
- **Lokasyon null** → StockLevel düşüş atlanır; stok tutarsızlığı oluşur. Client'tan gelen `locationId` zorunlu olmalı
- **`totalAmount` recalculate yok** — insert sırasında request'teki değer değil, Java'da subtotal − discount + tax hesaplanır (guard)

## Sektör Notu — Plaka Takibi (Sprint 6b context)

**Yedek parça sektörü**: Satışa konu parçanın hangi araca/plakaya gittiğini takip etmek istenir.

Mevcut model:
- `Sale` ↔ `Vehicle` FK **YOK**
- `SaleItem` ↔ `Vehicle` FK **YOK**
- [[entities/vehicle]] sadece **katalog** (make/model/year), `plate` alanı yok
- `VehicleCompatibility` = parça katalogunda "hangi araca takılır" eşleştirmesi (satışta değil)

Sprint 6b için seçenekler:
- **A (pragmatik)**: `Payment.description` içinde "plaka:XX" string — şema değişikliği yok
- **B (yarı-yapısal)**: `Sale.vehicle_plate VARCHAR(20)` — tek alan, filter + chip
- **C (yapısal)**: Yeni `CustomerVehicle` entity (customer_id + plate + vehicle_id?) + `Sale.customer_vehicle_id FK` — rapor zenginleştirme mümkün

## Sources

- `pos-product-manager/src/main/java/com/sedcore/sales/entity/Sale.java`
- `pos-product-manager/src/main/java/com/sedcore/sales/service/impl/SaleServiceIntegrated.java:createSale` (70–200)

## Related

- [[entities/sale-item]]
- [[entities/customer]]
- [[entities/customer-account]]
- [[entities/account-transaction]]
- [[entities/stock-movement]]
- [[syntheses/flow-sale-checkout]]
- [[concepts/optimistic-lock-version]]
