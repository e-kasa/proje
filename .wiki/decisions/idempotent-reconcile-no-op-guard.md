---
title: Karar — Idempotent Reconcile (Drift Yoksa Save Yok)
tags: [decision, reconcile, idempotency]
date: 2026-04-25
status: accepted
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\decisions\idempotent-reconcile-no-op-guard.md
---

# Idempotent Reconcile

## Karar

`reconcile(id)` drift 0 ise `save()` çağırmaz, `@Version` tick'lemez. Audit log yine yazılır ("hiç drift yok" bilgisi için).

## Gerekçe

- İstemsiz @Version ilerlemesi → sonraki UPDATE'ler OptimisticLockException atarsa tuhaf
- Nightly reconcile her gece sessizce çalışsın, drift olmayan tenant'ları "dokunmadan" geçsin

## Sources

- `.claude/wiki/decisions/idempotent-reconcile-no-op-guard.md`
- [[raw/code-refs/2026-04-25-drift-reconciliation-flow]]

## Related

- [[decisions/ledger-as-source-of-truth]]
- [[entities/reconcile-audit-log]]
