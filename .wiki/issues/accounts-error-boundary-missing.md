---
title: AccountsHub Error Boundary / Loading State Eksik (RESOLVED)
tags: [issue, resolved, ux, flutter]
date: 2026-04-25
resolved: 2026-04-26
status: resolved
priority: medium
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\syntheses\accounts-hub-production-readiness.md
---

# Error Boundary Missing (P1.5) — RESOLVED

AccountsHub network fail / backend 500 olduğunda ekran boş veya default error. Profesyonel POS UI için loading skeleton + error banner + retry butonu gerekir.

## Çözüm — Sprint 8 hot-fix WP2 (3/3 panel)

`AccountsErrorView` widget'ı 3 panele entegre edildi. Loading skeleton (`CircularProgressIndicator`) + retry butonu + friendly error message.

| Panel | Provider | Konum | Tarih |
|---|---|---|---|
| `AccountsListPanel` | `accountsListProvider` | [accounts_list_panel.dart:175-181](project_pos/lib/features/accounts/widgets/accounts_list_panel.dart#L175-L181) | Sprint 8 |
| `StatementDetailPanel` | `accountStatementProvider` | [statement_detail_panel.dart:48-54](project_pos/lib/features/accounts/widgets/statement_detail_panel.dart#L48-L54) | Sprint 8 hot-fix |
| `AccountsSummaryBar` | `accountSummaryProvider` | [accounts_summary_bar.dart:23-34](project_pos/lib/features/accounts/widgets/accounts_summary_bar.dart#L23-L34) | Sprint 8 hot-fix (compact mode) |

`AccountsSummaryBar` üst bar olduğu için `AccountsErrorView(compact: true)` mode kullanılır — küçük inline banner.

## Sources

- [accounts_error_view.dart](project_pos/lib/features/accounts/widgets/accounts_error_view.dart) — paylaşılan widget
- [[raw/code-refs/2026-04-25-accounts-hub-production-readiness]]

## Related

- [[syntheses/accounts-module-overview]]
- [[syntheses/sprint-8-implementation-plan-2026-04-26]] §WP2
