# Toplu Ürün Ekleme — Tam Süreç Akışı

> **Bu dosya kullanıcı yolculuğunu + sistem akışını tek kaynakta anlatır.**
> Teknik DB hiyerarşisi için `docs/batch-entry-hierarchy.md` kullanın.
>
> Son güncelleme: 2026-04-21

---

## 1. Mimari Özeti

```
┌─────────┐   ┌──────────┐   ┌────────────┐   ┌────────┐   ┌─────────┐
│ Flutter │ → │ Backend  │ → │ Python     │ → │ Backend│ → │ DB      │
│ UI      │   │ PDFBox   │   │ /parse-text│   │ Match+ │   │ Multi-  │
│         │   │ veya OCR │   │ (regex)    │   │ Enrich │   │ entity  │
└─────────┘   └──────────┘   └────────────┘   └────────┘   └─────────┘
```

**Servisler:**
- Flutter UI: `project_pos/lib/screens/inventory/batch_entry/`
- Java Backend: `pos-product-manager` (port 8001)
- Python OCR/Parse: `ocr-service` (port 8003)
- API Gateway: `api-manager` (port 8080, `/product/*` proxy)

---

## 2. Kullanıcı Yolculuğu — 6 Aşama

### Aşama 1 — Veri Kaynağı Seç

Kullanıcı batch ekranında 3 moddan biriyle ürün ekler:

| Mod | Akış | Sonuç |
|-----|------|-------|
| 📄 **Belge Yükle** | PDF / Kamera / Galeri · max 10 MB | Otomatik N satır (eşleşme + enrichment) |
| 📷 **Barkod Tara** | EAN13 girişi veya QR scanner | Tek satır (barcode eşleşmesi + enrich) |
| ➕ **Manuel Ekle** | "Yeni Satır" butonu | Boş draft satır |

**Header formu** (ortak):
- Tedarikçi (zorunlu)
- Fatura No (opsiyonel, otomatik üretilir)
- İrsaliye No (opsiyonel)
- Tarih (default: bugün)
- Lokasyon (STORE / WAREHOUSE, zorunlu)

---

### Aşama 2 — PDF Parse + Eşleştirme

PDF modu seçildiğinde akış:

```
PDF yüklendi (Flutter FilePicker)
    ↓ POST /product/api/v1/document/analyze (multipart)
Java DocumentAnalyzeServiceImpl.parsePdf
    ↓
PDFBox → tam metin
    ↓
  < 100 char? ─────► Python OCR (/ocr/extract, EasyOCR)
    ↓ evet                 ↓
    └────→ Python /parse-text ←────┘
                ↓
        invoice_parser.py:
        · Tablo header tespit (Mal/Hizmet, Miktar, Birim Fiyat, KDV, ...)
        · Header + 3 alt satır (multi-line)
        · Footer tespit (Mal Hizmet Toplam, Yalnız, İmza, IBAN ...)
        · Non-product filtre (Tel, VKN, TCKN, ETTN, Email)
        · Her ürün satırı regex parse:
            - Ürün adı
            - Barkod (EAN13) veya OEM
            - Miktar + birim ("140 Adet")
            - KDV oranı (%10)
            - İskonto oranı (İsk. %10)
            - Birim fiyat + total price (heuristic: qty × price ≈ total)
                ↓
    JSON: {items: [...], headerLine, footerLine, skipped, totalLines}
                ↓
Java: ParsedLine listesi → buildResults → matchToProduct
```

#### matchToProduct — 3 seviyeli eşleşme

| Seviye | Güven | Kaynak |
|--------|-------|--------|
| 1. BARCODE | 100% | `barcodeRepository.findByBarcodeCode(ean13)` |
| 2. OEM | 90% | `oemNumberRepository.findByOemNumberIgnoreCase(oem)` |
| 3. İSİM | 50% | `productRepository.searchProducts(keyword)` + ilk 3 aday |

#### enrichFromVariant — Mevcut ürün zenginleştirme

Eşleşme bulunursa variant'tan şu bilgiler Flutter'a gönderilir:

