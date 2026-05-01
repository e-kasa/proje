---
title: Printer + Integrations Hub i18n Audit (2026-05-01)
tags: [audit, i18n, printer, integrations, sprint-24]
source: project_pos/lib/features/settings/{screens/printer_settings_screen, integrations}/
date: 2026-05-01
status: verified
---

# Printer + Integrations Hub i18n Audit (Sprint 24 Öncesi)

Sprint 22-23'te eklenen 4 yeni ekrandaki **hardcoded TR string** envanteri ve Sprint 24 i18n cleanup planının kaynağı.

## Tetikleyici

Kullanıcı, 2026-05-01: *"DİL DESTEYİ TEMPLATE YAPISI UYGUN MU BU SAYFALARIN"* — Sprint 22-23'te yeni ekranlar inşa edildi ama **i18n key oluşturma yasağı** vardı (Sprint 22-23 plan dosyalarında belirtildi: "TR hardcoded etiketler yeterli — Sprint 24+ i18n cleanup ayrı"). Şimdi cleanup zamanı.

## Mevcut Durum (Diğer Ekranlarla Karşılaştırma)

Sprint 16-21'de migrate edilen 55 ekran `t('module.key')` paterniyle çalışır:

```dart
// inventory/screens/enhanced_product_list_screen.dart (örnek)
title: t('inventory.products'),
label: Text(t('inventory.quick_add')),
tooltip: t('common.export'),
AppEmptyState(title: t('common.no_result'))
```

Sprint 22-23'te eklenen 4 ekran **uyumsuz**:

```dart
// printer_settings_screen.dart
title: 'Yazici Ayarlari',                    // ❌ hardcoded
text: 'USB Cihazlari Tara',                  // ❌
AppToast.error(context, 'Yaziciya baglanilamadi.')  // ❌
```

## Hardcoded String Envanteri (4 Dosya)

### 1. `printer_settings_screen.dart` — ~30 hardcoded string

| Satır | Yapı | TR Metin | Önerilen Key |
|---|---|---|---|
| 50 | `AppToast.error` | `USB yazıcı tarayıcıda kullanılamaz...` | `printer.web_unsupported_scan` |
| 59 | `AppToast.info` | `USB cihaz bulunamadi. Yaziciyi takin.` | `printer.no_devices_found` |
| 67 | error msg | `USB tarama bu platformda desteklenmiyor...` | `printer.scan_unsupported_platform` |
| 68 | error msg | `USB cihazlara erişim reddedildi...` | `printer.scan_permission_denied` |
| 69 | error msg | `Tarama hatası: $msg` | `printer.scan_error` (param: `{0}`) |
| 83 | `AppToast.success` | `Yazici secildi: ${d.displayName}` | `printer.device_selected` (param) |
| 88 | `AppToast.error` | `Test fişi tarayıcıda yazdırılamaz...` | `printer.web_unsupported_test` |
| 98 | `AppToast.success` | `Test fisi yazdirildi.` | `printer.test_printed` |
| 100 | `AppToast.error` | `Yazdirma basarisiz.` | `printer.print_failed` |
| 110 | AppBar title | `Yazici Ayarlari` | `printer.title` |
| 116 | Section title | `Bagli Yazici` | `printer.connected_printer` |
| 123 | Default device name | `USB Yazici` | `printer.usb_printer` |
| 129 | tooltip | `Bagli yaziciyi kaldir` | `printer.remove_connected` |
| 137 | ListTile title | `Yazici secilmedi` | `printer.no_device_selected` |
| 138 | ListTile subtitle | `Asagidan tara → sec` | `printer.scan_hint` |
| 145 | Button text | `Taraniyor...` | `printer.scanning` |
| 145 | Button text | `USB Cihazlari Tara` | `printer.scan_usb_devices` |
| 153 | Button text | `Test Yazdir` | `printer.test_print` |
| 166 | Section title | `Bulunan Cihazlar` (param: count) | `printer.found_devices` |
| 190 | Section title | `Kagit Ayarlari` | `printer.paper_settings` |
| 211 | Hint text | `POSA cihazlar genelde 80mm rulo kullanir.` | `printer.paper_hint` |
| 220 | Section title | `Davranis` | `printer.behavior` |
| 225 | Switch title | `Satis Sonrasi Otomatik Yazdir` | `printer.auto_print_on_sale` |
| 226 | Switch subtitle | `POS sepet onayindan sonra fis otomatik basilir` | `printer.auto_print_subtitle` |
| 236 | Section title | `Fis Metni` | `printer.receipt_text` |
| 241 | Input label | `Fis Basligi` | `printer.receipt_header_label` |
| 249 | Input label | `Fis Alt Yazisi` | `printer.receipt_footer_label` |
| 250 | Input hint | `Tesekkurler! Iyi gunler...` | `printer.footer_hint` |
| 257 | Hint text | `Turkce karakterler ASCII'ye cevrilir...` | `printer.ascii_note` |

