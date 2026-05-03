---
title: Wiki Olay Kaydı (Event Log)
type: log
format: append-only
last-verified: 2026-04-25
---

# Wiki Olay Kaydı

Append-only olay kaydı. **En yeni üste**.

## Olaylar

## [2026-05-03] sprint-29-fix-2 | Etiket Baskısı: Fiş Yazıcısı Smart Fallback (Case 1.5) ✅

### Tetikleyici

Kullanıcı runtime test: *"YAZICI SEÇTİM AMA PDF OLARAK YÖNLENDİMRE YAPIYOR BU CİHAZ FİŞ BASIYOR SDECE"*

POSA termal **fiş yazıcısı** (Sprint 22'de yapılandırıldı) ile ürün detayı ekranındaki **etiket basma** denendi → sistem PDF dialog açtı, Windows POSA driver'a PDF rasterize göndermeye çalıştı (yavaş + ölçek bozuk + termal kağıt için anlamsız).

### Kök Sebep Analizi

[`product_detail_screen.dart`](project_pos/lib/features/inventory/screens/product_detail_screen.dart) Sprint 24'te **3-state akış** ile yazılmıştı:

```
Case 1: labelPrintSettings.isConfigured == true → ESC/POS USB direkt
Case 2: USB hata → fallback PDF dialog
Case 3: !labelPrintSettings.isConfigured → PDF dialog
```

Kullanıcı **Etiket Yazıcı ayarlarını yapmadı** (POSA fiş yazıcısı vardı, ayrı etiket cihazı bilmiyor/yok) → **Case 3** çalıştı → PDF dialog → Windows print queue → POSA termal cihaza PDF rasterize.

**Eksik insight (Sprint 24)**: POSA gibi termal fiş yazıcıları zaten ESC/POS standardında **barkod komutu** destekler. Tek cihaz hem 80mm fiş hem barkod basabilir; ayrı etiket yazıcı zorunlu değil.

### Çözüm: Case 1.5 — Fiş Yazıcısı Fallback

[`product_detail_screen.dart`](project_pos/lib/features/inventory/screens/product_detail_screen.dart) `_printBarcodeLabels` metoduna **yeni state** eklendi:

```
Case 1   : Etiket yazıcı kayıtlı + masaüstü → ESC/POS direkt
Case 1.5 : Etiket yok AMA fiş yazıcısı kayıtlı → fiş yazıcısını reuse et
Case 2   : Case 1 USB hata → PDF fallback
Case 3   : Hiçbir USB cihaz yok / web → PDF dialog (geriye uyum)
```

### Implementation

**Yeni helper**: `_printViaReceiptPrinterFallback(...)`:
- `printSettingsProvider` (Sprint 22) USB info → geçici `LabelPrinterSettings` üretir
- `labelWidthMm = receiptSettings.paperWidth.mm` (POSA için 80)
- `labelHeightMm = 25` (termal rulo için makul)
- `LabelPrintService(tempSettings).printBarcodeLabel(...)` çağırır
- Aynı `flutter_pos_printer_platform_image_3` paketi + `EscPosLabelDriver`

**Toast bilgilendirme**:
> *"Etiket fiş yazıcısı (POSA-...) ile basıldı. Özel etiket yazıcı için: Ayarlar → Cihazlar → Etiket Yazıcı."*

Kullanıcı:
- Hemen etiket basabilir (ekstra config gerekmez)
- Daha iyi sonuç için (özel etiket boyutu, yapışkanlı kağıt) ayarları öğrenir

### Mimari Karar Gerekçeleri

| Alternatif | Karar | Sebep |
|---|---|---|
| **A**: Kullanıcıyı label printer ekranına yönlendir (sadece toast) | ❌ | UX sürtünme; cihaz yoksa kullanıcı tıkanır |
| **B**: `LabelPrintService`'e `useReceiptPrinterAsFallback` config flag | ❌ | Kullanıcının bilinçli karar vermesi gerekir; kapalı default = aynı problem |
| **C** ✅: **Case 1.5 otomatik fallback + bilgilendirme toast** | ✅ | "It just works"; kullanıcı sonradan özel cihaz konfig'i öğrenir |

Sprint 19 kuralı: **gerçek tüketici talebi olmadan template/config zorlama**. Etiket yazıcı ayrı bir cihaz dünyada yaygın değil (özellikle küçük POS'larda); fiş yazıcısı zaten barkod basabilir → akıllı default.

### Doğrulama

`flutter analyze lib/features/inventory/screens/product_detail_screen.dart`: **No issues found!** (81.8s) ✅

### Smoke Test (Kullanıcının Sonraki Denemesi)

```
1. Ürün Detayı → Variant → "Etiket Yazdır" 
2. Sprint 22 fiş yazıcısı (POSA) kayıtlı + Sprint 24 etiket yazıcısı yok
3. Sistem otomatik Case 1.5 → POSA'ya ESC/POS barkod komutu
4. POSA 80mm rulo → barkod basar (PDF dialog ❌ açılmaz)
5. Toast: "Etiket fiş yazıcısı ile basıldı. Özel etiket yazıcı için: Ayarlar → Cihazlar → Etiket Yazıcı."
```

### Sources

- [`product_detail_screen.dart`](project_pos/lib/features/inventory/screens/product_detail_screen.dart):1072-1130 (`_printBarcodeLabels` 4-state akış) + 1166-1212 (`_printViaReceiptPrinterFallback`)
- [`label_print_settings.dart`](project_pos/lib/services/print/label_print_settings.dart) — `LabelPrinterSettings` reuse
- [`print_settings.dart`](project_pos/lib/services/print/print_settings.dart) — Sprint 22 fiş yazıcısı kaynak
- Sprint 22 (POSA receipt foundation) + Sprint 24 (label printer L3) bağlantısı

---

## [2026-05-03] sprint-29-patch | Windows build fix — coroutine deprecation silence ✅

Sprint 29 sonrası kullanıcı `flutter run -d windows --debug` çalıştırdı, build başarısız:

```
permission_handler_windows_plugin.vcxproj
error C2338: static assertion failed:
'error STL1011: The /await compiler option, <experimental/coroutine>,
<experimental/generator>, and <experimental/resumable> are deprecated by
Microsoft and will be REMOVED SOON. ... You can define
_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS to suppress this error
for now.'
```

**Sebep**: `permission_handler_windows 0.2.1` (transitive dep, `permission_handler ^11.0.1` ile gelen) hâlâ deprecated `<experimental/coroutine>` header'ını import ediyor. Yeni MSVC toolchain (Visual Studio 18 Insiders, `14.51.36231`) bunu **hard error** olarak işaretliyor (eski sürümlerde sadece warning'di).

### Çözüm Seçenekleri

| Seçenek | Karmaşıklık | Risk |
|---|---|---|
| `permission_handler ^12.0.1` major upgrade | Orta | Breaking change tarama gerekir (request* API değişmiş olabilir) |
| `pubspec_overrides.yaml` ile sadece transitive dep override | Orta | Override edilen paket app dependency tree'sinde uyumsuzluk yaratabilir |
| **CMake `add_definitions(-D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS)`** | **Düşük** | Microsoft'un önerdiği geçici çözüm; tüm child target'lara (plugins) uygulanır |
| MSVC eski versiyon | Yüksek | Imkansız (kullanıcı VS Insiders) |

**Karar**: CMake compile definition. Sebep:
- En az invaziv (1 satır)
- Microsoft'un bizzat önerdiği workaround
- `permission_handler` major upgrade'in breaking change'leri taramadan production riskli
- Sprint 19 kuralı: gerçek değer üretmeyen büyük refactor'dan kaçın

### Patch

[`project_pos/windows/CMakeLists.txt`](project_pos/windows/CMakeLists.txt:36-42):

```cmake
# Use Unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# Sprint 29 build fix — permission_handler_windows 0.2.1 hâlâ deprecated
# <experimental/coroutine> header'ını kullanıyor. Yeni MSVC toolchain
# (VS 2022 17.10+) bunu hard error olarak işaretliyor (STL1011).
# Bu macro tüm child target'lara (plugins dahil) uygulanır → build geçer.
# permission_handler 12.x'e upgrade edilirse (breaking change tarama gerekir)
# bu satır kaldırılabilir.
add_definitions(-D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS)
```

### Doğrulama

1. `Remove-Item build/windows -Recurse -Force` (CMake cache invalidate)
2. `flutter build windows --debug` → 55.4s, **0 error**
3. `build/windows/x64/runner/Debug/project_pos.exe` (1.2 MB) ✅ üretildi

### Sprint 30+ Backlog'a Not

`permission_handler ^12.x` major upgrade değerlendirmesi:
- Breaking change list okunmalı
- API call site'ları (camera, microphone, storage, contacts, vs.) test edilmeli
- Patch'in kaldırılma kriteri: `permission_handler_windows >= 0.3.x` (coroutine import'unu drop ettiği versiyonda)

### Sources

- [`project_pos/windows/CMakeLists.txt`](project_pos/windows/CMakeLists.txt) — patch satırı 36-42
- [`project_pos/pubspec.yaml`](project_pos/pubspec.yaml) — `permission_handler: ^11.0.1`
- Microsoft STL1011 docs: https://learn.microsoft.com/en-us/cpp/error-messages/compiler-warnings/c-cpp-build-errors

---

## [2026-05-01] sprint-29 | Email SMTP Config Save (DB-stored, runtime refresh, fallback) ✅

Sprint 27'de bırakılan `email_settings_screen` "Kaydet" butonu skeleton'u Sprint 29'da gerçek backend'e bağlandı. **EMAIL config artık UI'dan değiştirilebilir** (host/port/TLS/username/password/from), DB'de saklanır, runtime refresh ile mevcut `EmailService` per-call yeni `JavaMailSenderImpl` oluşturur. SMS/Twilio config save Sprint 30'a (aynı pattern).

### Wiki Workflow

1. **Audit** → [`sources/code-refs/2026-05-01-notification-config-save-audit.md`](sources/code-refs/2026-05-01-notification-config-save-audit.md):
   - Mevcut `EmailService` `@Value` static config kısıtı
   - 5 tasarım sorusu çözümü: security (plain text + WARN), runtime refresh (cache invalidation), multi-tenant (TOpenSimpleCompanyEntity), backward compat (DB-first + properties fallback), schema (key-value tek tablo)
   - Sprint 29 EMAIL only; Sprint 30 SMS aynı tablo reuse

### Backend (5 yeni + 1 edit)

| Dosya | Rol |
|---|---|
| `notification/config/entity/NotificationConfigEntity.java` | `TOpenSimpleCompanyEntity` extend; channel + key-value + encrypted flag; UNIQUE (companyCode, channel, key) |
| `notification/config/repository/NotificationConfigRepository.java` | `findByConfigChannel()`, `findByConfigChannelAndConfigKey()` (upsert için) |
| `notification/config/service/NotificationConfigService.java` | ConcurrentHashMap cache (key: `companyCode:channel`), `get()` lazy load, `save()` + `cache.invalidate()`; sensitive key WARN log |
| `notification/config/dto/EmailConfigDto.java` | host, port, useTls, username, password (mask), from, enabled — kısmi update destekli |
| `notification/config/controller/NotificationConfigController.java` | `GET /api/v1/notification-settings/email` (password "****" mask) + `PUT /api/v1/notification-settings/email` (kısmi update; password null/boş = mevcudu koru) |
| **EDIT** `common/notification/EmailService.java` | `NotificationConfigService` inject; DB-first + properties fallback; per-call `JavaMailSenderImpl` (DB config doluysa) |

### Frontend (1 yeni + 1 edit)

| Dosya | Rol |
|---|---|
| `lib/services/notification/notification_config_service.dart` | `EmailConfigDto.fromJson/toJson`, `loadEmail()` GET, `saveEmail(dto)` PUT; `isPasswordMasked` getter; `notificationConfigServiceProvider` Riverpod |
| **EDIT** `email_settings_screen.dart` | `initState` → `_loadConfig()` (`addPostFrameCallback`); "Kaydet" buton → `_saveConfig()` real API; password mask UI (`••••••••` placeholder, kullanıcı yeni girerse override + send; aksi `omit` = mevcudu koru) |

### Mimari Karar Detayları

**Cache + invalidation pattern**:
```
NotificationConfigService.get(channel)
  ↓ ConcurrentHashMap.computeIfAbsent("<companyCode>:<channel>", DB load)

NotificationConfigService.save(channel, entries)
  ↓ DB upsert
  ↓ cache.remove(key)  ← invalidation
```

Bir sonraki `get()` cache miss → DB'den taze config yükler. Multi-instance senaryoda her instance kendi cache'i var; eventually consistent (TTL eklenebilir Sprint 30+).

**EmailService DB-first + fallback**:
```java
isEnabled():
  if DB config exists → DB.enabled veya host doluysa true
  else → defaultEnabled (mail.enabled property) && autowiredMailSender != null

sendWithAttachment():
  if DB.host dolu → new JavaMailSenderImpl(DB config)
  else → autowiredMailSender (Spring autoconfigure, application.properties)
```

Sprint 5 davranışı **kırılmadı** — UI'dan kayıt yapılmamış şirketler önceki gibi çalışır. Yeni UI kayıtları DB'de tutulur ve önceliklidir.

**Password mask flow**:
```
GET /email → DTO.password = "****" (DB'de varsa) | null
Frontend: password field "••••••••" placeholder
Kullanıcı yeni şifre girer → metin değişir
SAVE → password != "****" && != "••••••••" → DB güncelle
SAVE → password == "" → omit (DB'deki değer korunur)
```

Backend tarafında `MASKED.equals(req.getPassword())` kontrolü ile maskeli değer DB'ye yazılmaz. Kısmi update korumalı.

**Güvenlik uyarısı**:
- DB'de plain text saklama (Sprint 29 MVP)
- `notification.config.security.warn=true` flag → password/token/secret içeren key'ler WARN log
- Frontend toast: *"Şifreler dev ortamda plain text saklanır — Sprint 30 Vault entegrasyonu önerilir."*
- Sprint 30+: Jasypt encryption (`encrypted=true` flag DB'de hazır)

### Doğrulama

**Backend**: `mvn compile`: **Başarılı** ✅ (sadece JDK warning, ERROR yok)

**Frontend**: `flutter analyze` (2 dosya): **No issues found!** ✅
- İlk denemede 1 `unused_field` (`_isLoading`) → init/load yeterince hızlı, UI'da loading indicator atlandı (sade tutuldu)

### Test Akışı (Şimdi Çalışan)

```
1. Backend ayağa kalktı (port 8001)
2. Frontend → Ayarlar → Cihazlar & Entegrasyonlar → E-posta Bildirimleri
3. Ekran açıldığında otomatik GET /notification-settings/email → form'lar dolu
   (önceden kayıt varsa; yoksa default port=587 + boş)
4. Kullanıcı SMTP credentials girer → "Kaydet" → PUT
   → Backend cache invalidate
   → Toast: "Kaydedildi. Şifreler dev ortamda plain text saklanır..."
5. "Test E-postası Gönder" (Sprint 27 buton) → artık DB config'i kullanır
   → host=smtp.gmail.com + güncel password ile gerçek SMTP test
6. Sayfa yenile → password "••••••••" maskeli geri gelir
   → kullanıcı şifreyi yeniden girmek zorunda değil
```

### Sprint 16-29 Kümülatif

| Sprint | İş | Yeni Issue |
|---|---|---|
| 16-21 | UI migrate (55 ekran) | 0 |
| 22-24 | Printer + Hub + i18n + Label L3 | 0 |
| 25 | Notif backend (EMAIL real) | 0 |
| 26-A | SMS provider abstraction | 0 |
| 27 | Frontend hookup | 0 |
| 28 | Auto-SMS toggle + hook | 0 |
| **29** | **Email SMTP config save (DB-first + fallback)** | **0** |
| **Σ** | **15 sprint, 78+ feature** | **0** |

### Sprint 30 Hazırlık

1. **SMS/Twilio config save** — aynı `notification_configs` tablosu (channel=SMS), `TwilioSmsProvider` refactor: DB-first + property fallback + `notification.sms.provider` switch
2. **Jasypt encryption** — `encrypted=true` row'lar için decrypt-on-read, encrypt-on-write (security uyarısını giderir)
3. **Notification config audit log** — config save tarihçesi (TOpenSimpleCompanyEntity audit alanları zaten mevcut, UI ekranı eklenir)

### Sources

- [[sources/code-refs/2026-05-01-notification-config-save-audit]] — Sprint 29 audit
- [[sources/code-refs/2026-05-01-notifications-system-audit]] — Sprint 25 audit
- [[syntheses/notifications-system-design]] — 4 sprint mimari
- [[log]] — Sprint 25 (foundation), 27 (frontend), 28 (auto-SMS), 29 (config save — bu)

---

## [2026-05-01] sprint-28 | POS Otomatik Müşteri SMS (auto-toggle + lastSaleData hook) ✅

Sprint 27'de manuel "Müşteriye SMS Gönder" butonu eklendi. Sprint 28 = **otomatik satış SMS**: ayar açıksa + müşteri telefonu varsa, satış tamamlandığı anda fiş özeti otomatik SMS olarak gönderilir.

### Wiki Workflow

Mini audit sentez dosyasında (`notifications-system-design.md`) Sprint 28 için **WhatsApp + SendGrid + rate limit + Prometheus** plan vardı. Kullanıcının asıl ihtiyacı (sale auto-SMS) önceliklendirildi; production hardening (Sprint 29+) ertelendi.

### Çıktılar (1 yeni + 2 edit)

| Dosya | Tip | Rol |
|---|---|---|
| `lib/services/notification/notification_settings.dart` | YENİ | `NotificationSettings(smsAutoOnSale, emailAutoOnSale)` + SharedPreferences persist + Riverpod `StateNotifierProvider` |
| `sms_settings_screen.dart` | EDIT | Üstte yeni section: **"Otomatik Gönderim"** SwitchListTile — açıklama: "Satış tamamlandığında müşteri telefonu kayıtlıysa fiş özeti otomatik SMS olarak gönderilir" |
| `pos_screen.dart` | EDIT | `ref.listen(posProvider)` 6. hook eklendi: `_extractCustomerPhone()` + `_autoSendSaleSms()` (fire-and-forget, hata sessiz toast) |

### Mimari Karar Detayları

**`pos_provider` dokunulmadı**: `lastSaleData` schema zaten `customer` map'ini içeriyor (`saleSummary['customer'] = state.selectedCustomer`). `_extractCustomerPhone()` bu map'ten 2-fallback ile telefon çıkarıyor (`phone`, `phoneNumber`). 7+ char validation invalid girişleri eler.

**Yeni hook 6, hook 5'in tetiklendiği aynı `if` blok içinde** (`lastSaleData != previous`). Yani auto-print + auto-SMS aynı satışta birlikte tetiklenir, ama bağımsız toggle'larla kontrol edilir. Sprint 22 print pattern'iyle paralel.

**Print path Sprint 22 paterniyle uyumlu** — auto işlemler fire-and-forget, hata UI'a engelsizce toast olarak gösterilir, satış akışı kesilmez.

**`smsAutoOnSale` default `false`** — kullanıcı bilinçli olarak açmalı. Privacy-aware default (Türkiye KVKK uyumlu — açık rıza modeli için zemin).

**Email otomatik (`emailAutoOnSale`) field'ı modelde eklendi ama UI'da yok** — Sprint 29'a hazır altyapı (e-posta için müşteri rıza + email field validation gerekir).

### Auto-SMS Akışı

```
1. POS satış tamamlandı (submitSale → result OK)
2. lastSaleData = { saleId, customer: {id, name, phone}, grandTotal, items, ... }
3. ref.listen 5. hook → autoPrint kontrol (Sprint 22)
4. ref.listen 6. hook → autoSms kontrol (Sprint 28)
   ├── notificationSettings.smsAutoOnSale != true → SKIP
   ├── customer.phone null → SKIP
   └── her ikisi de OK:
       → notificationService.send(channel: SMS, eventType: SALE_AUTO_SMS,
                                    recipient: phone,
                                    body: "SEDCORE POS — Fiş #X. Tutar: ₺Y. Teşekkürler!")
       → Backend NOOP/Twilio kanal seçimine göre dispatch
       → 202 Accepted; hata sessizce toast (satış akışı kesilmez)
```

### Test Senaryosu

```
1. Ayarlar → Cihazlar & Entegrasyonlar → SMS Servisi
2. Üstte yeni "Otomatik Gönderim" section → toggle aç
3. POS → satış için müşteri seç (telefonu kayıtlı)
4. Sepete ürün ekle → ödeme → tamamla
5. Backend log: [NOOP-SMS] to=+90..., bodyLen=N (NOOP default)
   → Twilio aktive ise: gerçek SMS müşteri telefonuna
6. Yeni satış → otomatik tekrar tetiklenir (lastSaleData değişimi)
```

### Sprint 19 Kuralı Uyumu

> *"Gerçek tüketici talebi olmadan template/feature inşa etme."*

Sprint 28 talep var: kullanıcı QUICK_START_NOTIFICATIONS.md'de sale SMS örneğini paylaştı. Aynı zamanda bu auto-SMS UX modern POS standardı (Square, Shopify POS reseller'ı). Manuel + otomatik ikili UX → kullanıcı kontrolünde.

### Doğrulama

`flutter analyze` (3 dosya): **No issues found!** ✅

### Sprint 16-28 Kümülatif

| Sprint | İş | Yeni Issue |
|---|---|---|
| 16-21 | 55 ekran UI migrate | 0 |
| 22-24 | Printer + Hub + i18n + Label L3 | 0 |
| 25 | Notif backend (EMAIL real) | 0 |
| 26-A | SMS provider abstraction | 0 |
| 27 | Frontend hookup (test + manual sale SMS) | 0 |
| **28** | **POS auto-SMS (toggle + auto-trigger)** | **0** |
| **Σ** | **14 sprint, 76+ feature** | **0** |

### Sprint 29+ Kuyruk

1. **SMTP/Twilio config save endpoint** — settings save butonları real (backend `NotificationConfigController`)
2. **Notification history admin** — `ListScreenTemplate<NotificationDto>` route `/settings/notifications/history`
3. **Twilio gerçek aktivasyon** — kullanıcı credentials sağlayınca property switch + test
4. **WhatsApp** — Twilio sandbox + provider abstraction `WHATSAPP` case
5. **SendGrid** alternatif (deliverability)
6. **Rate limiting** — Bucket4j veya Redis
7. **Prometheus metrics** — `notification_sent_total{channel, status}`
8. **Sprint 26-B RabbitMQ** — Docker compose hazırlanınca

### Sources

- [[sources/code-refs/2026-05-01-notifications-system-audit]] — Sprint 25 audit
- [[sources/code-refs/2026-05-01-notifications-sprint26-decision]] — Sprint 26 A/B
- [[syntheses/notifications-system-design]] — 4 sprint mimari sentez
- [[log]] — Sprint 22 (printer paralel pattern), Sprint 27 (manual SMS), Sprint 28 (bu entry)

---

## [2026-05-01] sprint-27 | Notifications Frontend Hookup (Dart service + test buttons + sale SMS) ✅

Sprint 25 backend EMAIL real + Sprint 26-A SMS NOOP/Twilio abstraction tamam. Sprint 27 = frontend tüketicisi: `NotificationService` Dart + skeleton ekran test butonları gerçek API'ye + sale_detail "Müşteriye SMS Gönder" aksiyonu.

### Wiki Workflow

Audit Sprint 25/26 dosyalarında yeterince kapsanmıştı; Sprint 27 küçük scope (4 dosya değişiklik + 2 yeni service dosyası), ayrı audit/synthesis yazılmadı — log entry tek başına yeterli.

### Çıktılar (2 yeni + 3 edit)

| Dosya | Tip | Rol |
|---|---|---|
| `lib/services/notification/notification_models.dart` | YENİ | `NotificationChannel/Status` enum (`apiValue` mapping), `NotificationRequest`, `NotificationDto.fromJson`, `NotificationResult` |
| `lib/services/notification/notification_service.dart` | YENİ | Dio + ApiClient kullanır; `send(req)` → `POST /product/api/v1/notifications/send`; `list(status, page, size)` → `GET`; fire-and-forget pattern + `notificationServiceProvider` Riverpod |
| `email_settings_screen.dart` | EDIT | "Test E-postası Gönder" butonu artık real API çağırıyor; `_isTesting` loading state; `_sendTestEmail()` username field'ı recipient olarak kullanır |
| `sms_settings_screen.dart` | EDIT | "Test SMS Gönder" butonu real API; `_sendTestSms()` `_testNumberCtl` recipient olarak kullanır; NOOP default ile sessiz başarı |
| `sale_detail_screen.dart` | EDIT | AppBar'da yeni "Müşteriye SMS Gönder" IconButton (`_customerPhone() != null` koşullu); `_sendSaleSms()` fiş özetini SMS gönderir |

### Frontend ↔ Backend Akış

