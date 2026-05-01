import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

import 'label_driver.dart';
import 'label_print_settings.dart';

/// Sprint 24 — Barkod etiketi ESC/POS [LabelDriver] implementasyonu.
///
/// `LabelDriver` interface'inin ESC/POS varyantı. `ReceiptTemplate` paterni
/// paralel — aynı paket (`esc_pos_utils_plus`), aynı `_ascii()` Türkçe
/// normalize. Sprint 25+ ZPL adapter `ZplLabelDriver` aynı interface'i
/// implemente eder.
///
/// Kullanım `LabelPrintService` üzerinden:
/// ```dart
/// const driver = EscPosLabelDriver();
/// final bytes = await driver.buildBarcodeLabel(
///   settings: settings,
///   value: '8690000123456',
///   productName: 'Balata Ön Sol',
/// );
/// ```
class EscPosLabelDriver extends LabelDriver {
  const EscPosLabelDriver();

  @override
  String get protocolKey => 'esc_pos';

  @override
  String get displayName => 'ESC/POS Termal';

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
    final profile = await CapabilityProfile.load();
    // Etiket yazıcıları çoğunlukla 58mm kabul eder; geniş etiket için 80mm
    final paperSize =
        settings.labelWidthMm <= 58 ? PaperSize.mm58 : PaperSize.mm80;
    final gen = Generator(paperSize, profile);
    final List<int> bytes = [];
    final type = codeType ?? settings.defaultCodeType;

    // ── ÜRÜN ADI (üst) ────────────────────────────────────────────────────
    if (settings.showProductName &&
        productName != null &&
        productName.isNotEmpty) {
      bytes.addAll(gen.text(
        _ascii(productName),
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ),
      ));
    }

    // ── BARKOD ────────────────────────────────────────────────────────────
    bytes.addAll(_buildBarcodeBytes(gen, value, type));

    // ── SKU (alt) ─────────────────────────────────────────────────────────
    if (settings.showSku && sku != null && sku.isNotEmpty) {
      bytes.addAll(gen.text(
        'SKU: ${_ascii(sku)}',
        styles: const PosStyles(align: PosAlign.center),
      ));
    }

    // ── FİYAT (alt) ───────────────────────────────────────────────────────
    if (settings.showPrice && price != null) {
      bytes.addAll(gen.text(
        money.format(price),
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
        ),
      ));
    }

    bytes.addAll(gen.feed(1));

    // ── KESİM ─────────────────────────────────────────────────────────────
    if (settings.autoCutAfterEach) {
      bytes.addAll(gen.cut());
    } else {
      bytes.addAll(gen.feed(2));
    }

    return bytes;
  }

  /// Test etiketi — yazıcı tanımlı kontrolü için sabit içerik.
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

  /// Code128 / EAN-13 / QR seçimine göre `Generator` API'sini kullanır.
  List<int> _buildBarcodeBytes(
    Generator gen,
    String value,
    LabelCodeType type,
  ) {
    switch (type) {
      case LabelCodeType.qr:
        return gen.qrcode(
          value,
          size: QRSize.size6,
          align: PosAlign.center,
        );
      case LabelCodeType.ean13:
        // EAN-13: 12 digit + checksum (paket otomatik üretir)
        // Geçersiz veri ise Code128'e düş
        if (RegExp(r'^\d{12,13}$').hasMatch(value)) {
          return gen.barcode(
            Barcode.ean13(value.split('').map(int.parse).toList()),
            width: 3,
            height: 80,
            textPos: BarcodeText.below,
          );
        }
        // Fallback Code128
        return gen.barcode(
          Barcode.code128(value.codeUnits),
          width: 3,
          height: 80,
          textPos: BarcodeText.below,
        );
      case LabelCodeType.code128:
        return gen.barcode(
          Barcode.code128(value.codeUnits),
          width: 3,
          height: 80,
          textPos: BarcodeText.below,
        );
    }
  }

  /// Türkçe karakterleri ASCII'ye çevir (POSA çoğunlukla CP857 değil).
  /// `ReceiptTemplate._ascii()` ile aynı mantık — paylaşmak için ileride
  /// `print/utils/ascii_helper.dart`'a çıkarılabilir.
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
