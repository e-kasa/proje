---
title: Drift (Denormalize ↔ Ledger Sapması)
tags: [concept, accounts, drift, correctness]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\concepts\drift.md
date: 2026-04-25
status: draft
---

# Drift

Denormalize özet alan (örn. `CustomerAccount.currentBalance`) ile ledger'dan yeniden hesaplanan değer (SUM AccountTransaction) arasında oluşan sapma. Finansal veride kabul edilemez; tespit + düzeltme gerekir.

## Kaynakları

1. Concurrent insert sırasında denormalize eksik update (cross-transaction)
2. Commit fail sonrası ledger commit + denormalize rollback
3. Manuel SQL müdahalesi
4. Uygulama bug'ı aggregation formülünü değiştirmesi
5. Seed data tutarsız

## Çözüm

Ledger kabul edilir (source of truth), denormalize üstüne yazılır. Bkz. [[concepts/denormalization-with-reconcile]] ve [[decisions/ledger-as-source-of-truth]].

## Sources

- [[raw/code-refs/2026-04-25-drift-reconciliation-flow]]
- [[raw/code-refs/2026-04-25-ledger-version-adr]]

## Related

- [[concepts/ledger-vs-denormalize]]
- [[concepts/denormalization-with-reconcile]]
- [[entities/account-transaction]]
- [[entities/customer-account]]
