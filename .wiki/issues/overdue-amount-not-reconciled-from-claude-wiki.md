---
title: overdueAmount Reconcile Kapsamı Dışında (detailed merge from .claude/wiki/)
type: issue
source: .claude/wiki/issues/overdue-amount-not-reconciled.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
status: resolved
note: "MERGE_NEEDED — overlap; this resolved version has 5th aggregate JPQL + verification recipe."
---

# overdueAmount Reconcile Kapsamı Dışında

## Belirti (Geçmiş)
[[syntheses/flow-drift-reconciliation]] sadece `currentBalance`, `totalDebt`, `totalCredit` ve `totalTransactionCount` alanlarını karşılaştırıyordu. `overdueAmount` ledger'dan türetilmiyordu → drift oluşursa düzelmezdi.

## Kök Neden
`overdueAmount` hesabı vadesi geçen işlemlerin toplamı — ledger'da `AccountTransaction.dueDate` + `isOverdue` flag kullanılıyor, fakat reconcile query bu koşulu aggregate etmiyordu.

## Fix (2026-04-24 — Sprint 2)

**Dosyalar**:
- `AccountTransactionRepository.java:122-138` — `ledgerTotalsForCustomer` ve `ledgerTotalsForSupplier` query'lerine 5. aggregate eklendi:
  ```jpql
  COALESCE(SUM(CASE WHEN (t.isOverdue = true
                          OR (t.dueDate IS NOT NULL AND t.dueDate < CURRENT_DATE AND t.debitAmount > 0))
                     THEN t.debitAmount - t.creditAmount
                     ELSE 0 END), 0)
  ```
  `fetchSummaryAggregates` ile aynı overdue koşulu — tutarlılık.

- `CustomerAccountServiceImpl.reconcile` — `totals[4]` okuma + 4. eşitlik kontrolü + `acct.setOverdueAmount(ledgerOverdue)` + log'da `overdueDrift`.
- `SupplierAccountServiceImpl.reconcile` — simetrik.

## Verification
Seed'de `dueDate < today AND debitAmount > 0` bir AccountTransaction ekle → `CustomerAccount.overdueAmount` elle 0'a çek → `/admin/accounts/reconcile/customer/{id}` → sonra DB'de `customer_accounts.overdue_amount` ledger SUM'una eşit olmalı.

## Related
- [[syntheses/flow-drift-reconciliation]]
- [[entities/customer-account]]
- [[entities/supplier-account]]
- [[entities/account-transaction]]
- [[sources/code-refs/2026-04-24-drift-reconcile]]
