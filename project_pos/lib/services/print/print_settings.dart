import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 22 — POS Receipt Printer ayarları (Windows desktop USB ESC/POS).
///
/// SharedPreferences'da saklanır; uygulama açılırken `PrintSettingsNotifier.load()`
/// ile yüklenir. UI: `printer_settings_screen.dart`. Tüketici: `UsbPrintService`.
class PrintSettings {
  /// Bağlanılacak USB cihazın vendor ID'si (decimal). null ise yazıcı bağlı değil.
  final int? vendorId;

  /// USB product ID (decimal).
  final int? productId;

  /// Ekranda gösterilen cihaz adı ("POSA-80" gibi). Sadece UI için.
  final String? deviceName;

  /// Kağıt genişliği (mm). POSA çoğunlukla 80mm.
  final PaperWidth paperWidth;

  /// Satış sonrası fişi otomatik yazdır.
  final bool autoPrintOnSale;

  /// Fiş başında firma logosu/başlık.
  final String headerText;

  /// Fiş alt yazısı (teşekkürler vb).
  final String footerText;

  const PrintSettings({
    this.vendorId,
    this.productId,
    this.deviceName,
    this.paperWidth = PaperWidth.mm80,
    this.autoPrintOnSale = false,
    this.headerText = 'SEDCORE POS',
    this.footerText = 'Tesekkurler! Iyi gunler...',
  });

  bool get isConfigured => vendorId != null && productId != null;

  PrintSettings copyWith({
    int? vendorId,
    int? productId,
    String? deviceName,
    PaperWidth? paperWidth,
    bool? autoPrintOnSale,
    String? headerText,
    String? footerText,
    bool clearDevice = false,
  }) {
    return PrintSettings(
      vendorId: clearDevice ? null : (vendorId ?? this.vendorId),
      productId: clearDevice ? null : (productId ?? this.productId),
      deviceName: clearDevice ? null : (deviceName ?? this.deviceName),
      paperWidth: paperWidth ?? this.paperWidth,
      autoPrintOnSale: autoPrintOnSale ?? this.autoPrintOnSale,
      headerText: headerText ?? this.headerText,
      footerText: footerText ?? this.footerText,
    );
  }
}

enum PaperWidth {
  mm58(58),
  mm80(80);

  final int mm;
  const PaperWidth(this.mm);

  /// esc_pos_utils PaperSize'a karşılık gelen integer (chars per line baz).
  /// 58mm → 32 char, 80mm → 48 char (default font A için).
  int get charsPerLine => this == PaperWidth.mm58 ? 32 : 48;
}

class PrintSettingsNotifier extends StateNotifier<PrintSettings> {
  PrintSettingsNotifier() : super(const PrintSettings());

  static const _kVendorId = 'print.vendor_id';
  static const _kProductId = 'print.product_id';
  static const _kDeviceName = 'print.device_name';
  static const _kPaperWidth = 'print.paper_width';
  static const _kAutoPrint = 'print.auto_print';
  static const _kHeader = 'print.header';
  static const _kFooter = 'print.footer';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = PrintSettings(
      vendorId: prefs.getInt(_kVendorId),
      productId: prefs.getInt(_kProductId),
      deviceName: prefs.getString(_kDeviceName),
      paperWidth: PaperWidth.values.firstWhere(
        (w) => w.name == prefs.getString(_kPaperWidth),
        orElse: () => PaperWidth.mm80,
      ),
      autoPrintOnSale: prefs.getBool(_kAutoPrint) ?? false,
      headerText: prefs.getString(_kHeader) ?? 'SEDCORE POS',
      footerText: prefs.getString(_kFooter) ?? 'Tesekkurler! Iyi gunler...',
    );
  }

  Future<void> updateDevice({
    required int vendorId,
    required int productId,
    required String deviceName,
  }) async {
    state = state.copyWith(
      vendorId: vendorId,
      productId: productId,
      deviceName: deviceName,
    );
    await _persist();
  }

  Future<void> clearDevice() async {
    state = state.copyWith(clearDevice: true);
    await _persist();
  }

  Future<void> updatePaperWidth(PaperWidth width) async {
    state = state.copyWith(paperWidth: width);
    await _persist();
  }

  Future<void> updateAutoPrint(bool value) async {
    state = state.copyWith(autoPrintOnSale: value);
    await _persist();
  }

  Future<void> updateText({String? header, String? footer}) async {
    state = state.copyWith(headerText: header, footerText: footer);
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.vendorId != null) {
      await prefs.setInt(_kVendorId, state.vendorId!);
    } else {
      await prefs.remove(_kVendorId);
    }
    if (state.productId != null) {
      await prefs.setInt(_kProductId, state.productId!);
    } else {
      await prefs.remove(_kProductId);
    }
    if (state.deviceName != null) {
      await prefs.setString(_kDeviceName, state.deviceName!);
    } else {
      await prefs.remove(_kDeviceName);
    }
    await prefs.setString(_kPaperWidth, state.paperWidth.name);
    await prefs.setBool(_kAutoPrint, state.autoPrintOnSale);
    await prefs.setString(_kHeader, state.headerText);
    await prefs.setString(_kFooter, state.footerText);
  }
}

final printSettingsProvider =
    StateNotifierProvider<PrintSettingsNotifier, PrintSettings>(
  (ref) => PrintSettingsNotifier()..load(),
);