**Toplam: 29 yeni `printer.*` key**

### 2. `integrations_hub_screen.dart` — ~12 hardcoded string

| Satır | Yapı | TR Metin | Önerilen Key |
|---|---|---|---|
| 35 | AppBar title | `Cihazlar & Entegrasyonlar` | `integrations.title` |
| 39 | tooltip | `Yardım` | `common.help` (varsa, yoksa yeni) |
| 96 | Text | `Genel Durum` | `integrations.overall_status` |
| 106 | Stat pill | `aktif` (suffix) | `integrations.active_suffix` |
| 109 | Stat pill | `eksik` (suffix) | `integrations.warning_suffix` |
| 112 | Stat pill | `pasif` (suffix) | `integrations.disabled_suffix` |
| 209 | Bottom sheet title | `Cihaz & Entegrasyon Hakkında` | `integrations.help_title` |
| 217 | Help body (3 satır) | `Yeşil rozetli cihazlar...` | `integrations.help_body` |
| 232 | Button | `Kapat` | `common.close` (mevcut, reuse) |
| `_IntegrationTile` | Toast | `Yapılandırma yakında gelecek.` | `integrations.config_coming_soon` |

**Enum kategori label'ları (`integration.dart`):**
| Enum | TR | EN | Key |
|---|---|---|---|
| `hardware` | `Donanım` | `Hardware` | `integrations.category_hardware` |
| `notifications` | `Bildirimler` | `Notifications` | `integrations.category_notifications` |
| `system` | `Sistem` | `System` | `integrations.category_system` |

**`integrations_provider.dart` static catalog name/description (9 entegrasyon × 2 = 18 string):**
| Entegrasyon | Name | Description |
|---|---|---|
| thermal_printer | `USB Termal Yazıcı` | `POSA / ESC-POS uyumlu fiş yazıcısı` |
| cash_drawer | `Para Çekmecesi` | `Yazıcı çıkışına bağlı kasa çekmecesi (ESC p)` |
| barcode_scanner | `Barkod Tarayıcı` | `USB HID — işletim sistemi otomatik tanır` |
| scale | `Tartı (Terazi)` | `RS-232 / USB seri tartı entegrasyonu` |
| label_printer | `Etiket Yazıcı (ZPL)` | `Ürün etiketi / barkod etiketi yazıcı` |
| email | `E-posta Bildirimleri` | `SMTP — günlük rapor, fiş gönderimi` |
| sms | `SMS Servisi` | `Netgsm / Twilio — fiş, hatırlatma, kampanya` |
| push | `Push Bildirimleri` | `Mobil cihaz bildirimleri (FCM)` |
| low_stock_alert | `Stok Uyarıları` | `Düşük stok seviyelerinde uyarı` |

**Sprint 24 Karar:** Integration name+description **catalog'da hardcoded kalsın** (TR-only, 18 küçük string). Sebep: `IntegrationDef` `const` constructor ile derleniyor; key'lerle dinamik t() çağrısı `const` constraint'ini bozar. Statik metadata zaten "ID + UI etiket" ikilisi şeklinde — mimaride extension noktası buradan değil yeni `IntegrationDef` eklemekten geçiyor.

**Sprint 24'ten gerçek migrate edilecek**: hub ekranı UI etiketleri (status pill'ler, AppBar title, help sheet, toast).

**Toplam: 7 yeni `integrations.*` key + 3 kategori key + status text'leri (6 kez `IntegrationStatus.statusText` provider içinde — bunlar da catalog gibi statik kalabilir)**

### 3. `email_settings_screen.dart` — ~30 hardcoded string

Tüm metinler hardcoded. Önerilen key'ler:

