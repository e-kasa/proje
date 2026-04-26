---
title: StockLevel (detailed merge from .claude/wiki/)
type: entity
source: .claude/wiki/entities/stock-level.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
note: "MERGE_NEEDED — .wiki/entities/stock-level.md is a stub; this verified version has unique constraint + concurrency mechanism + drift risk analysis."
---

# StockLevel

## Amaç
Anlık stok bakiyesi — (productVariant × location × companyCode) başına tek kayıt. Stock movement tablosu append-only tarihsel iken bu **denormalize özet**: hızlı okuma için. Aynı [[concepts/pattern-denormalization-with-reconcile]] pattern.

## Kritik Alanlar

| Alan | Tip | Anlam |
|---|---|---|
| variantId | String(36) | ProductVariant FK (plain String — JOIN performans tercihi) |
| locationId | String(50) | Store.code veya Warehouse.code (örn. `STORE-01`) |
| locationType | String(10) | `STORE` veya `WAREHOUSE` |
| quantity | Integer | Anlık stok (her harekette +/− güncellenir) |
| minQuantity | Integer? | Per-lokasyon kritik eşik; null → `ProductVariant.minStockLevel` fallback |
| version | Long (@Version) | Optimistic lock — paralel hareket race koruması |

## Unique Constraint
`uk_sl_variant_location_company` — `(variant_id, location_id, company_code)` tek satır garanti.

## İndeksler
- `idx_sl_variant_location` — variant+location yaygın sorgu
- `idx_sl_critical` — `company_code + quantity + min_quantity` (kritik alarm query'leri)

## Beslenme Akışı

1. `PurchaseService` satın alma sonrası → quantity += SaleItem.qty
2. `SaleService` satış → quantity -= SaleItem.qty (stok kontrolü ile)
3. `StockTransferService` transfer → kaynak -qty, hedef +qty (iki row update)
4. `StockMovement` yazılır (append-only, tarihsel)

## Concurrency Kontrolü (2026-04-24 W2 Sprint 4 düzeltme)

| İşlem | Mekanizma | Neden |
|---|---|---|
| `deductStock` | **PESSIMISTIC_WRITE lock** (`findByVariantIdAndLocationIdForUpdate`) | İki paralel satışın aynı row'u birbirinin üstüne yazmasını tamamen engeller |
| `addStock` | **Atomic UPDATE** (`@Modifying incrementQuantity`) | Row yoksa save path'e düşer; yaygın olanda lock'a gerek yok |
| `setStock` (sayım düzeltme) | Normal save | Sayım nadir; @Version yakalar |

`@Version` burada **ikincil** — primary path'ler pessimistic + atomic.

## Drift Riski

[[entities/stock-movement]] ile StockLevel **senkron tutulmalı**. Drift nedenleri:
- Servis commit fail sonrası inconsistent state
- `addStock` yeni-row path'inde findBy + save arası race (küçük pencere)
- StockMovement insert edilir ama StockLevel güncellemesi exception nedeniyle rollback

Şu an reconcile endpoint yok (AccountsHub gibi). Gelecek sprint adayı: `StockLevel.reconcile(variantId, locationId)` — SUM(StockMovement.quantityChange) karşılaştırması.

## Tuzaklar

- `variantId` plain String FK → cascade delete yok, manuel senkron
- locationId + locationType ikilisi → `locationId` tek başına unique değil (Store `STORE-01` ve Warehouse `WH-01` ayrı)
- Yeni variant × location kombinasyonu ilk satışa kadar var olmaz — `getOrCreate()` pattern gerekli

## Sources
- pos-product-manager/src/main/java/com/sedcore/inventory/entity/StockLevel.java
- ADR: `.claude/decisions/2026-04-13-location-id-unification.md`

## Related
- [[entities/stock-movement]]
- [[concepts/pattern-denormalization-with-reconcile]]
- [[concepts/optimistic-lock-version]]
- [[syntheses/denormalization-strategy]]
