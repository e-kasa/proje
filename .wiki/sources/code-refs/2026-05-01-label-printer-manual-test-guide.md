---
title: Etiket Yazıcı Manuel Test Rehberi (Sprint 24 + Sprint 29-fix-6/7 güncellemesi)
tags: [test-guide, label-printer, manual-test, sprint-24, sprint-29, escpos, posa, zjiang]
source: project_pos/lib/services/print/, lib/features/inventory/screens/product_detail_screen.dart
date: 2026-05-06
status: verified
related-sprint: 24
revisions:
  - 2026-05-01 — Sprint 24 ilk yayım (Case 3 PDF dialog fallback dahil)
  - 2026-05-06 — Sprint 29-fix-6 (PDF kaldırıldı) + fix-7 (KDV fiş) sonrası rehber güncel akışa hizalandı
---

# Etiket Yazıcı Manuel Test Rehberi

Sprint 24 implementasyonu + Sprint 29 düzeltmeleri sonrası **kullanıcı tarafından runtime'da yapılacak** smoke test akışı. Audit: [[sources/code-refs/2026-05-01-label-printer-implementation-audit]] · Synthesis: [[syntheses/label-printer-architecture]].

> ⚠️ **Sprint 29-fix-6 sonrası kritik değişiklik**: PDF print path **tamamen kaldırıldı**. Hiçbir senaryoda Windows print dialog / "FeedMe POS Print Job" / "Microsoft Print to PDF" açılmaz. Yapılandırma yoksa açık hata toast + ayar ekranına yönlendirme.

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

## Senaryo 1: Hiç USB Yazıcı Yapılandırılmamış (Açık Hata Yolu)

**Amaç:** Etiket yazıcı + fiş yazıcı kayıtlı değilken kullanıcı net bir yönlendirme alıyor mu?

**Adımlar:**
1. Settings → Cihazlar & Entegrasyonlar → **Etiket Yazıcı** satırı: turuncu "Yapılandırılmadı" badge
2. Settings → **Fiş Yazıcı** satırı: turuncu "Yapılandırılmadı" badge (Sprint 22)
3. Geri → ürün listesine git
4. Bir ürün aç → **Barkod Yaz** → modal aç → adet 1 → **Yazdır**

**Beklenen sonuç (Sprint 29-fix-6 sonrası):**
- Modal kapanır
- ⚠️ Toast (kırmızı/error): **"USB yazıcı yapılandırılmamış. Ayarlar → Cihazlar & Entegrasyonlar → Etiket Yazıcı veya Fiş Yazıcı menüsünden cihaz seçin."**
- ❌ Windows print dialog **AÇILMAZ**
- ❌ "FeedMe POS Print Job" / "Microsoft Print to PDF" kayıtlı PDF dosyası **OLUŞMAZ**
- ❌ Belgeler klasöründe yeni `.pdf` dosyası bulunmaz

**Doğrulama:** Sprint 29-fix-6 PDF kaldırma + fix-4 kIsWeb gating birlikte çalışıyor.

> ⚠️ **Sprint 24'teki eski davranış**: Bu senaryo eski rehberde "Windows print dialog açılır" idi. Sprint 29-fix-2/3/4/5/6 boyunca PDF path kademeli olarak kaldırıldı (5 iter, kullanıcı 17 deneme dahil). Artık dialog yerine açık hata gösterilir.

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

## Senaryo 3: Yapılandırılmış + USB Bağlantı Hatası (Case 2 — Açık Hata)

**Amaç:** Cihaz erişilemiyor olduğunda kullanıcı gerçek hatayı görüyor mu?

**Setup:**
1. Senaryo 2'de yazıcı yapılandırıldı (status yeşil)
2. **Zjiang/POSA yazıcısının USB kablosunu çıkar** (veya cihaz gücünü kapat)
3. Bir ürün aç → **Barkod Yaz** → adet 1 → **Yazdır**

