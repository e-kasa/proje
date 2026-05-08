import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/app_logger.dart';
import '../service_locator.dart';

/// Sprint 30 — Firma kimlik bilgisi (fiş header bloğu için).
///
/// `CompanySettingsScreen` üzerinden backend'e (`product/api/v1/company/settings`)
/// kaydedilen firma bilgisinin offline-first cache'i. `ReceiptTemplate` bu veriyi
/// kullanarak fişe firma unvanı + VKN + Vergi Dairesi + adres + telefon basar.
///
/// Paterni: [`PrintSettings`](services/print/print_settings.dart) — SharedPreferences cache
/// + `loaded` flag (UI ilk frame'de stale-but-correct göster).
///
/// Audit: [[sources/code-refs/2026-05-06-eArsiv-receipt-compliance-audit]]
/// Sentez: [[syntheses/eArsiv-receipt-compliance]] (K1, K2)
class CompanyInfo {
  /// Ticari unvan ("Sedcore Bilişim A.Ş." gibi). Boş ise PrintSettings.headerText fallback.
  final String companyName;

  /// 10 haneli Vergi Kimlik Numarası. Boş geçilebilir (fiş satırı atlanır).
  final String taxNumber;

  /// Vergi dairesi adı ("Şişli" gibi). Boş geçilebilir.
  final String taxOffice;

  /// Mağaza adresi (cadde/sokak/şehir). Boş geçilebilir.
  final String address;

  /// İletişim telefonu (opsiyonel).
  final String phone;

  /// E-posta (opsiyonel — fişe basılmaz, future kullanım).
  final String email;

  /// MERSIS No (opsiyonel, gelecek sertifikasyon için tutuldu).
  final String mersisNo;

  /// SharedPreferences'tan hidrasyon tamamlandı mı.
  ///
  /// `false` iken UI loading göstermeli; aksi halde boş alanlarla fiş basılır.
  final bool loaded;

  const CompanyInfo({
    this.companyName = '',
    this.taxNumber = '',
    this.taxOffice = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.mersisNo = '',
    this.loaded = false,
  });

  /// Fişte firma blok basılmaya değer mi (en az unvan + VKN olmalı).
  bool get isComplete => companyName.isNotEmpty && taxNumber.isNotEmpty;

  /// Sertifikasyon yolu açılırsa (Sprint 32+) flag açılır; default false →
  /// fiş "resmi belge değildir" disclaimer'ı gösterir.
  bool get isOfficialReceipt => false;

  CompanyInfo copyWith({
    String? companyName,
    String? taxNumber,
    String? taxOffice,
    String? address,
    String? phone,
    String? email,
    String? mersisNo,
    bool? loaded,
  }) {
    return CompanyInfo(
      companyName: companyName ?? this.companyName,
      taxNumber: taxNumber ?? this.taxNumber,
      taxOffice: taxOffice ?? this.taxOffice,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      mersisNo: mersisNo ?? this.mersisNo,
      loaded: loaded ?? this.loaded,
    );
  }
}

class CompanyInfoNotifier extends StateNotifier<CompanyInfo> {
  CompanyInfoNotifier(this._ref) : super(const CompanyInfo());

  final Ref _ref;

  static const _kCompanyName = 'company.name';
  static const _kTaxNumber = 'company.tax_number';
  static const _kTaxOffice = 'company.tax_office';
  static const _kAddress = 'company.address';
  static const _kPhone = 'company.phone';
  static const _kEmail = 'company.email';
  static const _kMersisNo = 'company.mersis_no';

  /// App boot çağrısı — SharedPreferences'tan hidrasyon, sonra background
  /// silent refresh (`refreshFromBackend()`).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = CompanyInfo(
      companyName: prefs.getString(_kCompanyName) ?? '',
      taxNumber: prefs.getString(_kTaxNumber) ?? '',
      taxOffice: prefs.getString(_kTaxOffice) ?? '',
      address: prefs.getString(_kAddress) ?? '',
      phone: prefs.getString(_kPhone) ?? '',
      email: prefs.getString(_kEmail) ?? '',
      mersisNo: prefs.getString(_kMersisNo) ?? '',
      loaded: true,
    );
    // Cache yüklendi → background'da güncel veri çek (kritik path bloklamaz).
    unawaited(refreshFromBackend());
  }

  /// Backend'den firma ayarlarını çek + cache güncelle.
  ///
  /// `CompanySettingsScreen.save` sonrası çağrılır. Network hatası → state
  /// değişmez, AppLogger.warning. Auth/multi-tenant header `service_locator`
  /// üzerinden ApiClient interceptor tarafından eklenir.
  Future<void> refreshFromBackend() async {
    try {
      final svc = _ref.read(userServiceProvider);
      final data = await svc.getCompanySettings();
      final next = state.copyWith(
        companyName: data['companyName']?.toString() ?? state.companyName,
        taxNumber: data['taxNumber']?.toString() ?? state.taxNumber,
        taxOffice: data['taxOffice']?.toString() ?? state.taxOffice,
        address: data['address']?.toString() ?? state.address,
        phone: data['phone']?.toString() ?? state.phone,
        email: data['email']?.toString() ?? state.email,
        mersisNo: data['mersisNo']?.toString() ?? state.mersisNo,
        loaded: true,
      );
      state = next;
      await _persist();
    } catch (e) {
      AppLogger.warning(
        'CompanyInfo backend refresh basarisiz, cache kullaniliyor',
        tag: 'CompanyInfo',
        error: e,
      );
    }
  }

  /// Logout/tenant değişiminde çağrılır — cache'i temizle (Sprint 30 K2).
  Future<void> clear() async {
    state = const CompanyInfo(loaded: true);
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_kCompanyName),
      prefs.remove(_kTaxNumber),
      prefs.remove(_kTaxOffice),
      prefs.remove(_kAddress),
      prefs.remove(_kPhone),
      prefs.remove(_kEmail),
      prefs.remove(_kMersisNo),
    ]);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCompanyName, state.companyName);
    await prefs.setString(_kTaxNumber, state.taxNumber);
    await prefs.setString(_kTaxOffice, state.taxOffice);
    await prefs.setString(_kAddress, state.address);
    await prefs.setString(_kPhone, state.phone);
    await prefs.setString(_kEmail, state.email);
    await prefs.setString(_kMersisNo, state.mersisNo);
  }
}

/// Riverpod provider — app boot'ta `load()` ile cache hidrasyonu otomatik.
final companyInfoProvider =
    StateNotifierProvider<CompanyInfoNotifier, CompanyInfo>(
  (ref) => CompanyInfoNotifier(ref)..load(),
);
