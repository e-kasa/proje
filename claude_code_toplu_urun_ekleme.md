# CLAUDE CODE KOMUTLARI - Toplu Ürün Ekleme

---

## MOD 1: HIZLI TABLO GİRİŞİ (Barkod Tara → Tablo → Toplu Kaydet)

```
project_pos Flutter projesinde barkod tarama / arama ile hızlı çoklu ürün ekleme ekranı oluştur. Bu ekran oto yedek parça sektörü için tasarlanmış: tedarikçiden mal geldiğinde faturadaki 20-30 kalemi hızlıca sisteme girmek için kullanılacak. Mevcut add_purchase_screen.dart'ın çoklu ürün ekleme pattern'ini referans al ama bu ekran hem YENİ ürün oluşturabilmeli hem MEVCUT ürün stok/fiyat güncelleyebilmeli.

### DOSYA YAPISI

lib/screens/inventory/batch_entry/
├── batch_product_screen.dart
├── widgets/
│   ├── batch_header_form.dart
│   ├── product_entry_table.dart
│   ├── barcode_search_input.dart
│   ├── quick_product_dialog.dart
│   └── batch_summary_bar.dart
├── providers/
│   └── batch_entry_provider.dart
└── models/
    └── batch_entry_models.dart

### 1. batch_entry_models.dart

```dart
enum RowStatus { newProduct, existing, matched, error, saving, saved }

class BatchEntryRow {
  String? id;                    // Satır benzersiz ID (uuid)
  String barcode;
  String productName;
  String? oemNumber;
  String? brandId;
  String? brandName;
  String? categoryId;
  String? categoryName;
  String? unitId;
  double purchasePrice;
  double salePrice;
  double vatRate;                // Varsayılan: 20.0
  int quantity;
  RowStatus status;
  String? existingProductId;     // Eşleşen ürün ID (mevcut ürün ise)
  String? existingVariantId;
  String? existingVariantSku;
  String? errorMessage;
  bool isExpanded;               // Mobilde detay alanı açık mı

  // Hesaplanan alanlar
  double get lineTotal => salePrice * quantity;
  double get lineCost => purchasePrice * quantity;
  double get lineProfit => lineTotal - lineCost;
}

class BatchEntryState {
  // Ortak başlık bilgileri
  String? supplierId;
  String? supplierName;
  String? invoiceNumber;
  String? deliveryNoteNumber;
  DateTime purchaseDate;
  String? storeId;
  String? warehouseId;

  // Satırlar
  List<BatchEntryRow> rows;

  // Hesaplanan
  int get totalItems => rows.length;
  int get newItems => rows.where((r) => r.status == RowStatus.newProduct).length;
  int get existingItems => rows.where((r) => r.status == RowStatus.existing || r.status == RowStatus.matched).length;
  double get totalCost => rows.fold(0, (sum, r) => sum + r.lineCost);
  double get totalSale => rows.fold(0, (sum, r) => sum + r.lineTotal);
  double get totalProfit => totalSale - totalCost;

  bool get isValid => rows.isNotEmpty && supplierId != null && warehouseId != null;
}

class BatchSaveResult {
  int totalProcessed;
  int newCreated;
  int stockUpdated;
  int errors;
  List<String> errorMessages;
}
```

### 2. batch_entry_provider.dart

Riverpod StateNotifier<BatchEntryState> oluştur. Metotlar:

```
class BatchEntryNotifier extends StateNotifier<BatchEntryState> {

  // Barkod ile ürün ara ve satır ekle
  Future<void> addByBarcode(String barcode) async {
    // 1. ProductService ile barkod ara (product/api/v1/products/search?keyword=barcode)
    // 2. BULDU → BatchEntryRow oluştur:
    //    - status: RowStatus.existing
    //    - existingProductId, existingVariantId, existingVariantSku doldur
    //    - productName, brandName, purchasePrice, salePrice mevcut veriden al
    //    - quantity: 1 (kullanıcı değiştirecek)
    //    - Aynı barkod zaten tabloda varsa → sadece quantity++ yap, yeni satır ekleme
    // 3. BULAMADI → BatchEntryRow oluştur:
    //    - status: RowStatus.newProduct
    //    - barcode: taranan barkod
    //    - Diğer alanlar boş (kullanıcı dolduracak)
    //    - vatRate: 20.0 (varsayılan)
  }

