---
type: raw-pointer
immutable: true
kind: flutter-widget
date: 2026-04-24
---

# Raw Pointer — AccountsListPanel

**Dokunulmaz.**

## Dosya
`project_pos/lib/features/accounts/widgets/accounts_list_panel.dart` (yaklaşık 340 satır)

## Tip
`ConsumerStatefulWidget` — hub'ın sol panelindeki birleşik müşteri+tedarikçi listesi.

## Özellikler
- Filter: tümü / müşteri / tedarikçi / vadesi geçen
- Search (ad, telefon)
- Satır: avatar + isim + tip chip + bakiye (currentBalance)
- Seçim callback: `onSelect(StatementArgs)`
- "Yeni hesap" butonu — modal olarak `AccountEditForm` açar (inline form yok, 2026-04-24 UX kararı)

## Bağımlılıklar
- `accountsListProvider` — liste verisi + filter
- `accountSummaryProvider` — overdueIds kaynağı
- `AccountEditForm` — modal içinde create
