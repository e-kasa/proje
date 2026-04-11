# CLAUDE.md — Toplu Ürün Girişi (`batch_entry/`)

Bu dosya **yalnızca bu klasör** için geçerlidir.  
Genel proje kuralları için kök `CLAUDE.md`'e bak.

---

## 1. SAYFANIN AMACI

Kasiyerin veya depo personelinin tedarikçiden gelen **fatura/irsaliye bazında** toplu ürün girişi yapmasını sağlar.

Üç giriş modu desteklenir:

```
1. Manuel Ürün Arama   → Sistemde var, stok/fiyat güncelle
2. Yeni Ürün Ekleme    → Sistemde yok, sıfırdan kayıt oluştur
3. PDF / Fatura Yükle  → Faturadaki ürünleri otomatik oku → var/yok eşleştir
```

Tüm modlar aynı `BatchEntryState`'i paylaşır ve aynı `submitAll()` akışından geçer.

---

## 2. DOSYA YAPISI

```
batch_entry/
├── CLAUDE.md                          ← bu dosya
├── batch_product_screen.dart          ← Ana ekran (route: /inventory/batch-entry)
├── models/
│   └── batch_entry_models.dart        ← BatchEntryRow, BatchEntryState, BatchSaveResult
├── providers/
│   └── batch_entry_provider.dart      ← BatchEntryNotifier (StateNotifier)
└── widgets/
    ├── batch_header_form.dart         ← Başlık formu (tedarikçi, fatura, depo, mağaza, tarih)
    ├── batch_summary_bar.dart         ← Alt özet çubuğu (toplam maliyet, kar %, kaydet butonu)
    ├── barcode_search_input.dart      ← Barkod/OEM arama input'u
    ├── product_entry_table.dart       ← Desktop tablo görünümü (DataTable)  ⚠️ henüz import edilmiyor
    └── quick_product_dialog.dart      ← Satır detay dialog'u (birim, OEM, raf, açıklama)
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
  ├── existing rows → PurchaseService.createPurchase()    (toplu, tek çağrı)
  └── new rows     → ProductService.createProduct()       (her ürün ayrı çağrı)
```

---

## 4. BatchEntryRow — TAM ALAN LİSTESİ

```dart
// Kimlik
String id                   // ← _generateId() ile otomatik
RowStatus status            // newProduct | existing | matched | saving | saved | error

// Temel — tüm sektörler
String barcode              // EAN13 / QR / OEM
String productName          // zorunlu (yeni ürünlerde)
String? categoryId          // ← ZORUNLU — dropdown'dan UUID; text girmek YASAK
String? categoryName        // ← sadece gösterim için
String? brandId             // ← dropdown'dan ID
String? brandName           // ← gösterim + payload için
String? unitId              // 'pcs' | 'kg' | 'lt' | vb.
double purchasePrice        // alış fiyatı
double salePrice            // satış fiyatı (zorunlu)
double vatRate              // KDV % (0 | 1 | 8 | 10 | 18 | 20)
bool vatIncluded            // KDV dahil mi? (default: false)
int quantity                // adet (min: 1)
String? description

// Sektöre özgü
String? shelfLocation       // raf kodu (parçacı: zorunlu, diğer: opsiyonel)
int minStockLevel           // minimum stok uyarı seviyesi (default: 10)
String? oemNumber           // OEM no — tek OEM (parçacı, teknoloji)
List<Map<String,String>> oemList        // [{'oemNumber':..., 'manufacturer':...}]
List<Map<String,String>> crossRefList   // [{'crossRefNumber':..., 'crossRefBrand':...}]

// Varyant (ayakkabı / tekstil / teknoloji)
String? variantSize         // beden / numara (footwear)
String? variantColor        // renk (footwear, technology)
String? warrantyMonths      // garanti ay (technology)
String? imeiSerial          // IMEI / seri no (technology)
Map<String,String> attributes   // {'Renk':'Kırmızı', 'Beden':'42'} — payload için

// Mevcut ürün referansı
String? existingProductId
String? existingVariantId
String? existingVariantSku

// UI
bool isExpanded
String? errorMessage
```

