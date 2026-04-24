---
title: AccountsHubScreen — Cari Hesaplar Master-Detail Hub
tags: [source, screen, flutter, master-detail]
source: raw/screens/accounts-hub-screen.md
date: 2026-04-24
status: verified
---

# AccountsHubScreen

## Amaç
Cari Hesaplar (customer + supplier) için responsive **master-detail hub** ekranı. Summary bar + liste paneli + ekstre detay paneli — tek rota üzerinde tümü.

## Ne Yapıyor

1. `initState` → `WidgetsBinding.addPostFrameCallback` ile 3 provider paralel yüklenir:
   - `accountSummaryProvider.load()` — toplam bakiye + overdue list
   - `paymentListProvider.load()` — bugünkü tahsilat için payment listesi
   - `accountsListProvider.load()` — liste (summary'nin overdueIds'inden sonra)
2. `LayoutBuilder` — `maxWidth >= 800` → row (liste 360px + detay expanded), else liste full screen.
3. Satır tıklanır → `selectedAccountProvider` set edilir + `accountStatementProvider.setAccount(...)`.
   - Dar ekranda → MaterialPageRoute push (`_AccountDetailPage`).
   - `.then((_) → selectedAccountProvider = null)` — pop sonrası seçim temizlenir (aynı cariye tekrar tıklanabilir).
4. Refresh: pull-to-refresh veya AppBar refresh butonu → summary + payments paralel, sonra list + statement sıralı.

## Kritik Kod Noktaları

- [accounts_hub_screen.dart:27](../../../accounts_hub_screen.dart) — `_wideBreakpoint = 800`
- [accounts_hub_screen.dart:32-37](../../../accounts_hub_screen.dart) — postFrameCallback initLoad
- [accounts_hub_screen.dart:51-68](../../../accounts_hub_screen.dart) — `_selectFromList` (responsive branching)
- [accounts_hub_screen.dart:90-122](../../../accounts_hub_screen.dart) — LayoutBuilder master-detail

## Kararlar
- [[decisions/master-detail-800px-breakpoint]]
- [[decisions/post-frame-parallel-load]]

## İlgili
- [[entities/accounts-hub-screen]]
- [[entities/accounts-notifiers]]
- [[entities/accounts-list-panel]]
- [[entities/statement-detail-panel]]
- [[syntheses/accounts-screens-overview]]
- [[syntheses/accounts-data-flow]]

## Sources
- `raw/screens/accounts-hub-screen.md`
- `project_pos/lib/features/accounts/screens/accounts_hub_screen.dart`
