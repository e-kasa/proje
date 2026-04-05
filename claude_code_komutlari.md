# CLAUDE CODE KOMUTLARI - Flutter POS Projesi İyileştirme

Aşağıdaki komutları sırayla Claude Code'a yapıştırarak kullanın.
Her komut bağımsızdır, tek tek verilebilir.

---

## 1. KRİTİK - Environment Konfigürasyonu

```
project_pos/lib/core/constants/app_constants.dart dosyasında baseUrl 'http://localhost:8080/' olarak hardcoded yazılmış. Bunu environment-based konfigürasyona çevir.

Yapılacaklar:
- lib/core/constants/env_config.dart dosyası oluştur
- 3 ortam tanımla: dev (localhost:8080), staging, production
- baseUrl'i --dart-define veya .env dosyasından okuyan bir yapı kur
- app_constants.dart'taki baseUrl'i EnvConfig.baseUrl olarak değiştir
- main.dart'ta ortam seçimini başlangıçta ayarla
- Mevcut tüm ApiClient referanslarının çalışmaya devam ettiğinden emin ol
```

---

## 2. KRİTİK - Print ve Hata Düzeltmeleri

```
project_pos projesinde aşağıdaki kod kalitesi sorunlarını düzelt:

1) Print() kullanımlarını logger ile değiştir:
   - lib/providers/auth_provider.dart satır 49 ve 109
   - lib/providers/theme_provider.dart satır 227 ve 246
   - lib/screens/pos/pos_sales_screen.dart satır 40 ve 53
   Bir logger utility oluştur (lib/core/utils/app_logger.dart) ve tüm print()'leri bununla değiştir.

2) Boş catch bloklarını düzelt:
   - lib/services/product_service.dart satır 227: catch (_) {} → loglama ekle
   - lib/screens/inventory/enhanced_product_list_screen.dart satır 62: catch (_) {} → loglama ekle

3) URL format hatası düzelt:
   - lib/services/product_service.dart satır 158: 'product/api/v1/products$id' → 'product/api/v1/products/$id'
   - Satır 209 ve 226'daki benzer URL hatalarını da kontrol et ve düzelt

4) Tip uyumsuzluğu düzelt:
   - lib/services/stock_service.dart satır 149-161: productId int yerine String (UUID) olmalı
   - lib/providers/data_providers.dart satır 152: int.tryParse(productId) kaldır, String olarak kullan

Her değişiklikten sonra mevcut kodun derlenebildiğinden emin ol.
```

---

## 3. KRİTİK - Test Altyapısı

```
project_pos Flutter projesine test altyapısı kur.

1) pubspec.yaml'a ekle:
   dev_dependencies:
     flutter_test: sdk: flutter
     mockito: ^5.4.4
     build_runner: ^2.4.8
     mocktail: ^1.0.3

2) Test klasör yapısını oluştur:
   test/
   ├── unit/
   │   ├── services/
   │   │   ├── product_service_test.dart
   │   │   ├── sales_service_test.dart
   │   │   └── stock_service_test.dart
   │   └── providers/
   │       └── auth_provider_test.dart
   ├── widget/
   │   └── screens/
   │       └── login_screen_test.dart
   └── helpers/
       ├── mock_api_client.dart
       └── test_helpers.dart

3) mock_api_client.dart: ApiClient'ın mock versiyonunu oluştur (mocktail kullanarak)
4) product_service_test.dart: ProductService için en az 5 test yaz (getProducts, getProductById, createProduct, updateProduct, deleteProduct)
5) auth_provider_test.dart: Login, logout, token refresh testleri yaz
6) login_screen_test.dart: Form validasyonu, buton durumları için widget test yaz

Testlerin hepsinin geçtiğinden emin ol: flutter test
```

---

## 4. KRİTİK - add_product_wizard_screen Refactor

