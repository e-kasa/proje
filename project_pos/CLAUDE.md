---
module: project_pos
type: Flutter POS Application
base-url: localhost:8080  (api-manager gateway)
state-management: Riverpod 2.x StateNotifier
navigation: GoRouter
depends-on: [api-manager, security, pos-product-manager]
touch-when: [new-feature, screen, widget, i18n, router, auth, batch-entry, wizard]
last-verified: 2026-04-16
---

# CLAUDE.md — project_pos (Flutter)

Genel kurallar: kök `CLAUDE.md`.  
URL kuralı: `.claude/reference/url-routing.md`. API zarfı: `.claude/reference/api-response.md`.  
JWT parse: `.claude/reference/jwt-payload.md`. Sektör: `.claude/reference/sector-strings.md`.  
Yeni feature: `.claude/runbooks/new-feature-flutter.md`.

---

## Mimari — Feature-First

```
lib/
├── core/       → Altyapı (api, config, di, router, theme, widgets, utils)
├── shared/     → Cross-feature (auth/i18n/menu providers, services, models)
└── features/   → 20 business domain
```

### features/ Klasörleri

```
auth, dashboard, menu, pos
inventory (add_product wizard + batch_entry)
catalog, stock, sales, purchases
suppliers (upload/ merge), customers, accounts
finance, reports, import (bulk + scanner merge)
autoparts (OEM/araç/parça arama)
warehouse, store, hrm, settings
```

### core/ Özet

```
core/api/api_client.dart           # apiClientProvider — tüm servisler buradan
core/di/service_locator.dart       # Aggregator, re-export only
core/router/app_router.dart        # GoRouter routerProvider
core/theme/app_colors.dart         # Tüm renkler — direkt Color() YASAK
core/widgets/                      # AppScaffold, AppButton, AppCard, AppToast...
core/utils/i18n_helper.dart        # i18nOf(ref) → t('key')
```

### shared/ Özet

```
shared/providers/auth_provider.dart    # AuthNotifier — JWT parse, login/logout
shared/providers/i18n_provider.dart
shared/providers/menu_provider.dart
shared/providers/sector_provider.dart  # sectorConfigProvider
shared/models/                         # User, AuthState, MenuItem
shared/services/                       # auth, i18n, menu, registration
```

---

## Feature Klasör Kuralları

```
features/<name>/
├── di/<name>_di.dart     → Provider tanımları. Logic YOK.
├── models/               → Data class'lar. Başka feature import ETMEZ.
├── providers/            → StateNotifier. autoDispose ZORUNLU.
├── services/             → ApiClient constructor inject. Riverpod import etmez.
├── screens/              → ConsumerStatefulWidget
└── widgets/              → 2+ screen kullanan widget'lar
```

**Yasaklar:**
- Feature-A → Feature-B direkt import (sadece `shared/` veya DI)
- `XService(ApiClient())` new'leme (her zaman DI)

Detaylı şablon: `.claude/runbooks/new-feature-flutter.md`.

---

## Tenant Konfigürasyon

```
Login → JWT → User parse → ApiClient interceptor → X-Company-Code header
```

JWT parse detayı: `.claude/reference/jwt-payload.md`.

---

## Tasarım Sistemi

```dart
// Layout
AppScaffold(body: ..., appBar: ...)            // Scaffold YASAK
AppAppBar.standard(title: t('...'))             // title = String

// Butonlar
AppButton.primary / .outline / .danger / .success

// Geri bildirim
AppToast.success(context, t('common.saved'))
AppConfirmationDialog.show(...)

// İçerik
AppCard, AppEmptyState.noData, AppEmptyState.error, AppBadge, AppInput

// Ortak
SectionHeader, StatCard
```

**Renkler — sadece `AppColors`:**
- `primary / success / warning / danger / info / orange / pink`
- `textPrimary / textSecondary / textMuted / bgLight / border`
- Yasak: `Colors.blue`, `Colors.grey`, `Colors.red` (Colors.white hariç)
- `.withOpacity(0.1)` → `.withValues(alpha: 0.1)`

---

## i18n

- `i18nOf(ref)` → `t('key')` — tüm metinler zorunlu
- Yeni ekran → `security/data.sql`'e anahtar ekle
- ID format: `bnd-XX000-0000-0000-NNNNNNNNNNNN`
- Modül prefix: `bt, wz, pd, st, sl, pu, cu, su, rp, fn, se, au, cm, db`

