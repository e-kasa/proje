---
title: SaleItem (detailed merge from .claude/wiki/)
type: entity
source: .claude/wiki/entities/sale-item.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
note: "MERGE_NEEDED — .wiki/entities/sale-item.md is a stub; this verified version has full field table + calculation order + return logic."
---

# SaleItem

## Amaç

Bir [[entities/sale]]'in tek satırı — varyant, miktar, birim fiyat, indirim, KDV ve satır totali. Vergi raporlaması ve iade hesaplaması buradan yapılır.

## Kritik Alanlar

| Alan | Tip | Anlam |
|---|---|---|
| `sale` | FK Sale, LAZY, NOT NULL | Hangi satışın kalemi |
| `variant` | FK ProductVariant, LAZY, NOT NULL | Hangi ürün varyantı |
| `quantity` | Integer | Satış adedi |
| `unitPrice` | BigDecimal(15,2) | Brüt birim fiyat (indirim öncesi) |
| `discountRate` | BigDecimal(5,2) | % oran |
| `discountAmount` | BigDecimal(15,2) | Hesaplanmış tutar (gross × rate / 100) |
| `taxRate` / `taxAmount` | BigDecimal(5,2) / BigDecimal(15,2) | KDV |
| `lineTotal` | BigDecimal(15,2) | Net + tax — iade hesabında kullanılır |
| `returnedQuantity` | Integer | Bugüne kadar iade edilen adet |
| `@Version` | Long | Concurrent iade koruması |

## Hesaplama Sırası (createSale içinde)

```
gross       = unitPrice × quantity
discAmt     = gross × discountRate / 100        (HALF_UP, scale 2)
net         = gross − discAmt
taxAmt      = net × taxRate / 100               (HALF_UP, scale 2)
lineTotal   = net + taxAmt
```

Tüm hesaplamalar Java'da; client'tan sadece `unitPrice`, `discountRate`, `taxRate`, `quantity` gelir.

## İade Hesabı (createSaleReturn)

```
perUnit   = lineTotal / originalQuantity   (prorata)
returnAmt = perUnit × returnedQuantity
```

Neden prorata? Çünkü indirim ve KDV kalem bazında birleşik — birim başı geri hesapla.

**Guard**: `requested > (originalSold − alreadyReturned)` → `RuntimeException("İade miktarı fazla")`.

## İndeksler

```sql
idx_sale_item_sale    (sale_id)
idx_sale_item_variant (variant_id)
```

## @Version Pattern

Doğru — `returnedQuantity` mutated (createSaleReturn artırır). İki paralel iade aynı SaleItem'a gelirse lost update koruması. Bkz. [[concepts/optimistic-lock-version]].

## Tuzaklar

- **`returnedQuantity` null** olabilir (legacy data) — `!= null ? : 0` guard her yerde gerekli
- **`unitPrice` audit amaçlı** — iadeler `lineTotal / qty` prorata kullanır, `unitPrice` değil; çünkü indirim+KDV dahil tutar `unitPrice`'tan farklı
- **Plaka/araç eşlemesi yok** — sektör özelleştirmesi için ek alan gerekir (bkz. [[entities/sale]] sektör notu)

## Sources

- `pos-product-manager/src/main/java/com/sedcore/sales/entity/SaleItem.java`
- `pos-product-manager/src/main/java/com/sedcore/sales/service/impl/SaleServiceIntegrated.java:createSale` (90–123), `createSaleReturn` (280–413)

## Related

- [[entities/sale]]
- [[syntheses/flow-sale-checkout]]
- [[concepts/optimistic-lock-version]]