```
project_pos/lib/screens/inventory/add_product_wizard_screen.dart 4758 satır ve çok büyük. Bu dosyayı küçük bileşenlere ayır.

Hedef yapı:
lib/screens/inventory/add_product/
├── add_product_wizard_screen.dart (ana ekran, max 200 satır, stepper kontrolü)
├── steps/
│   ├── basic_info_step.dart (Adım 1: Ürün temel bilgileri formu)
│   ├── variants_step.dart (Adım 2: Varyant yönetimi)
│   ├── stock_barcode_step.dart (Adım 3: Stok ve barkod girişi)
│   ├── oem_crossref_step.dart (Adım 4: OEM ve çapraz referans)
│   └── images_step.dart (Adım 5: Görsel yükleme)
├── widgets/
│   ├── variant_form_card.dart (Tekil varyant formu)
│   ├── pricing_form.dart (Fiyat ve vergi girişi)
│   ├── stock_entry_form.dart (Stok giriş formu)
│   └── barcode_input.dart (Barkod giriş widget)
└── models/
    └── wizard_state.dart (Sihirbaz state modeli)

Kurallar:
- Hiçbir dosya 500 satırı geçmesin
- Mevcut tüm işlevsellik korunsun
- Riverpod state management'ı koru
- Router'daki /inventory/add-product yolu çalışmaya devam etsin
- Adımlar arası veri paylaşımı için wizard_state.dart kullan
- Her adım kendi validasyonunu yapsın
```

---

## 5. YÜKSEK - Gereksiz Dosyaları Temizle

```
project_pos projesinde aşağıdaki gereksiz/duplikat dosyaları temizle:

1) SİL: lib/screens/bulk_import/simplified_bulk_import_screen.dart
   - Nedeni: bulk_import_review_screen_v2.dart aynı işi yapıyor
   - Router'dan /bulk-import/simplified rotasını kaldır

2) SİL: lib/screens/bulk_import/supplier_import_review_table_screen.dart
   - Nedeni: supplier_import_review_screen.dart ile duplikat
   - Router'dan /bulk-import/supplier-table rotasını kaldır

3) SİL: lib/screens/settings/theme_settings_drawer.dart (eğer varsa)
   - Nedeni: theme_settings_drawer_advanced.dart ile duplikat

4) TAŞI: lib/screens/bulk_import/mock_import_data.dart → lib/core/data/mock_import_data.dart
5) TAŞI: lib/screens/bulk_import/simple_mock_data_v2.dart → lib/core/data/simple_mock_data_v2.dart
   - Tüm import referanslarını güncelle

6) Router'dan kaldırılan rotaları temizle
7) Menu screen'deki ilgili menü öğelerini kaldır veya güncelle
8) Projenin hatasız derlenebildiğini doğrula: flutter analyze
```

---

## 6. YÜKSEK - Müşteri/Tedarikçi Ortak Widget'lar

```
project_pos'ta müşteri ve tedarikçi ekranları arasında %70-80 kod tekrarı var. Ortak widget'lar çıkar:

1) lib/core/widgets/entity_list_screen.dart oluştur:
   - Generic EntityListScreen<T> widget'ı
   - Arama, filtre, seçim modu, istatistik kartları, kart listesi ortak pattern'i
   - customer_list_screen.dart ve supplier_list_screen.dart bunu kullansın

2) lib/core/widgets/entity_form_fields.dart oluştur:
   - Ortak form alanları: ad, telefon, email, adres, vergi no, vergi dairesi, tip seçimi, durum toggle
   - add_customer_screen.dart ve add_supplier_screen.dart bunu kullansın

3) lib/core/widgets/account_detail_widget.dart oluştur:
   - Hesap bakiye kartı, işlem listesi, ödeme kaydı butonu ortak yapısı
   - customer_account_detail_screen.dart ve supplier_account_detail_screen.dart bunu kullansın

4) Aynı pattern'i mağaza/depo için de uygula:
   - store_list_screen.dart ve warehouse_list_screen.dart → ortak LocationListScreen
   - add_store_screen.dart ve add_warehouse_screen.dart → ortak form widget'ları

Kurallar:
- Mevcut işlevselliği koru
- Her ekranın özel alanları (müşteriye özel, tedarikçiye özel) korunsun
- Generic type parametreleri kullan
- Tüm ekranların önceki gibi çalıştığını doğrula
```