**Beklenen sonuç (Sprint 29-fix-6 sonrası):**
- ⚠️ Toast (error): **"Etiket yazıcısına bağlanılamadı. USB bağlantı + driver kontrol edin (Ayarlar → Cihazlar → Etiket Yazıcı)."**
- ❌ Windows print dialog **AÇILMAZ** (eski PDF fallback davranışı silindi)
- ❌ Sistem yazıcısı seçim penceresi **AÇILMAZ**
- Uygulama crash etmez
- Logger console'da: `LabelPrintService` connect/send hatası veya `LabelPrintResult.failure(...)` kaydı

**Doğrulama:** Hata kaynağı görünür kalır; sessiz PDF fallback yok. Kullanıcı USB/driver sorununa odaklanabilir.

---

## Senaryo 4: Web Platform Guard

**Amaç:** Tarayıcıda donanım entegrasyonu disabled görünüyor mu + barkod basma denemesi açık hata veriyor mu?

**Komut:** `flutter run -d chrome`

**Adımlar:**
1. Settings → Cihazlar & Entegrasyonlar → **Etiket Yazıcı** satırı
2. Görsel: **dim opacity (~0.55)** + sağda küçük "Masaüstü" badge (desktop_windows ikonu + tooltip)
3. Switch yok (chevron_right de göstermesin — `hasMasterSwitch: false`)
4. Tıkla → Toast: "Etiket Yazıcı yalnız masaüstü uygulamasında kullanılır."
5. Bir ürün aç → **Barkod Yaz** → adet 1 → **Yazdır**

**Beklenen sonuç (Sprint 29-fix-6 sonrası):**
- ⚠️ Toast (error): **"Etiket basma için masaüstü uygulamasını + USB yazıcı kullanın. Web tarayıcıda yazıcı erişimi yoktur."**
- ❌ Tarayıcı PDF preview / "save as" dialog **AÇILMAZ**
- ❌ Yeni sekmede `printing` paketinin tarayıcı PDF görüntüleyicisi **AÇILMAZ** (eski Sprint 24 davranışı silindi)

**Doğrulama:** Web'de donanım entegrasyonu pasif + barkod akışı açık hata veriyor. Sprint 24'te web fallback PDF dialog vardı → fix-6'da kaldırıldı.

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

## Senaryo 7: Yalnız Fiş Yazıcısı (POSA) — Etiket Reuse (Case 1.5)

**Amaç:** Etiket yazıcı yapılandırılmamış ama POSA fiş yazıcısı kayıtlı → POSA'dan etiket basma çalışıyor mu? (Sprint 29-fix-2/3 davranışı)

**Setup:**
1. Settings → Cihazlar & Entegrasyonlar → **Etiket Yazıcı** kaydı **YOK** (turuncu badge)
2. Settings → **Fiş Yazıcı** (Sprint 22) kaydı **VAR** (yeşil badge — POSA-80 Series gibi)
3. Bir ürün aç → **Barkod Yaz** → adet 2, tip Code128 → **Yazdır**

**Beklenen sonuç:**
- ✅ POSA'dan **2 ayrı barkod etiketi** çıkar (kağıt 80mm, label 25mm yükseklik fallback)
- ℹ️ Toast (info): **"Etiket fiş yazıcısı (POSA-80 Series) ile basıldı. Özel etiket yazıcı için: Ayarlar → Cihazlar → Etiket Yazıcı."**
- ❌ Windows print dialog **AÇILMAZ**
- ❌ "FeedMe POS Print Job" sanal yazıcı **AÇILMAZ**

**Doğrulama:** Sprint 29-fix-2 Case 1.5 reuse + fix-3 result type + fix-6 PDF kaldırma birlikte çalışıyor. KOBİ tek-yazıcı senaryosu desteklenir (ayrı etiket yazıcı satın almak zorunlu değil).

**Hata varyantı:** POSA bağlı değilse → **"Fiş yazıcısı (POSA-80 Series) ile etiket basılamadı: <error>. USB bağlantı + WinUSB driver kontrol edin."** error toast (Senaryo 1'deki gibi PDF dialog'a düşmez).

---

## Senaryo 8: Fiş KDV Oranı Görüntüsü (Sprint 29-fix-7)

**Amaç:** POS satışı sonrası basılan fişte her satırda `*<oran>` göstergesi + footer'da "KDV TABLOSU" matris çıkıyor mu? (Türkiye Maliye fiş standardı)

