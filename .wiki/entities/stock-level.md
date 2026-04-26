---
title: StockLevel (Anlık Stok)
tags: [entity, inventory, denormalize]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\entities\stock-level.md
date: 2026-04-25
status: stub
---

# StockLevel

(variant × location × companyCode) için tek satır — anlık stok özeti. Append-only [[entities/stock-movement]]'ın denormalize hali.

## Concurrency

- `deductStock` → **PESSIMISTIC_WRITE lock** (`findByVariantIdAndLocationIdForUpdate`)
- `addStock` → **atomic increment** (`@Modifying`)
- `@Version` secondary guard

## Sources

- `.claude/wiki/entities/stock-level.md`
- [[raw/code-refs/2026-04-25-sale-checkout-flow]]

## Related

- [[entities/stock-movement]]
- [[decisions/stock-level-pessimistic-lock]]
