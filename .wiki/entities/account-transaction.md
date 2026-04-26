---
title: AccountTransaction (Ledger Kaydı)
tags: [entity, ledger, source-of-truth, accounts]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\entities\account-transaction.md
date: 2026-04-25
status: draft
---

# AccountTransaction

**Ledger** — tüm cari hesap hareketlerinin append-only kaydı. SEDCORE'da cari gerçeğinin **source of truth**'u. [[entities/customer-account]] ve [[entities/supplier-account]] buradan türer (reconcile ile).

## Önemli Alanlar

- `customer` / `supplier` (FK, ikisinden biri)
- `debitAmount`, `creditAmount`
- `balance` (insert anındaki running balance snapshot)
- `isCancelled`, `referenceType` (SALE/PAYMENT/PURCHASE/DISCOUNT/CANCEL/RETURN), `referenceId`, `referenceNumber`
- `dueDate`, `isOverdue`
- `@Version` (defense-in-depth; soft cancel UPDATE'lerinde aktif)

## Append-Only Semantik

Insert sonrası değiştirilmez; iptal için `isCancelled=true` set edilir (soft cancel). Bkz. [[concepts/append-only]].

## Sources

- `.claude/wiki/entities/account-transaction.md`
- [[raw/code-refs/2026-04-25-ledger-version-adr]]
- [[raw/code-refs/2026-04-25-drift-reconciliation-flow]]

## Related

- [[entities/customer-account]]
- [[entities/supplier-account]]
- [[concepts/ledger-vs-denormalize]]
- [[concepts/drift]]
- [[decisions/ledger-concurrency-defense-in-depth]]
