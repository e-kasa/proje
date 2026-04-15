---
module: pos-product-manager
type: Spring Boot Backend
port: 8001
context-path: /product (gateway prefix)
base-package: com.sedcore
depends-on: [core]
touch-when: [product, stock, sale, purchase, supplier, batch, pdf-analyze, inventory]
last-verified: 2026-04-16
---

# CLAUDE.md — pos-product-manager

Ana iş mantığı servisi. Ürün kataloğu, stok, satış, alım, tedarikçi, raporlar.  
Genel kurallar: kök `CLAUDE.md`.  
Şablonlar: `.claude/runbooks/new-entity.md`, `.claude/runbooks/new-endpoint.md`.  
Multi-tenant: `.claude/reference/multi-tenant.md`. API zarfı: `.claude/reference/api-response.md`.

---

## Paket Yapısı

```
com.sedcore/
├── PosProductManagerApplication
├── common/                          # config, context, filter, enums, exception, util
├── catalog/                         # Category, CategoryAttribute, CompanyCategory
├── product/                         # Product, ProductVariant, Brand, Unit, Barcode, Pricing
├── autoparts/                       # OemNumber, CrossReference, Vehicle, VehicleCompatibility
├── sales/                           # Sale, SaleReturn, SalesReport
├── purchase/                        # Purchase
├── supplier/                        # Supplier, SupplierAccount
├── report/                          # StatsService
└── recommendation/                  # RecommendationService
```

**AOP kritik:** Servis paketi `com.sedcore.{modul}.service.impl` altında olmalı. `com.sedcore.service.*` paketi yok, filter çalışmaz.

---

## Endpoint Standartı

Controller `/api/v1/...` yazar — Flutter `product/api/v1/...` çağırır. Detay: `.claude/reference/url-routing.md`.

```
GET    /api/v1/{resource}           → liste
GET    /api/v1/{resource}/{id}      → tekil
POST   /api/v1/{resource}           → oluştur
PUT    /api/v1/{resource}/{id}      → güncelle
DELETE /api/v1/{resource}/{id}      → soft delete
GET    /api/v1/{resource}/search?q= → arama
POST   /api/v1/{resource}/batch     → toplu
```

Yeni endpoint/entity eklerken runbook kullan.

---

## Batch Ürün Girişi

```
POST /product/api/v1/products/batch
```

**Amaç:** Flutter toplu ürün girişinden tek HTTP ile Purchase + N yeni ürün + N mevcut ürün stok güncellemesi.

### Request Özeti

```java
BatchCreateRequest {
    supplierId, invoiceNumber, deliveryNoteNumber,
    purchaseDate, storeId, warehouseId, notes,
    newProducts:      List<BatchProductItem>    // tempId, product, variants, oemNumbers, crossReferences
    existingProducts: List<BatchExistingItem>   // tempId, variantId, quantity, unitPrice, taxRate
}
```

### Response Özeti

```java
BatchCreateResponse {
    purchaseId, invoiceNumber, successCount, failCount, totalAmount,
    results: List<BatchItemResult>   // tempId, success, productId, variantId, message
}
```

### Servis Davranışı

1. Purchase kaydı (tek Purchase tüm batch için)
2. `newProducts` → her ürün `@Transactional(propagation=REQUIRES_NEW)` ile bağımsız
3. `existingProducts` → `StockMovement(IN)` + `variant.quantity++`
4. `Purchase.totalAmount` güncellenir
5. `tempId → result` map'i döner

Batch ekranı: `project_pos/lib/features/inventory/screens/batch_entry/CLAUDE.md`.

---

## Production-Ready Kurallar (aktif)

### Sektör İzolasyonu

```java
// ProductServiceImpl.createProduct() — sector her zaman firmadan
String companySector = companySettingRepository
    .findFirstByCompanyCodeOrderByCreateTimeDesc(CompanyContext.get())
    .map(CompanySetting::getSectorType)
    .orElse(dto.getProduct().getSector());
product.setSector(companySector);
```

`CompanySettingServiceImpl.updateSettings()` → `sectorType` güncellenmez (kurulumda sabit). Detay: `.claude/reference/sector-strings.md`.

### Purchase → storeId Zorunlu

`purchases.store_id` kolonu var. `PurchaseRequest.storeId` → `Purchase.storeId`. Batch flow'da da `setStoreId()` çağrılır.

### Mağaza Silme (Soft Delete)

```java
StoreService.deleteStore(id, companyCode)  // → isActive=false
```

---

## Exception Yönetimi — KRİTİK

