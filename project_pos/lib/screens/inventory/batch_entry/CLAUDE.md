# CLAUDE.md — Toplu Ürün Girişi (`batch_entry/`)

Bu dosya **yalnızca bu klasör** için geçerlidir.  
Genel proje kuralları için kök `CLAUDE.md`'e bak.

---

## 1. SAYFANIN AMACI

Kasiyerin veya depo personelinin tedarikçiden gelen **fatura/irsaliye bazında** toplu ürün girişi yapmasını sağlar.

Üç giriş modu desteklenir:

```
1. Barkod/OEM tarama    → Sistemde var  → RowStatus.existing  (stok + cari)
2. Manuel satır ekle    → Sistemde yok  → RowStatus.newProduct (ürün oluştur)
3. PDF / Fatura yükle   → TODO — henüz implement edilmedi
```

`submitAll()` tüm satırları **tek HTTP isteğiyle** gönderir:  
`POST /product/api/v1/products/batch` → `BatchCreateRequest` → `BatchCreateResponse`

---

## 2. DOSYA YAPISI

```
batch_entry/
├── CLAUDE.md
├── batch_product_screen.dart          ← Ana ekran + tüm internal widget'lar
├── models/
│   └── batch_entry_models.dart        ← Model sınıfları
├── providers/
│   └── batch_entry_provider.dart      ← BatchEntryNotifier (StateNotifier)
└── widgets/
    ├── batch_header_form.dart         ← Tedarikçi / fatura / depo / mağaza / tarih
    ├── batch_summary_bar.dart         ← Alt özet çubuğu
    ├── barcode_search_input.dart      ← Barkod/OEM arama
    ├── product_entry_table.dart       ← Desktop tablo (⚠️ henüz import edilmiyor)
    └── quick_product_dialog.dart      ← OEM / CrossRef / Raf detay dialog'u
```

---

## 3. VERİ AKIŞI

```
Giriş
  ├── Barkod tarama      → addByBarcode()  → existing / newProduct
  ├── Manuel ekle        → addManualRow()  → newProduct
  └── PDF (TODO)

State: BatchEntryState
  ├── header: supplierId, invoiceNumber, storeId, warehouseId, purchaseDate
  └── rows: List<BatchEntryRow>

submitAll()
  └── ProductService.batchCreate({
        supplierId, invoiceNumber, purchaseDate, storeId, warehouseId,
        newProducts:      [ { tempId, product{}, variants[], oemNumbers[], crossReferences[] } ]
        existingProducts: [ { tempId, variantId, quantity, unitPrice } ]
      })
      → BatchCreateResponse { purchaseId, results: [{tempId, success, productId, message}] }
      → results tempId üzerinden satırlara eşlenir → RowStatus.saved / RowStatus.error
```

---

## 4. MODEL SINIFLAR — `batch_entry_models.dart`

### 4.1 Enum'lar

```dart
enum RowStatus     { newProduct, existing, matched, error, saving, saved }
enum SectionStatus { complete, partial, empty }
enum CardReadiness { draft, incomplete, ready, saving, saved, error }
```

### 4.2 BatchVariantRow — Footwear çoklu varyant satırı

```dart
class BatchVariantRow {
  final String id;
  String size;        // Numara / Beden  → backend: attributes['Numara']
  String color;       // Renk            → backend: attributes['Renk']
  String barcode;
  int quantity;
  double? purchasePrice; // null → BatchEntryRow.purchasePrice'tan miras
  double? salePrice;     // null → BatchEntryRow.salePrice'tan miras

  bool get isValid => size.trim().isNotEmpty && quantity > 0;
}
```

### 4.3 BatchEntryRow — Tam alan listesi