---

## 7. YÜKSEK - POS Satış Ekranı (Yeniden Yaz)

```
project_pos/lib/screens/pos/pos_sales_screen.dart şu anda sadece ~100 satır mock veri ile çalışmıyor. Tam fonksiyonel bir POS satış ekranı oluştur.

lib/screens/pos/
├── pos_screen.dart (Ana POS ekranı)
├── widgets/
│   ├── product_search_panel.dart (Ürün arama: barkod, isim, kategori)
│   ├── cart_panel.dart (Sepet: ürünler, miktar, fiyat)
│   ├── payment_panel.dart (Ödeme: nakit, kart, havale, çoklu ödeme)
│   ├── cart_item_row.dart (Sepet satır widget'ı)
│   └── category_filter_bar.dart (Kategori hızlı filtre)
└── providers/
    └── pos_provider.dart (POS state yönetimi)

Özellikler:
- Sol panel: Ürün arama (barkod tarama, isim arama, kategori filtre)
- Sağ panel: Sepet (ürün listesi, miktar +/-, indirim, toplam)
- Alt kısım: Ödeme butonları (Nakit, Kredi Kartı, Havale)
- Ödeme modalı: Tutar giriş, para üstü hesaplama, çoklu ödeme desteği
- Barkod tarayıcı entegrasyonu (mevcut BarcodeScannerScreen'i kullan)
- Müşteri seçimi (opsiyonel, veresiye satış için)
- Satış tamamlandığında backend'e kaydet (SalesService kullan)
- Responsive: tablet yatay modda iki panel, telefonda tab geçişli

Backend entegrasyonu:
- Ürün listesi: ProductService.getProducts()
- Satış kayıt: SalesService.createSale()
- Stok güncelleme: Otomatik (backend tarafında)
- Müşteri seçimi: CustomerService.getCustomers()

Router'da mevcut /pos rotasını yeni ekrana yönlendir.
```

---

## 8. YÜKSEK - Satış Detay ve Liste Ekranları

```
project_pos'ta satış geçmişi ekranları eksik. Aşağıdaki ekranları oluştur:

1) lib/screens/sales/sale_list_screen.dart:
   - Satış listesi: tarih, müşteri, tutar, durum
   - Filtreler: tarih aralığı, müşteri, ödeme durumu (ödendi/veresiye/iptal)
   - Arama: satış numarası, müşteri adı
   - Kart tabanlı liste (purchase_list_screen.dart'ı referans al)
   - FAB: Yeni satış → /pos

2) lib/screens/sales/sale_detail_screen.dart:
   - Satış detay görünümü (purchase_detail_screen.dart pattern'ini kullan)
   - Başlık: Satış numarası, tarih, müşteri bilgisi
   - Ürün listesi: ürün adı, miktar, birim fiyat, toplam
   - Ödeme bilgisi: toplam, ödenen, kalan
   - İptal butonu (onay ile)
   - İade butonu → sale_return_screen'e yönlendir

3) Router'a ekle:
   - /sales → SaleListScreen (mevcut sales_screen.dart'ı değiştir)
   - /sales/detail/:id → SaleDetailScreen

4) SalesService'teki mevcut metotları kullan: getSales(), getSaleById(), cancelSale()

Stil olarak purchase_list_screen.dart ve purchase_detail_screen.dart ile tutarlı ol.
```

---

## 9. YÜKSEK - İade Ekranları

