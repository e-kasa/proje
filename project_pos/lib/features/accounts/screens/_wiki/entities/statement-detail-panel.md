---
title: StatementDetailPanel
tags: [entity, widget, flutter, detail-panel]
source: project_pos/lib/features/accounts/widgets/statement_detail_panel.dart
date: 2026-04-24
status: verified
---

# StatementDetailPanel

## Amaç
[[entities/accounts-hub-screen]]'in sağ paneli. Seçili cariye ait ekstreyi render eder — header (avatar + hesap bilgisi + butonlar) + 4 özet kart + hareket listesi.

## Tip
`ConsumerWidget`. Tek prop: `showBackButton: bool` — dar ekran push akışında geri butonu için.

## Watched Providers
- `selectedAccountProvider` → seçim varsa renderla, yoksa empty state
- `accountStatementProvider` → `isLoading` / `error` / `statement` (Map)

## Statement Field Extraction

```dart
final opening = (s['openingBalance'] ?? 0).toDouble();
final closing = (s['closingBalance'] ?? 0).toDouble();
final debit = (s['totalDebit'] ?? 0).toDouble();
final credit = (s['totalCredit'] ?? 0).toDouble();
final transactions = List<Map<String, dynamic>>.from(s['transactions'] ?? []);
```

Type-unsafe Map access — client-server alan sözleşmesine bağlı (bkz. [[concepts/untyped-map-api]]).

## Alt Bileşenler (private)

- **_Header** → avatar + hesap adı + customer/supplier badge + tarih chip + edit/PDF butonları
- **_SummaryGrid** → 4 kart responsive (<600px 2 sütun, ≥600 4 sütun)
- **_StatTile** → tek kart (icon + value + label)
- **_TxRow** → tarih + description + debit/credit + running balance

## Edit Akışı

`_handleEdit(context, ref, account)`:
1. `customerServiceProvider.getCustomerById(id)` veya `supplierServiceProvider.getSupplierById(id)` — initialData için
2. `showModalBottomSheet` (isScrollControlled: true) → `AccountEditForm(initialType, editingId, initialData)`
3. `onSuccess` → modal close

## PDF Akışı

`StatementPdfService.show(...)` çağrısı — client-side PDF üretimi. Backend'e taşımak gelecek sprint planlı (bkz. üst wiki `syntheses/accounts-hub-production-readiness` P2.3).

## Tuzaklar

- `statement` Map alanları silent null (örn. `'openingBalance'` yazımı değişirse 0 gösterir)
- `transactions` array `s['transactions'] ?? []` — backend boş veya yok → empty list (OK)
- Refresh → provider load → liste kayar; kullanıcı scroll pozisyonunu kaybeder

## Sources
- [[sources/screens/2026-04-24-statement-detail-panel]]
- `project_pos/lib/features/accounts/widgets/statement_detail_panel.dart`

## Related
- [[entities/accounts-hub-screen]]
- [[entities/account-edit-form]]
- [[entities/accounts-notifiers]]
- [[decisions/edit-via-modal-not-inline]]
- [[decisions/pdf-client-side-for-now]]
