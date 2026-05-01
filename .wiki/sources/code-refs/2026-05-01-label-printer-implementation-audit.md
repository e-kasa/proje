---
title: Etiket Yazıcı L1→L3 Implementation Audit (2026-05-01)
tags: [audit, label-printer, hardware, sprint-24, escpos, integrations]
source: project_pos/lib/features/{settings,inventory,services/print}/
date: 2026-05-01
status: verified
related-sprint: 24
---

# Etiket Yazıcı L1→L3 Implementation Audit

Sprint 23'te catalog-only (L1) bırakılan **Etiket Yazıcı (ZPL)** entegrasyonu, 2026-05-01 kullanıcı talebiyle **L3 (real)** seviyeye çıkarılıyor. Bu audit mevcut iki ayrı yazdırma akışını, ProductDetail entegrasyonunu, ESC/POS barkod komutunu ve risk noktalarını dokümante eder.

## Tetikleyici

Kullanıcı sırasıyla:
1. *"ÜRÜN DETAYI EKRANINDA BARKOD YAZ DEDİĞİMİZDE ÇALIŞACAK MI?"* — geriye uyum ve mevcut durumu sorgulama
2. *"FİŞ BASMA İÇİN FARKLI BARKOT BASMAK İÇİN FARKLI YAZILARI TANIYACAK MI?"* — 2 ayrı yazıcı senaryosu
3. *"SENARYO 3 EKLE"* — ayrı slot + otomatik yönlendirme inşa et

Sprint 19 kuralı: *"Gerçek tüketici talebi olmadan template/feature inşa etme."* Şimdi talep geldi → L1→L3 atlanıyor.

## Mevcut İki Ayrı Yazdırma Akışı

### Akış A: Fiş Yazdırma (Sprint 22) — USB ESC/POS Direkt

```
POS satış sonrası RECEIPT_PREVIEW_DIALOG
  → posProvider.printLastReceipt()
  → printSettingsProvider (vendorId/productId)
  → PrintService.printSaleReceipt(saleData)
  → ReceiptTemplate.buildSaleReceipt() — ESC/POS bytes
  → PrinterManager.send(USB) — direkt cihaza
```

**Karakteristik:**
- Tek `printSettingsProvider` slotu, kullanıcı bir kez seçer
- Hızlı (~100ms), print dialog yok
- Windows desktop only (Sprint 23 hot-fix kIsWeb guard)
- `flutter_pos_printer_platform_image_3` paketi
- Provider: `lib/services/print/print_settings.dart:160-163`
- Service: `lib/services/print/print_service.dart:14-76`

### Akış B: Barkod Yazdırma (Mevcut Eski Kod) — `printing` Paketi PDF

```
ProductDetail "Barkod Yaz" butonu
  → _printBarcodeLabels(ctx, product, variant, ...)
  → Printing.layoutPdf(onLayout: ...)
  → pw.Document() + pw.BarcodeWidget(Code128|QR)
  → Windows print dialog AÇILIR
  → Kullanıcı yazıcı seçer → OS print spooler → driver → cihaz
```

**Karakteristik:**
- **Hiçbir kayıt yok**, her tıklamada print dialog
- PDF render (1-3 sn ilk job)
- Web'de tarayıcı print dialog — paket cross-platform
- Windows printer driver ŞART (generic USB destekleyici yetmez)
- `printing` paketi
- Kod: `lib/features/inventory/screens/product_detail_screen.dart:1069-1161`

### Karşılaştırma Tablosu

| | Akış A (Fiş) | Akış B (Barkod — şu anki) | Akış C (Barkod — Sprint 24 hedef) |
|---|---|---|---|
| Cihaz seçimi | Settings'te kayıtlı | Print dialog her seferinde | Settings'te kayıtlı |
| Hız | ~100ms | ~1-3sn | ~100ms |
| Driver | Generic USB yeter | Windows print spooler driver şart | Generic USB yeter |
| Web | ❌ kIsWeb guard | ✅ tarayıcı dialog | ❌ kIsWeb guard + fallback Akış B |
| Format | Raw ESC/POS bytes | PDF render | Raw ESC/POS bytes |
| Fallback yok mu | Hata toast | — | Akış B'ye düş |

## Sprint 23 Hub Mimarisi — Etiket Yazıcı L1 Durumu

[[syntheses/integrations-hub-architecture]] uyarınca etiket yazıcı şu an **L1 (catalog-only)**:

```dart
// integrations_provider.dart:52-59
IntegrationDef(
  id: 'label_printer',
  name: 'Etiket Yazıcı (ZPL)',
  description: 'Ürün etiketi / barkod etiketi yazıcı',
  icon: Icons.label,
  iconColor: AppColors.info,
  category: IntegrationCategory.hardware,
  requiresDesktop: true,                 // Sprint 23 hot-fix
  // configRoute YOK — "Yakında" toast
),
```

