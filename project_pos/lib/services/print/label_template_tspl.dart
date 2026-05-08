import 'package:intl/intl.dart';

import 'label_driver.dart';
import 'label_print_settings.dart';

/// Sprint 30 — TSPL (TSC Printer Language) [LabelDriver] implementasyonu.
///
/// Zjiang LABEL-9X10, Argox CP serisi, TSC TX/TE serisi gibi etiket
/// yazıcılarının yaygın protokolü. `EscPosLabelDriver` paralel paterni —
/// aynı interface, farklı bytes builder.
///
/// 4-protokol probe testinde (2026-05-06) kullanıcı cihazı (VID:0416 PID:5011
/// LABEL-9X10) **TSPL ile fiziksel çıktı verdi**, ESC/POS bytes'ı sessizce
/// reddetti. Bu driver o cihaz aileleri için.
///
/// TSPL referansı: https://www.tscprinters.com/EN/PrintLanguage/TSPL
///
/// Ana komutlar:
/// - `SIZE w mm,h mm`     — etiket boyutu
/// - `GAP n mm,m`         — etiketler arası boşluk
/// - `CLS`                — image buffer temizle
/// - `TEXT x,y,"font",rotate,xMul,yMul,"text"`
/// - `BARCODE x,y,"type",h,humanRead,rotate,nW,nH,"data"`
/// - `QRCODE x,y,ECC,cellWidth,mode,rotate,"data"`
/// - `PRINT m,n`          — m kopya, n etiket
class TsplLabelDriver extends LabelDriver {
  const TsplLabelDriver();

  @override
  String get protocolKey => 'tspl';

  @override
  String get displayName => 'TSPL (Zjiang LABEL / Argox / TSC)';

  @override
  Future<List<int>> buildBarcodeLabel({
    required LabelPrinterSettings settings,
    required String value,
    String? productName,
    String? sku,
    double? price,
    LabelCodeType? codeType,
  }) async {
    final money = NumberFormat.currency(locale: 'tr_TR', symbol: 'TL ');
    final type = codeType ?? settings.defaultCodeType;
    final w = settings.labelWidthMm;
    final h = settings.labelHeightMm;

    final buf = StringBuffer();
    // Header
    buf.writeln('SIZE $w mm,$h mm');
    buf.writeln('GAP 2 mm,0');
    buf.writeln('DIRECTION 1');
    buf.writeln('REFERENCE 0,0');
    buf.writeln('DENSITY 8');
    buf.writeln('SPEED 4');
    buf.writeln('CLS');

    // ── ÜRÜN ADI (üst) ────────────────────────────────────────────────────
    int y = 10;
    if (settings.showProductName &&
        productName != null &&
        productName.isNotEmpty) {
      // font "3" = 24x24 dot Roman
      final t = _escape(_ascii(productName));
      buf.writeln('TEXT 10,$y,"3",0,1,1,"$t"');
      y += 30;
    }

    // ── BARKOD / QR ───────────────────────────────────────────────────────
    final barcodeY = y;
    switch (type) {
      case LabelCodeType.qr:
        // QRCODE x,y,ECC(L/M/Q/H),cellWidth,mode(A/M),rotate,"data"
        buf.writeln('QRCODE 10,$barcodeY,M,5,A,0,"${_escape(value)}"');
        y += 60;
        break;
      case LabelCodeType.ean13:
        if (RegExp(r'^\d{12,13}$').hasMatch(value)) {
          // BARCODE x,y,"EAN13",h,humanReadable(0/1/2),rotate,nW,nH,"data"
          buf.writeln('BARCODE 10,$barcodeY,"EAN13",60,1,0,2,2,"$value"');
        } else {
          buf.writeln('BARCODE 10,$barcodeY,"128",60,1,0,2,2,"${_escape(value)}"');
        }
        y += 80;
        break;
      case LabelCodeType.code128:
        buf.writeln('BARCODE 10,$barcodeY,"128",60,1,0,2,2,"${_escape(value)}"');
        y += 80;
        break;
    }

    // ── SKU + FİYAT (alt) ─────────────────────────────────────────────────
    if (settings.showSku && sku != null && sku.isNotEmpty) {
      buf.writeln('TEXT 10,$y,"2",0,1,1,"SKU: ${_escape(_ascii(sku))}"');
      y += 24;
    }
    if (settings.showPrice && price != null) {
      buf.writeln('TEXT 10,$y,"3",0,1,1,"${_escape(money.format(price))}"');
    }

    // Print 1 copy
    buf.writeln('PRINT 1,1');

    // TSPL bytes — ASCII (Türkçe karakterler `_ascii()` ile dönüştürülmüş zaten)
    return buf.toString().codeUnits;
  }

  @override
  Future<List<int>> buildTestLabel(LabelPrinterSettings settings) async {
    return buildBarcodeLabel(
      settings: settings,
      value: 'TEST-12345',
      productName: 'Test Etiketi',
      sku: 'TEST-SKU',
      price: 99.99,
      codeType: LabelCodeType.code128,
    );
  }

  /// TSPL string literal'larında çift tırnak escape edilmeli.
  String _escape(String input) => input.replaceAll('"', r'\"');

  /// Türkçe → ASCII (TSPL Latin codepage olabilir ama güvenli yol).
  String _ascii(String input) {
    return input
        .replaceAll('Ç', 'C').replaceAll('ç', 'c')
        .replaceAll('Ğ', 'G').replaceAll('ğ', 'g')
        .replaceAll('İ', 'I').replaceAll('ı', 'i')
        .replaceAll('Ö', 'O').replaceAll('ö', 'o')
        .replaceAll('Ş', 'S').replaceAll('ş', 's')
        .replaceAll('Ü', 'U').replaceAll('ü', 'u');
  }
}