  // Manuel boş satır ekle (barkod olmadan)
  void addManualRow() {
    // Boş BatchEntryRow ekle, status: RowStatus.newProduct
    // Ortak başlıktan vatRate'i miras al
  }

  // Satır güncelle (inline düzenleme)
  void updateRow(String rowId, {
    String? productName,
    String? barcode,
    String? oemNumber,
    String? brandId,
    String? categoryId,
    double? purchasePrice,
    double? salePrice,
    double? vatRate,
    int? quantity,
  })

  // Satır sil
  void removeRow(String rowId)

  // Satır sırasını değiştir (opsiyonel)
  void reorderRow(int oldIndex, int newIndex)

  // Ortak başlık güncelle
  void updateHeader({
    String? supplierId,
    String? invoiceNumber,
    String? deliveryNoteNumber,
    DateTime? purchaseDate,
    String? storeId,
    String? warehouseId,
  })

  // Toplu işlemler
  void applyPriceToAll({double? purchasePrice, double? salePrice})
  void applyVatToAll(double vatRate)
  void applyCategoryToAll(String categoryId, String categoryName)
  void applyBrandToAll(String brandId, String brandName)

  // Validasyon
  String? validateAll() {
    // Her satırı kontrol et:
    // - Yeni ürünlerde ad zorunlu
    // - Fiyat > 0
    // - Miktar > 0
    // - Kategori seçili (yeni ürünlerde)
    // Hata varsa ilk hatayı döndür
  }

  // TOPLU KAYDET
  Future<BatchSaveResult> submitAll() async {
    // 1. validateAll() çağır, hata varsa dur
    // 2. Her satırı sırayla işle:
    //
    //    MEVCUT ÜRÜN (status == existing/matched):
    //    → PurchaseService.createPurchase() ile satın alma kaydı oluştur
    //      (bu otomatik olarak PURCHASE_IN stok hareketi yaratır)
    //    → Eğer fiyat değiştiyse, fiyat güncelleme API çağır
    //
    //    YENİ ÜRÜN (status == newProduct):
    //    → ProductService.createProduct() ile ürün oluştur:
    //      payload: {
    //        "product": { name, sku (auto-generate), categoryId, brand, unit, description },
    //        "variants": [{
    //          "sku": auto-generated,
    //          "name": productName,
    //          "pricing": { purchasePrice, salePrice, vatRate, vatIncluded: true },
    //          "initialStocks": [{ warehouseId, storeId, quantity }],
    //          "barcodes": [{ "code": barcode, "type": "EAN13", "isPrimary": true }]
    //        }],
    //        "purchase": { supplierId, invoiceNumber, purchaseDate, storeId, warehouseId }
    //      }
    //    → Eğer oemNumber varsa, OemService.bulkCreate() ile ekle
    //
    // 3. Sonuç döndür: BatchSaveResult
    // 4. Hata olan satırları status: RowStatus.error yap, errorMessage doldur
    // 5. Başarılı olanları status: RowStatus.saved yap
  }

