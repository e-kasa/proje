---
title: Pattern — Denormalization with Reconcile
type: concept
source: .claude/wiki/patterns/denormalization-with-reconcile.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
note: "MERGE_NEEDED — overlap with .wiki/concepts/denormalization-with-reconcile.md (similar topic, different angle)."
---

# Denormalization with Reconcile

## Problem
Ledger (append-only hareket) tek başına okumada yavaş — her bakiye sorgusunda `SUM(debit − credit)` kabul edilemez. Özellikle liste ekranlarında N müşteri × her biri için SUM.

## Çözüm
Özet alan (`currentBalance`) denormalize tutulur; yazım anında write-through güncellenir. Periyodik reconcile ile ledger'a karşı doğrulanır.

## SEDCORE Uygulaması

| Entity | Denormalize Alan | Beslenme | Reconcile |
|---|---|---|---|
| [[entities/customer-account]] | currentBalance, totalDebt, totalCredit | applyDebit/Credit | [[syntheses/flow-drift-reconciliation]] |
| [[entities/supplier-account]] | aynı | simetrik | aynı |
| [[entities/stock-level]] | quantity | StockMovement event'leri | (manuel, henüz yok) |

## Bileşenler

1. **Denormalize entity** — `@Version` opt-lock, write-through setter metodları (applyDebit/Credit/reverse*)
2. **Ledger entity** — append-only, `isCancelled` flag, `@Version` VAR (defense-in-depth)
3. **Reconcile servis** — ledger aggregate vs denormalize karşılaştırma, idempotent save
4. **Admin endpoint** — manuel tetik, drift count döner

## Trade-off

- Okuma hızlı (tek row fetch)
- Liste ekranı performans iyi
- Kredi limit kontrolü kolay (currentBalance + creditLimit karşılaştırma)
- [[concepts/drift]] riski
- `@Version` zorunlu
- Reconcile maintenance iş yükü

## Tuzaklar

- `@Version` ledger'da var ama append-only semantiğinde sınırlı koruma
- Reconcile scheduled yapılırsa gözlem tut — sessiz düzeltme gerçek sorunu maskeler
- Seed data ledger'a yazıp cache güncellemesi unutulursa baştan drift

## Alternatifler

- **Pure ledger + CQRS view** — separate read model, async project. Maintenance daha ağır
- **Materialized view** — DB-side, ama PostgreSQL'de manual refresh gerekir
- **Pure denormalize (ledger yok)** — audit kaybı, iptal yapılamaz

## Sources

- [[sources/code-refs/2026-04-24-drift-reconcile]]
- [[sources/code-refs/2026-04-22-accounts-hub-perf]]

## Related

- [[concepts/ledger-vs-denormalize]]
- [[concepts/drift]]
- [[concepts/write-through-cache]]
- [[syntheses/flow-drift-reconciliation]]
- [[concepts/optimistic-lock-version]]
