---
title: Fiş Yazıcı Her Açılışta Yeniden Tanıtım Gerektiriyor (FIX UYGULANDI — Manuel Test Bekliyor)
tags: [issue, in-progress, receipt-printer, escpos, usb, ux, persistence, sprint-30]
date: 2026-05-06
status: fix-applied
priority: high
source: project_pos/lib/services/print/print_settings.dart, project_pos/lib/services/print/print_service.dart, project_pos/lib/features/settings/screens/printer_settings_screen.dart
---

# Fiş Yazıcı Her Açılışta Yeniden Tanıtım Gerektiriyor

## Semptom

Kullanıcı POS uygulamasını her açtığında **fiş yazıcısını (POSA / Zjiang termal, USB)** ayarlardan tekrar seçmek zorunda kalıyor. Beklenen davranış: yazıcı **bir kez** tanıtıldıktan sonra her oturumda otomatik kullanılabilmeli — "set & forget".

> Kullanıcı talebi (2026-05-06): *"FİŞ YAZICI UYGULAMADA SADECE BİR DEFA TANITILMALI HER SEFERİNDE TANIMA İHTİYACINDAN KURTUL"*

## Mevcut Durum (Kod Analizi)

`PrintSettings` zaten **SharedPreferences** ile kalıcı saklamaya sahip:

