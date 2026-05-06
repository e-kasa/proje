import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'print_settings.dart';
import 'receipt_template.dart';

/// Sprint 22 — POS Receipt yazıcı servis abstraction.
///
/// USB transport (POSA termal yazıcı, Windows desktop).
/// `PrintSettings` ile çalışır; kayıtlı vendor/product ID üzerinden cihaza
/// bağlanır, `ReceiptTemplate` ile üretilen ESC/POS bytes'ı raw olarak gönderir.
///
/// Riverpod provider: `printServiceProvider`.
class PrintService {
  final PrintSettings _settings;
  final PrinterManager _manager = PrinterManager.instance;

  PrintService(this._settings);

  /// Sprint 29-fix-5 — Sanal yazıcı isim pattern'ları.
  ///
  /// `flutter_pos_printer_platform_image_3` Windows'ta `EnumPrintersW`
  /// kullanır → tüm kayıtlı sistem yazıcılarını döndürür (sanal dahil).
  /// Bu pattern'lar listelenmemeli; çünkü kullanıcı POSA gibi termal
  /// cihaz arıyor, sanal PDF/OneNote/Fax değil.
  static const _virtualPrinterPatterns = [
    'microsoft print to pdf',
    'microsoft xps document writer',
    'print to pdf',
    'save as pdf',
    'fax',
    'onenote',
    'send to onenote',
    'feedme',     // FeedMe POS Print Job sanal yazıcısı
    'print job',  // generic "POS Print Job" sanal yazıcılar
    'to pdf',     // Foxit PDF, vs.
    'pdf creator',
    'cutepdf',
    'doPDF',
  ];

  /// `LabelPrintService` aynı blacklist'i reuse eder.
  static bool isVirtualPrinterName(String name) {
    final lower = name.toLowerCase().trim();
    return _virtualPrinterPatterns.any((p) => lower.contains(p));
  }

  /// Bağlı USB cihazları tara. UI'da seçim için kullanılır.
  ///
  /// Sprint 29-fix-5: Sanal yazıcılar (Microsoft Print to PDF, OneNote,
  /// Fax, FeedMe POS Print Job, vb.) filtre dışı tutulur.
  ///
  /// Returns: vendor/product ID + cihaz adı listesi.
  Future<List<UsbDeviceInfo>> discoverDevices() async {
    final devices = await _manager.discovery(type: PrinterType.usb).toList();
    return devices
        .where((d) => !isVirtualPrinterName(d.name))
        .map((d) => UsbDeviceInfo(
              name: d.name,
              vendorId: int.tryParse(d.vendorId ?? '') ?? 0,
              productId: int.tryParse(d.productId ?? '') ?? 0,
            ))
        .toList();
  }

  /// Satış fişi yazdır.
  Future<PrintResult> printSaleReceipt(Map<String, dynamic> sale) async {
    if (!_settings.isConfigured) {
      return PrintResult.failure('Yazici yapilandirilmamis. Ayarlardan secin.');
    }
    final bytes = await ReceiptTemplate(_settings).buildSaleReceipt(sale);
    return _send(bytes);
  }

  /// Test sayfası yazdır.
  Future<PrintResult> printTestPage() async {
    if (!_settings.isConfigured) {
      return PrintResult.failure('Yazici yapilandirilmamis.');
    }
    final bytes = await ReceiptTemplate(_settings).buildTestPage();
    return _send(bytes);
  }

  Future<PrintResult> _send(List<int> bytes) async {
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
        return PrintResult.failure(
          'Yaziciya baglanilamadi (VID=${_settings.vendorId}, PID=${_settings.productId}).',
        );
      }
      final ok = await _manager.send(type: PrinterType.usb, bytes: bytes);
      await _manager.disconnect(type: PrinterType.usb);
      return ok
          ? PrintResult.success()
          : PrintResult.failure('Yazici komutu reddedildi.');
    } catch (e) {
      return PrintResult.failure('Yazdirma hatasi: $e');
    }
  }
}

class UsbDeviceInfo {
  final String name;
  final int vendorId;
  final int productId;

  UsbDeviceInfo({
    required this.name,
    required this.vendorId,
    required this.productId,
  });

  String get displayName =>
      name.isNotEmpty ? name : 'USB-$vendorId:$productId';
}

class PrintResult {
  final bool success;
  final String? error;

  PrintResult._(this.success, this.error);

  factory PrintResult.success() => PrintResult._(true, null);
  factory PrintResult.failure(String error) => PrintResult._(false, error);
}

final printServiceProvider = Provider<PrintService>((ref) {
  final settings = ref.watch(printSettingsProvider);
  return PrintService(settings);
});
