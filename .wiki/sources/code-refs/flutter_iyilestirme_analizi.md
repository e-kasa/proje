---
title: Flutter İyileştirme Analizi
type: source
source: flutter_iyilestirme_analizi.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# FLUTTER POS PROJESİ - İYİLEŞTİRME ANALİZ RAPORU

**Proje:** project_pos (Flutter POS & Envanter Yönetim Sistemi)
**Tarih:** 5 Nisan 2026
**Toplam Dart Dosyası:** 188
**Toplam Satır:** 69.904
**Ortalama Dosya Boyutu:** 371 satır

---

## 1. PROJE YAPISI ÖZETİ

### Mimari
- State Management: Flutter Riverpod (StateNotifier pattern)
- Navigation: GoRouter (auth-based redirect)
- API: Dio (JWT interceptor, token refresh)
- Local DB: SQLite (sqflite)
- UI: Material 3, responsive layout (sidebar + bottom nav)

### Modül Dağılımı
- screens/: 73 ekran dosyası (30 klasör)
- services/: 30 servis dosyası
- models/: 13 model dosyası
- providers/: 4 provider dosyası
- core/widgets/: 14 ortak bileşen
- core/: API, theme, layout, utils

---

## 2. GEREKSİZ EKRANLAR (Silinmesi / Kaldırılması Önerilen)

| # | Dosya | Neden | Öneri |
|---|-------|-------|-------|
| 1 | mock_import_data.dart | Ekran değil, veri dosyası. screens/ klasöründe olmamalı | core/data/ klasörüne taşı |
| 2 | simple_mock_data_v2.dart | Ekran değil, veri dosyası. screens/ klasöründe olmamalı | core/data/ klasörüne taşı |
| 3 | simplified_bulk_import_screen.dart | bulk_import_review_screen_v2 ile aynı işi yapıyor. Eski versiyon | Sil, v2 kullan |
| 4 | supplier_import_review_table_screen.dart | supplier_import_review_screen ile neredeyse aynı, sadece tablo görünümü farklı | review_screen'e tab olarak ekle |
| 5 | theme_settings_drawer.dart | theme_settings_drawer_advanced.dart ile çok benzer | Tek drawer'da birleştir |
| 6 | inventory_screen.dart | Sadece 153 satır konteyner ekran. Router zaten yönlendirme yapıyor | Kaldır, doğrudan product list'e yönlendir |
| 7 | success_screen.dart | Sadece basit başarı mesajı. Genel bir widget olabilir | core/widgets/ altına taşı |
| 8 | supplier_file_upload_screen.dart | supplier_upload_wizard_screen ile çakışıyor. Backend yok | Wizard'a entegre et veya sil |
| 9 | pos_sales_screen.dart | ~1250 satır ama mock veriye dayalı, gerçek POS işlevi eksik | sales_screen ile birleştir veya tamamen yeniden yaz |
| 10 | sales_screen.dart | Erken aşamada, fonksiyonel değil. POS screen ile isim çakışması | pos_sales_screen ile birleştir |

**Toplam: 10 gereksiz dosya**

---

## 3. BENZER EKRANLAR (Birleştirme / Refactor Potansiyeli)

