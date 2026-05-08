---
title: Cari Liste Pagination Yok (RESOLVED)
tags: [issue, resolved, accounts, performance]
date: 2026-04-25
resolved: 2026-05-06
status: resolved
priority: medium
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\syntheses\accounts-hub-production-readiness.md
---

# Accounts Pagination Missing (P1.3) — RESOLVED

`/customers` + `/suppliers` tüm satırları döner. 1000+ müşteri olduğunda liste yavaşlar; frontend donar.

## Çözüm

| Sprint | Aşama | Detay |
|---|---|---|
| Sprint 8 (B0) | Backend cursor pagination | `GET /api/v1/accounts/list?cursor=X&limit=N&filter=&q=` — cursor-based, sıralama (name, type, id), backend `Math.min(200, limit)` clamp |
| Sprint 8 hot-fix v2 | `_pageLimit=100` + auto-prefetch | KOBİ tenant uyumu: ilk yükleme 100 + boş query'de 1 sayfa daha (~200) → "Z" harfli müşteri açılışta görünür |
| Sprint 8 frontend | Infinite scroll | `accounts_list_panel.dart` 200px threshold → `loadMore()` |
| Sprint 30 | Kullanıcı tercihi 50/100/200 | `accountsListPaginationProvider` (SharedPreferences `accounts_list.page_limit`) + `_PageSizeButton` UI seçici |

## Kanıt

- Backend: [`AccountStatementControllerImpl.java`](pos-product-manager/src/main/java/com/sedcore/finance/controller/impl/AccountStatementControllerImpl.java)
- Frontend: [`accounts_list_provider.dart:165-203`](project_pos/lib/features/accounts/providers/accounts_list_provider.dart#L165-L203) — `_fetch` cursor-based
- Settings: [`accounts_list_settings.dart`](project_pos/lib/features/accounts/providers/accounts_list_settings.dart) — kullanıcı page-limit tercihi
- UI: [`accounts_list_panel.dart`](project_pos/lib/features/accounts/widgets/accounts_list_panel.dart) — `_PageSizeButton` (search bar yanında)

## Sources

- [[raw/code-refs/2026-04-25-accounts-hub-production-readiness]]

## Related

- [[syntheses/accounts-module-overview]]
- [[syntheses/sprint-8-implementation-plan-2026-04-26]] §WP1