```
matchedCurrentStock     (toplam stok, tüm lokasyonlar)
matchedSalePrice        (aktif VariantPricing.salePrice)
matchedPurchasePrice    (aktif VariantPricing.purchasePrice)
matchedLastPurchasePrice (en son StockMovement PURCHASE_IN.unitPrice)
matchedShelfLocation    (ProductVariant.shelfLocationCode)
matchedBrandName        (Product.brand)
matchedOemCodes         (ilk 3 OEM, kart chip'leri için)
matchedVariantCount     (ürünün TOPLAM variant sayısı)
matchedVariants[]       (TÜM variantların özeti: attributes/stok/fiyat/raf)
```

---

### Aşama 3 — Result Bottom Sheet

PDF analizi tamamlanınca kullanıcıya gösterilen sheet:

```
┌───────────────────────────────────────────┐
│ Belge Analizi: GER2025000030968  [Dosya]  │
│ [3 Kalem] [2 ✓ Mevcut] [1 + Yeni]         │
├───────────────────────────────────────────┤
│ ☑ ✓ Mevcut (Barkod)  GÖMLEK 42 Siyah      │
│   SKU: X-123  ·  140 adet · ₺454,55       │
├───────────────────────────────────────────┤
│ ☑ ⚠ Mevcut (İsim)   AKÜ Bosch              │
│   İsim eşleşmesi · güven %50               │
│   [Alternatif Göster ▼] [Yeni Ürün Olarak]│
├───────────────────────────────────────────┤
│ ☑ + Yeni             FREN BALATA           │
│   Kategori seçilmeli                       │
├───────────────────────────────────────────┤
│ ⚠ Yeni ürünler için kategori seçimi gerekli│
│ [Tümünü Seç] [Temizle]  [3 Kalemi Aktar ▼]│
└───────────────────────────────────────────┘
```

**Etkileşimler:**
- Her satır **checkbox** ile seçilebilir (default: tümü seçili)
- **NAME match satırlarında** → "Alternatif Göster" butonu → ilk 3 aday kart olarak açılır (SKU + stok + fiyat)
- Her NAME match'te → "Yeni Ürün Olarak Kaydet" → o satır locally NOT_FOUND yapılır
- **Varyant grubu** satırlarında → expand ile alt beden/renk listesi
- **OCR banner** → taranmış PDF'se "Bu belge OCR ile okundu, doğrulayın" uyarısı

**Import** butonuna basınca seçilen kalemler `BatchEntryRow` olarak batch listesine eklenir.

---

### Aşama 4 — Batch Draft Listesi

Ana ekranda kartlar durum renkleri ile listelenir:

#### Mevcut ürün kartı (yeşil)
```
✓ Mevcut   GÖMLEK
           [📦 3 varyant] [🏷 Tekstil] [🏭 GESTO] [qr 8690...]
           [🗄 A-12-3]
           Alış ₺454,55 · Satış ₺500 · KDV %10 · 140 adet
```

#### Yeni ürün kartı (turuncu)
```
+ Yeni     GÖMLEK (draft)
           Kategori seçilmeli · [📦 1 varyant] · ⚠ Eksik Alan
           Alış ₺454,55 · Satış ₺454,55 · KDV %10 · 1 adet
```

**Alt bar özeti:**
```
3 Ürün · 147 Adet · Maliyet ₺65.364 · Satış ₺75.500 · Kâr %15.5
```

---

### Aşama 5 — Kart Detay Dialog'u

Karta tıklayınca 600px dialog açılır. Mevcut/yeni ayrımı:

#### 📘 Mevcut ürün dialog'u (read-only + stok güncelle)

```
┌─ Bölüm 1: Ürün Bilgisi ──────────────────┐
│ ✓ Mevcut · GÖMLEK · SKU: X-123           │
│ [🏷 Tekstil] [🏭 GESTO] [qr 8690...]     │
│ [🗄 A-12-3]                               │
│                                           │
│ [📦 3 varyant ▼]  ← tıkla expand         │
│   ● 42 Siyah   10 adet · ₺454 · A-12     │
│   ○ 43 Siyah    5 adet · ₺454 · A-12     │
│   ○ 44 Kırmızı  8 adet · ₺454 · A-13     │
│                                           │
│ [OEM: 123456, 789012, 456789]             │
│ ℹ Stok ve cari güncellenecek              │
└───────────────────────────────────────────┘

┌─ Bölüm 2: Fiyat & Stok ──────────────────┐
│ Alış ₺*   [454,55]    Satış ₺  [500,00]  │
│ Fatura Adet: [140]   Teslim: [140]       │
│ KDV %10 ▼   KDV Dahil [x]   İskonto 0%   │
└───────────────────────────────────────────┘
```