Status case placeholder'ında (`integrations_provider.dart:144-156`):

```dart
case 'scale': case 'label_printer': case 'email': ...
  final masterEnabled = ref.watch(_placeholderMasterProvider(id));
  return IntegrationStatus(
    isEnabled: masterEnabled, isConfigured: false,
    statusText: masterEnabled ? 'Aktif (yapılandırılmadı)' : 'Pasif',
    subtitle: 'Yapılandırma yakında',
  );
```

**L1→L3 promotion için 3-katman extension paterni** (Sprint 23'te öngörülmüş):

1. `IntegrationDef` — `configRoute: '/settings/label-printer'` ekle
2. `integrationStatusProvider` — yeni `case 'label_printer':` real provider watch
3. Yeni ekran + router entry

Hub kodu **dokunulmaz**. Bu paterni Sprint 24 takip edecek.

## ESC/POS Barkod Komut Referansı

Zjiang/POSA termal yazıcılar (ve genel ESC/POS uyumlu termal cihazlar) şu komutları tanır:

| Komut | Bytes | İşlev |
|---|---|---|
| `GS w n` | `0x1D 0x77 n` | Barkod genişliği (n=2..6, default 3) |
| `GS h n` | `0x1D 0x68 n` | Barkod yüksekliği (dot, n=1..255, default 162) |
| `GS H n` | `0x1D 0x48 n` | Barkod altı text pozisyonu (0=yok, 1=üst, 2=alt, 3=ikisi) |
| `GS f n` | `0x1D 0x66 n` | Barkod altı text fontu (0=A, 1=B) |
| `GS k m d1...dn` | `0x1D 0x6B m ...` | Barkod yazdır (m=barcode type) |

**Code128 (m=73):** `GS k 73 n d1 d2 ... dn` — n=length, dataset CODE B karakter aralığı

**QR Code:** Daha karmaşık — `GS ( k` model + `GS ( k` size + `GS ( k` ECC + `GS ( k` data + `GS ( k` print sequence

**`flutter_pos_printer_platform_image_3` üzerinden** — paket yüksek seviye API sunuyor:
```dart
// pseudo-code
final bytes = <int>[];
bytes.addAll([0x1D, 0x77, 3]);            // GS w 3 — width
bytes.addAll([0x1D, 0x68, 80]);            // GS h 80 — height
bytes.addAll([0x1D, 0x48, 2]);             // GS H 2 — text below
bytes.addAll([0x1D, 0x6B, 73, data.length]);  // GS k 73 n
bytes.addAll(data.codeUnits);              // barcode data
bytes.addAll([0x0A, 0x0A, 0x0A]);          // line feed × 3
bytes.addAll([0x1D, 0x56, 0x00]);          // GS V 0 — full cut
```

Sprint 24 `LabelTemplate` bu paterni kullanacak. Test edilecek: Zjiang firmware'i hangi komutları kabul ediyor.

## ProductDetail `_printBarcodeLabels` Mevcut Kod Detayı

[`product_detail_screen.dart:1069-1161`](project_pos/lib/features/inventory/screens/product_detail_screen.dart#L1069-L1161):

```dart
Future<void> _printBarcodeLabels(
  BuildContext ctx,
  Map<String, dynamic> product,
  _VariantPrint variant,
  bool showName,
  bool showPrice,
  bool showSku,
  String labelSize,        // 'S' | 'M' | 'L'
  int quantity,
  String codeType,         // 'Code128' | 'QR'
) async {
  // Etiket boyutu: S=3x1cm, M=5x2cm, L=8x3cm (QR ise kare)
  final lW = ...;
  final lH = ...;

  await Printing.layoutPdf(onLayout: (format) async {
    final doc = pw.Document();
    final pwBarcode = isQr ? pw.Barcode.qrCode() : pw.Barcode.code128();
    for (int i = 0; i < quantity; i++) {
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat(lW, lH, marginAll: 4),
        build: (context) => pw.Center(child: pw.Column(...)),
      ));
    }
    return doc.save();
  });
}
```

**Tetiklendiği yer (line 908-912):**
```dart
onPressed: () => _printBarcodeLabels(
  ctx, product, variantPrint,
  showName, showPrice, showSku,
  labelSize, quantity, codeType,
),
```

Sprint 24 sonrası 3-state akış (mevcut akış case 3'te korunur):

```dart
Future<void> _printBarcodeLabels(...) async {
  final settings = ref.read(labelPrintSettingsProvider);

  // Case 1: USB direkt
  if (!kIsWeb && settings.isConfigured) {
    final service = ref.read(labelPrintServiceProvider);
    for (int i = 0; i < quantity; i++) {
      final result = await service.printBarcodeLabel(
        value: variant.barcodeValue,
        codeType: codeType,
        showName: showName, productName: product['name']?.toString() ?? '',
        showPrice: showPrice, price: variant.price,
        showSku: showSku, sku: variant.sku,
      );
      if (!result.success) {
        // Case 2: USB hata — fallback dialog
        AppToast.warning(context, 'Etiket yazıcısına bağlanılamadı, dialog\'a düşülüyor');
        await _fallbackToPdfDialog(...);
        return;
      }
    }
    AppToast.success(context, '$quantity etiket yazdırıldı');
    return;
  }

  // Case 3: Yapılandırılmamış veya web — mevcut PDF dialog
  await _fallbackToPdfDialog(product, variant, ...);
}
```

## Risk Noktaları

### R1. Termal makara ≠ yapışkanlı etiket
Zjiang termal yazıcı 80mm sürekli kağıt kullanır — yapışkan değil. Kullanıcı barkod basıp ürüne yapıştırma bekliyor olabilir. Audit mesajı: dedicated etiket yazıcı (Zebra/Brother) için sektör 25+ ZPL adapter gerekir; mevcut ESC/POS yolu sadece "kupon-tarzı" etiket için uygun.

### R2. ESC/POS barkod komut uyumluluğu
`GS k 73 ...` (Code128) bazı düşük-cost Çin firmware'lerinde yanlış implement edilmiş olabilir. Mitigasyon: Ekrandaki "Test Etiketi Yazdır" buton önce dene; başarısızsa kullanıcı fallback (`Printing.layoutPdf`) kullanır.

### R3. Aynı USB cihaz hem fiş hem etiket
Tek Zjiang yazıcısı olan kullanıcı ikisinde de aynı VID/PID kayıtlayabilir. Karar: kabul et, uyarı göster. UX: "Bu cihaz fiş yazıcısı olarak da kayıtlı — aynı yazıcıdan iki amaca da basılır." Tek yazıcılı KOBİ için akıllı varsayılan.

### R4. PrinterManager singleton çakışması
`PrinterManager.instance` static singleton. Aynı anda fiş + etiket yazdırma race condition? Dart single-threaded ama async; iki `_send()` çağrısı sıralı olarak çalışır, paket internal queue varsa sorun değil. Manuel test: arka arkaya fiş + barkod bas, çakışma var mı kontrol.

### R5. Sprint 24 i18n cleanup planı çakışması
[[sources/code-refs/2026-05-01-printer-integrations-i18n-audit]] zaten 86 yeni key planlamış. Sprint 24 etiket yazıcı için ek ~25 key (`bnd-lpr-*` prefix) eklenir. İki iş paralel; aynı dosya `data.sql` ama farklı satır blokları → çakışma yok.

## 3-Katman Extension Paterninin Somut Kullanımı

Sprint 23 `integrations-hub-architecture` paterni (W2 synthesis'te öngörülmüş):

| Katman | L1 (Sprint 23) | L3 (Sprint 24 sonrası) |
|---|---|---|
| **Catalog** (`IntegrationDef`) | `configRoute: null`, `icon: Icons.label` | `configRoute: '/settings/label-printer'`, ikon aynı |
| **Status case** | `_placeholderMasterProvider` | `ref.watch(labelPrintSettingsProvider)` real |
| **Screen** | yok | `label_printer_settings_screen.dart` |

Hub ekranı (`integrations_hub_screen.dart`) ZERO değişiklik gerektirir. Paterni doğrulayan ilk somut promotion.

## Sources

- [`product_detail_screen.dart:1069-1161`](project_pos/lib/features/inventory/screens/product_detail_screen.dart#L1069-L1161) — mevcut Akış B
- [`print_settings.dart`](project_pos/lib/services/print/print_settings.dart) — Akış A pattern
- [`print_service.dart`](project_pos/lib/services/print/print_service.dart) — `PrintService:14-76` paterni
- [`receipt_template.dart`](project_pos/lib/services/print/receipt_template.dart) — `_ascii()` helper paylaşılabilir
- [`integrations_provider.dart:52-59,144-156`](project_pos/lib/features/settings/integrations/providers/integrations_provider.dart) — L1 catalog state
- [[syntheses/integrations-hub-architecture]] — 3-katman extension paterni
- [[sources/code-refs/2026-05-01-printer-integrations-i18n-audit]] — Sprint 24 i18n paralel iş

## Related

- [[syntheses/label-printer-architecture]] — bu audit'in W2 synthesis çıktısı
- [[concepts/sector-agnostic]] — etiket yazıcı tüm sektörlerde aynı, sektör-bağımsız
- [[log]] — Sprint 22 (printer foundation) + Sprint 24 (label-printer)
