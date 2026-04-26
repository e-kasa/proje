---
title: Denormalization with Reconcile Pattern
tags: [concept, pattern, accounts, drift]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\patterns\denormalization-with-reconcile.md
date: 2026-04-25
status: draft
---

# Denormalization with Reconcile

**Pattern**: Hızlı okuma için denormalize özet + drift'i periyodik audit ile tespit + düzeltme.

## Uygulama

1. Write-through: her write ledger + denormalize (aynı @Transactional)
2. Audit: periyodik `reconcile()` — ledger'dan yeniden hesaplayıp denormalize ile karşılaştır
3. Drift varsa: ledger kabul + denormalize üstüne yaz + ReconcileAuditLog
4. Alert: drift count > 0 → Slack/email

## Trade-off

- ✅ Okuma hızı (O(1) bakiye)
- ✅ Drift kaynakları kapsayıcı (manuel SQL, commit fail, seed bug, ...)
- ❌ Drift tespiti gecikmeli (gece reconcile çalışana kadar)
- ❌ Audit altyapı gerekli (tablo + service + alert)

## Sources

- `.claude/wiki/patterns/denormalization-with-reconcile.md`
- [[raw/code-refs/2026-04-25-drift-reconciliation-flow]]
- [[raw/code-refs/2026-04-25-accounts-hub-production-readiness]]

## Related

- [[concepts/drift]]
- [[concepts/ledger-vs-denormalize]]
- [[entities/reconcile-audit-log]]
