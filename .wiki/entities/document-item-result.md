---
title: DocumentItemResult — PDF/fatura analiz kalem DTO'su
type: entity
source: pos-product-manager/src/main/java/com/sedcore/product/model/DocumentItemResult.java
ingested: 2026-04-25
last-verified: 2026-04-25
status: stub
---

# DocumentItemResult

## Tanım

PDF/fatura analizi sonucu üretilen tek satır kalem DTO'su. `matchStatus = FOUND/NOT_FOUND` ile kullanıcıya gösterilir; varyant grupları için alt liste tutar.

## Kod Konumu

- `pos-product-manager/src/main/java/com/sedcore/product/model/DocumentItemResult.java:18`
- Üretici: `DocumentAnalyzeServiceImpl` (PDF/OCR analiz pipeline)
- Tüketici: Flutter `batch_entry/.../document_analyze_result_sheet.dart`

## Önemli Alanlar

### Extracted (PDF'den çıkarılan ham veri)
- `rowIndex`, `rawText`
- `extractedName`, `extractedCode`, `extractedQuantity`, `extractedUnitPrice`

### Match (DB ile eşleşme)
- `matchStatus` — FOUND / NOT_FOUND
- `matchedProductId`, `matchedVariantId`, `matchedSku`
- `matchedSalePrice`, `matchedPurchasePrice`, `matchedLastPurchasePrice`
- `matchedShelfLocation`, `matchedBrandName`, `matchedOemCodes`
- `matchedVariantCount`, `matchedVariants` (varyant grup için)
- `matchType` — BARCODE / OEM / NAME
- `matchConfidence` — 1.0 (BARCODE) / 0.9 (OEM) / 0.5 (NAME) / 0.0 (yok)
- `matchCandidates` — NAME match alternatifleri (kullanıcı seçer)

### Quality Flags
- `warningFlags` — `NAME_MATCH_UNCERTAIN`, `PRICE_MISMATCH`, `NO_PRICE`, `DUPLICATE_MERGED`, `VARIANT_GROUP`, `OCR_PROCESSED`

### Variant Group
- `variantGroup` (boolean) + `variants` (list)

## Kullanım

Toplu ürün girişi PDF/OCR akışı:
1. Kullanıcı PDF yükler → `/product/api/v1/document/analyze`
2. Backend OCR + text parse → `List<DocumentItemResult>` döner
3. Flutter `BatchEntryNotifier.addFromDocumentItems(...)` → `[[entities/batch-entry-row]]`'a dönüştürür

## Related

- [[entities/batch-entry-row]]
- [[concepts/batch-entry-state]]
- [[syntheses/flow-batch-entry]]
- [[entities/product-variant]]
