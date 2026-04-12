# CLAUDE.md — Toplu Ürün Girişi (`batch_entry/`)

Bu dosya **yalnızca bu klasör** için geçerlidir.  
Genel proje kuralları için kök `CLAUDE.md`'e bak.

---

## 1. SAYFANIN AMACI

Kasiyerin veya depo personelinin tedarikçiden gelen **fatura/irsaliye bazında** toplu ürün girişi yapmasını sağlar.

Üç giriş modu desteklenir:

```
1. Manuel Ürün Arama   → Sistemde var, stok + tedarikçi cari güncelle
2. Yeni Ürün Ekleme    → Sistemde yok, sıfırdan kayıt oluştur
3. PDF / Fatura Yükle  → Faturadaki ürünleri otomatik oku → var/yok eşleştir (TODO)
```

Tüm modlar aynı `BatchEntryState`'i paylaşır ve aynı `submitAll()` akışından geçer.

**Mevcut ürünlerde** sadece stok güncellenir + tedarikçi cari kaydı oluşur. Ürün bilgisi değişmez.

---

## 2. DOSYA YAPISI

```
batch_entry/
├── CLAUDE.md                          ← bu dosya
├── batch_product_screen.dart          ← Ana ekran (route: /inventory/batch-entry)
├── models/
│   └── batch_entry_models.dart        ← Tüm model sınıfları (aşağıda detay)
├── providers/
│   └── batch_entry_provider.dart      ← BatchEntryNotifier (StateNotifier)
└── widgets/
    ├── batch_header_form.dart         ← Başlık formu (tedarikçi, fatura, depo, mağaza, tarih)
    ├── batch_summary_bar.dart         ← Alt özet çubuğu
    ├── barcode_search_input.dart      ← Barkod/OEM arama input'u
    ├── product_entry_table.dart       ← Desktop tablo görünümü ⚠️ henüz import edilmiyor
    └── quick_product_dialog.dart      ← Satır detay dialog'u
```

---

## 3. VERİ AKIŞI

```
Giriş
  ├── Barkod/OEM tarama       → addByBarcode()   → RowStatus.existing  veya  RowStatus.newProduct
  ├── Manuel satır ekle       → addManualRow()   → RowStatus.newProduct
  └── PDF yükle (TODO)        → parsePdfRows()   → her satır için addByBarcode() mantığı

State: BatchEntryState
  ├── header (tedarikçi, fatura, depo, mağaza, tarih)
  └── rows: List<BatchEntryRow>  (her ürün = 1 satır)

submitAll()
  ├── existing rows → PurchaseService.createPurchase()  (stok + tedarikçi cari)
  └── new rows     → ProductService.createProduct()     (her ürün ayrı çağrı)
```

---

## 4. MODEL SINIFLAR — `batch_entry_models.dart`

### 4.1 Enum'lar

```dart
enum RowStatus   { newProduct, existing, matched, error, saving, saved }
enum SectionStatus { complete, partial, empty }
enum CardReadiness { draft, incomplete, ready, saving, saved, error }
```

### 4.2 BatchVariantRow — Footwear çoklu varyant satırı

```dart
class BatchVariantRow {
  final String id;    // otomatik
  String size;        // Numara / Beden  → backend: attributes['Numara']
  String color;       // Renk            → backend: attributes['Renk']
  String barcode;
  int quantity;
  double? purchasePrice; // null = BatchEntryRow.purchasePrice'tan miras alınır
  double? salePrice;     // null = BatchEntryRow.salePrice'tan miras alınır

  bool get isValid => size.trim().isNotEmpty && quantity > 0;
}
```

### 4.3 BatchEntryRow — Tam alan listesi

