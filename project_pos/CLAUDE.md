# CLAUDE.md — project_pos (Flutter POS Uygulaması)

Genel kurallar ve multi-tenant zorunlulukları için kök `CLAUDE.md`'e bak.  
**Base URL:** localhost:8080 (api-manager gateway üzerinden)

---

## 1. MİMARİ — FEATURE-FIRST

`lib/` klasörü üç katmana ayrılmıştır:

```
lib/
├── core/           ← Altyapı — sıfır business logic
├── shared/         ← 3+ feature kullanan cross-cutting concerns
└── features/       ← Her business domain kendi klasöründe
```

### 1a. core/ — Altyapı Katmanı

```
lib/core/
├── api/
│   └── api_client.dart          # Dio + apiClientProvider (tüm servisler buradan inject alır)
├── config/
│   └── sector_config.dart       # SectorConfig, SectorType, sectorConfigProvider
├── constants/
│   └── app_constants.dart
├── di/
│   └── service_locator.dart     # Aggregator — feature DI dosyalarını re-export eder
├── layouts/
│   ├── adaptive_bottom_nav.dart
│   ├── adaptive_sidebar.dart
│   ├── responsive_layout.dart
│   └── right_menu_drawer.dart
├── router/
│   └── app_router.dart          # GoRouter — routerProvider
├── theme/
│   ├── app_colors.dart          # Tüm renkler buradan — direkt Color() yasak
│   ├── app_theme.dart
│   └── app_gradients.dart
├── utils/
│   ├── i18n_helper.dart         # i18nOf(ref) → t('key')
│   ├── validation_helper.dart
│   ├── app_logger.dart
│   └── responsive.dart
└── widgets/                     # Tasarım sistemi
    ├── app_*.dart               # AppButton, AppCard, AppToast, AppInput...
    ├── section_header.dart      # Bölüm başlığı widget
    ├── stat_card.dart           # İstatistik kartı widget
    └── widgets.dart             # Barrel export — TÜM widget'ları buradan import et
```

### 1b. shared/ — Paylaşılan Katman

```
lib/shared/
├── models/
│   ├── auth_state.dart          # AuthState
│   ├── user_model.dart          # User (JWT'den parse)
│   └── menu_models.dart         # MenuItem, MenuCategory
├── providers/
│   ├── auth_provider.dart       # AuthNotifier — JWT parse, login/logout
│   ├── i18n_provider.dart       # i18nProvider
│   ├── menu_provider.dart       # menuProvider
│   ├── navigation_provider.dart
│   ├── sector_provider.dart     # sectorConfigProvider
│   └── theme_provider.dart
└── services/
    ├── auth_service.dart
    ├── i18n_service.dart
    ├── menu_service.dart
    └── registration_service.dart
```

### 1c. features/ — Business Katmanı (20 Feature)

```
lib/features/
├── auth/               login, company registration
├── dashboard/          modern_dashboard
├── menu/               menu_screen
├── pos/                POS satış — providers/, widgets/ alt yapısı var
├── inventory/          Ürün, barkod, marka, birim
│   ├── di/             inventory_di.dart (productServiceProvider vs.)
│   ├── services/       product, brand, unit, category, company_category
│   ├── screens/
│   │   ├── add_product/   ← Wizard (CLAUDE.md, models/, steps/, widgets/ alt yapısı KORUNUR)
│   │   └── batch_entry/   ← Batch (CLAUDE.md, models/, providers/, widgets/ KORUNUR)
│   └── widgets/        quick_add_product_modal.dart
├── catalog/            Kategori yönetimi (category, company_category ekranları)
├── stock/              Stok, transfer, sayım, hareketler
│   ├── models/         stock_management_models.dart
│   └── services/       stock_service, stock_report_service
├── sales/              Satış listesi, detay, iade
├── purchases/          Alım listesi, detay, iade
├── suppliers/          Tedarikçi + upload/ (supplier_upload merge edildi)
│   └── models/         supplier_document, supplier_upload_* modelleri
├── customers/          Müşteri, cari hesap
├── accounts/           Hesap ekstresi, gecikmiş takip
├── finance/            Gider, gelir, nakit akışı
├── reports/            Satış, kâr, ürün analizleri
├── import/             Toplu veri aktarımı (bulk_import + scanner merge)
│   └── models/         backend_product_import, bulk_import_models
├── autoparts/          OEM, çapraz ref, araç uyumu, parça arama
│   └── services/       oem, cross_reference, vehicle, part_search
├── warehouse/          Depo yönetimi
├── store/              Mağaza yönetimi
├── hrm/                Çalışan yönetimi
└── settings/           Ayarlar, profil, kullanıcı yönetimi, admin panel
```