---

## 5. SEKTÖRE GÖRE KART ALANLARI

`SectorConfig` (`core/config/sector_config.dart`) ile yönetilir.  
Kart açıldığında (`isExpanded = true`) sektöre göre alanları göster:

### 5.1 Her Sektörde Ortak (daima göster)

| Alan | Tip | Zorunlu |
|------|-----|---------|
| Ürün adı | text | ✓ yeni |
| Barkod | text | — |
| Alış fiyatı | number | — |
| Satış fiyatı | number | ✓ |
| KDV % | dropdown (0/1/8/10/18/20) | — |
| KDV dahil mi? | switch | — |
| Adet | +/− kontrol | ✓ |
| Kategori | **dropdown** (UUID seçer) | ✓ yeni |
| Marka | dropdown (brandId seçer) | cfg.brandRequired |
| Açıklama | text (multiline) | — |

### 5.2 Yedek Parçacı (`SectorType.autoParts`)

```
+ OEM Numarası          (oemList — çoklu giriş)
+ Çapraz Referans       (crossRefList — çoklu giriş)
+ Raf Kodu              (shelfLocation) ← ZORUNLU
+ Min. Stok Seviyesi    (minStockLevel)
+ Araç Uyumu            (TODO — ileride eklenecek)
```

### 5.3 Genel Perakende (`SectorType.general`)

```
+ Depo Konumu           (shelfLocation)
+ Min. Stok Seviyesi
```

### 5.4 Teknoloji / Elektronik (`SectorType.technology`)

```
+ Seri Numarası         (imeiSerial / oemNumber)
+ Garanti Süresi (ay)   (warrantyMonths)
+ Renk                  (variantColor → attributes['Renk'])
+ IMEI                  (imeiSerial)
```

### 5.5 Ayakkabı / Tekstil (`SectorType.footwear`)

```
+ Renk                  (variantColor → attributes['Renk'])
+ Beden / Numara        (variantSize → attributes['Beden'])
  → Her beden = ayrı satır, AYNI ürünü gruplayarak göster
```

---

## 6. PAYLOAD STANDARDI — Wizard ile Birebir Uyumlu

`submitAll()` içinde yeni ürün oluşturulurken **bu yapıya** uy.  
Referans: `add_product/models/wizard_actions.dart → buildPayload()`

```dart
final payload = {
  'product': {
    'name': row.productName,
    'sku': _generateSku(),
    'categoryId': row.categoryId,          // ← UUID zorunlu
    'brand': row.brandName ?? '',
    'unit': row.unitId ?? cfg.labels.defaultUnit,
    'description': row.description ?? '',
    'sector': cfg.type.apiValue.toLowerCase(), // 'parcaci' | 'giyim' | 'genel'
    'metadata': _buildMetadata(row, cfg),   // sektöre özgü JSON
  },
  'oemNumbers': row.oemList
      .where((o) => (o['oemNumber'] ?? '').isNotEmpty)
      .map((o) => {
        'oemNumber': o['oemNumber'],
        'manufacturer': o['manufacturer'] ?? '',
        'isPrimary': o == row.oemList.first,
      }).toList(),
  'crossReferences': row.crossRefList
      .where((c) => (c['crossRefNumber'] ?? '').isNotEmpty)
      .map((c) => {
        'crossRefNumber': c['crossRefNumber'],
        'crossRefBrand': c['crossRefBrand'] ?? '',
        'notes': c['notes'],
      }).toList(),
  'variants': [
    {
      'sku': _generateSku(),
      'name': row.productName,
      'shelfLocationCode': row.shelfLocation,
      'attributes': row.attributes,          // {'Renk': 'Kırmızı', 'Beden': '42'}
      'pricing': {
        'purchasePrice': row.purchasePrice,
        'salePrice': row.salePrice,
        'vatRate': row.vatRate,
        'vatIncluded': row.vatIncluded,      // ← HARDCODE true değil
        'specialTaxRate': null,
        'withholdingTaxRate': null,
        'taxExempt': false,
      },
      'initialStocks': [
        {
          'storeId': state.storeId,
          'warehouseId': state.warehouseId,
          'quantity': row.quantity,
        }
      ],
      'barcodes': row.barcode.isNotEmpty
          ? [{'code': row.barcode, 'type': 'EAN13', 'isPrimary': true}]
          : [],
    }
  ],
  'purchase': {
    'supplierId': state.supplierId,
    'invoiceNumber': state.invoiceNumber ?? _autoInvoiceNo(),
    'deliveryNoteNumber': state.deliveryNoteNumber,
    'purchaseDate': DateFormat('yyyy-MM-dd').format(state.purchaseDate),
    'storeId': state.storeId,
    'warehouseId': state.warehouseId,
    'notes': null,
  },
};
```

