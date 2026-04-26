---
title: Silent Null Bug (Map Okuma Tuzağı)
tags: [concept, bug-class, untyped, client]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\issues\today-collection-always-zero.md
date: 2026-04-25
status: stub
---

# Silent Null Bug

Client `Map<String,dynamic>` response okuyorken alan adı yanlış/değişirse compile hatası **yok**, runtime'da null → 0.0/false. Sessizce UI yanlış değer gösterir.

SEDCORE'da 3+ kez görüldü:
- [[issues/today-collection-always-zero]] — paymentDate → transactionDate rename
- [[issues/customer-list-balance-zero]] — toMap alanı atlanmış
- [[issues/supplier-list-balance-zero]] — balance → currentBalance rename

Çözümü [[concepts/typed-api-contract]] (Sprint 4 OpenAPI codegen).

## Sources

- [[raw/code-refs/2026-04-25-openapi-codegen-pattern]]
- `.claude/wiki/issues/today-collection-always-zero.md`

## Related

- [[concepts/typed-api-contract]]
- [[issues/today-collection-always-zero]]