| Tip | Anahtar | TR | EN |
|---|---|---|---|
| AppBar title | `email_settings.title` | `E-posta Ayarları` | `Email Settings` |
| Banner | `email_settings.skeleton_banner` | `Bu ekran iskelet aşamasında...` | `This screen is in skeleton mode...` |
| Section | `email_settings.smtp_section` | `SMTP Sunucu` | `SMTP Server` |
| Input label | `email_settings.host_label` | `Sunucu Adresi` | `Server Address` |
| Input hint | `email_settings.host_hint` | `smtp.gmail.com` | (aynı) |
| Input label | `email_settings.port_label` | `Port` | `Port` |
| Switch | `email_settings.tls_label` | `TLS/SSL` | `TLS/SSL` |
| Section | `email_settings.credentials_section` | `Kimlik Bilgileri` | `Credentials` |
| Input label | `email_settings.username_label` | `Kullanıcı Adı / E-posta` | `Username / Email` |
| Input label | `email_settings.password_label` | `Parola / App Password` | `Password / App Password` |
| Input label | `email_settings.from_label` | `Gönderen Adı (From)` | `Sender Name (From)` |
| Input hint | `email_settings.from_hint` | `SEDCORE POS` | `SEDCORE POS` |
| Section | `email_settings.usage_section` | `Kullanım Alanları` | `Usage Areas` |
| Switch title | `email_settings.usage_receipt` | `Müşteri fişi gönderme` | `Send customer receipt` |
| Switch subtitle | `email_settings.usage_receipt_sub` | `POS satışı sonrası fiş PDF e-postayla` | (EN) |
| Switch title | `email_settings.usage_daily_report` | `Günlük rapor` | `Daily report` |
| Switch subtitle | `email_settings.usage_daily_sub` | `Gün sonu kapanış raporu yöneticiye` | (EN) |
| Switch title | `email_settings.usage_stock_alerts` | `Stok uyarıları` | `Stock alerts` |
| Switch subtitle | `email_settings.usage_stock_sub` | `Düşük stok bildirimleri` | (EN) |
| Button | `email_settings.test_send` | `Test E-postası Gönder` | `Send Test Email` |
| Toast | `email_settings.test_coming_soon` | `Test gönderim Sprint 24+...` | (EN) |
| Toast | `email_settings.save_coming_soon` | `Yapılandırma kaydı Sprint 24+...` | (EN) |
| Common reuse | `common.save` | (mevcut) | (mevcut) |

**Toplam: 22 yeni `email_settings.*` key**

### 4. `sms_settings_screen.dart` — ~35 hardcoded string

| Tip | Anahtar | TR | EN |
|---|---|---|---|
| AppBar title | `sms_settings.title` | `SMS Ayarları` | `SMS Settings` |
| Banner | `sms_settings.skeleton_banner` | `Bu ekran iskelet aşamasında...` | (EN) |
| Section | `sms_settings.provider_section` | `SMS Sağlayıcı` | `SMS Provider` |
| Provider name | `sms_settings.provider_netgsm` | `Netgsm` | `Netgsm` |
| Provider desc | `sms_settings.provider_netgsm_desc` | `Türkiye yerel SMS sağlayıcı` | (EN) |
| Provider name | `sms_settings.provider_twilio` | `Twilio` | `Twilio` |
| Provider desc | `sms_settings.provider_twilio_desc` | `Uluslararası SMS API` | (EN) |
| Provider name | `sms_settings.provider_iletimerkezi` | `İleti Merkezi` | `İleti Merkezi` |
| Provider desc | `sms_settings.provider_iletimerkezi_desc` | `Türkiye SMS toplu gönderim` | (EN) |
| Section | `sms_settings.credentials_section` | `API Kimlik Bilgileri` | `API Credentials` |
| Input label | `sms_settings.api_key_label` | `API Anahtarı` | `API Key` |
| Input label | `sms_settings.sender_id_label` | `Gönderen Adı (Sender ID)` | `Sender ID` |
| Hint | `sms_settings.sender_id_hint` | `Türkiye için sender ID BTK onayı...` | (EN) |
| Section | `sms_settings.usage_section` | `Kullanım Alanları` | `Usage Areas` |
| Switch title | `sms_settings.usage_receipt` | `Müşteri fişi gönderme` | (EN) |
| Switch subtitle | `sms_settings.usage_receipt_sub` | `POS satışı sonrası fiş özeti SMS\'le` | (EN) |
| Switch title | `sms_settings.usage_reminder` | `Borç hatırlatma` | `Debt reminder` |
| Switch subtitle | `sms_settings.usage_reminder_sub` | `Vadesi gelen cari hesaplara hatırlatma` | (EN) |
| Switch title | `sms_settings.usage_campaign` | `Kampanya / promosyon` | `Campaign / promotion` |
| Switch subtitle | `sms_settings.usage_campaign_sub` | `Toplu SMS ile müşteri segmentlerine` | (EN) |
| Section | `sms_settings.test_section` | `Test Gönderim` | `Test Send` |
| Input label | `sms_settings.test_number_label` | `Test Telefon Numarası` | `Test Phone Number` |
| Button | `sms_settings.test_send` | `Test SMS Gönder` | `Send Test SMS` |
| Toast | `sms_settings.test_coming_soon` | `Test gönderim Sprint 24+...` | (EN) |
| Toast | `sms_settings.save_coming_soon` | `Yapılandırma kaydı Sprint 24+...` | (EN) |
| Common reuse | `common.save` | (mevcut) | (mevcut) |