### `_buildMetadata(BatchEntryRow row, SectorConfig cfg)`

```dart
Map<String, dynamic>? _buildMetadata(BatchEntryRow row, SectorConfig cfg) {
  switch (cfg.type) {
    case SectorType.autoParts:
      final meta = <String, dynamic>{};
      if (row.shelfLocation != null) meta['shelfLocation'] = row.shelfLocation;
      if (row.oemList.isNotEmpty) meta['oemCount'] = row.oemList.length;
      return meta.isEmpty ? null : meta;
    case SectorType.footwear:
      final meta = <String, dynamic>{};
      // fabric, season alanları eklenirse buraya
      return meta.isEmpty ? null : meta;
    case SectorType.technology:
      final meta = <String, dynamic>{};
      if (row.warrantyMonths != null) meta['warranty'] = row.warrantyMonths;
      return meta.isEmpty ? null : meta;
    default:
      return null;
  }
}
```

---

## 7. MEVCUT ÜRÜNLERİ BULMAK — `addByBarcode()` Kuralları

Mevcut ürün backend'den döndüğünde `BatchEntryRow`'u şöyle doldur:

```dart
BatchEntryRow(
  barcode: p['barcode']?.toString() ?? trimmed,
  productName: p['name']?.toString() ?? '',
  brandName: p['brand']?.toString(),
  categoryId: p['categoryId']?.toString(),
  categoryName: p['categoryName']?.toString(),   // _mapProduct'ta alınmalı
  purchasePrice: _variantPurchasePrice(p),        // variants[0].purchasePrice
  salePrice: _variantSalePrice(p),                // variants[0].salePrice (basePrice'dan)
  vatRate: (p['taxRate'] as num?)?.toDouble() ?? 20.0,
  quantity: 1,
  status: RowStatus.existing,
  existingProductId: p['id']?.toString(),
  existingVariantId: p['variantId']?.toString(),
  existingVariantSku: p['sku']?.toString(),
)
```

`ProductService._mapProduct()` aşağıdaki alanları da dönmelidir:
- `categoryName` → `raw['categoryName']`
- `purchasePrice` → `firstVariant['purchasePrice']`
- `taxRate` → `firstVariant['vatRate'] ?? firstVariant['taxRate']`

---

## 8. PDF FATURA OKUMA — MOD 3 (TODO)

### Akış

```
1. Kullanıcı PDF seçer (file_picker)
2. PDF'teki satırlar parse edilir (pdf_text → NLP veya regex)
3. Her satır için addByBarcode() mantığı uygulanır:
   - Barkod / OEM ile arama → bulunursa RowStatus.existing
   - Bulunamazsa → RowStatus.newProduct (isim, fiyat otomatik doldurulur)
4. Kullanıcı eksik alanları tamamlar → submitAll()
```

### PDF Parse Stratejisi

