---
title: ProductVariant — ürünün satışa konu konkre varyantı
type: entity
source: pos-product-manager/src/main/java/com/sedcore/product/entity/ProductVariant.java
ingested: 2026-04-25
last-verified: 2026-04-25
status: stub
---

# ProductVariant

## Tanım

Ürünün satışa konu konkre varyantı (renk/beden/numara). **Stok hareketi ve fiyatlandırma variant düzeyinde** — Product domain entity, ProductVariant SKU bazlı satış birimi.

## Kod Konumu

- `pos-product-manager/src/main/java/com/sedcore/product/entity/ProductVariant.java:20`
- `@Version` mevcut — optimistic lock

## Önemli Alanlar

| Alan | Tip | Kısıt |
|---|---|---|
| `sku` | varchar(50) | unique, not null |
| `slug` | string | |
| `name` | string | |
| `additionalPrice` | BigDecimal(15,2) | base ürüne ek fiyat |
| `attributes` | jsonb Map | renk/beden vb. dinamik |
| `product` | ManyToOne | Product referansı |
| `isDeleted` | boolean | soft delete |
| `minStockLevel` | int default 10 | per-varyant alarm eşiği |
| `shelfLocationCode` | string | depo raf konumu |
| `version` | Long | optimistic lock |

## OneToMany İlişkiler

- `stockMovement` — `[[entities/stock-movement]]`
- `variantPricings` — fiyat geçmişi
- `barcodes` — birden fazla barkod
- `oemNumbers` — yedek parça OEM kodu listesi
- `crossReferences` — çapraz referans (eşdeğer parçalar)
- `vehicleCompatibilities` — uyumlu araç modelleri

## Kullanım

- `[[entities/sale-item]].variant` — satış kalem hedefi
- `[[entities/stock-level]]` — variant × location anlık bakiye
- Batch entry akışı: `[[entities/batch-entry-row]]` → backend `ProductVariant` insert/update
- `[[entities/document-item-result]]` PDF analiz match'i variant ile yapılır

## Related

- [[entities/sale-item]]
- [[entities/stock-movement]]
- [[entities/stock-level]]
- [[concepts/optimistic-lock-version]]
- [[syntheses/flow-batch-entry]]
