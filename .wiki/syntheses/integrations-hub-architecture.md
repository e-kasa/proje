---
title: Cihazlar & Entegrasyonlar Hub Mimarisi (Sprint 23)
tags: [synthesis, ui-architecture, settings, integrations, sprint-23, extension-pattern]
source: project_pos/lib/features/settings/integrations/
date: 2026-05-01
status: draft
---

# Cihazlar & Entegrasyonlar Hub Mimarisi

Sprint 23'te tasarlanan, ayarlar ekranındaki dağınık donanım/bildirim section'larını **tek hub** altında toplayan extensible katman. Audit: [[sources/code-refs/2026-05-01-integrations-hub-audit]].

## Mimari Hiyerarşisi

```
SettingsScreen (Sprint 15 DetailScreenTemplate, 4 tab)
    System Tab
       ↓ tek satır: "Cihazlar & Entegrasyonlar"
       ↓ context.push('/settings/integrations')

IntegrationsHubScreen (BaseScaffold, ConsumerWidget) — Sprint 23 YENİ
    ├── Summary Card (X aktif / Y eksik / Z pasif)
    ├── Donanım kategorisi (5 entegrasyon)
    │     ├── USB Termal Yazıcı  ──→  /settings/printer       (Sprint 22)
    │     ├── Para Çekmecesi      ──→  /settings/printer       (yazıcıya bağlı)
    │     ├── Barkod Tarayıcı     ──→  (yapılandırma yok)
    │     ├── Tartı               ──→  Yakında toast
    │     └── Etiket Yazıcı       ──→  Yakında toast
    └── Bildirimler kategorisi (4 entegrasyon)
          ├── E-posta              ──→  /settings/email         (Sprint 23 skeleton)
          ├── SMS                  ──→  /settings/sms           (Sprint 23 skeleton)
          ├── Push                 ──→  Yakında toast
          └── Stok Uyarıları       ──→  Yakında toast
```

## 3-Katman Soyutlama

### Katman 1: `IntegrationDef` — Statik Metadata

[`integrations/models/integration.dart`](project_pos/lib/features/settings/integrations/models/integration.dart):

```dart
const IntegrationDef(
  id: 'thermal_printer',                    // unique, status case key
  name: 'USB Termal Yazıcı',
  description: 'POSA / ESC-POS uyumlu fiş yazıcısı',
  icon: Icons.print,
  iconColor: AppColors.primary,
  category: IntegrationCategory.hardware,
  configRoute: '/settings/printer',         // null ise "Yakında" toast
  hasMasterSwitch: true,                    // false ise sadece bilgi (chevron_right)
)
```

**Statik const list** — derleme zamanında bilinir, runtime modify edilmez. Yeni entegrasyon eklemek = bu listeye `IntegrationDef` eklemek.

### Katman 2: `integrationStatusProvider.family<String, IntegrationStatus>` — Dinamik Durum

```dart
final integrationStatusProvider = Provider.family<IntegrationStatus, String>((ref, id) {
  switch (id) {
    case 'thermal_printer':
      final s = ref.watch(printSettingsProvider);          // GERÇEK kaynak
      return IntegrationStatus(
        isEnabled: s.autoPrintOnSale || s.isConfigured,
        isConfigured: s.isConfigured,
        statusText: s.isConfigured ? 'Bağlı: ${s.deviceName}' : 'Yapılandırılmadı',
        subtitle: '${s.paperWidth.mm}mm · ${autoOnLabel}',
      );

    case 'cash_drawer':
      final s = ref.watch(printSettingsProvider);          // YAZICIYA BAĞLI
      return IntegrationStatus(isEnabled: s.isConfigured, ...);

    case 'barcode_scanner':
      return const IntegrationStatus(
        isEnabled: true, isConfigured: true,
        statusText: 'Aktif (USB HID otomatik)',
      );

    // Placeholder (Sprint 24+ gerçek implementasyon)
    case 'scale': case 'label_printer': case 'email': case 'sms': ...
      final masterEnabled = ref.watch(_placeholderMasterProvider(id));
      return IntegrationStatus(
        isEnabled: masterEnabled, isConfigured: false,
        statusText: masterEnabled ? 'Aktif (yapılandırılmadı)' : 'Pasif',
      );
  }
});
```

**Family pattern**: her ID için ayrı reactive provider, yazıcı durumu değişirse sadece o satır rebuild olur. Performans + temiz separation.

### Katman 3: `IntegrationToggleNotifier` — Master Switch Handler

```dart
class IntegrationToggleNotifier {
  void toggle(String id, bool value) {
    switch (id) {
      case 'thermal_printer':
        _ref.read(printSettingsProvider.notifier).updateAutoPrint(value);
        break;
      case 'scale': case 'email': case 'sms': ...
        _ref.read(_placeholderMasterProvider(id).notifier).state = value;
        break;
    }
  }
}
```