```
project_pos'ta satış iade ve satın alma iade ekranları yok. Oluştur:

1) lib/screens/sales/sale_return_screen.dart:
   - Satış seçimi veya satış ID ile açılır
   - İade edilecek ürünleri seç (checkbox + miktar)
   - İade nedeni seçimi (dropdown: hasarlı, yanlış ürün, müşteri iadesi, diğer)
   - İade notu (text alanı)
   - Toplam iade tutarı hesaplama
   - Onaylandığında: SalesService üzerinden iade kaydı
   - Stok hareketi: SALE_RETURN_IN otomatik

2) lib/screens/purchases/purchase_return_screen.dart:
   - Satın alma seçimi veya purchase ID ile açılır
   - İade edilecek ürünleri seç (checkbox + miktar)
   - İade nedeni (hasarlı, yanlış sevk, kalite sorunu, diğer)
   - Toplam iade tutarı
   - Onaylandığında: PurchaseService üzerinden iade kaydı
   - Stok hareketi: PURCHASE_RETURN_OUT otomatik

3) Router'a ekle:
   - /sales/return/:saleId → SaleReturnScreen
   - /purchases/return/:purchaseId → PurchaseReturnScreen

4) İlgili detay ekranlarına "İade" butonu ekle
```

---

## 10. YÜKSEK - Stok Transfer Oluşturma

```
project_pos'ta stok transfer inceleme (stock_transfer_review_screen.dart) var ama transfer oluşturma ekranı yok. Oluştur:

lib/screens/stock/stock_transfer_screen.dart:
- Kaynak depo/mağaza seçimi (dropdown)
- Hedef depo/mağaza seçimi (dropdown)
- Ürün ekleme: barkod tarama veya arama
- Ürün listesi: ürün adı, mevcut stok, transfer miktarı
- Toplam ürün ve miktar özeti
- Transfer notu
- Onayla butonu → StockService.createTransfer()
- Başarı sonrası stock_transfer_review_screen'e yönlendir

Router'a ekle: /stock/transfer → StockTransferScreen
Menu screen'e ve sidebar'a ekle.
```

---

## 11. YÜKSEK - Mock Servisleri API'ye Bağla

```
project_pos'ta aşağıdaki servisler hala mock veri kullanıyor. API entegrasyonunu yap:

1) lib/services/finance_service.dart (494 satır, useMockData = true):
   - Expense CRUD: POST/GET/PUT/DELETE /api/finance/expenses
   - Revenue CRUD: POST/GET/PUT/DELETE /api/finance/revenues
   - Summary: GET /api/finance/summary
   - Mock metotları sil, gerçek API çağrılarıyla değiştir
   - Hata yönetimi ekle (try-catch + kullanıcıya mesaj)

2) lib/services/report_service.dart (309 satır, useMockData = true):
   - Dashboard stats: GET /api/reports/dashboard
   - Sales summary: GET /api/reports/sales-summary
   - Inventory report: GET /api/reports/inventory
   - Mock metotları sil, gerçek API çağrılarıyla değiştir

3) lib/services/hrm_service.dart (298 satır, useMockData = true):
   - Employee CRUD: /api/hrm/employees
   - Department list: /api/hrm/departments
   - Mock metotları sil, gerçek API çağrılarıyla değiştir

4) lib/services/auth_service.dart (useMockData = true):
   - useMockData = false yap
   - Mock login bloğunu kaldır

Her serviste useMockData flag'ini false yap veya kaldır.
Backend endpoint'leri mevcut değilse, serviste TODO yorum bırak.
```

---

## 12. YÜKSEK - Kullanıcı ve Firma Yönetimi