```dart
// Kimlik
String id                   // otomatik (_generateId)
RowStatus status            // newProduct | existing | matched | saving | saved | error

// Temel — tüm sektörler
String barcode
String productName          // zorunlu (yeni ürünlerde)
String? categoryId          // ← ZORUNLU — dropdown'dan UUID; text girmek YASAK
String? categoryName        // sadece gösterim
String? brandId             // dropdown'dan ID
String? brandName           // gösterim + payload
String? unitId
double purchasePrice        // alış fiyatı — mevcut ürünlerde cari için ZORUNLU
double salePrice            // satış fiyatı ← ZORUNLU
double vatRate              // 0 | 1 | 8 | 10 | 18 | 20
bool vatIncluded            // default: false
int quantity                // min: 1 ← ZORUNLU
String? description

// Sektöre özgü
String? shelfLocation       // raf kodu (parçacı: ZORUNLU, diğer: opsiyonel)
int minStockLevel           // default: 10
String? oemNumber           // tek OEM (UI input)
List<Map<String,String>> oemList       // [{'oemNumber':..., 'manufacturer':...}]
List<Map<String,String>> crossRefList  // [{'crossRefNumber':..., 'crossRefBrand':...}]
Map<String,String> attributes          // sektöre özgü key-value

// Footwear çoklu varyant
List<BatchVariantRow> variantRows  // footwear sektöründe dolu, diğerlerinde []

// Mevcut ürün referansı
String? existingProductId
String? existingVariantId
String? existingVariantSku

// UI
bool isExpanded
String? errorMessage
```

### 4.4 BatchRowCompletion — Kart tamamlanma hesabı

```dart
BatchRowCompletion.compute(row, {
  isExisting, brandRequired, oemRequired, shelfRequired,
  showOem, showShelf,
  showVariantTable,  // ← footwear için true (cfg.fields.showVariantSize)
})
```

**SectionA** (Ürün Bilgileri):
- `isExisting` → daima complete
- Yeni: `productName` + `categoryId` + (brandRequired → `brandName`)

**SectionB** (Fiyat & Stok):
- `salePrice > 0` + `quantity > 0`
- `isExisting` → ayrıca `purchasePrice > 0` zorunlu (cari kaydı için)

**SectionC** (Detaylar):
- `showVariantTable=true` → `variantRows.any(v => v.isValid)` zorunlu
- Diğer sektörler → `oemRequired` + `shelfRequired` kontrolleri

**CardReadiness**:
- `draft` → hiçbir şey girilmemiş
- `incomplete` → eksik zorunlu alan var (missingFields listesi dolu)
- `ready` → tüm zorunlular tamam, kaydedilebilir
- `saving / saved / error` → kayıt durumu

---

## 5. SEKTÖRE GÖRE KART ALANLARI

`SectorConfig` (`core/config/sector_config.dart`) sektörü belirler.

### 5.1 Her Sektörde Ortak

| Alan | Tip | Zorunlu |
|------|-----|---------|
| Ürün adı | text | ✓ yeni |
| Barkod | text | — |
| Alış fiyatı | number | mevcut ürün: ✓ |
| Satış fiyatı | number | ✓ |
| KDV % | dropdown (0/1/8/10/18/20) | — |
| KDV dahil mi? | switch | — |
| Adet | +/− | ✓ |
| Kategori | dropdown (UUID) | ✓ yeni |
| Marka | dropdown | cfg.brandRequired |
| Açıklama | text | — |

### 5.2 Yedek Parçacı (`SectorType.autoParts`)

```
Section 3: OEM Numarası (oemList) + Çapraz Referans (crossRefList)
           Raf Kodu (shelfLocation) ← ZORUNLU
           Min. Stok Seviyesi
Payload:  oemNumbers + crossReferences backend'e gönderilir
OEM/CrossRef: backend'de variant[0]'a bağlanır (single variant, tasarım gereği)
```

### 5.3 Genel Perakende (`SectorType.general`)

```
Section 3: Depo Konumu (shelfLocation, opsiyonel) + Min. Stok
```

### 5.4 Teknoloji (`SectorType.technology`)

```
Section 3: Seri/IMEI No (oemNumber → attributes['imei']) + Raf + Min. Stok
NOT: Backend'de ayrı SerialNumber entity yok.
     IMEI attributes map'e kaydedilir: attributes['imei'] = '354...'
     quantity=10 → 10 adet, IMEI model referansı olarak saklanır
```

### 5.5 Ayakkabı / Tekstil (`SectorType.footwear`)