---

## 2. FEATURE KLASÖRÜ KURALLARI

Her feature klasörü aşağıdaki standart yapıyı takip eder:

```
features/<name>/
├── di/<name>_di.dart     → Provider<XService> tanımları BURADA. Logic yok.
├── models/               → Bu feature'a özgü data class'lar. Başka feature import ETMEZ.
├── providers/            → StateNotifier'lar. autoDispose ZORUNLU.
├── services/             → ApiClient constructor inject. Riverpod import etmez.
├── screens/              → ConsumerStatefulWidget ekranlar
└── widgets/              → 2+ screen tarafından kullanılan widget'lar
```

**Yasaklar:**
```dart
// ❌ Feature-A bir Feature-B dosyasını direkt import etmez
import 'package:project_pos/features/inventory/services/product_service.dart'; // POS'tan yapma

// ✅ Cross-feature paylaşım → shared/ veya DI üzerinden
import 'package:project_pos/core/di/service_locator.dart'; // provider alır
import 'package:project_pos/shared/providers/auth_provider.dart'; // shared'dan alır

// ❌ Servisi direkt new'leme YASAK
final service = ProductService(ApiClient()); // initState içinde YAPMA

// ✅ Her zaman DI'dan
final service = ref.read(productServiceProvider);
```

---

## 3. DI (DEPENDENCY INJECTION) YAPISI

```dart
// core/api/api_client.dart — apiClientProvider burada tanımlı
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

// features/inventory/di/inventory_di.dart
final productServiceProvider = Provider<ProductService>(
  (ref) => ProductService(ref.watch(apiClientProvider)),
);
final brandServiceProvider = Provider<BrandService>(
  (ref) => BrandService(ref.watch(apiClientProvider)),
);

// core/di/service_locator.dart — SADECE aggregator (tanım yok, re-export)
export 'package:project_pos/features/inventory/di/inventory_di.dart';
export 'package:project_pos/features/sales/di/sales_di.dart';
// ...

// Her ekranda:
import 'package:project_pos/core/di/service_locator.dart'; // tek import
// sonra ref.read(productServiceProvider) kullan
```

**Eski `lib/services/service_locator.dart` ve `lib/services/*.dart` dosyaları:**  
Backward compat için re-export shim olarak kaldı. Yeni kod bu eski path'lere import EKLEMEMELI.

---

## 4. STATE MANAGEMENT — RİVERPOD

**Kural:** Her feature için ayrı `StateNotifier` + `autoDispose`.

```dart
// State modeli
class MyState {
  final List<Map<String,dynamic>> items;
  final bool isLoading;
  final String? error;
  const MyState({this.items = const [], this.isLoading = false, this.error});

  MyState copyWith({
    List<Map<String,dynamic>>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => MyState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );
}

// Notifier
class MyNotifier extends StateNotifier<MyState> {
  MyNotifier(this._ref) : super(const MyState());
  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _ref.read(myServiceProvider).getItems();
      state = state.copyWith(items: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Provider — features/<name>/di/<name>_di.dart içinde tanımla
final myProvider = StateNotifierProvider.autoDispose<MyNotifier, MyState>(
  (ref) => MyNotifier(ref),
);
```

---

## 5. TENANT KONFİGÜRASYON

