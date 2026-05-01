import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'label_driver.dart';
import 'label_print_settings.dart';
import 'label_template.dart';
import 'print_service.dart' show UsbDeviceInfo;

/// Sprint 24 — Etiket yazıcı servis abstraction.
///
/// `PrintService` (Sprint 22 fiş yazıcısı) paterni paralel — tek paket
/// (`flutter_pos_printer_platform_image_3`), aynı `PrinterManager.instance`
/// singleton'ı, ayrı `LabelPrinterSettings` ile çalışır. Race condition yok
/// (Dart async serial).
///
/// Riverpod provider: `labelPrintServiceProvider`.
class LabelPrintService {
  final LabelPrinterSettings _settings;
  final LabelDriver _driver;
  final PrinterManager _manager = PrinterManager.instance;

  /// Default driver: ESC/POS termal (Sprint 24).
  /// Sprint 25+ ZPL talep gelirse `ZplLabelDriver()` enjekte edilir.
  LabelPrintService(this._settings,
      {LabelDriver driver = const EscPosLabelDriver()})
      : _driver = driver;

  /// Bağlı USB cihazları tara — UI'da etiket yazıcı seçimi için.
  Future<List<UsbDeviceInfo>> discoverDevices() async {
    final devices = await _manager.discovery(type: PrinterType.usb).toList();
    return devices
        .map((d) => UsbDeviceInfo(
              name: d.name,
              vendorId: int.tryParse(d.vendorId ?? '') ?? 0,
              productId: int.tryParse(d.productId ?? '') ?? 0,
            ))
        .toList();
  }

  /// Tek bir barkod etiketi yazdır.
  ///
  /// `codeType` null ise `settings.defaultCodeType` kullanılır.
  Future<LabelPrintResult> printBarcodeLabel({
    required String value,
    String? productName,
    String? sku,
    double? price,
    LabelCodeType? codeType,
  }) async {
    if (!_settings.isConfigured) {
      return LabelPrintResult.failure('Etiket yazıcı yapılandırılmamış.');
    }
    final bytes = await _driver.buildBarcodeLabel(
      settings: _settings,
      value: value,
      productName: productName,
      sku: sku,
      price: price,
      codeType: codeType,
    );
    return _send(bytes);
  }

  /// Test etiketi yazdır — yazıcı seçimi sonrası UI'da kullanılır.
  Future<LabelPrintResult> printTestLabel() async {
    if (!_settings.isConfigured) {
      return LabelPrintResult.failure('Etiket yazıcı yapılandırılmamış.');
    }
    final bytes = await _driver.buildTestLabel(_settings);
    return _send(bytes);
  }

  Future<LabelPrintResult> _send(List<int> bytes) async {
    try {
      final connected = await _manager.connect(
        type: PrinterType.usb,
        model: UsbPrinterInput(
          name: _settings.deviceName ?? '',
          vendorId: _settings.vendorId.toString(),
          productId: _settings.productId.toString(),
        ),
      );
      if (!connected) {
        return LabelPrintResult.failure(
          'Etiket yazıcısına bağlanılamadı (VID=${_settings.vendorId}, '
          'PID=${_settings.productId}).',
        );
      }
      final ok = await _manager.send(type: PrinterType.usb, bytes: bytes);
      await _manager.disconnect(type: PrinterType.usb);
      return ok
          ? LabelPrintResult.success()
          : LabelPrintResult.failure('Etiket yazıcı komutu reddedildi.');
    } catch (e) {
      return LabelPrintResult.failure('Etiket yazdırma hatası: $e');
    }
  }
}

class LabelPrintResult {
  final bool success;
  final String? error;

  LabelPrintResult._(this.success, this.error);

  factory LabelPrintResult.success() => LabelPrintResult._(true, null);
  factory LabelPrintResult.failure(String error) =>
      LabelPrintResult._(false, error);
}

final labelPrintServiceProvider = Provider<LabelPrintService>((ref) {
  final settings = ref.watch(labelPrintSettingsProvider);
  return LabelPrintService(settings);
});
