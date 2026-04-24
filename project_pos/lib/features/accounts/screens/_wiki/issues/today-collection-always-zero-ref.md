---
title: Bugünkü Tahsilat 0 TL (Historical Reference)
tags: [issue, resolved, historical]
date: 2026-04-23
status: resolved
---

# Bugünkü Tahsilat 0 TL — Tarihsel Referans

Bu sorun **önce** çözüldü; bu wiki kurulumundan önce. Detay üst wiki'de:

- **Ana kayıt**: `.claude/wiki/issues/today-collection-always-zero.md`
- **Root cause**: `accounts_summary_bar.dart` `_todayCollection` filter alan adları yanlış (`p['type']` → yok, `paymentType` var; `p['date']` → yok, `paymentDate` var)
- **Fix**: 2026-04-23 — correct field names + `customerId != null` + `isCancelled != true`

## Bu Wiki Kapsamında
[[concepts/untyped-map-api]] pattern'inin canlı örneği. `AccountsSummaryBar` bu wiki'nin ingest scope'unda değil ama aynı feature.

## Related
- `.claude/wiki/issues/today-collection-always-zero.md` (parent)
- [[concepts/untyped-map-api]]
- [[entities/accounts-notifiers]] — `paymentListProvider` aynı payment listesini kullanır