```
Login → JWT alınır → payload parse edilir → User nesnesi oluşturulur
User.selectedCompanyCode → ApiClient interceptor → X-Company-Code header
```

**JWT Parse (AuthNotifier içinde — shared/providers/auth_provider.dart):**
```dart
final payload      = jwtDecode(token);
final sessionStr   = payload['sessionInstance'] as String;
final session      = jsonDecode(sessionStr);
final userInfo     = session['userInformation'];

// JWT alan adları TOpenLoginUser Java field adlarından gelir (Gson — getter değil field kullanır)
User(
  id:                   userInfo['userId'] as String? ?? userInfo['id'] as String? ?? '',
  username:             userInfo['userName'] as String? ?? '',  // ← 'username' değil 'userName'
  displayName:          userInfo['displayName'] as String? ?? '',  // ← fullName DEĞİL
  selectedCompanyCode:  userInfo['selectedCompanyCode'] as String? ?? '',  // ← 'companyCode' değil
  languageVal:          userInfo['languageVal'] as String? ?? 'tr',
  // roles: [{roleName: "ADMIN"}] formatında — e.toString() YANLIŞ → e['roleName'] kullan
  roles: (session['roles'] as List?)
      ?.map((e) => (e as Map)['roleName'] as String? ?? e.toString())
      .toList() ?? [],
  storeId:              userInfo['dynamicLoginParameters']?['storeId'] as String?,
  sectorType:           userInfo['dynamicLoginParameters']?['sectorType'] as String?,
)

// ⚠️ sessionId null-safe — backend her zaman set etmez
final sessionId = payload['sessionId'] as String? ?? '';  // as String → TypeError riski!
```

---

## 6. KULLANILAN PAKETLER

```yaml
flutter_riverpod: "^2.6.1"   # State management
go_router: "^14.8.1"          # Navigation + deep link
dio: "^5.x"                   # HTTP client
sqflite: "^2.x"               # Yerel DB (offline destek)
fl_chart: "^0.68.0"           # Grafik (Line, Bar, Pie)
mobile_scanner: "^3.5.7"      # Barkod okuma
intl: "^0.19.x"               # Tarih/para (tr_TR locale)
shared_preferences: "^2.x"    # Token saklama
google_fonts: "^6.x"          # Tipografi
file_picker: "^8.x"           # PDF / dosya seçimi
```

---

## 7. EKRAN ŞABLONU

```dart
class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = i18nOf(ref);
    final state = ref.watch(myProvider);

    return AppScaffold(
      appBar: AppAppBar.standard(title: t('menu.my_screen')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? AppEmptyState.error(title: t('common.error'), description: state.error!)
              : state.items.isEmpty
                  ? AppEmptyState.noData(title: t('common.no_data'))
                  : _buildContent(state, t),
    );
  }
}
```

---

## 8. SERVİS ŞABLONU

```dart
// lib/features/<name>/services/my_service.dart
class MyService {
  final ApiClient _apiClient;
  MyService(this._apiClient);  // Constructor inject — direkt new'leme YASAK

  Future<List<Map<String,dynamic>>> getItems() async {
    try {
      final res = await _apiClient.get('product/api/v1/my-resource');
      return List<Map<String,dynamic>>.from(res.data['data'] ?? []);
    } catch (e) {
      debugPrint('MyService.getItems hata: $e');
      rethrow;
    }
  }
}

// lib/features/<name>/di/<name>_di.dart'a ekle:
final myServiceProvider = Provider<MyService>(
  (ref) => MyService(ref.watch(apiClientProvider)),
);
```

---

## 8a. BATCH ÜRÜN GİRİŞİ — SERVİS VE PROVIDER

```dart
// lib/features/inventory/services/product_service.dart
Future<Map<String, dynamic>> batchCreate(Map<String, dynamic> request) async {
  try {
    final response = await _apiClient.post(
      'product/api/v1/products/batch',
      data: request,
    );
    return (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  } catch (e) {
    debugPrint('ProductService.batchCreate hata: $e');
    rethrow;
  }
}
```

