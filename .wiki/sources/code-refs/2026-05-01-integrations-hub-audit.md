---
title: Cihazlar & Entegrasyonlar Hub Audit (2026-05-01)
tags: [audit, ui, settings, integrations, hardware, notifications, sprint-23]
source: project_pos/lib/features/settings/screens/settings_screen.dart `_buildSystemTab` + Sprint 22 outputs
date: 2026-05-01
status: verified
---

# Cihazlar & Entegrasyonlar Hub Audit (Sprint 23 Öncesi)

Sprint 22'de POSA termal yazıcı entegrasyonu eklendikten sonra ortaya çıkan **ayarlar ekranı dağınıklığı** ve **dummy switch problemi** belgelenmesi.

## Kullanıcı Tetikleyicisi

> "AYARLAR BÖLÜMÜNDE CİHAZLAR MAİL SMS GİBİ ÖZELLİKLERİN OLDUĞU AKTİF PASİF İŞLEMLERİN YAPILDIĞI BİR EKRAN İYİ OLMAZ MI" — Kullanıcı, 2026-05-01

Bu istek standart POS UX paterni: **tek "Cihazlar & Entegrasyonlar" hub'ı**, kategorize edilmiş, master switch + status badge + detay yönlendirme. Square POS, Shopify POS, IKAS Stoji vb. örneklerinde mevcut.

## Mevcut Dağınıklık (`settings_screen.dart`)

### `_buildSystemTab` — 3 dağınık section

[`settings_screen.dart:818-870`](project_pos/lib/features/settings/screens/settings_screen.dart):

```dart
_buildSystemTab() {
  return ListView(children: [
    _section('Donanım', [                       // Sprint 22'de eklendi (yeni)
      _item(Icons.print, 'Yazıcı Ayarları',
          'USB termal fiş yazıcısı (POSA, ESC/POS)',
          onTap: () => context.push('/settings/printer')),
    ]),
    _section('Veri & Gizlilik', [                // Sprint 1'den beri
      _item(Icons.backup_outlined, 'Yedekleme', 'Son: Bugün 03:00', ...),
      _item(Icons.sync, 'Senkronizasyon', 'Otomatik açık', ...),
      _item(Icons.delete_outline, 'Önbelleği Temizle', '128 MB', ...),
    ]),
    _section('Hakkında', [...]),
    AppCard(/* Tehlikeli Alan: Logout */),
  ]);
}
```

### `_buildNotificationsTab` — Tab 4 (`Settings.notifications`)

[`settings_screen.dart:786-808`](project_pos/lib/features/settings/screens/settings_screen.dart):

```dart
_section('Yönetim', [...]),                      // Users/Company/Sector links
_section('Bildirimler', [
  _item(Icons.email_outlined, 'E-posta Bildirimleri', 'Günlük raporlar',
      trailing: Switch(value: true, onChanged: (v) {})),    // ❌ DUMMY
  _item(Icons.inventory_outlined, 'Stok Uyarıları', 'Düşük stok bildir',
      trailing: Switch(value: true, onChanged: (v) {})),    // ❌ DUMMY
  _item(Icons.trending_down, 'Satış Uyarıları', 'Satış düşüşlerini bildir',
      trailing: Switch(value: false, onChanged: (v) {})),   // ❌ DUMMY
]),
```

**Tüm switch'ler `(v) {}` — fonksiyonsuz**. Kullanıcı toggle yapsa state kaybolur, persist edilmez, gerçek bildirim gönderilmez.

## Tespit Edilen Sorunlar

| # | Sorun | Etki |
|---|---|---|
| 1 | "Donanım" sadece yazıcıyı içerir — gelecek cihazlar (terazi, etiket yazıcı, cash drawer) eklendikçe 5+ section olacak | Settings ekran kalabalığı |
| 2 | "Bildirimler" switch'leri **fonksiyonsuz** — kullanıcı yapılandırılmış sanır, hayal kırıklığı | UX kayıp |
| 3 | E-posta/SMS **detay ekranı yok** — switch açılınca SMTP credential nereye girilecek? | Yapılandırma boşluğu |
| 4 | Donanım + bildirim ayrı tab'larda → kullanıcı "cihazlar" diye düşünüp tek yerde bekliyor | Navigation çatlağı |
| 5 | `printer_settings_screen` Sprint 22'de gelişti ama bağlantı durumu (bağlı/bağlı değil) settings_screen'de görünmez | Status görünürlüğü yok |