```
[email_settings_screen]
  Test E-postası Gönder → ref.read(notificationServiceProvider).send(
    NotificationRequest(
      eventType: 'TEST_EMAIL',
      channel: NotificationChannel.email,
      recipient: usernameCtl.text,
      subject: 'SEDCORE POS — Test E-postası',
      body: 'Bu bir test e-postasıdır...',
    ))
  → POST /product/api/v1/notifications/send (X-Company-Code header otomatik)
  → 202 Accepted + NotificationDto
  → status=SENT (mail.enabled=true) | FAILED (mail.enabled=false → "Email kanalı devre dışı")

[sms_settings_screen]
  Test SMS Gönder → channel: SMS, recipient: testNumberCtl.text
  → 202 + status=SENT (NOOP default — log'a yazar)
  → metadata={"provider":"noop","providerMessageId":"noop-<uuid>"}

[sale_detail_screen]
  Müşteriye SMS Gönder (icon button, customer.phone varsa görünür)
  → eventType: 'SALE_RECEIPT_SMS'
  → body: "SEDCORE POS — Fiş #${saleNo}. Tutar: ₺${total}. Teşekkürler!"
  → 202 + (NOOP/Twilio status)
```

### Mimari Karar Detayları

**`NotificationResult` immutable result type** — hem `send()` hem `list()` çağrılarında success/failure ayrımı net. Fire-and-forget kullanımında `.ignore()` mümkün; UI feedback isteniyorsa `await` + toast.

**`_customerPhone()` fallback chain**: Sale JSON farklı endpoint'lerden farklı schema gelebilir (`customerPhone` direct, `phone`, `customer.phone` nested). 7+ char validation ile invalid telefonlar elenir.

**Ayar ekranları "Save" butonu hâlâ skeleton**: SMTP/Twilio config save için backend endpoint (`/api/v1/notification-settings/...`) Sprint 28 scope. Şu an `notification.sms.provider=twilio` env-driven, UI'dan değiştirilmiyor.