```
Section 3: _FootwearVariantTable — inline düzenlenebilir tablo
  Kolonlar: Numara/Beden | Renk | Adet | Barkod | Alış ₺ | Satış ₺ | ×
  - Her satır = ayrı bir backend variant (ayrı SKU, ayrı stok)
  - Fiyatlar boş bırakılırsa kart seviyesinden miras alınır
  - "Varyant Ekle" butonu ile yeni satır eklenir
  - isValid: size.isNotEmpty && quantity > 0

_BatchAttributesSection footwear'da GİZLİDİR (variant tablosu yeterli)
```

**Footwear payload yapısı** (`submitAll` içinde):

```dart
// variantRows her biri ayrı variant olarak gönderilir
'variants': row.variantRows.map((vr) => {
  'sku': _generateSku(),
  'name': '${row.productName} - ${vr.size} ${vr.color}'.trim(),
  'attributes': {
    'Numara': vr.size,
    if (vr.color.isNotEmpty) 'Renk': vr.color,
  },
  'pricing': {
    'purchasePrice': vr.purchasePrice ?? row.purchasePrice,
    'salePrice': vr.salePrice ?? row.salePrice,
    'vatRate': row.vatRate,
    'vatIncluded': row.vatIncluded,
  },
  'barcodes': vr.barcode.isNotEmpty
      ? [{'code': vr.barcode, 'type': 'EAN13', 'isPrimary': true}]
      : [],
  'initialStocks': [{'storeId': state.storeId, 'warehouseId': state.warehouseId, 'quantity': vr.quantity}],
}).toList(),
```

---

## 6. PAYLOAD STANDARDI

### 6.1 Sektor string kuralı

```dart
'sector': cfg.type.apiValue   // 'AUTO_PARTS' | 'GENERAL' | 'TECHNOLOGY' | 'FOOTWEAR'
// Backend Product.sector plain String — doğrudan saklıyor, validate etmiyor
// Flutter SectorTypeExt.fromApi() ile parse edilir
// YANLIŞ: cfg.type.apiValue.toLowerCase() → 'auto_parts' — tutarlı değil
```

### 6.2 Genel payload şablonu (footwear dışı)

```dart
{
  'product': {
    'name': row.productName,
    'sku': _generateSku(),
    'categoryId': row.categoryId,    // UUID zorunlu
    'brand': row.brandName ?? '',
    'unit': row.unitId ?? cfg.labels.defaultUnit,
    'description': row.description ?? '',
    'sector': cfg.type.apiValue,
    'metadata': _buildMetadata(row, cfg),
  },
  'oemNumbers': row.oemList
      .where((o) => (o['oemNumber'] ?? '').isNotEmpty)
      .map((o) => {'oemNumber': o['oemNumber'], 'manufacturer': o['manufacturer'] ?? '',
                   'isPrimary': o == row.oemList.first}).toList(),
  'crossReferences': row.crossRefList
      .where((c) => (c['crossRefNumber'] ?? '').isNotEmpty)
      .map((c) => {'crossRefNumber': c['crossRefNumber'], 'crossRefBrand': c['crossRefBrand'] ?? ''}).toList(),
  'variants': [
    {
      'sku': _generateSku(),
      'name': row.productName,
      'shelfLocationCode': row.shelfLocation,
      'attributes': row.attributes,
      'pricing': {
        'purchasePrice': row.purchasePrice,
        'salePrice': row.salePrice,
        'vatRate': row.vatRate,
        'vatIncluded': row.vatIncluded,
        'taxExempt': false,
      },
      'initialStocks': [{'storeId': state.storeId, 'warehouseId': state.warehouseId, 'quantity': row.quantity}],
      'barcodes': row.barcode.isNotEmpty ? [{'code': row.barcode, 'type': 'EAN13', 'isPrimary': true}] : [],
    }
  ],
  'purchase': {
    'supplierId': state.supplierId,
    'invoiceNumber': state.invoiceNumber ?? _autoInvoiceNo(),
    'deliveryNoteNumber': state.deliveryNoteNumber,
    'purchaseDate': DateFormat('yyyy-MM-dd').format(state.purchaseDate),
    'storeId': state.storeId,
    'warehouseId': state.warehouseId,
  },
}
```

