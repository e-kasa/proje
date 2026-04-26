---
title: ReconcileAuditLog (Reconcile Denetim Kaydı)
tags: [entity, audit, accounts]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\entities\reconcile-audit-log.md
date: 2026-04-25
status: stub
---

# ReconcileAuditLog

Her drift reconcile çağrısının audit kaydı. Kim ne zaman hangi hesabı hangi sonuçla düzeltti. `@Transactional(REQUIRES_NEW)` — asıl reconcile rollback olsa bile audit korunur.

## Alanlar

- `scope` (SINGLE | ALL)
- `entityType` (CUSTOMER | SUPPLIER)
- `accountId`, balance/debt/credit before-after, driftAmount, correctionCount

## Sources

- `.claude/wiki/entities/reconcile-audit-log.md`
- [[raw/code-refs/2026-04-25-drift-reconciliation-flow]]
- [[raw/code-refs/2026-04-25-accounts-hub-production-readiness]]

## Related

- [[entities/account-transaction]]
- [[concepts/drift]]
- [[syntheses/accounts-module-overview]]