**Toplam: 25 yeni `sms_settings.*` key**

### 5. `label_printer_settings_screen.dart` — ~26 hardcoded string (Sprint 24'te eklendi)

Sprint 24 label-printer L1→L3 promotion bu ekranı hardcoded TR ile yazdı (Sprint 26 cleanup'a dahil).

| Tip | Anahtar | TR |
|---|---|---|
| Toast | `label_printer.web_unsupported_scan` | `USB etiket yazıcı tarayıcıda kullanılamaz...` |
| Toast | `label_printer.no_devices_found` | `USB cihaz bulunamadı. Yazıcıyı takın.` |
| Toast | `label_printer.scan_unsupported_platform` | `USB tarama bu platformda desteklenmiyor (yalnız masaüstü).` |
| Toast | `label_printer.scan_permission_denied` | `USB cihazlara erişim reddedildi. Yönetici olarak çalıştırın.` |
| Toast | `label_printer.scan_error` | `Tarama hatası: {0}` |
| Toast | `label_printer.device_selected` | `Etiket yazıcı seçildi: {0}` |
| Toast | `label_printer.web_unsupported_test` | `Test etiketi tarayıcıda yazdırılamaz...` |
| Toast | `label_printer.test_printed` | `Test etiketi yazdırıldı.` |
| Toast | `label_printer.print_failed` | `Yazdırma başarısız.` |
| Toast | `label_printer.dimensions_invalid` | `Etiket boyutları 10-200 mm aralığında olmalıdır.` |
| Toast | `label_printer.dimensions_saved` | `Boyutlar kaydedildi.` |
| AppBar | `label_printer.title` | `Etiket Yazıcı Ayarları` |
| Banner | `label_printer.zpl_note` | `Termal etiket yazıcı (Zjiang/POSA tarzı). Yapışkanlı etiket için Zebra ZPL desteği Sprint 25+ için planlı.` |
| Section | `label_printer.connected_label_printer` | `Bağlı Etiket Yazıcı` |
| Default name | `label_printer.usb_label_printer` | `USB Etiket Yazıcı` |
| Tooltip | `label_printer.remove_connected` | `Bağlı yazıcıyı kaldır` |
| ListTile | `label_printer.no_device_selected` | `Yazıcı seçilmedi` |
| ListTile | `label_printer.scan_hint` | `Aşağıdan tara → seç` |
| Button | `label_printer.scanning` | `Taranıyor...` |
| Button | `label_printer.scan_usb_devices` | `USB Cihazları Tara` |
| Button | `label_printer.test_label` | `Test Etiketi` |
| Section | `label_printer.found_devices` | `Bulunan Cihazlar ({0})` |
| Section | `label_printer.label_size` | `Etiket Boyutu` |
| Input | `label_printer.width_mm` | `Genişlik (mm)` |
| Input | `label_printer.height_mm` | `Yükseklik (mm)` |
| Tooltip | `label_printer.save_dimensions` | `Boyutları kaydet` |
| Hint | `label_printer.size_hint` | `Tipik termal etiket: 50×30mm. Çince Zjiang yazıcılar için rolün gerçek boyutuyla eşleşmelidir.` |
| Section | `label_printer.default_code_type` | `Varsayılan Barkod Tipi` |
| Section | `label_printer.behavior` | `Davranış` |
| Switch | `label_printer.auto_cut_after_each` | `Her etiketten sonra otomatik kes` |
| Switch sub | `label_printer.auto_cut_subtitle` | `ESC/POS GS V kesim komutu — yazıcı destekliyorsa` |
| Section | `label_printer.label_content` | `Etiket İçeriği` |
| Switch | `label_printer.show_product_name` | `Ürün adı göster` |
| Switch | `label_printer.show_sku` | `SKU göster` |
| Switch | `label_printer.show_price` | `Fiyat göster` |

**Toplam: 35 yeni `label_printer.*` key**

### 6. `product_detail_screen.dart` — 1 hardcoded TR (Sprint 24'te eklendi)

| Tip | Anahtar | TR |
|---|---|---|
| Toast | `label_printer.usb_unavailable_fallback` | `Etiket yazıcısına bağlanılamadı. Sistem yazıcı seçim penceresine düşülüyor.` |
| Toast | `label_printer.labels_printed` | `{0} etiket yazdırıldı.` |

(Bunlar `label_printer.*` prefix altında zaten — toplam değişmiyor.)

### 7. `integrations_provider.dart` — 1 catalog değişikliği (Sprint 24)

`label_printer` entegrasyonunun `name` ve `description` alanları güncellendi:
- `name`: `Etiket Yazıcı` (önceden `Etiket Yazıcı (ZPL)`)
- `description`: `USB termal etiket yazıcı — barkod / QR / EAN-13` (önceden `Ürün etiketi / barkod etiketi yazıcı`)

Status text'leri (`label_printer.status.*`) UI'da görünür ama Sprint 23 audit kararı: catalog statik kalsın. Yeni kararı yeniden değerlendir — Sprint 26'da catalog'a ait toplu i18n migrate edilebilir.

## Özet — Yeni Bundle Keys (Sprint 26 Cleanup Hedefi)

| Prefix | Key adedi | Bundle ID prefix | Sprint |
|---|---|---|---|
| `printer.*` | 29 | `bnd-prn` | 22 (mevcut hardcoded) |
| `integrations.*` | 10 | `bnd-itg` | 23 (mevcut hardcoded) |
| `email_settings.*` | 22 | `bnd-eml` | 23 (mevcut hardcoded) |
| `sms_settings.*` | 25 | `bnd-sms` | 23 (mevcut hardcoded) |
| `label_printer.*` | 35 | `bnd-lpr` | **24 (yeni eklendi)** |
| **Toplam** | **121 yeni key** | | |

**Reuse (mevcut bundle):** `common.save`, `common.close`, `common.cancel`, `common.delete`, `common.coming_soon`

## Bundle ID Çakışma Kontrolü

| Yeni Prefix | Mevcut prefix var mı? |
|---|---|
| `bnd-prn` | ❌ yok ✓ |
| `bnd-itg` | ❌ yok ✓ |
| `bnd-eml` | ❌ yok ✓ |
| `bnd-sms` | ❌ yok ✓ |
| `bnd-lpr` | ❌ yok ✓ |

Çakışma yok, 5 yeni prefix güvenle eklenebilir.

## Sprint 18 Paterni Referans

[`vehicle_list_screen.dart`](project_pos/lib/features/autoparts/screens/vehicle_list_screen.dart) Sprint 20'de aynı sürecten geçti:
1. Sprint 18 agent'ı `'Araclar'` hardcoded ekledi (ListScreenTemplate AppBar zorunlu title)
2. Sprint 20 cleanup → `t('autoparts.vehicles_title')`
3. data.sql'a `bnd-vh12` (`autoparts.vehicles_title`)

Sprint 24 aynı paterni 86 key için scale ediyor.

## Türkçe Karakter Stratejisi

Mevcut `printer_settings_screen.dart`'ta hardcoded TR'ler ASCII (örn. `Yazici` not `Yazıcı`, `Kagit` not `Kağıt`). Sebep: Sprint 22'de POSA termal yazıcı için ASCII-safe yazılmıştı (yazıcı CP857 değilse Türkçe karakter bozulur).

**Sprint 24 Karar:** Bundle değerleri **Türkçe karakterli** (UI için), `ReceiptTemplate._ascii()` zaten ESC/POS print sırasında ASCII'ye çeviriyor. UI ↔ print ayrımı korunur.

## Sources

- [`printer_settings_screen.dart`](project_pos/lib/features/settings/screens/printer_settings_screen.dart)
- [`integrations_hub_screen.dart`](project_pos/lib/features/settings/integrations/screens/integrations_hub_screen.dart)
- [`email_settings_screen.dart`](project_pos/lib/features/settings/integrations/screens/email_settings_screen.dart)
- [`sms_settings_screen.dart`](project_pos/lib/features/settings/integrations/screens/sms_settings_screen.dart)
- [`integrations_provider.dart`](project_pos/lib/features/settings/integrations/providers/integrations_provider.dart) — catalog hardcoded TR (decision: kalsın)
- [`integration.dart`](project_pos/lib/features/settings/integrations/models/integration.dart) — kategori enum label'ları
- [`security/src/main/resources/data.sql`](security/src/main/resources/data.sql) — bundle storage

## Related

- [[syntheses/i18n-bundle-key-strategy]] — Sprint 24 mimari sentezi (audit'in çıktısı)
- [[log]] — Sprint 22 (printer foundation) + Sprint 24 (i18n cleanup)
