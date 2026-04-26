---
title: Defense in Depth (Katmanlı Savunma)
tags: [concept, security, concurrency]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\decisions\2026-04-24-ledger-no-version-accept-reconcile-guard.md
date: 2026-04-25
status: stub
---

# Defense in Depth

Birden fazla bağımsız savunma katmanı — biri fail olursa diğeri devreye girer. SEDCORE'da ledger concurrency: `@Version` (runtime real-time lost-update) + reconcile (kümülatif drift düzeltme). İkisi birbirini kapsamayan boşluklara cevap verir.

## Sources

- [[raw/code-refs/2026-04-25-ledger-version-adr]]

## Related

- [[concepts/optimistic-lock-version]]
- [[concepts/drift]]
- [[decisions/ledger-concurrency-defense-in-depth]]