---

## 7. KART TASARIM SİSTEMİ — Widget Mimarisi

### 7.1 Collapsed kart

```
[_ReadinessBadge]  Ürün adı + meta chips      [_WizardStepDots]
                   eksik alan uyarısı (incomplete ise)
                   fiyat / adet kontrolü
```

### 7.2 Expanded kart — Bölümler

```
Section 1: _WizardSectionHeader(step:1, "Ürün Bilgileri")
  ├── Mevcut ürün → _ExistingProductInfoCard (read-only)
  └── Yeni ürün   → Ürün adı, Barkod, Kategori, Marka, Birim

Section 2: _WizardSectionHeader(step:2, "Fiyat & Stok")
  └── Alış, Satış, KDV, KDV dahil, Adet

Section 3: _WizardSectionHeader(step:3, ...)
  ├── footwear → _FootwearVariantTable
  └── diğer    → OEM/Raf/MinStok (showOem || showShelf ise gösterilir)

Section 4: _BatchAttributesSection (footwear'da GİZLİ)
  └── Sektöre özgü attribute chip'leri
```

### 7.3 Yeni widget'lar (batch_product_screen.dart içinde)

| Widget | Açıklama |
|--------|---------|
| `_ReadinessBadge` | CardReadiness'a göre renkli pill badge |
| `_WizardStepDots` | 3 daire: complete=yeşil dolu, partial=amber, empty=gri |
| `_WizardSectionHeader` | Adım no + başlık + tamamlanma chip'i |
| `_ExistingProductInfoCard` | Mevcut ürün read-only bilgi kartı (Section A) |
| `_FootwearVariantTable` | Footwear için inline varyant tablosu |
| `_VariantTableRow` | Tek varyant satırı (TextFields inline) |
| `_VCell` | Tablo hücresi TextField |

### 7.4 Durum renkleri

```
CardReadiness.draft      → AppColors.textMuted
CardReadiness.incomplete → AppColors.warning
CardReadiness.ready      → AppColors.success
CardReadiness.saving     → AppColors.warning
CardReadiness.saved      → AppColors.success
CardReadiness.error      → AppColors.danger
```

---

## 8. MEVCUT ÜRÜN AKIŞI

```dart
// addByBarcode() → RowStatus.existing
BatchEntryRow(
  barcode: p['barcode'] ?? trimmed,
  productName: p['name'] ?? '',
  brandName: p['brand'],
  categoryId: p['categoryId'],
  categoryName: p['categoryName'],      // ← _mapProduct'ta alınmalı
  purchasePrice: p['purchasePrice'],    // ← firstVariant['purchasePrice']
  salePrice: p['sellingPrice'] ?? p['basePrice'] ?? 0,
  vatRate: p['taxRate'] ?? 20.0,
  quantity: 1,
  status: RowStatus.existing,
  existingProductId: p['id'],
  existingVariantId: p['variantId'],
  existingVariantSku: p['sku'],
)

// submitAll() — existing row için PurchaseService.createPurchase() çağrılır:
// → StockMovement(PURCHASE_IN) oluşturulur
// → SupplierAccount.currentBalance += totalAmount (cari borç)
// → AccountTransaction kaydı oluşur
```

---

## 9. BİLİNEN HATALAR — GELİŞTİRİLECEK

### P0 — Kritik (kayıt çalışmıyor)

- [ ] **`categoryId` null** — Yeni ürün kartında kategori serbest metin, `categoryId` set edilmiyor.  
  **Çözüm:** `CategoryPickerField` widget → dropdown ile UUID set et.

### P1 — Yüksek (veri yanlış kaydediliyor)

