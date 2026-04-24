---
title: AccountsHubScreen
tags: [entity, screen, flutter]
source: project_pos/lib/features/accounts/screens/accounts_hub_screen.dart
date: 2026-04-24
status: verified
---

# AccountsHubScreen

## Amaç
Cari Hesaplar feature'ının giriş ekranı. Responsive master-detail hub: summary + list + detail.

## Tip
`ConsumerStatefulWidget` → `_AccountsHubScreenState`.

## Route
`/accounts` (router: `app_router.dart`).

## Layout Stratejisi

```
             AppAppBar (title + refresh btn)
             ───────────────────────────────
             AccountsSummaryBar (4 kart yatay)
             ───────────────────────────────
   isWide?  → Row[ ListPanel(360) | Divider | DetailPanel(expanded) ]
     else   → ListPanel full, satır tıkla → push DetailPage
```

Breakpoint: **800px**.

## State

Screen kendi state'i minimal (sadece `_refresh` orchestration). Asıl state:
- [[entities/accounts-notifiers]] — 3 StateNotifier
- [[entities/accounts-list-provider]] — liste veri
- [[entities/selected-account-provider]] — seçili hesap

## Kritik Davranış

1. `initState` → `addPostFrameCallback` → 3 provider paralel load (ama `accountsListProvider` summary'den sonra çünkü overdueIds lazım)
2. Satır seçimi: `selectedAccountProvider` set + `accountStatementProvider.setAccount(...)`
3. Mobile push → pop sonrası `selectedAccountProvider = null` (aynı satıra tekrar tıklanabilsin)

## Tuzaklar

- `initState` senkron ama load async — `mounted` check her provider'da kritik
- `_wideBreakpoint = 800` hardcoded — tablet portrait (768) dar sayılır
- Refresh tüm provider'ları tetikler; büyük tenant'ta maliyetli

## Sources
- [[sources/screens/2026-04-24-accounts-hub-screen]]
- `project_pos/lib/features/accounts/screens/accounts_hub_screen.dart:19-138`

## Related
- [[entities/accounts-summary-bar]]
- [[entities/accounts-list-panel]]
- [[entities/statement-detail-panel]]
- [[entities/accounts-notifiers]]
- [[decisions/master-detail-800px-breakpoint]]
- [[decisions/post-frame-parallel-load]]
- `.claude/wiki/flows/accounts-hub-load.md` (backend çağrı zinciri)
