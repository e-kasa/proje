---
title: Etiket Yazıcı Mimarisi (Sprint 24)
tags: [synthesis, label-printer, escpos, hardware, sprint-24, integrations, extension-pattern]
source: project_pos/lib/services/print/, lib/features/settings/integrations/
date: 2026-05-01
status: draft
---

# Etiket Yazıcı Mimarisi

Sprint 24'te [[syntheses/integrations-hub-architecture]] **L1→L3 promotion** paterninin **ilk somut kullanımı**. Audit: [[sources/code-refs/2026-05-01-label-printer-implementation-audit]].

## Kararlar

### K1. İki Ayrı Slot — Tek Paket
**Karar:** `printSettingsProvider` (fiş, mevcut) + `labelPrintSettingsProvider` (etiket, yeni) **iki ayrı StateNotifier**. Aynı paket (`flutter_pos_printer_platform_image_3`) farklı `PrinterManager.instance` kullanmaz — singleton ama serial async ile race olmaz.

**Sebep:**
- Kullanıcı senaryosu net: 2 ayrı yazıcı (Zjiang fiş + Zebra etiket) veya tek yazıcı her ikisi için
- Tek `printSettingsProvider`'a `labelMode` flag eklemek karmaşık state machine yaratır
- Ayrı slot → temiz separation, her slotun kendi paper width/cut/header ayarı bağımsız
- SharedPreferences key prefix farklı (`print.*` vs `label_print.*`) — migration sorunu yok

**Alternatif (reddedilen):** Tek `PrintSettings` extend edip iki cihaz alanı taşı. Reddi: state shape karmaşıklaşır, mevcut `printSettingsProvider` consumer'ları (POS receipt flow) bozulur.

### K2. ESC/POS Only — ZPL Sprint 25+
**Karar:** Sprint 24 sadece ESC/POS termal etiket yazıcı destekler (Zjiang/POSA tarzı). ZPL (Zebra) adapter **yapılmaz**.

**Sebep:**
- Kullanıcı Zjiang sahibi → ESC/POS yeter (audit R2)
- ZPL ayrı paket gerekir (`zpl` paketi veya custom serializer)
- Sprint 19 kuralı: gerçek talep gelince inşa et — Zebra talebi şu an yok
- Mimari ZPL'e açık: `LabelPrintService` arkasına `LabelDriver` interface'i eklemek 1-2 saatlik iş, gelecekte yapılır

**Genişletme noktası (Sprint 25+ için):**
```dart
abstract class LabelDriver {
  Future<List<int>> buildBarcodeBytes({...});
}
class EscPosLabelDriver implements LabelDriver { ... }   // Sprint 24
class ZplLabelDriver implements LabelDriver { ... }      // Sprint 25+ (talep gelince)
```

Sprint 24'te `LabelPrintService` direkt `EscPosLabelTemplate` kullanır; driver soyutlaması Sprint 25'te eklenir.

### K3. ProductDetail 3-State Akış (Geriye Uyumlu Fallback)
**Karar:** `_printBarcodeLabels` üç davranışlı:
- **Case 1:** Etiket yazıcı yapılandırılmış + Windows desktop → `LabelPrintService` USB direkt, hızlı
- **Case 2:** Yapılandırılmış ama USB hata (cihaz kopuk, driver yok, vb.) → AppToast.warning + `Printing.layoutPdf` fallback
- **Case 3:** Yapılandırılmamış veya web → mevcut `Printing.layoutPdf` davranışı

**Sebep:**
- Mevcut kullanıcılar için **regresyon yok** (Case 3 = eski akış)
- Yeni kullanıcılar yapılandırırsa otomatik hızlı yola düşer (Case 1)
- Kapasıte problemi ya da yanlış konfigürasyon panik yaratmaz (Case 2)
- Web kullanıcıları zaten USB erişemez → tarayıcı print dialog (Case 3) korunur

**Alternative (reddedilen):** "Kayıt yoksa hata, dialog'a düşme yok" — yeni özellik dayatması, mevcut kullanıcı için bozulma.

