---
title: AccountsHub Flutter Ekranları
type: source
source: .claude/wiki/sources/code-refs/2026-04-21-accounts-hub-screens.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# AccountsHub Flutter Ekranları

## Amaç
Cari Hesaplar (Accounts) feature'ının Flutter tarafı — özet bar, müşteri/tedarikçi listesi, ekstre detayı, vadesi geçmiş takibi, ödeme kayıt modal'ı.

## Ne Yapıldı

1. **AccountsHubScreen**: Ana sayfa, 3 panel layout (summary bar + list panel + detail panel)
2. **Widgets**: `accounts_summary_bar` (4 özet kartı), `accounts_list_panel` (müşteri/tedarikçi satır listesi), `statement_detail_panel` (seçili hesabın ekstresi)
3. **Alt ekranlar**: `AccountStatementScreen`, `AccountSummaryDashboardScreen`, `OverdueTrackingScreen`, `PaymentRecordModal`
4. **Providers**: `accountsListProvider` (liste + filter), `selectedAccountProvider` (detay fetch)

## Değişen Dosyalar

- project_pos/lib/features/accounts/screens/accounts_hub_screen.dart
- project_pos/lib/features/accounts/widgets/accounts_summary_bar.dart — `_todayCollection` filter
- project_pos/lib/features/accounts/widgets/accounts_list_panel.dart — bakiye satırı
- project_pos/lib/features/accounts/widgets/statement_detail_panel.dart
- project_pos/lib/features/accounts/providers/accounts_list_provider.dart — müşteri + tedarikçi birleşik liste
- project_pos/lib/features/accounts/providers/selected_account_provider.dart
- project_pos/lib/features/accounts/screens/payment_record_modal.dart

## Raw Pointer

`commit: c1a44fe`

## Sorunlar (çözüldü)

- [[issues/today-collection-always-zero]] — `p['type']`/`p['date']` alan adları backend ile uyuşmuyordu
- [[issues/customer-list-balance-zero]] (backend'e bağlı, bkz. 2026-04-22)
- [[issues/supplier-list-balance-zero]] — DTO field adı `balance` → `currentBalance` rename gerekliydi

## İlgili

- [[syntheses/flow-accounts-hub-load]]
- [[syntheses/flow-today-collection-calc]]
- [[entities/payment]]
- [[syntheses/accounts-overview]]
