---
title: SaleServiceIntegrated (Satış Servis Uygulaması)
tags: [entity, service, sale, transactional]
source: C:\Users\Win11\Documents\GitHub\proje\pos-product-manager\src\main\java\com\sedcore\sales\service\impl\SaleServiceIntegrated.java
date: 2026-04-25
status: stub
---

# SaleServiceIntegrated

Satış domain'inin ana servisi. Tek `@Transactional` altında 7 adımlı `createSale`, simetrik `cancelSale` ve `createSaleReturn`.

## Önemli Metodlar

- `createSale(SaleRequest)` → Sale + SaleItem + StockMovement + CustomerAccount update + AccountTransaction
- `checkCreditLimit(customer, amount, override)` — override flag + role check (Sprint 5 P2.5)
- `cancelSale(id, reason)` — stok geri + account ters + AccountTransaction CANCEL
- `createSaleReturn(id, request)` — kısmi iade

## Sources

- `pos-product-manager/src/main/java/com/sedcore/sales/service/impl/SaleServiceIntegrated.java`
- [[raw/code-refs/2026-04-25-sale-checkout-flow]]

## Related

- [[entities/sale]]
- [[decisions/credit-limit-override-role-based]]
