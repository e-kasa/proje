---
title: StatementDetailPanel — Ekstre Detay Widget
tags: [source, widget, flutter, detail-panel]
source: raw/screens/statement-detail-panel.md
date: 2026-04-24
status: verified
---

# StatementDetailPanel

## Amaç
Hub'ın **sağ paneli** — seçili cariye ait ekstre. `StatementArgs` üzerinden `accountStatementProvider`'dan veri çeker, yoksa placeholder gösterir.

## UI Bileşenleri (yukarıdan aşağı)

1. **Empty state** — seçim yoksa `AppEmptyState.noData` prompt
2. **Loading** — `CircularProgressIndicator`
3. **Error** — `AppEmptyState.error` + refresh button
4. **_Header (AppCard)**:
   - Avatar + hesap adı + tip etiketi (renk: customer→info, supplier→orange)
   - `onBack` (mobile push'ta), `onEdit`, `onPdf` butonları
   - Tarih aralığı chip → `showDateRangePicker` (firstDate 2020)
5. **_SummaryGrid** — 4 kart (açılış / toplam borç / toplam alacak / kapanış)
   - Geniş (>600): 4 sütun, dar: 2 sütun
6. **Transactions** başlık + sayaç
7. **_TxRow** listesi — tarih + açıklama + debit/credit + running balance
8. **RefreshIndicator** wrap ile pull-to-refresh

## Edit Akışı

```dart
onEdit → _handleEdit(context, ref, account) →
  customerServiceProvider.getCustomerById / supplierServiceProvider.getSupplierById →
  showModalBottomSheet(isScrollControlled: true) →
    AccountEditForm(initialType, editingId, initialData)
```

Modal bottom sheet — klavye geldiğinde `viewInsets.bottom` ile itilir.

## PDF Export

`StatementPdfService.show(...)` — bu widget'ta çalışır, backend'e değil. Client-side PDF üretimi (gelecek: backend taşımak [[issues/pdf-client-to-backend-migration]] planlı).

## Kritik Kod Noktaları

- [statement_detail_panel.dart:54-60](../../../../widgets/statement_detail_panel.dart) — statement field extraction
- [statement_detail_panel.dart:139-188](../../../../widgets/statement_detail_panel.dart) — `_handleEdit` modal akışı
- [statement_detail_panel.dart:320-373](../../../../widgets/statement_detail_panel.dart) — `_SummaryGrid` responsive cols
- [statement_detail_panel.dart:431-498](../../../../widgets/statement_detail_panel.dart) — `_TxRow` (running balance display)

## Kararlar
- [[decisions/edit-via-modal-not-inline]]
- [[decisions/pdf-client-side-for-now]]

## İlgili
- [[entities/statement-detail-panel]]
- [[entities/account-edit-form]]
- [[entities/accounts-notifiers]]
- [[flows/statement-load-flow]]

## Sources
- `raw/screens/statement-detail-panel.md`
- `project_pos/lib/features/accounts/widgets/statement_detail_panel.dart`
