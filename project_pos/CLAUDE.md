# CLAUDE.md — project_pos (Flutter POS Uygulaması)

Genel kurallar ve multi-tenant zorunlulukları için kök `CLAUDE.md`'e bak.  
**Base URL:** localhost:8080 (api-manager gateway üzerinden)

---

## 1. KLASÖR YAPISI

```
lib/
├── core/
│   ├── api/
│   │   └── api_client.dart          # Dio — JWT interceptor, X-Company-Code, auto-refresh
│   ├── config/
│   │   └── sector_config.dart       # Sektör bazlı alan görünürlüğü (SectorConfig, SectorType)
│   ├── constants/
│   │   └── app_constants.dart
│   ├── layouts/
│   │   └── responsive_layout.dart   # Desktop sidebar + mobile bottom nav
│   ├── theme/
│   │   └── app_colors.dart          # Tüm renkler buradan — direkt Color() yasak
│   ├── utils/
│   │   ├── router.dart              # GoRouter — routerProvider
│   │   └── i18n_helper.dart         # i18nOf(ref) → t('key')
│   └── widgets/                     # Tasarım sistemi (AppButton, AppCard, AppToast...)
│       └── widgets.dart             # Barrel export
│
├── models/                          # Dart model sınıfları
│
├── providers/
│   ├── auth_provider.dart           # AuthNotifier, User modeli, JWT parse
│   └── sector_provider.dart         # sectorConfigProvider
│
├── services/
│   └── service_locator.dart         # Tüm Provider tanımları — tek dosya
│
└── screens/                         # 76+ ekran
    ├── auth/                        # login, register
    ├── dashboard/
    ├── pos/                         # POS satış ekranı
    ├── inventory/                   # Ürün yönetimi, toplu giriş, wizard
    │   ├── add_product/             # Adım adım wizard
    │   └── batch_entry/             # Toplu ürün girişi (CLAUDE.md var)
    ├── stock/                       # Stok, transfer, hareketler
    ├── sales/                       # Satış listesi, iade
    ├── purchases/                   # Satın alma
    ├── customers/                   # Müşteri, cari hesap
    ├── suppliers/                   # Tedarikçi
    ├── finance/                     # Giderler
    ├── accounts/                    # Cari hesap ekstresi
    ├── reports/                     # Günlük kapanış, satış analizi
    └── settings/                    # Firma, kullanıcı ayarları
```

---

## 2. STATE MANAGEMENT — RİVERPOD

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

// Provider
final myProvider = StateNotifierProvider.autoDispose<MyNotifier, MyState>(
  (ref) => MyNotifier(ref),
);
```

**Basit, salt-okunur veri için:**
```dart
final myCategoriesProvider = FutureProvider.autoDispose<List<Map<String,dynamic>>>(
  (ref) => ref.read(categoryServiceProvider).getCategories(),
);
```

---

## 3. TENANT KONFİGÜRASYON — NASIL ÇALIŞIR

```
Login → JWT alınır → payload parse edilir → User nesnesi oluşturulur
User.selectedCompanyCode → ApiClient interceptor → X-Company-Code header
```

**JWT Parse (AuthNotifier içinde):**
```dart
final payload      = jwtDecode(token);
final sessionStr   = payload['sessionInstance'] as String;
final session      = jsonDecode(sessionStr);
final userInfo     = session['userInformation'];