  // Tabloyu temizle
  void clearAll()
}
```

Provider tanımı service_locator.dart'a ekle:
```dart
final batchEntryProvider = StateNotifierProvider<BatchEntryNotifier, BatchEntryState>((ref) {
  return BatchEntryNotifier(
    ref.read(productServiceProvider),
    ref.read(purchaseServiceProvider),
    ref.read(oemServiceProvider),
    ref.read(supplierServiceProvider),
    ref.read(stockServiceProvider),
  );
});
```

### 3. batch_product_screen.dart

Ana ekran yapısı:

```
Scaffold(
  appBar: AppBar(
    title: "Toplu Ürün Girişi",
    actions: [
      // Tümünü Temizle butonu (onay dialog ile)
      // Toplu İşlem menüsü (PopupMenuButton):
      //   - Tümüne KDV Uygula
      //   - Tümüne Kategori Uygula
      //   - Tümüne Marka Uygula
      //   - Tümüne Alış Fiyatı Uygula
      //   - Tümüne Satış Fiyatı Uygula
    ]
  ),
  body: Column(
    children: [
      // 1. BatchHeaderForm (tedarikçi, fatura, depo - katlanabilir)
      // 2. BarcodeSearchInput (barkod tarama/yazma alanı + "Manuel Ekle" butonu)
      // 3. Expanded → ProductEntryTable (ürün tablosu, scroll edilebilir)
      // 4. BatchSummaryBar (özet + kaydet butonu)
    ]
  )
)
```

### 4. batch_header_form.dart

Katlanabilir panel (ExpansionTile veya AnimatedContainer):

```
Row/Wrap(
  children: [
    // Tedarikçi dropdown (SupplierService.getSuppliers())
    // Fatura No (TextFormField)
    // İrsaliye No (TextFormField, opsiyonel)
    // Fatura Tarihi (DatePicker, varsayılan: bugün)
    // Depo seçimi (WarehouseService.getWarehouses())
    // Mağaza seçimi (StoreService.getStores())
  ]
)
```

Responsive:
- Desktop: tek satırda 6 alan
- Tablet: 2 satırda 3'er alan
- Telefon: dikey liste

İlk açılışta açık, doldurulduktan sonra kullanıcı katla butonuyla küçültebilir (sadece tedarikçi adı ve fatura no görünür).

### 5. barcode_search_input.dart

```
Row(
  children: [
    // Expanded: TextField
    //   - hint: "Barkod tarayın veya ürün adı/kodu yazın..."
    //   - onSubmitted: provider.addByBarcode(value)
    //   - autofocus: true (her kayıt sonrası tekrar odaklan)
    //   - suffixIcon: barkod tarayıcı ikonu → BarcodeScannerScreen aç
    //     (sonuç gelince addByBarcode çağır)
    //
    // SizedBox(width: 8),
    //
    // "Manuel Ekle" butonu → provider.addManualRow()
  ]
)
```

Barkod tarandıktan/yazıldıktan sonra:
- Input temizlenir
- Yeni satır tabloya eklenir (en üste, animasyonlu)
- Input tekrar odaklanır (sürekli tarama için)
- Kısa bir toast gösterilir: "✓ [Ürün Adı] eklendi" veya "Yeni ürün satırı açıldı"

### 6. product_entry_table.dart

DESKTOP/TABLET görünümü (genişlik >= 900):
```
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: DataTable(
    columns: [
      "#",           // Sıra no
      "Durum",       // Rozet: Yeni (turuncu) / Mevcut (yeşil) / Hata (kırmızı) / Kaydedildi (mavi)
      "Barkod",      // Düzenlenebilir (yeni ürünlerde)
      "Ürün Adı",    // Düzenlenebilir (yeni), readonly (mevcut)
      "OEM No",      // Düzenlenebilir
      "Marka",       // Dropdown (BrandService)
      "Kategori",    // Dropdown (CategoryService)
      "Alış ₺",      // Düzenlenebilir sayısal
      "Satış ₺",     // Düzenlenebilir sayısal
      "KDV %",       // Dropdown: 0, 1, 8, 10, 18, 20
      "Adet",        // Düzenlenebilir sayısal (+ / - butonları)
      "Toplam ₺",    // Hesaplanan (salePrice × quantity), readonly
      "İşlem",       // Sil butonu + detay butonu (yeni ürünlerde)
    ],
    rows: state.rows.map((row) => DataRow(...)).toList()
  )
)
```

MOBİL görünümü (genişlik < 900):
```
ListView.builder(
  itemCount: state.rows.length,
  itemBuilder: (context, index) => Card(
    child: ExpansionTile(
      // Başlık: [Durum rozeti] Ürün Adı — Adet × Fiyat = Toplam
      // Genişletilince: tüm alanlar alt alta (TextFormField'lar)
      // Sil butonu
    )
  )
)
```

Inline düzenleme kuralları:
- MEVCUT ürünlerde: ad, marka, kategori READONLY (gri arka plan). Sadece miktar, alış fiyatı, satış fiyatı düzenlenebilir.
- YENİ ürünlerde: tüm alanlar düzenlenebilir. Ad ve kategori zorunlu (boşsa kırmızı border).
- Adet alanında + / - butonları olsun (hızlı artırma için).
- Fiyat alanları number input, Türk Lirası formatında (1.234,56).
- "Detay" butonu → quick_product_dialog açar (sadece yeni ürünlerde, birim, açıklama gibi ek alanlar için).

### 7. quick_product_dialog.dart

Yeni ürün için ek bilgi giriş dialog'u. Tablodaki temel alanların dışında kalan bilgiler:

```
AlertDialog(
  title: "Ürün Detayları — [Ürün Adı]",
  content: SingleChildScrollView(
    child: Column(
      children: [
        // Birim dropdown (UnitService) — varsayılan: Adet
        // Açıklama (TextFormField, 3 satır)
        // Raf konumu (TextFormField)
        // OEM Numaraları (dinamik liste: + ekle / - sil)
        //   Her satır: [OEM No] [Üretici]
        // Çapraz Referanslar (dinamik liste: + ekle / - sil)
        //   Her satır: [Ref Kodu] [Marka]
        // Min stok seviyesi (sayısal)
        // ÖTV oranı (sayısal, opsiyonel)
      ]
    )
  ),
  actions: [
    TextButton("İptal"),
    ElevatedButton("Kaydet"),  // Dialog'u kapatır, satırı günceller
  ]
)
```

### 8. batch_summary_bar.dart

Ekranın en altında sabit bar:

```
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(üst gölge, arka plan rengi),
  child: Row(
    children: [
      // Sol: İstatistik chip'leri
      //   "[12] Ürün"  "[4] Yeni"  "[8] Mevcut"
      //
      // Orta: Tutar bilgileri
      //   "Alış: ₺32.450"  "Satış: ₺45.230"  "Kar: ₺12.780"
      //
      // Sağ: Butonlar
      //   OutlinedButton("Temizle")  // Tüm tabloyu temizle (onay ile)
      //   ElevatedButton("Tümünü Kaydet (12)")  // Sayı badge'i ile
      //     - Disabled: rows boşsa veya header eksikse
      //     - Tıklanınca: onay dialog → submitAll()
      //     - Kayıt sırasında: CircularProgressIndicator
    ]
  )
)

