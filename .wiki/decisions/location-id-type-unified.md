---
title: Karar — locationId + locationType Birleşimi
tags: [decision, inventory, schema]
date: 2026-04-25
status: accepted
source: C:\Users\Win11\Documents\GitHub\proje\CLAUDE.md
---

# locationId + locationType

## Karar

Eski `storeId` / `warehouseId` kaldırıldı. Tek `locationId` (String) + `locationType` (`STORE`/`WAREHOUSE`). StockMovement, Sale, Purchase, StockLevel hepsinde aynı kullanım.

## Gerekçe

- Store/Warehouse ayrı tablolar olsa da lokasyon semantiği tek — ortak kolon basitlik
- Transfer akışı (STORE↔WAREHOUSE) tek alanla temsil

## Sources

- [[raw/code-refs/2026-04-25-project-root-claude]]
- [[raw/code-refs/2026-04-25-sale-checkout-flow]]

## Related

- [[entities/stock-level]]
- [[entities/stock-movement]]