User(
  id:                   userInfo['id'],
  username:             userInfo['username'],
  displayName:          userInfo['displayName'],      // ← fullName DEĞİL
  selectedCompanyCode:  userInfo['companyCode'],
  languageVal:          userInfo['languageVal'] ?? 'tr',
  roles:                (session['roles'] as List).map((r) => r['roleName'] as String).toList(),
  storeId:              userInfo['dynamicLoginParameters']?['storeId'],
  sectorType:           userInfo['dynamicLoginParameters']?['sectorType'],
)
```

**Çoklu firma desteği:**
```dart
// Kullanıcı firma değiştirdiğinde:
ref.read(authProvider.notifier).switchCompany(newCompanyCode);
// ApiClient interceptor otomatik güncellenir
```

**Sektör konfigürasyonu:**
```dart
final config = ref.watch(sectorConfigProvider);
// config.type          → SectorType (autoParts / general / technology / footwear)
// config.fields        → SectorFields (hangi alanlar görünür)
// config.labels        → SectorLabels (alan etiketleri)
// config.type.apiValue → backend'e gönderilen string
```

---

## 4. KULLANILAN PAKETLER

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

## 5. EKRAN ŞABLONU

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

## 6. SERVİS ŞABLONU

```dart
class MyService {
  final ApiClient _apiClient;
  MyService(this._apiClient);

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

// service_locator.dart'a ekle:
final myServiceProvider = Provider<MyService>(
  (ref) => MyService(ref.watch(apiClientProvider)),
);
```

---

## 7. TASARIM SİSTEMİ

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

## 8. ROUTER

```dart
// router.dart — routerProvider (GoRouter)
// Yeni route eklemek:
GoRoute(
  path: '/my-screen',
  builder: (ctx, state) => const MyScreen(),
),

// Navigasyon:
context.go('/my-screen');
context.push('/my-screen');
context.pop();
```

---

## 9. i18n — ZORUNLU

```dart
// Kullanım
final t = i18nOf(ref);
Text(t('common.save'))
AppToast.success(context, t('common.saved'))

// ❌ Hardcode Türkçe metin YASAK
// ✅ t('key') her zaman
```

---

## 9a. i18n KAYIT ZORUNLULUĞU — HER EKRAN

**Her yeni ekran veya bileşen tasarlandığında aşağıdakiler ZORUNLUDUR:**

1. Ekrandaki tüm `t('prefix.key')` anahtarları `security/src/main/resources/data.sql`'e kayıt olarak eklenmelidir.
2. Kayıt formatı:
```sql
('bnd-XX000-0000-0000-NNNNNNNNNNNN', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
 'prefix.key', 'Türkçe Metin', 'English Text'),
```
3. ID format kuralı:
   - `bnd-` prefix'i sabit
   - `XX` = modül kodu (bt=batch, wz=wizard, pd=product, st=stock, sl=sale, ...)
   - Sıra numarası mevcut son kayıttan devam eder
4. Aynı prefix altındaki tüm mevcut kayıtlar kontrol edilmeli, **sadece eksik olanlar** eklenmeli.

**Modül prefix kodları:**
```
bt  → batch (toplu ürün girişi)
wz  → wizard (ürün ekleme sihirbazı)
pd  → product (ürün genel)
st  → stock (stok)
sl  → sale (satış)
pu  → purchase (satın alma)
cu  → customer (müşteri)
su  → supplier (tedarikçi)
rp  → report (rapor)
fn  → finance (cari/finans)
se  → settings (ayarlar)
au  → auth (giriş/kimlik)
cm  → common (ortak)
db  → dashboard
```

**Kontrol adımları (yeni ekran eklerken):**
```
1. Ekrandaki tüm t('X.Y') anahtarlarını listele
2. grep 'X.Y' security/src/main/resources/data.sql → eksikleri bul
3. Eksikleri data.sql'e ekle (INSERT INTO blok içine)
4. security servisini restart et → cache temizlenir
```

---

## 10. DARK MODE

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
// ❌ color: Colors.white  (hardcode)
// ✅ color: isDark ? const Color(0xFF1A1A2E) : Colors.white
```

---

## 11. SIK YAPILAN HATALAR

| Hata | Çözüm |
|------|-------|
| `Scaffold(...)` | `AppScaffold(...)` kullan |
| `AppAppBar(title: Text('...'))` | `title` String alır |
| `.withOpacity(0.1)` | `.withValues(alpha: 0.1)` |
| `GestureDetector` + Container | `Material + InkWell` |
| `Colors.blue` | `AppColors.info` |
| `user.fullName` | `user.displayName` |
| `response.data['items']` | `response.data['data']` |
| Hardcode Türkçe metin | `t('key')` |
| Provider `dispose` unutmak | `autoDispose` kullan |
