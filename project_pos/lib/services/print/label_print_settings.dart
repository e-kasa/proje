import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 24 — Etiket yazıcı ayarları (Windows desktop USB ESC/POS).
///
/// `PrintSettings` (Sprint 22 fiş yazıcısı) paterni paralel — ayrı slot,
/// ayrı SharedPreferences key prefix. UI: `label_printer_settings_screen.dart`.
/// Tüketici: `LabelPrintService`.
class LabelPrinterSettings {
  /// Bağlanılacak USB cihazın vendor ID'si (decimal). null ise yazıcı bağlı değil.
  final int? vendorId;

  /// USB product ID (decimal).
  final int? productId;

  /// Ekranda gösterilen cihaz adı.
  final String? deviceName;

  /// Etiket genişliği (mm). Çoğu termal etiket 40, 50 veya 80 mm.
  final int labelWidthMm;

  /// Etiket yüksekliği (mm). Tek bir etiketin Y boyutu.
  final int labelHeightMm;

  /// Varsayılan barkod tipi.
  final LabelCodeType defaultCodeType;

  /// Her etiketten sonra otomatik kesim yapılsın mı (`GS V` cut komutu).
  final bool autoCutAfterEach;

  /// Etiket altına ürün adı yazılsın mı.
  final bool showProductName;

  /// Etiket altına SKU yazılsın mı.
  final bool showSku;

  /// Etiket altına fiyat yazılsın mı.
  final bool showPrice;

  /// Sprint 30 — Yazıcı protokolü. Cihaz ailesine göre seçilir:
  /// - `escPos`: POSA / Zjiang ZJ-58/80 fiş termal (default — backward compat)
  /// - `tspl`: Zjiang LABEL-9X10, Argox CP, TSC TX/TE etiket yazıcılar
  ///
  /// Hızlı Kurulum sihirbazı cihaz adında "label" / "9X10" varsa otomatik
  /// `tspl` seçer. Manuel override label_printer_settings_screen üzerinden.
  final LabelProtocol protocol;

  /// SharedPreferences'tan hidrasyon tamamlandı mı.
  ///
  /// `false` iken UI "yapılandırılmamış" yerine loading göstermeli — aksi halde
  /// ilk frame'de kayıtlı yazıcı varken bile "yazıcı yok" görünür ve kullanıcı
  /// gereksiz yere yeniden seçim yapar (Sprint 30 receipt-printer-repeated-pairing fix).
  final bool loaded;

  const LabelPrinterSettings({
    this.vendorId,
    this.productId,
    this.deviceName,
    this.labelWidthMm = 50,
    this.labelHeightMm = 30,
    this.defaultCodeType = LabelCodeType.code128,
    this.autoCutAfterEach = true,
    this.showProductName = true,
    this.showSku = true,
    this.showPrice = false,
    this.protocol = LabelProtocol.escPos,
    this.loaded = false,
  });

  bool get isConfigured => vendorId != null && productId != null;

  LabelPrinterSettings copyWith({
    int? vendorId,
    int? productId,
    String? deviceName,
    int? labelWidthMm,
    int? labelHeightMm,
    LabelCodeType? defaultCodeType,
    bool? autoCutAfterEach,
    bool? showProductName,
    bool? showSku,
    bool? showPrice,
    LabelProtocol? protocol,
    bool? loaded,
    bool clearDevice = false,
  }) {
    return LabelPrinterSettings(
      vendorId: clearDevice ? null : (vendorId ?? this.vendorId),
      productId: clearDevice ? null : (productId ?? this.productId),
      deviceName: clearDevice ? null : (deviceName ?? this.deviceName),
      labelWidthMm: labelWidthMm ?? this.labelWidthMm,
      labelHeightMm: labelHeightMm ?? this.labelHeightMm,
      defaultCodeType: defaultCodeType ?? this.defaultCodeType,
      autoCutAfterEach: autoCutAfterEach ?? this.autoCutAfterEach,
      showProductName: showProductName ?? this.showProductName,
      showSku: showSku ?? this.showSku,
      showPrice: showPrice ?? this.showPrice,
      protocol: protocol ?? this.protocol,
      loaded: loaded ?? this.loaded,
    );
  }
}

enum LabelCodeType {
  code128('Code128'),
  ean13('EAN-13'),
  qr('QR Code');

  final String label;
  const LabelCodeType(this.label);
}

