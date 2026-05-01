import 'package:flutter/material.dart';

/// Sprint 23 — Cihazlar & Entegrasyonlar hub'ı için generic model.
///
/// Her entegrasyon (yazıcı, mail, SMS, terazi, ...) `IntegrationDef` ile
/// tanımlanır; gerçek durum ve switch davranışı hub ekranı tarafından
/// `Riverpod` provider'larından okunur — model sadece statik metadata.
class IntegrationDef {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color iconColor;
  final IntegrationCategory category;

  /// Detay/ayar ekranı route'u. null ise "Yakında" toast.
  final String? configRoute;

  /// Master switch destekli mi? false ise sadece bilgilendirme.
  final bool hasMasterSwitch;

  /// Yalnız masaüstü uygulamasında kullanılabilir mi (USB / seri port erişimi
  /// gerektiren entegrasyonlar). Web build'de kart disabled görünür.
  final bool requiresDesktop;

  const IntegrationDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.category,
    this.configRoute,
    this.hasMasterSwitch = true,
    this.requiresDesktop = false,
  });
}

enum IntegrationCategory {
  /// Yazıcı, terazi, cash drawer, barkod tarayıcı — fiziksel donanım
  hardware('Donanım', Icons.devices),

  /// E-posta, SMS, push — uzak bildirim servisleri
  notifications('Bildirimler', Icons.notifications_active),

  /// Backup, sync, webhook — sistem entegrasyonları (gelecek)
  system('Sistem', Icons.settings_ethernet);

  final String label;
  final IconData icon;
  const IntegrationCategory(this.label, this.icon);
}

/// Bir entegrasyonun anlık durumu.
class IntegrationStatus {
  /// Master switch durumu (kullanıcı açtı/kapadı).
  final bool isEnabled;

  /// Yapılandırma tamamlandı mı (cihaz seçildi, credential girildi, vs.).
  final bool isConfigured;

  /// Status badge metni ("Bağlı: POSA-80", "Yapılandırılmadı", "Hata", vs.).
  final String statusText;

  /// Ek alt bilgi (örn. son test, hata sebebi).
  final String? subtitle;

  const IntegrationStatus({
    required this.isEnabled,
    required this.isConfigured,
    required this.statusText,
    this.subtitle,
  });

  /// Renk kodu: yeşil (aktif+bağlı), turuncu (aktif ama yapılandırılmadı),
  /// gri (kapalı), kırmızı (hata).
  IntegrationHealth get health {
    if (!isEnabled) return IntegrationHealth.disabled;
    if (!isConfigured) return IntegrationHealth.warning;
    return IntegrationHealth.healthy;
  }
}

enum IntegrationHealth { healthy, warning, disabled, error }
