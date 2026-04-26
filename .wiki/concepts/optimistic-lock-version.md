---
title: Optimistic Lock (@Version) Pattern
tags: [concept, pattern, concurrency, hibernate]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\patterns\optimistic-lock-version.md
date: 2026-04-25
status: draft
---

# Optimistic Lock (@Version)

Entity üzerinde `@Version` alanı → Hibernate her UPDATE'e `WHERE version = ?` ekler; eşleşmezse `OptimisticLockException`. Lost update senaryolarında ikinci yazım algılanır.

## SEDCORE Kullanımı

- [[entities/customer-account]], [[entities/supplier-account]] — concurrent sale + payment yarışı
- [[entities/stock-level]] — secondary (asıl koruma pessimistic lock)
- [[entities/account-transaction]] — defense-in-depth (soft cancel UPDATE'leri)
- [[entities/sale]], [[entities/sale-item]], [[entities/purchase]] — cancel/return concurrency

## Sources

- `.claude/wiki/patterns/optimistic-lock-version.md`
- [[raw/code-refs/2026-04-25-ledger-version-adr]]

## Related

- [[concepts/defense-in-depth]]
- [[decisions/ledger-concurrency-defense-in-depth]]
