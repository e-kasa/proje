---
title: SupplierAccount (Tedarikçi Cari)
tags: [entity, accounts, denormalize]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\entities\supplier-account.md
date: 2026-04-25
status: stub
---

# SupplierAccount

Tedarikçinin denormalize bakiyesi. [[entities/customer-account]] ile simetrik — `@Version` + `currentBalance`/`totalDebt`/`totalCredit`/`overdueAmount`.

## Sources

- `.claude/wiki/entities/supplier-account.md`
- [[raw/code-refs/2026-04-25-purchase-checkout-flow]]
- [[raw/code-refs/2026-04-25-drift-reconciliation-flow]]

## Related

- [[entities/supplier]]
- [[entities/account-transaction]]
- [[concepts/denormalization-with-reconcile]]