- ● dolu daire = fatura ile eşleşen variant
- ○ boş daire = ürünün diğer variantları (read-only görüntü)
- "Alış Fiyatı" editable — cari hesap için zorunlu
- "Fatura Adet ≠ Teslim Adet" ise shortage tracking

#### 📗 Yeni ürün dialog'u (tamamlama formu)

```
┌─ Bölüm 1: Ürün Bilgileri ────────────────┐
│ Ürün Adı*  [GÖMLEK]                       │
│ Barkod     [8690000123456]                │
│ Kategori*  [Tekstil ▼]                    │
│ Marka      [GESTO ▼]  ← autocomplete      │
│ Birim      [adet ▼]                       │
│ Açıklama   [...]                          │
└───────────────────────────────────────────┘

┌─ Bölüm 2: Varyant - Fiyat & Stok ────────┐
│ 📦 Otomatik varyant  [1]                  │
│   SKU: kayıt sonrası atanır               │
│   [qr 8690...] [🗄 A-12-3] [attr: 2]      │
│   ℹ Birim fiyat, stok, barkod bu          │
│     varyanta kaydedilir                   │
│                                           │
│ Varsayılan Alış ₺* [454,55]               │
│ Varsayılan Satış ₺* [500,00]              │
│ [↓ Alış Uygula] [↓ Satış Uygula] [5 adet]│
│                                           │
│ Toplam Alış ₺ [2272,75]  ← variant'lara   │
│ Toplam Satış ₺ [2500,00]    auto-split!   │
│ ℹ Toplam fiyat tüm variantlara adet       │
│   oranıyla bölüşür                        │
│                                           │
│ Adet 5   KDV %10 ▼   KDV Dahil   İsk 0%  │
│                                           │
│ 💰 Kâr: ₺45,45/br · Toplam ₺227,25 · %9.1│
└───────────────────────────────────────────┘

┌─ Bölüm 3: Sektöre Özel ───────────────────┐
│ autoParts:   OEM · Raf* · Min Stok        │
│ footwear:    _BatchVariantBuilder         │
│              (size × color, N variant)    │
│ technology:  IMEI/Seri · Raf · Min Stok   │
│ general:     Raf · Min Stok               │
└───────────────────────────────────────────┘
```

**Mimari prensip:** Her yeni ürün **en az 1 varyant** ile kaydedilir.
Birim fiyat, stok ve barkod **ürün seviyesinde değil variant seviyesinde** tutulur.

---

### Aşama 6 — Submit (Tümünü Kaydet)

```
Kullanıcı "Tümünü Kaydet" → validateAll
    ↓
Validasyon:
  ✓ Tedarikçi seçili
  ✓ Lokasyon (store/warehouse) seçili
  ✓ Her satır: productName ≠ boş (yeni için)
  ✓ categoryId ≠ boş (yeni için)
  ✓ salePrice > 0
  ✓ quantity > 0
  ✓ Footwear: en az 1 geçerli variant
    ↓
Tek HTTP: POST /product/api/v1/products/batch
    ↓
Backend ProductServiceImpl.batchCreateProducts:
  1. Supplier doğrulama (RuntimeException: "Tedarikçi yok")
  2. Purchase başlığı oluştur (totalAmount=0, status=PENDING)
  3. for (BatchProductItem : newProducts):
       @Transactional(REQUIRES_NEW)
       _createProductWithPurchase(cpr, purchase)
         → Product save
         → for variant: ProductVariant + VariantPricing + Barcode
                      + StockMovement(PURCHASE_IN) + StockLevel.addStock
         → for TÜM variantlar × OEM: OemNumber.save  (2026-04-21 fix)
         → for TÜM variantlar × CrossRef: CrossReference.save
       try-catch → partial success, diğer ürünler devam eder
  4. for (BatchExistingItem : existingProducts):
       variant = variantService.findById(variantId)
       StockMovement (PURCHASE_IN) + StockLevel.addStock
       shortage hesabı: invoiceQty vs quantity farkı
  5. Purchase.totalAmount/invoiceAmount/shortageAmount güncelle
     purchase.setPurchaseStatus (PARTIAL / COMPLETED)
  6. shortage > 0 → supplierClaimService.openClaim(SHORTAGE)
  7. supplierAccountService.applyDebit(supplier, totalAmount)
     → SupplierAccount.currentBalance += totalAmount
     → SupplierAccount.totalDebt += totalAmount
    ↓
Response: {
  purchaseId, invoiceNumber,
  successCount, failCount, totalAmount,
  results: [{tempId, success, productId, variantId, message}]
}
    ↓
Flutter: results[] tempId ile satırlara eşlenir
         → başarılılar RowStatus.saved (yeşil ✓)
         → başarısızlar RowStatus.error (kırmızı + message)
```

