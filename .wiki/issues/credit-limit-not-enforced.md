---
title: Satış Akışında Kredi Limiti Enforce Edilmiyor (RESOLVED)
tags: [issue, resolved, sales, credit]
date: 2026-04-25
status: resolved
resolved-date: 2026-04-24
source: C:\Users\Win11\Documents\GitHub\proje\pos-product-manager\src\main\java\com\sedcore\sales\service\impl\SaleServiceIntegrated.java
---

# Credit Limit Not Enforced

**Kök neden**: Kredi limiti aşılsa da satış tamamlanabiliyordu — `isCreditLimitExceeded` flag'i hesaplanıyor ama checkout'ta kontrol edilmiyordu.

**Fix**: `SaleServiceIntegrated.checkCreditLimit` + `SaleRequest.overrideCreditLimit` + SecurityContextHolder rol check. Flutter `PaymentPanel._submitWithCreditLimitFallback` confirm dialog (Sprint 5 P2.5).

## Sources

- [[raw/code-refs/2026-04-25-sale-checkout-flow]]
- [[raw/code-refs/2026-04-25-accounts-hub-production-readiness]]

## Related

- [[decisions/credit-limit-override-role-based]]
- [[entities/sale-service-integrated]]
