---
title: overdueAmount Reconcile Kapsamı Dışında (RESOLVED)
tags: [issue, resolved, accounts, drift]
date: 2026-04-25
status: resolved
resolved-date: 2026-04-24
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\issues\overdue-amount-not-reconciled.md
---

# overdueAmount Reconcile Eksikliği

**Kök neden**: Reconcile sadece balance/debt/credit/count 4 aggregate'i düzeltiyordu; `overdueAmount` türev alanı drift içinde kalıyordu.

**Fix**: 5. aggregate eklendi — `COALESCE(SUM(CASE WHEN (isOverdue=true OR (dueDate < today AND debit > 0)) THEN debit-credit ELSE 0 END), 0)`. Reconcile `totals[4]` okur + 4. eşitlik kontrolü + `setOverdueAmount` (Sprint 2).

## Sources

- [[raw/code-refs/2026-04-25-drift-reconciliation-flow]]
- [[raw/code-refs/2026-04-25-accounts-hub-production-readiness]]

## Related

- [[entities/customer-account]]
- [[entities/account-transaction]]