### i18n Kritik Hatalar

```dart
// ❌ const içinde t() — derleme hatası
const Expanded(child: Column(children: [Text(t('nav.app_name'))]))

// ✅ const kaldır
Expanded(child: Column(children: [Text(t('nav.app_name'), style: const TextStyle(...))]))

// ❌ Private method içinde t tanımlı değil
Widget _buildHeader() { return Text(t('nav.title')); }

// ✅ Parametre geç
Widget _buildHeader(String Function(String) t) { return Text(t('nav.title')); }
```

---

## Lokasyon Mimarisi (2026-04-13)

Eski `storeId + warehouseId` kaldırıldı. Tek alan:

```dart
'locationId':   'STORE-01'    // Store.code veya Warehouse.code
'locationType': 'STORE'       // 'STORE' | 'WAREHOUSE'
```

Detay: `.claude/decisions/2026-04-13-location-id-unification.md`.

**Karıştırma — `User.storeId` farklı:**
```dart
final jwtStoreId = ref.read(authProvider).user?.storeId;  // kasiyerin mağazası — DEĞİŞMEDİ
'locationId': state.activeLocationId                       // stok hareket lokasyonu — yeni
```

---

## Aktif Router Path'leri — ÖNEMLİ

Router hâlâ `lib/screens/` path'ini kullanıyor (migration sprint 3'te):

```dart
import 'package:project_pos/screens/inventory/add_product/add_product_wizard_screen.dart';
import 'package:project_pos/screens/inventory/batch_entry/batch_product_screen.dart';
```

**Değişiklik yaparken** `lib/screens/inventory/` düzenlenir, `lib/features/inventory/` değil.

POS ekranı `features/` altında: `features/pos/screens/pos_screen.dart`. `lib/screens/pos/` → dead code.

---

## Kullanılan Paketler

```yaml
flutter_riverpod: ^2.6.1   go_router: ^14.8.1   dio: ^5.x
sqflite: ^2.x   fl_chart: ^0.68.0   mobile_scanner: ^3.5.7
intl: ^0.19.x   shared_preferences: ^2.x   google_fonts: ^6.x   file_picker: ^8.x
```

---

## Kullanıcı Yönetimi Servis Path'leri

```dart
static const _base = 'security/api/users';               // v1 YOK
static const _rolesBase = 'security/api/users/available-roles';

// assignRole body: {'roleCode': roleCode}  — 'roleId' değil
```

Kullanıcı modeli: `userName, displayName, roles (List<String>), storeId`.

---

## Sık Yapılan Hatalar

| Hata | Çözüm |
|------|-------|
| `api/v1/stores` prefix'siz | `product/api/v1/stores` |
| `http://localhost:8001/...` | `product/...` (gateway) |
| `Scaffold(...)` | `AppScaffold(...)` |
| `AppAppBar(title: Text(...))` | `title` String alır |
| `Colors.blue` | `AppColors.info` |
| `.withOpacity(0.1)` | `.withValues(alpha: 0.1)` |
| `response.data['items']` | `response.data['data']` |
| Hardcode Türkçe | `t('key')` |
| `XService(ApiClient())` | `ref.read(xServiceProvider)` |
| Provider `dispose` | `autoDispose` |
| Feature-A → Feature-B direkt import | `shared/` veya DI |
| `lib/services/` import | `features/<name>/services/` |
| `user.fullName` | `user.displayName` |
| `userInfo['id']` | `userInfo['userId']` |
| `userInfo['username']` | `userInfo['userName']` |
| `userInfo['companyCode']` | `userInfo['selectedCompanyCode']` |
| `payload['sessionId'] as String` | `as String? ?? ''` |
| `e.toString()` roller için | `(e as Map)['roleName']` |
| Refresh URL | `security/api/v1/auth/refresh-token` |
| `'storeId'` payload | `locationId + locationType` |
| `state.activeStoreId` | `state.activeLocationId` |
| `const Column([Text(t(...))])` | `const` kaldır |
| `lib/features/inventory/` düzenlemek (wizard/batch için) | Router `lib/screens/` kullanıyor |
| `'sector': 'parcaci'` | `sectorType.apiValue` → `'AUTO_PARTS'` |
| Birim default `'pcs'` | `'adet'` standart |
