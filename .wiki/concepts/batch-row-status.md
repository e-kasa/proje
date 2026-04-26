---
title: RowStatus — toplu giriş satır durum makinesi
type: concept
source: project_pos/lib/features/inventory/screens/batch_entry/models/batch_entry_models.dart
ingested: 2026-04-25
last-verified: 2026-04-25
status: stub
---

# RowStatus (Batch Row Status)

## Tanım

Toplu girişte satırın durum makinesi — UI rengi, save akışı ve readiness hesabı bu enum üzerinden ilerler.

## Kod Konumu

- `batch_entry_models.dart:1` — `enum RowStatus`

## Enum Değerleri

```dart
enum RowStatus { newProduct, existing, matched, error, saving, saved }
```

## Yardımcı Enum'lar

```dart
enum SectionStatus { complete, partial, empty }
enum CardReadiness { draft, incomplete, ready, saving, saved, error }
```

`CardReadiness` `BatchRowCompletion.compute(row)` ile satır kartına atanır — UI rengi/badge buradan gelir.

## Geçişler

```
newProduct/existing → saving (submit) → saved
                                      ↘ error (response başına)
matched              → barkod arama eşleşmesi (geçici, kullanıcı confirm)
```

`submitAll()` hata yakalarsa orijinal status'a geri döner — `saving` takılı kalmaz.

## Kullanım

- `BatchEntryRow.status`
- Sayaçlar: `BatchEntryState.newItems`, `savedItems`, `errorItems`
- UI: satır chip rengi/ikonu (`AppColors.success/danger/warning`)

## Related

- [[entities/batch-entry-row]]
- [[concepts/batch-entry-state]]
- [[concepts/app-colors-palette]]
