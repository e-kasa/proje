---
title: Ledger @Version — Drift'e Reconcile + Defense-in-Depth
type: decision
source: .claude/wiki/decisions/trust-reconcile-no-ledger-version.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
status: active
---

# Ledger @Version — Drift'e Reconcile + Defense-in-Depth (A+D)

## Karar
[[entities/account-transaction]] üzerinde `@Version` **vardır** (kod gerçeği, 2026-04-24 tespit). Karar A+D **defense-in-depth**: `@Version` runtime lost-update koruması + [[syntheses/flow-drift-reconciliation]] kümülatif drift düzeltme + [[entities/reconcile-audit-log]] + (Sprint 3) alerting.

## Neden
1. `@Version` kod tarafında zaten mevcut — kaldırmak risk yaratır
2. Append-only semantiği `cancel(user)` gibi UPDATE'lerde @Version koruma sağlar (insert-only değil, soft-cancel destekli)
3. Pessimistic lock (SELECT FOR UPDATE) throughput'u ciddi düşürür
4. Mevcut drift insidansı düşük — reconcile maliyeti kabul edilebilir
5. İki katman birbirini tamamlar: anlık (Version) + kümülatif (reconcile)

## Geçersiz Olma Koşulu
- Prod'da drift > %1 → B (pessimistic) gündeme gelir
- Concurrent sale+payment yarışı repro edildiyse karar yeniden değerlendirilir

## Related
- `.claude/decisions/2026-04-24-ledger-no-version-accept-reconcile-guard.md` (tam ADR)
- [[concepts/drift]]
- [[concepts/write-through-cache]]
- [[concepts/pattern-denormalization-with-reconcile]]
- [[syntheses/flow-drift-reconciliation]]
- [[entities/account-transaction]]
- [[entities/reconcile-audit-log]]
