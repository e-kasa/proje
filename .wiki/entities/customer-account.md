---
title: CustomerAccount (Müşteri Cari Hesap)
tags: [entity, accounts, denormalize]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\entities\customer-account.md
date: 2026-04-25
status: draft
---

# CustomerAccount

Müşterinin denormalize (özetlenmiş) bakiyesi: `currentBalance`, `totalDebt`, `totalCredit`, `overdueAmount`. `@Version` opt-lock. Gerçek hareketler [[entities/account-transaction]]'da; denormalize buradaki kayıtlarla drift oluşabilir → [[concepts/drift]].

## Türev Alanlar

- `availableCreditLimit = creditLimit − currentBalance`
- `isCreditLimitExceeded = availableCreditLimit < 0`

## Sources

- `.claude/wiki/entities/customer-account.md`
- [[raw/code-refs/2026-04-25-sale-checkout-flow]]
- [[raw/code-refs/2026-04-25-drift-reconciliation-flow]]

## Related

- [[entities/customer]]
- [[entities/account-transaction]]
- [[concepts/denormalization-with-reconcile]]
- [[concepts/write-through-cache]]