## Standart POS UX Paterni (Endüstri Karşılaştırması)

| POS Sistemi | Hub Adı | Kategorize | Master Switch | Status Badge |
|---|---|---|---|---|
| **Square POS** | "Hardware & Devices" | ✅ (printer/scale/scanner/customer-display) | ✅ | ✅ (yeşil/kırmızı online/offline) |
| **Shopify POS** | "Hardware" + "Apps" | ✅ | ✅ | ✅ |
| **IKAS Stoji** | "Cihazlar" | ✅ | ✅ | ✅ |
| **Loyverse** | "Connected Devices" + "Notifications" (ayrı 2 sayfa) | Yarım | Yalnız bazıları | Yok |

**Çoğunluk paterni:** Tek hub, kategori grubu, master toggle + detay yönlendirme. Sprint 23 bu pateni izleyecek.

## Sprint 22'den Devralınan Bileşenler

[`lib/services/print/print_settings.dart`](project_pos/lib/services/print/print_settings.dart):
- `PrintSettings` (vendorId, productId, deviceName, paperWidth, autoPrintOnSale, headerText, footerText)
- `printSettingsProvider` (StateNotifier, SharedPreferences)
- `PrintSettings.isConfigured` → bool (yazıcı bağlandı mı)

→ Hub'da yazıcı satırı bu provider'ı **watch** edecek; statusText `s.deviceName` ile dolu, switch `autoPrintOnSale` toggle.

## Sprint 23 Entegrasyon Kataloğu (9 Cihaz/Servis)

### Donanım (5)

| ID | İsim | Real/Placeholder | Sebep |
|---|---|---|---|
| `thermal_printer` | USB Termal Yazıcı (POSA) | **REAL** | Sprint 22'de inşa edildi, kullanıcı POSA cihazına sahip |
| `cash_drawer` | Para Çekmecesi (ESC p) | **REAL (yarı)** | Yazıcıya bağlı; ayrı UI gerek değil, status yansıtma yeterli |
| `barcode_scanner` | USB HID Barkod Tarayıcı | **REAL (otomatik)** | OS otomatik tanır, yapılandırma gerekmez; sadece "Aktif" göster |
| `scale` | Tartı (Terazi RS-232) | Placeholder | Müşteri talebi yok; ileride |
| `label_printer` | Etiket Yazıcı (ZPL) | Placeholder | Müşteri talebi yok; ZPL ayrı ESC/POS'tan |

### Bildirimler (4)

| ID | İsim | Real/Placeholder | Sebep |
|---|---|---|---|
| `email` | E-posta (SMTP) | Placeholder | Backend gönderim servisi yok; UI iskelet hazır olsun |
| `sms` | SMS (Netgsm/Twilio) | Placeholder | Provider entegrasyonu yok; UI iskelet hazır olsun |
| `push` | Mobil Push (FCM) | Placeholder | Mobile build yok; ileride |
| `low_stock_alert` | Stok Uyarıları | Placeholder | Backend trigger var ama UI hookup yok |

## Sprint 19 Kuralı Uyumu

> *"Gerçek tüketici talebi olmadan template/feature inşa etme."*

**Hub iskeleti** = UX foundation, talep var (kullanıcı bu turn'de istedi).
**Email/SMS gerçek backend** = talep yok → placeholder ekran (UI hazır, backend gelince hookup).

DashboardScreenTemplate hatası (Sprint 20'de emekli) tekrarlanmamalı — placeholder ekran inşa etmek farklı, **gerçek backend** inşa etmek farklı.

## Sources

- [`settings_screen.dart`](project_pos/lib/features/settings/screens/settings_screen.dart) — mevcut dağınık tab yapısı
- [`print_settings.dart`](project_pos/lib/services/print/print_settings.dart) — Sprint 22'den hazır provider
- [`pending-work-status-2026-04-26.md`](syntheses/pending-work-status-2026-04-26.md) — P3.5/P3.6 placeholder backlog'lar
- Endüstri referansı: Square/Shopify/IKAS POS hardware hub paternleri (developer docs)

## Related

- [[syntheses/integrations-hub-architecture]] — Sprint 23 mimari sentezi (bu audit'in çıktısı)
- [[log]] — Sprint 22 (printer) + Sprint 23 (hub) entries
