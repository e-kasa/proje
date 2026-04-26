---
title: Karar — İskonto SupplierAccount'u Etkilemez (Audit Only)
tags: [decision, purchase, accounting]
date: 2026-04-25
status: accepted
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\entities\supplier-claim.md
---

# İskonto SupplierAccount Etkisiz

## Karar

`PurchaseServiceImpl.applyDiscount` ile shortage kapatılırsa:
- `Purchase.shortageAmount` ↓
- `Purchase.discountAmount` ↑
- [[entities/supplier-account]] etkisiz (debit/credit değişmez)
- Audit için [[entities/account-transaction]] tipi `DISCOUNT` yazılır (balance snapshot, etkisiz)

## Gerekçe

Eksik mal için baştan debit yazılmamıştı (bkz. [[decisions/debit-only-received-amount]]); iskonto "olmayan borcu kapatıyor" semantiği. Ters credit yazmak yanlış olur.

## Sources

- [[raw/code-refs/2026-04-25-purchase-checkout-flow]]

## Related

- [[entities/supplier-claim]]
- [[decisions/debit-only-received-amount]]
- [[concepts/invoice-vs-total-shortage]]