/// Sprint 30 — Etiket yazıcı protokolü.
enum LabelProtocol {
  escPos('ESC/POS', 'POSA / Zjiang fiş termal'),
  tspl('TSPL', 'Zjiang LABEL / Argox / TSC etiket');

  final String label;
  final String description;
  const LabelProtocol(this.label, this.description);
}

class LabelPrintSettingsNotifier extends StateNotifier<LabelPrinterSettings> {
  LabelPrintSettingsNotifier() : super(const LabelPrinterSettings());

  static const _kVendorId = 'label_print.vendor_id';
  static const _kProductId = 'label_print.product_id';
  static const _kDeviceName = 'label_print.device_name';
  static const _kLabelWidth = 'label_print.label_width_mm';
  static const _kLabelHeight = 'label_print.label_height_mm';
  static const _kCodeType = 'label_print.default_code_type';
  static const _kAutoCut = 'label_print.auto_cut';
  static const _kShowName = 'label_print.show_name';
  static const _kShowSku = 'label_print.show_sku';
  static const _kShowPrice = 'label_print.show_price';
  static const _kProtocol = 'label_print.protocol';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = LabelPrinterSettings(
      vendorId: prefs.getInt(_kVendorId),
      productId: prefs.getInt(_kProductId),
      deviceName: prefs.getString(_kDeviceName),
      labelWidthMm: prefs.getInt(_kLabelWidth) ?? 50,
      labelHeightMm: prefs.getInt(_kLabelHeight) ?? 30,
      defaultCodeType: LabelCodeType.values.firstWhere(
        (t) => t.name == prefs.getString(_kCodeType),
        orElse: () => LabelCodeType.code128,
      ),
      autoCutAfterEach: prefs.getBool(_kAutoCut) ?? true,
      showProductName: prefs.getBool(_kShowName) ?? true,
      showSku: prefs.getBool(_kShowSku) ?? true,
      showPrice: prefs.getBool(_kShowPrice) ?? false,
      protocol: LabelProtocol.values.firstWhere(
        (p) => p.name == prefs.getString(_kProtocol),
        orElse: () => LabelProtocol.escPos,
      ),
      loaded: true,
    );
  }

  /// Self-healing: VID/PID kayıtlı kalır, sadece Windows enumeration sırasında
  /// değişen `deviceName` güncellenir. `LabelPrintService._send()` connect
  /// failure → rediscover → match akışında çağrılır. Detay için bkz.
  /// `PrintSettingsNotifier.refreshDeviceName`.
  Future<void> refreshDeviceName(String newName) async {
    if (state.vendorId == null || state.productId == null) return;
    if (state.deviceName == newName) return;
    state = state.copyWith(deviceName: newName);
    await _persist();
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

  Future<void> updateDimensions({int? widthMm, int? heightMm}) async {
    state = state.copyWith(
      labelWidthMm: widthMm,
      labelHeightMm: heightMm,
    );
    await _persist();
  }

  Future<void> updateCodeType(LabelCodeType type) async {
    state = state.copyWith(defaultCodeType: type);
    await _persist();
  }

  Future<void> updateAutoCut(bool value) async {
    state = state.copyWith(autoCutAfterEach: value);
    await _persist();
  }

  Future<void> updateShowFields({
    bool? name,
    bool? sku,
    bool? price,
  }) async {
    state = state.copyWith(
      showProductName: name,
      showSku: sku,
      showPrice: price,
    );
    await _persist();
  }

  Future<void> updateProtocol(LabelProtocol protocol) async {
    state = state.copyWith(protocol: protocol);
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
    await prefs.setInt(_kLabelWidth, state.labelWidthMm);
    await prefs.setInt(_kLabelHeight, state.labelHeightMm);
    await prefs.setString(_kCodeType, state.defaultCodeType.name);
    await prefs.setBool(_kAutoCut, state.autoCutAfterEach);
    await prefs.setBool(_kShowName, state.showProductName);
    await prefs.setBool(_kShowSku, state.showSku);
    await prefs.setBool(_kShowPrice, state.showPrice);
    await prefs.setString(_kProtocol, state.protocol.name);
  }
}

final labelPrintSettingsProvider =
    StateNotifierProvider<LabelPrintSettingsNotifier, LabelPrinterSettings>(
  (ref) => LabelPrintSettingsNotifier()..load(),
);