- [ ] **`oemNumbers` payload'a girmiyor** — `row.oemList` var ama submitAll'da kullanılmıyor.
- [ ] **`crossReferences` payload'a girmiyor** — `row.crossRefList` var ama submitAll'da kullanılmıyor.
- [ ] **`attributes` variants bloğuna gitmiyor** — `row.attributes` map payload'a eklenmeli.
- [ ] **Mevcut ürün `purchasePrice` = 0** — `_mapProduct`'ta `firstVariant['purchasePrice']` alınmıyor.
- [ ] **`metadata` eksik** — `_buildMetadata()` submitAll içinde implemente edilmemiş.
- [ ] **Footwear `submitAll`** — `variantRows` birden fazla variant olarak payload'a gönderilmeli (§5.5).

### P2 — Orta (UX sorunları)

- [ ] **`TextEditingController` stale** — `applyBrandToAll` vb. sonrası controller'lar güncellenmez.
- [ ] **KDV dropdown gösterilmiyor** — Expanded formda `vatRate` dropdown eksik.
- [ ] **`BatchHeaderForm._loadData` hata sessiz yutuluyuyor** — `catch (_) {}` → `debugPrint` ekle.

### P3 — Düşük / İleride

- [ ] **`ProductEntryTable` kullanılmıyor** — Desktop modda aktifleştirilebilir.
- [ ] **`categoryName` mevcut ürünlerde boş** — `_mapProduct`'ta eksik.
- [ ] **PDF fatura yükleme modu** — Henüz implement edilmedi (§8).
- [ ] **OEM ile arama** — `addByBarcode` yalnızca barkod/isim arıyor, OEM arama yok.

---

## 10. GELİŞTİRME ÖNCELİK SIRASI

```
Sprint 1: Kayıt düzeltmeleri
  1. categoryId dropdown → CategoryPickerField
  2. oemNumbers + crossReferences payload'a ekle
  3. attributes variants bloğuna ekle
  4. metadata implementasyonu (_buildMetadata)
  5. Mevcut ürün purchasePrice düzeltme (_mapProduct)

Sprint 2: Footwear tamamlama
  6. submitAll'da variantRows → çoklu variant payload
  7. Footwear collapsed görünüm: "N varyant" chip

Sprint 3: UX iyileştirmeleri
  8. TextEditingController senkron (didUpdateWidget)
  9. KDV dropdown expanded formda göster
  10. ProductEntryTable desktop'ta aktifleştir

Sprint 4: PDF modu
  11. PdfInvoiceParser + UI
  12. OEM arama desteği
```

---

## 11. i18n ANAHTARLARI (data.sql — bnd-bt prefixli)

Son eklenen aralıklar:

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
| bt081 | `batch.existing_stock_note` | Mevcut ürün: stok ve cari hesap güncellenecek | ... |
| bt082 | `batch.ready` | Hazır | Ready |
| bt083 | `batch.details` | Detaylar | Details |
| bt084 | `batch.product_info` | Ürün Bilgileri | Product Info |
| bt085 | `batch.variants` | Varyantlar | Variants |

---

## 12. BAĞIMLILIKLAR

```dart
// service_locator.dart'ta tanımlı
productServiceProvider
purchaseServiceProvider
supplierServiceProvider
warehouseServiceProvider
storeServiceProvider
companyCategoryServiceProvider
brandServiceProvider

// Provider'lar
batchEntryProvider    // StateNotifierProvider.autoDispose<BatchEntryNotifier, BatchEntryState>
sectorConfigProvider  // SectorConfig (type, fields, labels)
```

---

## 13. TEST SENARYOLARI

```
✓ Barkod ile mevcut ürün bulma → purchasePrice, salePrice, vatRate doğru dolar
✓ Bulunamayan barkod → yeni satır, boş form
✓ Aynı barkod iki kez taranır → adet +1 artar
✓ Yeni ürün: categoryId seçilmeden → incomplete, kayıt engellenebilir
✓ Yeni ürün: salePrice = 0 → CardReadiness.incomplete
✓ Mevcut ürün: purchasePrice = 0 → CardReadiness.incomplete (cari için zorunlu)
✓ Footwear: variantRows boş → SectionC empty, incomplete
✓ Footwear: en az 1 valid variant → SectionC complete
✓ submitAll: tedarikçi yok → validation hatası
✓ submitAll: depo yok → validation hatası
✓ Kısmi başarı: 3 üründen 1 hatalı → diğer 2 saved, 1 error
```