Yazıcı toggle gerçek setting değiştirir (POS sale flow'unu etkiler). Placeholder'lar RAM-only (Sprint 24+ SharedPreferences ekleyecek).

## Health Enum + Renk Semantiği

```dart
enum IntegrationHealth { healthy, warning, disabled, error }
```

- **healthy** (yeşil): `isEnabled && isConfigured` → "Bağlı: POSA-..."
- **warning** (turuncu): `isEnabled && !isConfigured` → "Aktif (yapılandırılmadı)"
- **disabled** (gri): `!isEnabled` → "Pasif"
- **error** (kırmızı): future use (e.g., "Bağlantı koptu")

Hub satırında 3 yer renk gösterir:
1. Status badge (sağ üst, küçük rounded chip)
2. Subtitle text rengi
3. (gelecek) İkon dim/highlight

## Extension Noktaları (yeni entegrasyon eklemek)

3 adımlı:

1. **`integrations/models/integration.dart`'da yeni `IntegrationDef`** (statik catalog'a ekle)
2. **`integration_provider.dart`'ta yeni `case`** (status nasıl hesaplanır)
3. **(opsiyonel) yeni `*_settings_screen.dart`** + router entry

Örnek: yarın "Lab Yazıcı (CUPS)" eklemek istesek:

```dart
// 1. Catalog
const IntegrationDef(
  id: 'lab_printer', name: 'Lab Yazıcı', icon: Icons.print, category: hardware,
  configRoute: '/settings/lab-printer', ...
),

// 2. Status case
case 'lab_printer':
  final s = ref.watch(labPrinterSettingsProvider);  // Yeni provider
  return IntegrationStatus(...);

// 3. Yeni ekran + router
GoRoute(path: '/settings/lab-printer', builder: (...) => LabPrinterSettingsScreen()),
```

Hub kodunu **dokunmadan** yeni cihaz eklenebilir.

## Sprint 19 Kuralının Uygulaması

Sprint 19'da emekli edilen DashboardScreenTemplate öğretisi:
> *"Gerçek tüketici talebi olmadan template/feature inşa etme."*

Sprint 23'te bu **aktif olarak uygulandı**:

| Bileşen | Karar | Sebep |
|---|---|---|
| Hub iskeleti | İnşa edildi | Kullanıcı talebi (2026-05-01) |
| Yazıcı entegrasyonu | İnşa edildi (Sprint 22) | Kullanıcı POSA cihazına sahip |
| Barkod tarayıcı | Otomatik aktif | OS hallediyor, ekstra UI gerekmez |
| Cash drawer | Yazıcıya bağlı | ESC/POS pin komutu, ayrı ekran gereksiz |
| **Email/SMS skeleton ekran** | Placeholder | UI hazır, **backend yok** — Sprint 19 kuralı: backend talep gelince inşa et |
| **Push/Stok uyarısı/Terazi/Etiket yazıcı** | Sadece master switch placeholder | Hiç müşteri talebi yok, tam ekran bile inşa etme |

Bu **kademeli yatırım** stratejisi:
- L0: Hiçbir şey (cihaz/servis tanımlanmamış)
- L1: Catalog'da `IntegrationDef` (hub'da görünür, master switch placeholder)
- L2: Skeleton config ekranı (UI hazır, "Sprint 24+" banner)
- L3: Real implementasyon (SharedPreferences/backend hookup)

Yazıcı L3, Email/SMS L2, Push/Terazi/Etiket L1.

## Riskler

- **Placeholder switch karışıklığı**: Kullanıcı switch'i açar, "neden çalışmıyor" der. Mitigation: `IntegrationStatus.subtitle` "Yapılandırma yakında" ve email/sms ekranlarında sarı banner.
- **Status drift**: Yazıcı bağlandı ama provider invalidate edilmedi → hub eski durum gösterir. Mitigation: `printSettingsProvider` zaten `StateNotifier`, herhangi bir değişiklik tüm `watch`çıları rebuild eder.
- **Placeholder master switch persistence eksik**: Restart'ta sıfırlanır. Mitigation: Sprint 24+ task ("kullanıcı switch'i kaybolduğunu farkederse").

## Verification

- `flutter analyze` (5 yeni dosya): bekleniyor 0 yeni issue
- Smoke test (kullanıcı runtime'da):
  1. Settings → Sistem → "Cihazlar & Entegrasyonlar" tıkla
  2. 3 kategori (Donanım/Bildirimler) görmeli, summary card "X aktif / Y eksik / Z pasif"
  3. Yazıcı satırı: gerçek durumu yansıtmalı (Sprint 22'de bağlanmışsa yeşil "Bağlı: POSA-...")
  4. E-posta tıkla → SMTP skeleton + sarı banner
  5. SMS tıkla → SMS skeleton + sarı banner
  6. Push satırına Switch toggle → state RAM'de tutulmalı (yeşil → "Aktif (yapılandırılmadı)" turuncu)

## Sources

- [[sources/code-refs/2026-05-01-integrations-hub-audit]] — bu mimarinin doğduğu audit
- [[syntheses/design-system-template-architecture]] — Sprint 15-21 BaseScaffold + template katmanı (hub bu katmanın tüketicisi)
- [[log]] — Sprint 22 (printer) + Sprint 23 (hub) entries

## Related

- [[concepts/app-colors-palette]]
- [[entities/project-pos]]
- `lib/services/print/print_settings.dart` — Sprint 22 yazıcı provider