// Mobilde: sadece toplam + kaydet butonu (tek satır)
```

### 9. ROUTER ENTEGRASYONU

lib/core/utils/router.dart'a ekle:
```dart
GoRoute(
  path: '/inventory/batch-entry',
  builder: (context, state) => const BatchProductScreen(),
),
```

lib/screens/menu/menu_screen.dart'ta "Ürün Yönetimi" bölümüne ekle:
```dart
_MenuItem(
  icon: Icons.playlist_add,
  title: 'Toplu Ürün Girişi',
  subtitle: 'Barkod tarayarak hızlı ürün ekle',
  route: '/inventory/batch-entry',
),
```

Sidebar'a da ekle (responsive_layout.dart veya adaptive_sidebar.dart):
"ÜRÜN KATALOĞU" bölümüne → "Toplu Ürün Girişi" menü öğesi.

### 10. KAYIT SONRASI DAVRANIŞLAR

submitAll() başarılı olduktan sonra:
- Sonuç dialog'u göster:
  "✓ 12 ürün başarıyla işlendi
   • 4 yeni ürün oluşturuldu
   • 8 mevcut ürünün stoğu güncellendi
   • Toplam alış: ₺32.450
   [Yeni Giriş Yap]  [Satın Alma Detayına Git]"
- "Yeni Giriş Yap" → ekranı sıfırla (header bilgileri koru, tablo temizle)
- "Satın Alma Detayına Git" → /purchases/detail/:id

Kısmi başarı durumunda:
- Başarılı satırlar yeşil (saved rozeti)
- Hatalı satırlar kırmızı (error rozeti + hata mesajı)
- "X ürün kaydedildi, Y ürün hatalı. Hatalıları düzeltip tekrar deneyin."
- Sadece hatalı satırlar tabloda kalır, başarılılar kaldırılır

### ÖNEMLI KURALLAR
- Hiçbir dosya 350 satırı geçmesin
- Tüm servis çağrıları try-catch içinde olsun
- Loading state'leri düzgün yönetilsin (satır bazlı + genel)
- Riverpod ConsumerStatefulWidget kullan
- AppColors, AppConstants tema sabitlerini kullan
- Türkçe UI metinleri
- Tablet/desktop'ta tablo, telefonda kart listesi (responsive)
- Her satırda ValueKey kullan (performans için)
- Barkod tarandıktan sonra input otomatik temizlensin ve odaklansın
- Mevcut projedeki diğer ekranlarla tutarlı tasarım (aynı kart stili, aynı renk paleti)
- flutter analyze hatasız geçmeli
```

