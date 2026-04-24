---
title: Accounts Screens — Genel Bakış
tags: [synthesis, overview, flutter]
date: 2026-04-24
status: verified
covers:
  - "[[entities/accounts-hub-screen]]"
  - "[[entities/accounts-list-panel]]"
  - "[[entities/statement-detail-panel]]"
  - "[[entities/account-edit-form]]"
  - "[[entities/accounts-notifiers]]"
---

# Accounts Screens — Genel Bakış

Flutter `features/accounts/` feature'ının UI + state mimarisi. Tek hub ekranı, 3 ana widget, 3 StateNotifier, 2 modal (edit + payment).

## Bileşen Haritası

```
AccountsHubScreen [[entities/accounts-hub-screen]]
 ├─ AccountsSummaryBar (widget, 4 kart)
 ├─ AccountsListPanel [[entities/accounts-list-panel]]
 │    └─ (modal) AccountEditForm [[entities/account-edit-form]] — create
 └─ StatementDetailPanel [[entities/statement-detail-panel]]
      ├─ _Header (tarih picker + edit + PDF butonları)
      ├─ _SummaryGrid (4 kart)
      ├─ _TxRow (hareket listesi)
      └─ (modal) AccountEditForm — edit
      └─ (service) StatementPdfService.show()
```

## State Katmanı

[[entities/accounts-notifiers]] — 3 ana StateNotifier:
- `AccountSummaryNotifier` → özet + overdue list
- `OverdueTrackingNotifier` → (ayrı rota, scope dışı)
- `AccountStatementNotifier` → seçili hesap ekstresi

Ek provider'lar:
- `selectedAccountProvider` — seçili `StatementArgs` (nullable)
- `accountsListProvider` — merged customer+supplier list
- `paymentListProvider` — bugünkü tahsilat için

## Kritik Akışlar
- [[syntheses/accounts-data-flow]] — init load sırası + seçim akışı + edit akışı

## Ana Kararlar
- [[decisions/master-detail-800px-breakpoint]]
- [[decisions/merged-customer-supplier-list]]
- [[decisions/overdue-aware-list-ordering]]
- [[decisions/polymorphic-account-edit-form]]
- [[decisions/inline-form-to-modal-migration]]

## Geçmiş Buglar
- [[issues/today-collection-always-zero-ref]] — summary bar filter (çözüldü)
- [[issues/dar-ekran-yeniden-secim-bug]] — seçim reset pattern (çözüldü)

## Backend ile Kesişim

Upstream sayfalar (`.claude/wiki/`):
- `flows/accounts-hub-load` — backend çağrı zinciri
- `flows/today-collection-calc` — client filter
- `flows/drift-reconciliation` — admin arka plan
- `entities/customer-account`, `entities/supplier-account` — domain model
- `syntheses/accounts-overview` — uçtan uca hikaye
- `syntheses/accounts-hub-production-readiness` — gap analizi

## Kavramlar
- [[concepts/master-detail-layout]]
- [[concepts/sentinel-copy-with]]
- [[concepts/untyped-map-api]]

## Sources
- Tüm `sources/screens/*.md`