**TOpenException / TOpenMessage KULLANMA** — log'da object reference görünür, debug imkânsız.

```java
// ✅ Proje exception'ları — log'da net mesaj, doğru HTTP status
throw new NotFoundException("Ürün bulunamadı: " + id);           // 404
throw new BusinessException("Stok yetersiz: " + current);        // 400
throw new ConflictException("Bu SKU kayıtlı: " + sku);           // 409

// ❌ Log'da "TOpenException: [com.towpen....TOpenMessage@5bd0d0d5]"
throw new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006));
```

Exception → HTTP tablosu: `.claude/reference/api-response.md`.

---

## Veritabanı Şeması (Özet)

```
products, product_variants, product_variant_attr, brands, units
categories, company_categories, category_attributes
oem_numbers, cross_references, vehicles, vehicle_compatibility
sales, sale_items, sale_returns
purchases, purchase_items
suppliers, supplier_accounts
stock_movements
```

Tüm tablolarda: `company_code`, `created_at`, `updated_at`, `is_deleted`.

---

## data.sql Sorumluluk

**Bu servisin:** `company` (FK güvencesi), `stores`, `warehouses`, `categories`, `company_categories`, `brands`, `units`, `products`, `product_variants`, `stock_movements`.

**EKLEME:** `role_def`, `user_def`, `user_def_access`, `user_role` — security/data.sql'de.

### inventory_view

```sql
-- data.sql ilk 3 satır — sıra önemli
DROP TABLE IF EXISTS inventory_view;   -- Hibernate bazen tablo yapar
DROP VIEW IF EXISTS inventory_view;    -- Önceki view
CREATE VIEW inventory_view AS ...;
```

### store_id Ataması

```sql
-- Kasiyerlerin store_id'si mağazalar oluşturulduktan SONRA
UPDATE user_def SET store_id = 'STORE-01' WHERE user_name = 'kasiyer';
```

`ALTER TABLE ... ADD COLUMN` **EKLEME** — Hibernate schema'yı yönetir.

---

## PDF Fatura Analizi

```
POST /api/v1/document/analyze   (multipart, field: "file")
Flutter URL: product/api/v1/document/analyze
```

### Dosyalar

```
model/DocumentItemResult.java
model/DocumentAnalyzeResponse.java
service/DocumentAnalyzeService.java
service/impl/DocumentAnalyzeServiceImpl.java
controller/DocumentAnalyzeController.java
controller/impl/DocumentAnalyzeControllerImpl.java
```

### Parse Akışı

1. PDFBox → `PDFTextStripper.setSortByPosition(true)` → tüm metin
2. `\r?\n` ile satırlara böl
3. Her satır: `shouldSkipLine()` + `extractLineInfo()` + `matchToProduct()`
4. `DocumentAnalyzeResponse` döner

### Eşleştirme Sırası

```
1. BARCODE (EAN13 13 rakam)   → barcodeRepository.findByBarcodeCode
2. OEM (harf+rakam 4-20)      → oemNumberRepository.findByOemNumberIgnoreCase
3. NAME (ilk 2-3 kelime ≥3c)  → productRepository.searchProducts   ⚠️ belirsiz, kullanıcı onay gerekli
4. NOT_FOUND                  → Flutter'da yeni ürün satırı
```

### Desteklenen / Desteklenmeyen

```
✅ Dijital PDF (metin seçilebilir)
✅ Türkçe format (1.234,56 virgüllü)
✅ Çok sayfalı
❌ Taranmış/görüntü PDF     → Sprint 2: Tesseract OCR
❌ Şifreli/korumalı PDF
❌ Excel/Word               → Sadece PDF
```

### Sprint 1 Kalan Görevler

`.claude/status/sprint.md` → Sprint 1 checklist.

Detay (backend alan listesi, eşleştirme kritik notlar): batch entry CLAUDE.md §14.

---

## Sık Yapılan Hatalar

| Hata | Çözüm |
|------|-------|
| Controller `@RequestHeader("X-Company-Code")` | Token'da var — `CompanyContext.get()` kullan |
| `new TOpenException(...)` fırlatmak | Proje exception'ları (Not/Business/Conflict) |
| Servis paketi `com.sedcore.service.*` | `com.sedcore.{modul}.service.impl` |
| Entity `@Filter` tekrar | Superclass'ta var, sil |
| `companyCode` parametre adı filter'da | `cpCode` |
| data.sql'e kullanıcı INSERT | security/data.sql'e ekle |
| `ALTER TABLE` data.sql'de | Hibernate ddl-auto yönetir |
| Request'te sector override | Backend firmadan override eder |