```
Fatura tipi algılama:
  - "Fatura No" satırı → invoiceNumber otomatik doldur
  - "Tarih" satırı → purchaseDate otomatik doldur

Ürün satırı regex (örnek):
  r'(\d{10,13})\s+(.*?)\s+(\d+)\s+([\d,\.]+)'
  grup 1 = barkod, grup 2 = isim, grup 3 = adet, grup 4 = fiyat

Fiyat formatı:
  '1.234,50 TL' → parsePrice() → 1234.50
```

### Gerekli Paket

```yaml
# pubspec.yaml'a ekle (henüz yok):
pdf_text: ^x.x.x        # veya syncfusion_flutter_pdf
file_picker: ^x.x.x     # zaten varsa kontrol et
```

### Provider Metodu

```dart
Future<void> importFromPdf(String filePath) async {
  state = state.copyWith(isPdfParsing: true);
  try {
    final rows = await PdfInvoiceParser.parse(filePath);
    for (final row in rows) {
      await addByBarcode(row.barcode ?? row.productName ?? '');
      // varsa fiyatı override et
    }
  } finally {
    state = state.copyWith(isPdfParsing: false);
  }
}
```

---

## 9. BİLİNEN HATALAR — GELİŞTİRİLECEK

Öncelik sırası ile:

### P0 — Kritik (kayıt çalışmıyor)

- [ ] **`categoryId` null** — Yeni ürün kartında kategori serbest metin, `categoryId` set edilmiyor.  
  **Çözüm:** `_Field` yerine `CategoryPickerField` kullan → dropdown ile `categoryId` + `categoryName` set et.

- [ ] **`sector` eksik** — `product.sector` payload'da yok.  
  **Çözüm:** `cfg.type.apiValue.toLowerCase()` ile ekle.

### P1 — Yüksek (veri yanlış kaydediliyor)

- [ ] **`vatIncluded` hardcode `true`** — payload'da her zaman `true`.  
  **Çözüm:** `BatchEntryRow.vatIncluded` alanı ekle, formda switch göster.

- [ ] **`oemNumbers` payload'a girmiyor** — `// Skip for now` yorumu var.  
  **Çözüm:** `row.oemList` varsa payload'a ekle.

- [ ] **`attributes` eksik** — Varyant özellikleri (Renk, Beden) payload'a girmiyor.  
  **Çözüm:** `BatchEntryRow.attributes` map'ini variants bloğuna ekle.

- [ ] **Mevcut ürün `purchasePrice` = 0** — `_mapProduct`'ta variant `purchasePrice` alınmıyor.  
  **Çözüm:** `_mapProduct`'a `purchasePrice: firstVariant['purchasePrice']` ekle.

- [ ] **`metadata` eksik** — `_buildMetadata()` metodu yok.  
  **Çözüm:** Yukarıdaki §6'daki implementasyonu ekle.

### P2 — Orta (UX sorunları)

- [ ] **`TextEditingController` stale** — Toplu işlemler (`applyBrandToAll` vb.) sonrası  
  kart controller'ları güncellenmez. `didUpdateWidget` + `setState()` ile sync et.

- [ ] **`applyCategoryToAll` / `applyBrandToAll` sıra bozuyor** — yeni satırları öne,  
  mevcutları arkaya koyuyor. Orijinal sıra korunmalı.

- [ ] **KDV input alanı yok** — Expanded formda vatRate dropdown'u gösterilmiyor.  
  `product_entry_table.dart`'ta var ama `batch_product_screen.dart`'ta eksik.

- [ ] **`crossReferences` payload'a girmiyor** — `row.crossRefList` var ama submitAll'da kullanılmıyor.

- [ ] **`BatchHeaderForm._loadData` hata sessiz yutuluyuyor** — `catch (_) {}`.  
  `debugPrint` ekle.

### P3 — Düşük / İleride

- [ ] **`ProductEntryTable` kullanılmıyor** — Widget yazılmış ama hiçbir yerde import edilmiyor.  
  Desktop modda `_BatchRowCard` ListView yerine bu kullanılabilir.