`batch_entry/` klasörü (`features/inventory/screens/batch_entry/`) kendi CLAUDE.md, models/, providers/, widgets/ alt yapısını korur.

---

## 9. ROUTER

```dart
// lib/core/router/app_router.dart — routerProvider (GoRouter)
// Yeni route eklemek:
GoRoute(
  path: '/my-screen',
  builder: (ctx, state) => const MyScreen(),
  // import: package:project_pos/features/<name>/screens/my_screen.dart
),

// Navigasyon:
context.go('/my-screen');
context.push('/my-screen');
context.pop();
```

---

## 10. TASARIM SİSTEMİ

```dart
// Layout
AppScaffold(body: ..., appBar: ...)    // Scaffold KULLANMA
AppAppBar.standard(title: t('...'))    // title = String, Text() sarma

// Butonlar
AppButton.primary(text: t('common.save'), onPressed: () {})
AppButton.outline(text: t('common.cancel'), onPressed: () {})
AppButton.danger(text: t('common.delete'), onPressed: () {})
AppButton.success(text: t('common.confirm'), onPressed: () {})

// Geri bildirim
AppToast.success(context, t('common.saved'))
AppToast.error(context, t('common.error'))
AppConfirmationDialog.show(context: context, title: '...', onConfirm: () {})

// İçerik
AppCard(child: ...)
AppEmptyState.noData(title: t('common.no_data'))
AppEmptyState.error(title: t('common.error'), description: _error!)
AppBadge(text: '...', color: AppColors.success)
AppInput(label: '...', controller: _ctrl, validator: ...)

// Ortak widgetlar (core/widgets/ barrel'ından import et)
SectionHeader(title: '...', subtitle: '...')  // Bölüm başlığı
StatCard(title: '...', value: '...', icon: ...) // İstatistik kartı
```

**Renkler — sadece AppColors kullan:**
```dart
AppColors.primary / success / warning / danger / info
AppColors.orange / pink                      // Sektör aksanları
AppColors.textPrimary / textSecondary / textMuted
AppColors.bgLight / border

// ❌ Colors.blue, Colors.grey, Colors.red — YASAK (Colors.white hariç)
// ❌ .withOpacity(0.1)  →  .withValues(alpha: 0.1) kullan
```

---

## 11. i18n — ZORUNLU

```dart
// Kullanım
final t = i18nOf(ref);
Text(t('common.save'))
AppToast.success(context, t('common.saved'))

// ❌ Hardcode Türkçe metin YASAK
// ✅ t('key') her zaman
```

**Her yeni ekranda data.sql'e anahtar eklenmeli** (bkz. kök CLAUDE.md §11 ve project_pos CLAUDE.md §11a).

---

## 11a. i18n KAYIT ZORUNLULUĞU

**Her yeni ekran tasarlandığında:**
1. Ekrandaki tüm `t('prefix.key')` anahtarlarını listele
2. `security/src/main/resources/data.sql`'e ekle (INSERT INTO bloğu içine)
3. security servisini restart et

**Kayıt formatı:**
```sql
('bnd-XX000-0000-0000-NNNNNNNNNNNN', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
 'prefix.key', 'Türkçe Metin', 'English Text'),
```

**Modül prefix kodları:**
```
bt=batch, wz=wizard, pd=product, st=stock, sl=sale, pu=purchase
cu=customer, su=supplier, rp=report, fn=finance, se=settings
au=auth, cm=common, db=dashboard
```

---

## 12. YENİ FEATURE EKLEME AKIŞI

```
1. features/<name>/ klasörünü oluştur
2. di/<name>_di.dart — Provider tanımları
3. services/<name>_service.dart — ApiClient inject
4. models/ — feature'a özgü data class'lar (cross-feature ise shared/'a)
5. providers/<name>_provider.dart — StateNotifier (gerekirse)
6. screens/<name>_screen.dart — ConsumerStatefulWidget
7. core/di/service_locator.dart'a DI export ekle
8. core/router/app_router.dart'a GoRoute ekle
9. data.sql'e i18n anahtarları ekle
```

