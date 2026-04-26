---
title: SaleItem (Satış Satırı)
tags: [entity, sale, line-item]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\entities\sale-item.md
date: 2026-04-25
status: stub
---

# SaleItem

Satışın tek satırı: variant + miktar + birim fiyat + indirim + KDV + lineTotal. `returnedQuantity` ile kısmi iade takibi. `@Version` concurrent iade koruması.

## Sources

- [[raw/code-refs/2026-04-25-sale-checkout-flow]]
- `pos-product-manager/src/main/java/com/sedcore/sales/entity/SaleItem.java`

## Related

- [[entities/sale]]
- [[entities/stock-movement]]
