---
title: AccountsListPanel
tags: [entity, widget, flutter, list]
source: project_pos/lib/features/accounts/widgets/accounts_list_panel.dart
date: 2026-04-24
status: verified
---

# AccountsListPanel

## Amaç
[[entities/accounts-hub-screen]]'in sol paneli. Birleşik müşteri+tedarikçi listesi + filter + search + yeni ekle.

## Tip
`ConsumerStatefulWidget`. Props: `selectedId`, `onSelect(StatementArgs)`.

## UI Bölgeleri

1. **Top bar**:
   - Search `TextField` (ad, telefon eşleşmesi)
   - Filter tabs: tümü / müşteri / tedarikçi / vadesi geçen
   - "Yeni hesap" butonu (`_NewAccountButton`)
2. **Liste**:
   - Her satır: avatar (customer/supplier ikon) + isim + tip chip + bakiye
   - Overdue satırında uyarı badge (overdueIds set'ine göre)
   - Seçili satır highlight (`selectedId` match)
3. **Empty states**:
   - Search bulunamadı
   - Filter sonucu boş
   - Liste boş (henüz hiç hesap yok → "Yeni hesap" CTA)

## Data

### Watched
- `accountsListProvider` → merged list + filter state
- `accountSummaryProvider.overdueList` → overdueIds set ("vadesi geçen" filter için)

### Mutations
- Filter tab → `accountsListProvider.notifier.setFilter(...)`
- Search → `accountsListProvider.notifier.setSearch(...)`
- Yeni hesap → modal açılır → success → `accountsListProvider.notifier.load()`

## 2026-04-24 UX Revizyonu

Önceden: "Yeni hesap" butonuna tıklama → `AnimatedSize` ile inline form expand (liste üstünde). Konfigürasyon: `_showNewForm` state flag.

Şimdi: **Modal bottom sheet** — edit akışıyla simetrik. `_openCreateModal()` çağrılır → `showModalBottomSheet(AccountEditForm(...))`.

Sebep: inline form liste scrolling'i bozuyordu, mobile'da klavye çakışıyordu. Edit zaten modaldı → CRUD simetrisi. Bkz. [[decisions/inline-form-to-modal-migration]].

## Tuzaklar

- `overdueIds` summary'den türetilir → summary henüz load olmadıysa vadesi geçen filter yanlış sonuç verir. Çözüm: hub initState'te summary → list sıralı yükler
- Müşteri ve tedarikçi `currentBalance` alanı backend DTO'sunda aynı adla olmalı (2026-04-22 `supplier.balance → currentBalance` rename bu yüzden)

## Sources
- [[sources/screens/2026-04-24-accounts-list-panel]]
- `project_pos/lib/features/accounts/widgets/accounts_list_panel.dart`

## Related
- [[entities/accounts-hub-screen]]
- [[entities/account-edit-form]]
- [[decisions/merged-customer-supplier-list]]
- [[decisions/inline-form-to-modal-migration]]
- [[decisions/overdue-aware-list-ordering]]
- `.claude/wiki/issues/supplier-list-balance-zero` (related historical bug)
