---
title: i18n Bundle Key Naming Strategy (Sprint 24)
tags: [synthesis, i18n, bundle, naming, sprint-24]
source: project_pos/lib/features/**/screens/ + security/src/main/resources/data.sql
date: 2026-05-01
status: draft
---

# i18n Bundle Key Naming Strategy

Sprint 24'te 86 yeni bundle key eklenirken belirgin bir naming pattern lazım — gelecekte yeni feature'lar bu kuralları izlesin. Audit: [[sources/code-refs/2026-05-01-printer-integrations-i18n-audit]].

## Mevcut Bundle Yapısı

`security/src/main/resources/data.sql` `ext_bundles` tablosu:

```sql
INSERT INTO ext_bundles (id, ..., bundle_code, bundle_message_tr, bundle_message_en) VALUES
('bnd-i029-...', ..., 'inventory.products', 'Ürünler', 'Products');
```

Mevcut prefix dağılımı (audit edildi):

| Prefix | Modül | Key sayısı |
|---|---|---|
| `bnd-i*` | inventory | 73 |
| `bnd-bt*`, `bnd-pd*` | batch + product details | 216 / 216 |
| `bnd-s*`, `bnd-sl*`, `bnd-sm*`, `bnd-st*` | sales (multi-prefix) | 112 / 51 / 25 / 28 |
| `bnd-c*` | common | 65 |
| `bnd-actx*`, `bnd-actxf*`, `bnd-actxg*`, `bnd-acfrm*`, `bnd-acpa*`, `bnd-ac*` | accounts (multi-prefix) | 15 + 5 + 3 + 15 + 7 + 6 |
| `bnd-vh*` | vehicle (autoparts) | 11 |
| `bnd-a*` | auth | 13 |
| `bnd-f*`, `bnd-fn*` | finance | 23 + 29 |
| `bnd-p*`, `bnd-pr*`, `bnd-ps*`, `bnd-pt*`, `bnd-pu*` | pos + purchase + ... | 46+6+3+6+4 |
| `bnd-r*`, `bnd-rp*` | reports | 11 + 6 |
| `bnd-d*` | dashboard | 6 |
| `bnd-hr*` | hrm | 2 |
| `bnd-cm*`, `bnd-cs*`, `bnd-cf*` | catalog/customer/... | 7/5/4 |
| `bnd-bi*` | bulk import | 3 |
| `bnd-m*`, `bnd-n*` | menu / notification | 12 + 7 |
| `bnd-is*`, `bnd-v*`, `bnd-vl*`, `bnd-ws*`, `bnd-wz*` | misc | 3+9+1+4+12 |
| `bnd-slpay*` | sale-payment | 10 |
| `bnd-cx*` | common-extra | (Sprint 22+) |

**Toplam ~1100 bundle key** (sayım yaklaşık).

## Tespit Edilen Sorunlar (Mevcut)

1. **Prefix tutarsızlığı**: `bnd-s*`, `bnd-sl*`, `bnd-sm*`, `bnd-st*` hepsi sales modülü farklı submodül'ler. Yeni gelen ekliyor → çakışma riski.
2. **Akronim okunmazlık**: `bnd-actxg`, `bnd-bi`, `bnd-pd` — anlamak için kod okumak gerek.
3. **Length ihlal**: `bnd-actxg-XX-...` 5+ karakter prefix; bazıları 1 karakter (`bnd-a*`, `bnd-c*`).

## Sprint 24 Yeni Naming Strateji

### Bundle Code (Flutter `t('...')` argümanı)

**Format:** `<feature>.<key>` veya `<feature>.<sub_feature>.<key>`

```dart
t('printer.scan_usb_devices')           // ✅ feature + key
t('email_settings.smtp_section')        // ✅ feature + key (snake_case)
t('integrations.category_hardware')     // ✅ feature + key
t('common.save')                        // ✅ shared (reuse mevcut)
```

**Kurallar:**
- snake_case (Dart `t('...')` argümanı için)
- Feature name **tam yazılır** (kısaltma yok): `printer` not `prn`, `email_settings` not `eml_set`
- Sub-feature opsiyonel: `email_settings.smtp.host_label` veya `email_settings.host_label` — Sprint 24'te 3 seviye derinleşmedi (ekran sayısı az)
- Common (`common.*`) **kesinlikle reuse**: yeni `common.save` ekleme — mevcut var

### Bundle ID (data.sql primary key)

**Format:** `bnd-<3-letter-prefix><nnn>-0000-0000-0000-<12-digit>`

