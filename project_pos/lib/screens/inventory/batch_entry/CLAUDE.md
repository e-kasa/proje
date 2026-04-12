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

### P1 — Veri sorunları

- [ ] **Mevcut ürün `purchasePrice` = 0** — `_mapProduct` içinde `firstVariant['purchasePrice']`  
  bakıyor ama API response yapısına göre key farklı olabilir → test edilmeli.

### P2 — UX sorunları

- [ ] **`TextEditingController` stale** — `applyBrandToAll` vb. sonrası `_syncControllers`  
  build'de çağrılıyor ama odak sorunları olabilir — test edilmeli.
- [ ] **KDV dropdown** — Section 2'de `vatRate` dropdown mevcut, ama `taxExempt` /  
  `specialTaxRate` batch modelde yok (wizard'da var).

### P3 — İleride

- [ ] **`ProductEntryTable`** — Desktop modda import edilmiyor.
- [ ] **PDF fatura parse** — `parsePdfRows()` metodu yok.
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

SONRA:
  Sprint 3: UX iyileştirmeleri
    - taxExempt / specialTaxRate batch modele ekle
    - ProductEntryTable desktop'ta aktifleştir
    - Mevcut ürün purchasePrice edge case testi

  Sprint 4: PDF modu
    - PdfInvoiceParser
    - OEM arama desteği
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

---

## 12. BAĞIMLILIKLAR

```dart
// batch_entry_provider.dart — doğrudan kullanılan
productServiceProvider     // batchCreate() + addByBarcode()
oemServiceProvider         // (henüz aktif kullanılmıyor)
sectorConfigProvider       // SectorConfig (type, fields, labels)
companyCategoryServiceProvider  // batchCategoriesProvider için

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
