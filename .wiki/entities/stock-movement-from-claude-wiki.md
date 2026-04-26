---
title: StockMovement (detailed merge from .claude/wiki/)
type: entity
source: .claude/wiki/entities/stock-movement.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
note: "MERGE_NEEDED — .wiki/entities/stock-movement.md is a stub; this verified version has movement type details + append-only semantics."
---

# StockMovement

## Amaç
Stok hareketi **audit kaydı** — append-only ledger. Her giriş/çıkış (satış, alım, transfer, sayım, iade) buraya yazılır. Anlık bakiye için [[entities/stock-level]] kullanılır; bu tablo tarihsel referans.

## Kritik Alanlar

| Alan | Tip | Anlam |
|---|---|---|
| variant | ProductVariant (LAZY FK) | Hangi ürün varyantı |
| locationId | String | Store.code veya Warehouse.code |
| locationType | String | `STORE` veya `WAREHOUSE` |
| movementType | enum (StockMovementType) | `PURCHASE_IN` / `SALE_OUT` / `TRANSFER_OUT` / `TRANSFER_IN` / `RETURN` / `ADJUSTMENT` / `COUNT` |
| quantityChange | Integer | +N giriş, −N çıkış |
| source (sale/purchase) | LAZY FK | İlgili belge (SALE_OUT → Sale, PURCHASE_IN → Purchase) |
| version | Long (@Version) | Optimistic lock |

## Append-Only Semantiği

- Kayıt insert sonrası değiştirilmez
- İptal için ayrı ters hareket atılır (örn. satış iptali → ADJUSTMENT +N veya RETURN kaydı) — [[entities/account-transaction]]'daki `isCancelled` pattern'inden farklı; burada ters insert standart
- StockMovement'ın kendisi silinmez — audit korunur

## Beslenme

1. Write-through cache pattern: `PurchaseService.checkout` hem StockLevel quantity'yi günceller hem StockMovement yazar (aynı `@Transactional`)
2. `SaleService.checkout` simetrik
3. `StockTransferService` → iki StockMovement (TRANSFER_OUT + TRANSFER_IN) + iki StockLevel update

## İndeksler
- `idx_sm_variant`, `idx_sm_location`, `idx_sm_company`

## Tuzaklar

- `@Version` var ama append-only tabloda opt-lock tartışmalı — pratikte concurrent insert hedeflenmiyor (aynı row güncellenmez). Import edilmiş ama etkisi sınırlı
- `variant` LAZY — raporlama ekranlarında N+1 riski (list query'sinde `@EntityGraph` gerekebilir)
- `quantityChange` işareti tutarsızsa kümülatif SUM yanlış — `movementType` ile işaret bekleniyor (PURCHASE_IN pozitif, SALE_OUT negatif)

## Sources
- pos-product-manager/src/main/java/com/sedcore/inventory/entity/StockMovement.java

## Related
- [[entities/stock-level]]
- [[entities/sale]]
- [[entities/purchase]]
- [[syntheses/flow-batch-entry]]
- [[concepts/ledger-vs-denormalize]]