**Yeni prefix'ler:**
- 3 karakterlik kısaltma (mevcut paterne uyum + okunabilirlik)
- Çakışma yok (audit'te kontrol edildi)

| Sprint 24 yeni prefix | Anlamı |
|---|---|
| `bnd-prn` | printer |
| `bnd-itg` | integrations (hub) |
| `bnd-eml` | email_settings |
| `bnd-sms` | sms_settings |

**Sequential numbering:** her prefix kendi `nnn` namespace'i (001-999):
```sql
('bnd-prn001-0000-...', ..., 'printer.title', 'Yazıcı Ayarları', 'Printer Settings'),
('bnd-prn002-0000-...', ..., 'printer.connected_printer', 'Bağlı Yazıcı', 'Connected Printer'),
...
```

### Bundle Değer Stratejisi

| Alan | Kural | Örnek |
|---|---|---|
| `bundle_message_tr` | **Türkçe karakterli** (UI render için) | `'Yazıcı Ayarları'`, `'Kağıt Genişliği'` |
| `bundle_message_en` | Doğal İngilizce | `'Printer Settings'` |

**Türkçe karakter notu:** Sprint 22'de `printer_settings_screen` hardcoded TR'ler **ASCII** idi (`Yazici` not `Yazıcı`). Sebep: POSA termal yazıcı `_ascii()` çevirmesi yapıyordu — kod yazarı UI'da da ASCII koymuş. **Yanlış.**

UI render Türkçe karakter destekler (Flutter'ın default font + Android/Windows). ASCII'ye çevirmek **sadece print path'inde** olmalı (`ReceiptTemplate._ascii()` mevcut, korunur). Sprint 24 cleanup: bundle TR değerleri Türkçe karakterli yazılır.

### Parametre Substitution

Bazı string'lerde dinamik değer var:
- `'Yazici secildi: ${d.displayName}'` → `'Yazıcı seçildi: {0}'` (placeholder)
- `'Bulunan Cihazlar (${_devices.length})'` → `'Bulunan Cihazlar ({0})'`

Mevcut `i18n_helper.dart` API:
```dart
t('printer.device_selected', {'name': device.displayName})
// veya:
t('printer.device_selected').replaceAll('{name}', device.displayName)
```

**Karar:** `replaceAll('{0}', value)` paterni — basit, mevcut kodda da var. Kompleks pluralization Sprint 25+ scope'unda (ICU MessageFormat ihtiyacı doğarsa).

## Kararlar Özeti (Sprint 24)

1. **Yeni 4 prefix:** `bnd-prn`, `bnd-itg`, `bnd-eml`, `bnd-sms` — 3 karakter, çakışma yok
2. **86 yeni key:** `printer.*` (29), `integrations.*` (10), `email_settings.*` (22), `sms_settings.*` (25)
3. **Common reuse:** `common.save`, `common.close`, `common.cancel`, `common.delete`, `common.coming_soon`
4. **Bundle değerler Türkçe karakterli** (UI için), ASCII çevirimi sadece `ReceiptTemplate._ascii()`'de kalır
5. **`integrations_provider.dart` catalog name+description hardcoded kalır** (`const` constructor constraint, 18 küçük string, mimaride extension noktası `IntegrationDef` ekleme — i18n key avantajı düşük)
6. **Parametreli string'ler `{0}` placeholder + `replaceAll`** (basic substitution; ICU Sprint 25+)

## Extension Noktaları

Yeni feature i18n eklerken:

1. Audit dosyası: `sources/code-refs/<tarih>-<feature>-i18n-audit.md` — hardcoded string envanteri
2. Bundle prefix seç: 3 karakter, mevcut prefix'lerle çakışmasın (`grep "bnd-XXX" data.sql`)
3. Mantıksal namespace: `<feature>.<key>` veya `<feature>.<sub>.<key>`
4. Common reuse: `common.save/cancel/delete/close/coming_soon` zaten var
5. data.sql'a `INSERT INTO ext_bundles ... ON CONFLICT DO NOTHING` (idempotent)
6. Flutter dosyada `final t = i18nOf(ref);` + `t('feature.key')`

## Riskler

- **Bundle çakışma**: yeni prefix önceden var → `grep` zorunlu (audit kontrolü).
- **Türkçe karakter sorunu**: Bundle TR değerleri UTF-8 kayıtlı, MySQL/PostgreSQL `utf8mb4` collation gerek (zaten standart).
- **Parametreli string'lerin EN/TR placeholder konum farkı**: `{0}` numerik index farklı dilde farklı pozisyonda olabilir. Sprint 24'te basit (suffix only), Sprint 25+'da ICU.
- **Print path TR karakter regression**: `ReceiptTemplate._ascii()` korunmalı; bundle TR değişikliği ESC/POS print path'ini etkilemez (UI render ayrı).

## Verification

- `flutter analyze` 4 dosya: 0 yeni issue
- Manuel smoke (kullanıcı runtime'da):
  1. Settings → Sistem → "Cihazlar & Entegrasyonlar" → Türkçe karakterli başlık görmeli (`Cihazlar & Entegrasyonlar` zaten doğru)
  2. Yazıcı Ayarları açıldığında: AppBar `Yazıcı Ayarları` (yeni TR karakter), section'lar `Bağlı Yazıcı`/`Kağıt Ayarları`/`Davranış`/`Fiş Metni`
  3. EN dil seçilirse: `Printer Settings`, `Connected Printer`, ...

## Sources

- [[sources/code-refs/2026-05-01-printer-integrations-i18n-audit]] — bu sprint'in temeli
- [[syntheses/integrations-hub-architecture]] — Sprint 23 mimari (i18n öncesi durum)
- `security/src/main/resources/data.sql` — bundle storage
- `lib/core/utils/i18n_helper.dart` — `i18nOf(ref)` + `t('...')` API

## Related

- [[log]] — Sprint 24 entry (i18n cleanup)
- Memory: `feedback_wiki_workflow.md` — kullanıcı feedback'i (audit/synthesis/log üçlüsü)
