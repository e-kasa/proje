import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../company/company_info.dart';
import 'hidden_printers.dart';
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
  final CompanyInfo? _company;
  final HiddenPrinters? _hidden;
  final PrinterManager _manager = PrinterManager.instance;

  /// Sprint 30 — self-healing connect callback. Connect başarısızsa
  /// rediscover yapılır, aynı VID/PID match eden cihazın yeni `name`'i
  /// settings'e back-write edilir → bir sonraki açılışta direkt başarılı
  /// connect. null ise back-write devre dışı (test/headless senaryolar).
  final Future<void> Function(String newName)? _onDeviceNameRefresh;

  PrintService(
    this._settings, {
    CompanyInfo? company,
    HiddenPrinters? hidden,
    Future<void> Function(String newName)? onDeviceNameRefresh,
  })  : _company = company,
        _hidden = hidden,
        _onDeviceNameRefresh = onDeviceNameRefresh;

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
  /// Fax, FeedMe POS Print Job, vb.) sabit blacklist ile filtre dışı.
  /// Sprint 30: Kullanıcı tarafından gizlenmiş yazıcılar (`hiddenPrintersProvider`)
  /// da filtre dışı tutulur — eski/dummy printer'ları temizlemek için.
  ///
  /// Returns: vendor/product ID + cihaz adı listesi.
  Future<List<UsbDeviceInfo>> discoverDevices() async {
    final devices = await _manager.discovery(type: PrinterType.usb).toList();
    return devices
        .where((d) => !isVirtualPrinterName(d.name))
        .where((d) => _hidden == null || !_hidden.isHidden(d.name))
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
    final bytes = await ReceiptTemplate(_settings, company: _company)
        .buildSaleReceipt(sale);
    return _send(bytes);
  }

  /// Test sayfası yazdır.
  Future<PrintResult> printTestPage() async {
    if (!_settings.isConfigured) {
      return PrintResult.failure('Yazici yapilandirilmamis.');
    }
    final bytes = await ReceiptTemplate(_settings, company: _company)
        .buildTestPage();
    return _send(bytes);
  }

  Future<PrintResult> _send(List<int> bytes) async {
    try {
      // Sprint 30 — Proactive warmup: app boot sonrası ilk connect'in
      // güvenilir çalışması için her _send başında discovery yap. Paket
      // PrinterManager singleton'ı internal state'i bu sırada hazırlar.
      // Maliyet: 50-200ms ekstra. Kazanç: app yeniden açıldıktan sonra
      // ilk basma denemesinde "yaziciya baglanilamadi" yerine direkt başarı.
      final liveName = await _rediscoverDeviceName();
      AppLogger.info(
        'PrintService warmup: saved="${_settings.deviceName}" live="$liveName"',
        tag: 'PrintService',
      );

      // Önce live name (varsa) ile dene — Windows EnumPrintersW name değişimini
      // yakalar. Yoksa kayıtlı name ile fallback dene.
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
        return PrintResult.failure(
          'Yaziciya baglanilamadi (VID=${_settings.vendorId}, PID=${_settings.productId}). '
          'Yazici takili ve acik mi kontrol edin. Kayit korunuyor.',
        );
      }

      // Live name kayıtlıdan farklıysa SharedPreferences'a back-write
      if (successName != _settings.deviceName) {
        await _onDeviceNameRefresh?.call(successName);
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
        'PrintService connect "$name" → $ok',
        tag: 'PrintService',
      );
      return ok;
    } catch (e) {
      AppLogger.warning(
        'PrintService connect "$name" exception',
        tag: 'PrintService',
        error: e,
      );
      return false;
    }
  }

  /// Discovery yapıp aynı VID/PID match eden cihazın güncel `name`'ini döndür.
  /// Bulamazsa null. Connect failure fallback için kullanılır.
  ///
  /// Sprint 30 fix — Generic / Text Only sürücüsü VID=0 PID=0 verir; bu
  /// durumda VID/PID match birden fazla cihazla eşleşip yanlış cihazı
  /// dönebilir. Bu yüzden önce `deviceName` exact match denenir; sadece
  /// gerçek USB cihazlar (VID/PID > 0) için VID/PID fallback yapılır.
  Future<String?> _rediscoverDeviceName() async {
    try {
      final devices = await discoverDevices();
      // 1. Tercih: aynı isim — Generic Text Only durumunda doğru cihazı bulur
      final savedName =
          (_settings.deviceName ?? '').toLowerCase().trim();
      if (savedName.isNotEmpty) {
        for (final d in devices) {
          if (d.name.toLowerCase().trim() == savedName) {
            return d.name;
          }
        }
      }
      // 2. Fallback: VID/PID > 0 ise VID/PID match (gerçek USB cihaz)
      if (_settings.vendorId != null && _settings.vendorId != 0) {
        for (final d in devices) {
          if (d.vendorId == _settings.vendorId &&
              d.productId == _settings.productId) {
            return d.name;
          }
        }
      }
    } catch (_) {
      // Discovery başarısızsa sessiz geç — outer error handling devralır
    }
    return null;
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
  final company = ref.watch(companyInfoProvider);
  final hidden = ref.watch(hiddenPrintersProvider);
  final notifier = ref.read(printSettingsProvider.notifier);
  return PrintService(
    settings,
    company: company,
    hidden: hidden,
    onDeviceNameRefresh: notifier.refreshDeviceName,
  );
});