```
project_pos'ta kullanıcı yönetimi ve firma ayarları ekranları eksik. Backend'de UserDef, RoleDef, Company entity'leri mevcut. Ekranları oluştur:

1) lib/screens/settings/user_management_screen.dart:
   - Kullanıcı listesi (ad, email, rol, durum)
   - Kullanıcı ekleme/düzenleme modalı
   - Rol atama
   - Durum toggle (aktif/pasif)
   - API: security modülündeki UserDef endpoint'leri

2) lib/screens/settings/company_settings_screen.dart:
   - Firma adı, vergi no, vergi dairesi
   - Logo yükleme
   - Varsayılan para birimi
   - Fatura ayarları (seri no prefix, KDV oranı)
   - API: Company entity endpoint'leri

3) lib/services/user_service.dart oluştur:
   - getUsers(), createUser(), updateUser(), toggleUserStatus()
   - getRoles(), assignRole()

4) Router'a ekle:
   - /settings/users → UserManagementScreen
   - /settings/company → CompanySettingsScreen

5) Settings ekranındaki placeholder butonları bu ekranlara yönlendir
```

---

## 13. ORTA - Eksik Rapor Ekranlarını Tamamla

```
project_pos'ta aşağıdaki rapor ekranları yarım kalmış. Tamamla:

1) lib/screens/reports/product_sales_analysis_screen.dart:
   - Tarih aralığı seçimi
   - Ürün bazlı satış sıralaması (en çok satan → en az)
   - Her ürün kartında: satış adedi, toplam ciro, ortalama fiyat, kar marjı
   - İlk 3'e altın/gümüş/bronz rozet
   - SalesReportService.getProductAnalysis() kullan

2) lib/screens/reports/profit_overview_screen.dart:
   - Tarih aralığı seçimi
   - Toplam gelir, toplam gider, net kar kartları
   - Kar marjı yüzdesi
   - Aylık trend grafiği (fl_chart kullan)
   - Kategori bazlı kar dağılımı
   - ReportService kullan

3) lib/screens/reports/sales_summary_screen.dart:
   - Günlük/haftalık/aylık toggle
   - Satış adet, ciro, ortalama sepet tutarı
   - Ödeme yöntemine göre dağılım
   - Grafik görselleştirme

4) lib/screens/reports/reports_screen.dart:
   - TODO olan export fonksiyonunu ekle (PDF veya Excel olarak dışa aktar)

customer_sales_analysis_screen.dart'ı stil referansı olarak kullan.
```

---

## 14. ORTA - Finans Ekranları Tamamlama

```
project_pos'ta gider ekranı var ama gelir ve ödeme ekranları eksik. Oluştur:

1) lib/screens/finance/add_income_screen.dart:
   - add_expense_screen.dart'ı referans al, aynı pattern
   - Tutar, kategori, durum, ödeme yöntemi, açıklama
   - Gelir kategorileri: Satış, Hizmet, Kira, Diğer
   - FinanceService.createRevenue() kullan

2) lib/screens/finance/payment_list_screen.dart:
   - Tüm ödeme/tahsilatların merkezi listesi
   - Filtre: tip (ödeme/tahsilat), tarih, müşteri/tedarikçi
   - Kart: tutar, tarih, ilgili kişi, ödeme yöntemi, referans no
   - PaymentService kullan (yoksa oluştur)

3) lib/screens/finance/cash_flow_screen.dart:
   - Dönem seçimi (günlük/haftalık/aylık)
   - Giriş-çıkış karşılaştırma
   - Net nakit akışı grafiği (fl_chart)
   - Detaylı tablo

Router'a ekle ve finance_dashboard_screen'deki butonları yönlendir.
```

---

## 15. ORTA - Theme Provider Düzeltme

```
project_pos/lib/providers/theme_provider.dart'ta tema ayarları pipe-delimited string olarak SharedPreferences'a kaydediliyor (satır 188-223). Bu kırılgan ve hata eğilimli. JSON serileştirmeye çevir:

1) ThemeSettings sınıfına toJson() ve fromJson() metotları ekle
2) _saveSettings() metodunu jsonEncode kullanacak şekilde güncelle
3) _loadSettings() metodunu jsonDecode kullanacak şekilde güncelle
4) Eski pipe-delimited format ile geriye uyumluluğu koru (migration):
   - Eğer SharedPreferences'ta eski format varsa, oku ve JSON'a çevir
   - Yeni kayıtlar her zaman JSON olsun
5) Hata durumunda varsayılan tema ayarlarına dön (print yerine logger kullan)
```