| # | Grup | Ekran 1 | Ekran 2 | Benzerlik | Öneri |
|---|------|---------|---------|-----------|-------|
| 1 | Satış Ekranları | pos_sales_screen.dart | sales_screen.dart | Her ikisi de satış ekranı, ikisi de eksik | Tek SalesScreen + ayrı POS modülü |
| 2 | Tema Ayarları | theme_settings_drawer.dart | theme_settings_drawer_advanced.dart | İkisi de tema seçimi yapıyor | Tek drawer, toggle ile gelişmiş mod |
| 3 | Toplu Import | bulk_import_review_screen_v2.dart | simplified_bulk_import_screen.dart | Aynı inceleme/onaylama işlevi | v2 kullan, simplified sil |
| 4 | Tedarikçi Import | supplier_import_review_screen.dart | supplier_import_review_table_screen.dart | Kart vs tablo görünümü, aynı veri | Tek ekranda kart/tablo geçişi |
| 5 | Tedarikçi Yükleme | supplier_file_upload_screen.dart | supplier_import_upload_screen.dart | Her ikisi de dosya yükleme | Tek yükleme ekranı |
| 6 | Müşteri/Tedarikçi Liste | customer_list_screen.dart | supplier_list_screen.dart | %80 kod tekrarı: arama, filtre, kart | Ortak BaseEntityListScreen çıkar |
| 7 | Müşteri/Tedarikçi Ekle | add_customer_screen.dart | add_supplier_screen.dart | Benzer form alanları | Ortak form widget'ları çıkar |
| 8 | Müşteri/Tedarikçi Hesap | customer_account_detail_screen.dart | supplier_account_detail_screen.dart | Aynı hesap detay yapısı | Ortak AccountDetailWidget |
| 9 | Mağaza/Depo Liste | store_list_screen.dart | warehouse_list_screen.dart | Benzer istatistik, arama, CRUD | Ortak LocationListScreen |
| 10 | Mağaza/Depo Ekle | add_store_screen.dart | add_warehouse_screen.dart | Benzer form yapısı | Ortak form widget'ları |
| 11 | Mock Veri | mock_import_data.dart | simple_mock_data_v2.dart | İkisi de import için mock veri | Tek dosyada birleştir |
| 12 | Tedarikçi Wizard | supplier_upload_wizard_screen.dart | supplier_file_upload_screen.dart | İkisi de yükleme akışı | Wizard kullan, diğerini sil |

**Toplam: 12 benzer grup, tahmini %30-40 kod tekrarı azaltılabilir**

---

## 4. OLMASI GEREKEN EKRANLAR

### KRİTİK ÖNCELİK
| # | Modül | Ekran | Açıklama | Backend |
|---|-------|-------|----------|---------|
| 1 | Satış | pos_screen.dart (TAM POS) | Tam fonksiyonel POS: ürün arama, sepet, ödeme, fiş. Mevcut pos_sales_screen mock veriye dayalı | Sale entity mevcut |
| 2 | Fatura | invoice_screen.dart | Fatura oluşturma/görüntüleme. e-Fatura desteği | Yeni entity gerekli |

### YÜKSEK ÖNCELİK
| # | Modül | Ekran | Açıklama | Backend |
|---|-------|-------|----------|---------|
| 3 | Satış | sale_detail_screen.dart | Satış detay görünümü (fatura, ürünler, ödeme) | Sale entity mevcut |
| 4 | Satış | sale_list_screen.dart | Satış geçmişi listesi, filtreler, arama | SaleService mevcut |
| 5 | Satış | sale_return_screen.dart | Satış iade işlemi | SALE_RETURN_IN mevcut |
| 6 | Fatura | invoice_list_screen.dart | Fatura listesi ve arama | Yeni entity gerekli |
| 7 | Satın Alma | purchase_return_screen.dart | Tedarikçiye iade, stok çıkışı | PURCHASE_RETURN_OUT mevcut |
| 8 | Stok | stock_transfer_screen.dart | Depolar arası transfer oluşturma | StockTransfer mevcut |
| 9 | Stok | stock_count_screen.dart | Stok sayım başlatma | Kısmen mevcut |
| 10 | Finans | add_income_screen.dart | Gelir kaydı ekleme (gider var, gelir yok) | Kısmen mevcut |
| 11 | Finans | payment_list_screen.dart | Tüm ödeme/tahsilat listesi | Payment entity mevcut |
| 12 | Araç | oem_cross_reference_screen.dart | OEM ve çapraz referans yönetimi | Entity mevcut |
| 13 | Sistem | company_settings_screen.dart | Firma ayarları: logo, vergi bilgileri | Company entity mevcut |
| 14 | Sistem | user_management_screen.dart | Kullanıcı/rol yönetimi | UserDef, RoleDef mevcut |

