---
title: Karar — Ledger Source of Truth, Denormalize Türevdir
tags: [decision, accounts, drift]
date: 2026-04-25
status: accepted
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\decisions\ledger-as-source-of-truth.md
---

# Ledger = Source of Truth

## Karar

Drift tespit edildiğinde [[entities/account-transaction]] doğru kabul edilir; denormalize ([[entities/customer-account]], [[entities/supplier-account]]) üstüne yazılır. Ters yön yasak.

## Gerekçe

Ledger append-only — tüm hareketler tek tek kaydedilir, en az "yalan" söyler. Denormalize cache; drift kaynağı her zaman denormalize tarafında.

## Sources

- `.claude/wiki/decisions/ledger-as-source-of-truth.md`
- [[raw/code-refs/2026-04-25-drift-reconciliation-flow]]

## Related

- [[concepts/ledger-vs-denormalize]]
- [[concepts/drift]]