### K4. Hub L1→L3 Promotion — 3-Katman Paterninin Doğrulanması
**Karar:** [[syntheses/integrations-hub-architecture]]'da öngörülen 3 adımı tam takip et:
1. `IntegrationDef.configRoute` ekle (catalog'da)
2. `integrationStatusProvider` `case 'label_printer':` real provider watch
3. Yeni ekran + router

Hub kodu (`integrations_hub_screen.dart`) **dokunulmaz**. Bu paterni doğrulayan ilk somut promotion → mimari sağlamlığını gösterir.

**Sebep:**
- Sprint 23'te tasarlanan extension paterninin testi
- Gelecek L1→L3 promotion'lar (scale, label_printer, vb.) için referans
- Hub stabilize, sadece configuration ekleyerek genişletilebilir

### K5. Test Etiketi Butonu — Erken Hata Tespit
**Karar:** Settings ekranında "Test Etiketi Yazdır" butonu zorunlu. Kullanıcı yazıcı seçtikten sonra önce test eder, ESC/POS komut uyumsuzluğu üretimde değil setup sırasında ortaya çıkar.

**Test etiket içeriği:** Code128 barkod (`TEST-12345`) + ürün adı placeholder + tarih.

**Sebep:** Audit R2 — düşük-cost Çin firmware'i `GS k 73` komutunu yanlış implement edebilir. Test başarısızsa kullanıcı kaydı silebilir, fallback yola düşer.

### K6. Aynı USB Cihaz İki Slot — Kabul + Uyarı
**Karar:** Kullanıcı tek Zjiang yazıcısını hem fiş hem etiket olarak kayıtlayabilir. Engelleme yok, yumuşak uyarı: "Bu cihaz fiş yazıcısı olarak da kayıtlı."

**Sebep:**
- KOBİ tipik: tek termal yazıcı, hem makbuz hem barkod
- Sert engelleme yapay kısıtlama yaratır
- Uyarı kullanıcıya bilinçli seçim hakkı bırakır
- Race condition yok (audit R4) — Dart single-threaded async

## Mimari Şeması

```
ProductDetail._printBarcodeLabels()
   │
   ├─ Case 1: !kIsWeb && labelPrintSettings.isConfigured
   │      ↓
   │   labelPrintServiceProvider.printBarcodeLabel(...)
   │      ↓
   │   LabelTemplate.buildBarcodeLabel() → ESC/POS bytes
   │      ↓
   │   PrinterManager.connect(USB) + send(bytes)
   │      ↓
   │   (success?) ✓ → AppToast.success
   │              ✗ → fall to Case 2
   │
   ├─ Case 2: USB hata
   │      ↓
   │   AppToast.warning('dialog\'a düşülüyor')
   │      ↓
   │   _fallbackToPdfDialog() (Case 3 yolu)
   │
   └─ Case 3: Yapılandırılmamış/web
          ↓
       Printing.layoutPdf(onLayout: pw.Document...)
          ↓
       OS print dialog → kullanıcı yazıcı seç → driver → cihaz
```

```
Settings → Cihazlar Hub → Etiket Yazıcı kartı (L3 sonra)
   │
   ├─ Web: dim opacity + "Masaüstü" badge (Sprint 23 kIsWeb guard)
   ├─ Desktop, configRoute set → context.push('/settings/label-printer')
   │
   └─ LabelPrinterSettingsScreen
         ├─ Bağlı yazıcı status (yeşil/turuncu)
         ├─ USB Cihazları Tara butonu
         ├─ Discovered devices listesi
         ├─ Etiket boyutu (genişlik/yükseklik mm)
         ├─ Default code type (Code128 / EAN13 / QR)
         ├─ "Her etiketten sonra otomatik kes" switch
         ├─ Test Etiketi Yazdır butonu
         └─ Bağlantıyı kaldır (× ikonu)
```

## Riskler ve Mitigasyon

| Risk | Olasılık | Mitigasyon |
|---|---|---|
| Termal makara yapışkan değil — kullanıcı yapışkan etiket bekliyor | DÜŞÜK | Settings ekranında hint: "Yapışkanlı etiket için Zebra önerilir; Sprint 25+ ZPL adapter" |
| ESC/POS barkod komutu Zjiang firmware'inde tanınmaz | ORTA | Test Etiketi butonu + Case 2 fallback (PDF dialog) |
| PrinterManager race (fiş + etiket aynı anda) | DÜŞÜK | Dart async serial; manuel test: arka arkaya bas, çakışma var mı kontrol |
| Aynı USB cihaz iki slot — kullanıcı confused | DÜŞÜK | Yumuşak uyarı; KOBİ için doğru senaryo |
| Sprint 24 i18n cleanup planı + bu sprint hardcoded TR ekler | DÜŞÜK | Audit'te listele, i18n cleanup turunda toplu migrate |

## Implementation Sıra

Audit + synthesis önce yazıldı. Sonra:

1. `label_print_settings.dart` — `print_settings.dart` paterni paralel
2. `label_print_service.dart` — `print_service.dart` paterni paralel
3. `label_template.dart` — yeni dosya, ESC/POS bytes builder
4. `label_printer_settings_screen.dart` — `printer_settings_screen.dart` paterni paralel + ek alanlar
5. `app_router.dart` — `/settings/label-printer` route
6. `integrations_provider.dart` — `label_printer` case real
7. `product_detail_screen.dart:1069-1161` — `_printBarcodeLabels` 3-state
8. `flutter analyze` doğrula
9. Wiki log entry + index satırı

## Sources

- [[sources/code-refs/2026-05-01-label-printer-implementation-audit]] — bu mimarinin doğduğu audit
- [[syntheses/integrations-hub-architecture]] — 3-katman extension paterni (Sprint 23, bu sprint test ediyor)
- [`print_settings.dart`](project_pos/lib/services/print/print_settings.dart) — Akış A reference pattern
- [`print_service.dart`](project_pos/lib/services/print/print_service.dart) — PrintService template
- [`receipt_template.dart`](project_pos/lib/services/print/receipt_template.dart) — ASCII normalize helper
- [`product_detail_screen.dart:1069`](project_pos/lib/features/inventory/screens/product_detail_screen.dart#L1069) — modify edilecek mevcut kod

## Related

- [[concepts/sector-agnostic]] — etiket yazıcı sektör-bağımsız
- [[entities/project-pos]] — Flutter app
- [[log]] — Sprint 24 entry implementation sonrası eklenecek