---

## 3. Özel Senaryolar

### 3.1 Variant grubu toplam fiyat dağıtımı (YENİ — 2026-04-21)

**Senaryo:** Fatura "SİYAH TSHIRT S/M/L/XL/XXL · 5 adet · Toplam 500 TL"

**Otomatik (PDF akışı):**
```
Python: variantGroup=true, variants=[S,M,L,XL,XXL], totalPrice=500
  ↓
Provider auto-split: 500 / 5 = 100 TL birim
  ↓
Her variant.purchasePrice = 100 TL (otomatik)
```

**Manuel (dialog'da):**
- Dialog'da "Toplam Alış ₺" alanı
- Kullanıcı 600 yazarsa → `_distributeTotalToVariants(600, 'purchase')`
- `600 / sum(variantQty)` → her variant'a yeni birim fiyat
- Varsayılan Alış ₺ alanı da sync

### 3.2 Shortage (eksik teslimat)

```
Fatura: 10 adet × ₺100 = ₺1000
Teslim: 8 adet × ₺100 = ₺800
    ↓
Purchase.invoiceAmount = 1000
Purchase.totalAmount = 800
Purchase.shortageAmount = 200
Purchase.purchaseStatus = PARTIAL
    ↓
SupplierClaim otomatik açılır (ClaimReason.SHORTAGE)
    ↓
SupplierAccount.applyDebit(supplier, 800)  ← teslim tutarı, fatura değil
```

### 3.3 Multi-line header (e-Arşiv fatura)

```
Satır N:   Sıra  Mal Hizmet  Miktar  Birim Fiyat  İskonto  İskonto  KDV  Tutar
Satır N+1: No                                     Oranı    Tutarı   Oranı
Satır N+2:  1   GÖMLEK   140 Adet  454,55 TL              %10    70.000,01 TL
```

Python:
1. Satır N `_is_table_header()` → 3+ keyword eşleşir → header kabul
2. Satır N+1 → `_is_table_header_continuation()` → sayı yok + 1 keyword → header devamı, atla
3. Satır N+2 → regex parse edilir → ürün satırı ✓

### 3.4 NAME match alternatif seçim

```
Fatura satırı: "AKÜ 12V 60AH"
  ↓
searchProducts("akü") → 3 sonuç:
  1. Bosch Akü 12V 60AH (güven 0.5)
  2. Varta Akü 12V 60AH (güven 0.4)
  3. Mutlu Akü 12V 55AH (güven 0.3)
  ↓
matchedProductId = Bosch, matchCandidates = [Varta, Mutlu]
  ↓
Result sheet: "[Alternatif Göster ▼]"
Kullanıcı Varta'yı seçerse → local override, matchedVariantId değişir
```

### 3.5 Taranmış PDF (görüntü tabanlı)

```
PDFBox çıktı < 100 char → dijital metin yok
  ↓
callOcrService(file, table_only=true)
  ↓
Python EasyOCR (Türkçe + İngilizce dil modeli)
  ↓
OCR text → /parse-text (aynı regex akışı)
  ↓
Response.scannedPdf = true
  ↓
Flutter sheet'te OCR uyarı banner'ı
```

---

## 4. Hata Durumları

| Durum | Davranış |
|-------|----------|
| Python `/parse-text` down | Java fallback `parseText()` devreye girer |
| EasyOCR yok + taranmış PDF | 503 "`/ocr/extract` kullanılamaz — EasyOCR kurulmalı" |
| Tek ürün SKU çakışması | O satır `BatchItemResult.success=false`, diğerleri commit |
| Tüm ürünler fail | Outer transaction rollback + error banner |
| Kategori seçilmemiş | Submit engellenır, UI "incomplete" chip |
| Supplier seçilmemiş | Submit engellenir, validation hatası |
| Timeout (30s+) | Flutter "Belge analizi zaman aşımı" toast |
| 10 MB üstü dosya | Pre-check 10 MB + backend 400 response |

---

## 5. Data Akış Katmanları

```
Flutter State (Riverpod)            →  Payload (JSON)            →  Backend (Java)          →  DB
──────────────────────────────────     ──────────────────────────    ──────────────────────     ─────────
BatchEntryState                        BatchCreateRequest            BatchCreateRequest         -
├─ supplierId                          ├─ supplierId                 .supplierId                -
├─ invoiceNumber                       ├─ invoiceNumber              .invoiceNumber             Purchase.invoice_number
├─ locationId+Type                     ├─ locationId+Type            .locationId+Type           Purchase.location_id
├─ purchaseDate                        ├─ purchaseDate               .purchaseDate              Purchase.purchase_date
└─ rows: List<BatchEntryRow>           ├─ newProducts: [...]         .newProducts               Product/Variant/Pricing
                                       └─ existingProducts: [...]    .existingProducts          StockMovement
BatchEntryRow (yeni)                   BatchProductItem
├─ productName                         ├─ product.name               CreateProductRequest       Product.name
├─ categoryId                          ├─ product.categoryId         .product                   Product.category_id
├─ brandName                           ├─ product.brand              .product                   Product.brand
├─ variantRows (footwear)              ├─ variants: [...]            .variants                  ProductVariant × N
│  ├─ size,color,qty,price             │  ├─ sku, name, attributes   ProductVariantRequest      variant_pricing
│  └─ attributesMap                    │  ├─ pricing.*               .pricing                   variant_pricing
├─ oemList                             │  ├─ barcodes[]              BarcodeRequest             barcodes
└─ crossRefList                        │  └─ initialStocks[]         InitialStocksRequest       stock_movements + stock_levels
                                       ├─ oemNumbers[]               (TÜM variantlara bind)     oem_numbers
                                       └─ crossReferences[]          (TÜM variantlara bind)     cross_references

BatchEntryRow (mevcut)                 BatchExistingItem
├─ existingVariantId                   ├─ variantId                  .variantId                 StockMovement.variant_id
├─ quantity                            ├─ quantity                   .quantity                  StockMovement.quantity
├─ invoiceQuantity                     ├─ invoiceQuantity            shortage hesabı            Purchase.shortage_amount
├─ purchasePrice                       ├─ unitPrice                  .unitPrice                 StockMovement.unit_price
└─ vatRate                             └─ taxRate                    .taxRate                   -
```

---

## 6. İlgili Dosyalar (Kod Lokasyonları)

### Flutter
- `lib/screens/inventory/batch_entry/batch_product_screen.dart` — ana ekran + dialog
- `lib/screens/inventory/batch_entry/models/batch_entry_models.dart` — BatchEntryRow, State
- `lib/screens/inventory/batch_entry/providers/batch_entry_provider.dart` — StateNotifier, submitAll
- `lib/features/inventory/services/document_analyze_service.dart` — DTO + /document/analyze client
- `lib/features/inventory/screens/batch_entry/widgets/document_analyze_result_sheet.dart` — result UI

### Backend (Java — `pos-product-manager`)
- `src/main/java/com/sedcore/product/service/impl/ProductServiceImpl.java` — `batchCreateProducts`, `_createProductWithPurchase`
- `src/main/java/com/sedcore/product/service/impl/DocumentAnalyzeServiceImpl.java` — `parsePdf`, `callParseTextService`, `matchToProduct`, `enrichFromVariant`
- `src/main/java/com/sedcore/product/model/BatchCreateRequest.java` — DTO
- `src/main/java/com/sedcore/product/model/BatchProductItem.java` / `BatchExistingItem.java`
- `src/main/java/com/sedcore/product/model/DocumentItemResult.java` — analyze response
- `src/main/java/com/sedcore/product/model/MatchedVariantSummary.java` — variant özet DTO
- `src/main/java/com/sedcore/supplier/service/impl/SupplierAccountServiceImpl.java` — applyDebit

### Python (`ocr-service`)
- `main.py` — FastAPI app + `/parse-text`, `/ocr/extract`, `/health`
- `invoice_parser.py` — `parse_invoice_text`, `_parse_product_line`, tablo filtre
- `ocr_engine.py` — EasyOCR wrapper (opsiyonel)

### i18n
- `security/src/main/resources/data.sql` — bt001-bt194 anahtarları

---

## 7. Sprint Durumu (2026-04-21)

**Tamamlanan:**
- ✅ PDF parse Python'a taşındı (v6b26be5)
- ✅ Mevcut ürün kartında variant özeti (8c560d6)
- ✅ OEM/CrossRef tüm variantlara bindi (4b47f13)
- ✅ SupplierAccount otomatik borç (4b47f13)
- ✅ SKU güvenli üretim (Random.secure)
- ✅ Toplam fiyat → variant orantılı dağıtım (6b26be5)
- ✅ NAME match alternatif adaylar
- ✅ Shortage takibi + SupplierClaim
- ✅ Multi-line header (e-Arşiv)
- ✅ Variant garantili UI (ec43caa)

**Sprint 2 (sonraki):**
- [ ] Primary barcode DB unique constraint
- [ ] VariantPricing.validFrom (pricing history)
- [ ] ProductPrice orphan cleanup (cascade)
- [ ] Optimistic locking retry + backoff (@Version)
- [ ] N+1 query optimization (JOIN FETCH)

**Sprint 3 (mimari):**
- [ ] PostgreSQL RLS double-safety
- [ ] AsyncNotifier migration (Riverpod)
- [ ] `lib/screens/` → `lib/features/` migration
- [ ] WebSocket stok alarm bildirimi

**Sprint 4 (gelişmiş):**
- [ ] LLM fallback (PDFBox+Python fail → Claude API)
- [ ] Offline sync (sqflite + conflict resolution)
- [ ] Variant grup algılama Python'a

---

## 8. Test Senaryoları

```
✓ Barkod tara → mevcut ürün eşleşir → existing satır + enrich
✓ Bilinmeyen barkod → yeni ürün draft açılır
✓ Aynı barkod iki kez → quantity +1
✓ Kategori seçilmemiş yeni ürün → SectionA incomplete → submit engellenir
✓ salePrice=0 → incomplete
✓ Mevcut ürün purchasePrice=0 → cari için zorunlu
✓ Footwear variantRows boş → submit engellenir
✓ Footwear ≥1 valid variant → submit OK
✓ PDF yükle → multi-line header düzgün parse
✓ PDF yükle → "Mal Hizmet Toplam" footer ürün olarak sayılmaz
✓ PDF yükle → KDV %10 fiyat olarak algılanmaz
✓ NAME match → "Alternatif Göster" → aday seçilir, matched değişir
✓ NAME match → "Yeni Ürün Olarak" → local NOT_FOUND
✓ variantGroup totalPrice → otomatik auto-split
✓ Toplam Alış ₺ UI'da girilince → her variant anında update
✓ Batch submit → 5/5 başarılı → Purchase oluşur + stok artar + cari borç
✓ Batch submit → 1 fail, 4 ok → partial success, Purchase ortak
✓ Taranmış PDF + EasyOCR kurulu → OCR çalışır, banner gösterilir
✓ Taranmış PDF + EasyOCR yok → 503 hata mesajı
```

---

## 9. İlgili Dokümanlar

- `docs/batch-entry-hierarchy.md` — Entity oluşum hiyerarşisi
- `ocr-service/README.md` — Python servis kurulum + API
- `project_pos/lib/screens/inventory/batch_entry/CLAUDE.md` — Flutter modül kuralları
- `pos-product-manager/CLAUDE.md` §6a — Backend batch endpoint detayı
- Kök `CLAUDE.md` §5 — Domain Özeti (entity ilişkileri)
