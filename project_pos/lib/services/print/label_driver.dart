import 'label_print_settings.dart';

/// Sprint 24+ — Etiket yazıcı protokol soyutlaması.
///
/// `LabelDriver` farklı etiket yazıcı protokollerini (ESC/POS termal,
/// Zebra ZPL, Brother PT, vb.) tek `LabelPrintService` arkasında değiştirilebilir
/// kılar. `LabelPrintService` driver'ı `LabelPrinterSettings.protocol`'e göre
/// seçer (Sprint 25+ talep gelince).
///
/// Şu anki implementasyon:
/// - [EscPosLabelDriver] ([label_template.dart]) — Sprint 24 default
///
/// Sprint 25+ planı:
/// - `ZplLabelDriver` — Zebra LP/TLP serisi için
/// - `BrotherPtDriver` — Brother PT yapışkan etiket
abstract class LabelDriver {
  const LabelDriver();

  /// Driver'ın bu yazıcı için uygun olup olmadığını test eder.
  /// `LabelPrinterSettings.protocol` ile eşleşen driver seçilir.
  String get protocolKey;

  /// Insan okur etiket (UI'da driver seçim listesi için).
  String get displayName;

  /// Tek bir barkod etiketi için bytes üret.
  Future<List<int>> buildBarcodeLabel({
    required LabelPrinterSettings settings,
    required String value,
    String? productName,
    String? sku,
    double? price,
    LabelCodeType? codeType,
  });

  /// Test etiketi — yazıcı setup doğrulaması için.
  Future<List<int>> buildTestLabel(LabelPrinterSettings settings);
}
