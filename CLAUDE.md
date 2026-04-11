# CLAUDE.md — Proje Genel Rehberi

Bu dosya tüm alt projeleri kapsar. **Yeni oturumda ilk oku.**

---

# 0. ÇALIŞMA TARZI — ZORUNLU

**Onay isteme, doğrudan yap.**

- Dosya taşıma, yeniden adlandırma, silme, refactoring gibi işlemlerde onay sorma.
- Kodu yaz, değişikliği uygula, sonucu raporla.
- "Yapalım mı?", "Emin misiniz?", "Devam edeyim mi?" gibi sorular sorma.
- Yıkıcı ve geri alınamaz işlemlerde bile (branch silme, force push, reset --hard gibi) önce niyetini açıkça belirt ve hemen uygula — sor değil.
- Kullanıcı bir şey istedi → yap → sonucu bildir.

---

# 1. PROJE YAPISI

```
proje/
├── project_pos/          # Flutter POS uygulaması (Android, iOS, Web, Desktop)
├── pos-product-manager/  # Spring Boot backend (Java 17, PostgreSQL)
├── security/             # Spring Boot güvenlik servisi (JWT auth)
├── core/                 # Towpen base library (com.towpen:core:11.3.5)
└── template/             # React/TS admin dashboard şablonu (referans)
```

**Servis portları:**
- `security` → 8000
- `pos-product-manager` → 8001
- Flutter → localhost (debug)

**Build sırası:**
```bash
cd core && mvn install -q          # 1. Önce core
cd security && mvn spring-boot:run  # 2. Security (port 8000)
cd pos-product-manager && mvn spring-boot:run  # 3. Backend (port 8001)
# Flutter son
```

---

# 2. FLUTTER POS UYGULAMASI (`project_pos/`)

## Teknoloji Stack

| Paket | Amaç |
|-------|------|
| `flutter_riverpod` | State management (StateNotifier) |
| `go_router` | Navigation + deep linking |
| `dio` | HTTP client (JWT interceptor, auto-refresh) |
| `sqflite` | Yerel veritabanı |
| `fl_chart` | Grafik (Line, Bar, Pie) |
| `mobile_scanner` | Barkod okuma |
| `intl` | Tarih/para formatı (`tr_TR`) |

**Paket adı:** `project_pos` | **Dart SDK:** ^3.11.1

---

## Proje Yapısı

```
lib/
├── core/
│   ├── api/api_client.dart            # Dio HTTP client — baseUrl, JWT, X-Company-Code
│   ├── config/sector_config.dart      # Sektör bazlı alan konfigürasyonu
│   ├── constants/app_constants.dart   # Sabitler (bakınız §2.3)
│   ├── theme/app_colors.dart          # Renk paleti (bakınız §2.4)
│   ├── utils/router.dart              # GoRouter — routerProvider (bakınız §2.8)
│   ├── layouts/responsive_layout.dart # Desktop sidebar + mobile bottom nav
│   └── widgets/                       # Tasarım sistemi (bakınız §2.5)
├── models/                            # Data modelleri
├── providers/
│   ├── auth_provider.dart             # AuthNotifier + User modeli (bakınız §2.7)
│   └── sector_provider.dart
├── services/service_locator.dart      # Tüm Provider tanımları (bakınız §2.9)
└── screens/                           # 76 ekran (bakınız §2.10)
```

---

## 2.1 Ekran Yapısı Şablonu

> **Kural:** Her ekranda `Scaffold` yerine `AppScaffold` kullan.  
> `AppScaffold` gradient arka plan + beyaz kart body (üst köşe 18px yuvarlak) sağlar.  
> `backgroundColor` parametresi geçme — `AppScaffold` bunu yönetir.

```dart
class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ref.read(myServiceProvider).getData();
      setState(() { _items = data; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(                              // ← Scaffold DEĞİL
      appBar: AppAppBar.standard(title: 'Başlık'),  // ← gradient otomatik
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppEmptyState.error(title: 'Hata', description: _error!)
              : _items.isEmpty
                  ? AppEmptyState.noData(title: 'Veri yok')
                  : _buildContent(),
    );
  }
}
```

### AppScaffold parametreleri

```dart
AppScaffold(
  appBar: AppAppBar.standard(title: 'Başlık', actions: [...]),
  body: ...,
  floatingActionButton: FloatingActionButton(...),
  floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
  bottomNavigationBar: BottomAppBar(...),
  drawer: Drawer(...),
  resizeToAvoidBottomInset: false,  // Klavye açılınca body küçülmesin
)
```

### Görsel yapı

```
┌─────────────────────────────────┐
│  ████ Gradient AppBar ████████  │  ← #667eea → #764ba2
│  ╭─────────────────────────────╮│
│  │  Beyaz kart (bgLight)       ││  ← üst köşe 18px yuvarlak
│  │  body content buraya        ││
│  └─────────────────────────────╯│
└─────────────────────────────────┘
```

### ❌ Yapılmaması gerekenler

```dart
// YANLIŞ — Scaffold kullanma
Scaffold(
  backgroundColor: AppColors.bgLight,  // ← gerekmiyor
  appBar: AppAppBar.standard(...),
  body: ...
)

// YANLIŞ — backgroundColor verme
AppScaffold(
  backgroundColor: Colors.white,  // ← AppScaffold'da bu parametre yok
  ...
)
```

---

## 2.2 State Management Şablonu (StateNotifier)

```dart
// State sınıfı
class MyState {
  final List<Item> items;
  final bool isLoading;
  final String? error;
  const MyState({this.items = const [], this.isLoading = false, this.error});

  MyState copyWith({List<Item>? items, bool? isLoading, String? error, bool clearError = false}) {
    return MyState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Notifier
class MyNotifier extends StateNotifier<MyState> {
  MyNotifier(this._ref) : super(const MyState());
  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _ref.read(myServiceProvider).getItems();
      state = state.copyWith(items: items, isLoading: false);
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

---

## 2.3 Servis Şablonu

```dart
class MyService {
  final ApiClient _apiClient;
  MyService(this._apiClient);

