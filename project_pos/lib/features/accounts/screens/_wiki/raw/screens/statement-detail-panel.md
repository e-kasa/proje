---
type: raw-pointer
immutable: true
kind: flutter-widget
date: 2026-04-24
---

# Raw Pointer — StatementDetailPanel

**Dokunulmaz.**

## Dosya
`project_pos/lib/features/accounts/widgets/statement_detail_panel.dart` (499 satır — en büyük widget)

## Tip
`ConsumerWidget` — hub'ın sağ panelindeki cari ekstre görüntüleyici.

## Alt Widget'lar (private)
- `_Header` — başlık, geri butonu, tarih aralığı, PDF + edit butonları
- `_SummaryGrid` — 4 kart (açılış / borç / alacak / kapanış)
- `_StatTile` — özet kart
- `_TxRow` — tek hareket satırı (running balance ile)

## Bağımlılıklar
- `selectedAccountProvider`, `accountStatementProvider`
- `StatementPdfService.show()` — PDF export
- `AccountEditForm` — modal içinde edit
- `customerServiceProvider`, `supplierServiceProvider` — edit için data fetch