---

## MOD 2: WIZARD'A "KAYDET VE YENİ EKLE" BUTONU

```
project_pos/lib/screens/inventory/add_product_wizard_screen.dart dosyasındaki ürün ekleme sihirbazına "Kaydet ve Yeni Ekle" özelliği ekle. Bu özellik sayesinde bir ürün kaydedildikten sonra form sıfırlanır ve yeni ürüne geçilir, ama sık tekrar eden alanlar (kategori, marka, birim, tedarikçi, depo, KDV oranı) korunur.

### YAPILACAKLAR

1. WizardState'e (veya wizard_state.dart) "retainedFields" yapısı ekle:

```dart
class RetainedFields {
  String? categoryId;
  String? categoryName;
  String? brandId;
  String? brandName;
  String? unitId;
  String? unitName;
  double? vatRate;
  bool? vatIncluded;
  double? specialTaxRate;
  double? withholdingTaxRate;
  String? supplierId;
  String? supplierName;
  String? storeId;
  String? warehouseId;
}
```

2. WizardState'e "saveAndContinue" flag'i ekle:
```dart
bool saveAndContinue = false;
```

3. Mevcut handleSubmit() metodunu güncelle:

```dart
Future<void> handleSubmit({bool andContinue = false}) async {
  // ... mevcut kayıt mantığı ...

  // BAŞARI DURUMUNDA:
  if (andContinue) {
    // 1. Korunacak alanları kaydet
    final retained = RetainedFields(
      categoryId: state.selectedCategoryId,
      categoryName: state.selectedCategoryName,
      brandId: state.selectedBrandId,
      brandName: state.selectedBrandName,
      unitId: state.selectedUnitId,
      unitName: state.selectedUnitName,
      vatRate: state.selectedVatRate,
      vatIncluded: state.vatIncluded,
      specialTaxRate: state.specialTaxRate,
      withholdingTaxRate: state.withholdingTaxRate,
      supplierId: state.supplierId,
      supplierName: state.supplierName,
      storeId: state.selectedStoreId,
      warehouseId: state.selectedWarehouseId,
    );

    // 2. State'i sıfırla
    state.reset();

    // 3. Korunan alanları geri yükle
    state.applyRetainedFields(retained);

    // 4. İlk adıma dön
    setState(() => _currentStep = 0);

    // 5. Başarı mesajı göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ ${productName} kaydedildi. Yeni ürün ekleyebilirsiniz.'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );

    // 6. Kaydedilen ürün sayacını artır
    _savedCount++;

  } else {
    // Mevcut davranış: pop ile geri dön
    Navigator.pop(context, true);
  }
}
```

4. WizardState'e reset() ve applyRetainedFields() metotları ekle:

```dart
void reset() {
  // Tüm TextEditingController'ları temizle
  productNameController.clear();
  skuController.clear();
  basePriceController.text = '0';
  basePurchasePriceController.text = '0';
  descriptionController.clear();
  // Varyantları temizle
  variants.clear();
  // OEM ve çapraz referansları temizle
  oemNumbers.clear();
  crossReferences.clear();
  // Görselleri temizle
  productImages.clear();
  // Diğer state'leri sıfırla
  isVariableProduct = false;
  attributes.clear();
  // ... tüm alanlar
}