---

## 16. ORTA - Supplier Upload TODO'ları

```
project_pos/lib/screens/supplier_upload/ klasöründe birçok TODO var. Bunları tamamla:

1) supplier_upload_wizard_screen.dart satır 590: "TODO: Backend'e gönder"
   - BulkImportService veya SupplierService üzerinden dosya yükleme API çağrısı ekle
   - Yükleme progress göster
   - Başarı/hata durumunu kullanıcıya bildir

2) supplier_file_upload_screen.dart satır 70: "TODO: Backend'e dosya yükle"
   - Multipart file upload implementasyonu
   - ApiClient.upload() metodu yoksa ekle

3) file_preview_screen.dart satır 28: "TODO: Backend'e analiz isteği gönder"
   - Dosya analiz API çağrısı
   - Sonuçları tabloda göster

4) decision_table_screen.dart satır 64 ve 104: "TODO: Varyant formu, Backend'e kaydet"
   - Expansion panel ile varyant düzenleme formu
   - Kaydet butonu ile backend'e gönderme

Eğer backend endpoint'leri mevcut değilse, servis metodunu yazıp içine TODO yorum bırak.
```

---

## 17. ORTA - Product Detail TODO'ları

```
project_pos/lib/screens/inventory/product_detail_screen.dart'taki TODO'ları tamamla:

1) Satır 199: "TODO: Navigate to edit screen"
   - Düzenle butonuna tıklandığında /inventory/add-product?id={productId} rotasına yönlendir
   - AddProductWizardScreen'in edit modunu desteklediğinden emin ol

2) Satır 574: "TODO: Add OEM number dialog"
   - OEM numarası ekleme dialog'u oluştur
   - Form: OEM numarası, üretici adı
   - OemService.addOemNumber() çağrısı
   - Ekleme sonrası listeyi yenile

3) Satır 692: "TODO: Add cross reference dialog"
   - Çapraz referans ekleme dialog'u oluştur
   - Form: referans kodu, marka, açıklama
   - CrossReferenceService.addCrossReference() çağrısı
   - Ekleme sonrası listeyi yenile
```

---

## 18. DÜŞÜK - Dokümantasyon

```
project_pos projesinin ana dosyalarına dartdoc dokümantasyonu ekle:

1) lib/services/ altındaki tüm servis dosyalarına:
   - Sınıf açıklaması (/// ile)
   - Her public metoda açıklama, parametreler, dönüş tipi
   - Örnek: /// Ürünleri listeler. [page] ve [limit] ile sayfalama destekler.

2) lib/providers/ altındaki tüm provider dosyalarına:
   - Provider amacı
   - State yapısı açıklaması

3) lib/core/api/api_client.dart:
   - Interceptor açıklamaları
   - Token yenileme akışı açıklaması

4) lib/core/utils/validation_helper.dart:
   - Her validasyon metoduna açıklama ve örnek

Dil: Türkçe (proje Türkçe olduğu için)
```

---

## UYGULAMA SIRASI ÖNERİSİ

1. Komut 1 (env config) → 2 (hata düzeltme) → 5 (temizlik) → Derleme testi
2. Komut 3 (test altyapısı)
3. Komut 4 (wizard refactor) → 6 (ortak widget) → Derleme testi
4. Komut 7 (POS) → 8 (satış ekranları) → 9 (iade) → 10 (transfer)
5. Komut 11 (mock→API) → 12 (kullanıcı yönetimi)
6. Komut 13 (raporlar) → 14 (finans) → 15 (theme) → 16-17 (TODO'lar)
7. Komut 18 (dokümantasyon)
