---
title: Etiket Yazıcı Manuel Test Rehberi (Sprint 24)
tags: [test-guide, label-printer, manual-test, sprint-24, escpos, zjiang]
source: project_pos/lib/services/print/, lib/features/inventory/screens/product_detail_screen.dart
date: 2026-05-01
status: verified
related-sprint: 24
---

# Etiket Yazıcı Manuel Test Rehberi

Sprint 24 implementasyonu sonrası **kullanıcı tarafından runtime'da yapılacak** smoke test akışı. Audit: [[sources/code-refs/2026-05-01-label-printer-implementation-audit]] · Synthesis: [[syntheses/label-printer-architecture]].

## Önkoşullar

| | Donanım | Yazılım |
|---|---|---|
| **Zorunlu** | Windows 10/11 PC | Flutter SDK + `flutter_pos_printer_platform_image_3` paketi pubspec'te |
| **Tercihli** | Zjiang/POSA termal yazıcı (USB) | Windows generic USB driver (Aygıt Yöneticisi'nde tanınır) |
| **Opsiyonel** | İkinci termal yazıcı (fiş için) | — |

## Çalıştırma Komutu

```bash
cd project_pos
flutter run -d windows
```

> ⚠️ `flutter run -d chrome` ile **çalışmaz** — Sprint 23 hot-fix kIsWeb guard tarafından engellenmiş, USB tarama "USB tarama bu platformda desteklenmiyor (yalnız masaüstü)" toast verir.

---

## Senaryo 1: Yapılandırılmamış (Geriye Uyum — Case 3)

**Amaç:** Sprint 24 öncesi davranış korunmuş mu?

**Adımlar:**
1. Settings → Cihazlar & Entegrasyonlar → "Etiket Yazıcı" satırı görmeli
2. Status: **turuncu** "Yapılandırılmadı" badge + subtitle "Tara → Cihaz seç"
3. **Tıklamadan** geri çık → ürün listesine git
4. Bir ürün aç → **Barkod Yaz** butonu (toolbar veya ilgili tab)
5. Modal: barkod tipi/boyut/adet seç → **Yazdır** tıkla

**Beklenen sonuç:**
- Modal kapanır
- Windows **standart print dialog** açılır (yazıcı seçim penceresi)
- Sistem yazıcılarından biri seçilebilir
- "İptal" çekilse bile uygulama crash etmez, dialog kapanır

**Doğrulama:** Sprint 24 öncesi davranış birebir aynı — bu sprint regresyon yaratmadı.

---

## Senaryo 2: Yapılandırılmış + USB Direkt (Case 1)

**Amaç:** Yeni USB ESC/POS akışı çalışıyor mu?

**Setup:**
1. Zjiang termal yazıcıyı USB ile bağla, gücünü aç
2. Aygıt Yöneticisi'nde "USB Yazıcı Destek" veya benzer cihaz görünmeli
3. Settings → Cihazlar & Entegrasyonlar → **Etiket Yazıcı** kartına tıkla
4. **USB Cihazları Tara** butonuna tıkla
5. Listede Zjiang/POSA cihazını gör → tıkla
6. Yeşil onay: "Etiket yazıcı seçildi: ..."
7. Etiket boyutu: **50×30mm** (varsayılan)
8. Default barkod tipi: **Code128** (varsayılan)
9. **Test Etiketi** butonu → bir test etiketi basılmalı
   - İçerik: "Test Etiketi" + Code128 barkod (`TEST-12345`) + "SKU: TEST-SKU" + "TL 99,99"
10. Geri Settings → ana ekrana git
11. Bir ürün aç → **Barkod Yaz** → adet 3, tip Code128 → **Yazdır**

**Beklenen sonuç:**
- ❌ Print dialog AÇILMAZ
- ✅ Termal yazıcıdan **3 ayrı barkod etiketi** çıkar (ayrı ayrı kesim varsa)
- ✅ Toast: "3 etiket yazdırıldı."
- ✅ Hız: < 2 saniye (3 etiket için)

**Doğrulama:** USB ESC/POS direkt akışı (Akış C) çalışıyor.

---

## Senaryo 3: Yapılandırılmış + USB Hata (Case 2 Fallback)

**Amaç:** Cihaz bağlantı hatasında graceful fallback çalışıyor mu?

**Setup:**
1. Senaryo 2'de yazıcı yapılandırıldı (status yeşil)
2. **Zjiang yazıcısının USB kablosunu çıkar** (veya gücünü kapat)
3. Bir ürün aç → **Barkod Yaz** → adet 1 → **Yazdır**

**Beklenen sonuç:**
- ⚠️ Toast: **"Etiket yazıcısına bağlanılamadı. Sistem yazıcı seçim penceresine düşülüyor."**
- Windows print dialog açılır (Senaryo 1 davranışı)
- Uygulama crash etmez
- Logger console'da: `Etiket yazıcı USB tarama hatası` veya bağlantı hatası kaydı

**Doğrulama:** Case 2 → Case 3 graceful fallback çalışıyor; kullanıcı kayıp etiket basamaz, alternatif yola düşer.

---

## Senaryo 4: Web Platform Guard

**Amaç:** Tarayıcıda donanım entegrasyonu disabled görünüyor mu?

**Komut:** `flutter run -d chrome`

**Adımlar:**
1. Settings → Cihazlar & Entegrasyonlar → **Etiket Yazıcı** satırı
2. Görsel: **dim opacity (~0.55)** + sağda küçük "Masaüstü" badge (desktop_windows ikonu + tooltip)
3. Switch yok (chevron_right de göstermesin — `hasMasterSwitch: false`)
4. Tıkla → Toast: "Etiket Yazıcı yalnız masaüstü uygulamasında kullanılır."

**Beklenen sonuç:** Tarayıcıda donanım entegrasyonu pasif görünüyor; kullanıcı yanlış yola sapmaz.

---

## Senaryo 5: Aynı USB Cihaz İki Slot (Tek Yazıcı KOBİ)

**Amaç:** Tek termal yazıcı hem fiş hem etiket olarak kullanılabilir mi?

**Setup:**
1. Settings → Cihazlar & Entegrasyonlar → **USB Termal Yazıcı** (fiş) → Tara → Zjiang seç
2. Geri → **Etiket Yazıcı** → Tara → Aynı Zjiang'ı seç
3. POS satışı tamamla → Fiş Yazdır → fiş çıkar
4. Bir ürün aç → Barkod Yaz → etiket çıkar

**Beklenen sonuç:**
- Her iki akış aynı yazıcıyı kullanır
- Fiş tam genişlikte (80mm), etiket küçük (50×30mm) — paper width farkı
- İki kayıt bağımsız, biri silinince diğeri etkilenmez

**Doğrulama:** Synthesis K6 (aynı USB cihaz iki slot) doğrulandı; KOBİ senaryosu desteklenir.

---

## Senaryo 6: Etiket Boyutu Persistence

**Amaç:** SharedPreferences değerleri restart sonrası korunuyor mu?

**Adımlar:**
1. Etiket Yazıcı ayarlarına git → Boyut **40×25mm** olarak değiştir → Kaydet
2. Default barkod tipi → **QR Code** seç
3. "Her etiketten sonra otomatik kes" → kapat
4. **Uygulamayı kapat**
5. **Yeniden aç** → Settings → Etiket Yazıcı

**Beklenen sonuç:**
- Boyut: 40×25mm
- Code Type: QR Code
- Auto-cut: kapalı
- Yazıcı seçimi (VID/PID) korunmuş

**Doğrulama:** `LabelPrintSettingsNotifier._persist()` ve `load()` çift yönlü çalışıyor.

---

## Hata Durumu Senaryoları

| Belirti | Olası Sebep | Çözüm |
|---|---|---|
| "USB cihaz bulunamadı" | Yazıcı kapalı, kablo gevşek, driver yok | Aygıt Yöneticisi kontrolü |
| Test etiketi çıktı ama Türkçe karakter bozuk | Codepage CP857 değil — `_ascii()` zaten ASCII'ye çeviriyor | Beklenen davranış (yazıcı codepage destekleyene kadar) |
| Barkod basıldı ama metin altında değil | `BarcodeText.below` ESC/POS komutu yazıcı tarafından desteklenmiyor | Yazıcı dökümantasyonuna bak; alternatif `Generator.text()` ile elle yaz |
| 3 etiket istenince 1 etiket basıldı, sonra durdu | Cihaz buffer dolu / disconnect | USB hub değiştir, doğrudan PC'ye bağla |
| Uygulama crash | Catch dışı exception | AppLogger.error console kayıtlarına bak — bug raporla |

---

## Smoke Test Checklist (Hızlı Kontrol)

- [ ] **S1** Yapılandırılmamış → PDF dialog açılır (Case 3, geriye uyum)
- [ ] **S2** Yapılandırılmış + USB → 3 etiket termal yazıcıdan direkt çıkar (Case 1)
- [ ] **S3** USB kopuk → uyarı toast + PDF dialog fallback (Case 2)
- [ ] **S4** Web → "Masaüstü" badge + tıklama bloke
- [ ] **S5** Tek yazıcı 2 slot → ikisi de çalışır
- [ ] **S6** Restart → SharedPreferences korunmuş
- [ ] Test etiketi içerik kontrolü (barkod okunur mu — telefon kamera ile barcode reader app)
- [ ] Hız ölçümü: Case 1'de 5 etiket < 4 saniye

## Sources

- [`product_detail_screen.dart:1069-1240`](project_pos/lib/features/inventory/screens/product_detail_screen.dart#L1069-L1240) — `_printBarcodeLabels` 3-state akış
- [`label_print_service.dart`](project_pos/lib/services/print/label_print_service.dart) — `LabelPrintService` + `EscPosLabelDriver` enjeksiyonu
- [`label_template.dart`](project_pos/lib/services/print/label_template.dart) — `EscPosLabelDriver` impl
- [`label_printer_settings_screen.dart`](project_pos/lib/features/settings/screens/label_printer_settings_screen.dart) — UI
- [[syntheses/label-printer-architecture]] — mimari karar referansı
- [[syntheses/integrations-hub-architecture]] — hub L1→L3 paterni

## Related

- [[sources/code-refs/2026-05-01-label-printer-implementation-audit]]
- [[log]]