  Future<List<Map<String, dynamic>>> getItems() async {
    try {
      final response = await _apiClient.get('product/api/v1/items');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      debugPrint('getItems hata: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createItem(Map<String, dynamic> body) async {
    try {
      final response = await _apiClient.post('product/api/v1/items', data: body);
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } catch (e) {
      debugPrint('createItem hata: $e');
      rethrow;
    }
  }
}

final myServiceProvider = Provider<MyService>((ref) {
  return MyService(ref.watch(apiClientProvider));
});
```

---

## 2.4 Sabitler (AppConstants)

```dart
AppConstants.baseUrl              // API base URL (EnvConfig)
AppConstants.tokenKey             // 'auth_token'
AppConstants.refreshTokenKey      // 'refresh_token'
AppConstants.userKey              // 'user_data'
AppConstants.companyCodeKey       // 'company_code'
AppConstants.defaultPageSize      // 20
AppConstants.maxPageSize          // 100
AppConstants.shortAnimation       // 200ms
AppConstants.mediumAnimation      // 300ms
AppConstants.longAnimation        // 500ms
AppConstants.defaultPadding       // 16.0
AppConstants.smallPadding         // 8.0
AppConstants.largePadding         // 24.0
AppConstants.defaultBorderRadius  // 12.0  ← direkt kullan, BorderRadius.circular() sarma
AppConstants.cardElevation        // 0.0
AppConstants.dateFormat           // 'dd/MM/yyyy'
AppConstants.timeFormat           // 'HH:mm'
AppConstants.dateTimeFormat       // 'dd/MM/yyyy HH:mm'
```

---

## 2.5 Renk Paleti (AppColors)

```dart
// Ana renkler
AppColors.primary        // #667eea (indigo-blue)
AppColors.primaryDark    // #5568d3
AppColors.primaryLight   // #8896f0
AppColors.secondary      // #8b5cf6 (violet)

// Durum renkleri
AppColors.success        // #10b981 (emerald)
AppColors.warning        // #f59e0b (amber)
AppColors.danger         // #ef4444 (red)
AppColors.info           // #3b82f6 (blue)

// Arka plan (durum)
AppColors.bgSuccess      // #d1fae5
AppColors.bgWarning      // #fef3c7
AppColors.bgDanger       // #fee2e2
AppColors.bgInfo         // #dbeafe

// Metin
AppColors.textPrimary    // #111827
AppColors.textSecondary  // #6b7280
AppColors.textMuted      // #9ca3af

// Zemin / Sınır
AppColors.bgLight        // #f9fafb
AppColors.border         // #e5e7eb
AppColors.dark           // #1f2937

// Aksanlar (grafik, badge)
AppColors.purple | AppColors.pink | AppColors.indigo
AppColors.teal   | AppColors.orange | AppColors.cyan

// Gradyan
AppColors.gradientStart  // #667eea
AppColors.gradientEnd    // #764ba2
```

**❌ `Colors.blue`, `Colors.grey`, `Colors.red` KULLANMA** (`Colors.white` hariç)

---

## 2.6 Tasarım Sistemi Widgetları

```dart
// App Bar
AppAppBar.standard(title: 'Başlık')           // Standart
AppAppBar.standard(title: '...', actions: []) // Aksiyonlu

// Butonlar
AppButton.primary(text: 'Kaydet', onPressed: () {})
AppButton.outline(text: 'İptal', onPressed: () {})
AppButton.danger(text: 'Sil', onPressed: () {})
AppButton.primary(text: '...', icon: Icons.add, onPressed: () {})

// Kartlar
AppCard(child: ...)
AppGlassCard(child: ...)

// Boş Durumlar
AppEmptyState.noData(title: 'Veri yok', description: 'Henüz kayıt eklenmedi')
AppEmptyState.error(title: 'Hata', description: errorMessage)

// Bildirimler (context gerekli)
AppToast.success(context, 'Başarılı')
AppToast.error(context, 'Hata mesajı')
AppToast.warning(context, 'Uyarı')

// Dialog
AppConfirmationDialog.show(
  context: context,
  title: 'Silmek istiyor musunuz?',
  onConfirm: () => _delete(),
)

// Bottom Sheet
AppBottomSheet.show(context: context, child: ...)

// Badge
AppBadge(text: 'Yeni', color: AppColors.success)

// Shimmer (yüklenme iskeleti)
AppShimmer(child: Container(height: 60))

// Optimized List (büyük listeler için)
AppOptimizedList(items: items, itemBuilder: (item) => ...)

// Input
AppInput(label: 'Ad', controller: _ctrl, validator: ...)
```

**❌ `AppLoadingIndicator()` YOK** → `CircularProgressIndicator()` kullan  
**❌ `AppButton.text()` YOK** → `.outline()` kullan  
**❌ `AppEmptyState(message: '')` YOK** → `description:` kullan

---

## 2.7 Import Kuralları

```dart
// Derin klasörlerden → paket import (package:)
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/constants/app_constants.dart';
import 'package:project_pos/services/service_locator.dart';

// Aynı feature içinde → göreceli import (./)
import '../providers/pos_provider.dart';
import 'widgets/receipt_preview_dialog.dart';
```

---

## 2.8 Auth Yapısı

### User Modeli Alanları

```dart
class User {
  final String id;
  final String username;
  final String displayName;       // ← fullName DEĞİL
  final String selectedCompanyCode;
  final String languageVal;       // 'TR'
  final List<String> roles;       // ['KASIYER', 'ADMIN', ...]
  final String? email;
  final String? sectorType;       // 'AUTO_PARTS' | 'TECHNOLOGY' | 'FOOTWEAR' | 'GENERAL'
  final String? storeId;          // Kasiyerin mağaza ataması (JWT'den gelir)
}
```

### AuthState Alanları

```dart
class AuthState {
  final User? user;
  final String? token;
  final String? refreshToken;
  final String? sessionId;
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
}
```

### JWT Parse (sessionInstance)

```dart
// JWT payload içindeki sessionInstance string'i JSON olarak parse edilir
final sessionInstanceStr = jwtPayload['sessionInstance'] as String;
final sessionInstance = jsonDecode(sessionInstanceStr);
final userInfo = sessionInstance['userInformation'];
// userInfo alanları: userId, userName, displayName, dynamicLoginParameters.storeId
// Roller: sessionInstance['roles'] → List
```

### Rol Sabitleri

| Rol | Erişim |
|-----|--------|
| `ADMIN` | Her şey |
| `MAGAZA_ADMIN` | POS, Envanter, Stok, Satış, Rapor |
| `KASIYER` | POS, kendi mağazası stok |
| `DEPO` | Stok, transfer, envanter |

---

## 2.9 Tüm Service Provider'lar

```dart
// Temel
apiClientProvider              // Dio HTTP client
authServiceProvider

// Ürün & Stok
productServiceProvider         // product/api/v1/products
categoryServiceProvider        // api/category
companyCategoryServiceProvider // api/company-category
brandServiceProvider           // api/brand
unitServiceProvider            // api/unit
stockServiceProvider           // product/api/v1/stock-movements
stockReportServiceProvider     // api/v1/reports/stock
warehouseServiceProvider       // api/v1/warehouses
storeServiceProvider           // api/v1/stores

// Satış & Müşteri
salesServiceProvider           // api/v1/sales
customerServiceProvider        // api/v1/customers
accountServiceProvider         // api/v1/customers/{id}/account
salesReportServiceProvider     // api/v1/reports/sales

// Tedarikçi & Satın Alma
supplierServiceProvider        // api/v1/suppliers
purchaseServiceProvider        // api/v1/purchases
paymentServiceProvider         // api/v1/payments

// Araç & OEM (Yedek Parça)
vehicleServiceProvider         // api/vehicle
oemServiceProvider             // api/oem-number
crossReferenceServiceProvider  // api/cross-reference
partSearchServiceProvider      // api/part-search
vehicleCompatibilityService    // api/vehicle-compatibility

// Diğer
reportServiceProvider          // api/v1/reports/*
userServiceProvider            // security/api/users
bulkImportServiceProvider
menuServiceProvider            // security/api/menu
i18nServiceProvider
recommendationServiceProvider  // api/v1/recommendations
registrationServiceProvider
```

---

## 2.10 Route Listesi (GoRouter)

```
/login  /register
/dashboard  /menu  /profile

── Satış ──────────────────────────────
/pos              PosScreen
/sales            SaleListScreen
/sales/detail/:id SaleDetailScreen
/sales/return/:saleId  SaleReturnScreen
/scanner          BarcodeScannerScreen

── Müşteri ────────────────────────────
/customers                 CustomerListScreen
/customers/add             AddCustomerScreen
/customers/edit/:id        AddCustomerScreen (edit mode)
/customers/account/:id     CustomerAccountDetailScreen

── Tedarikçi ──────────────────────────
/suppliers                 SupplierListScreen
/suppliers/add             AddSupplierScreen
/suppliers/edit/:id        AddSupplierScreen (edit mode)
/suppliers/account/:id     SupplierAccountDetailScreen
/part-search               PartSearchScreen

── Envanter ───────────────────────────
/inventory                 InventoryScreen
/inventory/products        EnhancedProductListScreen
/inventory/products/:id    ProductDetailScreen
/inventory/add-product     AddProductWizardScreen
/inventory/categories      CategoryListScreen
/inventory/brands          BrandsScreen
/inventory/units           UnitsScreen
/inventory/barcodes        BarcodeManagementScreen
/inventory/batch-entry     BatchProductScreen

── Stok ───────────────────────────────
/stock                     EnhancedStockScreen
/stock/multi-warehouse     MultiWarehouseStockScreen
/stock/transfer            StockTransferScreen
/stock/transfer-review     StockTransferReviewScreen
/stock/count-review        StockCountReviewScreen
/stock/movements           StockMovementHistoryScreen
/stock/alerts              StockAlertScreen
/stock/value-report        StockValueReportScreen

── Depo & Mağaza ──────────────────────
/warehouses  /warehouses/add  /warehouses/edit/:id
/stores      /stores/add      /stores/edit/:id

── Satın Alma ─────────────────────────
/purchases                 PurchaseListScreen
/purchases/create          AddPurchaseScreen
/purchases/detail/:id      PurchaseDetailScreen
/purchases/return/:purchaseId  PurchaseReturnScreen

── Raporlar ───────────────────────────
/reports                   ReportsScreen
/reports/daily-summary     DailySummaryScreen
/reports/sales-summary     SalesSummaryScreen
/reports/product-analysis  ProductSalesAnalysisScreen
/reports/customer-analysis CustomerSalesAnalysisScreen
/reports/profit-overview   ProfitOverviewScreen

── Finans ─────────────────────────────
/finance              FinanceDashboardScreen
/finance/expenses     ExpenseListScreen
/finance/expenses/add AddExpenseScreen
/finance/add-income   AddIncomeScreen
/finance/payments     PaymentListScreen
/finance/cash-flow    CashFlowScreen

── Cari Hesaplar ──────────────────────
/accounts              AccountSummaryDashboardScreen
/accounts/statement    AccountStatementScreen
/accounts/overdue      OverdueTrackingScreen

── İnsan Kaynakları ───────────────────
/hrm/employees         EmployeeListScreen
/hrm/employees/add     AddEmployeeScreen
/hrm/employees/edit/:id

── Toplu İçe Aktarma ──────────────────
/bulk-import           BulkImportUploadScreen
/bulk-import/supplier-upload
/bulk-import/review
/bulk-import/supplier-wizard  SupplierUploadWizardScreen

── Ayarlar ────────────────────────────
/settings              SettingsScreen
/settings/users        UserManagementScreen
/settings/company      CompanySettingsScreen
/settings/sector       SectorSettingsScreen

── Araç Uyumu ─────────────────────────
/vehicles                       VehicleListScreen
/vehicles/compatibility/:variantId  VehicleCompatibilityScreen
```

---

## 2.11 POS Ekranı — Kritik Notlar

- **Klavye Kısayolları:** F1/Ctrl+P: Ödeme, F5: Yenile, ESC: Arama temizle, Ctrl+Delete: Sepet sıfırla
- **Per-store stok:** `_normalizeProductStock(product, storeId)` → `myStoreStock` / `availableElsewhere`
- **CrossLocationAlert:** Başka mağazada stok varsa dialog açılır, `forceAdd: true` ile eklenebilir
- **Mağaza Seçici:** JWT `storeId` yoksa `availableStoreIds`'den seçim açılır (`_showStorePicker`)
- **setActiveStore():** Mağaza değişince tüm ürünler `_normalizeProductStock` ile yeniden işlenir
- **Parked Orders:** Sipariş park edilip geri açılabilir
- **Fiş Önizleme:** `ReceiptPreviewDialog` → `notifier.printLastReceipt()` (ESC/POS hazır değil)

---

## 2.12 Sektör Konfig Sistemi

| Sektör | Enum | Özel Alanlar |
|--------|------|-------------|
| Yedek Parça | `SectorType.autoParts` | OEM, araç uyumu, çapraz ref, raf kodu |
| Genel Perakende | `SectorType.general` | Temel ürün, barkod, depo |
| Teknoloji | `SectorType.technology` | IMEI, seri no, garanti |
| Ayakkabı/Tekstil | `SectorType.footwear` | Beden, renk, kumaş, sezon |

---

## 2.13 API Path Özeti

```
Base: AppConstants.baseUrl
Auth header: Bearer {token}
Tenant header: X-Company-Code: {companyCode}

product/api/v1/products              Ürünler
product/api/v1/sales                 Satışlar
product/api/v1/stock-movements       Stok hareketleri
product/api/v1/purchases             Satın almalar
product/api/v1/customers             Müşteriler
product/api/v1/suppliers             Tedarikçiler
product/api/v1/recommendations/hybrid Öneriler
product/api/v1/reports/sales/*       Satış raporları
product/api/v1/reports/stock/*       Stok raporları
product/api/v1/warehouses            Depolar
product/api/v1/stores                Mağazalar
product/api/v1/stock-transfers       Stok transferleri
product/api/v1/payments              Ödemeler
product/api/v1/account-statements    Hesap ekstresi
product/api/oem-numbers/variant/{id} OEM numaraları
product/api/cross-reference/variant/{id} Çapraz referanslar
product/api/v1/vehicle-compatibility/variant/{id} Araç uyumu
```

---

## 2.14 Hata Akışı (Flutter → UI)

```
API isteği başarısız
  → DioException (status code, response body)
  → service: debugPrint + rethrow
  → provider/notifier: state.copyWith(error: e.toString())
  → build(): AppEmptyState.error(...) VEYA
  → one-off action: AppToast.error(context, e.toString())
```

---

## 2.15 Sık Yapılan Hatalar (Flutter)

| Hata | Çözüm |
|------|-------|
| `Scaffold(backgroundColor: AppColors.bgLight, ...)` | `AppScaffold(...)` kullan — backgroundColor verme |
| `AppScaffold(backgroundColor: ...)` | Bu parametre yok — AppScaffold kendi yönetir |
| `AppAppBar(title: Text('...'))` | `title` String alır, Text() sarma |
| `AppButton.text(...)` | `.text()` yok → `.outline()` kullan |
| `AppEmptyState(message: '')` | `description:` parametresi |
| `BorderRadius.circular(AppConstants.borderRadiusMedium)` | Direkt `AppConstants.defaultBorderRadius` |
| `ref.watch(appRouterProvider)` | `routerProvider` kullan |
| `User(fullName: '...')` | `displayName` kullan |
| `AppLoadingIndicator()` | `CircularProgressIndicator()` kullan |
| `Colors.blue` / `Colors.grey` | `AppColors.info` / `AppColors.textMuted` |
| `catch (_) {}` sessiz | En az `debugPrint('$e')` ekle |
| `DropdownButtonFormField` assertion | `value` mutlaka items listesinde olmalı, `safeValue` guard kullan |
| `response.data['items']` | `response.data['data']` — backend `ApiResponse<T>` döner |

---

## 2.16 Build

```bash
flutter analyze          # 0 error hedefi
flutter run -d chrome    # Web debug
flutter build apk        # Android release
flutter test
```

---

## 2.17 Tam Veri Akışı Zinciri

### Login → Token → API isteği

```
1. LoginScreen → authNotifier.login(username, password)
2. POST security:8000/auth/login
   → Response: { payload: { accessToken, refreshToken, sessionId } }
3. JWT decode: base64 → sessionInstance (JSON string) → userInformation
   → storeId: dynamicLoginParameters.storeId
   → roles: sessionInstance.roles[].roleName
   → sectorType: dynamicLoginParameters.sectorType
4. SharedPreferences.setString:
   - 'auth_token'     → accessToken
   - 'refresh_token'  → refreshToken
   - 'company_code'   → selectedCompanyCode
   - 'user_data'      → jsonEncode(user)
   - 'session_id'     → sessionId
5. Her API isteğinde ApiClient otomatik ekler:
   - Authorization: Bearer {token}
   - X-Company-Code: {companyCode}
6. 401 alınırsa: POST /security/refresh → yeni token → isteği tekrarla
   (Completer ile race condition koruması — tek seferde refresh yapılır)
7. Refresh da başarısız → AuthEvents.notifyUnauthorized() → logout
```

### API Response yapısı (HER yanıtta)

```dart
// Backend her zaman ApiResponse<T> döner:
// { success: true, data: T, message: null }
// { success: false, data: null, message: "Hata mesajı", errorCode: 1001 }

// Flutter'da her zaman:
final response = await _apiClient.get('product/api/v1/items');
final items = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
// ❌ response.data['items']  veya  response.data['result']  YANLIŞ
// ✅ response.data['data']   HER ZAMAN bu key
```

---

## 2.18 Form Şablonu

```dart
class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  String _type = 'INDIVIDUAL';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Edit mode: widget.item != null → controller'ları doldur
    _nameCtrl  = TextEditingController(text: widget.item?['name'] ?? '');
    _phoneCtrl = TextEditingController(text: widget.item?['phone'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;  // ← validasyon önce
    setState(() => _isLoading = true);

    final data = {
      'name':    _nameCtrl.text.trim(),
      'phone':   _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'type':    _type,
      'isActive': _isActive,
    };

    try {
      final svc = ref.read(myServiceProvider);
      if (widget.item != null) {
        await svc.update(widget.item!['id'], data);
      } else {
        await svc.create(data);
      }
      if (mounted) {
        AppToast.success(context, 'Kaydedildi');
        Navigator.pop(context, true);  // ← true: üst ekran yenilesin
      }
    } catch (e) {
      if (mounted) AppToast.error(context, 'Hata: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.standard(title: widget.item != null ? 'Düzenle' : 'Yeni Ekle'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Bölüm 1: Temel Bilgiler ──────────────────────────
              _buildSectionCard('Temel Bilgiler', [
                AppInput(
                  label: 'Ad *',
                  controller: _nameCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ad zorunludur' : null,
                ),
                const SizedBox(height: 12),
                AppInput(
                  label: 'Telefon',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
              ]),
              const SizedBox(height: 16),

              // ── Bölüm 2: Durum ───────────────────────────────────
              _buildSectionCard('Durum', [
                SwitchListTile(
                  title: const Text('Aktif'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ]),
              const SizedBox(height: 24),

              // ── Kaydet Butonu ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  text: _isLoading ? 'Kaydediliyor…' : 'Kaydet',
                  icon: Icons.save_rounded,
                  onPressed: _isLoading ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
}
```

### Form validasyon kuralları

```dart
// Zorunlu metin
validator: (v) => (v == null || v.trim().isEmpty) ? 'Alan zorunludur' : null,

// Sayı (pozitif)
validator: (v) {
  final n = double.tryParse(v ?? '');
  if (n == null) return 'Geçerli sayı girin';
  if (n <= 0) return 'Sıfırdan büyük olmalı';
  return null;
},

// E-posta (opsiyonel, dolu ise format kontrol)
validator: (v) {
  if (v == null || v.trim().isEmpty) return null;
  final emailReg = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailReg.hasMatch(v.trim()) ? null : 'Geçersiz e-posta';
},
```

---

## 2.19 Liste Ekranı Şablonu (Filtreli)

```dart
// Mevcut pattern: tüm veriyi çek → lokal filtrele (server-side pagination yok)
class _MyListState extends ConsumerState<MyListScreen> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'ALL';   // 'ALL' | 'ACTIVE' | 'INACTIVE'
  List<Map<String, dynamic>> _all = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      _all = await ref.read(myServiceProvider).getAll();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _all;
    final q = _searchCtrl.text.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((item) =>
        (item['name']?.toString().toLowerCase() ?? '').contains(q)
      ).toList();
    }
    if (_statusFilter == 'ACTIVE')   list = list.where((i) => i['isActive'] == true).toList();
    if (_statusFilter == 'INACTIVE') list = list.where((i) => i['isActive'] != true).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.standard(
        title: 'Liste',
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () async {
            final result = await context.push('/my-screen/add');
            if (result == true) _load();  // ← ekleme sonrası yenile
          }),
        ],
      ),
      body: Column(
        children: [
          // ── Arama + Filtre ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Ara…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); setState(() {}); })
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true, fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _statusFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'ALL',      child: Text('Tümü')),
                  DropdownMenuItem(value: 'ACTIVE',   child: Text('Aktif')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Pasif')),
                ],
                onChanged: (v) => setState(() => _statusFilter = v!),
              ),
            ]),
          ),

          // ── Liste ────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? AppEmptyState.error(title: 'Hata', description: _error!, onAction: _load)
                    : _filtered.isEmpty
                        ? AppEmptyState.noData(title: 'Kayıt bulunamadı')
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, i) => _buildItem(_filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
```

---

## 2.20 Navigasyon (GoRouter) Örnekleri

```dart
// Sayfaya git
context.push('/customers');

// Parametre ile git
context.push('/customers/edit/${customer['id']}');
context.push('/customers/account/${customer['id']}');

// Sonuç bekle (form kapatılınca true/false döner)
final result = await context.push<bool>('/customers/add');
if (result == true) _load();  // Yeni kayıt eklendiyse yenile

// Geri git
context.pop();
context.pop(true);  // Üst ekrana değer döndür

// Ana sayfaya dön (tüm stack temizle)
context.go('/dashboard');

// Mevcut route'u değiştir (history'e ekleme)
context.replace('/login');
```

---

## 2.21 Tarih/Para Formatlama

```dart
import 'package:intl/intl.dart';

// Para formatı — her zaman tr_TR
final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
currency.format(1234.5)   // → "₺1.234,50"

// Tarih formatları
final dateF    = DateFormat('dd.MM.yyyy', 'tr_TR');
final dateTimeF = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');
final monthF   = DateFormat('MMMM yyyy', 'tr_TR');

dateF.format(DateTime.now())       // → "11.04.2026"
dateTimeF.format(DateTime.now())   // → "11.04.2026 14:30"

// API'ye gönderirken ISO format
DateTime.now().toIso8601String()               // → "2026-04-11T14:30:00.000"
DateTime.now().toIso8601String().split('T')[0] // → "2026-04-11"  (sadece tarih)

// API'den DateTime parse
DateTime.tryParse(item['saleDate']?.toString() ?? '') ?? DateTime.now()
```

---

## 2.22 Grafik Şablonları (fl_chart)

```dart
import 'package:fl_chart/fl_chart.dart';

// ── LineChart (satış trendi) ─────────────────────────────────
LineChart(
  LineChartData(
    lineBarsData: [
      LineChartBarData(
        spots: data.asMap().entries.map((e) =>
          FlSpot(e.key.toDouble(), e.value['total']?.toDouble() ?? 0)
        ).toList(),
        isCurved: true,
        color: AppColors.primary,
        barWidth: 2.5,
        belowBarData: BarAreaData(
          show: true,
          color: AppColors.primary.withValues(alpha: 0.08),
        ),
        dotData: const FlDotData(show: false),
      ),
    ],
    gridData: const FlGridData(show: false),
    borderData: FlBorderData(show: false),
    titlesData: FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true, reservedSize: 28,
          getTitlesWidget: (v, _) => Text(labels[v.toInt()],
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ),
      ),
    ),
  ),
)

// ── BarChart (kategori karşılaştırma) ───────────────────────
BarChart(
  BarChartData(
    barGroups: data.asMap().entries.map((e) =>
      BarChartGroupData(x: e.key, barRods: [
        BarChartRodData(
          toY: e.value['value']?.toDouble() ?? 0,
          color: AppColors.chartColors[e.key % AppColors.chartColors.length],
          width: 18,
          borderRadius: BorderRadius.circular(4),
        ),
      ])
    ).toList(),
    titlesData: FlTitlesData(
      bottomTitles: AxisTitles(sideTitles: SideTitles(
        showTitles: true, reservedSize: 32,
        getTitlesWidget: (v, _) => Text(labels[v.toInt()],
          style: const TextStyle(fontSize: 10)),
      )),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    ),
    gridData: const FlGridData(show: false),
    borderData: FlBorderData(show: false),
  ),
)

// ── PieChart (dağılım) ───────────────────────────────────────
PieChart(
  PieChartData(
    sections: data.asMap().entries.map((e) {
      final total = data.fold<double>(0, (s, d) => s + (d['value'] as num).toDouble());
      final value = (e.value['value'] as num).toDouble();
      return PieChartSectionData(
        color: AppColors.chartColors[e.key % AppColors.chartColors.length],
        value: value,
        title: '%${(value / total * 100).toStringAsFixed(0)}',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList(),
    sectionsSpace: 2,
    centerSpaceRadius: 40,
  ),
)

// ── LinearProgressIndicator (basit dağılım, fl_chart gerektirmez) ──
Column(
  children: items.map((item) {
    final pct = total > 0 ? item['value'] / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(item['label'], style: const TextStyle(fontSize: 13)),
          Text(currency.format(item['value']),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ]),
    );
  }).toList(),
)
```

### Grafik renk paleti (12 renk)

```dart
// AppColors'a eklendi — grafiklerde sırayla kullan
static const List<Color> chartColors = [
  Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899),
  Color(0xFFF97316), Color(0xFFEAB308), Color(0xFF22C55E),
  Color(0xFF10B981), Color(0xFF14B8A6), Color(0xFF06B6D4),
  Color(0xFF0EA5E9), Color(0xFF3B82F6), Color(0xFF6366F1),
];
```

---

## 2.23 Rapor Servisi Sorgu Parametreleri

```dart
// Tarih aralıklı raporlar — standart format
final start = DateFormat('yyyy-MM-dd').format(startDate);  // "2026-01-01"
final end   = DateFormat('yyyy-MM-dd').format(endDate);    // "2026-04-11"

// Satış özeti
salesReportService.getSalesSummary(
  startDate: start,
  endDate: end,
  groupBy: 'day',   // 'day' | 'week' | 'month'
)

// Ürün analizi
salesReportService.getProductSalesAnalysis(
  startDate: start,
  endDate: end,
  limit: 20,
)

// Stok hareketleri (sayfalama parametreli)
stockService.getStockMovements(
  movementType: 'SALE_OUT',  // opsiyonel
  startDate: startDate,
  endDate: endDate,
  page: 0,
  limit: AppConstants.defaultPageSize,
)
```

---

## 2.24 Çözülmüş Bug Kataloğu

| Hata | Neden | Çözüm |
|------|-------|-------|
| `DropdownButtonFormField` assertion | `value` items listesinde yok (stale state) | `safeValue` guard: `items.any((i) => i.value == val) ? val : null` |
| Duplicate dropdown items | API aynı ID'yi iki kez döndü | `.toSet().toList()` ile deduplicate |
| `ON CONFLICT DO NOTHING` + FK hata | Insert atlandı ama başka tablo o ID'ye FK tuttu | ID'leri data.sql'de hizala |
| `DROP TABLE IF EXISTS` view için hata | VIEW'ı TABLE komutuyla silmeye çalışma | `DROP VIEW IF EXISTS` kullan |
| `child: Scaffold(` AppScaffold'a çevrilmedi | Regex lookbehind `child:` öncesini atladı | Manuel `AppScaffold` ile değiştir |
| `withOpacity` deprecated | Flutter SDK güncellendi | `withValues(alpha: 0.x)` kullan |
| POS `availableStoreIds` boş | JWT `storeId` null, multi-store mantığı atlandı | `_loadInitialData` içinde `availableStoreIds` kontrolü |
| Recommendation panel yerde yer kaplar | `recommendations.isEmpty` kontrolü eksik | `if (isEmpty && !isLoading) return SizedBox.shrink()` |
| Security FK `udef-depo0-` vs `udef-depo-` | İki serviste farklı UUID prefix | Her iki data.sql'de aynı ID kullan |
| `BaseEntityListScreen` header gradient almadı | Ham `AppBar()` kullanıyordu | `flexibleSpace` + `AppGradients.primaryGradient` ile güncelle |

---

## 2.25 Yeni Ekran Hızlı Başlangıç Checklist

```
□ AppScaffold kullan (Scaffold değil, backgroundColor verme)
□ AppAppBar.standard(title: '...') ile header
□ ConsumerStatefulWidget şablonu (§2.1)
□ _isLoading / _error / _data state pattern
□ initState → _loadData() çağrısı
□ dispose → TextEditingController'ları dispose et
□ body → isLoading ? CircularProgressIndicator
              : error ? AppEmptyState.error(onAction: _load)
              : empty ? AppEmptyState.noData
              : _buildContent()
□ RefreshIndicator ile pull-to-refresh
□ API yanıtı: response.data['data'] (her zaman bu key)
□ Tarih: DateFormat('dd.MM.yyyy', 'tr_TR')
□ Para: NumberFormat.currency(locale: 'tr_TR', symbol: '₺')
□ Toast: AppToast.success/error(context, mesaj)
□ Navigation dönüş: context.pop(true) → üst ekran yenilesin
□ router.dart'a route ekle
□ menu_screen.dart'a menü linki ekle (gerekiyorsa)
```

```bash
flutter analyze          # 0 error hedefi
flutter run -d chrome    # Web debug
flutter build apk        # Android release
flutter test
```

---

# 3. SPRING BOOT BACKEND (`pos-product-manager/`)

## Teknoloji Stack

- **Framework:** Spring Boot 3.x (Java 17)
- **ORM:** Spring Data JPA / Hibernate
- **Base Library:** `com.towpen:core:11.3.5` (TOpenSimpleCompanyEntity, BaseDaoRepository, TOpenException, TMessageType)
- **Build:** Maven
- **DB:** PostgreSQL, `ddl-auto=create`, `spring.sql.init.mode=always` (data.sql her başlatmada çalışır)

---

## 3.1 Proje Yapısı

```
src/main/java/com/sedcore/
├── controller/impl/    # REST controller implementasyonları
├── controller/         # Controller interface'leri
├── service/impl/       # Service implementasyonları
├── service/            # Service interface'leri
├── repository/         # Spring Data JPA repository'leri
├── entity/             # JPA entity'leri (bakınız §3.6)
├── model/              # DTO / Request / Response
│   └── reports/        # Rapor DTO'ları
├── enums/              # StockMovementType, ProductRelationType, ProductStatus
├── context/            # CompanyContext (ThreadLocal)
└── util/               # ExceptionMapper, EntityAuditHelper
```

---

## 3.2 Controller Şablonu

```java
@RestController
@RequestMapping("/api/v1/items")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Items")
@SecurityRequirement(name = "Bearer Authentication")
public class ItemControllerImpl {

    private final ItemService itemService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<ItemResponse>>> list() {
        try {
            return ResponseEntity.ok(ApiResponse.success(itemService.getAll()));
        } catch (TOpenException e) {
            throw e;                       // ← ASLA modify etme
        } catch (Exception e) {
            log.error("Item listeleme hatası", e);
            throw ExceptionMapper.map(e);  // ← genel hatalar için
        }
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ItemResponse>> create(@Valid @RequestBody ItemRequest request) {
        try {
            return ResponseEntity.ok(ApiResponse.success(itemService.create(request)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Item oluşturma hatası", e);
            throw ExceptionMapper.map(e);
        }
    }
}
```

---

## 3.3 Service Şablonu

```java
@Service
@Slf4j
@Transactional
@RequiredArgsConstructor
public class ItemServiceImpl extends BaseDbServiceImp<ItemRepository, Item>
        implements ItemService {

    @Override
    public Class<?> getDTOClassForService() { return ItemResponse.class; }

    @Override
    @Transactional(readOnly = true)  // ← Okuma metotlarında mutlaka
    public List<ItemResponse> getAll() {
        String companyCode = CompanyContext.get();
        if (companyCode == null || companyCode.isBlank()) companyCode = "syste";
        return dao.findByCompanyCodeAndIsDeletedFalseOrderByName(companyCode).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    public ItemResponse create(ItemRequest request) {
        Item item = Item.builder()
                .name(request.getName())
                .isActive(true)
                .build();
        Item saved = save(item);
        log.info("Item oluşturuldu: {} ({})", saved.getName(), saved.getId());
        return toResponse(saved);
    }

    // Kendi entity'si → save(entity)
    // Başka service'in entity'si → prepareAndSave(repository, entity)

    // ── MAPPING — ZORUNLU PATTERN ────────────────────────────────────────
    // Response sınıfı DtoBaseModel extend etmeli (bakınız §3.13)
    private ItemResponse toResponse(Item item) {
        return toDTO(item);  // ← BeanUtils tabanlı, aynı isimli tüm alanlar kopyalanır
    }

    // FK ilişkisinden gelen alanlar varsa — toDTO() sonrası manuel ekle:
    // private ItemResponse toResponse(Item item) {
    //     ItemResponse dto = toDTO(item);
    //     dto.setCategoryName(item.getCategory().getName());  // FK alanı
    //     dto.setStatusLabel(item.getStatus().getDescription()); // computed
    //     return dto;
    // }
}
```

---

## 3.4 Entity Şablonu

```java
@Entity
@Table(name = "items", indexes = {
    @Index(name = "idx_item_name", columnList = "name")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Item extends TOpenSimpleCompanyEntity {

    @Column(name = "name", nullable = false, length = 200)
    private String name;

    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Builder.Default
    @Column(name = "is_deleted")
    private Boolean isDeleted = false;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 20)
    private ProductStatus status;

    // İlişkiler — DAIMA LAZY
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    @OneToMany(mappedBy = "item", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<SubItem> subItems;
}
```

---

## 3.5 Repository Şablonu

```java
@Repository
public interface ItemRepository extends BaseDaoRepository<Item> {
    List<Item> findByIsActiveTrueOrderByNameAsc();
    Optional<Item> findByCode(String code);

    // Derived queries: companyCode her zaman 2. parametre
    List<Item> findByVariantIdAndCompanyCode(String variantId, String companyCode);

    // Custom JPQL
    @Query("SELECT i FROM Item i WHERE i.category.id = :categoryId AND i.isDeleted = false ORDER BY i.name")
    List<Item> findByCategoryId(@Param("categoryId") String categoryId);

    // Native SQL (karmaşık JOIN'ler)
    @Query(value = """
        SELECT p.id, p.name, COUNT(*) as cnt
        FROM items i JOIN products p ON i.product_id = p.id
        WHERE i.company_code = :companyCode
        GROUP BY p.id, p.name ORDER BY cnt DESC
        """, nativeQuery = true)
    List<Object[]> findTopItems(@Param("companyCode") String companyCode);
}
```

---

## 3.6 Entity İlişki Haritası

```
Product (1) ──< ProductVariant (N)
                    │
                    ├──< OemNumber
                    ├──< CrossReference
                    ├──< VehicleCompatibility >── Vehicle
                    ├──< StockMovement >── Warehouse
                    ├──< Barcode
                    └── VariantPricing

Sale (1) ──< SaleItem >── ProductVariant
  │            └── StockMovement (SALE_OUT)
  ├── Customer
  └──< SaleReturn ──< SaleReturnItem

Purchase (1) ──< PurchaseItem >── ProductVariant
  │               └── StockMovement (PURCHASE_IN)
  └── Supplier

Customer (1) ── CustomerAccount (1)
                    └──< AccountTransaction

Supplier (1) ── SupplierAccount (1)
                    └──< AccountTransaction

StockTransfer ──< StockTransferItem >── ProductVariant
  ├── Warehouse (source)
  └── Warehouse (destination)

Category ──< Category (self-join: parent/children)
  └──< CategoryAttribute
```

---

## 3.7 Tüm Endpoint'ler

```
── Ürün & Kategori ────────────────────────────────────
GET/POST             api/v1/products
GET/PUT/DELETE/PATCH api/v1/products/{id}
GET                  api/v1/products/search
GET/POST             api/category
GET/PUT/DELETE       api/category/{id}
GET                  api/category/tree  /root  /children/{parentId}
GET/POST/PUT/DELETE  api/brand
PATCH                api/brand/{id}/toggle-status
GET/POST/PUT/DELETE  api/unit
GET/POST/PUT/DELETE  api/vehicle
GET                  api/vehicle/makes  /models  /search

── Stok ───────────────────────────────────────────────
GET/POST             api/v1/stock-movements
GET                  api/v1/stock-movements/{id}  /stats
GET/POST             api/v1/stock-transfers
POST                 api/v1/stock-counts
GET                  api/v1/warehouses  /{id}
GET                  api/v1/stores      /{id}

── Satış & Müşteri ────────────────────────────────────
GET/POST             api/v1/sales
GET                  api/v1/sales/{id}  /by-number/{num}  /stats
POST                 api/v1/sales/{id}/returns
PATCH                api/v1/sales/{id}/cancel
GET/POST/PUT/DELETE  api/v1/customers
PATCH                api/v1/customers/{id}/toggle-status
GET                  api/v1/customers/{id}/account  /transactions  /stats
POST                 api/v1/customers/{id}/payment
PUT                  api/v1/customers/{id}/credit-limit

── Satın Alma & Tedarikçi ─────────────────────────────
GET/POST/PUT         api/v1/purchases
GET                  api/v1/purchases/{id}  /stats
POST                 api/v1/purchases/{id}/returns
PATCH                api/v1/purchases/{id}/cancel
GET/POST/PUT/DELETE  api/v1/suppliers
GET                  api/v1/suppliers/{id}/account  /transactions  /stats
POST                 api/v1/suppliers/{id}/payment
PUT                  api/v1/suppliers/{id}/credit-limit

── Ödemeler & Finans ──────────────────────────────────
GET/POST             api/v1/payments
GET                  api/v1/payments/{id}
PATCH                api/v1/payments/{id}/cancel  /verify
GET                  api/v1/account-statements  /overdue  /summary
GET                  api/v1/account-transactions/{id}
PATCH                api/v1/account-transactions/{id}/cancel

── Raporlar ───────────────────────────────────────────
GET                  api/v1/reports/sales/summary
GET                  api/v1/reports/sales/by-product
GET                  api/v1/reports/sales/by-customer
GET                  api/v1/reports/sales/profit-overview
GET                  api/v1/reports/stock/value-summary
GET                  api/v1/reports/stock/movement-summary
GET                  api/v1/reports/stock/critical-alerts
GET                  api/v1/reports/stock/warehouse-breakdown
GET                  api/v1/stats/overview  /revenue  /top-products  /order-status

── Yedek Parça Özgü ───────────────────────────────────
GET/POST/DELETE      api/oem-numbers/variant/{variantId}
POST                 api/oem-numbers/bulk/{variantId}
GET/POST/DELETE      api/cross-reference/variant/{variantId}
GET                  api/cross-reference/search
GET/POST/DELETE      api/vehicle-compatibility/variant/{variantId}
GET                  api/part-search

── Öneri ──────────────────────────────────────────────
GET                  api/v1/recommendations/hybrid?productIds=...&variantIds=...
```

---

## 3.8 Kritik Kurallar

### Company Scoping — HER sorguda

```java
String companyCode = CompanyContext.get();
if (companyCode == null || companyCode.isBlank()) companyCode = "syste";
repository.findByVariantId(variantId, companyCode);
```

### TMessageType (core JAR — genişletilemez!)

```java
TMessageType.FIELD_IS_REQUIRED_1001        // Zorunlu alan
TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006 // Kayıt bulunamadı
TMessageType.ALREADY_EXISTS_1004            // Zaten mevcut
TMessageType.SAME_AS_DB_CAN_NOT_UPDATE_1050 // Değişiklik yok
TMessageType.ENTERED_DATA_IS_NOT_IN_FORMAT_1046 // Format hatası
TMessageType.UNEXPECTED_ERROR_9999          // Genel hata
// ❌ BRAND_CREATE_ERROR_1301 gibi custom değerler YOK → ExceptionMapper.map(e) kullan
```

### Loglama

```java
log.info("Oluşturuldu: {} ({})", saved.getName(), saved.getId()); // ✅
log.error("Hata", e);                                              // ✅
log.error("Hata: " + e.getMessage());                             // ❌ concatenation yasak
```

### Adlandırma

```
Sınıf:    BrandController (interface) → BrandControllerImpl
Tablo:    Çoğul snake_case (brands, categories, stock_movements)
Sütun:    snake_case (is_active, company_code, create_time)
Field:    camelCase (isActive, companyCode, createTime)
Boolean:  is* veya has* prefix (isActive, isDeleted, hasReturn)
Enum:     UPPER_SNAKE (PURCHASE_IN, SALE_OUT, ACTIVE)
Endpoint: kebab-case (/toggle-status, /by-number)
```

---

## 3.9 Önemli Akışlar

### Satış Oluşturma

```
POST api/v1/sales (SaleRequest)
  → SaleServiceIntegrated.createSale(request)
    1. Sale entity oluştur + save()
    2. Her item için: StockMovement(SALE_OUT) + prepareAndSave()
    3. Veresiye ise: CustomerAccount bakiyesi güncelle + AccountTransaction ekle
    → SaleResponse döner (saleNumber, grandTotal, items, customer)
```

### Stok Hareketi Tipleri

```
PURCHASE_IN        Satın alma girişi
PURCHASE_RETURN_OUT Satın alma iade çıkışı
SALE_OUT           Satış çıkışı
SALE_RETURN_IN     Satış iade girişi
SALE_CANCEL_IN     Satış iptal girişi
TRANSFER_IN        Transfer girişi
TRANSFER_OUT       Transfer çıkışı
ADJUSTMENT_IN      Sayım fazlası
ADJUSTMENT_OUT     Sayım eksiği
```

### Öneri Sistemi

```
GET api/v1/recommendations/hybrid?productIds=...&variantIds=...
  → RecommendationServiceImpl.getHybridRecommendations()
    1. getFrequentlyBoughtTogether(variantIds)  — sale_id JOIN
    2. getSimilarProducts(productIds)           — product_relationship
    3. getCrossReferencedProducts(variantIds)   — cross_references self-join
    → Dedupe → Weighted score → limit
```

---

## 3.10 Seed Data (data.sql)

```
SEDCORE  (Yedek Parçacı):
  5 ürün, 7 varyant (var-oto1-...-001→007)
  Mağaza: STORE-01,  Depo: WH-01
  Kullanıcılar: kasiyer(STORE-01), kasiyer2(SUBE-01), depo, magaza_admin

SEDCORE1 (Elbise Mağazası):
  5 ürün, 15 varyant (var-elb1-...-001→015)
  Mağaza: STORE-02, Depo: WH-02
  Kullanıcılar: giyimkasiyer(STORE-02), giyimdepo

cross_references  : 28 kayıt, 5 paylaşılan OEM grubu
stock_movements   : 9 farklı hareket tipi (tarih aralıklı)
product_relationship: COMPLEMENTARY, SIMILAR, ALTERNATIVE örnekleri
```

---

## 3.11 Sık Yapılan Hatalar (Backend)

| Hata | Çözüm |
|------|-------|
| Custom TMessageType | Yok → `ExceptionMapper.map(e)` |
| `findBySaleId(saleId)` tek parametre | `findBySaleId(saleId, companyCode)` — 2. param companyCode |
| `catch (Exception e) {}` boş | `log.error("...", e); throw ExceptionMapper.map(e);` |
| `DROP TABLE IF EXISTS` view için | `DROP VIEW IF EXISTS` kullan |
| `ON CONFLICT (id) DO NOTHING` | Farklı ID + aynı username → insert atlanır, FK bozulur |
| `throw ExceptionMapper.map(e)` `e` tanımsız | `throw new TOpenException(new TOpenMessage(TMessageType.FIELD_IS_REQUIRED_1001))` |
| Null bytes dosyada | `tr -d '\0' < file > file.clean && mv file.clean file` |
| `io.swagger.v3.oas.models.components.Components` | `io.swagger.v3.oas.models.Components` (components alt paket değil) |
| `return ResponseBuilder.builder()...build()` mapper'da | `toDTO(entity)` kullan — bakınız §3.13 |
| Response DTO'da `extends DtoBaseModel` eksik | `toDTO()` çalışmaz → ekle |
| `collect(Collectors.toList())` | `.toList()` (Java 25) |
| Record Response + `toDTO()` | Records DtoBaseModel extend edemez → class yap |
| Cross-service `toResponse()` private | Interface'e ekle: `MyResponse toResponse(MyEntity e)` |
| `toDTO(variant)` — farklı entity tipi | T mismatch → delegate: `variantService.mapToResponse(v)` |

---

## 3.12 Build

```bash
cd core && mvn install -q
cd pos-product-manager && mvn compile   # 0 error hedefi
mvn spring-boot:run
mvn test
```

---

## 3.13 Entity → DTO Mapping Standardı (ZORUNLU)

> **Kural:** Tüm `toResponse()` / `mapToResponse()` metotlarında `BaseDbServiceImp.toDTO()` kullan.  
> Builder pattern ile manuel mapping **yasaktır**.

### Response DTO Kuralları

```java
// ✅ DOĞRU — Her Response DTO DtoBaseModel extend etmeli
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class ItemResponse extends DtoBaseModel {
    private String id;
    private String name;
    private String companyCode;
    private Boolean isActive;
}

// ❌ YANLIŞ — DtoBaseModel olmadan
public class ItemResponse {   // extends eksik
    ...
}
```

**Kısıtlamalar:**
- **Java Records** `extends DtoBaseModel` yapamaz → Records sadece rapor/salt-okunur model için kullan (bakınız §3.13-Records)
- `@Builder @NoArgsConstructor @AllArgsConstructor` üçü birlikte zorunlu — `toDTO()` no-args constructor gerektirir

### Mapping Kategorileri

**Kategori 1 — Tam eşleşme** (yalnızca `toDTO(entity)`):
```java
// Entity ve Response field isimleri + tipleri birebir eşleşiyor
private ItemResponse toResponse(Item item) {
    return toDTO(item);
}
```
Örnekler: `BrandResponse`, `UnitResponse`, `VehicleResponse`

**Kategori 2 — Kısmi eşleşme** (`toDTO()` + manuel supplement):
```java
// BeanUtils eşleşen alanları kopyalar; FK/enum/computed alanlar manuel eklenir
private OemNumberResponse toResponse(OemNumber oem) {
    OemNumberResponse dto = toDTO(oem);
    dto.setVariantId(oem.getVariant().getId());          // FK → manuel
    return dto;
}

private BarcodeResponse toResponse(Barcode b) {
    BarcodeResponse dto = toDTO(b);
    dto.setBarcodeType(b.getBarcodeType() != null        // enum→String → manuel
        ? b.getBarcodeType().name() : null);
    return dto;
}

private AccountTransactionResponse toResponse(AccountTransaction tx) {
    AccountTransactionResponse dto = toDTO(tx);
    dto.setTransactionTypeLabel(                         // computed → manuel
        tx.getTransactionType() != null
            ? tx.getTransactionType().getDescription() : null);
    if (tx.getSupplier() != null) {
        dto.setSupplierId(tx.getSupplier().getId());     // FK → manuel
        dto.setSupplierName(tx.getSupplier().getName());
    }
    return dto;
}
```

**Kategori 3 — Farklı entity tipi** (cross-service delegasyon):
```java
// ProductServiceImpl'de T=Product olduğundan, ProductVariant için toDTO() çalışmaz
// → delegate to variantService.mapToResponse() (interface'e eklenmeli)
private ProductVariantResponse mapVariantToResponse(ProductVariant variant) {
    ProductVariantResponse dto = variantService.mapToResponse(variant); // ← delegasyon
    // Bu service'e özgü enrichment
    dto.setInventory(inventoryService.findByVariantIdSafe(variant.getId()));
    return dto;
}
```

### BeanUtils Kopyalama Kuralları

| Durum | BeanUtils Davranışı | Çözüm |
|-------|---------------------|-------|
| Aynı isim + aynı tip | ✅ Kopyalar | — |
| Enum → aynı Enum tipi | ✅ Kopyalar | — |
| Enum → String | ❌ Kopyalamaz | `dto.setX(entity.getX().name())` |
| FK ilişkisi (`@ManyToOne`) | ❌ Kopyalamaz | `dto.setXId(entity.getX().getId())` |
| `List<Entity>` (LAZY) | ❌ Kopyalamaz | manuel map |
| Farklı isimli alan | ❌ Kopyalamaz | `dto.setDisplayName(entity.getUserDisplayName())` |
| Hesaplanan alan | ❌ Kopyalamaz | `dto.setLabel(entity.getEnum().getDescription())` |

### Stream.toList() — Java 25

```java
// ✅ DOĞRU — Java 25
return dao.findAll().stream()
        .map(this::toResponse)
        .toList();

// ❌ ESKİ — artık kullanma
return dao.findAll().stream()
        .map(this::toResponse)
        .collect(Collectors.toList());
```

### Records (Rapor Modelleri)

Records sadece **`BaseDbServiceImp` extend etmeyen** report servislerinde kullanılır.  
`toDTO()` ile uyumsuz — builder ve no-args constructor gerektirmez.

```java
// ✅ DOĞRU — SalesReportServiceImpl toDTO() kullanmıyor
@Builder
public record ProfitOverview(BigDecimal revenue, BigDecimal cost) {}

// ❌ YANLIŞ — toDTO() kullanılan servis için Record
public record BrandResponse(String id, String name) {}  // DtoBaseModel extend edilemez
```

### Cross-Service Mapper Erişimi

Başka bir servis `toResponse()` metoduna ihtiyaç duyuyorsa → **interface'e ekle**:

```java
// AccountTransactionService interface:
AccountTransactionResponse toResponse(AccountTransaction tx);

// ProductVariantService interface:
ProductVariantResponse mapToResponse(ProductVariant variant);
```

### Yeni Servis Checklist

```
□ Response DTO → extends DtoBaseModel ekle
□ @NoArgsConstructor @AllArgsConstructor ekle (builder varsa)
□ getDTOClassForService() → return MyResponse.class
□ toResponse() / mapToResponse() → toDTO() ile başla
□ FK alanları → toDTO() sonrası manuel set
□ Enum → String dönüşümü → toDTO() sonrası .name() ile set
□ Computed alanlar → toDTO() sonrası hesapla
□ .collect(Collectors.toList()) → .toList() (Java 25)
□ Java Records → sadece non-BaseDbServiceImp report servislerinde
□ Cross-service mapper erişimi → interface'e metot ekle
```

---

## 3.12 Build

```bash
cd core && mvn install -q
cd pos-product-manager && mvn compile   # 0 error hedefi
mvn spring-boot:run
mvn test
```

---

# 4. GÜVENLİK SERVİSİ (`security/`)

- **Port:** 8000
- **JWT:** `sessionInstance` alanında `userInformation` + `roles` gömülü
- **Roller:** `userRoleRepository.findByUserDef(userId)` ile yüklenir
- **Menü:** `role_menu` tablosundan kullanıcı bazlı menü yapısı döner (`RoleMenuRepository.findMenuStructureByRole(userId)`)
- **Menü servisi:** `MenuCategoryServiceImpl.getMenusForUser()` → `List<DtoMenuCategory>` (nested)

### Kullanıcı Tablosu

| Kullanıcı | Şifre | Rol | Company | Store |
|-----------|-------|-----|---------|-------|
| admin | admin | ADMIN | SEDCORE | — |
| kasiyer | 123 | KASIYER | SEDCORE | STORE-01 |
| kasiyer2 | 123 | KASIYER | SEDCORE | SUBE-01 |
| depo | 123 | DEPO | SEDCORE | — |
| magaza_admin | 123 | MAGAZA_ADMIN | SEDCORE | — |
| giyimkasiyer | 123 | KASIYER | SEDCORE1 | STORE-02 |
| giyimdepo | 123 | DEPO | SEDCORE1 | — |

### JWT Parse (Flutter tarafı)

```dart
final sessionInstanceStr = jwtPayload['sessionInstance'] as String;
final sessionInstance = jsonDecode(sessionInstanceStr);
final userInfo = sessionInstance['userInformation'];
// Alanlar: userId, userName, displayName
// storeId: userInfo['dynamicLoginParameters']['storeId']
// Roller: (sessionInstance['roles'] as List).map((r) => r['roleName']).toList()
```

### Security ID Kuralı

```
User ID format: udef-{username}-0000-0000-0000-000000000001
Örnek: udef-admin-0000-0000-0000-000000000001
       udef-depo-0000-0000-0000-000000000003   ← "depo0" DEĞİL "depo"
```

---

# 5. TEMPLATE (`template/`)

React 19 + TypeScript + Vite admin dashboard — SEDCORE backend'e bağlı yönetim paneli.

## Teknoloji Stack

- **State:** Redux Toolkit + Zustand
- **UI:** Ant Design (primary), Bootstrap (layout), PrimeReact (tablo/grafik)
- **HTTP:** Axios (iki ayrı instance)
- **Build:** `npm run dev` / `npm run build`

## API Bağlantısı

```
security (auth)  → http://localhost:8000  → securityApi (axiosClient)
product manager  → http://localhost:8001  → productApi  (axiosClient)
```

```ts
// Kullanım:
import { securityApi } from "../core/axiosClient";
import { productApi }  from "../core/axiosClient";
import { api }         from "../core/axiosClient"; // productApi ile aynı (backward compat)
```

**Her istekte otomatik eklenen headerlar (interceptor):**
- `Authorization: Bearer {token}`
- `X-Company-Code: {companyCode}` → Redux `auth.companyCode` → localStorage `companyCode`

## Tema Renkleri (Flutter ile eşleştirildi)

```scss
$primary:          #667eea   // Flutter AppColors.primary
$primary-hover:    #5568d3
$primary-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%)
```

Header ve sidebar `$primary-gradient` kullanır.  
Tüm `$primary` referansları otomatik güncellenir (SCSS `$primary` değişkeni).

## Proje Yapısı

```
src/
├── core/
│   ├── axiosClient/index.ts    # securityApi + productApi + api (compat)
│   ├── redux/authSlice.ts      # token, user, companyCode
│   └── redux/store.tsx
├── services/
│   └── authService.ts          # securityApi.post("security/authenticate")
├── assets/scss/
│   ├── utils/_variables.scss   # $primary: #667eea, $primary-gradient
│   └── layout/
│       ├── _header.scss        # gradient background
│       └── _sidebar.scss       # $primary renkler, hover rgba
└── environment.tsx             # API_SECURITY_URL, API_PRODUCT_URL sabitleri
```

## AuthSlice Alanları

```ts
interface AuthState {
  token: string | null;
  user: any | null;
  companyCode: string | null;   // X-Company-Code header için
}
// setCredentials({ accessToken, user?, companyCode? })
// logout() → token + companyCode temizler
```

## Yeni Servis Şablonu (Template)

```ts
import { productApi } from "../core/axiosClient";

export const ProductService = {
  list: () => productApi.get<Product[]>("product/api/v1/products"),
  getById: (id: number) => productApi.get<Product>(`product/api/v1/products/${id}`),
  create: (data: CreateProductDto) => productApi.post<Product>("product/api/v1/products", data),
  update: (id: number, data: UpdateProductDto) => productApi.put<Product>(`product/api/v1/products/${id}`, data),
  delete: (id: number) => productApi.delete(`product/api/v1/products/${id}`),
};
```

## Sık Yapılan Hatalar (Template)

| Hata | Çözüm |
|------|-------|
| `api.post("security/authenticate")` | `securityApi.post(...)` kullan |
| `axios.create({ baseURL: '...:8080' })` | `securityApi` (8000) veya `productApi` (8001) kullan |
| `X-Company-Code` eksik | Interceptor otomatik ekliyor, manuel ekleme |
| Renk #FE9F43 (turuncu) | `$primary` SCSS değişkeni veya `#667eea` kullan |
| `Colors.blue` direkt (React'ta) | Ant Design token veya `var(--primary)` CSS değişkeni |

---

# 6. MİMARİ HIZLI BAŞVURU

## Yeni Özellik Ekleme Akışı

```
1. Backend Entity         → TOpenSimpleCompanyEntity extends, @Table, LAZY ilişkiler
2. Backend Repository     → BaseDaoRepository extends, companyCode parametreli sorgular
3. Backend DTO            → Request (@NotBlank validasyon)
                            Response → extends DtoBaseModel, @Data @Builder @NoArgsConstructor @AllArgsConstructor
4. Backend Service        → BaseDbServiceImp extends, readOnly okumalar, save/prepareAndSave
                            getDTOClassForService() → return MyResponse.class
                            toResponse() → toDTO(entity) + manuel FK/enum/computed supplement (§3.13)
                            stream().map().toList()  ← Collectors.toList() DEĞİL
5. Backend Controller     → TOpenException catch + rethrow, diğerleri ExceptionMapper.map
6. Flutter Service        → ApiClient inject, response.data['data'], rethrow
7. service_locator.dart   → Provider<MyService> ekle
8. Flutter Provider       → StateNotifier + autoDispose (gerekiyorsa)
9. Flutter Screen         → ConsumerStatefulWidget şablonu
10. router.dart           → GoRoute ekle
11. Menü                  → menu_screen.dart bölüm ekle (+ rol filtresi)
```

## Hata Yönetimi Zinciri

```
Backend: throw new TOpenException(...)
  ↓ GlobalExceptionHandler
  ↓ ApiResponse { success: false, message: "...", errorCode: 1001 }

Flutter: DioException
  ↓ service: debugPrint + rethrow
  ↓ notifier: state.copyWith(error: e.toString())
  ↓ build(): AppEmptyState.error() VEYA AppToast.error()
```

## Multi-Tenant Veri İzolasyonu

```
Her HTTP isteğinde: X-Company-Code: {companyCode}  ← Flutter ApiClient otomatik ekler
Backend: CompanyContext.get() → ThreadLocal'dan çeker
Repository: HER sorguda companyCode filtresi zorunlu
```

## Soft Delete Kuralı

```java
// Entity'de isDeleted alanı var → asla fiziksel silme
// Listeleme: findByIsDeletedFalse(...)
// Tekil: findByIdAndIsDeletedFalse(id)
// Silme: entity.setIsDeleted(true); save(entity);
```