- [ ] **`categoryName` mevcut ürünlerde boş** — `_mapProduct`'ta `categoryName` alınmıyor.

- [ ] **`vatRate` mevcut ürünlerde sabit 20** — `_mapProduct`'tan `taxRate` alınmalı.

- [ ] **PDF fatura yükleme modu** — Henüz implement edilmedi (bkz. §8).

- [ ] **OEM ile arama** — `addByBarcode` şu an sadece ürün adı/barkod ile arıyor.  
  Parçacı sektöründe OEM ile de arama yapılmalı.

---

## 10. GELİŞTİRME ÖNCELİK SIRASI

```
Sprint 1: P0 düzeltmeleri
  1. categoryId dropdown → CategoryPickerField widget
  2. sector alanı payload'a ekleme
  3. addByBarcode: purchasePrice, vatRate, categoryName düzeltme

Sprint 2: P1 düzeltmeleri
  4. vatIncluded switch + BatchEntryRow alanı
  5. oemNumbers + crossReferences payload ekleme
  6. attributes map payload ekleme
  7. _buildMetadata() implementasyonu

Sprint 3: P2 UX iyileştirmeleri
  8. TextEditingController senkron (didUpdateWidget)
  9. applyBrandToAll / applyCategoryToAll sıra fix
  10. KDV dropdown expanded formda göster
  11. ProductEntryTable desktop'ta aktifleştir

Sprint 4: PDF modu
  12. PdfInvoiceParser implementasyonu
  13. UI: PDF yükle butonu + parse progress
  14. OEM arama desteği
```

---

## 11. KART TASARIM KURALLARI

- Her kart collapsed hâlde: **ürün adı + durum badge + fiyat + adet kontrolü**
- Her kart expanded hâlde: **sektöre göre tam form** (bkz. §5)
- Durum renkleri:
  - `newProduct` → `AppColors.info` (mavi)
  - `existing` / `matched` → `AppColors.success` (yeşil)
  - `saving` → `AppColors.warning` (sarı, pulsing)
  - `saved` → `AppColors.success` soluk + checkmark
  - `error` → `AppColors.danger` (kırmızı) + hata mesajı
- `GestureDetector` KULLANMA → `InkWell` + `Material` kullan
- Dark mode kontrolü her container'da: `isDark ? Color(0xFF1A1A2E) : Colors.white`

---

## 12. BAĞIMLILIKLAR

```dart
// Provider bağımlılıkları (service_locator.dart'ta tanımlı)
productServiceProvider      // ürün arama + oluşturma
purchaseServiceProvider     // mevcut ürün satın alma
supplierServiceProvider     // tedarikçi listesi (header form)
warehouseServiceProvider    // depo listesi (header form)
storeServiceProvider        // mağaza listesi (header form)
companyCategoryServiceProvider  // kategori dropdown (kart içi)
brandServiceProvider        // marka dropdown (kart içi)

// Provider'lar
batchEntryProvider          // StateNotifierProvider.autoDispose<BatchEntryNotifier, BatchEntryState>
sectorConfigProvider        // sektör konfigürasyonu
```

---

## 13. TEST SENARYOLARI

```
✓ Barkod ile mevcut ürün bulma → purchasePrice, salePrice, vatRate doğru dolar
✓ Bulunamayan barkod → yeni satır açılır, boş form
✓ Aynı barkod iki kez taranır → adet +1 artar
✓ Yeni ürün: categoryId seçilmeden kayıt → validation hatası
✓ Yeni ürün: salePrice = 0 → validation hatası
✓ Mevcut ürün: quantity = 0 → validation hatası
✓ submitAll: tedarikçi seçilmemişse → validation hatası
✓ submitAll: depo seçilmemişse → validation hatası
✓ Kısmi başarı: 3 üründen 1 hatalı → diğer 2 kaydedilir, 1 error durumunda kalır
✓ Toplu KDV uygulama → tüm satırlar güncellenir
✓ applyBrandToAll → sadece newProduct satırları güncellenir, sıra bozulmaz
```