void applyRetainedFields(RetainedFields retained) {
  if (retained.categoryId != null) selectedCategoryId = retained.categoryId;
  if (retained.categoryName != null) selectedCategoryName = retained.categoryName;
  if (retained.brandId != null) selectedBrandId = retained.brandId;
  // ... diğer alanlar
  if (retained.vatRate != null) selectedVatRate = retained.vatRate!;
  if (retained.vatIncluded != null) vatIncluded = retained.vatIncluded!;
  // ...
  notifyListeners();
}
```

5. Son adımdaki (Step 4 - Preview) footer butonlarını güncelle:

Mevcut "Kaydet" butonu yanına "Kaydet ve Yeni Ekle" butonu ekle:

```dart
// Footer bölümünde (son adımda):
Row(
  children: [
    // Sol: Geri butonu
    OutlinedButton(
      onPressed: () => setState(() => _currentStep--),
      child: Text('Geri'),
    ),

    Spacer(),

    // Kaydedilen ürün sayacı (eğer > 0 ise)
    if (_savedCount > 0)
      Chip(
        avatar: Icon(Icons.check_circle, color: AppColors.success, size: 18),
        label: Text('$_savedCount ürün kaydedildi'),
        backgroundColor: AppColors.success.withOpacity(0.1),
      ),

    SizedBox(width: 8),

    // Kaydet ve Yeni Ekle butonu
    OutlinedButton.icon(
      onPressed: state.isSaving ? null : () => handleSubmit(andContinue: true),
      icon: Icon(Icons.add_circle_outline),
      label: Text('Kaydet ve Yeni Ekle'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary),
      ),
    ),

    SizedBox(width: 8),

    // Ana Kaydet butonu
    ElevatedButton.icon(
      onPressed: state.isSaving ? null : () => handleSubmit(andContinue: false),
      icon: state.isSaving
        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
        : Icon(Icons.save),
      label: Text('Kaydet ve Kapat'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
      ),
    ),
  ],
)
```

6. _savedCount state değişkeni ekle:

```dart
class _AddProductWizardScreenState extends ConsumerState<AddProductWizardScreen> {
  int _currentStep = 0;
  int _savedCount = 0;  // Bu oturumda kaydedilen ürün sayısı
  // ... mevcut state
}
```

7. AppBar'a kaydedilen ürün sayacı ekle:

```dart
AppBar(
  title: Text(_savedCount > 0
    ? 'Ürün Ekle ($_savedCount kaydedildi)'
    : 'Ürün Ekle'),
  // ... mevcut actions
)
```

8. Ekrandan çıkarken uyarı göster (eğer form doluysa):

```dart
// WillPopScope veya PopScope ile sar:
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;

    // Form boş değilse onay iste
    if (_hasUnsavedChanges()) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Çıkmak istediğinize emin misiniz?'),
          content: Text(
            _savedCount > 0
              ? '$_savedCount ürün kaydedildi. Mevcut formdaki değişiklikler kaybolacak.'
              : 'Formdaki değişiklikler kaybolacak.'
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('İptal')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Çık')),
          ],
        ),
      );
      if (shouldPop == true) Navigator.pop(context, _savedCount > 0);
    } else {
      Navigator.pop(context, _savedCount > 0);
    }
  },
  child: Scaffold(...)
)
```

### KURALLAR
- Mevcut wizard işlevselliğini BOZMA
- Sadece ekleme yap, mevcut kodu minimum değiştir
- "Kaydet ve Yeni Ekle" butonunu sadece son adımda (Preview) göster
- Sıfırlama sonrası SKU otomatik yeni üretilsin
- TextEditingController'ların dispose edilmeden temizlendiğinden emin ol
- Korunan alanların dropdown'ları doğru seçili gelsin (controller + state senkron)
- flutter analyze hatasız geçmeli
```

---

## UYGULAMA SIRASI

1. Önce Mod 2'yi uygula (daha küçük değişiklik, mevcut dosyada)
2. Sonra Mod 1'i uygula (yeni dosyalar, bağımsız ekran)
3. Her ikisini de router ve menüye ekle
4. Test et: flutter analyze