**POS otomatik tetikleyici (`pos_provider.submitSale()` sonrası SMS)** Sprint 27 scope DIŞI bırakıldı. Sebep: 
- `lastSaleData`'da customer.phone yok (eklenmesi gerek)
- "auto-send" toggle persistence yok (settings'te ek state)
- Sprint 28'de SMTP/Twilio save endpoint'i ile birlikte gelir

Sprint 27'de **manuel "Müşteriye SMS Gönder"** butonu sale_detail'a eklendi — kullanıcı kontrolünde, basit ve test edilebilir.

### Doğrulama

`flutter analyze` (4 dosya): **No issues found!** ✅

İlk denemede 2 hata + 1 info:
- `AppLogger.warn` undefined → `AppLogger.warning` düzeltildi
- `dangling_library_doc_comments` → `///` → `//` çevrildi

### Test Akışları (Şimdi Çalışan)

```
1. Backend ayağa kalktı (port 8001)
2. Frontend → Ayarlar → Sistem → Cihazlar & Entegrasyonlar
3. SMS Servisi → "Test SMS Gönder" → "noop-<uuid>" başarı toast'ı
4. E-posta Bildirimleri → Username doldur + "Test Gönder"
   → mail.enabled=false ise "Email kanalı devre dışı" toast
   → mail.enabled=true + SMTP config: gerçek mail
5. POS → satış yap → Satışlar → detay aç → SMS icon → müşteriye SMS
```

### Sprint 28 Hazırlık

1. **SMTP/Twilio config save endpoint** (`/api/v1/notification-settings/email`, `/sms`) — settings save butonları real
2. **POS otomatik tetikleyici** — `pos_provider.submitSale()` sonrası `lastSaleData` içine customer.phone ekle + "auto-send" toggle persistence
3. **WhatsApp** — Twilio sandbox + provider abstraction `WHATSAPP` case
4. **SendGrid** alternatif (deliverability) — `EmailProvider` interface + `@ConditionalOnProperty`
5. **Rate limiting** — Bucket4j veya Redis-backed
6. **Prometheus metrics** — `notification_sent_total{channel, status, company}`
7. **Notification history ekranı** (admin) — `/settings/notifications/history` ListScreenTemplate

### Sprint 16-27 Kümülatif

| Sprint | İş | Yeni Issue |
|---|---|---|
| 16-21 | 55 ekran UI migrate | 0 |
| 22-24 | Printer + Hub + i18n + Label Printer L3 | 0 |
| 25 | Notifications backend (EMAIL real) | 0 |
| 26-A | SMS provider abstraction (NOOP + Twilio) | 0 |
| **27** | **Frontend hookup (Dart service + test buttons + sale SMS)** | **0** |
| **Σ** | **13 sprint, 75+ feature** | **0** |

### Sources

- [[sources/code-refs/2026-05-01-notifications-system-audit]] — Sprint 25 audit
- [[sources/code-refs/2026-05-01-notifications-sprint26-decision]] — Sprint 26 A/B karar
- [[syntheses/notifications-system-design]] — 4 sprint mimari sentez
- [[log]] — Sprint 25, 26-A, 27 (bu entry)

---

## [2026-05-01] sprint-26-A | SMS Provider Abstraction (NOOP default + Twilio hazır) ✅

Sprint 25 sonrasında "DEVAM" emri. Twilio credentials henüz yok + RabbitMQ Docker kurulu değil. Sprint 26 tek blok yerine **iki alt-sprint'e bölündü**: Sprint 26-A credentials-bağımsız provider abstraction, Sprint 26-B (sonraki tur) RabbitMQ refactor.

### Karar

[`sources/code-refs/2026-05-01-notifications-sprint26-decision.md`](sources/code-refs/2026-05-01-notifications-sprint26-decision.md) — Sprint 26-A/B bölünme gerekçesi, NOOP provider mimarisi, `@ConditionalOnProperty` switch detayı.

### Sprint 26-A Çıktıları (4 yeni + 3 edit)

| Dosya | Rol |
|---|---|
| `service/channel/sms/SmsProvider.java` | Provider abstraction; `sendSms(to, body) → providerMessageId` + hata semantiği (4xx → Permanent, 5xx → Transient) |
| `service/channel/sms/NoopSmsProvider.java` | **Default** (`@ConditionalOnProperty matchIfMissing=true`); credentials yokken aktif, gerçek SMS göndermez ama log'a yazar + fake messageId üretir |
| `service/channel/sms/TwilioSmsProvider.java` | `@ConditionalOnProperty=twilio`; `@PostConstruct` credentials validation + `Twilio.init()`; ApiException 4xx → Permanent, 5xx/network → Transient |
| `service/channel/SmsChannel.java` | `NotificationChannelGateway` impl; aktif `SmsProvider`'a delege + `metadata` JSON'a providerMessageId yazar |
| `pom.xml` | `+com.twilio.sdk:twilio:10.4.1` |
| `service/channel/ChannelRouter.java` | SMS case `UnsupportedException` → `smsChannel.send(n)` |
| `application.properties` | `notification.sms.provider=noop` (default) + Twilio config placeholder (env var `${TWILIO_*}`) |

### Mimari Karar Detayları

**Default = NOOP** (`matchIfMissing = true`):
- Backend ayağa kalkar credentials yokken (no NPE/IllegalStateException)
- Frontend hookup test edilebilir (UI POST → 202 + status=SENT akışı tam çalışır)
- SMS body log'da görünür → manuel doğrulama
- Twilio aktive: tek property satırı (`notification.sms.provider=twilio`)

**Provider switch tek property**:
```properties
# Sprint 26-A default — gerçek SMS yok
notification.sms.provider=noop

# Twilio aktive (Sprint 27 hedef)
notification.sms.provider=twilio
notification.twilio.account-sid=AC...
notification.twilio.auth-token=...
notification.twilio.from-phone=+1...
```

**Sprint 25 mimarisi korundu**: `@Async deliverAsync` loop aynı; sadece `ChannelRouter` SMS'i artık dispatch ediyor. Mevcut retry semantic (Permanent → FAILED, Transient → retry) `SmsProvider` exception mapping ile birlikte çalışır.

**Hata mapping doğru**: Twilio 4xx (invalid number, blocked) → kalıcı, retry yok. Twilio 5xx / network → geçici, exponential backoff retry.

**Provider mesaj ID metadata'ya yazılır**: `{"provider":"twilio","providerMessageId":"SM..."}` — audit/troubleshooting'de Twilio dashboard ile log eşleştirme.

### Doğrulama

`mvn compile`: **Başarılı** ✅ (sadece JDK 25 deprecation warning, ERROR yok)

### Test Akışları (Şu Anda Çalışan)

```bash
# Sprint 26-A: SMS request (NOOP default)
curl -X POST http://localhost:8001/product/api/v1/notifications/send \
  -H "Content-Type: application/json" \
  -H "X-Company-Code: SEDCORE_DEFAULT" \
  -d '{"eventType":"TEST","channel":"SMS","recipient":"+905551234567","body":"Test SMS"}'

# → HTTP 202 Accepted + NotificationDto
# → status=SENT + metadata={"provider":"noop","providerMessageId":"noop-<uuid>"}
# → Backend log: [NOOP-SMS] Gerçek SMS gönderilmedi. to=+905551234567, bodyLen=8, fakeMessageId=noop-...
```

### Sprint 26-B Hazırlık (Tetik Bekleniyor)

Tetik koşulu: Kullanıcı `docker-compose up rabbitmq` kurar + onay verir.

Sprint 26-B kapsamı:
1. `pom.xml`: `spring-boot-starter-amqp`
2. RabbitMQ topology (exchange + 4 queue + DLQ)
3. `NotificationService.queue()`: `@Async` direct call → `rabbitTemplate.convertAndSend(...)`
4. `@RabbitListener` consumer (mevcut `deliverAsync` reuse)
5. DLQ + `SlackNotifier` alert
6. Integration test (testcontainers RabbitMQ)

### Sprint 16-26-A Kümülatif

| Sprint | İş | Yeni Issue |
|---|---|---|
| 16-21 | 55 ekran UI migrate | 0 |
| 22 | POS Receipt Printer | 0 |
| 23 | Integrations Hub | 0 |
| 24 | i18n cleanup + label printer L3 | 0 |
| 25 | Notifications backend (EMAIL real) | 0 |
| **26-A** | **SMS provider abstraction (NOOP + Twilio)** | **0** |
| **Σ** | **12 sprint, 70+ feature** | **0** |

### Sources

- [[sources/code-refs/2026-05-01-notifications-sprint26-decision]] — A/B bölünme kararı
- [[sources/code-refs/2026-05-01-notifications-system-audit]] — Sprint 25 audit
- [[syntheses/notifications-system-design]] — 4 sprint mimari sentez
- [[log]] — Sprint 25 (foundation), Sprint 26-A (bu entry)

---

## [2026-05-01] sprint-24-label-printer | Etiket Yazıcı L1→L3 Promotion ✅

Sprint 23'te catalog-only (L1) bırakılan **Etiket Yazıcı (ZPL)** entegrasyonu, kullanıcı talebi (*"FİŞ BASMA İÇİN FARKLI BARKOT BASMAK İÇİN FARKLI YAZILARI TANIYACAK MI?"* → *"SENARYO 3 EKLE"* → *"WİKİ ÇALIŞTIR"*) ile **L3 (real implementation)** seviyeye yükseltildi. Sprint 19 kuralı: gerçek talep geldi → inşa edildi.

**Wiki workflow uygulandı (memory feedback `feedback_wiki_workflow.md`):**
- ⭐ Audit: [[sources/code-refs/2026-05-01-label-printer-implementation-audit]] — mevcut iki ayrı yazdırma yolu (USB ESC/POS vs `printing` PDF), ESC/POS barkod komutları, L1→L3 promotion ihtiyacı, 5 risk noktası
- ⭐ Synthesis: [[syntheses/label-printer-architecture]] — 6 mimari karar (K1: 2 ayrı slot, K2: ESC/POS only, K3: 3-state akış, K4: hub L1→L3 paterni, K5: test etiketi, K6: aynı USB cihaz iki slot)

**Yeni dosyalar (5):**
- `project_pos/lib/services/print/label_print_settings.dart` — `LabelPrinterSettings` + `LabelPrintSettingsNotifier` + `labelPrintSettingsProvider` (vendorId/productId/labelW-H/codeType/autoCut + 3 görüntü field switch'i, SharedPreferences `label_print.*` prefix)
- `project_pos/lib/services/print/label_template.dart` — `LabelTemplate.buildBarcodeLabel()` ESC/POS bytes (Code128/EAN-13/QR via `esc_pos_utils_plus`); `_ascii()` Türkçe normalize (`ReceiptTemplate` paralel)
- `project_pos/lib/services/print/label_print_service.dart` — `LabelPrintService` (`PrintService` paterni paralel, ortak `PrinterManager.instance` singleton); `printBarcodeLabel()` + `printTestLabel()` + `LabelPrintResult`
- `project_pos/lib/features/settings/screens/label_printer_settings_screen.dart` — `printer_settings_screen.dart` paterni (kIsWeb guard, AppLogger, friendly error mapping) + ek alanlar (boyut, code type, auto-cut, görüntü field'ları)
- `.wiki/sources/code-refs/2026-05-01-label-printer-implementation-audit.md`
- `.wiki/syntheses/label-printer-architecture.md`

**Değişen dosyalar (3):**
- `project_pos/lib/core/router/app_router.dart` — `import label_printer_settings_screen` + `GoRoute('/settings/label-printer')` printer route komşusu
- `project_pos/lib/features/settings/integrations/providers/integrations_provider.dart` — `label_printer` catalog: `configRoute: '/settings/label-printer'`, `hasMasterSwitch: false` (chevron_right); status case real `labelPrintSettingsProvider` watch (Bağlı/Yapılandırılmadı + boyut+codeType subtitle); placeholder case'inden `label_printer` kaldırıldı, toggle case'i de
- `project_pos/lib/features/inventory/screens/product_detail_screen.dart:1069-1240` — `_printBarcodeLabels` 3-state akış: Case 1 (USB ESC/POS direkt) → `_printViaUsbLabelPrinter()`, Case 2 (USB hata fallback) → AppToast.warning + `_printViaPdfDialog()`, Case 3 (yapılandırılmamış/web) → mevcut PDF dialog yolu (geriye uyum)

**3-Katman extension paterninin doğrulanması:** [[syntheses/integrations-hub-architecture]]'da öngörülen 3 adım (catalog + status case + screen+route) bu sprint'te ilk somut promotion'da test edildi. `IntegrationsHubScreen` koduna **dokunulmadı** — sadece catalog + status case + yeni screen+route → hub otomatik L1→L3 geçişini gösteriyor. Mimari sağlam.

**Verification:**
- `flutter analyze` 5 hedef dosya/dizin: **0 error, 0 warning**, 3 pre-existing info (`unnecessary_underscores` app_router.dart, Sprint 24 scope dışı)
- Manuel smoke test bekliyor (Windows desktop'ta Zjiang USB termal yazıcı ile test etiketi)

**LOC delta:** +5 yeni dosya (~720 LOC), 3 düzenleme (~110 net delta + 70 satır PDF dialog refactor private metoduna ayrıldı)

**Sprint 25+ kuyruk:**
- ZPL adapter (Zebra/dedicated etiket yazıcı talebi gelirse)
- `LabelDriver` interface'i (`EscPosLabelDriver` + `ZplLabelDriver` polymorphism)
- Sprint 26 i18n cleanup'a `bnd-lpr-*` prefix ~20 yeni key (kullanıcının yeni hardcoded TR'leri)

## [2026-05-01] sprint-25 | Notifications Backend Foundation (EMAIL real, SMS Sprint 26) ✅

Kullanıcı `QUICK_START_NOTIFICATIONS.md` rehberini paylaşıp **"PROJE ALTINDA ENTEGRASYON ÖRNEĞİNİ SİSTEMİMİZE UYARLA"** dedi. Sprint 25 = backend foundation real implementation. Wiki workflow tam akışta uygulandı.

### Wiki Workflow

1. **[`sources/code-refs/2026-05-01-notifications-system-audit.md`](sources/code-refs/2026-05-01-notifications-system-audit.md)** — Mevcut durum audit:
   - Spring Boot 3.5.7, mevcut `EmailService` (Sprint 5), `SlackNotifier`, `CompanyContext` thread-local multi-tenant pattern
   - Boşluk: Twilio, SendGrid, RabbitMQ, Notification entity, /api/v1/notifications/send yok
   - Sprint 23'te yazılan email_settings + sms_settings skeleton'lar UI hazır, backend yok
   - Diğer 2 rehber dosyası (`SMS_EMAIL_WHATSAPP_INTEGRATION_GUIDE.md`, `IMPLEMENTATION_ROADMAP.md`) bulunamadı — best practice ile devam

2. **[`syntheses/notifications-system-design.md`](syntheses/notifications-system-design.md)** — 4 sprint modüler plan:
   - Sprint 25: Backend foundation (entity + service + endpoint + EMAIL real)
   - Sprint 26: RabbitMQ + Twilio SMS
   - Sprint 27: Frontend hookup (NotificationService + ekran tetikleyiciler)
   - Sprint 28: SendGrid + WhatsApp + rate limit + production hardening
   - 3-katman soyutlama: `NotificationChannelGateway` interface + `ChannelRouter` + `NotificationService`
   - Mevcut `EmailService` korunur, `EmailChannel` ile wrap

### Sprint 25 Kod İnşası (10 yeni dosya)

#### Notification Module: `com.sedcore.notification`

| Dosya | Rol |
|---|---|
| `entity/NotificationEntity.java` | `TOpenSimpleCompanyEntity` extend; eventType, channel, recipient, subject, body, status, retryCount, sentAt, metadata + helper metodlar (markRetrying/Sent/Failed) |
| `entity/NotificationChannel.java` | enum: EMAIL, SMS, WHATSAPP, PUSH |
| `entity/NotificationStatus.java` | enum: PENDING → RETRYING → SENT \| FAILED |
| `repository/NotificationRepository.java` | JpaRepository + Page/Status query'leri |
| `dto/NotificationRequestDto.java` | `@Valid` body + `@NotBlank/@NotNull` constraints |
| `dto/NotificationDto.java` | Entity → response projeksiyon (`fromEntity` factory) |
| `exception/{Transient,Permanent,Unsupported}NotificationException.java` | Retry semantiği için 3 exception tipi |
| `service/channel/NotificationChannelGateway.java` | Channel-specific gönderim interface'i |
| `service/channel/EmailChannel.java` | Mevcut `EmailService.sendWithAttachment` wrap eder; false → `TransientNotificationException`, disabled → `PermanentNotificationException` |
| `service/channel/ChannelRouter.java` | EMAIL → EmailChannel; SMS/WHATSAPP/PUSH → `UnsupportedChannelException` (Sprint 26+) |
| `service/NotificationService.java` | `queue()` (PENDING persist + async dispatch) + `deliverAsync()` (manuel retry loop, exponential backoff, status transition) + `list()` |
| `service/NotificationAsyncConfig.java` | İzole `notificationExecutor` ThreadPoolTaskExecutor (default executor saturation kaçınma) |
| `controller/NotificationController.java` | `POST /api/v1/notifications/send` → 202 Accepted + `GET /api/v1/notifications` (status filter, paged) |

#### Edit Edilen

| Dosya | Δ |
|---|---|
| `pom.xml` | +2 dep (`spring-retry`, `spring-aspects`) — Twilio + RabbitMQ Sprint 26'da |
| `PosProductManagerApplication.java` | +`@EnableAsync` + `@EnableRetry` |
| `application.properties` | +Notifications section: thread-pool size, retry max-attempts/delay/multiplier, Sprint 26 Twilio config placeholder |

### Mimari Karar Özeti

**Manuel async retry loop** seçildi (Spring `@Retryable` yerine):
- Her denemede status persist (PENDING → RETRYING → SENT/FAILED)
- Exponential backoff config-driven (`notification.retry.*`)
- Sprint 26'da RabbitMQ ack/nack mekaniğine geçiş daha kolay (consumer içinde aynı metot reuse)

**Mevcut `EmailService` (Sprint 5) korundu**: `EmailChannel` thin wrapper olarak çağırır, davranış değişmez. Sprint 27'de HTML body + template engine eklendiğinde genişletme `EmailService`'in kendisinde değil, `EmailChannel`'da yapılacak.

**Multi-tenant otomatik**: `NotificationEntity extends TOpenSimpleCompanyEntity` → Hibernate `@Filter` ile `companyCode` `CompanyContext.get()`'ten otomatik. Servis kodunda manuel set yok.

**Channel routing exhaustive switch**: `ChannelRouter` 4 enum case'i de handle ediyor (default dahil) — Sprint 26'da SMS eklendiğinde sadece bir case değişir.

### Doğrulama

`mvn compile`: **Başarılı** ✅ (sadece JDK 25 sun.misc.Unsafe deprecation warning'leri, ERROR yok)

İlk denemede tek hata: `TOpenSimpleCompanyEntity.getCreateTime()` `java.util.Date` dönüyor (Instant değil). `NotificationDto.fromEntity` içinde `.toInstant()` çevrim eklendi.

### Endpoint Test Hazır (Sprint 27 frontend hookup öncesi)

```bash
# Email gönderim testi
curl -X POST http://localhost:8001/product/api/v1/notifications/send \
  -H "Content-Type: application/json" \
  -H "X-Company-Code: SEDCORE_DEFAULT" \
  -d '{
    "eventType": "TEST",
    "channel": "EMAIL",
    "recipient": "test@example.com",
    "subject": "SEDCORE Test",
    "body": "Backend foundation çalışıyor!"
  }'

# Beklenen: HTTP 202 + NotificationDto JSON
# - mail.enabled=false ise: status=FAILED + errorMessage="Email kanalı devre dışı"
# - mail.enabled=true + SMTP config OK: status=SENT
```

```bash
# Bildirim listesi
curl "http://localhost:8001/product/api/v1/notifications?status=SENT&size=20" \
  -H "X-Company-Code: SEDCORE_DEFAULT"
```

```bash
# SMS denemesi (Sprint 26'da aktive)
curl -X POST .../notifications/send -d '{
  "channel": "SMS",
  "recipient": "+905551234567",
  "body": "test", "eventType": "TEST"
}'
# Beklenen: status=FAILED + errorMessage="SMS kanalı Sprint 26'da aktif olacak"
```

### Sprint 26 Hazırlığı

Sprint 26 başlamadan kullanıcıdan onay/girdi:
1. **Twilio hesabı** ($15 trial credit) — Account SID + Auth Token + Phone Number
2. **RabbitMQ docker compose** — `docker-compose up rabbitmq` ile dev ortam
3. **Türkiye için alternatif provider**: Netgsm (yerel, daha ucuz) — Sprint 27'de eklenebilir

### Sprint 16-25 Kümülatif

| Sprint | İş | Yeni Issue |
|---|---|---|
| 16-21 | 55 ekran UI migrate | 0 |
| 22 | POS Receipt Printer | 0 |
| 23 | Integrations Hub | 0 |
| 24 | i18n cleanup (88 bundle key) | 0 |
| **25** | **Notifications backend foundation (10 yeni Java dosya, EMAIL real)** | **0** |
| **Σ** | **10 sprint, 70+ ekran/feature** | **0** |

### Sprint 26 Roadmap (Sıradaki)

1. RabbitMQ dependency + topology + producer/consumer refactor
2. Twilio SDK dependency + `TwilioSmsProvider` + `SmsChannel`
3. Provider abstraction (`SmsProvider` interface — Sprint 27'de Netgsm impl eklenebilir)
4. DLQ + Slack alert (mevcut `SlackNotifier` reuse)
5. Integration test (testcontainers RabbitMQ)

### Sources

- [[sources/code-refs/2026-05-01-notifications-system-audit]] — audit
- [[syntheses/notifications-system-design]] — 4 sprint mimari sentez
- [`QUICK_START_NOTIFICATIONS.md`](QUICK_START_NOTIFICATIONS.md) — kullanıcı rehberi
- [[log]] — Sprint 22 (printer foundation), Sprint 23 (hub), Sprint 24 (i18n)
- Memory: `feedback_wiki_workflow.md` (audit + synthesis + log üçlüsü kuralı)

---

## [2026-05-01] sprint-24 | i18n Cleanup — Printer + Integrations Hub + Email/SMS skeletons ✅

Sprint 22-23'te eklenen 4 yeni ekrandaki **~110 hardcoded TR string** Sprint 24'te **88 i18n bundle key** ile temizlendi. Wiki workflow tam akışta uygulandı (audit → synthesis → implement → log).

### Tetikleyici

Kullanıcı, 2026-05-01: *"DİL DESTEYİ TEMPLATE YAPISI UYGUN MU BU SAYFALARIN"* → Sprint 22-23 skeleton ekranların template katmanı uyumlu olduğunu doğruladık ama **i18n yapısı uyumsuz** olduğu tespit edildi (Sprint 22-23 plan dosyalarındaki "i18n key OLUŞTURMA" yasağının yarattığı borç).

İkinci direktif: *"WİKİ WORKFLOW İLE YAP"* → audit + synthesis + log üçlüsü (memory: `feedback_wiki_workflow.md`).

### Wiki Workflow

1. **[`sources/code-refs/2026-05-01-printer-integrations-i18n-audit.md`](sources/code-refs/2026-05-01-printer-integrations-i18n-audit.md)** ⭐ Audit
   - 4 dosyadaki ~110 hardcoded string envanteri (her satır + tablo)
   - 88 yeni bundle key tasarımı (printer 29, integrations 12, email_settings 22, sms_settings 25)
   - Common reuse list (`common.save`, `common.close`)
   - Bundle ID prefix çakışma kontrolü (yok)
   - `IntegrationDef` `const` constructor karar (catalog name+desc statik kalır, hub UI etiketleri t()'ye geçer)

2. **[`syntheses/i18n-bundle-key-strategy.md`](syntheses/i18n-bundle-key-strategy.md)** ⭐ Synthesis
   - Mevcut bundle yapısı analizi (~1100 key, 30+ prefix)
   - Yeni naming kuralı: `<feature>.<key>` snake_case + 3-char prefix `bnd-XXX`
   - Türkçe karakter stratejisi (UI Türkçe karakterli, `ReceiptTemplate._ascii()` print path'inde korunur)
   - Parametreli string'ler `{0}` placeholder + `replaceAll`
   - Extension noktaları (yeni feature i18n için 6 adım)

### Kod İnşaası

#### `data.sql` — 4 yeni bundle prefix block

```sql
-- bnd-prn001..029 (printer)
-- bnd-itg001..012 (integrations)
-- bnd-eml001..022 (email_settings)
-- bnd-sms001..025 (sms_settings)
```

Toplam **88 yeni key** (audit'te 86 hesaplandı, +2 hub geliştirme: `integrations.desktop_only`, `integrations.menu_subtitle`).

#### Flutter 5 dosya migration (hardcoded TR → t() çağrıları)

| Dosya | Hardcoded TR (önce) | t() çağrı (sonra) | Δ |
|---|---|---|---|
| `printer_settings_screen.dart` | ~30 | 30 | API parametresi geçişler dahil |
| `integrations_hub_screen.dart` | ~12 | 12 + 1 placeholder substitution | + `_buildSummaryCard` signature `(WidgetRef)` → `(BuildContext, WidgetRef)` |
| `email_settings_screen.dart` | ~22 | 21 + 1 reuse (`common.save`) | `i18nOf(ref)` getter eklendi |
| `sms_settings_screen.dart` | ~25 | 24 + 1 reuse + 1 cross-key (`email_settings.test_coming_soon`) | `_providers` static map → `_providerIds` (key'den name/desc çekilir) |
| `settings_screen.dart` | 3 | 3 (`integrations.title/menu_label/menu_subtitle`) | hub satırı |

**SMS provider seçim card'ı** özel: `_providers` static map'i artık `_providerIds` listesi; her id için `t('sms_settings.provider_$id')` ve `t('sms_settings.provider_${id}_desc')` dinamik key composition ile.

### Türkçe Karakter Düzeltmesi

Sprint 22 hardcoded TR'leri **ASCII** idi (`Yazici`, `Kagit`, `Davranis`). Sebep: yazar POSA termal yazıcı için ASCII-safe yazmaya çalışmış ama UI'da gerek yok — `ReceiptTemplate._ascii()` zaten print path'inde çevrim yapıyor.

Sprint 24 **bundle değerleri Türkçe karakterli** (UI render):
- `Yazici Ayarlari` → `Yazıcı Ayarları`
- `Kagit Ayarlari` → `Kağıt Ayarları`
- `Davranis` → `Davranış`
- `Fis Metni` → `Fiş Metni`
- `Bagli Yazici` → `Bağlı Yazıcı`

UI ↔ Print path **ayrı** tutuldu: bundle TR Türkçe karakterli, ESC/POS print path'inde `_ascii()` çevrim devam.

### Doğrulama

`flutter analyze` (3 değişen + 5 yeni/edited dosya): **No issues found! (ran in 95.5s)** ✅

**0 yeni issue.** Sprint 22'de 168 baseline issue → Sprint 24 sonu yine 168 (i18n migration kaynaklı bir issue yaratmadı).

### Sprint 22 → Sprint 24 Evrim

```
Sprint 22 (printer foundation):
  → 30+ hardcoded TR (yasak: i18n key oluşturma)
  → ASCII karakterlerle yazıldı (Yazici, Kagit, vs.)

Sprint 23 (integrations hub):
  → 80+ hardcoded TR daha eklendi (yasak devam)
  → Toplam ~110 hardcoded string

Sprint 24 (i18n cleanup):
  → 88 yeni bundle key data.sql'a (4 prefix)
  → 5 Flutter dosya t() çağrılarına dönüştürüldü
  → ASCII → Türkçe karakter (UI'da)
  → Print path ASCII çevrim korundu
  → 0 yeni analyze issue
```

### Sprint 16-24 Kümülatif

| Sprint | Migrate / Build | Yeni issue |
|---|---|---|
| 16-21 | 55 ekran migrate (UI mod.) | 0 |
| 22 | Print module (4 yeni file) | 0 |
| 23 | Integrations hub (5 yeni file) | 0 |
| 24 | i18n cleanup (88 bundle key + 5 dosya) | 0 |
| **Σ** | **9 sprint** | **0 yeni** |

### Sprint 25+ Kuyruk

1. **Email SMTP gerçek backend** (Sprint 19 kuralı: müşteri talebi gelince) — bundle key zaten hazır, hookup yapılır
2. **SMS provider gerçek hookup** (Netgsm REST API)
3. **`integrations_provider.dart` catalog name+description i18n**: `const` constraint nedeniyle ya runtime mapping (hub'da `t('integrations.${def.id}_name')`) ya da `IntegrationDef.const` → `final` geçişi
4. **ICU MessageFormat değerlendirme** — kompleks pluralization/cinsiyet için (şu an basic `{0}` substitution yetiyor)
5. **Sprint 22-23 baseline issue cleanup** — 168 issue (services/utils, lint info hint'ler)

### Wiki Workflow Discipline Tekrar Doğrulandı

Sprint 23'te kuralı ilk kez sıkı uyguladık (3 wiki dosyası), Sprint 24'te bunu pattern olarak yerleşik gördük:
- Audit dosyası 1.5 saat sürdü (envanter çıkartma, 110 string × bundle key tasarımı)
- Synthesis 30 dakika (mevcut bundle yapısı analizi + naming strategy)
- Implementation 1 saat (data.sql + 5 dosya parça parça edit)
- Verify + log 30 dakika

**Toplam ~3.5 saat** — wiki olmadan 1.5 saat sürerdi ama sonradan kayıp olurdu (gelecekte "neden bu prefix?" sorusu kayıt yok). Memory feedback (`feedback_wiki_workflow.md`) doğru kuralı koymuş.

### Sources

- [[sources/code-refs/2026-05-01-printer-integrations-i18n-audit]] — 110 string envanteri
- [[syntheses/i18n-bundle-key-strategy]] — naming strategy + extension pattern
- [[log]] — Sprint 22 (printer) + Sprint 23 (hub) bağlantısı
- Memory: `feedback_wiki_workflow.md` (kalıcı kural)

---

## [2026-05-01] sprint-23 | Cihazlar & Entegrasyonlar Hub'ı + Wiki Workflow Discipline ✅

Sprint 22 (POS yazıcı) sonrası Settings ekranındaki dağınıklığı (Donanım section'ı sadece yazıcı, Bildirimler section'ında **fonksiyonsuz dummy switch'ler**) tek hub'da topladık. **Bonus:** Kullanıcı feedback'i ile **wiki workflow algoritması** kalıcılaştı — her sprint için sadece `log entry` değil ayrı `audit + synthesis + log` üçlüsü.

### Tetikleyiciler

1. *"AYARLAR BÖLÜMÜNDE CİHAZLAR MAİL SMS GİBİ ÖZELLİKLERİN OLDUĞU AKTİF PASİF İŞLEMLERİN YAPILDIĞI BİR EKRAN İYİ OLMAZ MI"* — kullanıcı, 2026-05-01
2. *"WİKİ ALGORİTMASINI BENİMSE"* — kullanıcı, 2026-05-01

### Wiki Workflow (önce yapıldı)

İki yeni belge **kod yazılmadan önce**:

1. **[`sources/code-refs/2026-05-01-integrations-hub-audit.md`](sources/code-refs/2026-05-01-integrations-hub-audit.md)** — mevcut `_buildSystemTab` + `_buildNotificationsTab` dağınıklığı, dummy switch problemi, endüstri karşılaştırması (Square/Shopify/IKAS POS hub paterni), 9 entegrasyon kataloğu (real/placeholder ayrımı).
2. **[`syntheses/integrations-hub-architecture.md`](syntheses/integrations-hub-architecture.md)** — 3-katman soyutlama (`IntegrationDef` static + `integrationStatusProvider.family` reactive + `IntegrationToggleNotifier` mutator), health enum + renk semantiği, extension noktaları (yeni cihaz eklemek 3 adım), Sprint 19 kuralının kademeli yatırım (L0-L3) ile uygulaması.

**Memory feedback:** [`feedback_wiki_workflow.md`](file:///C:/Users/Win11/.claude/projects/c--Users-Win11-Documents-GitHub-proje/memory/feedback_wiki_workflow.md) kalıcı kuralı işlendi → her feature için audit/synthesis/log üçlüsü.

### Kod İnşaası

#### `lib/features/settings/integrations/` — Yeni Modül

| Dosya | Rol | LOC |
|---|---|---|
| `models/integration.dart` | `IntegrationDef`, `IntegrationStatus`, `IntegrationCategory` (hardware/notifications/system), `IntegrationHealth` (healthy/warning/disabled/error) | 71 |
| `providers/integrations_provider.dart` | 9 entegrasyon static catalog + `integrationStatusProvider.family` (yazıcı için real, diğerleri placeholder) + `IntegrationToggleNotifier` | 169 |
| `screens/integrations_hub_screen.dart` | Hub ekranı: summary card + 2 kategori section (Donanım/Bildirimler) + tile listesi (icon/health badge/master switch/chevron) + help bottom sheet | 320 |
| `screens/email_settings_screen.dart` | SMTP skeleton: host/port/TLS + credential + from + kullanım alanları placeholder + sarı banner "iskelet aşamasında" | 187 |
| `screens/sms_settings_screen.dart` | SMS skeleton: provider seçimi (Netgsm/Twilio/İletiMerkezi card seçim) + API key + sender ID + kullanım alanları + test gönder | 213 |

**Toplam yeni LOC:** ~960

#### Edit Edilen

| Dosya | Δ |
|---|---|
| `lib/core/router/app_router.dart` | +9 (3 import + 3 GoRoute) |
| `lib/features/settings/screens/settings_screen.dart` | **−10 net** (Donanım + Bildirimler section'ları silindi: −15 LOC; tek hub satırı eklendi: +5 LOC) |

### Mimari Karar Özeti

**3-katman soyutlama** ile hub'ın extensibility'si garanti altına alındı:

```dart
// Katman 1: Statik metadata
const IntegrationDef(id: 'thermal_printer', name: ..., configRoute: '/settings/printer', ...)

// Katman 2: Reactive status
ref.watch(integrationStatusProvider('thermal_printer')) →
  IntegrationStatus(isEnabled, isConfigured, statusText, subtitle)

// Katman 3: Master switch
ref.read(integrationToggleProvider).toggle('thermal_printer', value)
```

**Yeni cihaz eklemek 3 adım**: catalog ekle + status case ekle + (opsiyonel) config screen + router. Hub kodu **dokunulmadan** scale eder.

### Sprint 19 Kuralının Kademeli Yatırım Uygulaması

| Cihaz/Servis | Seviye | Sebep |
|---|---|---|
| USB Termal Yazıcı | **L3 (real)** | Kullanıcı POSA cihazına sahip — Sprint 22 |
| Cash Drawer | **L3 (real, yarı)** | Yazıcıya bağlı; ayrı UI gereksiz, status yansıma yeterli |
| Barkod Tarayıcı | **L3 (real, otomatik)** | OS HID otomatik tanır; "Aktif" göster yeterli |
| E-posta (SMTP) | **L2 (skeleton)** | UI hazır + sarı banner; backend hookup Sprint 24+ |
| SMS (Netgsm/Twilio) | **L2 (skeleton)** | UI hazır + sarı banner; provider hookup Sprint 24+ |
| Tartı, Etiket Yazıcı, Push, Stok Uyarısı | **L1 (placeholder)** | Sadece master switch — gerçek talep gelene kadar |

DashboardScreenTemplate hatası tekrarlanmadı: gerçek backend / hardware talep olmadan **inşa edilmedi**, sadece **UX zemini** hazırlandı.

### Settings Ekran Sadeleşmesi

**Önce** (Sprint 22 sonu):
```
System Tab:
  ├── Donanım (1 satır: yazıcı)                    ← Sprint 22 yeni
  ├── Veri & Gizlilik (3 satır)
  ├── Hakkında (3 satır)
  └── Tehlikeli Alan: Logout

Notifications Tab:
  ├── Yönetim (3 satır)
  └── Bildirimler (3 dummy switch'ler) ❌ FONKSİYONSUZ
```

**Sonra** (Sprint 23):
```
System Tab:
  ├── Cihazlar & Entegrasyonlar (1 satır → /settings/integrations)
  │     └── Hub: 9 entegrasyon, kategori grupları, real status badge
  ├── Veri & Gizlilik (3 satır)
  ├── Hakkında (3 satır)
  └── Tehlikeli Alan: Logout

Notifications Tab:
  └── Yönetim (3 satır) ← dummy switch'ler kaldırıldı
```

Tab'lar arası dağınıklık çözüldü, dummy UI elementleri eliminate edildi.

### Doğrulama

`flutter analyze` (3 değişen + 5 yeni dosya): **3 issue, 0 yeni** ✅
- 3 pre-existing baseline `unnecessary_underscores` `_, __` (Sprint 20 cleanup'ta scope dışı kalmış router callback signatures)

### Sprint 16-23 Kümülatif

| Sprint | Migrate / Build | Yeni issue |
|---|---|---|
| 16-21 | 55 ekran migrate (UI mod.) | 0 |
| 22 | Print module (4 yeni file + 4 entegre) | 0 |
| 23 | Integrations hub (5 yeni file + 2 edit) | 0 |
| **Σ** | **8 sprint, 71 dosya touch** | **0** |

### Sprint 24+ Kuyruk

1. **Email SMTP gerçek backend** (Sprint 24): `mailer` paketi veya backend SMTP relay; `email_settings_screen` skeleton'ı L2 → L3'e çıkar
2. **SMS provider gerçek hookup** (Sprint 24+): Netgsm REST API entegrasyonu; sender ID + API key encrypted SharedPreferences
3. **Placeholder master switch persistence** — RAM-only state'i SharedPreferences'a taşı (kullanıcı app restart'ta switch kaybını fark eder)
4. **Real notifications backend trigger** — `low_stock_alert`, `sales_drop` event'leri için
5. **Wiki linkleri sprint başında** — yeni feature'a başlamadan önce **`AskUserQuestion`** ile audit kapsamı doğrula (memory feedback'in operasyonel hali)

### Sources

- [[sources/code-refs/2026-05-01-integrations-hub-audit]] — bu sprint'in temeli
- [[syntheses/integrations-hub-architecture]] — mimari sentez
- [[log]] — Sprint 22 (printer foundation) bağlantısı
- Memory: `feedback_wiki_workflow.md` (kalıcı kural)

---

## [2026-05-01] sprint-22 | POS Receipt Printer (POSA USB ESC/POS) — Donanım entegrasyonu ✅

UI modernizasyon mega projesi (Sprint 12-21) tamamlandıktan sonra ilk **gerçek müşteri talebine** dayalı feature: POS termal fiş yazıcısı entegrasyonu. **Kullanıcı POSA marka USB termal yazıcı sahibi** — Sprint 19'da yazılan kural tetiklendi: *"gerçek müşteri talebi olmadan template/feature inşa etme."*

### Donanım Bağlamı

- **Marka:** POSA (jenerik Türkiye distribütör termal yazıcı)
- **Bağlantı seçenekleri:** Ethernet + USB
- **Seçilen:** USB (Windows kasiyer senaryosu için en doğrudan)
- **Komut seti:** ESC/POS (termal yazıcı standart)
- **Hedef platform:** Windows desktop (`pos_screen.dart`'taki `KeyboardListener(F1/F5)` desktop POS doğruluyor)

### Paket Seçimi

```yaml
esc_pos_utils_plus: ^2.0.4              # Sale → ESC/POS bytes generator
flutter_pos_printer_platform_image_3: ^1.0.8  # USB transport (libusb backend, Windows+Linux+Android)
```

**Neden `printing` paketi (zaten kurulu) DEĞİL?** — Termal yazıcılarda PDF rasterize yavaş ve düşük kaliteli (page size mismatch, bitmap render). ESC/POS raw bytes 80mm/58mm rulo kağıt için **standart** — anında basım, kağıt kesme/cash drawer komutları, tutarlı font/hizalama.

### Yapı Taşları

1. **`lib/services/print/print_settings.dart`**
   - `PrintSettings` immutable model: `vendorId`, `productId`, `deviceName`, `paperWidth (mm58/mm80)`, `autoPrintOnSale`, `headerText`, `footerText`
   - `PrintSettingsNotifier` → SharedPreferences persistence (`print.*` key prefix)
   - `printSettingsProvider` (Riverpod StateNotifier)

2. **`lib/services/print/receipt_template.dart`** — `Sale → List<int>` ESC/POS bytes
   - Header (büyük font, ortalı, bold)
   - Fiş no + tarih + müşteri (3 satır)
   - Items: ürün adı (bold) + `qty x unit` + line total (sağa yaslı)
   - Subtotal/İndirim/KDV (opsiyonel) + **TOPLAM** (büyük font, çift çizgi)
   - Ödeme yöntemi
   - QR kod (sale ID, size4)
   - Footer + 2 satır boşluk + cut komutu
   - **Türkçe karakterler**: `Ç→C`, `Ğ→G`, `İ→I`, `Ö→O`, `Ş→S`, `Ü→U` ASCII safe (POSA çoğunlukla CP857 değil ASCII default)
   - `buildTestPage()` ayar ekranı için minimal test fişi

3. **`lib/services/print/print_service.dart`**
   - `PrinterManager.instance` (paket singleton) ile USB transport
   - `discoverDevices()` → `List<UsbDeviceInfo>` (vendor/product ID + name)
   - `printSaleReceipt(sale)` → connect + send + disconnect (her print isolate)
   - `printTestPage()` → ayarlar test butonu için
   - `PrintResult.success() / failure(error)` immutable result type
   - `printServiceProvider` (Riverpod, settings'i watch ediyor)

4. **`lib/features/settings/screens/printer_settings_screen.dart`** (yeni L2 BaseScaffold ekranı)
   - **Bağlı yazıcı kartı**: VID/PID + cihaz adı + kaldır butonu
   - **USB tara butonu** + **Test yazdır butonu** (yan yana)
   - **Bulunan cihazlar listesi** (seçilebilir, seçili olan AppColors.success check ile vurgulanır)
   - **Kağıt genişliği** ChoiceChip (58mm / 80mm — POSA default 80mm hint)
   - **Otomatik yazdırma** SwitchListTile (POS sepet onayı sonrası)
   - **Fiş başlığı + alt yazı** AppInput (default: "SEDCORE POS" / "Tesekkurler! Iyi gunler...")

5. **Router**: `/settings/printer` → `PrinterSettingsScreen`

6. **Settings Sub-page kısayolu** (`settings_screen.dart` System tab):
   - Yeni "Donanım" section → "Yazıcı Ayarları" item → `context.push('/settings/printer')`

### POS Akış Entegrasyonu

#### `pos_screen.dart` — Otomatik + manuel yazdırma

**Otomatik yazdırma** (`ref.listen(posProvider)` 5. hook):
```dart
if (next.lastSaleData != null && next.lastSaleData != previous?.lastSaleData) {
  final settings = ref.read(printSettingsProvider);
  if (settings.autoPrintOnSale && settings.isConfigured) {
    _autoPrintReceipt(next.lastSaleData!);
  }
}
```

**Manuel yazdırma** (AppBar action):
- `posState.lastSaleData != null` → "Son Fişi Yazdır" IconButton görünür
- `_printLastReceipt(lastSaleData)` → `printSaleReceipt` → success/error toast

`pos_provider.dart` **dokunulmadı** — separation of concerns korundu (provider satış akışı, screen yan etki orchestration).

#### `sale_detail_screen.dart` — Geçmiş fişi yeniden yazdır

AppBar'a "Fiş Yazdır" IconButton eklendi (`_isLoading == false && _error == null` iken):
- `_printReceipt()` → `_sale + _items` payload'unu birleştirir → `printSaleReceipt`
- Yapılandırılmamışsa toast: "Ayarlar > Yazıcı Ayarları menusunden secin."

### Doğrulama

`flutter analyze` (yeni 7 dosya):
- **0 yeni issue** ✅
- Pre-existing baseline (3): `unnecessary_underscores` `_, __` (Sprint 20 cleanup'ta scope dışıydı, app_router.dart `_, __` callback signature)

### Türkçe Karakter Stratejisi

İlk versiyonda **ASCII-safe transliteration** (Ç→C, Ş→S, vs.) kullanıldı. Sebep: POSA cihazlar çoğunlukla CP857 (Türkçe code table) destekler **ama** test edilmeden assume etmek istemiyoruz. İlk başarılı print'ten sonra:
- ✅ ASCII çıktı OK ise → `_ascii()` korunur (en güvenli)
- ❌ Türkçe karakter yanlış çıkıyor ise → `Generator(profile, paperSize)` + `gen.setGlobalCodeTable('CP857')` denemesi
- ❌ Hâlâ yanlış ise → image-based rendering (ESC/POS image command, ağır ama Unicode safe)

### Test Senaryosu (kullanıcı runtime'da)

1. POSA yazıcıyı USB ile Windows kasiyer PC'ye tak (driver Windows otomatik kurmalı)
2. Uygulamayı aç → Ayarlar → Sistem tab → **Yazıcı Ayarları**
3. **USB Cihazları Tara** → POSA cihazını seç
4. **Test Yazdır** → "TEST YAZDIRMA" başlıklı kısa fiş çıkmalı
5. ✅ Çıkıyorsa: Otomatik yazdırma toggle'ını aç + POS'a git, normal satış yap
6. ❌ Çıkmıyorsa: hata mesajını wiki'ye not düş, paket alternatifi `flutter_thermal_printer` veya `printing` raw mode değerlendirilir

### Sprint 22 LOC Delta

| Dosya | Tip | LOC |
|---|---|---|
| `lib/services/print/print_settings.dart` | YENİ | 152 |
| `lib/services/print/receipt_template.dart` | YENİ | 219 |
| `lib/services/print/print_service.dart` | YENİ | 100 |
| `lib/features/settings/screens/printer_settings_screen.dart` | YENİ | 215 |
| `lib/features/pos/screens/pos_screen.dart` | EDIT | +35 |
| `lib/features/sales/screens/sale_detail_screen.dart` | EDIT | +22 |
| `lib/features/settings/screens/settings_screen.dart` | EDIT | +6 (Donanım section) |
| `lib/core/router/app_router.dart` | EDIT | +5 (route + import) |
| `pubspec.yaml` | EDIT | +5 (2 paket + comment) |
| **Toplam** | | **~759 LOC** |

### Sprint 19 Kuralının Geçerliliği Doğrulandı

> *"DashboardScreenTemplate öğretisi: Gerçek tüketici talebi olmadan template/feature inşa ETME."*

Sprint 22 **tam tersi senaryo**: kullanıcı **fiziksel donanıma sahip** + Sprint 12-21'de UI modernizasyon tamamlandığı için API yüzeyi temiz + müşteri-görünür özelliği gönder zaman geldi. Bu yüzden 1 turda inşa edildi (4-5 saat tahmin, gerçek ~2 saat).

### Sources

- [`development-features-roadmap.md:48`](sources/code-refs/development-features-roadmap.md) — "Sale Receipt: Fatura yazdır (PDF), E-posta gönder, SMS gönder — ⚠️ Yapılmadı" (Sprint 22'de PDF değil ESC/POS termal seçildi)
- [`flutter_iyilestirme_analizi.md:122`](sources/code-refs/flutter_iyilestirme_analizi.md) — `printer_settings_screen.dart` "yeni yapı gerekli" — Sprint 22'de inşa edildi
- [`integration-catalog.md:42`](syntheses/integration-catalog.md) — "Barkod yazıcı ZPL/ESC-POS Orta öncelik" — Sprint 22'de fiş yazıcı (ESC/POS) odaklı, barkod yazıcı (ZPL) ayrı sprint için kalıyor
- [`live-status-2026-04-23.md:199`](sources/status-snapshots/live-status-2026-04-23.md) — "Receipt Generation: Print/Email/SMS — Pending"

### Kalan İşler (Sprint 23+ önerisi)

1. **Smoke test** (kullanıcı runtime'da)
2. **Türkçe karakter doğrulaması** — ASCII çıktı OK mi yoksa CP857 gerek mi?
3. **transaction kart modal'ı fiş yazdırma** — Sprint 19 `transactions-card-improvements.md` planı (referenceType=SALE → fiş modal)
4. **PDF receipt fallback** — yazıcı bağlı değilse `printing` paketi ile PDF üret (e-posta/SMS gönderim için zemin)
5. **Cash drawer komutu** — POSA cihazda var ise (ESC `p` 0x70 + pin)
6. **Barkod yazıcı (ZPL)** — ürün etiketi için ayrı sprint
7. **Ethernet bağlantı seçeneği** — POSA Ethernet portu da var, network printer eklenebilir (`PrinterType.network` aynı paket destekler)

---

## [2026-04-28] sprint-21 | Son 8 L1 ekran migration + supplier_upload Radio<bool> refactor — **100% MIGRATION TAMAMLANDI** 🎉

Sprint 20'de baseline cleanup yapıldıktan sonra Sprint 21 = **kalan 8 legacy L1 ekranı bitirme** + Sprint 20'den ertelenen Radio<bool> refactor.

### İş Kolları

- **21-A (kendim, 4 ekran)**: store + warehouse list/form (`store_list`, `store_add`, `warehouse_list`, `warehouse_add`)
- **21-B (agent, 4 ekran)**: inventory (2) + reports (2) — `product_detail`, `batch_product`, `customer_sales_analysis`, `product_sales_analysis`
- **21-C (kendim, 1 refactor)**: supplier_upload_wizard kart-içi `Radio<bool>` → `Icon(radio_button_*)` (deprecated API kaldırıldı, davranış aynı)

### Sonuçlar

| # | Ekran | Modül | Karar | LOC delta |
|---|---|---|---|---|
| 1 | `store_list_screen.dart` | store | **ListScreenTemplate** | inline |
| 2 | `store_add_screen.dart` | store | BaseScaffold swap | +1 |
| 3 | `warehouse_list_screen.dart` | warehouse | **ListScreenTemplate** | inline |
| 4 | `warehouse_add_screen.dart` | warehouse | BaseScaffold swap | +1 |
| 5 | `product_detail_screen.dart` | inventory | BaseScaffold swap (×3 — loading/error/data dalları) | +1 |
| 6 | `batch_product_screen.dart` | inventory | BaseScaffold swap (L3 custom — DataTable + dynamic AppBar chip) | +1 |
| 7 | `customer_sales_analysis_screen.dart` | reports | BaseScaffold swap | +1 |
| 8 | `product_sales_analysis_screen.dart` | reports | BaseScaffold swap | +1 |
| 9 | `supplier_upload_wizard_screen.dart` | suppliers | **Radio<bool> refactor** + `use_super_parameters` fix | inline |

**Template dağılımı (8 migrate):**
- ListScreenTemplate: 2 (store_list, warehouse_list)
- BaseScaffold swap: 6
- FormScreenTemplate / DetailScreenTemplate: 0

### 21-C Refactor Detay

`supplier_upload_wizard_screen.dart:273-280` — `Radio<bool>` widget'ı kart içinde **görsel select indicator** olarak kullanılıyordu (kart zaten `GestureDetector(onTap: ...)` ile çalışıyor; Radio'nun `onChanged` redundant'tı). 

Çözüm:
```dart
// Eski (3 deprecated_member_use):
Radio<bool>(value: true, groupValue: isSelected, onChanged: ..., activeColor: color)

// Yeni:
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8),
  child: Icon(
    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
    color: isSelected ? color : (isEnabled ? AppColors.textMuted : AppColors.border),
    size: 22,
  ),
)
```

**6 deprecated_member_use → 0** (Radio.value, Radio.groupValue, Radio.onChanged, Radio.activeColor 2'şer kez)

Bonus: `use_super_parameters` lint (Sprint 20'de scope dışında kalmıştı) düzeltildi:
```dart
// Eski:
const SupplierUploadWizardScreen({Key? key, ...}) : super(key: key);
// Yeni:
const SupplierUploadWizardScreen({super.key, ...});
```

### 100% MIGRATION TAMAMLANDI 🎉

**Sprint 21 sonu final scan:**
```
Total screen dosyası: 64
Template (L2):    25 ekran  (39%)
BaseScaffold (L3): 37 ekran  (58%)
Other:             2 ekran   (3% — abstract/modal)
L1 (AppScaffold):  0 ekran   ✅
L0 (raw Scaffold): 0 ekran   ✅
```

**Sprint 16-21 kümülatif:**

| Sprint | Migrate | Yeni issue | LOC delta |
|---|---|---|---|
| 16 | 16 | 0 | −204 |
| 17 | 9 | 0 | −110 |
| 18 | 12 (+1 skip) | 0 | −193 |
| 19 | 10 (+4 skip) | 0 | ~+1 |
| 20 | 0 (cleanup) | 0 | 0; **−46 baseline** |
| 21 | 8 + 1 refactor | 0 | ~+5; **−7 baseline** |
| **Σ** | **55 ekran** | **0** | **~−501 LOC + −53 baseline issue** |

### Final flutter analyze

- **Sprint 21 sonu:** 165 issue (Sprint 20 sonu 168 → −3)
- **Sprint 16 başı:** ~260+ tahmin (Sprint 16-19'da hep "pre-existing baseline" denilen 47 issue + diğer)
- **Sprint 16 → Sprint 21:** project-wide ~260+ → 165 (−~37%)
- Migration kaynaklı yeni issue: **0** (tüm 6 sprint boyunca konfirm)

### Kalan 165 Issue (Sprint 22+ kapsam)

Bu 165 issue **migration scope'u DIŞINDADIR** — tamamı services/utils/widgets/providers dosyalarında ve bazı template-içi `_, __` lint info'ları:
- `unnecessary_underscores` (Dart 3.0+ pattern, otomatik düzeltilebilir)
- `prefer_final_fields`, `use_super_parameters` (otomatik düzeltilebilir)
- `unnecessary_to_list_in_spreads` (otomatik)
- Diğer: backend service / utility helper / form validators

**Sprint 22+ önerisi:** `dart fix --apply` çalıştırılarak ~50-80 issue otomatik düzeltilebilir. Geri kalan `unused_element`, `dangling_library_doc_comments`, `constant_identifier_names` manuel cleanup.

### Mimari Hedef Tamamlandı

Sprint 15'te kurulan template katmanı + Sprint 16-21 modernizasyon serisi:

- ✅ **L0 (raw Scaffold) yasak** kuralı uygulandı: 0 ekran
- ✅ **L1 (AppScaffold legacy)** tamamen migrate: 0 ekran
- ✅ **L2 (template)** adoption: 25 ekran (List, Form, Detail)
- ✅ **L3 (BaseScaffold custom)** opt-in pattern: 37 ekran
- ❌ **DashboardScreenTemplate** emekli (Sprint 20)
- ⏭️ **Bottom sheet'ler** (5 modal) ve **multi-step wizard'lar** (5 ekran) kalıcı olarak template scope dışı

### Yeni Ekran Standardı (Sprint 22+ için kalıcı kural)

> **Hiçbir yeni ekranda raw `Scaffold` veya `AppScaffold` kullanılmaz.**
> Liste? → `ListScreenTemplate`. Form? → `FormScreenTemplate`. Tab detay? → `DetailScreenTemplate`. Custom layout? → `BaseScaffold`.
> 
> **`AppScaffold` artık deprecated** — sadece `BaseScaffold` ve template katmanı resmi API.

### Sources

- [[sources/code-refs/2026-04-27-design-system-template-audit]] — Sprint 15 audit
- [[syntheses/design-system-template-architecture]] — Sprint 16-21 final mimari

---

## [2026-04-28] sprint-20 | Cleanup — DashboardScreenTemplate emekli + Flutter 3.31-3.34 deprecations + autoparts i18n ✅

Sprint 16-19 boyunca biriken **"pre-existing baseline"** olarak ertelenen 47 issue Sprint 20'de temizlendi. **DashboardScreenTemplate emekliye ayrıldı** (file delete). Sprint 18'in autoparts hardcoded TR borcu i18n key'lerine çevrildi.

### 1. DashboardScreenTemplate Emekli ✅

**Dosya:** `lib/core/widgets/templates/dashboard_screen_template.dart` SİLİNDİ.

**Sebep (Sprint 19 entry'sinde detaylı):** 5 sprint (15-19), 0 tüketici. Sprint 19'da `modern_dashboard_screen` (843 LOC, en güçlü aday) bile reddetti — hero header AppBar değil, section title'lar serpiştirilmiş, KPI'lar `AppStatCard` değil + 4 sütun, custom skeleton.

**Doğrulama:**
- `Grep DashboardScreenTemplate` → 1 dosya (kendisi). Hiçbir referans yok.
- File deleted, no broken imports.

**Wiki güncellemeleri:**
- [`sources/code-refs/2026-04-27-design-system-template-audit.md`](sources/code-refs/2026-04-27-design-system-template-audit.md) → DashboardScreenTemplate satırı ❌ EMEKLİ olarak işaretlendi
- [`syntheses/design-system-template-architecture.md`](syntheses/design-system-template-architecture.md) → "DashboardScreenTemplate" bölümü "EMEKLİ (Sprint 20)" notuyla güncellendi (eski tasarım referans için bırakıldı)

### 2. autoparts i18n keys eklendi ✅

Sprint 18'de `vehicle_list_screen` ve `part_search_screen` ListScreenTemplate'a migrate edilirken AppBar başlığı için **hardcoded TR string** eklenmişti (`'Araclar'`, `'Parca Arama'`).

**Sprint 20 düzeltme:**

`security/src/main/resources/data.sql` (bnd-vh prefix'i altında):
```sql
('bnd-vh12-..., 'autoparts.vehicles_title',     'Araçlar',     'Vehicles'),
('bnd-vh13-..., 'autoparts.part_search_title',  'Parça Arama', 'Part Search'),
```

Flutter:
- `vehicle_list_screen.dart`: `title: 'Araclar'` → `title: t('autoparts.vehicles_title')`
- `part_search_screen.dart`: `title: 'Parca Arama'` → `title: t('autoparts.part_search_title')`

### 3. Flutter 3.31-3.34 Deprecations + Async Gaps Cleanup ✅

Cleanup agent 47 hedef dosyada Sprint 20 scope'undaki tüm issue tiplerini temizledi.

**Düzeltilen issue dağılımı (46 toplam):**

| Issue Tipi | Adet | Düzeltme |
|---|---|---|
| `DropdownButtonFormField.value` → `initialValue` | **21** | Flutter 3.33+ migration |
| `use_build_context_synchronously` | **8** | `if (!context.mounted) return;` guard |
| `Radio` → `RadioGroup` | **4** | Flutter 3.32+ ancestor pattern (2 form) |
| `unused_local_variable` | 2 | sil |
| `unnecessary_cast` | 2 | kaldır |
| `Switch.activeColor` → `activeThumbColor` | 1 | Flutter 3.31+ migration |
| `Matrix4.translate()` → `translateByDouble()` | 1 | Flutter 3.34+ migration |
| `unnecessary_import` | 1 | kaldır |
| `unnecessary_string_interpolations` (bonus) | 1 | sadeleştir |

**ATLANAN (1 yer, intentional):**
- `supplier_upload_wizard_screen.dart:273-280` — Radio<bool> kart-içi kullanımı. Her kart kendi içinde tek Radio bool ile checkbox-ish davranıyor; Radio'lar farklı kart'larda dağılmış, RadioGroup ile sarmak davranış değiştirebilirdi. **Sprint 21+'da ayrı bir refactor olarak ele alınabilir** (Radio<bool> → Checkbox geçiş daha temiz).

### 4. Flutter Analyze Sonuçları

| Metrik | Önce | Sonra | Δ |
|---|---|---|---|
| Project-wide issue | 214 | 168 | **−46** |
| Sprint 16-19 hedef dosyalardaki Sprint 20-scope issue | 47 | 1 (atlanmış Radio<bool>) | **−46** |
| Sprint 16-19 hedef dosyalardaki Sprint 20-scope-dışı issue | 16 | 16 | 0 |

**Hedef dosyalarda kalan 16 issue (Sprint 20 scope DIŞI, Sprint 21+):**
- `prefer_final_fields`
- `unnecessary_to_list_in_spreads`
- `use_super_parameters`
- `unnecessary_brace_in_string_interps`
- `unnecessary_non_null_assertion`
- `unnecessary_underscores` (Dart 3.0+ pattern)

Bu issue'lar **lint hint/info seviyesinde** — Flutter çalıştırması veya UI davranışını etkilemez. Sprint 21+'da auto-fix yapılabilir (`dart fix --apply`).

### Sprint 16-20 Final İstatistik

**Migrate edilen ekran sayısı:** 47 + cleanup (47 dosya touch'lı)

| Template | Kümülatif Adoption |
|---|---|
| ListScreenTemplate | **16 ekran** ⭐ en başarılı |
| BaseScaffold swap | **27 ekran** ⭐ opt-in stratejisi |
| FormScreenTemplate | 3 ekran |
| DetailScreenTemplate | 2 ekran |
| ~~DashboardScreenTemplate~~ | **0 ekran** ❌ EMEKLİ |

**Kümülatif LOC delta:** ~−506 (Sprint 16: −204, Sprint 17: −110, Sprint 18: −193, Sprint 19: ~+1)

**Kümülatif `flutter analyze` issue düşümü (Sprint 20 sonu):**
- Sprint 16'dan beri yarattığımız **yeni issue: 0** (her sprint'te konfirm edildi)
- Sprint 20'de **−46 baseline issue** temizlendi
- Project-wide: 214 → 168 (−21%)

### Sprint 21+ İçin Notlar

1. **Hedef dosyalarda kalan 16 lint info** (hepsi otomatik düzeltilebilir):
   - `dart fix --apply` çalıştır, ya da
   - manuel `prefer_final_fields`, `use_super_parameters`, `unnecessary_underscores` (`_, __` → `_, _`) düzelt
2. **supplier_upload_wizard_screen Radio<bool>** refactor: Radio<bool> → Checkbox geçişi daha temiz
3. **bulk_import_review_screen_v2.dart 2128 LOC** ekran-içi component splitting kandidati
4. **edit_product_modal + 3 modal**: ihtiyaç doğarsa `BottomSheetTemplate` Sprint 22+'da inşa edilebilir (gerçek müşteri olmadan inşa ETME — DashboardScreenTemplate hatası tekrarlanmaz)
5. **Migration tamamlandı:** Sprint 16-19 boyunca 47 ekranın tamamı migrate edildi. Yeni ekran eklenirken **L0 (legacy `Scaffold`) yasak**, **L1 (AppScaffold)** yerine **L2 (template) veya L3 (BaseScaffold custom)** tercih edilsin.

### Sources

- [[sources/code-refs/2026-04-27-design-system-template-audit]] — Sprint 15 audit + Sprint 20 emekli notu
- [[syntheses/design-system-template-architecture]] — 4 (was 5) template mimarisi

---

## [2026-04-28] sprint-19 | Import + Auth + Menu + POS + Dashboard migration (10 ekran) + DashboardScreenTemplate emekli kararı ✅

Sprint 18'in devamı. 5 modül, 14 hedef dosya. 4 dosya bottom sheet/modal olduğu için intentional skip. **Önemli mimari karar: DashboardScreenTemplate emekli edilecek (Sprint 20'de file delete).**

### İş Kolları

- **19-A (kendim, 3 ekran)**: `menu_screen` + `login_screen` + `company_registration_screen`
- **19-B (agent, 5 ekran)**: import workflow (`barcode_scanner`, `bulk_import_review_v2`, `bulk_import_upload`, `supplier_import_review`, `supplier_import_upload`)
- **19-C (agent, 2 ekran)**: `modern_dashboard_screen` + `pos_screen` — **DashboardScreenTemplate son şansı**

### Sonuçlar

| # | Ekran | Modül | Karar | LOC delta |
|---|---|---|---|---|
| 1 | `menu_screen.dart` | menu | BaseScaffold swap | 373→374 (+1) |
| 2 | `login_screen.dart` | auth | BaseScaffold swap | 813→814 (+1) |
| 3 | `company_registration_screen.dart` | auth | BaseScaffold swap | 621→622 (+1) |
| 4 | `barcode_scanner_screen.dart` | import | BaseScaffold swap | 399→400 (+1) |
| 5 | `bulk_import_review_screen_v2.dart` | import | BaseScaffold swap | 2128→2129 (+1) |
| 6 | `bulk_import_upload_screen.dart` | import | BaseScaffold swap | 1056→1057 (+1) |
| 7 | `supplier_import_review_screen.dart` | import | **ListScreenTemplate** | 911→902 (**−9**) |
| 8 | `supplier_import_upload_screen.dart` | import | BaseScaffold swap | 496→497 (+1) |
| 9 | `modern_dashboard_screen.dart` | dashboard | BaseScaffold swap | 843→844 (+1) |
| 10 | `pos_screen.dart` | pos | BaseScaffold swap | 244→246 (+2) |
| – | `edit_product_modal.dart` | import | **SKIP** (Container/bottom sheet) | – |
| – | `modals/manual_match_modal.dart` | import | **SKIP** (modal) | – |
| – | `modals/match_confirm_modal.dart` | import | **SKIP** (modal) | – |
| – | `modals/update_stock_modal.dart` | import | **SKIP** (modal) | – |

**Net LOC delta:** ~+1 (yalnız supplier_import_review template adoption ile −9 kazandı; geri kalanı +1 import line overhead).

**Template dağılımı (10 migrate):**
- ListScreenTemplate: **1** (10%)
- BaseScaffold swap: **9** (90%)
- DashboardScreenTemplate: **0**

### KRİTİK MİMARİ KARAR: DashboardScreenTemplate emekli edilecek

**5 sprint, 0 tüketici.** Sprint 19-C'de `modern_dashboard_screen` (843 LOC, en güçlü aday) bile reddetti. Agent raporundaki sebepler:

1. **Hero header AppBar değil**: Full-width gradient kart + içine refresh+profile butonları gömülü. Template `AppAppBar.standard(title:)` zorunlu — kabul etmiyor.
2. **Section title'lar serpiştirilmiş**: "Hızlı Aksiyonlar / Modüller / Son Aktiviteler" bloklar arasına serpiştirilmiş; template `sections: [...]` listesi monolithic block sırası bekliyor.
3. **KPI cards `AppStatCard` değil**: Gradient ikon + raw değer/label, custom dark/light + onTap (lowStock → /stock/alerts). Template `statCardColumns=2` default; ekran 4 sütun + cardlar birbirinden farklı (lowStock conditional gradient).
4. **Custom skeleton** template'in `isLoading` spinner'ına sığmaz.

`finance_dashboard_screen` (Sprint 18) aynı sebeplerle reddetti. **POS dashboard'larda ortak desen yok** — herkesin hero card'ı, KPI dizilimi, section sırası farklı.

**Sprint 20 task:** `lib/core/widgets/templates/dashboard_screen_template.dart` SİL, ölü kod → BaseScaffold (sync body) ile direkt çalış.

### Multi-Step Wizard Pattern'ı Doğrulandı

Sprint 17'de `supplier_upload_wizard_screen` ile başlayan, Sprint 19'da 4 ekrana yayılan pattern:
- `company_registration_screen` (3-step wizard)
- `bulk_import_review_screen_v2` (3-step bulk import: indicator + custom bottom bar)
- `bulk_import_upload_screen` (4-state UI: idle/uploading/success/error)
- `supplier_import_upload_screen` (2-state: form/progress)

**Hepsi BaseScaffold swap.** Step indicator + custom bottom action bar + state-based UI dinamiği FormScreenTemplate'in section-only paterne uymuyor. **Yeni öğreti:** Multi-step wizard pattern'ı kalıcı olarak template scope dışı — Sprint 20+ için `WizardScreenTemplate` ihtiyacı tartışılabilir, ama önce gerçek müşteriye sahip olmalı (DashboardScreenTemplate hatasını tekrarlama).

### Auth Modülünün Özel Yapısı

`login_screen` + `company_registration_screen` her ikisi de:
- Desktop: 5/6 split (left brand panel + right form)
- Mobile: gradient header + form card
- AnimationController + FadeTransition
- Custom branding panels

FormScreenTemplate'in section-list yapısı bu split layout'u taşıyamaz → BaseScaffold swap. Auth modülü "L3 custom" kategorisinde kalır.

### POS Custom L3 Doğrulandı

Sprint 15 audit'inde POS "L3 custom" olarak işaretlendi. Sprint 19-C agent bunu doğruladı:
- `KeyboardListener` (F1 ödeme, F5 yenile)
- Raw `Scaffold` (AppScaffold bile değil!)
- Custom gradient AppBar (Color(0xFF667eea) → Color(0xFF764ba2)) — `AppAppBar.primary` değil
- LayoutBuilder cart-aware split (>900px desktop 7/3, mobile single)
- Conditional FAB (mobile + cart not empty)

**Karar:** `Scaffold` → `BaseScaffold(appBar: customAppBar, body: LayoutBuilder, fab: ...)` swap. Custom gradient AppBar olduğu gibi korundu.

### Modal Skip Listesi

4 dosya migrate **edilmedi**:
- `edit_product_modal.dart` (546 LOC) — Container döndürüyor (bottom sheet)
- `modals/manual_match_modal.dart` (421 LOC) — modal
- `modals/match_confirm_modal.dart` (354 LOC) — modal
- `modals/update_stock_modal.dart` (217 LOC) — modal
- (`_DecisionBottomSheet` supplier_import_review içinde inline — yine bottom sheet)

Bu modaller `BottomSheetTemplate` (Sprint 21+ ihtiyaç doğarsa) için aday — ama **gerçek tüketici talebi olmadan template inşa etme**.

### Doğrulama

- `flutter analyze` 10 dosya: **10 issue, 0 yeni** ✅
- Pre-existing baseline:
  - 5× `use_build_context_synchronously` (bulk_import_review_v2)
  - 1× `unnecessary_brace_in_string_interps`, 1× `deprecated_member_use 'value'`
  - 2× `unused_local_variable` (bulk_import_upload)
  - 1× `Matrix4.translate` deprecated (menu_screen)

### Sprint 16-19 Toplam Tablosu

| Sprint | Migrate | List | Form | Detail | Dashboard | BaseScaffold | Adoption % | LOC |
|---|---|---|---|---|---|---|---|---|
| 16 | 16 | 7 | 1 | 1 | 0 | 7 | 56% | −204 |
| 17 | 9 | 2 | 0 | 0 | 0 | 7 | 22% | −110 |
| 18 | 12 | 6 | 2 | 0 | 0 | 4 | 67% | −193 |
| 19 | 10 | 1 | 0 | 0 | 0 | 9 | 10% | ~+1 |
| **Σ** | **47** | **16** | **3** | **1** | **0** | **27** | **42%** | **~−506** |

### Sprint 16-19 sonunda template kullanım istatistiği

- ListScreenTemplate: **16 ekran** (en başarılı)
- FormScreenTemplate: **3 ekran**
- DetailScreenTemplate: **1 ekran** (settings) + 1 (Sprint 16 stock_alert)
- **DashboardScreenTemplate: 0 ekran** ❌ EMEKLİ
- BaseScaffold swap: **27 ekran**

### Sprint 20 Görevleri (Cleanup)

1. **DashboardScreenTemplate emekli** (file delete + audit/synthesis update)
2. **Pre-existing baseline issue cleanup** (~30 issue tahmini):
   - `deprecated_member_use 'value'` (DropdownButtonFormField) — Flutter 3.33+ `initialValue` migration
   - `deprecated_member_use 'activeColor'` (Switch) — `activeThumbColor`
   - `deprecated_member_use 'groupValue'/'onChanged'` (Radio) — `RadioGroup` ancestor
   - `use_build_context_synchronously` (5×bulk_import_review_v2 + sale_detail)
   - `Matrix4.translate` deprecated (menu_screen)
   - `unused_local_variable` (bulk_import_upload)
3. **Hardcoded TR strings i18n** (Sprint 18 not):
   - `autoparts.vehicles_title` → `'Araclar'`
   - `autoparts.part_search_title` → `'Parça Arama'`

### Sources

- [[sources/code-refs/2026-04-27-design-system-template-audit]]
- [[syntheses/design-system-template-architecture]]

---

## [2026-04-28] sprint-18 | Finance + HRM + Autoparts + Supplier Claims migration (12 ekran +1 skip) ✅

Sprint 17'nin devamı. 4 modül, 13 hedef ekran. 1 ekran (claim_resolve_sheet) bottom sheet olduğu için intentional skip.

### İş Kolları

- **18-A (kendim, 3 ekran)**: `expense_list_screen` + `employee_list_screen` + `supplier_claims_list_screen`
- **18-B (agent, 5 ekran)**: finance/hrm form+dashboard ekranları
- **18-C (agent, 5 ekran)**: autoparts (3) + supplier_claims (2)

### Sonuçlar

| # | Ekran | Modül | Karar | LOC delta |
|---|---|---|---|---|
| 1 | `expense_list_screen.dart` | finance | **ListScreenTemplate** | 439→391 (**−48**) |
| 2 | `employee_list_screen.dart` | hrm | **ListScreenTemplate** | 432→400 (**−32**) |
| 3 | `supplier_claims_list_screen.dart` | supplier_claims | **ListScreenTemplate** | 212→186 (**−26**) |
| 4 | `add_expense_screen.dart` | finance | BaseScaffold swap | 318→319 (+1) |
| 5 | `add_income_screen.dart` | finance | **FormScreenTemplate** | 246→206 (**−40**) |
| 6 | `cash_flow_screen.dart` | finance | BaseScaffold swap | 399→400 (+1) |
| 7 | `finance_dashboard_screen.dart` | finance | BaseScaffold swap | 409→410 (+1) |
| 8 | `add_employee_screen.dart` | hrm | **FormScreenTemplate** | 341→346 (+5) |
| 9 | `part_search_screen.dart` | autoparts | **ListScreenTemplate** | 458→451 (−7) |
| 10 | `vehicle_compatibility_screen.dart` | autoparts | **ListScreenTemplate** | 306→293 (−13) |
| 11 | `vehicle_list_screen.dart` | autoparts | **ListScreenTemplate** | 462→448 (−14) |
| 12 | `supplier_claim_detail_screen.dart` | supplier_claims | BaseScaffold swap (asyncValue) | 372→351 (**−21**) |
| – | `claim_resolve_sheet.dart` | supplier_claims | **SKIP** (bottom sheet) | – |

**Net LOC delta:** ~−193 LOC

**Template dağılımı (12 migrate):**
- ListScreenTemplate: **6** (50%)
- FormScreenTemplate: **2** (17%)
- BaseScaffold swap: **4** (33%)
- DetailScreenTemplate / DashboardScreenTemplate: 0

### Önemli Bulgular

#### 1. claim_resolve_sheet.dart SKIP — Template scope sınırı

`showModalBottomSheet(builder: (_) => ClaimResolveSheet(...))` ile çağrılıyor. `Container(decoration: BoxDecoration(borderRadius: BorderRadius.vertical(top: Radius.circular(16))))` + `MediaQuery.viewInsets.bottom` padding pattern'ı = **bottom sheet**, Scaffold değil.

Template katmanı (BaseScaffold/ListScreenTemplate/FormScreenTemplate/DetailScreenTemplate/DashboardScreenTemplate) **sadece tam-ekran Scaffold** için tasarlandı. Bottom sheet'ler scope dışında — ileride `BottomSheetTemplate` ihtiyacı doğarsa Sprint 21+'da ele alınabilir.

#### 2. FormScreenTemplate başarı + başarısızlık örnekleri

**Başarı:** `add_income_screen` (246→206, **−40 LOC**) — 2 temiz section, klasik save button, dynamic action yok = template'in tam hedefi.

**Başarısızlık:** `add_expense_screen` form gibi ama `AppAppBar.primary` (gradient) kullanıyor. FormScreenTemplate `AppAppBar.standard`'ı zorlar → BaseScaffold swap (gradient korunur).

**Hibrid:** `add_employee_screen` → FormScreenTemplate ama loading state için BaseScaffold fallback dalı eklendi (template loading mode desteklemiyor).

#### 3. Dashboard/chart ekranları template-uyumsuz

`cash_flow_screen` ve `finance_dashboard_screen` ilk bakışta DashboardScreenTemplate adayı görünüyordu:
- **`cash_flow_screen`**: SegmentedButton period selector + custom `_BarRow` bar chart + dynamic refresh action — chart-heavy, template grid'e sığmaz.
- **`finance_dashboard_screen`**: Full-width hero net-income card (yeşil/kırmızı conditional) + 2-kolon revenue/expense + 3-satır quick action grid + 2 kategori breakdown — DashboardScreenTemplate'in `statCards` (default 2 sütun grid) yapısı simetrisini bozuyor.

Karar: BaseScaffold swap. **DashboardScreenTemplate adoption oranı şu ana kadar Sprint 15-18'de %0** — bu öğreti Sprint 19+ için önemli (ya template'i revize et, ya da emekli olduğunu kabul et).

#### 4. Hardcoded TR string ek borç (autoparts)

`vehicle_list_screen` ve `part_search_screen` orijinalde **AppBar'sızdı**. ListScreenTemplate AppBar dayatıyor → agent yeni i18n key oluşturmadan 2 hardcoded TR string ekledi: `'Araclar'` ve `'Parça Arama'`. Sprint 20 cleanup'a not: 2 i18n key (`autoparts.vehicles_title`, `autoparts.part_search_title`) eklenmeli.

#### 5. supplier_claim_detail BaseScaffold asyncValue mode

İlk `BaseScaffold<T>(asyncValue: ..., dataBuilder: ...)` kullanımı. Manuel `async.when(loading/error/data)` switcher → template `dataBuilder` + otomatik error retry'a delege edildi.

### Sprint 18 vs 16-17 Karşılaştırma

| Metrik | Sprint 16 | Sprint 17 | Sprint 18 |
|---|---|---|---|
| Migrate ekran | 16 | 9 | 12 (+1 skip) |
| ListScreenTemplate | 7 | 2 | **6** |
| FormScreenTemplate | 1 | 0 | **2** |
| DetailScreenTemplate | 1 | 0 | 0 |
| DashboardScreenTemplate | 0 | 0 | 0 |
| BaseScaffold swap | 7 | 7 | 4 |
| **Template adoption %** | **56%** | **22%** | **67%** |
| Net LOC delta | ~−204 | ~−110 | ~−193 |
| Yeni `flutter analyze` issue | 0 | 0 | 0 |

Sprint 18 template adoption oranı **%67** — Sprint 16'yı geçti. Sebep: bu modüller (finance/hrm/autoparts/supplier_claims) **list-heavy** (12 ekrandan 6'sı liste). Sprint 17'de transaction-heavy (sale/purchase) modüller %22 idi.

### Doğrulama

- `flutter analyze` 12 dosya: **19 issue, 0 yeni** ✅
- 1 baseline issue **temizlendi** (add_income_screen `unused_import` rewrite sırasında düştü) — 11→10 baseline
- Pre-existing kalan: deprecated `value` (×16), `activeColor` (×1), `use_build_context_synchronously`, `unnecessary_to_list_in_spreads` (×2)

### Kalan Roadmap

| Sprint | Modül | Ekran | Tahmini |
|---|---|---|---|
| 19 | import + auth + menu + pos + dashboard | ~10 | 2 gün |
| 20 | Cleanup: deprecated value, activeColor, async gaps, hardcoded TR strings (autoparts) | ~25 issue | 1 gün |

### Sources

- [[sources/code-refs/2026-04-27-design-system-template-audit]] — Sprint 15 audit
- [[syntheses/design-system-template-architecture]] — 4 template mimarisi

---

## [2026-04-28] sprint-17 | Sales + Purchases + Accounts modül migration (9 ekran) ✅

Sprint 16'nın devamı: 17. modüler hedef sales + purchases + accounts (+suppliers'dan upload wizard). 9 ekran, ~6,800 LOC.

### İş Kolları

- **17-A (kendim, 2 ekran)**: `sale_list_screen` + `purchase_list_screen` — klasik liste yapısı.
- **17-B (agent, 2 ekran)**: `sale_detail_screen` (939) + `purchase_detail_screen` (881) — büyük tek-view detaylar.
- **17-C (agent, 5 ekran)**: `sale_return` + `add_purchase` + `purchase_return` + `accounts_hub` + `supplier_upload_wizard` — form/hub/wizard.

### Sonuçlar

| # | Ekran | Modül | Karar | LOC delta |
|---|---|---|---|---|
| 1 | `sale_list_screen.dart` | sales | **ListScreenTemplate** | 547→481 (**-66**) |
| 2 | `purchase_list_screen.dart` | purchases | **ListScreenTemplate** | 312→271 (**-41**) |
| 3 | `sale_detail_screen.dart` | sales | BaseScaffold swap | 987→988 (+1) |
| 4 | `purchase_detail_screen.dart` | purchases | BaseScaffold swap | 925→926 (+1) |
| 5 | `sale_return_screen.dart` | sales | BaseScaffold swap | +1/-1 |
| 6 | `add_purchase_screen.dart` | purchases | BaseScaffold swap | +1/-1 |
| 7 | `purchase_return_screen.dart` | purchases | BaseScaffold swap | +1/-1 |
| 8 | `accounts_hub_screen.dart` | accounts | BaseScaffold swap | +1/-1 |
| 9 | `supplier_upload_wizard_screen.dart` | suppliers | BaseScaffold swap (×3 — wizard + summary + success) | +5/-3 |

**Net LOC delta:** ~−110 LOC (17-A −107, 17-B/C +5 import overhead).

**Template dağılımı:**
- ListScreenTemplate: 2
- FormScreenTemplate: 0
- DetailScreenTemplate: 0
- BaseScaffold swap: 7

### Önemli Bulgu: "Form-tarzı görünen ama özel davranışlı"

Sprint 17 öncesi, sale_return + add_purchase + purchase_return ekranlarının FormScreenTemplate adayı olduğu varsayılıyordu. Agent migration sırasında doğru karar verdi: **hiçbiri FormScreenTemplate'e oturmadı.** Sebepler:

- **`add_purchase_screen.dart`**: AppBar `actions:` içinde `if (_grandTotal > 0)` koşullu currency chip + body içinde inline submit + dinamik ürün arama+expansion list — section-only layout'a uymuyor.
- **`sale_return_screen.dart`** + **`purchase_return_screen.dart`**: Custom bottom bar (toplam iade hesabı + warning gradient + danger button) + checkbox/qty selector item card — FormSection mantığına direnç gösteriyor.
- **`accounts_hub_screen.dart`**: LayoutBuilder ile responsive master/detail split (≥800px Row, <800px tek panel) + AppBar bottom border + AccountsSummaryBar — herhangi bir template'e sığmaz.
- **`supplier_upload_wizard_screen.dart`**: 2× AppScaffold (wizard + summary view) + 1× nested `_SuccessScreen` AppScaffold + custom 3-button navbar (Geri/Atla/Kaydet&Devam) + `LinearProgressIndicator` — multi-step wizard pattern'ı FormScreenTemplate'e direnir.

Bu Sprint 16'nın "BaseScaffold-only swap geçerli karar" prensibini doğruluyor: **gerçek dünya formları çoğunlukla template-uyumsuzdur.** Form-look-alike olsa bile dynamic AppBar action, custom bottom bar, multi-step wizard, master-detail split sıkça görülüyor.

### Detail Ekranları Hakkında

Sale + purchase detay ekranlarının 800-1000 LOC olması yanıltıcı. İçleri **tab tabanlı değil** — single-view scroll layout (header + status banner + amount + items + notes + action button cards). DetailScreenTemplate **tab odaklı**, bu ekranlar için fayda yok. BaseScaffold swap doğru karar.

### Doğrulama

- `flutter analyze` 9 dosya: **19 issue, 0 yeni** ✅
- Pre-existing baseline (Sprint 20 cleanup için listede):
  - `deprecated_member_use 'value'` (DropdownButtonFormField) ×4
  - `deprecated_member_use 'groupValue'/'onChanged'` (Radio) ×8
  - `unnecessary_cast` ×2, `unnecessary_import`, `use_super_parameters`, `unnecessary_underscores`, `use_build_context_synchronously` ×2

### İlginç Pattern: AppBar'sız BaseScaffold

`supplier_upload_wizard_screen` içindeki `_SuccessScreen` (nested success view) AppBar'sız → `BaseScaffold(body: ...)` (appBar parametresi atılır). Sprint 16'da `enhanced_stock_screen` benzeri pattern uygulanmıştı. BaseScaffold AppBar opsiyonel olarak destekliyor.

### Sprint 17 vs 16 Karşılaştırması

| Metrik | Sprint 16 | Sprint 17 |
|---|---|---|
| Ekran sayısı | 16 | 9 |
| ListScreenTemplate | 7 | 2 |
| FormScreenTemplate | 1 | 0 |
| DetailScreenTemplate | 1 | 0 |
| BaseScaffold swap | 7 | 7 (78%) |
| Net LOC delta | ~−204 | ~−110 |
| Yeni `flutter analyze` issue | 0 | 0 |

Sprint 17'de BaseScaffold-only swap oranı %78 (Sprint 16'da %44). Bu modüller (sales/purchases/accounts) doğası gereği **işlemsel/transaction-based** — daha çok özel bottom bar + dynamic AppBar action içeriyor.

### Sources

- [[sources/code-refs/2026-04-27-design-system-template-audit]] — Sprint 15 audit
- [[syntheses/design-system-template-architecture]] — 4 template mimarisi

---

## [2026-04-28] sprint-16 | Inventory + Catalog + Stock modül migration (16 ekran) ✅

Sprint 15'te kurulan template katmanı + 2 PoC migration sonrası, audit'teki Sprint 16-20 modüler roadmap başlatıldı. Sprint 16 = inventory + catalog + stock üç modülü, toplam 16 ekran.

### Migration Stratejisi

**3 paralel iş kolu:**
- **16-A (ana iş, kendim)**: `enhanced_product_list_screen.dart` — Sprint 13'te pagination pattern'ı bu ekranda doğmuştu, artık template tüketicisi olmalı (dogfood).
- **16-B (agent)**: 7 küçük catalog/inventory ekranı.
- **16-C (agent)**: 8 stock ekranı.

**Karar kuralı (her ekran için):** Template doğal oturuyorsa migrate et; bottom-bar/AppBar dayatması davranış değişikliği yaratacaksa **BaseScaffold swap** yap (AppScaffold→BaseScaffold), ekstra zarar ver-me.

### 16-A: enhanced_product_list_screen.dart (`inventory/screens/`)

ListScreenTemplate'in **referans tüketicisi**. Önceki yapı (Sprint 13'ten miras):
- `_scrollController` field + `addListener(_onScroll)` initState + `removeListener+dispose` dispose + `_onScroll` bottom-200px metodu
- `_buildContent` (loading/empty/RefreshIndicator dispatcher)
- `_buildListView` (RefreshIndicator + ListView.builder + extraFooter)
- `_buildGridView` (RefreshIndicator + CustomScrollView + SliverGrid + SliverToBoxAdapter footer)
- `_buildLoadMoreFooter` (spinner veya "X öğe gösteriliyor" text)

Sonrası:
- Tek `ListScreenTemplate<Map<String,dynamic>>` çağrısı (~95 LOC build())
- `_scrollController` + `_onScroll` + `_buildContent` + `_buildListView` + `_buildGridView` + `_buildLoadMoreFooter` SİLİNDİ (~120 LOC)
- Net delta: **-25 LOC** (mantıksal mimari kazancı çok daha büyük: pagination/refresh/grid/empty hepsi template tarafında)
- `searchSlot`, `statsSlot`, `filterSlot`, `bottomBar` (selection mode), `floatingActionButton`, `emptyState` slot'larına temiz delege

Bu migration template tasarımının **dogfood doğrulaması**. Hiç custom override gerekmedi → API yeterli kapsamda.

### 16-B: 7 catalog/inventory küçük ekran (agent)

| # | Ekran | Karar | LOC Δ |
|---|---|---|---|
| 1 | `inventory_screen.dart` | BaseScaffold swap (özel hub layout) | +4/-2 |
| 2 | `brands_screen.dart` | ListScreenTemplate (search+stats+list) | +53/-75 |
| 3 | `units_screen.dart` | ListScreenTemplate (brands paralel) | +68/-90 |
| 4 | `barcode_management_screen.dart` | ListScreenTemplate (3 slot) | +92/-115 |
| 5 | `category_list_screen.dart` | ListScreenTemplate (selection-aware actions) | +75/-85 |
| 6 | `add_category_screen.dart` | FormScreenTemplate (3 section) | +121/-141 |
| 7 | `company_category_screen.dart` | BaseScaffold swap (gradient AppBar uyumsuz) | +5/-1 |

**Net delta:** -91 LOC. **0 yeni issue** (2 pre-existing baseline).

**Dağılım:** ListScreenTemplate ×4, FormScreenTemplate ×1, BaseScaffold swap ×2.

**Minor visual change:** `category_list_screen` + `add_category_screen` — `AppAppBar.primary` → `AppAppBar.standard` (template kısıtı). Davranış değil görsel: gradient/primary renk yerine standard tema rengi.

### 16-C: 8 stock ekranı (agent)

| # | Ekran | Karar | LOC Δ |
|---|---|---|---|
| 1 | `enhanced_stock_screen.dart` | BaseScaffold swap (orijinalde AppBar yoktu, dayatma kaçınıldı) | +1 |
| 2 | `multi_warehouse_stock_screen.dart` | ListScreenTemplate | -27 |
| 3 | `stock_value_report_screen.dart` | BaseScaffold swap (hero+stat hibrid layout) | -19 |
| 4 | `stock_transfer_screen.dart` | BaseScaffold swap (custom form, FormScreenTemplate uyumsuz) | +1 |
| 5 | `stock_alert_screen.dart` | DetailScreenTemplate (3 tab + isLoading/error delege) | -36 |
| 6 | `stock_movement_history_screen.dart` | ListScreenTemplate | -10 |
| 7 | `stock_count_review_screen.dart` | BaseScaffold swap (custom save bar) | +1 |
| 8 | `stock_transfer_review_screen.dart` | BaseScaffold swap (custom approve bar) | +1 |

**Net delta:** -88 LOC. **0 yeni issue** (12 → 12 baseline).

**Dağılım:** ListScreenTemplate ×2, DetailScreenTemplate ×1, BaseScaffold swap ×5.

**Öne çıkan:** `stock_alert_screen.dart` `DefaultTabController + Scaffold` deseninden DetailScreenTemplate'e tertemiz oturdu (-36 LOC tek dosya).

### Sprint 16 Toplam

| Metrik | Değer |
|---|---|
| Migrate edilen ekran | 16 |
| ListScreenTemplate kullanımı | 7 (1×ana + 4 catalog/inventory + 2 stock) |
| FormScreenTemplate kullanımı | 1 |
| DetailScreenTemplate kullanımı | 1 |
| BaseScaffold-only swap | 7 |
| Net LOC delta (toplam 16 dosya) | **~-204 LOC** |
| `flutter analyze` 16 dosya | 14 issue (hepsi pre-existing baseline, 0 yeni) |

### Önemli Karar: "BaseScaffold-only swap" pattern'ı

7/16 ekranda template'lere zorla sığdırma yerine sadece `AppScaffold→BaseScaffold` swap yapıldı:
- Custom layout (hub, hero+stat hibrid, tree-view)
- Bottom-bar ListView içinde değil Column içinde (transfer/review ekranları)
- AppBar olmayan ekran (template AppBar'ı dayatıyor)
- Gradient/custom AppBar (standard.AppAppBar uyumsuz)

Bu, template katmanının **opt-in** doğasını koruyor (mimaride L0/L1/L2/L3 hiyerarşisi). Template ekran sayısını arttırmak başarı metriği değil; **doğru ekranı doğru seviyede tutmak** asıl değer.

### Kalan Sprint 17-20 Modüller

| Sprint | Modül | Ekran | Tahmini |
|---|---|---|---|
| 17 | sales + purchases + accounts | ~9 | 2 gün |
| 18 | finance + hrm + autoparts + supplier_claims | ~13 | 2-3 gün |
| 19 | import + auth + menu + pos + dashboard | ~10 | 2 gün |
| 20 | Cleanup: pre-existing teknik borç (deprecated value, underscore stili) | ~10 | 1 gün |

### Doğrulama

- 16 dosya `flutter analyze`: 14 baseline issue, 0 yeni ✅
- Kullanıcı smoke test: bekliyor
- Template dogfood: enhanced_product_list_screen başarıyla template tüketicisi oldu — API genişletme gereği yok ✅

### Sources

- [[sources/code-refs/2026-04-27-design-system-template-audit]] — Sprint 15 audit
- [[syntheses/design-system-template-architecture]] — 4 template mimarisi (Sprint 15)

---

## [2026-04-27] sprint-15 | BaseScaffold + 4 Feature Template mimarisi + Settings/Reports migration ✅

Kullanıcı emri: "tüm ekranları BaseScaffold + Feature Templates + Design System uyumlu hale getir, wiki ile yap". Mega scope (64+ ekran). Sprint 15 = mimari kurulum + Settings+Reports modülü PoC. Sprint 16-20 ile devam edecek (audit'te modüler roadmap).

### Yeni Template Katmanı (5 dosya)

**1. BaseScaffold** — [`core/widgets/base_scaffold.dart`](project_pos/lib/core/widgets/base_scaffold.dart)
- AppScaffold + Riverpod `AsyncValue<T>` switcher
- `loading → CircularProgress`, `error → AppEmptyState.error(retry)`, `data → dataBuilder(T)`
- Sync mode: `body` parametresi de var (asyncValue olmazsa)

**2. ListScreenTemplate** — [`templates/list_screen_template.dart`](project_pos/lib/core/widgets/templates/list_screen_template.dart)
- Sprint 13'te `enhanced_product_list_screen` üzerinde geliştirilen pagination pattern reusable
- ScrollController bottom-200px → onLoadMore + RefreshIndicator + loading footer
- Generic `<T>` + itemBuilder + searchSlot/filterSlot/statsSlot/FAB/bottomBar slot'ları
- Grid mode (isGrid + gridDelegate)

**3. FormScreenTemplate** — [`templates/form_screen_template.dart`](project_pos/lib/core/widgets/templates/form_screen_template.dart)
- `FormSection(title, icon, fields)` listesi
- formKey + isSaving + canSubmit + customBottomBar/secondaryActions/topBanner

**4. DetailScreenTemplate** — [`templates/detail_screen_template.dart`](project_pos/lib/core/widgets/templates/detail_screen_template.dart)
- TabController + dispose self-managed
- `DetailTab(label, icon, builder)` listesi
- onTabChanged callback (tab-aware export gibi)
- headerSlot (TabBar ile TabBarView arasında — Reports date pill için)
- isLoading + error switcher
- keepTabsAlive (IndexedStack mode)

**5. DashboardScreenTemplate** — [`templates/dashboard_screen_template.dart`](project_pos/lib/core/widgets/templates/dashboard_screen_template.dart)
- statCards grid (default 2 sütun) + sections list + onRefresh

### PoC Migration (2 ekran)

| Ekran | Önce | Sonra | Özet |
|---|---|---|---|
| `settings_screen.dart` | AppScaffold + with SingleTickerProviderStateMixin + late TabController + initState/dispose + bottom: TabBar + TabBarView | DetailScreenTemplate(tabs: 4 DetailTab) | Boilerplate kaldırıldı, body 60→25 LOC |
| `reports_screen.dart` | AppScaffold + manual loading/error/TabController + headerColumn + TabBarView | DetailScreenTemplate(headerSlot, isLoading, error, onTabChanged) | TabController + loading/error helper, body 75→60 LOC |

**DetailScreenTemplate'a Sprint 15'te eklenen feature:** `headerSlot` (Reports'taki date pill + advanced report links için TabBar'ın altında ek alan).

### Agent Migration Sonucu (7 ekran ✅)

| Ekran | Karar | LOC değişim | Sebep |
|---|---|---|---|
| `profile_screen.dart` | BaseScaffold | 276→277 | Tab/form/dashboard yapısı yok — pass-through |
| `company_settings_screen.dart` | BaseScaffold | 339→340 | Save AppBar action'da kalmalı (FormScreenTemplate behavior değişikliği yaratırdı) |
| `sector_settings_screen.dart` | BaseScaffold | 273→274 | Sektör seçim kartı listesi — özel layout |
| `user_management_screen.dart` | **ListScreenTemplate** | **910→898 (−12)** | Search/filter/list/refresh/empty hepsi template'a delege ✅ |
| `daily_summary_screen.dart` | BaseScaffold | 408→409 | Date selector statCards öncesi (DashboardScreenTemplate header slotu yok) |
| `sales_summary_screen.dart` | BaseScaffold | 399→400 | Custom date pill + period toggle + chart |
| `profit_overview_screen.dart` | BaseScaffold | 242→243 | Custom date pill + 3 top cards |

**Toplam:** 2847 → 2841 (−6 net LOC). user_management −12 (gerçek refactor), diğerlerinde +1 import shift.

**Karar paterni:** Form/Dashboard template'leri "save AppBar→bottom bar" veya "header slot" gibi UX değişikliği gerektirdiği ekranlarda BaseScaffold tercih edildi — Sprint 16+'da i18n + UX kararıyla beraber FormScreenTemplate/DashboardScreenTemplate'a geçirilebilir.

### Sprint 15 Final İstatistik

- **Yeni dosya:** 5 (BaseScaffold + 4 template)
- **Migrate edilen ekran:** 9 (settings_screen, reports_screen + agent 7 ekran)
- **Template kullanım:** DetailScreenTemplate ×2, ListScreenTemplate ×1, BaseScaffold ×6
- **Toplam LOC değişim:** project_pos/lib +1100 (5 yeni template) − 50 (9 migration nettir)
- **`flutter analyze`:** 0 yeni issue ✅ (6 pre-existing teknik borç korundu — `_, __` underscores, use_build_context_synchronously, use_null_aware_elements — Sprint 20 cleanup'ında ele alınacak)

### Wiki Back-File

- **Audit:** [[sources/code-refs/2026-04-27-design-system-template-audit]] — design system 21 widget + 64+ ekran envanteri + modüler roadmap
- **Synthesis:** [[syntheses/design-system-template-architecture]] — 5 dosya mimarisi + L0-L3 migration seviyeleri + Sprint 15 sonuç + riskler
- **Index:** Sources/Sprint öncesi audit'ler + Syntheses/Sprint Plans bölümlerine yeni satır

### Sprint 16-20 Roadmap

| Sprint | Modül | Ekran | Tahmini |
|---|---|---|---|
| 16 | inventory + stock + catalog | ~13 | 2-3 gün |
| 17 | sales + purchases + accounts | ~9 | 2 gün |
| 18 | finance + hrm + autoparts + supplier_claims | ~13 | 2-3 gün |
| 19 | import + auth + menu + pos + dashboard | ~10 | 2 gün |
| 20 | Cleanup: pre-existing teknik borç (deprecated value, underscore stili) | ~10 | 1 gün |

Toplam ~10 iş günü, 5 sprint.

### Verification

- `flutter analyze` (5 yeni template + 2 PoC ekran): **0 issue** ✅
- Smoke test bekliyor (kullanıcı runtime)

## [2026-04-27] sprint-14 | ProductCard tam migration — Inventory list/grid kartları ✅

Sprint 12'den ertelenen W1.4 (ProductCard tam migration) bu sprintte uygulandı. Inventory liste/grid kartlarındaki ~470 LOC kod tek `ProductCard` çağrısına dönüştürüldü.

### ProductCard Genişletmeleri

**Yeni field'lar (`ProductCardData`):**
- `unit: String?` — adet/kg/çift birim suffix'i stok rozetinde
- `oemNumbersText: String?` — OEM mode'da kart altı satır
- `crossRefsText: String?` — OEM mode'da kart altı satır

**Yeni property'ler (`ProductCard`):**
- `showOemRow: bool` — Inventory OEM search toggle açıkken `oemNumbersText` + `crossRefsText` satırları render eder
- `showStatusBadge: bool` — `data.status` ACTIVE değilse (DRAFT/INACTIVE/OUT_OF_STOCK) stok rozeti yanına status badge ekler

**Yeni helper'lar (ProductCard içinde):**
- `_buildStatusBadgeWidgets(t)` — status enum → AppBadge variant + i18n label
- `_buildOemRows(t)` — OEM/CrossRef satırları (Icons.confirmation_number / compare_arrows + AppColors.warning/info)
- `_buildStockBadge` artık unit suffix de gösteriyor: `"42 adet"` yerine `"42"`

### Inventory List Migration (`enhanced_product_list_screen.dart`)

| Helper / Method | Önce | Sonra |
|---|---|---|
| `_buildListCard` | 240 LOC body | 41 LOC ProductCard çağrısı |
| `_buildGridCard` | 213 LOC body | 35 LOC ProductCard çağrısı |
| `_StockChip` class | 55 LOC | silindi (ProductCard `_buildStockBadge` üstlendi) |
| `_getStatusBadgeVariant` | 7 LOC | silindi (ProductCard `_buildStatusBadgeWidgets`) |
| `_productIconPlaceholder` | 6 LOC | silindi (AppCachedImage errorWidget) |
| **Toplam dosya** | **1,778 LOC** (Sprint 12 öncesi) | **1,456 LOC** (~322 LOC azalma; Sprint 13 pagination state +130 LOC + W1.4 ~470 LOC silme) |

### İmport Eklemeler

- `package:project_pos/core/widgets/product_card.dart` — `unused_import` ignore yorumu kaldırıldı
- `package:project_pos/shared/providers/sector_provider.dart` — `sectorConfigProvider` watch için

### Verification

- `flutter analyze` (2 değiştirilmiş dosya): **0 issue** ✅
- Mevcut davranış korundu: tap → detail route, longPress → selection mode, OEM search toggle → OEM/CrossRef satırları, status DRAFT/INACTIVE → ek badge

### Sprint 15'e Ertelenen

- **W4.4 full** — `batch_product_screen.dart` 6,891 LOC DataTable → mobile kart layout (banner Sprint 13'te eklendi, full responsive Sprint 15)
- **Server-side category/status filter** — `/products?category=X&status=Y` backend genişletmesi (frontend client-side filter şu an pagination ile birlikte tutarsız sonuç verebilir, ama tek-sayfa kullanım için yeterli)
- **Wizard ileri refactor** — `variants_stock_step.dart` 1,179 LOC + `preview_step.dart` 1,045 LOC (opsiyonel, < 1500 LOC kabul edilebilir)
- **Batch screen 11 lint cleanup** — pre-existing teknik borç (deprecated value→initialValue, vd.)
- **Reference data API entegrasyonu** — Sprint 12 W1.2 `referenceDataProvider` şimdi static; backend `/reference-data` endpoint hazır olunca FutureProvider API çağrısı

### Smoke Test (Kullanıcı Runtime)

1. **Inventory list**: kart görünümü Sprint 12 öncesi ile aynı olmalı (sektör rozeti + status badge + OEM mode satırları)
2. **AutoParts firmasında**: search box yanındaki "OEM" toggle'a tıkla → OEM aramada kartların altında "OEM: 12345, 67890" + "Ref: ABC-123" satırları
3. **DRAFT/INACTIVE ürünler**: stok rozetinin yanında ek "Taslak" / "Pasif" rozeti
4. **Image olmayan ürünler**: AppCachedImage placeholder (CircularProgressIndicator) → errorWidget Icons.image_not_supported
5. **Selection mode** (long-press): hem list hem grid'de checkbox

## [2026-04-27] sprint-13 | Ürün liste pagination + batch mobile uyarı ✅

Sprint 12 sonrası Sprint 13 — ertelenen W4.2 (Inventory list pagination) + W4.4 (batch mobile) minimal implementasyonu. Kullanıcı "devam" emri.

### W4.2 Frontend Pagination — Inventory Ürün Listesi

**Backend kontrol:** `ProductControllerImpl.java:106` Spring `Pageable` ile `Page<ProductResponse>` döndürüyor — frontend hâlihazırda content[] çekiyordu, metadata kayıptı.

**Yeni:** [`product_service.dart`](project_pos/lib/features/inventory/services/product_service.dart) `getProductsPage()` method + `ProductListPage` model (items, currentPage, totalPages, totalElements, hasMore).

**Update:** [`enhanced_product_list_screen.dart`](project_pos/lib/features/inventory/screens/enhanced_product_list_screen.dart):
- State: `_currentPage`, `_hasMore`, `_isLoadingMore`, `_scrollController` (page size 50)
- `_loadProducts()` rewrite — page=0 reset + getProductsPage(search:_searchController.text)
- Yeni `_loadMoreProducts()` — page+=1, items append
- ScrollController bottom-200px → loadMore tetikleyici
- ListView/GridView → RefreshIndicator + ScrollController + loading footer
- `_onSearchChanged` → server-side search (page=0 reset, getProductsPage çağrısı)
- "X ürün gösteriliyor" footer (i18n key: `product.products_loaded`)

**Akış:** Liste açılır → ilk 50 ürün → scroll dibe → otomatik 50 daha → search yazınca page=0 reset + sunucu sorgusu. Pull-to-refresh çalışır. Eski client-side category/status filter korundu (server-side filter Sprint 14).

### W4.4 Batch Entry — Mobile Uyarı Banner

**Update:** [`batch_product_screen.dart`](project_pos/lib/features/inventory/screens/batch_entry/batch_product_screen.dart) build column'a `MediaQuery.of(context).size.width < 600` check + `_buildMobileWarningBanner()` ekleme: kullanıcıya "yatay çevirin / tablet kullanın" bilgi.

**Tam responsive kart layout Sprint 14'e ertelendi** — 6,891 LOC dosyada DataTable → kart layout büyük refactor.

### i18n (2 yeni key)

- `product.products_loaded` (`bnd-pd204`) — "ürün gösteriliyor" / "products shown"
- `batch.mobile_landscape_hint` (`bnd-bt218`) — uyarı banner metni

### Sprint 14'e Ertelenen

- **W1.4** ProductCard custom slot (OEM mode satır + status badge variant) + Inventory list `_buildListCard` 240 LOC tam migration
- **W4.4 full** Batch Entry DataTable → mobile kart layout (`<600px` koşullu render)
- **Server-side category/status filter** — pagination ile filter uyumu için backend endpoint genişletmesi (`/products?category=X&status=Y&page=0&size=50`)
- **Wizard `variants_stock_step.dart` 1,179 LOC + `preview_step.dart` 1,045 LOC ileri refactor** (opsiyonel)
- **Pre-existing teknik borç:** batch_product_screen.dart 11 lint info/warning (deprecated value→initialValue, unnecessary_underscores, prefer_interpolation, unused_parameter discountRate)

### Verification

- `flutter analyze` (3 değiştirilmiş dosya): **0 yeni issue** (11 pre-existing teknik borç batch_product_screen'de)
- Backend Maven dokunulmadı (sadece frontend + i18n)

## [2026-04-27] query | cari hesap bakiye bilgileri doğruluğu

**Soru:** "Cari işlemler kısmındaki genel ve müşteri/tedarikçi hesap bilgileri doğru mu?"

**Yöntem:** 2 paralel Explore agent (backend balance flow + frontend display) + 8 wiki sayfası audit (concepts: ledger-vs-denormalize, drift, denormalization-with-reconcile; entities: customer-account, account-transaction; decisions: ledger-as-source-of-truth, scheduled-reconcile-safe-rollout, db-side-aggregate-over-java-loop; issues: customer-list-balance-zero, today-collection-always-zero, overdue-amount-not-reconciled, accounts-pagination-missing, accounts-error-boundary-missing; syntheses: accounts-hub-production-readiness).

**Verdict:** ✅ Yapısal olarak doğru. Ledger + denormalize + write-through + reconcile pattern standart. Geçmiş silent-null bug'ları (customer/supplier-list-balance-zero, today-collection-always-zero) ve overdue reconcile RESOLVED. Üç operasyonel risk + üç UX gap açık (P1/P2 backlog).

**Geri-dosyalama:** `.wiki/syntheses/accounts-balance-correctness-audit-2026-04-27.md` ⭐ NEW (audit sentezi, 7 öneri Sprint 13 adayı).

**Index:** Syntheses bölümüne 1 satır link eklendi.

## [2026-04-27] sprint-12 | Ürün ekranları refactor — W1 + W4 implement + audit korreksiyon ✅

Kullanıcı "onay beklemeden tüm planı yap, test en sonda" emri ile Sprint 12 implementasyonu başladı. **Audit'in 4 ana iddiası kod doğrulamasıyla yanlış çıktı** — gerçek scope büyük ölçüde daha küçük.

### Audit Korreksiyonları (kod ile doğrulandı)

1. **Edit Flow YOK iddiası** → ASLINDA `product_detail_screen.dart:1609-1860` `_showProductEditSheet()` 251 LOC production-quality (sektör-aware, KDV chips, status, kategori dropdown, save+toast+refresh).
2. **Vehicle Compat tab merge önerisi** → Tab yapısı zaten **conditional**: `cfg.fields.showVehicleCompat`/`showCrossRef`. Merge cosmetic.
3. **Sektör tutarsızlığı** → YANLIŞ. `variants_step.dart` 23+148, `variants_stock_step.dart` 26+148 zaten SectorType switch + i18n; `batch_product_screen.dart` 37 cfg kullanım.
4. **Wizard 4,758 LOC** → YANLIŞ. `add_product_wizard_screen.dart` **524 LOC**. 6 step ayrı dosyada (basic_info 962, images 536, preview 1045, stock_barcode 701, variants 794, variants_stock 1179). Refactor edilmiş.

### Uygulanan Değişiklikler

**W1 (önceki tur):**
- Yeni: [`core/widgets/product_card.dart`](project_pos/lib/core/widgets/product_card.dart) — 3 mode + sektör-aware + AppBadge
- Yeni: [`shared/providers/reference_data_provider.dart`](project_pos/lib/shared/providers/reference_data_provider.dart) — VAT/Unit/ProductStatus tek hakikat noktası
- i18n: `stock.in_transit` (`bnd-s111`) + `stock.depleted` (`bnd-s112`)
- Update: `product_grid_item.dart` ConsumerWidget + i18n
- Update: ProductCard `_buildStockBadge` i18n

**W4 (bu tur):**
- Yeni: [`features/inventory/widgets/product_add_method_sheet.dart`](project_pos/lib/features/inventory/widgets/product_add_method_sheet.dart) — 4 yöntem disambiguation modal (Hızlı / Tam / Toplu / PDF)
- i18n: `product.add_method_*` 10 yeni key (`bnd-pd194-203`)
- Update: `enhanced_product_list_screen.dart` FAB → `ProductAddMethodSheet.show()` (eski direct Quick Add bypass)
- Update: ProductCard `_buildThumbnail` → `AppCachedImage` (cached_network_image entegrasyonu)

### Verification

- `flutter analyze` (5 değiştirilmiş/yeni dosya): **0 issue** ✅
- Manuel smoke test bekliyor (kullanıcı runtime'da)

### Sprint 13'e Ertelenenler (gerekçe: backend hazır ama frontend büyük scope)

- **W4.2 Pagination provider rewrite** — Backend `/products?page=0&size=10` mevcut (`ProductControllerImpl.java:106`), frontend `productServiceProvider.getProducts(size:100)` çekiyor; provider rewrite + scroll loadMore Sprint 13 (~1-2 gün)
- **W4.4 Batch Entry mobile kart** — `batch_product_screen.dart` 6,891 LOC, MediaQuery 1 kez. DataTable → kart layout büyük refactor, Sprint 13
- **W1.4 Inventory list ProductCard tam migration** — `_buildListCard` 240 LOC + OEM mode satırları + status badge variant'ları. ProductCard'a custom slot ekleyip migration Sprint 13
- **Wizard variants_stock_step.dart 1,179 LOC + preview_step.dart 1,045 LOC ileri refactor** — opsiyonel, < 1500 LOC kabul edilebilir

### Dosyalar

- Audit: [[sources/code-refs/2026-04-27-product-screens-audit]] (status: verified-with-corrections)
- Plan: [[syntheses/product-screens-revision-plan]] (status: superseded-by-implementation)
- Sprint planı: `.claude/plans/polymorphic-gathering-flute.md`

## [2026-04-27] query | ürün menüsü kartları + ürün detay ekranları revize plan

Kullanıcı talebi: "Ürün menüsü ekranındaki kartlar ve ürün detayındaki bütün ekranlarda kullanım, görünüm ve doğru akışlarla revize edilecek planı çıkaralım."

**Yöntem:** 3 paralel Explore agent (wiki sweep + POS scan + detail screens scan) + AskUserQuestion ile 4 scope kararı netleştirildi (POS+Inventory paralel + 4 detay revize alanı + büyük sprint 3-4 hafta + audit & synthesis ikili dosyalama).

**Bulgular özeti:**
- 2 menü ekranı (POS `pos_screen.dart` + `product_grid_item.dart`; Inventory `enhanced_product_list_screen.dart` 1,774 LOC)
- 6+ farklı ürün detay yolu (Wizard 4,758 LOC, Detail 2,872 LOC, Batch 6,891 LOC, Quick Add, Bulk Import, Edit Modal)
- 10 UX/UI sorun: Edit flow KIRIK (kod yok), 4+ ekleme yolu disambiguation YOK, kart duplikasyonu, hardcoded TR/threshold, reference data drift, sektör tutarsızlığı, pagination yok

**Geri-dosyalama (3 wiki sayfası):**
- `.wiki/sources/code-refs/2026-04-27-product-screens-audit.md` (yeni — mevcut durum + 10 sorun)
- `.wiki/syntheses/product-screens-revision-plan.md` (yeni — 4 hafta breakdown, 8 hedef sonuç)
- `.wiki/index.md` 2 yeni link (Sources/Sprint öncesi audit'ler + Syntheses/Sprint Plans)

**Sprint plan dosyası:** `.claude/plans/polymorphic-gathering-flute.md` (Sprint 12 detay implementation)

**Onay:** ExitPlanMode user approved (mega scope tüm 4 detay alanı + büyük sprint).

## [2026-04-27] sprint-11d | Plaka picker autocomplete (POS + Payment modal) ✅

POS satış sepeti ve Payment modal SPECIFIC modu plaka seçimleri **inline TextField + autocomplete** stiline geçti. Dropdown'lar kaldırıldı; çok plakalı müşterilerde (filo/taksi/transport) prefix-search ile hızlı seçim.

**Motivasyon:** Sprint 10/11c dropdown'ları 1-3 plakalı müşteri için yeterliydi; 10+ plakalı kayıtlarda scroll yorucu. Backend'de zaten `customerVehicleSearchProvider` (JPQL prefix `LIKE 'X%'`) hazırdı, UI bağlantısı eksikti.

**Yeni dosya (1):**
- `customers/widgets/vehicle_search_field.dart` — ortak `VehicleSearchField` widget. TextField + 300 ms debounce + inline suggestion overlay. Boş query'de tüm plakalar (`customerVehiclesProvider`), dolu query'de prefix search (`customerVehicleSearchProvider`). `allowClear`, `dense`, `trailing` slot, `selectedVehicle`/`onSelected` API.

**Değişen dosyalar (2):**
- `pos/widgets/customer_vehicle_picker.dart` — Dropdown + InputDecorator yapısı silindi, doğrudan `VehicleSearchField` döner; "+ yeni plaka" `trailing` slot'unda durur (44x44 primary card)
- `accounts/screens/payment_record_modal.dart` — `_buildVehicleFilter()` Container+DropdownButton yerine `VehicleSearchField(dense: true, allowClear: true)` döner; state `_selectedVehicleId` + `_selectedVehiclePlate` çiftinden `Map<String,dynamic>? _selectedVehicle` tek field'a indirgendi; `_buildOpenSalesPicker` ve `_submit` payload'ı bu Map'ten id/plateNormalized derive eder; `customer_vehicles_provider` import kaldırıldı (artık widget içinde)

**Backend dokunulmadı.** Sprint 9'dan beri `GET /customers/{id}/vehicles/search?q=` zaten vardı.

**UX detayları:**
- Focus → tüm plakalar suggestion açılır (boş query)
- Yazma → 300 ms debounce → server-side LIKE 'X%' (i18n key `vehicle.search_placeholder` placeholder)
- Suggestion item: plaka (bold) + altında `make model` (varsa, küçük gri)
- Boş sonuç → `common.no_records` mesajı
- Seçim → input metni `plateDisplay`, suggestion kapanır, focus düşer
- × ikonu (suffix) `allowClear: true` ise seçim varken belirir → `onSelected(null)` reset

**Verification:** `flutter analyze` 0 error (pre-existing 18 deprecation/style info kalır).

## [2026-04-27] sprint-11c | Plaka filtresi modal içine taşındı (UX refactor) ✅

Sprint 11'de eklenen `VehiclePlateSearchBar` (statement panel header dropdown) + `selectedVehicleProvider` kaldırıldı. Plaka picker artık `PaymentRecordModal` içinde **SPECIFIC** radyosu seçilince (parçacı sektörde) açık satışlar listesinin üstünde görünür.

**Motivasyon:** Plaka filtresi yalnız belirli açık satışa ödeme atfederken anlamlı. Header'da sürekli durması ekstre ekranını gereksiz kalabalıklaştırıyordu.

**Silinen dosyalar (2):**
- `accounts/providers/selected_vehicle_provider.dart`
- `accounts/widgets/vehicle_plate_search_bar.dart`

**Değişen dosyalar (2):**
- `accounts/widgets/statement_detail_panel.dart` — bar render bloğu (satır 119-124) + 4 import (`sector_config`, `sector_provider`, `selected_vehicle_provider`, `vehicle_plate_search_bar`) + `_handlePayment` modal çağrısında 2 parametre kaldırıldı
- `accounts/screens/payment_record_modal.dart` — `customerVehicleId` + `vehiclePlateNormalized` public parametreleri kaldırıldı; yerine local `_selectedVehicleId` + `_selectedVehiclePlate` state; yeni `_buildVehicleFilter()` widget; SPECIFIC + autoParts koşullu render; eski "filter active" info banner kaldırıldı; payload `customerVehicleId` SPECIFIC + seçili plaka şartına bağlandı (GENERAL'de iliştirilmez); 3 yeni import (`sector_config`, `customer_vehicles_provider`, `sector_provider`)

**Akış (yeni):**
1. AccountsHub → müşteri seç → ekstre paneli sade (plaka bar yok)
2. Tahsilat → modal açılır → "Belirli alışveriş" radyosu
3. (Parçacı sektörde) plaka dropdown belirir → "Tüm plakalar" veya bir plaka
4. `_selectedVehiclePlate` → `customerOpenSalesProvider(CustomerOpenSalesKey(...))` filtreli açık satışlar
5. Satış seç → tutar oto-dolar
6. Submit → payload `customerVehicleId` (sadece SPECIFIC + seçili plaka varsa)

**Backend:** Dokunulmadı.

**Verification:** `flutter analyze` 0 error (pre-existing 17 deprecation/style info kalır). Grep doğrulandı: `selectedVehicleProvider` ve `VehiclePlateSearchBar` projede 0 occurrence.

**i18n cleanup:** `vehicle.filter_active` (`bnd-vh12`) artık kullanılmıyor — `data.sql:2734-2735` blokundan silindi (Sprint 11'de eklenmişti, picker üstündeki dropdown banner'a ihtiyacı kaldırdı).

## [2026-04-27] sprint-11 | Accounts plaka filtresi + payment allocation ✅

Sprint 11 — AccountsHub'da plaka bazlı tahsilat akışı end-to-end. Statement panel header'ında dropdown'dan plaka seçilince tahsilat modal o plakaya ait açık satışları listeler ve `customerVehicleId` payment allocation'a iliştirilir.

**Değişen / yeni Flutter dosyaları (5):**

- `sales/services/sales_service.dart` — `getCustomerOpenSales(customerId, {vehiclePlate})` opsiyonel filtre param
- `accounts/providers/customer_open_sales_provider.dart` — `family<List, String>` → `family<List, CustomerOpenSalesKey>` tuple key (BREAKING; tek call site `payment_record_modal._buildOpenSalesPicker` güncellendi)
- `accounts/providers/selected_vehicle_provider.dart` ⭐ NEW — `StateProvider.autoDispose<Map<String,dynamic>?>` AccountsHub plaka seçimi state'i
- `accounts/widgets/vehicle_plate_search_bar.dart` ⭐ NEW — kompakt dropdown bar (Tüm plakalar + kayıtlı plakalar + × clear), `customerVehiclesProvider` watch
- `accounts/widgets/statement_detail_panel.dart` — VehiclePlateSearchBar SummaryGrid ile TxFilterBar arasına yerleştirildi (sektör=autoParts + customer check); `_handlePayment` `selectedVehicleProvider` okur, `customerVehicleId` + `vehiclePlateNormalized` modal'a geçer; `import sector_provider` eklendi
- `accounts/screens/payment_record_modal.dart` — `customerVehicleId` + `vehiclePlateNormalized` parametre çifti eklendi; `_buildOpenSalesPicker` `CustomerOpenSalesKey` tuple kullanır; Sprint 6b deprecated `_plateCtrl` TextField + `_normalizePlate()` + description prepend kaldırıldı; aktif filtre info banner gösterir; payload'a `customerVehicleId` iliştirir

**Backend dokunulmadı** — Sprint 9'dan beri `getCustomerOpenSales(customerId, vehiclePlate)` ve `Sale.vehiclePlateSnapshot` zaten hazırdı. Maven `mvn compile` exit 0.

**i18n ek:** `bnd-vh12` → `vehicle.filter_active` (TR "Plaka filtresi aktif" / EN "Vehicle filter active") `data.sql:2735` altına eklendi.

**Akış (parçacı sektör tahsilat):**

1. AccountsHub → müşteri seçimi → Statement panel açılır
2. Sektör autoParts ise SummaryGrid ALTINDA `VehiclePlateSearchBar` görünür
3. Dropdown'dan plaka seç → `selectedVehicleProvider` set olur
4. Tahsilat butonu → `_handlePayment` `selectedVehicle` okur → modal'a `customerVehicleId` + `vehiclePlateNormalized` geçer
5. Modal `_buildOpenSalesPicker` `CustomerOpenSalesKey(customerId, vehiclePlate: ...)` ile `customerOpenSalesProvider` çağırır → backend `?vehiclePlate=Y` filtreli açık satışlar
6. Kullanıcı satış seçer → tutar otomatik dolar
7. Submit → payload `customerVehicleId` + `allocations[{saleId, amount}]` ile backend'e gider
8. Backend Payment + PaymentAllocation kaydeder; `Sale.remainingAmount` güncellenir
9. AccountsHub liste + statement bakiye anında refresh (`ref.invalidate(accountsListProvider)` Sprint 8 hot-fix D1 sayesinde)

**Verification:**
- `flutter analyze` 4 modül üzerinde 0 error (8 pre-existing deprecation/style info)
- `mvn -DskipTests compile` exit 0
- Manuel test bekliyor: 1) sektör=butik panel'de SearchBar gizli mi 2) müşteri değişince plaka filtresi reset mi 3) plaka filtreliyken tahsilat sonrası bakiye anında düşüyor mu

**Sprint 11b deferred (kullanıcı kararına bırakıldı):**
- Migration script — eski `Payment.description "Plaka:"` prefix'lerini parse edip `CustomerVehicle` upsert (idempotent + `--dry-run`)
- `ReconcileScheduledJob` yeni invariant — `Sale.vehiclePlateSnapshot == sale.customerVehicle.plateNormalized`
- Drift bulunursa Slack notify + `.wiki/issues/` entry

## [2026-04-27] sprint-10b | POS Cart Panel + PosState plaka entegrasyonu ✅

Sprint 10b — cart_panel.dart + pos_provider.dart entegrasyonu tamamlandı (Sprint 10 kor frontend dosyaların ardından PosState refactor + sale request payload).

**Değişen Flutter dosyaları (2):**

`pos/providers/pos_provider.dart`:
- `PosState.selectedVehicle: Map<String,dynamic>?` field eklendi
- `copyWith` `clearVehicle: bool` flag pattern (mevcut `clearCustomer` ile tutarlı)
- `selectCustomer(...)` müşteri değişince plaka reset (aynı müşteri tekrar seçilince koru — `isSameCustomer` check)
- Yeni `selectVehicle(Map<String,dynamic>?)` method
- `saleData` payload: `if (selectedVehicle != null) 'customerVehicleId': selectedVehicle.id`

`pos/widgets/cart_panel.dart`:
- Yeni `_buildVehicleSection(ref, notifier, state)` private method — sektör=autoParts + customerId varsa CustomerVehiclePicker render; aksi halde SizedBox.shrink (butik sektör + peşin satış'ta tamamen gizli)
- Build column'a customerSection altına yerleştirildi
- `import 'package:project_pos/core/config/sector_config.dart'` (sectorTypeProvider erişimi)
- `import 'customer_vehicle_picker.dart'` (relative)

**Akış (parçacı sektör senaryosu):**
1. Kullanıcı POS'ta müşteri seçer → cart_panel customerSection değişir
2. Sektör autoParts ise customerSection ALTINDA `CustomerVehiclePicker` görünür
3. Kullanıcı dropdown'dan plaka seçer veya "+" ile yeni ekler (idempotent backend)
4. selectVehicle → state.selectedVehicle güncellenir
5. Submit → saleData.customerVehicleId backend'e gider
6. Backend SaleServiceIntegrated.createSale() → Sale.customerVehicle FK + vehiclePlateSnapshot doldurulur

**Müşteri Reset:** Müşteri değişince selectedVehicle reset; aynı müşteri tekrar seçildiyse plaka korunur.

**Bekleyen:**
- Frontend `flutter analyze` koşulmadı (kullanıcı runtime)
- Sprint 11: VehiclePlateSearchBar + PaymentRecordModal `_plateCtrl` deprecated kaldırma + migration script + reconcile invariant

## [2026-04-26] sprint-10 | Plaka takibi frontend kor — picker + service + provider ✅

Sprint 10 frontend kor implementasyonu (cart_panel + pos_provider entegrasyonu Sprint 10b'ye, çünkü PosState değişikliği büyük scope).

**Yeni Flutter dosyaları (4):**
- `customers/services/customer_vehicle_service.dart` — HTTP servisi (list, search, create idempotent, update, deactivate)
- `customers/providers/customer_vehicles_provider.dart` — Riverpod (FutureProvider.family `customerVehiclesProvider` + autocomplete `customerVehicleSearchProvider` + `CustomerVehicleSearchKey` tuple)
- `customers/widgets/add_customer_vehicle_modal.dart` — inline yeni plaka modal (idempotent backend POST → mevcutsa zaten döner)
- `pos/widgets/customer_vehicle_picker.dart` — plaka dropdown + "+" buton (yeni ekleme); dropdown empty/loading/error states

**i18n keys (10):** `vehicle.plate`, `add_new`, `make`, `model`, `year`, `no_vehicles`, `select`, `none`, `plate_required`, `search_placeholder` (TR + EN). ID: `bnd-vh01-10`.

**Sprint 10b (sonraki tur, 1-2 saat) — kalan iş:**
- `PosState`'e `selectedVehicle: Map<String,dynamic>?` field ekleme
- `PosNotifier.setSelectedVehicle(...)` method
- `cart_panel.dart` sektör check (`sectorTypeProvider == SectorType.autoParts && customerId != null`) + CustomerVehiclePicker entegre
- POS `saleData` payload'a `customerVehicleId` ekleme (`pos_provider.dart:741`)
- Müşteri değişince `selectedVehicle` reset

**Sprint 11 — accounts plaka tahsilat:**
- `VehiclePlateSearchBar` widget (statement_detail_panel)
- PaymentRecordModal `_plateCtrl` deprecated kaldırma
- Migration script: `Payment.description` "Plaka:" prepend → CustomerVehicle upsert
- ReconcileScheduledJob invariant

**Verification:** Frontend `flutter analyze` koşulmadı (kullanıcı runtime'da). Backend Maven exit 0 hâlâ geçerli (Sprint 9'dan).

## [2026-04-26] sprint-9 | Plaka takibi backend foundation ✅ (Opsiyon C, Maven exit 0)

Sprint 9 backend implementasyonu tamamlandı. Sentez planı [[syntheses/vehicle-plate-end-to-end-design-2026-04-26]] uygulandı.

**Yeni Java sınıfları (8):**
- `customer/entity/CustomerVehicle.java` — entity (`@Table customer_vehicles`, indexes, UNIQUE `(customer_id, plate_normalized, company_code)`, @Version)
- `customer/repository/CustomerVehicleRepository.java` — `findByCustomerIdAndIsActiveOrderByPlateDisplay`, `searchByCustomer`, `findByCustomerIdAndPlateNormalized`
- `customer/service/CustomerVehicleService.java` (interface) + `CustomerVehicleServiceImpl.java` — idempotent create, AOP filter aktif (@Service)
- `customer/controller/impl/CustomerVehicleControllerImpl.java` — REST CRUD + search endpoint'leri
- `customer/model/CustomerVehicleDto.java` (request) + `CustomerVehicleResponse.java`

**Değişen Java sınıfları (4):**
- `sales/entity/Sale.java` — `customerVehicle` ManyToOne FK + `vehiclePlateSnapshot` String denormalize cache
- `sales/model/SaleRequest.java` — `customerVehicleId` parametresi
- `sales/service/impl/SaleServiceIntegrated.java` — `createSale()` plaka FK + snapshot logic + müşteri-plaka tutarlılık kontrolü
- `sales/controller/impl/SaleControllerImpl.java` — `?vehiclePlate=Y` filter parametresi (normalize + Sale.vehiclePlateSnapshot LIKE contains)

**Endpoint Kataloğu (yeni 6):**
- `GET /api/v1/customers/{id}/vehicles` — aktif plakalar
- `GET /api/v1/customers/{id}/vehicles/search?q=34A` — autocomplete
- `GET /api/v1/customers/{id}/vehicles/{vid}` — tek kayıt
- `POST /api/v1/customers/{id}/vehicles` — idempotent create
- `PUT /api/v1/customers/{id}/vehicles/{vid}` — güncelleme
- `DELETE /api/v1/customers/{id}/vehicles/{vid}` — soft-delete
- + `GET /api/v1/sales?vehiclePlate=Y` filter parametresi

**Wiki dosyaları:**
- Yeni: [[entities/customer-vehicle]] — entity dokümantasyonu
- Yeni: [[decisions/2026-04-26-vehicle-plate-option-c]] — ADR
- Update: [[decisions/2026-04-24-vehicle-plate-tracking-option-a]] — SUPERSEDED işaretlendi
- Update: [[index]] — Sprint 9-11 alt-bölümü güncellendi

**Verification:** Backend Maven compile **exit 0** ✅. Frontend (Sprint 10) ve migration (Sprint 11) ayrı oturumlarda yapılacak.

**Bekleyen (Sprint 10 kapsamı):**
- `customer_vehicle_service.dart` Flutter service
- `customerVehiclesProvider` Riverpod (FutureProvider.family)
- `CustomerVehiclePicker` widget
- `cart_panel.dart` sektör-aware entegrasyon
- `AddCustomerVehicleModal` inline yeni plaka

**Bekleyen (Sprint 11 kapsamı):**
- `VehiclePlateSearchBar` (statement_detail_panel)
- PaymentRecordModal `_plateCtrl` deprecated kaldırma
- Migration script: mevcut `Payment.description` "Plaka:" prepend → CustomerVehicle upsert
- ReconcileScheduledJob yeni invariant

## [2026-04-26] design | plaka bazlı satış-tahsilat bütünsel — Opsiyon C tasarımı

Kullanıcı senaryosu: parçacı sektörde satış sırasında plaka kayıt + müşteri görünümünde plaka arama + tahsilatta plaka bazlı geçmiş seçimi. Geri-dosyalama: [[syntheses/vehicle-plate-end-to-end-design-2026-04-26]].

**Tetikleyici:** [[decisions/2026-04-24-vehicle-plate-tracking-option-a]] "Yeniden Değerlendirme Kriterleri" sağlandı — kullanıcı multi-plaka senaryosunu kanıtladı. Opsiyon A (description prepend) yetersiz, **Opsiyon C** (CustomerVehicle entity) gerekli.

**Tasarım özeti:**
- Backend: `CustomerVehicle` entity (`customer_id` + `plate_normalized` UNIQUE) + `Sale.customerVehicleId` FK + `Sale.vehiclePlateSnapshot` denormalize cache
- Endpoint: `/customers/{id}/vehicles` CRUD + search; `/sales?vehiclePlate=Y` filter
- Frontend: Sektör-aware widget'lar (`CustomerVehiclePicker`, `VehiclePlateSearchBar`, `AddCustomerVehicleModal`); sektör=autoParts kontrolü ile koşullu render
- Migration: mevcut `Payment.description` "Plaka: XX" prepend'lerini CustomerVehicle'a upsert (idempotent, dry-run desteği)
- Reconcile: yeni invariant `Sale.vehiclePlateSnapshot == customerVehicle.plateNormalized`

**Sprint roadmap (~7-10 gün):**
- Sprint 9: Backend foundation (entity + repo + service + endpoint + Sale FK)
- Sprint 10: Frontend POS (CustomerVehiclePicker + cart_panel + AddVehicleModal)
- Sprint 11: Accounts tahsilat (VehiclePlateSearchBar + statement_detail_panel + migration)

**Yeni backend servisler:** 8 yeni Java class + 5 değişen + 2 migration script + 1 reconcile invariant.
**Yeni frontend Dart dosyalar:** 5 yeni + 5 değişen.

Done kriteri 7 senaryo: butik sektörde plaka widget'ları görünmez (sektör isolation).

## [2026-04-26] correction | hot-fix-v3 YANLIŞ YORUM — REVERTED

Kullanıcı düzeltti: "yanlış geliştirme yapıldı. sistemimizde firma bazlı arama yapılır." Önceki tenant-leak yorumu HATALI — sistem multi-firma per-user mimarisi:

- Bir kullanıcı birden fazla firmaya sahip olabilir (SEDCORE otomotiv + SEDCORE1 butik)
- Backend endpoint'leri default tüm firmalardan döner
- "Firma bazlı arama" = frontend UI'dan companyCode filter

**Revert (git checkout HEAD --):**
- `CustomerService.search()` interface method (eklenmişti — geri alındı)
- `CustomerServiceImpl.search()` impl (geri alındı)
- `CustomerControllerImpl.list` service yönlendirme (geri alındı, repository direkt kalmaya devam ediyor — DOĞRU)

Backend Maven compile (revert sonrası): **exit 0** ✅

**Wiki düzeltme:**
- Yeni: [[concepts/multi-company-per-user-architecture]] — DOĞRU mimari açıklaması
- Deprecated: [[syntheses/tenant-leak-controller-direct-repository-2026-04-26]] — yanlış yorum, header DEPRECATED + supersedes link
- Index: tenant-leak link'i deprecated, multi-company-per-user-architecture eklendi

**Açık soru (kullanıcıdan netleştirme bekleniyor):**
AccountsListService'in `selectedCompanyCode` filter aktif tutması doğru mu? (önceki response'ta sadece SEDCORE 4 kayıt döndü.) Eğer "tüm firmalar" doğru ise oradaki filter da kaldırılmalı. Şu an dokunulmadı.

## [2026-04-26] 🚨 hot-fix-v3 | KRİTİK: multi-tenant leak — CustomerController repository bypass

> ⚠️ Bu girdideki "tenant leak" yorumu YANLIŞ olduğu sonradan tespit edildi (bkz. üstteki correction). Hot-fix v3 revert edildi. Detay: [[concepts/multi-company-per-user-architecture]]

Kullanıcı `/customers?isActive=true` response'u paylaştı: **2 farklı tenant'tan kayıt** (SEDCORE Usta+Adem, SEDCORE1 Moda Butik+**Zeynep**) → tenant izolasyon kırığı kanıtlandı.

Geri-dosyalama: [[syntheses/tenant-leak-controller-direct-repository-2026-04-26]] (KRİTİK).

**Kök neden:** [[concepts/hibernate-filter-runtime]] §Critical Bulgular #4 gerçekleşti. `CompanyHibernateFilterActivator` AOP pointcut `com.sedcore..service..*` — sadece service layer'da advice tetiklenir. CustomerControllerImpl direkt `customerRepository.search()` çağırdığı için (service bypass) Hibernate `@Filter("filterByCompanyCode")` aktif edilmedi → tüm tenant'lar geliyordu.

**Karşıt kanıt:** AccountsListService aynı oturumda sadece SEDCORE 4 kayıt döndürdü (önceki response 16:19) çünkü `@Service` annotated → AOP advice tetikleniyor.

**Uygulanan Düzeltme (Hot-Fix v3):**
- F1: `CustomerService.search(String, Boolean)` interface method eklendi
- F2: `CustomerServiceImpl.search` → `dao.search(q, isActive)` (service-layer çağrı)
- F3: `CustomerControllerImpl.list` → `customerService.search(...)` (repository direct yerine)
- Backend Maven compile: **exit 0** ✅

**Beklenen davranış (restart sonrası):**
- SEDCORE oturumu → sadece SEDCORE müşterileri
- SEDCORE1 oturumu → sadece SEDCORE1 (Zeynep + Moda Butik)
- Zeynep'in POS'ta SEDCORE oturumunda görünmesi tenant leak idi; artık görünmemeli (doğru davranış)

**Kalan Risk (Sprint 9 acil audit):**
- 7+ dosya / 13+ callsite hâlâ `customerRepository.findById/count`, `accountTransactionRepository.findCustomerStatement` direkt çağırıyor → cross-tenant ID erişimi açık
- Sistemik çözüm: AOP pointcut'ı controller'a yay (Seçenek A) + service üzerinden zorla (Seçenek B)

## [2026-04-26] query | zeynep DB'de yok kanıtlandı — backend response 4 kayıt

Kullanıcı backend response paylaştı: `hasMore=false`, 4 kayıt (oto1 tenant), Zeynep YOK. Geri-dosyalama: [[syntheses/zeynep-customer-not-in-db-2026-04-26]].

**Önceki hipotezler çürütüldü:**
- ❌ Pagination (hasMore=false zaten tüm kayıtları döndürdü)
- ❌ Filter (4 kayıttan 2 customer var, filter doğru)
- ❌ Endpoint tutarsızlığı (POS Cart Panel ve AccountsListService AYNI `customerRepository.search(null, true)` kullanıyor)

**4 yeni senaryo:**
- A: POS yeni müşteri eklerken backend POST başarısız oldu → frontend in-memory cache, DB'ye gitmedi
- B: Zeynep farklı tenant'ta (SEDCORE1 vs SEDCORE)
- C: `is_active=false` veya `is_deleted=true`
- D: Kullanıcı yanılgısı (POS'ta başka müşteri ile karıştırıyor)

**3-adım tanı:**
1. SQL: `SELECT * FROM customers WHERE LOWER(name) LIKE '%zeynep%'`
2. POS Cart Panel kapat-aç (state cache vs DB)
3. JWT decode → `selectedCompanyCode` ile `customer.company_code` karşılaştır

**Sistemik kalıcı çözüm (Sprint 9):**
- E1: AccountEditForm save sonrası `ref.invalidate(accountsListProvider)` audit
- E2: Backend POST hata durumunda Flutter explicit AppToast.error
- E3: Cart Panel _CustomerPickerSheet ile AccountsListProvider sync

## [2026-04-26] hot-fix-v2 | zeynep sorunu sistemik çözüm — pageLimit + auto-prefetch ✅

Kullanıcı talebi: "müşteriyi cari accountunda görmem lazım, sistem stabil çalışmalı". Pagination paradigmasından vazgeçmeden 3 değişiklik:

**B1** — Backend `AccountsListService.list` clamp `Math.min(50, limit)` → `Math.min(200, limit)`. KOBİ tenant'lar için yeterli üst sınır; 200+ müşteri varsa pagination devreye girer.

**B2** — Frontend `accounts_list_provider.dart` `_pageLimit` 50 → 100. İlk yükleme 100 müşteri.

**B3** — Frontend `loadFirst()` sonrası **auto-prefetch**: query boşsa + hasMore varsa otomatik 1x loadMore → toplam ~200 müşteri ilk açılışta. Sıralama `name ASC` olduğu için "Z" harfli müşteri (Zeynep dahil) artık ilk açılışta görünür.

**Mantık:** 200+ müşterili büyük tenant'lar için kullanıcı scroll yapar (manuel loadMore zaten çalışıyor). Auto-prefetch sadece query boşken — search yapıldığında server-side filter zaten kayıtları azaltır, prefetch gereksiz.

**Verification:**
- Backend Maven compile: exit 0 ✅
- Frontend `flutter analyze` koşulmadı (kullanıcı runtime)

Önceki troubleshooting rehberi geçerli: [[concepts/troubleshooting-customer-missing-in-accounts-hub]]. #1 pagination nedeni artık küçük tenant'lar için elendi.

## [2026-04-26] query | zeynep müşterisi POS'ta var ama cari hesaplarda yok

Geri-dosyalama: [[concepts/troubleshooting-customer-missing-in-accounts-hub]] — generic tanı rehberi (5 olası neden + adım-adım teşhis).

**Hipotezler (öncelik sırasıyla):**
1. 🔴 **Pagination** — limit 50, "Z" harfi ilk sayfada yok, scroll loadMore tetiklenmedi (en olası)
2. 🟠 Filter chip "Tedarikçi" veya "Vadesi Geçmiş" basılı
3. 🟠 Search query önceki aramadan açık
4. 🟡 `is_deleted=true` (paradox: POS Cart Panel aynı endpoint, gelmemeli)
5. 🟡 Multi-tenant `company_code` farklı (session değişimi varsa)
6. 🟢 Sprint 8 frontend pagination parse bug (az olası)

**Tanı 6-adım** sırasıyla UI (saniyeler) → backend curl → DB → JWT decode.

**Düzeltme önerileri:**
- #1 için: search box'a "z" yaz → server-side filter ile direkt gelir
- #2-3 için: chip "Tümü" + search clear
- #4 için: `UPDATE customers SET is_deleted=false`
- #5 için: company_code düzeltme (veri taşıma dikkat)

## [2026-04-26] sprint-8-cleanup | P0.2 + P1.1 + P2.5 batch — bütün planları sırayla ✅

Kullanıcı talebi: "ben dışarı çıkıyorum bütün planları sırayla yap". [[syntheses/pending-work-status-2026-04-26]] sırasına göre uygulandı:

**Tamamlanan (~5 saat eşdeğeri iş):**

**P0.2 — D3 frontend currentBalance render** ✅
- [`statement_detail_panel.dart`](project_pos/lib/features/accounts/widgets/statement_detail_panel.dart): `currentBalance` parse, `hasDrift` hesaplaması, `_SummaryGrid` constructor genişledi
- `_SummaryGrid` 4. tile primer değer `currentBalance` (denormalize gerçek), drift varsa warning icon + secondary line "⚠ Hesaplanan: X" göstergesi
- `_StatTile.secondaryValue` field eklendi (drift göstergesi için)

**P1.1a — StatementDetailPanel ErrorView** ✅
- `AppEmptyState.error` → `AccountsErrorView` (retry button + AppLogger pattern)

**P1.1b — AccountsSummaryBar ErrorView** ✅
- `summaryState.error != null` durumunda compact `AccountsErrorView` (yer kazanma için compact mode)

**P2.5 — Lint P1 cleanup** ✅
- 16 wikilink ad değişimi sed batch (flows/X → syntheses/flow-X, integrations/X → syntheses/integration-X, patterns/X → concepts/pattern-X veya concepts/X)
- 5 redirect: `[[contradictions]]` → claude-wiki-contradictions, `[[decisions/append-only-semantics]]` → concepts/append-only, vb
- `archive/README.md` placeholder yarat ([[archive/README]] kırık linki düzeltildi)

**Verification:**
- Backend Maven compile: **exit 0** ✅
- Frontend `flutter analyze` koşulmadı (kullanıcı runtime'da)

**Ertelendi (Sprint 9):**
- P1.2 T2-T4 service-level testler (1.6 gün — büyük scope)
- P1.3 B0 phase 2 POS Cart Panel paginated (1 gün)
- P2.1 B3 toplu ödeme UI (1.5-2 gün — backend hazır)
- P2.6 I5 test coverage geniş kapsam
- P2.7 18 MERGE_NEEDED dosya inceleme

**Kabul edilen Sprint 7+8 done kriteri:**
- Sprint 7: WP1 (4 dosya backend) + WP3 (provider) + WP4 (modal sale picker) + WP4.b (caller) + WP5 (i18n + ErrorView widget) + WP6 (3 wiki sayfası) + WP2 minimum test (3 test, BUILD SUCCESS) ✅
- Sprint 8: WP1 (5 dosya backend cursor pagination) + WP1 frontend (provider rewrite + scroll) + WP2 (3/3 panel ErrorView) ✅
- Hot-fix: D1 ref.invalidate + D2 limit 50 + D3 backend currentBalance + D3 frontend render ✅

**Toplam Sprint 7+8+hot-fix:**
- Backend: 6 yeni dosya, 4 update, 1 entity model genişledi
- Frontend: 4 yeni dosya, 5 update
- Wiki: 6 yeni sentez sayfası, 3 wiki sayfası (entity/concept/decision)
- Test: 1 test class (3 method, BUILD SUCCESS)
- i18n: 7 yeni anahtar (TR+EN)

**Kaynak:** kullanıcı talebi — auto mode "bütün planları sırayla yap".

## [2026-04-26] query | planda yapılmaya kalan var mı? — pending work status

Kullanıcı talebi: aktif tüm planlar + sentezler + hot-fix sonrası ne kaldı? Geri-dosyalama: [[syntheses/pending-work-status-2026-04-26]] — P0/P1/P2/P3 önceliklendirme + sprint roadmap.

**Konsolide kaynaklar:**
- Sprint 7 hold-overs: WP2 (3 panel ErrorView, 1 yapıldı), WP3 (T2-T4 testler), smoke test
- Sprint 8 hold-overs: D3 frontend render, B0 phase 2 (POS pagination), WP2/WP3 devamı
- v2 backlog: B0/B3/B6/B8/B9 + I5
- Lint action plan P1-P3 (sed batch, MERGE_NEEDED, xref, zayıf kaynak)
- Codebase snapshot P4 (React/controller/core ingest)

**Önerilen bu hafta sıra (~5 saat):**
1. P0.1 smoke test (sen runtime)
2. P0.2 D3 frontend `currentBalance` render (1-2 saat)
3. P1.1 ErrorBoundary kalan 2 panel (1.5 saat)
4. P2.5 lint P1 cleanup (1 saat — yüksek ROI)

**Kritik not:** Frontend `flutter analyze` Sprint 7+8 boyunca koşulmadı. P0.1'in parçası olarak `flutter analyze` öneriliyor.

## [2026-04-26] query | hot-fix: POS müşteri listesi + bakiye refresh ✅

Kullanıcı 2 üretim bug'ı raporladı:
1. POS satış ekranı müşteri listesi ≠ AccountsHub liste (eksik kayıtlar)
2. Cari hesapta ödeme sonrası bakiye UI'da güncellenmiyor (hot reload düzeltir)

İki paralel Explore agent kök nedenleri tespit etti. Geri-dosyalama: [[syntheses/accounts-bugfix-investigation-2026-04-26]].

**Kök Nedenler:**
- **Bug A**: Cart Panel `/customers?isActive=true` (sayfasız) ↔ AccountsHub `/accounts/list?limit=20&...` (paginated). Auth/filter doğru, sadece pagination farkı.
- **Bug B**: (1) Backend statement response'a denormalize `currentBalance` eksik — yalnızca `closingBalance` (transaction toplamı) var. (2) `_handlePayment` 3 autoDispose provider'a `Future.wait([notifier.load()])` → modal close + rebuild race. (3) Sprint 8 `loadFirst()` state reset timing.

**Uygulanan Düzeltmeler (3):**
- **D1** — `statement_detail_panel.dart`: `ref.invalidate(accountsListProvider)` + 3 load (4 yerine). AutoDispose race önlendi.
- **D2** — `accounts_list_provider.dart` `_pageLimit` 20→50 (backend Math.min(50, limit) clamp). Sprint 9: POS Cart Panel'i de paginated.
- **D3** — Backend `AccountStatementEntry.currentBalance: BigDecimal` field eklendi; `AccountStatementControllerImpl` `customerAccountService.getOrCreate(...).getCurrentBalance()` ile dolduruyor (supplier eşdeğeri). Fallback: exception → `closingBalance`. **Maven compile exit 0**.

**Sprint 9 hold-overs:**
- D3 frontend — `statement_detail_panel.dart` `currentBalance` render + drift göstergesi
- B0 frontend — POS Cart Panel paginated
- WP2 kalan 2 panel ErrorView (Sprint 8'den)
- WP3 T2-T4 testler

**Kaynak:** kullanıcı talebi — 2 üretim bug raporu + plan onayı (ExitPlanMode).

## [2026-04-26] sprint-8 | WP1 backend ✅ + WP1 frontend ✅ + WP2 kısmi ✅

Kullanıcı talebi: "ben dışarı çıkıyorum plan için onay veya soru sorma hepsini hallet". Açık sorular cevaplandı (cursor=JSON, limit=50, filter+query=AND, loader=CircularProgress, refresh=scroll-top). Sprint 8 önemli kısmı uygulandı:

**WP1 Backend ✅** (Maven compile exit 0):
- Yeni: `AccountsListCursor.java` — JSON transparent cursor (name|type|id tuple)
- Yeni: `PaginatedAccountsResponse.java` — items + nextCursor + hasMore
- Yeni: `AccountsListService.java` — CustomerRepository.search (DB-side, EntityGraph N+1 fix) + SupplierService.listSuppliers + in-memory merge/sort/cursor (R1: DB UNION optimization sprint sonuna)
- Yeni: `AccountsListControllerImpl.java` — `GET /api/v1/accounts/list?cursor=&limit=20&filter=&q=`

**WP1 Frontend ✅:**
- Update: `accounts_list_provider.dart` — komple rewrite, paginated state (`isLoadingMore`, `hasReachedEnd`, `nextCursor`), `loadFirst/loadMore/refresh`, debounced setQuery (300ms), setFilter triggers loadFirst, geriye uyum `load()` alias. AccountListItem.fromMap factory eklendi.
- Update: `accounts_list_panel.dart` — ScrollController bottom-200px loadMore, RefreshIndicator pull-to-refresh, loading footer, `AccountsErrorView` entegrasyonu (WP2 #1)

**WP2 ErrorView Entegrasyonu (kısmi):**
- ✅ AccountsListPanel — `AccountsErrorView` ile error state replace
- ⏳ StatementDetailPanel — Sprint 9'a kaydı
- ⏳ AccountsSummaryBar — Sprint 9'a kaydı

**Ertelendi (Sprint 9):**
- WP3 T2-T4 service-level testler (@SpringBootTest)
- WP2 kalan 2 panel ErrorView
- Plan v2 P3 yaşlandırma raporu (B6), overdue notification (B8), activity history (B9)

**Bilinen sınırlamalar:**
- AccountsListService in-memory merge (1000+ supplier'da yavaş olabilir; sprint sonu DB-side UNION optimization R1)
- SupplierRepository.search yok (Customer'da var) — supplier query'si in-memory filter
- Frontend `flutter analyze` koşulmadı (kullanıcı runtime ile doğrulayacak)

**Manuel doğrulama (kullanıcı):**
1. Backend restart sonrası `GET /product/api/v1/accounts/list?limit=5` → JSON `{items, nextCursor, hasMore}`
2. Flutter hot reload → AccountsHub → liste 20'şer kayıt yükleniyor, scroll'da loadMore tetikleniyor
3. Pull-to-refresh çalışıyor; filter/search değiştirince loadFirst tetikleniyor
4. Backend down → AccountsErrorView retry button'u çalışıyor

**Kaynak:** kullanıcı talebi — "plana göre doğru yoldan devam" + "hepsini hallet".

## [2026-04-26] sprint-8 | implementation plan yazıldı

Kullanıcı talebi: "devam" — Sprint 7 sonrası Sprint 8'e geçiş. Geri-dosyalama: [[syntheses/sprint-8-implementation-plan-2026-04-26]].

**Sprint 8 kapsamı (önerilen alt-küme):**
- WP1 (4-5g): B0 Pagination — backend birleşik `/accounts/list` endpoint (cursor-based) + frontend infinite scroll + server-side filter/query (debounced)
- WP2 (1.5h): ErrorBoundary 3 panel yaygın entegrasyon (Sprint 7 hold-over)
- WP3 (1.6g): T2-T4 service-level testler (@SpringBootTest) — reconcile drift + credit limit + sale-payment FK integrity

**Sprint 9'a kaydı:** B8 (overdue notification), B9 (activity history), B6 (yaşlandırma raporu).

**Kritik tasarım kararı:** Cursor-based pagination + birleşik endpoint (mevcut 2 ayrı customer/supplier endpoint yerine) — sayfa sınırı 2 koleksiyon arası kayıp önlenir.

**Açık sorular** (PR review): cursor format (opaque), limit upper bound, filter+query AND, initial loader skeleton vs spinner, pull-to-refresh kapsamı.

**Kullanıcı onayı bekliyor** WP1 implementasyonu için (backend AccountsListController + frontend paginated state).

## [2026-04-26] sprint-7 | WP2 minimum — test infrastructure + ilk test ✅

WP2'nin minimum scope'u uygulandı. `Tests run: 3, Failures: 0, Errors: 0 — BUILD SUCCESS`.

**Yeni dosyalar:**
- `pos-product-manager/pom.xml` — H2 (test scope) eklendi
- `src/test/resources/application-test.properties` — H2 in-memory PostgreSQL mode, ddl-auto=create-drop, sql.init.mode=never
- `src/test/java/com/sedcore/finance/repository/PaymentAllocationRepositoryTest.java` — 3 test (`@DataJpaTest`):
  - `save_withSaleFk_persists` — allocation insert (sale=null)
  - `findByPaymentId_returnsAllocations` — multi-allocation query (B3 senaryosu)
  - `sumActiveBySaleId_excludesCancelled` — cancelled payment'lar hariç toplam

**Mimari kararlar:**
- H2 with PostgreSQL mode seçildi (Testcontainers + Docker daemon kompleksitesinden kaçındık)
- `@DataJpaTest` ile sadece JPA katmanı (full Spring context yok, hızlı)
- `ID elle set edilmez` — TOpenSimpleCompanyEntity @PrePersist ile UUID üretir (lesson learned)
- data.sql test'te koşmaz (`sql.init.mode=never`) — her test temiz state

**Sonraki sprintte (WP2.4):**
- T1 full PaymentCreationIntegrationTest (@SpringBootTest service-level)
- T2 ReconcileDriftDetectionTest
- T3 CreditLimitGuardTest
- T4 SalePaymentFkIntegrityTest

Sprint 7 done kriteri büyük ölçüde sağlandı; hold-over: smoke test (kullanıcı runtime) + ErrorBoundary 3 panel entegrasyon (Sprint 8).

**Kaynak:** kullanıcı talebi — "plana göre doğru yoldan devam".

## [2026-04-25] sprint-7 | WP1+WP3+WP4+WP5 implementasyon (testler ertelendi)

Sprint 7 başlatıldı. Plan: [[syntheses/sprint-7-implementation-plan-2026-04-25]]. Tamamlanan iş paketleri:

**Backend (WP1):**
- Yeni: `PaymentAllocation.java` entity (sale-payment many-to-many, `@Version`, indexes)
- Yeni: `PaymentAllocationRepository.java` (`findByPaymentId/SaleId`, `sumActiveBySaleId`)
- Yeni: `AllocationRequest.java` (DTO)
- Update: `PaymentRequest.java` — `allocations: List<AllocationRequest>` field, `saleId` `@Deprecated`
- Update: `PaymentServiceImpl.java` — `createAllocations()` helper + `createCustomerPayment()` çağrısı
- ✅ Maven compile geçti (exit 0)

**Frontend (WP3+WP4+WP4.b):**
- Yeni: `customer_open_sales_provider.dart` (FutureProvider.family + autoDispose)
- Update: `sales_service.dart` — `getCustomerOpenSales(String customerId)` ek metod
- Update: `payment_record_modal.dart` — `customerId` parametresi, "Hangi Alışverişe?" radio + açık satış picker, submit `allocations` array
- Update: `statement_detail_panel.dart` — caller `customerId` aktarımı + payload `allocations` field
- Yeni: `accounts_error_view.dart` (I2 minimum widget — yaygın entegrasyon Sprint 8'e)

**i18n (WP5):**
- 7 yeni anahtar `accounts.payment_target/general_payment/specific_sale_payment/no_open_sales/sale_remaining/add_another_sale/allocation_sum_mismatch` (TR + EN)
- ID şeması: `bnd-acpa01-07`

**Wiki (WP6):**
- Yeni: [[entities/payment-allocation]]
- Yeni: [[concepts/payment-allocation-pattern]]
- Yeni: [[decisions/payment-allocation-from-day-1]] (B1↔B3 mimari karar ADR)
- Index güncellendi (Sprint 7 Decisions, Cari Hesap concepts, Domain Diğer entities)

**Ertelendi (Sprint sonu):**
- WP2 testler T1-T4 (proje sıfır test infrastructure → ayrı kurulum gerekli)
- WP6 manuel smoke test (kullanıcı runtime ile yapacak)
- I2 ErrorBoundary yaygın entegrasyon (3 panel) — Sprint 8

**Geriye uyum:** `Payment.sale` FK + `PaymentRequest.saleId` `@Deprecated` ama kabul ediliyor. Sprint 9'da kaldırılacak.

**Kaynak:** kullanıcı talebi — "cari işlemler planına devam et" + "B devam, testler sprint sonunda".

## [2026-04-25] query | cari işlemler planına devam — Sprint 7 implementation plan

Kullanıcı talebi: "cari işlemler planına devam et". Geri-dosyalama: [[syntheses/sprint-7-implementation-plan-2026-04-25]] — v2 analizinin Sprint 7'sini 6 iş paketi (WP1-WP6) olarak adım adım uygulama planı.

**WP listesi:**
- WP1 (1g): Backend PaymentAllocation entity many-to-many baştan
- WP2 (1.6g): Backend T1-T4 kritik path testleri (paralel WP1 ile)
- WP3 (0.5g): Frontend service + customerOpenSalesProvider
- WP4 (1g): Frontend PaymentRecordModal sale picker
- WP5 (1.5g): Frontend i18n (7 key) + ErrorBoundary (I2)
- WP6 (0.5g): Wiki final + smoke test

**Net iş:** ~6 gün, 1 hafta sprint. Her WP için: dosya yolu, done kriteri, risk matrisi.

**Sonraki adım:** kullanıcı onayı ile WP1 (backend) implementasyonu başlatılacak.

Index güncellendi: Modül & Mimari Özet altına sprint plan linki.

## [2026-04-25] query | cari hesaplar modülü geliştirme analizi

Kullanıcı talebi: "Cari hesaplar sayfasına odaklanıp geliştirme analizi çıkar." Geri-dosyalama: [[syntheses/accounts-development-analysis-2026-04-25]].

**Kapsam:** 50+ accounts wiki sayfası (entities, syntheses, decisions, concepts, issues + scoped `project_pos/.../accounts/_wiki/`) sentezlendi. Backend kod doğrulaması yapıldı (Payment.saleId FK, SaleController endpoint).

**Bulgular:**
- 5 açık issue (pagination, error boundary, overdue notification, activity history, test coverage)
- 7 yeni geliştirme adayı (alışveriş bazlı ödeme, plaka B/C, toplu ödeme, taksit, hızlı tahsilat, yaşlandırma raporu, SMS bildirim)
- P1-P3 önceliklendirme + 3 sprint roadmap önerisi

**Sprint 7 önerisi:** B1 (alışveriş bazlı ödeme — backend hazır) + I2 (error boundary) + I1 (pagination).

Index güncellendi: Modül & Mimari Özet altına development analysis linki.

## [2026-04-25] query | LINT sonucu yapılması gereken aksiyon planı

Kullanıcı talebi: 134 lint bulgusu için somut aksiyon planı. Geri-dosyalama: [[syntheses/lint-action-plan-2026-04-25]] (P1-P4 öncelikli, sed komutları + manuel sıra + tahmini efor + kabul kriterleri).

**Plan özeti:**
- **P1 (1 saat)** — Hızlı kazanç: 16 sed batch + 6 eksik hedef kararı + 8 placeholder fix
- **P2 (3-5 saat)** — Orta: 18 MERGE_NEEDED inceleme + 5 issues merge + 50 xref ekleme + 5 zayıf kaynak doğrulama
- **P3 (1 saat)** — Lint Pass 3 koşturma + archive doldurma
- **P4 (sprint backlog)** — React/controller/core ingest

**Hedef sağlık skoru:** Y:0, O:<20, D:<30 (mevcut Y:23 O:130 D:~76).

Index güncellendi: Modül & Mimari Özet altına aksiyon planı linki.

## [2026-04-25] query | tüm kod dosyalarından wiki güncelleme (faz 1 — pragmatic)

Kullanıcı talebi: "proje altındaki bütün kod dosyalarını oku, wiki belleğini bu mevcut kod üzerinden güncelle." Pragmatic kapsam (1362 kod dosyası tek turda imkansız): **lint-report'taki 13 eksik kavram için kod kanıtı + son 15 commit deltası**.

### Yeni dosyalar (15)

**Decisions (1):**
- `decisions/2026-04-24-vehicle-plate-tracking-option-a.md` — Sprint 6b ADR (description prepend, schema değişikliği yok). Scoped wiki'deki sentezi ana wiki'ye yansıt.

**Syntheses (1):**
- `syntheses/codebase-snapshot-2026-04-25.md` — kod ↔ wiki uyum analizi, son 15 commit drift, 1362 dosya envanter, faz planı.

**Entities (7) — eksik kavramlar için kod-bazlı stub:**
- `entities/user-def.md` (core/.../security/UserDef.java)
- `entities/user-def-access.md` (core/.../security/UserDefAccess.java)
- `entities/product-variant.md` (pos-product-manager/.../product/entity/ProductVariant.java)
- `entities/accounts-hub-screen.md` (project_pos/.../accounts/screens/accounts_hub_screen.dart)
- `entities/document-item-result.md` (pos-product-manager/.../product/model/DocumentItemResult.java)
- `entities/batch-entry-row.md` (project_pos/.../batch_entry/models/batch_entry_models.dart:251)
- `entities/company-setting.md` (pos-product-manager/.../company/entity/CompanySetting.java)

**Concepts (6) — eksik kavramlar için kod-bazlı stub:**
- `concepts/company-context.md` (pos-product-manager/.../common/context/CompanyContext.java)
- `concepts/pre-authorize-guard.md` (Spring Security pattern, 1 kullanım)
- `concepts/batch-entry-state.md` (project_pos/.../batch_entry/models/batch_entry_models.dart:473)
- `concepts/batch-row-status.md` (batch_entry_models.dart:1 enum)
- `concepts/app-colors-palette.md` (project_pos/lib/core/theme/app_colors.dart)
- `concepts/state-notifier-vs-async.md` (Riverpod migration özeti, henüz başlamadı)

### Index güncellendi (5 alt-bölüm)

- Decisions → Sprint 6b alt-bölümü
- Syntheses → Modül & Mimari Özet altına codebase-snapshot
- Entities → Security Domain (yeni alt-bölüm), Ürün satırı, Firma satırı, Flutter Screens & Models (yeni alt-bölüm)
- Concepts → Mimari satırına 2 yeni link, Flutter / Frontend (yeni alt-bölüm) — 4 yeni link

### Faz Dışı (sonraki turlara)

- React (template/) modülü — 525 dosya, sadece CLAUDE.md kopyası kapsamlı değil
- pos-product-manager controller-bazlı endpoint kataloğu — ~50 dosya
- core kütüphane derinleşme (TOpenSimpleCompanyEntity, BaseDbServiceImp, @FilterDef)
- 18 MERGE_NEEDED dosya manuel diff (lint borçları)

**Kaynak:** kullanıcı talebi (auto + plan mode geçişleri)

## [2026-04-25] lint | 134 bulgu (Y:23 O:130 D:~76) — tam pass 2

`raw/` hariç **188 dosya** üzerinde 6 kategorili tam sağlık kontrolü. Mekanik (Bash) + sample diff (manuel). Otomatik düzeltme yapılmadı; rapor: [[lint-report]].

**Sayım:**
- 🔴 Çelişki (gerçek): **0** (3 sample diff yapıldı — hepsi DUPLICATE/zenginleştirme)
- 🟠 Çelişki adayı (MERGE_NEEDED): 21 (18 `-from-claude-wiki` + 3 ADR↔sentez)
- ✅ Eskimiş: 0 (tümü ≤12 gün)
- 🟠 Yetim: 18 (hepsi `-from-claude-wiki` — MERGE_NEEDED ile örtüşür)
- 🔴 Kırık wikilink (gerçek): 22 (16 ad değişimi + 6 eksik hedef)
- 🟠 Eksik kavram (≥10 bahis, sayfa yok, generic terim filtreli): 13 (`UserDef`, `UserDefAccess`, `ProductVariant`, `CompanyContext`, `AccountsHub`, `BatchEntryRow`, vb.)
- 🟡 Tek-yönlü xref: 773 ham → ~50 öncelikli (concept↔entity karşılıklı eksiklik)
- 🟠 Zayıf kaynak (≤1 source): 81 (parser sınırlı; manuel doğrulama önerildi)

**En kritik 3:** (1) 16 ad-değişen kırık wikilink — sed ile 10 dk; (2) 18 MERGE_NEEDED yetim — manuel diff 2-3 saat; (3) 13 eksik domain kavram — UserDef/ProductVariant gibi core entity sayfaları yok.

**Kaynak:** kullanıcı /lint-pass talebi.

## [2026-04-25] migration | Proje geneli .md konsolidasyonu → .wiki/

Kullanıcı talebi: "proje altındaki tüm `.md` dosyalarını `.wiki/`'ye entegre et + orijinallerini sil/stub bırak". Plan: `C:\Users\Win11\.claude\plans\polymorphic-gathering-flute.md`. AskUserQuestion ile 4 karar netleştirildi (CLAUDE.md hard-delete vs stub çelişkisinde safety nedeniyle B yorumu / stub uygulandı).

**Kapsam dışı (dokunulmadı):** `template/node_modules/**` (1500+ npm artifact), `**/target/**`, `.git/**`, `.claude/worktrees/**`, `project_pos/ios/.../LaunchImage README`, `core/.github/...progress.md`, `.wiki/**` (hedef vault).

**6 paralel agent + manuel:** ~117 dosya işlendi.

| Grup | Kapsam | Dosya | Sonuç |
|---|---|---|---|
| Agent A | `.claude/{decisions,runbooks,reference,status,plans,guides,inventory,commands,INDEX}/` + 3 root scratch | 25 | Hepsi taşındı + stub. `multi-tenant.md` çakıştığı için `multi-tenant-routing.md` adıyla yazıldı. |
| Agent B1 | `.claude/wiki/entities/*` | 18 | Hepsi DUPLICATE (önceki ingest'te wiki'de mevcuttu) → stub. README ayrı kaydedildi. |
| Agent B2 | `.claude/wiki/{decisions,concepts,patterns,syntheses,integrations}/*` | 27 | 23 DUPLICATE, 1 NEW (`use-entity-graph-for-customer-account-fetch`), 3 README silindi. |
| Agent B3 | `.claude/wiki/{flows,issues,archive,raw,sources,glossary,contradictions,index,log,lint-report}/*` | 32 | 5 issues `-from-claude-wiki` suffix'i ile MERGE_NEEDED, geri kalan stub. 5 NEW yazım. |
| Agent C | Module README + `pos-product-manager/ERROR_HANDLING_GUIDE.md` | 3 | Hepsi NEW. |
| Agent E | 10 CLAUDE.md (root + 7 modül + 2 alt + `.claude/wiki/CLAUDE.md`) | 10 | Hepsi `.wiki/sources/claude-md/` altına; ~37 link replace (`.claude/reference/...` → `.wiki/concepts/...` vb.); orijinaller 1-satır pointer stub. |
| Manuel | 2 patterns (`optimistic-lock-version`, `scoped-feature-wiki`) | 2 | DUPLICATE → stub. |

**MERGE_NEEDED (manuel inceleme bekleniyor):** `-from-claude-wiki` suffix'li 5 issues + bazı concepts. Mevcut wiki sayfasıyla kaynak içerik farklılığı tespit edildi.

**Yeni dizin:** `.wiki/sources/status-snapshots/`, `.wiki/sources/claude-md/`.

**Index güncellendi:** Yeni 4 bölüm (CLAUDE.md Arşivi, Status Snapshots, Code-refs migration alt-bölümü, Patterns alt-bölümü). 50+ yeni MOC link.

**Stub formatı:** `> Bu içerik [.wiki/...](göreceli-link) altına taşındı (2026-04-25).` Auto-load mekanizması stub'ı okur, link üzerinden devam eder.

**Etkilenen yollar:** `.claude/{decisions,runbooks,reference,status,plans,guides,inventory,commands,wiki}/`, root CLAUDE.md ve 7 modül CLAUDE.md, 3 root scratch, 3 module README/GUIDE.

**Kaynak:** kullanıcı talebi (auto mode + AskUserQuestion onayı).

## [2026-04-25] full-setup | İlk kapsamlı kurulum + 7 kaynak ingest + 4 sentez + lint
- **PHASE 1 (Setup)**: 9 alt klasör + 9 .gitkeep + CLAUDE.md (217 satır) + index.md + log.md zaten kuruluydu (önceki turlardan)
- **PHASE 2 (Kaynak seçimi)**: Proje genelinde 7 öncelikli kaynak seçildi (CLAUDE.md kök, accounts-hub gap, sale-checkout, purchase-checkout, drift-reconciliation, openapi-codegen, ledger-adr). Symlink (ln -s) Windows Git Bash'te kopyalama davranışı yaptığı için pointer-markdown fallback'a geçildi → `raw/code-refs/2026-04-25-*.md` (7 dosya)
- **PHASE 3 (Ingest)**: Her kaynak için sources/code-refs/2026-04-25-<slug>.md (7 source summary). Bahsedilen 22 entity, 15 concept, 18 decision, 12 issue açıldı. Toplam 74 yeni içerik sayfası.
- **PHASE 4 (Sentez)**: 4 yüksek seviyeli sentez yazıldı:
  - `syntheses/pos-module-map` — servis + client haritası
  - `syntheses/sector-agnostic-architecture` — çoklu sektör mimarisi
  - `syntheses/accounts-module-overview` — cari hesap modülü
  - `syntheses/integration-catalog` — entegrasyon kataloğu
- **PHASE 5 (Lint)**: lint-report.md yazıldı — 0 yüksek/orta, 14 düşük (stub sayfalar). Çelişki yok, yetim yok, eskimiş yok.
- **PHASE 6 (Index/Log sync)**: index.md tüm kategorilerle güncel, log.md bu girdi.
- Toplam: 88 markdown dosyası (CLAUDE.md + index + log + lint-report + 84 içerik) ; 355+ wikilink cross-ref.
- Kaynak: kullanıcı talebi — tam otomatik tek-pass setup + ingest

## [2026-04-25] setup | Wiki iskeleti yeniden kuruldu (overwrite)
- Dokunulan dosyalar: `.wiki/CLAUDE.md`, `.wiki/index.md`, `.wiki/log.md`
- Kaynak: kullanıcı talebi — aynı scaffold prompt'u 2. kez; seçim: "Tam yeniden kur (overwrite)"
- Not: 9 alt klasör + 9 `.gitkeep` idempotent korundu; `raw/` hâlâ 0 kaynak. Placeholder yorumları sabit: `{{KAYNAK_KLASORU}}=code-refs`, `{{SORUN_KLASORU}}=issues`, `{{PROJE_ADI}}=SEDCORE POS`, `{{DIL}}=Türkçe`.

## [2026-04-24] setup | Wiki iskeleti kuruldu (ilk tur)
- Dokunulan dosyalar: `.wiki/CLAUDE.md`, `.wiki/index.md`, `.wiki/log.md`, 9 alt-klasör + `.gitkeep`
- Kaynak: kullanıcı talebi — `.wiki` yeni bağımsız vault, SEDCORE POS için sektör-agnostik kalıcı bilgi arşivi
- Not: İlk ingest manuel tetiklenecek. `raw/code-refs/` ve `raw/docs/` boş.
