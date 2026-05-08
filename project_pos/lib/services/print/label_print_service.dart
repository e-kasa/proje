import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import 'hidden_printers.dart';
import 'label_driver.dart';
import 'label_print_settings.dart';
import 'label_template.dart';
import 'label_template_tspl.dart';
import 'print_service.dart' show UsbDeviceInfo, PrintService;

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
  final HiddenPrinters? _hidden;
  final PrinterManager _manager = PrinterManager.instance;

  /// Sprint 30 — self-healing connect callback. Detay: `PrintService`.
  final Future<void> Function(String newName)? _onDeviceNameRefresh;

  /// Sprint 30 — Driver `settings.protocol`'a göre otomatik seçilir; explicit
  /// `driver` parametresi test enjekte için tutulur. Sprint 24'te default
  /// ESC/POS idi; Sprint 30'da TSPL eklendi (Zjiang LABEL-9X10 vb.).
  LabelPrintService(
    this._settings, {
    LabelDriver? driver,
    HiddenPrinters? hidden,
    Future<void> Function(String newName)? onDeviceNameRefresh,
  })  : _driver = driver ?? _driverFor(_settings.protocol),
        _hidden = hidden,
        _onDeviceNameRefresh = onDeviceNameRefresh;

  /// Settings'in protokol enum'una göre uygun driver instance döndür.
  /// Yeni protokol eklendiğinde burası genişler.
  static LabelDriver _driverFor(LabelProtocol protocol) {
    switch (protocol) {
      case LabelProtocol.tspl:
        return const TsplLabelDriver();
      case LabelProtocol.escPos:
        return const EscPosLabelDriver();
    }
  }

  /// Bağlı USB cihazları tara — UI'da etiket yazıcı seçimi için.
  ///
  /// Sprint 29-fix-5: Sanal yazıcılar (PDF/OneNote/Fax) sabit blacklist ile
  /// filtre dışı — `PrintService._virtualPrinterPatterns` reuse.
  /// Sprint 30: Kullanıcı gizleme listesi (`hiddenPrintersProvider`) ortak
  /// fiş+etiket akışı için filtreye dahildir.
  Future<List<UsbDeviceInfo>> discoverDevices() async {
    final devices = await _manager.discovery(type: PrinterType.usb).toList();
    return devices
        .where((d) => !PrintService.isVirtualPrinterName(d.name))
        .where((d) => _hidden == null || !_hidden.isHidden(d.name))
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
      // Sprint 30 — Proactive warmup (PrintService paterni paralel):
      // Her _send başında discovery yap → PrinterManager singleton internal
      // state'i hazırlanır + güncel deviceName alınır. App boot sonrası ilk
      // basma denemesi güvenilir çalışır. Maliyet 50-200ms, kazanç güvenilirlik.
      final liveName = await _rediscoverDeviceName();
      AppLogger.info(
        'LabelPrintService warmup: saved="${_settings.deviceName}" live="$liveName"',
        tag: 'LabelPrintService',
      );

      final saved = _settings.deviceName ?? '';
      final candidates = <String>[
        if (liveName != null) liveName,
        if (saved.isNotEmpty) saved,
      ];

      String? successName;
      for (final name in candidates) {
        final ok = await _tryConnect(name);
        if (ok) {
          successName = name;
          break;
        }
      }

      if (successName == null) {
        return LabelPrintResult.failure(
          'Etiket yazıcısına bağlanılamadı (VID=${_settings.vendorId}, '
          'PID=${_settings.productId}). Yazıcı takılı ve açık mı kontrol edin. '
          'Kayıt korunuyor.',
        );
      }

      if (successName != _settings.deviceName) {
        await _onDeviceNameRefresh?.call(successName);
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

  Future<bool> _tryConnect(String name) async {
    try {
      final ok = await _manager.connect(
        type: PrinterType.usb,
        model: UsbPrinterInput(
          name: name,
          vendorId: _settings.vendorId.toString(),
          productId: _settings.productId.toString(),
        ),
      );
      AppLogger.info(
        'LabelPrintService connect "$name" → $ok',
        tag: 'LabelPrintService',
      );
      return ok;
    } catch (e) {
      AppLogger.warning(
        'LabelPrintService connect "$name" exception',
        tag: 'LabelPrintService',
        error: e,
      );
      return false;
    }
  }

  /// Sprint 30 fix — Generic / Text Only sürücüsü VID=0 PID=0 verir; bu
  /// durumda VID/PID match yanlış cihaza düşebilir. Önce `deviceName`
  /// exact match, sonra (VID/PID > 0 ise) VID/PID fallback.
  Future<String?> _rediscoverDeviceName() async {
    try {
      final devices = await discoverDevices();
      final savedName = (_settings.deviceName ?? '').toLowerCase().trim();
      if (savedName.isNotEmpty) {
        for (final d in devices) {
          if (d.name.toLowerCase().trim() == savedName) {
            return d.name;
          }
        }
      }
      if (_settings.vendorId != 0) {
        for (final d in devices) {
          if (d.vendorId == _settings.vendorId &&
              d.productId == _settings.productId) {
            return d.name;
          }
        }
      }
    } catch (_) {
      // Discovery başarısızsa sessiz geç
    }
    return null;
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
  final hidden = ref.watch(hiddenPrintersProvider);
  final notifier = ref.read(labelPrintSettingsProvider.notifier);
  return LabelPrintService(
    settings,
    hidden: hidden,
    onDeviceNameRefresh: notifier.refreshDeviceName,
  );
});
