---
title: Ledger Source of Truth (detailed merge from .claude/wiki/)
type: decision
source: .claude/wiki/decisions/ledger-as-source-of-truth.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
status: active
note: "MERGE_NEEDED — overlap with .wiki/decisions/ledger-as-source-of-truth.md. This version has detailed reasoning + exceptions list."
---

# Ledger Source of Truth

## Karar
Drift tespit edildiğinde **ledger ([[entities/account-transaction]]) doğru kabul edilir**, denormalize ([[entities/customer-account]]/[[entities/supplier-account]]) üstüne yazılır.

## Neden
- Ledger append-only + `isCancelled` flag → tarihsel gerçek
- Denormalize cache'tir, tanım gereği türetilmiş değer
- Ters yön (denormalize → ledger düzelt) audit anlamını kaybettirir
- Ledger'da drift tespit ederken ledger'ı değiştirmek meta-level çelişki

## İstisnalar
- Ledger'ın kendisi hatalı (bug fix commit sonrası re-insert gerekiyorsa) → **manuel migration**, reconcile değil
- Seed data ledger'a yazarken cache'i atladıysa → reconcile doğru davranır (denormalize'ı senkronlar)

## Related
- [[concepts/ledger-vs-denormalize]]
- [[syntheses/flow-drift-reconciliation]]