```dart
String id                              // otomatik UUID
RowStatus status

// Temel
String barcode
String productName                     // zorunlu (yeni)
String? categoryId                     // UUID — dropdown'dan, text girmek YASAK
String? categoryName                   // görüntüleme
String? brandName                      // free text
String? unitId                         // 'adet' | 'kg' | 'lt' | ...
double purchasePrice                   // mevcut ürün: cari için ZORUNLU
double salePrice                       // ZORUNLU
double vatRate                         // 0|1|8|10|18|20, default 20.0
bool vatIncluded                       // default false
int quantity                           // ZORUNLU min:1
String? description

// Sektöre özgü
String? shelfLocation                  // parçacı: ZORUNLU
int minStockLevel                      // default 10
String? oemNumber                      // tekil OEM (UI giriş alanı)
List<Map<String,String>> oemList       // [{oemNumber, manufacturer}]
List<Map<String,String>> crossRefList  // [{crossRefNumber, crossRefBrand}]
Map<String,String> attributes          // sektör key-value

// Footwear çoklu varyant
List<BatchVariantRow> variantRows      // footwear → dolu, diğerleri → []

// Mevcut ürün referansı
String? existingProductId
String? existingVariantId
String? existingVariantSku

String? errorMessage
```

### 4.4 BatchRowCompletion

```dart
BatchRowCompletion.compute(row, {
  isExisting, brandRequired, oemRequired, shelfRequired,
  showOem, showShelf,
  showVariantTable,   // footwear → true (cfg.fields.showVariantSize)
})
```

| Section | Kontrol |
|---------|---------|
| A (Ürün Bilgileri) | existing→complete / yeni: productName + categoryId + (brandRequired→brandName) |
| B (Fiyat & Stok) | salePrice>0 + quantity>0; existing→ayrıca purchasePrice>0 |
| C (Detaylar) | showVariantTable→variantRows.any(isValid); diğer→oemRequired/shelfRequired |

---

## 5. SEKTÖRE GÖRE KART ALANLARI

### Her sektörde ortak
Ürün adı · Barkod · Kategori (UUID zorunlu) · Marka · Birim · Alış/Satış/KDV · Adet

### autoParts
```
Section 3: OEM listesi + CrossRef listesi + Raf kodu (ZORUNLU) + Min. Stok
Backend: oemNumbers[] + crossReferences[] → variant[0]'a bağlanır (single-variant tasarımı)
```

### general
```
Section 3: Depo konumu (opsiyonel) + Min. Stok
```

### technology
```
Section 3: IMEI / Seri No (oemNumber → metadata['imei']) + Raf + Min. Stok
NOT: Backend'de SerialNumber entity yok → IMEI metadata map'e kaydedilir
```

### footwear
```
Section 3: _FootwearVariantTable
  Kolonlar: Numara | Renk | Adet | Barkod | Alış ₺ | Satış ₺ | ×
  Her satır → ayrı backend variant (ayrı SKU, ayrı stok)
  Fiyat boş → kart seviyesinden miras
  isValid: size.isNotEmpty && quantity > 0
_BatchAttributesSection footwear'da GİZLİ
```

---

## 6. PAYLOAD STANDARDI

### 6.1 Sektör string

```dart
'sector': cfg.type.apiValue   // 'AUTO_PARTS' | 'GENERAL' | 'TECHNOLOGY' | 'FOOTWEAR'
// ❌ 'parcaci' / 'giyim' / 'genel' — ESKİ wizard formatı, artık kullanılmıyor
// ✅ Wizard da artık sectorType.apiValue kullanıyor (düzeltildi)
```

### 6.2 Batch endpoint yapısı

```dart
// POST /product/api/v1/products/batch
{
  'supplierId':          state.supplierId,
  'invoiceNumber':       '...',
  'purchaseDate':        'yyyy-MM-dd',
  'storeId':             state.storeId,
  'warehouseId':         state.warehouseId,
  'deliveryNoteNumber':  state.deliveryNoteNumber,  // opsiyonel

  'newProducts': [
    {
      'tempId': row.id,                             // sonuç eşlemesi için
      'product': {
        'name': row.productName,
        'sku':  _generateSku(),
        'categoryId': row.categoryId,               // UUID zorunlu
        'brand': row.brandName ?? '',
        'unit':  row.unitId ?? 'adet',
        'sector': cfg.type.apiValue,
        'metadata': _buildMetadata(row),
      },
      'variants': [                                 // footwear → N variant, diğer → 1
        {
          'sku': _generateSku(),
          'name': '...',
          'shelfLocationCode': row.shelfLocation,
          'attributes': { 'Numara': vr.size, 'Renk': vr.color },  // footwear
          'pricing': {
            'purchasePrice': ..., 'salePrice': ...,
            'vatRate': row.vatRate, 'vatIncluded': row.vatIncluded,
            'taxExempt': false,
          },
          'initialStocks': [{'storeId': ..., 'warehouseId': ..., 'quantity': ...}],
          'barcodes': [{'code': ..., 'type': 'EAN13', 'isPrimary': true}],
        }
      ],
      'oemNumbers':      [ {'oemNumber', 'manufacturer', 'isPrimary'} ],  // autoParts
      'crossReferences': [ {'crossRefNumber', 'crossRefBrand'} ],         // autoParts
    }
  ],

  'existingProducts': [
    {
      'tempId':    row.id,
      'variantId': row.existingVariantId,
      'quantity':  row.quantity,
      'unitPrice': row.purchasePrice,
      'taxRate':   row.vatRate,
    }
  ],
}
```

