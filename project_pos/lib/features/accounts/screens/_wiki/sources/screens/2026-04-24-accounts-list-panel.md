---
title: AccountsListPanel — Birleşik Müşteri+Tedarikçi Listesi
tags: [source, widget, flutter, list-panel]
source: raw/screens/accounts-list-panel.md
date: 2026-04-24
status: verified
---

# AccountsListPanel

## Amaç
Hub'ın **sol paneli** — müşteri ve tedarikçileri tek birleşik listede gösterir. Filter + search + yeni ekle + seçim.

## Props

| Prop | Tip | Anlam |
|---|---|---|
| `selectedId` | `String?` | Şu an seçili olan hesap ID (highlight) |
| `onSelect` | `void Function(StatementArgs)` | Satır tıklandığında çağrılır |

## UI

1. Üst bar: search input + filter tabs (tümü / müşteri / tedarikçi / vadesi geçen) + "yeni hesap" butonu
2. Liste: her satırda avatar (customer=person, supplier=business) + isim + tip chip + bakiye
3. Overdue satırlarda uyarı badge (overdueIds summaryProvider'dan gelir)
4. Empty state: arama/filter sonucu boşsa `AppEmptyState.noData`

## Data Kaynakları
- `accountsListProvider` — merged list, filter uygulanmış hali
- `accountSummaryProvider.overdueList` → overdueIds set — "vadesi geçen" filter için

## Yeni Hesap Butonu (2026-04-24 UX Revizyonu)
Önceden: inline `AnimatedSize` expand/collapse form. Şimdi: **modal** — `showModalBottomSheet` ile `AccountEditForm` açar. Edit akışı zaten modaldı; CRUD simetrisi sağlandı.

Bkz. [[decisions/inline-form-to-modal-migration]].

## Kararlar
- [[decisions/merged-customer-supplier-list]]
- [[decisions/inline-form-to-modal-migration]]
- [[decisions/overdue-aware-list-ordering]]

## İlgili
- [[entities/accounts-list-panel]]
- [[entities/account-edit-form]]
- [[entities/accounts-list-provider]]

## Sources
- `raw/screens/accounts-list-panel.md`
- `project_pos/lib/features/accounts/widgets/accounts_list_panel.dart`
- Konuşma bağlamı 2026-04-24 (inline → modal UX)
