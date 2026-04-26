---
title: BatchEntryState — toplu ürün girişi Riverpod state
type: concept
source: project_pos/lib/features/inventory/screens/batch_entry/models/batch_entry_models.dart
ingested: 2026-04-25
last-verified: 2026-04-25
status: stub
---

# BatchEntryState

## Tanım

Toplu ürün girişi ekranının üst düzey Riverpod state objesi — header (tedarikçi/lokasyon/fatura) + satır listesi + UI flag'leri tutar.

## Kod Konumu

- `batch_entry_models.dart:473` — `BatchEntryState` data class
- `batch_entry_provider.dart:29` — `BatchEntryNotifier extends StateNotifier<BatchEntryState>`
- Provider: `batchEntryProvider = StateNotifierProvider.autoDispose<...>`

## Alanlar

### Header
- `supplierId`, `supplierName`
- `invoiceNumber`, `deliveryNoteNumber`, `purchaseDate`
- `locationId`, `locationName`, `locationType`
- `categoryId`, `categoryName` (header bazlı toplu kategori)

### Body
- `rows` — `List<BatchEntryRow>`

### UI Flags
- `isSubmitting`
- `headerCollapsed`

## Türetilen Sayaçlar (getters)

`totalItems`, `newItems`, `existingItems`, `savedItems`, `errorItems`, `shortageItems`, `hasAnyShortage`

## Türetilen Toplamlar

`totalCost`, `totalSale`, `totalProfit`

## Validasyon

`isValid` — rows dolu + supplier seçili + location seçili.

## Notifier Davranışı

| Method | Amaç |
|---|---|
| `addByBarcode(barcode)` | Barkod ara, multi-match olursa picker dialog |
| `addFromDocumentItems(items)` | PDF analiz sonucu (`[[entities/document-item-result]]`) → satıra dönüştür |
| `addManualRow()` | Boş yeni satır |
| `updateRow(id, updates)` | Tek satır güncelle |
| `applyVatToAll/applyCategoryToAll/applyBrandToAll/applyPriceToAll` | Toplu güncelleme |
| `validateAll()` | Tüm satırlar için validation |
| `submitAll()` | Backend'e tek batch request → `BatchSaveResult` |

## Related

- [[entities/batch-entry-row]]
- [[concepts/batch-row-status]]
- [[concepts/state-notifier-vs-async]]
- [[syntheses/flow-batch-entry]]
