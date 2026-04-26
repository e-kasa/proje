---
title: SupplierClaim (Eksik Teslimat Talebi)
tags: [entity, purchase, claim]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\entities\supplier-claim.md
date: 2026-04-25
status: stub
---

# SupplierClaim

[[entities/purchase]] `shortageAmount > 0` olduğunda otomatik açılan talep. Lifecycle: OPEN → RESOLVED_DELIVERY / RESOLVED_DISCOUNT / CANCELLED.

- **Açılma**: `PurchaseServiceImpl.createPurchase` içinde, her eksik kalem `SupplierClaimLine` olarak
- **Kapanış**: geç teslim (PURCHASE_IN) veya iskonto (`applyDiscount`)
- **Finansal**: iskonto ile kapanışta SupplierAccount etkisi yok

## Sources

- `.claude/wiki/entities/supplier-claim.md`
- [[raw/code-refs/2026-04-25-purchase-checkout-flow]]

## Related

- [[entities/purchase]]
- [[decisions/discount-no-account-effect]]
- [[decisions/supplier-claim-auto-open]]
