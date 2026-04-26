---
title: AccountsHubScreen — cari hesaplar master/detail hub
type: entity
source: project_pos/lib/features/accounts/screens/accounts_hub_screen.dart
ingested: 2026-04-25
last-verified: 2026-04-25
status: stub
---

# AccountsHubScreen

## Tanım

Cari hesaplar ana ekranı — **master/detail hub**. Geniş ekranda solda hesap listesi + sağda statement detay; dar ekranda liste full + detay push.

## Kod Konumu

- `project_pos/lib/features/accounts/screens/accounts_hub_screen.dart:19`
- `ConsumerStatefulWidget` (Riverpod)

## Davranış

- **Breakpoint**: ≥800px master/detail; <800px liste full + push navigation.
- **initState** paralel yükleme:
  - `accountSummaryProvider` (toplam alacak/borç)
  - `paymentListProvider` (son ödemeler)
  - `accountsListProvider` (cari listesi)
- **`_refresh`** → tüm provider'ları yeniden çek; seçili cari varsa `accountStatementProvider` da yenile.
- **`_selectFromList`** → master/detail moduna göre setState veya navigation push.

## Widget Ağacı

- `AppScaffold` + `AppAppBar`
- `AccountsSummaryBar` — üst metrik şeridi
- `AccountsListPanel` — sol/full liste
- `StatementDetailPanel` — sağ/push ekstre

## Kullanım

Ana cari yönetim ekranı. Payment/statement/overdue işleyişi buradan başlar. Sprint 6a/6b'de iyileştirildi (payment recording, vehicle plate tracking).

## Performance Notu

DB-side aggregation optimization (Sprint 5) `accountSummaryProvider` arka planında çalışır — bkz. [[decisions/db-side-aggregate-over-java-loop]].

## Related

- [[entities/customer-account]]
- [[entities/supplier-account]]
- [[syntheses/accounts-module-overview]]
- [[syntheses/flow-accounts-hub-load]]
- [[decisions/2026-04-24-vehicle-plate-tracking-option-a]]
- [[concepts/app-colors-palette]]
