---
title: BatchEntryRow — toplu ürün girişi tablo satırı
type: entity
source: project_pos/lib/features/inventory/screens/batch_entry/models/batch_entry_models.dart
ingested: 2026-04-25
last-verified: 2026-04-25
status: stub
---

# BatchEntryRow

## Tanım

Toplu ürün girişi tablosundaki tek satırın UI state modeli. Yeni ürün veya mevcut ürün eşleşmesi olabilir; footwear için alt varyant satırları (`BatchVariantRow`) tutar.

## Kod Konumu

- `project_pos/lib/features/inventory/screens/batch_entry/models/batch_entry_models.dart:251`
- Hesaplama yardımcısı: `BatchRowCompletion.compute(...)` aynı dosya

## Önemli Alanlar

### Identity & Search
- `id`, `barcode`, `productName`, `oemNumber`

### Classification
- `brandId`/`brandName`, `categoryId`/`categoryName`, `unitId`

### Pricing
- `purchasePrice`, `salePrice`, `vatRate`, `discountRate`
- `vatIncluded` (boolean)

### Quantity & Shortage
- `quantity` — sipariş miktarı
- `invoiceQuantity` — faturada belirtilen
- (hesaplanan) `effectiveQuantity`, `receivedQty`, `resolvedInvoiceQty`, `shortageQty`, `hasShortage`

### State
- `status` — `[[concepts/batch-row-status]]` enum
- `errorMessage`, `description`, `shelfLocation`, `minStockLevel`
- `attributes` (Map), `oemList`, `crossRefList`, `variantRows`

### Existing Match (mevcut ürün eşleşmesi olduğunda)
- `existingProductId`, `existingVariantId`, `existingSku`
- `existingCurrentStock`, `existingSalePrice`, `existingPurchasePrice`, `existingLastPurchasePrice`
- `existingShelfLocation`, `existingBrandName`, `existingOemCodes`
- `existingVariantCount`, `existingVariants`

## Hesaplananlar (getters)

`lineTotal`, `lineCost`, `lineProfit`, `profitMargin`, `isNew`/`isExisting`/`hasError`/`isSaved`

## Kullanım

- Batch entry akışı satır birimi
- Tamamlanma değerlendirmesi `BatchRowCompletion.compute(row)` ile yapılır → `CardReadiness` enum
- Submit akışı `BatchEntryNotifier.submitAll()` `newProducts` + `existingProducts` ayrı listede backend'e gider

## Related

- [[concepts/batch-entry-state]]
- [[concepts/batch-row-status]]
- [[entities/document-item-result]]
- [[syntheses/flow-batch-entry]]
