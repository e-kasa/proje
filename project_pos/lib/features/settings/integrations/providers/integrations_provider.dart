import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/services/print/label_print_settings.dart';
import 'package:project_pos/services/print/print_settings.dart';

import '../models/integration.dart';

/// Sprint 23 — Cihazlar & Entegrasyonlar listesi (statik tanımlar).
///
/// Yeni entegrasyon eklemek için:
/// 1. `IntegrationDef`'i bu listeye ekle
/// 2. `integrationStatusProvider` family'sine ID için case ekle
/// 3. (varsa) ilgili `*_settings_screen.dart` ekranı yaz
const List<IntegrationDef> _integrationsCatalog = [
  // ── DONANIM ────────────────────────────────────────────────────────────
  IntegrationDef(
    id: 'thermal_printer',
    name: 'USB Termal Yazıcı',
    description: 'POSA / ESC-POS uyumlu fiş yazıcısı',
    icon: Icons.print,
    iconColor: AppColors.primary,
    category: IntegrationCategory.hardware,
    configRoute: '/settings/printer',
    requiresDesktop: true,
  ),
  IntegrationDef(
    id: 'cash_drawer',
    name: 'Para Çekmecesi',
    description: 'Yazıcı çıkışına bağlı kasa çekmecesi (ESC p)',
    icon: Icons.point_of_sale,
    iconColor: AppColors.success,
    category: IntegrationCategory.hardware,
    configRoute: '/settings/printer',
    hasMasterSwitch: false,
    requiresDesktop: true,
  ),
  IntegrationDef(
    id: 'barcode_scanner',
    name: 'Barkod Tarayıcı',
    description: 'USB HID — işletim sistemi otomatik tanır',
    icon: Icons.qr_code_scanner,
    iconColor: AppColors.info,
    category: IntegrationCategory.hardware,
    hasMasterSwitch: false,
    requiresDesktop: true,
  ),
  IntegrationDef(
    id: 'scale',
    name: 'Tartı (Terazi)',
    description: 'RS-232 / USB seri tartı entegrasyonu',
    icon: Icons.scale,
    iconColor: AppColors.warning,
    category: IntegrationCategory.hardware,
    requiresDesktop: true,
  ),
  IntegrationDef(
    id: 'label_printer',
    name: 'Etiket Yazıcı',
    description: 'USB termal etiket yazıcı — barkod / QR / EAN-13',
    icon: Icons.label,
    iconColor: AppColors.info,
    category: IntegrationCategory.hardware,
    configRoute: '/settings/label-printer',
    hasMasterSwitch: false,
    requiresDesktop: true,
  ),

  // ── BİLDİRİMLER ────────────────────────────────────────────────────────
  IntegrationDef(
    id: 'email',
    name: 'E-posta Bildirimleri',
    description: 'SMTP — günlük rapor, fiş gönderimi',
    icon: Icons.email,
    iconColor: AppColors.danger,
    category: IntegrationCategory.notifications,
    configRoute: '/settings/email',
  ),
  IntegrationDef(
    id: 'sms',
    name: 'SMS Servisi',
    description: 'Netgsm / Twilio — fiş, hatırlatma, kampanya',
    icon: Icons.sms,
    iconColor: AppColors.success,
    category: IntegrationCategory.notifications,
    configRoute: '/settings/sms',
  ),
  IntegrationDef(
    id: 'push',
    name: 'Push Bildirimleri',
    description: 'Mobil cihaz bildirimleri (FCM)',
    icon: Icons.notifications,
    iconColor: AppColors.warning,
    category: IntegrationCategory.notifications,
  ),
  IntegrationDef(
    id: 'low_stock_alert',
    name: 'Stok Uyarıları',
    description: 'Düşük stok seviyelerinde uyarı',
    icon: Icons.inventory_outlined,
    iconColor: AppColors.warning,
    category: IntegrationCategory.notifications,
  ),
];

/// Hub ekranı tüketicisi.
final integrationsCatalogProvider = Provider<List<IntegrationDef>>(
  (ref) => _integrationsCatalog,
);

