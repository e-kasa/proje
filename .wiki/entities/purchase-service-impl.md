---
title: PurchaseServiceImpl (Satın Alma Servisi)
tags: [entity, service, purchase, transactional]
source: C:\Users\Win11\Documents\GitHub\proje\pos-product-manager\src\main\java\com\sedcore\purchase\service\impl\PurchaseServiceImpl.java
date: 2026-04-25
status: stub
---

# PurchaseServiceImpl

Satın alma domain servisi. `createPurchase` + `cancelPurchase` + `createPurchaseReturn` + `applyDiscount` + claim delegasyonları.

## Önemli Metodlar

- `createPurchase(PurchaseRequest)` — 6 adım, shortage varsa SupplierClaim auto-open
- `applyDiscount(id, request)` — shortage'ı iskonto ile kapat; SupplierAccount etkisiz, DISCOUNT audit

## Sources

- `pos-product-manager/src/main/java/com/sedcore/purchase/service/impl/PurchaseServiceImpl.java`
- [[raw/code-refs/2026-04-25-purchase-checkout-flow]]

## Related

- [[entities/purchase]]
- [[entities/supplier-claim]]
- [[decisions/supplier-claim-auto-open]]