### 6.3 BatchCreateResponse

```dart
{
  'purchaseId':    '...',
  'invoiceNumber': '...',
  'successCount':  5,
  'failCount':     1,
  'totalAmount':   1250.00,
  'results': [
    { 'tempId': row.id, 'success': true,  'productId': '...', 'variantId': '...' },
    { 'tempId': row.id, 'success': false, 'message': 'Hata mesajı' },
  ]
}
```

---

## 7. KART TASARIM SİSTEMİ

### 7.1 Collapsed kart (tıklanabilir)

```
[StatusBar] [Numara] [_ReadinessBadge] Ürün adı         [_WizardStepDots] [edit icon]
                                       meta chips (barkod, kategori, marka, N varyant)
                                       fiyat satırı + adet kontrolü
```

Karta tıklanınca **popup dialog** açılır (`showDialog` → `_BatchRowEditDialog`).  
İnline expand **yok**.

### 7.2 Dialog — `_BatchRowEditDialog extends ConsumerStatefulWidget`

```
Header:   [accent icon] [ürün adı] [_ReadinessBadge] [_WizardStepDots] [×]
Body:     SingleChildScrollView
  Section 1 — Ürün Bilgileri   (existing → read-only ExistingProductInfoCard)
  Section 2 — Fiyat & Stok
  Section 3 — Detaylar / Footwear varyant tablosu
  Section 4 — Attributes (footwear'da GİZLİ)
Footer:   [Sil] [Kapat]
```

Controller'lar `initState`'te initialize edilir. `build()` başında `_syncControllers(row)` çağrılır.

### 7.3 Internal widget'lar

| Widget | Açıklama |
|--------|---------|
| `_ReadinessBadge` | CardReadiness → renkli pill |
| `_WizardStepDots` | 3 daire: complete=yeşil / partial=amber / empty=gri |
| `_WizardSectionHeader` | Adım no + başlık + tamamlanma chip'i |
| `_ExistingProductInfoCard` | Mevcut ürün read-only bilgi kartı |
| `_CategoryDropdown` | `batchCategoriesProvider` → UUID dropdown |
| `_UnitDropdown` | Birim seçimi (adet/kg/lt...) |
| `_FootwearVariantTable` | Inline varyant tablosu |
| `_VariantTableRow` | Tek varyant satırı |
| `_VCell` | Tablo hücresi TextField |
| `_MetaChip` | Collapsed kart etiketleri |
| `_QuantityControl` | +/− adet kontrolü |

### 7.4 Durum renkleri

```
CardReadiness.draft      → AppColors.textMuted
CardReadiness.incomplete → AppColors.warning
CardReadiness.ready      → AppColors.success
CardReadiness.saving     → AppColors.warning (animasyonlu)
CardReadiness.saved      → AppColors.success
CardReadiness.error      → AppColors.danger
```

---

## 8. MEVCUT ÜRÜN AKIŞI

```dart
// addByBarcode() → RowStatus.existing
BatchEntryRow(
  productName:       p['name'],
  categoryId:        p['categoryId'],
  categoryName:      p['categoryName'],
  purchasePrice:     firstVariant['purchasePrice'],   // ← variants[0]'dan alınır
  salePrice:         p['sellingPrice'] ?? p['basePrice'] ?? 0,
  vatRate:           p['taxRate'] ?? 20.0,
  existingVariantId: p['variantId'],
)

// submitAll() → BatchExistingItem olarak gönderilir
// Backend: StockMovement(PURCHASE_IN) + SupplierAccount cari borç kaydı
```