- [`print_settings.dart:87-101`](project_pos/lib/services/print/print_settings.dart#L87) — `load()` açılışta `vendorId`/`productId`/`deviceName` okur.
- [`print_settings.dart:160-163`](project_pos/lib/services/print/print_settings.dart#L160) — `printSettingsProvider` provider create'inde `..load()` çağırıyor.
- [`print_settings.dart:103-114`](project_pos/lib/services/print/print_settings.dart#L103) — `updateDevice()` `_persist()` çağırarak yazıyor.

Yani teoride bir kez seçildikten sonra **her açılışta otomatik yüklenmeli**. Buna rağmen kullanıcı her seferinde tanıtım gerektiğini bildiriyor → ya persistence kırılıyor ya da `isConfigured` flag UI'da yanıltıcı görünüyor.

## Olası Kök Nedenler

### 1. Async load race — UI cihaz bağlı sanmıyor olabilir
`load()` async, ama `printSettingsProvider` initial state `const PrintSettings()` (boş). UI ilk render'da `isConfigured = false` gördüğü için kullanıcıya "yazıcı yapılandırılmamış" gösteriyor olabilir. `..load()` tamamlanınca state güncellenir ama UI feedback'i kullanıcıya "hala kayıtlı değil" izlenimi veriyorsa kullanıcı yeniden seçiyor.

**Doğrulama**: `printer_settings_screen.dart` ilk frame'de `state.isConfigured` durumunu nasıl gösteriyor? Loading state var mı?

### 2. Windows USB enumeration — VID/PID değişmiyor ama `deviceName` farklılaşıyor
`flutter_pos_printer_platform_image_3` Windows'ta `EnumPrintersW` kullanıyor (bkz. [`print_service.dart:21-25`](project_pos/lib/services/print/print_service.dart#L21)). Cihaz portu değişirse veya Windows farklı bir sistem yazıcısı eşleştirirse `_send()` connect aşaması başarısız olabilir → kullanıcı çare olarak yazıcıyı silip yeniden seçiyor olabilir.

**Doğrulama**: `_send()` 95-98 satırlarında "Yaziciya baglanilamadi" hatası nasıl handle ediliyor? Tek başarısızlık kullanıcıyı settings'e yönlendiriyor mu?

### 3. `clearDevice` istemsiz tetikleniyor olabilir
`clearDevice()` çağrılırsa SharedPreferences anahtarları siliniyor (`prefs.remove(_kVendorId)` vb.). Bağlantı testi başarısızlığında veya bir UX akışında otomatik clear yapılıyor olabilir.

**Doğrulama**: `printer_settings_screen.dart` içinde `clearDevice()` çağıran tüm kod yolları taranmalı — örtük tetikleniyor mu?

### 4. SharedPreferences instance per-build farklı olabilir (low risk)
Genelde `SharedPreferences.getInstance()` singleton döndürür, ama Windows desktop sürümünde bir bug veya hot-restart davranışı varsa state taşınmıyor olabilir.

**Doğrulama**: Manuel testte `print.vendor_id` anahtarının `%APPDATA%/com.example.project_pos/shared_preferences.json` içinde kalıcı olduğunu kontrol et.

## Çözüm Hedefi

Kullanıcı bir kez yazıcıyı seçtikten sonra:

1. **Açılışta otomatik bağlantı denemesi** — `_send()` ilk çağrıda `connect()` başarısızsa otomatik olarak cihaz listesini yeniden tara, aynı VID/PID'yi bul, `deviceName`'i güncelle, persist et. (Self-healing.)
2. **Connect başarısızsa silme yok, retry + uyarı** — yazıcı kayıtlı kalmalı. Toast: *"Yazıcı bağlı değil, lütfen kabloyu kontrol edin."* — kayıt silinmesin, kullanıcı tekrar seçim yapmaya zorlanmasın.
3. **`isConfigured` UI feedback** — settings ekranında yeşil/turuncu rozet kalıcı görünmeli; "Test Yazdır" başarılı/başarısız ayrı state, persistence'ı etkilemesin.
4. **Etiket yazıcı için aynı patern** — `LabelPrintSettings` aynı düzeltmeyi paralel almalı (`label_print_settings.dart`).

## Aksiyon Planı (Sprint 30+ adayı)

1. **Reproduce + Log** — geliştirici makinesinde uygulamayı kapat/aç, SharedPreferences durumunu logla. Kullanıcının raporladığı semptomun hangi senaryoda ortaya çıktığını sabitle.
2. **Settings ekranı initial-render denetimi** — `printer_settings_screen.dart` ilk frame'de `isConfigured` doğru mu?
3. **Self-healing connect** — `print_service.dart` `_send()` connect başarısızsa fallback discover + match + retry.
4. **Persistence guard** — `clearDevice` yalnızca kullanıcı explicit "Bağlantıyı Kaldır" butonuna basınca tetiklensin; başka kod yolundan çağrı yok.
5. **Manuel test rehberi güncelle** — [[sources/code-refs/2026-05-01-label-printer-manual-test-guide]] benzeri bir rehber fiş yazıcı için yazılmadıysa açılır; "uygulama kapatıldıktan sonra ayarlar korundu mu?" senaryosu eklenir.

## Uygulanan Fix (2026-05-06, Sprint 30)

### A) `loaded` flag — hidrasyon farkındalığı

`PrintSettings` ve `LabelPrinterSettings` constructor'ına `loaded: false` field eklendi; `load()` tamamlandığında `loaded: true` olur. Settings ekranları ilk render'da `loaded == false` ise `CircularProgressIndicator` gösterir → kullanıcı "yazıcı yok" yanılgısına düşmez ve gereksiz yere yeniden seçim yapmaz.

- [`print_settings.dart`](project_pos/lib/services/print/print_settings.dart) — `loaded` field + copyWith
- [`label_print_settings.dart`](project_pos/lib/services/print/label_print_settings.dart) — paralel
- [`printer_settings_screen.dart`](project_pos/lib/features/settings/screens/printer_settings_screen.dart) — `if (!settings.loaded) → loading scaffold`
- [`label_printer_settings_screen.dart`](project_pos/lib/features/settings/screens/label_printer_settings_screen.dart) — paralel

### B) Self-healing connect — Windows enumeration drift'i tolere et

`PrintService._send()` ve `LabelPrintService._send()` connect başarısız olursa:

1. **Hızlı yol**: kayıtlı `deviceName` ile `_tryConnect()` dene
2. **Self-heal**: başarısızsa `discoverDevices()` çağrısı → kayıtlı VID/PID match eden cihazın güncel `name`'ini bul → o name ile retry
3. **Persist**: yeni name SharedPreferences'a `refreshDeviceName(newName)` ile back-write edilir → bir sonraki açılışta direkt başarılı connect
4. **Kayıt korunur**: tüm denemeler başarısız olsa bile VID/PID/name silinmez; kullanıcı "yazıcı takılı ve açık mı kontrol edin" mesajı görür ama yeniden tanıtım gerekmez

`_onDeviceNameRefresh` callback ile servis `printSettingsProvider` notifier'ına dependency-injected back-write yapar.

### C) Sanal yazıcı sweep — sadece hidrasyon sonrası

`printer_settings_screen.dart` `initState()`'teki "sanal yazıcıyı temizle" kodu hidrasyon henüz tamamlanmadığı için `deviceName=''` görüp false-negative üretiyordu (gerçek POSA cihazı kayıtlıyken bile sweep çalışıyordu). `_sweepVirtualPrinterIfHydrated()` build içinde `settings.loaded == true` koşulunda **bir kez** çalışır.

### D) TextEditingController hidrasyon senkronizasyonu

`_headerCtl` / `_footerCtl` (fiş) ve `_widthCtl` / `_heightCtl` (etiket) `initState`'te default değerlerle dolduruluyordu (hidrasyondan önce). İlk `loaded=true` build'inde gerçek SharedPreferences değerleriyle `_hydrateTextControllers()` / `_hydrateDimensionControllers()` çağrısıyla senkronize edilir.

### Test Edilecek Senaryolar (manuel)

- [ ] **S1**: Yazıcı bir kez seç → uygulama kapat → tekrar aç → yazıcı kayıtlı görünmeli, yeniden tarama/seçim gerekmez
- [ ] **S2**: Yazıcı seç → fişi başarıyla yazdır → yazıcıyı USB'den çıkar → "Test Yazdır" → "bağlanılamadı, kayıt korunuyor" mesajı + yazıcı listede kalmalı
- [ ] **S3**: Yazıcı seç → uygulamayı kapat → Windows'ta yazıcı sürücü adını değiştir (Aygıt Yöneticisi) → uygulamayı aç → "Test Yazdır" → ilk connect fail → discovery + retry başarılı → yeni name back-write
- [ ] **S4**: Etiket yazıcı için aynı 3 senaryo
- [ ] **S5**: Sanal yazıcı (Microsoft Print to PDF) kayıtlıysa → uygulama açılışında uyarı + temizlik (mevcut davranış, regresyon yok)

### `flutter analyze`

Print modülü dosyalarında `No issues found!` (4.2s, 3 dosya). Mevcut 164 info-level uyarı bu fix dışındaki dosyalardan.

## Sources

- [`print_settings.dart`](project_pos/lib/services/print/print_settings.dart) — SharedPreferences persistence
- [`print_service.dart`](project_pos/lib/services/print/print_service.dart) — connect/send/disconnect akışı
- [`printer_settings_screen.dart`](project_pos/lib/features/settings/screens/printer_settings_screen.dart) — UI giriş noktası
- Kullanıcı raporu (2026-05-06): "fiş yazıcı her seferinde yeniden tanıtılıyor"

## Related

- [[syntheses/label-printer-architecture]] — etiket yazıcı için paralel mimari (aynı patern)
- [[syntheses/integrations-hub-architecture]] — Cihazlar Hub L1→L3 promotion paterni
- [[entities/project-pos]] — Flutter app
