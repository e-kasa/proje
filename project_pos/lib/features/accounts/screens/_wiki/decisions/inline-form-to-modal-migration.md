---
title: Inline Form → Modal Migration (2026-04-24)
tags: [decision, ux, crud]
date: 2026-04-24
status: active
---

# Inline Form → Modal Migration

## Karar (2026-04-24)
[[entities/accounts-list-panel]]'deki "Yeni hesap" flow'u inline `AnimatedSize` expand yerine **modal bottom sheet** kullanır. Edit akışı zaten modaldı; CRUD simetrisi sağlandı.

## Neden
- İki flow'un aynı widget'ı (`AccountEditForm`) farklı kapsayıcıda açması — bilişsel yük
- Inline form scroll'u bozuyordu (liste yerini değiştiriyordu)
- Mobile'da klavye inline form'la çakışıyordu (viewInsets modal'da otomatik, inline'da manual)
- Standard pattern: `showModalBottomSheet(isScrollControlled: true)` + `viewInsets.bottom` padding

## Uygulama
`accounts_list_panel.dart`:
- `_showNewForm` state flag kaldırıldı
- `AnimatedSize` wrapper kaldırıldı
- `_NewAccountButton` tek durumlu (toggle yok, sadece `onPressed: _openCreateModal`)
- `_openCreateModal()` → `showModalBottomSheet(AccountEditForm(...))`

## Tuzak
Eski inline flow'u referans alan test/doc varsa güncellenmeli.

## Related
- [[entities/accounts-list-panel]]
- [[entities/account-edit-form]]
- [[decisions/edit-via-modal-not-inline]]