---

## 9. BİLİNEN HATALAR

### P1 — Kritik (Veri bütünlüğü)

- [ ] **Mevcut ürün `purchasePrice` = 0** — `_mapProduct` içinde `firstVariant['purchasePrice']`  
  bakıyor ama API response yapısına göre key farklı olabilir → test edilmeli.
- [ ] **PDF aktarımında `categoryId` boş** — Yeni ürün satırları kategori olmadan oluşur → batch  
  submit'te "Kategori zorunlu" hatası alınır. Kategori seçimi mandatory.
- [ ] **Stok concurrent update** — `ProductVariant`'ta `@Version` alanı yok → 2 kasiyerin  
  aynı ürünü aynı anda satması → lost update. Optimistic locking eklenmeli.

### P2 — UX sorunları

- [ ] **`TextEditingController` stale** — `applyBrandToAll` vb. sonrası `_syncControllers`  
  build'de çağrılıyor ama odak sorunları olabilir → test edilmeli.
- [ ] **KDV dropdown** — Section 2'de `vatRate` dropdown mevcut, ama `taxExempt` /  
  `specialTaxRate` batch modelde yok (wizard'da var).

### P3 — İleride

- [ ] **`ProductEntryTable`** — Desktop modda import edilmiyor.
- [ ] **OEM ile arama** — `addByBarcode` sadece barkod/isim, OEM arama yok.
- [ ] **`categoryName` mevcut ürünlerde** — API response'a göre değişebilir.

---

## 10. GELİŞTİRME ÖNCELİK SIRASI

```
✅ TAMAMLANDI:
  - CategoryId dropdown (_CategoryDropdown widget)
  - oemNumbers + crossReferences payload'a eklendi
  - Footwear multi-variant (variantRows → N variant)
  - submitAll → tek batch çağrısı (POST /products/batch)
  - Wizard sector string (parcaci/giyim → AUTO_PARTS/FOOTWEAR)
  - getMyCategoryList key normalizasyonu
  - minStockLevel backend DTO'ya eklendi
  - metadata technology fix (imei)
  - _buildOemList oemNumber fallback

🔴 SPRINT 1 — PDF FATURA ANALİZİ (DEVAM EDİYOR — TAMAMLANMADI):
  Mevcut: Temel altyapı (PDFBox, Flutter servis, result sheet, upload butonu)
  Eksik:
    [ ] Backend: KDV oranı extract (fatura'dan %18, %8 gibi)
    [ ] Backend: Birim extract ("ADET", "KG", "MT" vb. → DocumentItemResult.unit)
    [ ] Backend: DocumentItemResult modeline unit + vatRate + vatIncluded alanı ekle
    [ ] Backend: Fatura başlık bilgisi (fatura no, tarih) — opsiyonel
    [ ] Flutter: addFromDocumentItems() → KDV, birim aktarımı
    [ ] Flutter: Loading spinner (_uploadDocument sırasında dialog)
    [ ] Flutter: İsim eşleşmesi (NAME match) için kullanıcı onay UI
    [ ] Flutter: Yükleme hatası detaylı mesaj (ağ hatası vs. geçersiz PDF)
    [ ] Test: Gerçek fatura PDF'i ile uçtan uca test

  Sprint 2: UX iyileştirmeleri
    - taxExempt / specialTaxRate batch modele ekle
    - ProductEntryTable desktop'ta aktifleştir
    - Mevcut ürün purchasePrice edge case testi
    - Optimistic locking (@Version) → stok concurrent update fix
    - Async PDF analiz (polling) — büyük dosyalar için
    - Tesseract OCR fallback (taranmış PDF desteği)

  Sprint 3: Mimari iyileştirme
    - lib/screens/ → lib/features/ migration (batch_entry + wizard)
    - AsyncNotifier geçişi (StateNotifier'dan)
    - freezed paketi (copyWith boilerplate azalt)
    - Repository Layer ekle (Services → Repo → API)

  Sprint 4: Gelişmiş özellikler
    - WebSocket stok alarm bildirimi (SSE fallback)
    - PostgreSQL RLS + Hibernate @Filter hibrit (double-safety)
    - LLM fallback (PDF parse başarısız → Claude/GPT-4o)
    - Offline sync stratejisi (sqflite + conflict resolution)
```

---

## 11. i18n ANAHTARLARI (data.sql — `bnd-bt` prefix)

| ID | Key | TR | EN |
|----|-----|----|----|
| bt070 | `batch.status_draft` | Taslak | Draft |
| bt071 | `batch.status_incomplete` | Eksik Alan | Incomplete |
| bt072 | `batch.status_ready` | Hazır | Ready |
| bt073 | `batch.status_saved` | Kaydedildi | Saved |
| bt074 | `batch.status_saving` | Kaydediliyor... | Saving... |
| bt075 | `batch.status_error` | Hata | Error |
| bt076 | `batch.section_complete` | Tamamlandı | Complete |
| bt077 | `batch.section_partial` | Kısmen | Partial |
| bt078 | `batch.section_required` | Zorunlu | Required |
| bt079 | `batch.section_optional` | Opsiyonel | Optional |
| bt080 | `batch.price_and_stock` | Fiyat & Stok | Price & Stock |
| bt081 | `batch.existing_stock_note` | Mevcut ürün: stok ve cari hesap güncellenecek | Existing product: stock and supplier account will be updated |
| bt082 | `batch.ready` | Hazır | Ready |
| bt083 | `batch.details` | Detaylar | Details |
| bt084 | `batch.product_info` | Ürün Bilgileri | Product Info |
| bt085 | `batch.variants` | Varyantlar | Variants |
| bt086 | `batch.upload_document` | Fatura / İrsaliye Yükle | Upload Invoice / Bill |
| bt087 | `batch.document_uploading` | Belge analiz ediliyor... | Analyzing document... |
| bt088 | `batch.document_no_items` | Belgeden ürün kalemi çıkarılamadı | No product lines extracted from document |
| bt089 | `batch.document_items_imported` | kalem aktarıldı | items imported |
| bt090 | `batch.document_analyze_error` | Belge analizi başarısız oldu | Document analysis failed |

---

## 12. BAĞIMLILIKLAR

```dart
// batch_entry_provider.dart — doğrudan kullanılan
productServiceProvider          // batchCreate() + addByBarcode()
oemServiceProvider              // (henüz aktif kullanılmıyor)
sectorConfigProvider            // SectorConfig (type, fields, labels)
companyCategoryServiceProvider  // batchCategoriesProvider için
documentAnalyzeServiceProvider  // PDF fatura analizi (lib/services/service_locator.dart)

// batch_product_screen.dart — dialog ve kart içinde
batchEntryProvider         // StateNotifierProvider.autoDispose
batchCategoriesProvider    // FutureProvider.autoDispose → _CategoryDropdown
i18nOf(ref)               // t('key') — tüm metin zorunlu
```

---

## 13. TEST SENARYOLARI

```
✓ Barkod tarama → existing satır: purchasePrice/salePrice/vatRate dolar
✓ Bilinmeyen barkod → yeni satır, boş form açılır
✓ Aynı barkod iki kez → quantity +1 (addByBarcode duplicate logic)
✓ Kategori seçilmeden → SectionA incomplete, kayıt engellenir
✓ salePrice=0 → CardReadiness.incomplete
✓ Mevcut ürün purchasePrice=0 → CardReadiness.incomplete
✓ Footwear: variantRows boş → SectionC empty
✓ Footwear: ≥1 valid variant → SectionC complete
✓ submitAll: tedarikçi boş → validateAll() hata döner
✓ submitAll: depo/mağaza boş → validateAll() hata döner
✓ Kısmi başarı: results[] içinde success:false olan satır → RowStatus.error
✓ Tüm başarılı → BatchSaveResult.errors=0, purchaseId dolu
✓ Footwear: 3 variantRow → backend'e 3 ayrı variant gider
✓ autoParts: oemList → newProducts[].oemNumbers[] olarak gider
```

---

## 14. PDF FATURA ANALİZİ — DETAY

### 14.1 Dosya Lokasyonları

```
Backend:
  pos-product-manager/
  ├── model/DocumentItemResult.java        ← Tek satır sonuç DTO
  ├── model/DocumentAnalyzeResponse.java   ← Tüm belge sonuç DTO
  ├── service/DocumentAnalyzeService.java  ← Interface
  ├── service/impl/DocumentAnalyzeServiceImpl.java  ← PDFBox parse + match
  ├── controller/DocumentAnalyzeController.java
  └── controller/impl/DocumentAnalyzeControllerImpl.java

Flutter:
  features/inventory/services/document_analyze_service.dart   ← API client + model
  features/inventory/screens/batch_entry/widgets/
    └── document_analyze_result_sheet.dart                     ← Sonuç bottom sheet
  screens/inventory/batch_entry/
    ├── batch_product_screen.dart  (_uploadDocument metodu)
    └── providers/batch_entry_provider.dart  (addFromDocumentItems)
```

### 14.2 Backend: Fatura Alanları — Ne Okunuyor, Nasıl

Standart Türkçe fatura formatı:
```
Sıra | Ürün Kodu    | Açıklama              | Miktar | Birim | Birim Fiyat | KDV % | Toplam
  1  | 8690000123456 | MOTOR YAĞI 5W40 1 LT | 10     | ADET  | 125,50      | 18    | 1.255,00
  2  | F123456        | HAVA FİLTRESİ SIF    | 5      | ADET  |  85,00      | 8     |   425,00
```

**Şu an okunan alanlar:**
```
extractedCode     → EAN13 (13 rakam) veya OEM (harf+rakam karışımı 4-20 karakter)
extractedName     → kod ve sayılar temizlendikten sonra kalan metin
extractedQuantity → 1-9999 arası tam sayı
extractedUnitPrice → küçük pozitif ondalıklı sayı
```

**Regex detayları (DocumentAnalyzeServiceImpl.java):**
```java
// EAN13: tam 13 rakam
BARCODE_PATTERN = Pattern.compile("\\b(\\d{13})\\b");

// OEM: harf+rakam, 4-20 karakter, boşluk/tire/nokta içerebilir
OEM_PATTERN = Pattern.compile("\\b([A-Z0-9][A-Z0-9 .\\-]{3,18}[A-Z0-9])\\b");

// Sayılar: Türkçe format 1.234,56 → "1234.56" normalize edilir
// binlik nokta kaldırılır: (\\d)\\.(\\d{3}) → $1$2
// virgül → nokta: "," → "."
```

**Atlanan satırlar (shouldSkipLine):**
```java
SKIP_PREFIXES = ["sıra", "satır", "miktar", "birim", "adet", "toplam",
                  "genel", "kdv", "vergi", "iban", "banka", "sayfa",
                  "page", "tarih", "fatura", "irsaliye", "alıcı",
                  "satıcı", "müşteri", "adres", "telefon", "e-posta"]
// + sadece rakam/özel karakter içeren satırlar
// + 5 karakterden kısa satırlar
```

**ŞU AN EKSİK — OKUNMAYAN ALANLAR:**
```
❌ vatRate (KDV oranı)  → DocumentItemResult'ta alan yok, Flutter'da sabit 20.0
❌ unit (birim)         → "ADET","KG","MT" var ama temizleniyor, extract edilmiyor
❌ vatIncluded          → Fiyat KDV dahil mi? bilinmiyor
❌ totalPrice           → Satır toplamı (miktar × fiyat)
❌ invoiceNo            → Fatura numarası (belge başlığı)
❌ invoiceDate          → Fatura tarihi
❌ supplierName         → Tedarikçi adı
❌ rowNumber            → Belgedeki sıra numarası (1, 2, 3...)
❌ description          → Ürün açıklaması (uzun satır)
```

### 14.3 Ürün Eşleştirme Sırası

```
1. EAN13 Barkod → barcodeRepository.findByBarcodeCode(code)
   → Barcode.variant (ProductVariant object) → matchStatus: FOUND, matchType: BARCODE

2. OEM Numarası → oemNumberRepository.findByOemNumberIgnoreCase(code)
   → OemNumber.variant (ProductVariant object) → matchStatus: FOUND, matchType: OEM

3. İsim Arama → productRepository.searchProducts(keyword)
   → İlk 2-3 anlamlı kelime (≥3 karakter) → matchStatus: FOUND, matchType: NAME
   ⚠️ UYARI: İsim eşleşmesi yanlış ürün bulabilir → kullanıcı onayı gerekli

4. Bulunamadı → matchStatus: NOT_FOUND → Flutter'da yeni ürün olarak eklenir
```

**matchedVariantId kullanımı:**
```dart
// isFound=true → existingVariantId olarak BatchEntryRow'a set edilir
// submitAll() → existingProducts[] listesine gider
// Backend: StockMovement(IN) + SupplierAccount cari kaydı
```

### 14.4 Flutter: DocumentAnalyzeItem → BatchEntryRow Aktarım

```dart
// batch_entry_provider.dart → addFromDocumentItems()

// MEVCUT ÜRÜN (isFound=true):
BatchEntryRow(
  productName:      item.matchedProductName ?? item.extractedName ?? item.rawText,
  barcode:          item.extractedCode ?? '',
  quantity:         item.extractedQuantity?.toInt() ?? 1,
  purchasePrice:    item.extractedUnitPrice ?? 0,   // ← birim fiyat = alış fiyatı
  salePrice:        item.extractedUnitPrice ?? 0,   // ← aynı → kullanıcı düzeltmeli
  vatRate:          20.0,                           // ❌ sabit — faturadan gelmiyor
  status:           RowStatus.existing,
  existingVariantId: item.matchedVariantId,
  existingProductId: item.matchedProductId,
  existingVariantSku: item.matchedSku,
)

// YENİ ÜRÜN (isFound=false):
BatchEntryRow(
  productName:   item.extractedName ?? item.rawText,
  barcode:       item.extractedCode ?? '',
  quantity:      item.extractedQuantity?.toInt() ?? 1,
  purchasePrice: item.extractedUnitPrice ?? 0,
  salePrice:     item.extractedUnitPrice ?? 0,      // ← alış = satış → düzeltilmeli
  vatRate:       20.0,                              // ❌ sabit
  status:        RowStatus.newProduct,
  // categoryId: null → ❌ KRİTİK: submit öncesi seçilmeli
  // unitId:     null → "adet" default kullanılır
  // brandName:  null → boş kalır
)
```

### 14.5 Result Sheet'te Gösterilen / Gösterilmeyen Bilgiler

**Gösterilen:**
```
✅ Dosya adı, toplam kalem, mevcut/yeni sayısı (özet bar)
✅ Durum chip: "Mevcut" (mavi) / "Yeni" (turuncu)
✅ Eşleşme tipi: Barkod / OEM / İsim
✅ Ürün adı (matchedProductName veya extractedName)
✅ Çıkarılan kod (extractedCode)
✅ Miktar (extractedQuantity)
✅ Birim fiyat (extractedUnitPrice) — ₺ formatında
✅ Checkbox seçimi + Tümü Seç / Temizle
✅ "X Kalemi Aktar" butonu
```

**Gösterilmiyor (eksik):**
```
❌ KDV oranı
❌ Birim (ADET/KG vb.)
❌ İsim eşleşmesinde güven skoru / uyarı
❌ Loading spinner (analiz sırasında)
❌ Kategori gereksinim uyarısı (yeni ürün seçilince)
```

### 14.6 Desteklenen PDF Tipleri ve Sınırlamalar

```
✅ Dijital/vektörel PDF (metin seçilebilir)    → PDFBox doğrudan okur
❌ Taranmış/görüntü PDF (scanner çıktısı)       → OCR gerekli (Tesseract)
❌ Şifreli/korumalı PDF                         → Hata verir
❌ Excel/Word fatura                            → Desteklenmiyor (sadece PDF)
❌ Çok sayfalı belgeler                         → Her sayfa parse edilir ama yavaş
```

**Türkçe Format Desteği:**
```
✅ 1.234,56  → binlik nokta kaldırılır → "1234.56"
✅ 1234,56   → virgül nokta olur → "1234.56"
✅ 1.234     → integer olarak algılanır (binlik nokta kaldırılır)
⚠️ 1,234.56  → İngilizce format → yanlış parse edilir (Türkçe belge ise sorun değil)
```

### 14.7 Sonraki Geliştirmeler (Sprint 1 Tamamlama)

**Backend — DocumentItemResult modeline eklenecek:**
```java
// DocumentItemResult.java'ya eklenecek alanlar:
private String unit;           // "ADET" | "KG" | "MT" | "LT" vb.
private Double vatRate;        // 8.0 | 18.0 | 20.0 — faturadan extract
private Boolean vatIncluded;   // Fiyat KDV dahil mi?
private Double totalPrice;     // extractedQuantity × extractedUnitPrice
```

**Backend — DocumentAnalyzeServiceImpl.java'ya eklenecek:**
```java
// extractLineInfo() içine:
// Birim extract: "ADET|KG|LT|MT|M2|PAKET|KUTU|PCS|GR" → result.unit
// KDV extract: "\\b(18|8|1|20|10)\\s*%?" → sonraki sayı → result.vatRate
// Satır toplam: en büyük sayı (fiyat × miktar) → result.totalPrice
```

**Flutter — addFromDocumentItems() güncellemesi:**
```dart
BatchEntryRow(
  // ... mevcut alanlar ...
  vatRate:    item.vatRate ?? 20.0,         // faturadan gelen KDV
  vatIncluded: item.vatIncluded ?? false,
  unitId:     _mapUnit(item.unit),          // "ADET" → "adet"
)

String? _mapUnit(String? unit) => switch(unit?.toUpperCase()) {
  'ADET' || 'ADT' || 'PCS' => 'adet',
  'KG'  || 'KGR'           => 'kg',
  'LT'  || 'LTR'           => 'lt',
  'MT'  || 'MTR'           => 'mt',
  _                        => 'adet',  // default
};
```

**Flutter — Loading Dialog:**
```dart
// _uploadDocument() içinde toast yerine dialog göster
showDialog(context: context, barrierDismissible: false,
  builder: (_) => AlertDialog(
    content: Column(children: [
      CircularProgressIndicator(),
      SizedBox(height: 16),
      Text(t('batch.document_uploading')),
    ]),
  ),
);
final result = await service.analyzeDocument(file);
Navigator.pop(context);  // dialog kapat
```

---

## 15. MİMARİ KARARLAR (2026-04-13)

### 15.1 State Management

```
Şu an: StateNotifier + autoDispose (Riverpod 2.x)
Tavsiye: AsyncNotifier'a geçiş (load() barındıran ekranlar önce)
Hedef: freezed paketi → copyWith() boilerplate azalt

Değiştirilmeyecek: StateNotifier → Riverpod yatırımı korunacak.
BLoC/GetX/MobX denemesi yapılmayacak.
```

### 15.2 Multi-Tenant Güvenlik

```
Şu an: Hibernate @Filter (row-level, ThreadLocal companyCode)
Eksik: PostgreSQL RLS double-safety yok
Hedef (Sprint 3): ALTER TABLE products ENABLE ROW LEVEL SECURITY
                  CREATE POLICY tenant_policy ON products
                    USING (company_code = current_setting('app.current_company_code'))
```

### 15.3 Stok Concurrent Update

```
Şu an: Direkt write → lost update riski
Çözüm: @Version Long version alanı ProductVariant'a ekle
       ObjectOptimisticLockingFailureException → max 3 retry + exponential backoff
Hedef: Sprint 2
```

### 15.4 PDF Belge İşleme

```
Şu an: PDFBox sync (metin PDF ✅, taranmış ❌)
Sprint 1: KDV + birim extract tamamlama
Sprint 2: Async job (polling) + Tesseract OCR fallback
Sprint 4: LLM fallback (PDFBox başarısız → Claude API)
```

### 15.5 Gerçek Zamanlı Bildirim

```
Şu an: REST polling (5s interval)
Sprint 2: WebSocket stok alarm (/topic/stock/{companyCode})
          SSE fallback (WebSocket bağlanmadıysa)
```

### 15.6 Mimari Geçiş

```
lib/screens/   → lib/features/  migration ZORUNLU (iki path paralel yürüyor)
Batch entry + wizard hâlâ lib/screens/ altında (router bunu kullanıyor)
Migration sırasında router güncellenmeli (app_router.dart)
```