---

## 13. DARK MODE

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
// ❌ color: Colors.white  (hardcode)
// ✅ color: isDark ? const Color(0xFF1A1A2E) : Colors.white
```

---

## 14. SIK YAPILAN HATALAR

> **URL prefix kuralı:** Backend controller `/api/...` yazar, Flutter `security/api/...` veya `product/api/...` şeklinde service prefix ekler.  
> Tüm istekler api-manager (8080) üzerinden geçer — direkt 8001/8002 kullanılmaz.

| Hata | Çözüm |
|------|-------|
| `'api/v1/stores'` gibi prefix'siz URL | `'product/api/v1/stores'` — service prefix zorunlu |
| `'http://localhost:8001/api/...'` | `'product/api/...'` — direkt port kullanılmaz |
| `'http://localhost:8002/api/...'` | `'security/api/...'` — direkt port kullanılmaz |
| `Scaffold(...)` | `AppScaffold(...)` kullan |
| `AppAppBar(title: Text('...'))` | `title` String alır |
| `.withOpacity(0.1)` | `.withValues(alpha: 0.1)` |
| `GestureDetector` + Container | `Material + InkWell` |
| `Colors.blue` | `AppColors.info` |
| `user.fullName` | `user.displayName` |
| `response.data['items']` | `response.data['data']` |
| Hardcode Türkçe metin | `t('key')` |
| Provider `dispose` unutmak | `autoDispose` kullan |
| `XService(ApiClient())` new'leme | `ref.read(xServiceProvider)` kullan |
| Feature-A → Feature-B import | Yalnızca `shared/` veya DI üzerinden |
| `lib/services/` servis import | `features/<name>/services/` veya `core/di/service_locator.dart` |
| `lib/screens/` ekran import | `features/<name>/screens/` kullan |
| `lib/providers/` provider import | `shared/providers/` kullan |
| Sektör string hardcode `'genel'` | `sectorType.apiValue` → `'GENERAL'` |
| Birim default farklı | Her yerde `'adet'` kullan |
| `user_service.dart` base path yanlış | `_base = 'security/api/users'` (v1 yok!) |
| `available-roles` URL yanlış | `security/api/users/available-roles` |
| `assignRole` body'si yanlış | `{'roleCode': roleCode}` — `roleId` değil |
| `userInfo['id']` okumak | JWT'de alan `userId` — `userInfo['userId']` |
| `userInfo['username']` okumak | JWT'de alan `userName` (camelCase U büyük) |
| `userInfo['companyCode']` okumak | JWT'de alan `selectedCompanyCode` — Gson field adı |
| `payload['sessionId'] as String` | `sessionId` null olabilir → `as String? ?? ''` kullan |
| `session['roles'].map((e) => e.toString())` | Roller `{roleName: ADMIN}` map → `e['roleName']` oku |
| Refresh URL yanlış | `security/api/v1/auth/refresh-token` — eski `security/refresh` değil |

---

## KULLANICI YÖNETİMİ — SERVİS PATH'LERİ (2026-04-13)

```dart
// user_service.dart — doğru base path'ler:
static const _base = 'security/api/users';          // ✅  (v1 yok)
static const _rolesBase = 'security/api/users/available-roles';

// getAllUsers → GET security/api/users  (header: X-Company-Code)
// createUser  → POST security/api/users
// assignRole  → POST security/api/users/{id}/roles  body: {'roleCode': roleCode}
// removeRole  → DELETE security/api/users/{id}/roles/{roleCode}
// resetPassword → POST security/api/users/{id}/reset-password body: {'newPassword': pw}
```

**Kullanıcı modeli alan adları:**
```dart
// ✅ DOĞRU
user.userName        // kullanıcı adı (giriş için)
user.displayName     // görünen ad
user.roles           // List<String> — ['ADMIN', 'CASHIER']
user.storeId         // nullable

// ❌ YANLIŞ
user.email  user.name  user.username  user.fullName
```
