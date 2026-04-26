---
title: Ledger vs Denormalize Ayrımı
tags: [concept, accounts, architecture]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\concepts\ledger-vs-denormalize.md
date: 2026-04-25
status: draft
---

# Ledger vs Denormalize

SEDCORE cari hesap modeli iki katmandır:

| Katman | Tablolar | Rol |
|---|---|---|
| **Ledger** | [[entities/account-transaction]] | Append-only gerçek — tüm hareketler tek tek |
| **Denormalize** | [[entities/customer-account]], [[entities/supplier-account]] | Özet bakiye — hızlı okuma için |

İki katman senkron tutulmalı; olmazsa → [[concepts/drift]].

## Neden İki Katman?

- Ledger okuma hızlı değil (N hareket SUM)
- Denormalize okuma O(1) — liste ekranları için kritik
- Güncelleme write-through + periyodik reconcile audit

## Sources

- [[raw/code-refs/2026-04-25-drift-reconciliation-flow]]
- `.claude/wiki/concepts/ledger-vs-denormalize.md`

## Related

- [[concepts/drift]]
- [[concepts/write-through-cache]]
- [[concepts/denormalization-with-reconcile]]
