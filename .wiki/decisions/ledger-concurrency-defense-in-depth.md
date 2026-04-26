---
title: Karar — Ledger Concurrency: @Version + Reconcile (A+D)
tags: [decision, concurrency, ledger, adr]
date: 2026-04-25
status: accepted
source: C:\Users\Win11\Documents\GitHub\proje\.claude\decisions\2026-04-24-ledger-no-version-accept-reconcile-guard.md
---

# Ledger Concurrency: A+D Defense-in-Depth

## Karar

[[entities/account-transaction]] için iki bağımsız savunma katmanı birlikte uygulanır:

- **A**: `@Version` runtime lost-update koruması (kodda zaten var)
- **D**: Periyodik reconcile + ReconcileAuditLog + alert kümülatif drift düzeltme

## Gerekçe

İki katman farklı drift kaynaklarını kapsar:

- @Version: aynı satır paralel UPDATE (soft cancel senaryosu)
- Reconcile: commit-fail rollback, manuel SQL, seed bug, uygulama bug'ı — @Version'ın kör noktaları

## Tarihçe

- İlk ADR (Sprint 1): "no @Version, D only"
- Revize (Sprint 2): kodda @Version zaten vardı → ADR kod gerçeğine göre yeniden çerçevelendi

## Sources

- [[raw/code-refs/2026-04-25-ledger-version-adr]]
- `.claude/decisions/2026-04-24-ledger-no-version-accept-reconcile-guard.md`

## Related

- [[entities/account-transaction]]
- [[concepts/defense-in-depth]]
- [[concepts/optimistic-lock-version]]
- [[concepts/drift]]
