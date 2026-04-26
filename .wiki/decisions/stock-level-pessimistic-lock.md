---
title: Karar — StockLevel deductStock Pessimistic Lock
tags: [decision, inventory, concurrency]
date: 2026-04-25
status: accepted
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\entities\stock-level.md
---

# StockLevel Pessimistic Lock

## Karar

[[entities/stock-level]] `deductStock` **PESSIMISTIC_WRITE lock** kullanır (`findByVariantIdAndLocationIdForUpdate`). `@Version` retry yerine DB satır kilidi.

## Gerekçe

- İki paralel satış aynı stok row'una → atomik "yetersiz stok" kontrolü
- Optimistic lock retry logic'i karmaşık (sale flow içinde)
- `addStock` ise `@Modifying` atomic increment — race yok

## Sources

- `pos-product-manager/src/main/java/com/sedcore/inventory/service/impl/StockLevelServiceImpl.java`
- [[raw/code-refs/2026-04-25-sale-checkout-flow]]

## Related

- [[entities/stock-level]]
- [[concepts/optimistic-lock-version]]
