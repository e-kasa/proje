import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 28 — POS notifications kullanıcı ayarları.
///
/// Şu an sadece **Otomatik satış SMS'i** toggle'ı tutuluyor (POS satış
/// tamamlandığında müşteri telefonu varsa fiş özeti SMS olarak gönderilir).
///
/// SharedPreferences-backed; Sprint 22 [`PrintSettings`] paterniyle uyumlu.
/// Provider hub status query'leri için bu ayarı okuyabilir
/// (Sprint 23 `integrations_provider.dart` SMS satırı).
class NotificationSettings {
  /// Satış sonrası müşteriye otomatik SMS gönder (telefon varsa).
  final bool smsAutoOnSale;

  /// Satış sonrası müşteriye otomatik e-posta gönder (Sprint 29+ — placeholder).
  final bool emailAutoOnSale;

  const NotificationSettings({
    this.smsAutoOnSale = false,
    this.emailAutoOnSale = false,
  });

  NotificationSettings copyWith({
    bool? smsAutoOnSale,
    bool? emailAutoOnSale,
  }) {
    return NotificationSettings(
      smsAutoOnSale: smsAutoOnSale ?? this.smsAutoOnSale,
      emailAutoOnSale: emailAutoOnSale ?? this.emailAutoOnSale,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings());

  static const _kSmsAuto = 'notification.sms_auto_on_sale';
  static const _kEmailAuto = 'notification.email_auto_on_sale';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      smsAutoOnSale: prefs.getBool(_kSmsAuto) ?? false,
      emailAutoOnSale: prefs.getBool(_kEmailAuto) ?? false,
    );
  }

  Future<void> updateSmsAutoOnSale(bool value) async {
    state = state.copyWith(smsAutoOnSale: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSmsAuto, value);
  }

  Future<void> updateEmailAutoOnSale(bool value) async {
    state = state.copyWith(emailAutoOnSale: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEmailAuto, value);
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  (ref) => NotificationSettingsNotifier()..load(),
);
