---
title: Cari Liste Pagination Yok (OPEN)
tags: [issue, open, accounts, performance]
date: 2026-04-25
status: open
priority: medium
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\syntheses\accounts-hub-production-readiness.md
---

# Accounts Pagination Missing (P1.3)

`/customers` + `/suppliers` tüm satırları döner. 1000+ müşteri olduğunda liste yavaşlar; frontend donar.

**Aksiyon**: `?page=0&size=50` + `Pageable` repository + Flutter infinite scroll.

## Sources

- [[raw/code-refs/2026-04-25-accounts-hub-production-readiness]]

## Related

- [[syntheses/accounts-module-overview]]