### ORTA ÖNCELİK
| # | Modül | Ekran | Açıklama | Backend |
|---|-------|-------|----------|---------|
| 15 | Satış | quick_sale_screen.dart | Hızlı satış / barkod ile satış (mobil) | Mevcut |
| 16 | Müşteri | customer_detail_screen.dart | Müşteri detay: iletişim, geçmiş, bakiye | Mevcut |
| 17 | Tedarikçi | supplier_detail_screen.dart | Tedarikçi detay: alım geçmişi, bakiye | Mevcut |
| 18 | Finans | cash_flow_screen.dart | Nakit akışı raporu | Kısmen |
| 19 | Rapor | supplier_purchase_analysis_screen.dart | Tedarikçi bazlı alım analizi | Mevcut |
| 20 | Rapor | stock_report_screen.dart | Kapsamlı stok raporu, ABC analizi | Mevcut |
| 21 | Rapor | daily_summary_screen.dart | Günlük özet raporu | Mevcut |
| 22 | HRM | add_employee_screen.dart | Çalışan ekleme/düzenleme formu | HrmService mevcut |
| 23 | Araç | vehicle_add_screen.dart | Araç ekleme tam ekran formu (dialog yerine) | Mevcut |
| 24 | Bildirim | notifications_screen.dart | Bildirim merkezi | Yeni yapı gerekli |

### DÜŞÜK ÖNCELİK
| # | Modül | Ekran | Açıklama | Backend |
|---|-------|-------|----------|---------|
| 25 | HRM | employee_detail_screen.dart | Çalışan detay, performans, izin | Kısmen |
| 26 | Sistem | backup_restore_screen.dart | Yedekleme ve geri yükleme | Yeni yapı gerekli |
| 27 | Sistem | audit_log_screen.dart | İşlem geçmişi ve log takibi | Yeni yapı gerekli |
| 28 | Sistem | printer_settings_screen.dart | Yazıcı/fiş yazıcı ayarları | Yeni yapı gerekli |

---

## 5. KOD KALİTESİ ANALİZİ

### 5.1 Büyük Dosyalar (>500 satır) - Refactor Gerekli
| Dosya | Satır | Durum |
|-------|-------|-------|
| add_product_wizard_screen.dart | 4.758 | KRİTİK - Parçalara ayrılmalı |
| bulk_import_review_screen_v2.dart | 2.458 | KRİTİK - Widget'lara bölünmeli |
| pos_sales_screen.dart | 1.250 | YÜKSEK - Mock veri temizlenmeli |
| bulk_import_models.dart | 1.122 | ORTA - Model dosyaları ayrılmalı |
| add_supplier_screen.dart | 1.086 | YÜKSEK - Form bölümleri widget'a çıkarılmalı |
| supplier_import_review_screen.dart | 948 | ORTA |
| supplier_upload_wizard_screen.dart | 915 | ORTA |
| add_purchase_screen.dart | 906 | ORTA |
| product_detail_screen.dart | 900 | ORTA |
| modern_dashboard_screen.dart | 866 | ORTA |

### 5.2 TODO/FIXME Yorumları (9 adet)
- bulk_import_review_screen_v2.dart: 4 TODO (modal implementasyonları)
- decision_table_screen.dart: 1 TODO (backend endpoint)
- file_preview_screen.dart: 1 TODO (backend endpoint)
- supplier_file_upload_screen.dart: 1 TODO (backend endpoint)
- supplier_upload_wizard_screen.dart: 1 TODO (backend endpoint)
- quick_add_product_modal.dart: 1 TODO (barkod tarama)

### 5.3 Mock Data Durumu
| Servis | useMockData | Durum |
|--------|-------------|-------|
| bulk_import_service.dart | true | Mock aktif - backend entegrasyonu gerekli |
| finance_service.dart | true | Mock aktif - API bağlantısı gerekli |
| report_service.dart | true | Mock aktif - API bağlantısı gerekli |
| hrm_service.dart | true | Mock aktif - API bağlantısı gerekli |
| product_service.dart | false | API bağlı |
| sales_service.dart | false | API bağlı |
| stock_service.dart | false | API bağlı |
| customer_service.dart | false | API bağlı |
| supplier_service.dart | false | API bağlı |
| purchase_service.dart | false | API bağlı |

