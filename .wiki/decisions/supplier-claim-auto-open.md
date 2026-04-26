---
title: Karar — SupplierClaim Otomatik Açılır
tags: [decision, purchase, claim]
date: 2026-04-25
status: accepted
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\entities\supplier-claim.md
---

# SupplierClaim Auto-Open

## Karar

`PurchaseServiceImpl.createPurchase` içinde `shortageAmount > 0` olursa **otomatik** [[entities/supplier-claim]] açılır. Manuel oluşturma yok.

## Gerekçe

Eksik teslimat tespiti insan hatasına bırakılamaz — sistem otomatik kaydeder; lifecycle (OPEN → RESOLVED_DELIVERY/DISCOUNT) kullanıcı takip edebilir.

## Sources

- [[raw/code-refs/2026-04-25-purchase-checkout-flow]]

## Related

- [[entities/supplier-claim]]
- [[entities/purchase]]