/// Belirli bir entegrasyonun durum + master switch state'i.
///
/// Yazıcı için gerçek `printSettingsProvider` kullanılır; diğerleri
/// SharedPreferences-backed master toggle (TODO: Sprint 24+ gerçek implementasyon).
final integrationStatusProvider =
    Provider.family<IntegrationStatus, String>((ref, id) {
  switch (id) {
    case 'thermal_printer':
      final s = ref.watch(printSettingsProvider);
      return IntegrationStatus(
        isEnabled: s.autoPrintOnSale || s.isConfigured,
        isConfigured: s.isConfigured,
        statusText: s.isConfigured
            ? 'Bağlı: ${s.deviceName ?? "USB Yazıcı"}'
            : 'Yapılandırılmadı',
        subtitle: s.isConfigured
            ? '${s.paperWidth.mm}mm kağıt · '
                '${s.autoPrintOnSale ? "Otomatik yazdırma açık" : "Manuel yazdırma"}'
            : 'Tara → Cihaz seç',
      );

    case 'cash_drawer':
      final s = ref.watch(printSettingsProvider);
      return IntegrationStatus(
        isEnabled: s.isConfigured,
        isConfigured: s.isConfigured,
        statusText: s.isConfigured
            ? 'Yazıcıya bağlı (ESC p)'
            : 'Yazıcı yapılandırılmadı',
        subtitle: 'Yazıcı ile birlikte çalışır',
      );

    case 'barcode_scanner':
      return const IntegrationStatus(
        isEnabled: true,
        isConfigured: true,
        statusText: 'Aktif (USB HID otomatik)',
        subtitle: 'Sürücü/yapılandırma gerekmez',
      );

    case 'label_printer':
      // Sprint 24 — L1→L3 promotion: gerçek labelPrintSettingsProvider watch
      final s = ref.watch(labelPrintSettingsProvider);
      return IntegrationStatus(
        isEnabled: s.isConfigured,
        isConfigured: s.isConfigured,
        statusText: s.isConfigured
            ? 'Bağlı: ${s.deviceName ?? "USB Etiket Yazıcı"}'
            : 'Yapılandırılmadı',
        subtitle: s.isConfigured
            ? '${s.labelWidthMm}×${s.labelHeightMm}mm · ${s.defaultCodeType.label}'
            : 'Tara → Cihaz seç',
      );

    // Placeholder entegrasyonlar — Sprint 25+ gerçek implementasyon
    case 'scale':
    case 'email':
    case 'sms':
    case 'push':
    case 'low_stock_alert':
      final masterEnabled = ref.watch(_placeholderMasterProvider(id));
      return IntegrationStatus(
        isEnabled: masterEnabled,
        isConfigured: false,
        statusText: masterEnabled ? 'Aktif (yapılandırılmadı)' : 'Pasif',
        subtitle: 'Yapılandırma yakında',
      );

    default:
      return const IntegrationStatus(
        isEnabled: false,
        isConfigured: false,
        statusText: 'Bilinmeyen',
      );
  }
});

/// Placeholder master switch state'leri (RAM-only, app restart'ta sıfır).
/// Sprint 24+ SharedPreferences ile kalıcı yap.
final _placeholderMasterProvider =
    StateProvider.family<bool, String>((ref, id) => false);

/// Hub ekranı master switch toggle handler'ı.
///
/// Yazıcı için `printSettingsProvider.autoPrintOnSale` togglelar;
/// diğerleri RAM placeholder.
class IntegrationToggleNotifier {
  final Ref _ref;
  IntegrationToggleNotifier(this._ref);

  void toggle(String id, bool value) {
    switch (id) {
      case 'thermal_printer':
        _ref.read(printSettingsProvider.notifier).updateAutoPrint(value);
        break;
      case 'scale':
      case 'email':
      case 'sms':
      case 'push':
      case 'low_stock_alert':
        _ref.read(_placeholderMasterProvider(id).notifier).state = value;
        break;
    }
  }
}

final integrationToggleProvider = Provider<IntegrationToggleNotifier>(
  (ref) => IntegrationToggleNotifier(ref),
);
