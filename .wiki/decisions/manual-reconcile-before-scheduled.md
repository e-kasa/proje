---
title: Manuel Reconcile Endpoint (Scheduled Job'a Geçmeden)
type: decision
source: .claude/wiki/decisions/manual-reconcile-before-scheduled.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
status: active
---

# Manuel Reconcile Endpoint (Scheduled'dan Önce)

## Karar
[[syntheses/flow-drift-reconciliation]] ilk fazda **manuel POST endpoint** olarak yazıldı, `@Scheduled` cron job'a dönüştürülmedi.

## Neden
- Prod verisinde drift pattern'ı henüz gözlemlenmedi → scheduled sessiz düzeltme gerçek sorunu (concurrency, seed bug) maskeler
- Operator manuel tetikleme + log gözetimi → iç iş yükü görünür
- Endpoint response: `{ corrected: N }` → monitoring'e bağlanabilir

## Ne Zaman Scheduled'a Geçilir
- Manuel tetikleme sonrası 2-4 hafta drift sıfır veya açıklanabilir (ör. seed restart) dönüyorsa
- Audit log altyapısı kurulduysa ("kim/ne zaman/kaç row düzeltti")
- Prometheus drift count metric expose edildiyse

## Related
- [[syntheses/flow-drift-reconciliation]]
- [[sources/code-refs/2026-04-24-drift-reconcile]]