> Bu senaryo etiket yazıcı değil **fiş yazıcı (Sprint 22) testidir**, fakat aynı `LabelPrintService`/`PrintService` ESC/POS pipeline'ında çalıştığı için bu rehbere ekli — Sprint 29-fix-7 ile birlikte gelen davranıştır.

**Setup:**
1. POSA fiş yazıcısı kayıtlı (Senaryo 2 setup'ı gibi ama `Fiş Yazıcı` slotunda)
2. POS ekranında 2 farklı KDV oranlı ürün ekle:
   - "Fren Balata" — KDV %20, KDV-dahil ₺377.60
   - "Su" — KDV %1, KDV-dahil ₺25.50 (varsa; yoksa tek %20 ile devam)
3. Satışı tamamla → "Fiş Yazdır" tıkla

**Beklenen fiş içeriği:**

```
SEDCORE POS
Fis No: POS-...
Tarih: 06.05.2026 ...
--------------------
Fren Balata
  1 x TL 320.00     TL 377.60 *20      ← *20 KDV göstergesi
Su
  1 x TL 25.25      TL 25.50  *1       ← *1 KDV göstergesi
--------------------
Ara Toplam:        TL 345.25
KDV %20:            TL 57.60
KDV %1:              TL 0.25
====================
TOPLAM             TL 403.10
====================
Odeme: Nakit

KDV TABLOSU                          ← yeni section
--------------------
Oran  Matrah     KDV
%20   TL 320.00  TL 57.60
%1    TL  25.25  TL  0.25
--------------------

[QR kod]
#<saleId>
```

**Doğrulama kriterleri:**
- ✅ Her satırda sağda `*<oran>` (örn. `*20`, `*1`, `*8`)
- ✅ Totals bölümünde her oran için ayrı `KDV %<oran>:` satırı
- ✅ Footer'da "KDV TABLOSU" başlığı + "Oran / Matrah / KDV" 3 sütunlu matris
- ✅ Birden fazla oran varsa her oran için 1 satır
- ✅ Backward compat: cart item'larında `taxRate` yoksa eski tek `KDV: TL X` korunur (regression yok)

**Doğrulama:** [`receipt_template.dart`](project_pos/lib/services/print/receipt_template.dart) Sprint 29-fix-7 davranışı runtime'da görünür.

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
| "USB yazıcı yapılandırılmamış" toast (Senaryo 1) | Hiç USB cihaz kayıtlı değil | Settings → Cihazlar → Etiket Yazıcı VEYA Fiş Yazıcı → Tara → Cihaz seç |
| "Etiket yazıcısına bağlanılamadı" toast (Senaryo 3) | Yazıcı kapalı, kablo gevşek, driver yok | Aygıt Yöneticisi kontrolü; yazıcıyı aç + USB'yi yeniden tak |
| "Microsoft Print to PDF" listede tek görünür (Sprint 29-fix-5) | POSA Windows'a yazıcı olarak yüklenmemiş | Windows Ayarlar → Bluetooth ve cihazlar → Yazıcılar ve tarayıcılar → Cihaz ekle → Generic / Text Only sürücüsü |
| Önceki sanal yazıcı seçimi (PDF/OneNote/Fax) bağlı görünür | Sprint 29-fix-5 öncesi seçilmiş kayıt | Otomatik temizlenir (initState `clearDevice`); ardından tekrar tara |
| Test etiketi çıktı ama Türkçe karakter bozuk | Codepage CP857 değil — `_ascii()` zaten ASCII'ye çeviriyor | Beklenen davranış (yazıcı codepage destekleyene kadar) |
| Barkod basıldı ama metin altında değil | `BarcodeText.below` ESC/POS komutu yazıcı tarafından desteklenmiyor | Yazıcı dökümantasyonuna bak; alternatif `Generator.text()` ile elle yaz |
| 3 etiket istenince 1 etiket basıldı, sonra durdu | Cihaz buffer dolu / disconnect | USB hub değiştir, doğrudan PC'ye bağla |
| Fişte `*20` KDV göstergesi yok (Senaryo 8) | Cart item'da `taxRate` field'ı yok → backward compat eski tek `KDV:` satırı | Ürün KDV oranı ürün ekleme/düzenleme ekranında set edildi mi kontrol et |
| Uygulama crash | Catch dışı exception | AppLogger.error console kayıtlarına bak — bug raporla |
| Belgeler klasöründe "FeedMe POS Print Job (X).pdf" oluşur | **OLMAMALI** (Sprint 29-fix-6 sonrası) — eski PDF path bulgusu | `flutter clean && flutter pub get && flutter run -d windows` ile temiz build al; eski PDF'leri manuel sil |

---

## Smoke Test Checklist (Hızlı Kontrol — Sprint 29-fix-6/7 sonrası)

- [ ] **S1** Hiç USB yazıcı yok → **error toast** ("USB yazıcı yapılandırılmamış...") + PDF dialog AÇILMAZ
- [ ] **S2** Etiket yazıcı kayıtlı + USB → 3 etiket termal yazıcıdan direkt çıkar (Case 1)
- [ ] **S3** USB kopuk → "Etiket yazıcısına bağlanılamadı..." error toast (Case 2, PDF fallback yok)
- [ ] **S4** Web → "Masaüstü" badge + tıklama bloke + barkod basma error toast
- [ ] **S5** Tek yazıcı 2 slot → ikisi de çalışır
- [ ] **S6** Restart → SharedPreferences korunmuş
- [ ] **S7** Sadece fiş yazıcısı (POSA) kayıtlı → Case 1.5 reuse + info toast ("fiş yazıcısı ile basıldı")
- [ ] **S8** POS satışı → fişte `*20` KDV göstergesi + footer "KDV TABLOSU" matris (Sprint 29-fix-7)
- [ ] Test etiketi içerik kontrolü (barkod okunur mu — telefon kamera ile barcode reader app)
- [ ] Hız ölçümü: Case 1'de 5 etiket < 4 saniye
- [ ] **Negatif kontrol**: Belgeler klasöründe yeni `.pdf` dosyası **OLUŞMAZ** (Sprint 29-fix-6 regresyon kontrolü)
- [ ] **Negatif kontrol**: Sanal yazıcı (Microsoft Print to PDF, OneNote, FeedMe POS Print Job) USB tarama listesinde **GÖRÜNMEZ** (Sprint 29-fix-5)

## Sources

- [`product_detail_screen.dart:1080-1182`](project_pos/lib/features/inventory/screens/product_detail_screen.dart#L1080-L1182) — `_printBarcodeLabels` (Case 1 → Case 1.5 → error toast, PDF kaldırıldı)
- [`product_detail_screen.dart:1230-1274`](project_pos/lib/features/inventory/screens/product_detail_screen.dart#L1230-L1274) — `_printViaReceiptPrinterFallback` (Sprint 29-fix-3 result type)
- [`label_print_service.dart`](project_pos/lib/services/print/label_print_service.dart) — `LabelPrintService` + `EscPosLabelDriver` enjeksiyonu + `isVirtualPrinterName` reuse
- [`label_template.dart`](project_pos/lib/services/print/label_template.dart) — `EscPosLabelDriver` impl
- [`label_printer_settings_screen.dart`](project_pos/lib/features/settings/screens/label_printer_settings_screen.dart) — UI
- [`print_service.dart`](project_pos/lib/services/print/print_service.dart) — `_virtualPrinterPatterns` blacklist (Sprint 29-fix-5)
- [`receipt_template.dart`](project_pos/lib/services/print/receipt_template.dart) — KDV bucket aggregator + KDV TABLOSU footer (Sprint 29-fix-7)
- [`printer_settings_screen.dart`](project_pos/lib/features/settings/screens/printer_settings_screen.dart) — auto-clear sanal yazıcı + Windows kurulum banner (Sprint 29-fix-5)
- [[syntheses/label-printer-architecture]] — mimari karar referansı
- [[syntheses/integrations-hub-architecture]] — hub L1→L3 paterni

## Related

- [[sources/code-refs/2026-05-01-label-printer-implementation-audit]]
- [[log]] (özellikle Sprint 29-fix-2/3/4/5/6/7 girdileri — bu rehber 2026-05-06 revizyonu fix-6 + fix-7 sonrası gerçek davranışa hizalandı)