### 5.4 Güvenlik ve Yapılandırma
- baseUrl: env_config.dart ile yönetiliyor (dev/staging/prod)
- JWT token: SharedPreferences'da saklanıyor
- API interceptor: 401 durumunda token refresh
- Hardcoded şifre/key: Bulunamadı (İYİ)

### 5.5 Test Durumu
- test/ klasörü: VAR ama sadece placeholder widget test
- Unit test: YOK
- Widget test: YOK (anlamlı)
- Integration test: YOK
- DURUM: KRİTİK EKSİKLİK

---

## 6. İYİLEŞTİRME ÖNERİLERİ

### 6.1 Mimari İyileştirmeler
1. add_product_wizard_screen.dart (4758 satır) widget'lara parçalanmalı: her wizard adımı ayrı widget
2. Müşteri/Tedarikçi ekranları için ortak BaseEntityListScreen, BaseEntityFormScreen, BaseAccountDetailScreen oluşturulmalı
3. Mağaza/Depo ekranları için ortak LocationManagementScreen pattern'i çıkarılmalı
4. Mock data dosyaları screens/ klasöründen core/data/ klasörüne taşınmalı
5. success_screen.dart gibi genel bileşenler core/widgets/ altına alınmalı

### 6.2 Kod Kalitesi
1. print() ifadeleri kaldırılmalı, logger paketi kullanılmalı
2. Boş catch blokları düzeltilmeli (en az log yazılmalı)
3. TODO yorumları tamamlanmalı veya issue'ya dönüştürülmeli
4. Hardcoded Türkçe string'ler lokalizasyon dosyasına alınmalı
5. 500+ satır dosyalar refactor edilmeli

### 6.3 Eksik Özellikler (Öncelik Sırasıyla)
1. KRİTİK: Tam fonksiyonel POS satış ekranı
2. KRİTİK: Fatura sistemi (e-Fatura desteği)
3. YÜKSEK: Satış detay ve iade ekranları
4. YÜKSEK: Stok transfer oluşturma ekranı
5. YÜKSEK: Kullanıcı ve rol yönetimi
6. YÜKSEK: Gelir kaydı ve ödeme listesi
7. ORTA: Müşteri/tedarikçi detay sayfaları
8. ORTA: Rapor ve analiz ekranları
9. DÜŞÜK: Bildirim, yedekleme, yazıcı ayarları

### 6.4 Test Stratejisi
1. Unit test: Tüm servisler için (öncelik: product, sales, stock)
2. Widget test: Kritik form ekranları için
3. Integration test: POS satış akışı, satın alma akışı
4. Mockito ve test paketleri pubspec.yaml'a eklenmeli

### 6.5 Performans
1. Büyük listelerde pagination doğru kullanılmalı (pageSize: 20 tanımlı)
2. cached_network_image tüm resim yüklemelerinde kullanılmalı
3. Debounce (400ms) tüm arama alanlarında uygulanmalı
4. Riverpod family provider'lar ile gereksiz rebuild önlenmeli

---

## 7. İSTATİSTİK ÖZETİ

| Metrik | Değer |
|--------|-------|
| Toplam Dart Dosyası | 188 |
| Toplam Kod Satırı | 69.904 |
| Toplam Ekran | 73 |
| Tamamlanmış Ekran | 52 |
| Kısmen Tamamlanmış | 6 |
| Eksik/Çalışmayan | 5 |
| Gereksiz Ekran | 10 |
| Benzer Ekran Grubu | 12 |
| Olması Gereken Ekran | 28 |
| Servis Sayısı | 30 |
| Mock Aktif Servis | 4 |
| API Bağlı Servis | 16+ |
| TODO Sayısı | 9 |
| Test Dosyası | 1 (placeholder) |
| 500+ Satır Dosya | 39 |
| 1000+ Satır Dosya | 5 |
