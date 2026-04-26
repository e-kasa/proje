---
title: StockLevel Concurrency Dokümantasyonu Yanlış (RESOLVED)
tags: [issue, resolved, inventory, documentation]
date: 2026-04-25
status: resolved
resolved-date: 2026-04-24
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\entities\stock-level.md
---

# Stok Concurrency Dokümantasyonu Yanlış

**Kök neden**: Wiki sayfaları `StockLevel.deductStock` için "@Version retry" diyordu; kod gerçekte `PESSIMISTIC_WRITE lock` kullanıyor.

**Fix**: `entities/stock-level.md` ve `flows/sale-checkout.md` düzeltildi — asıl koruma pessimistic lock, @Version secondary guard.

## Sources

- `pos-product-manager/src/main/java/com/sedcore/inventory/service/impl/StockLevelServiceImpl.java`
- [[raw/code-refs/2026-04-25-sale-checkout-flow]]

## Related

- [[entities/stock-level]]
- [[decisions/stock-level-pessimistic-lock]]
