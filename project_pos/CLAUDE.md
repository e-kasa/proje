# Project POS - Flutter POS Uygulaması

## Proje Özeti

Çok platformlu (Android, iOS, Web, Desktop) Flutter POS (Satış Noktası) uygulaması. Yedek parça, genel perakende, teknoloji ve ayakkabı/tekstil sektörlerine uyarlanabilir yapıda. Backend API'ye Dio ile bağlanır, JWT kimlik doğrulama kullanır.

**Backend projesi:** `../pos-product-manager/` (aynı parent dizinde, kendi CLAUDE.md'si var)

## Teknoloji Stack

- **Framework:** Flutter (Dart SDK ^3.11.1)
- **State Management:** flutter_riverpod (StateNotifier + Provider pattern)
- **Navigation:** go_router (declarative routing)
- **HTTP Client:** dio (JWT interceptor, token refresh, company code header)
- **Yerel DB:** sqflite
- **Grafik:** fl_chart
- **Barkod:** mobile_scanner
- **Paket adı:** `project_pos`

## Proje Yapısı

```
lib/
├── core/                          # Çekirdek altyapı
│   ├── api/api_client.dart        # Dio tabanlı HTTP client (JWT, refresh, company header)
│   ├── config/sector_config.dart  # Sektör konfig sistemi (enum, labels, fields)
│   ├── constants/app_constants.dart  # Sabitler (API URL, renkler, chart renkleri)
│   ├── theme/
│   │   ├── app_colors.dart        # Renk paleti (primary, success, danger, bgLight vb.)
│   │   └── app_constants.dart     # UI sabitleri (spacing, radius, padding getter'ları)
│   ├── utils/
│   │   ├── router.dart            # GoRouter tanımı, routerProvider
│   │   ├── i18n_helper.dart       # i18nOf(ref), i18nMsgOf(ref)
│   │   └── app_logger.dart        # Loglama
│   ├── widgets/                   # Tasarım sistemi bileşenleri
│   │   ├── app_app_bar.dart       # AppAppBar (standard, primary, gradient factory)
│   │   ├── app_button.dart        # AppButton (primary, success, danger, outline factory)
│   │   ├── app_card.dart          # AppCard
│   │   ├── app_empty_state.dart   # AppEmptyState (noData, error factory)
│   │   ├── app_input.dart         # AppInput
│   │   └── widgets.dart           # Barrel export
│   └── layouts/
│       └── responsive_layout.dart # ShellRoute layout (drawer + bottom nav)
├── models/                        # Veri modelleri
├── providers/                     # Riverpod provider'lar
│   ├── auth_provider.dart         # authProvider (StateNotifierProvider<AuthNotifier, AuthState>)
│   └── sector_provider.dart       # sectorConfigProvider, sectorTypeProvider
├── services/                      # Backend API servisleri
│   └── service_locator.dart       # Tüm service provider tanımları
├── screens/                       # Ekranlar (feature-based organizasyon)
│   ├── pos/                       # POS satış ekranı
│   │   ├── pos_screen.dart        # Ana POS (KeyboardListener, kısayollar)
│   │   ├── providers/pos_provider.dart  # CartItem, PosState, PosNotifier
│   │   └── widgets/               # PaymentPanel, CartPanel, RecommendationPanel vb.
│   ├── inventory/                 # Envanter (ürün detay: 6 tab — Genel, OEM, ÇaprazRef, Araç, Geçmiş, İlişkiler)
│   ├── finance/                   # Finans (gider, gelir, ödeme, nakit akış)
│   ├── reports/                   # Raporlar
│   ├── sales/                     # Satış listesi, detay, iade
│   ├── purchases/                 # Alım listesi, detay, iade
│   ├── stock/                     # Stok yönetimi (transfer, sayım, hareket, alarm)
│   └── settings/                  # Ayarlar
└── widgets/                       # Ek widget'lar
```

---

## KOD YAZIM STİLİ (Yeni oturumda ilk oku!)

### 1. Ekran Yapısı Şablonu

```dart
class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  String Function(String) get t => i18nOf(ref);  // i18n her ekranda böyle alınır

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
    return Scaffold(
      backgroundColor: AppColors.bgLight,                    // ← HER ekranda
      appBar: AppAppBar.standard(title: t('screen.title')),  // ← String, Text() DEĞİL
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppEmptyState.error(title: t('common.error'), description: _error!)
              : _items.isEmpty
                  ? AppEmptyState.noData(title: t('common.no_data'))
                  : _buildContent(),
    );
  }
}
```

### 2. State Management (StateNotifier)

```dart
// İmmutable state class — copyWith + clear* flagları
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

// Notifier — _ref ile diğer provider'lara erişir
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

// Provider tanımı
final myProvider = StateNotifierProvider.autoDispose<MyNotifier, MyState>(
  (ref) => MyNotifier(ref),
);
```

### 3. Servis (API Çağrıları)

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
      rethrow;  // ← HER ZAMAN rethrow, caller handle eder
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    try {
      await _apiClient.post('product/api/v1/items', data: data);
    } catch (e) {
      debugPrint('create hata: $e');
      rethrow;
    }
  }
}

// Provider (service_locator.dart'ta)
final myServiceProvider = Provider<MyService>((ref) {
  return MyService(ref.watch(apiClientProvider));
});
```

### 4. Form Kaydetme Akışı

```dart
Future<void> _save() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isLoading = true);
  try {
    await ref.read(myServiceProvider).create({
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    });
    if (mounted) {
      AppToast.success(context, t('common.saved'));
      Navigator.pop(context, true);  // true = veri değişti, önceki ekran yenilesin
    }
  } catch (e) {
    if (mounted) AppToast.error(context, '$e');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

### 5. Dialog Açma

```dart
// Basit onay dialogu
final confirmed = await AppConfirmationDialog.showDelete(
  context: context, title: 'Sil', message: 'Emin misiniz?',
);
if (!confirmed) return;

// Özel dialog
showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
    title: const Text('Başlık'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [...]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
      ElevatedButton(onPressed: () { /* ... */ Navigator.pop(ctx); }, child: const Text('Tamam')),
    ],
  ),
);
```

### 6. Liste Kartı

```dart
ListView.separated(
  padding: const EdgeInsets.all(16),
  itemCount: items.length,
  separatorBuilder: (_, __) => const SizedBox(height: 12),
  itemBuilder: (context, index) {
    final item = items[index];
    return AppCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(Icons.xxx, color: AppColors.primary),
        ),
        title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(item['description'] ?? ''),
        trailing: Text('₺${item['price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
      ),
    );
  },
)
```

---

## Tasarım Sistemi Kuralları

### Widget API'leri (Kesin Kullanım)

```dart
// ✅ DOĞRU                           // ❌ YANLIŞ
AppAppBar.standard(title: 'Başlık')   // AppAppBar(title: Text('Başlık'))
AppAppBar.primary(title: 'Başlık')    // AppBar(title: ...)
AppButton.primary(text: 'Kaydet')     // AppButton.text(...)
AppButton.outline(text: 'İptal')      // AppButton(label: ...)
AppButton.danger(text: 'Sil')         // ElevatedButton(...)  — basit butonlar hariç
AppEmptyState.noData(description: '') // AppEmptyState(message: '')
AppEmptyState.error(description: '')  // AppEmptyState(onRetry: ...)
AppConstants.borderRadiusMedium       // BorderRadius.circular(AppConstants.borderRadiusMedium)
CircularProgressIndicator()           // AppLoadingIndicator()
ButtonSize.small                      // size: 18
```

### Renkler — HER ZAMAN `AppColors.xxx`

```dart
AppColors.primary        // Ana renk (#667eea)
AppColors.success        // Başarı (#10b981)
AppColors.danger         // Tehlike (#ef4444)
AppColors.warning        // Uyarı (#f59e0b)
AppColors.info           // Bilgi
AppColors.textPrimary    // Ana metin (#111827)
AppColors.textSecondary  // İkincil metin
AppColors.textMuted      // Soluk metin (#9ca3af)
AppColors.bgLight        // Scaffold arka plan (#f9fafb)
AppColors.bgSuccess      // Yeşil arka plan
AppColors.bgDanger       // Kırmızı arka plan
// ❌ Colors.blue, Colors.grey KULLANMA (Colors.white hariç)
```

### Spacing — `AppConstants.spacing*`

```dart
const SizedBox(height: AppConstants.spacing16)     // Elemanlar arası
const SizedBox(height: AppConstants.spacing24)     // Bölümler arası
AppConstants.paddingSmall      // EdgeInsets.all(8)
AppConstants.paddingMedium     // EdgeInsets.all(16)
AppConstants.pagePadding       // EdgeInsets.all(16)
AppConstants.borderRadiusSmall  // BorderRadius(8)  ← NESNE, double DEĞİL
AppConstants.borderRadiusMedium // BorderRadius(12) ← NESNE, double DEĞİL
```

### Metin Stilleri

```dart
// Font boyutları: 11 (muted), 12 (small), 13 (form), 14 (body), 16 (subtitle), 18+ (header)
Text('Başlık', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
Text('Normal', style: TextStyle(fontSize: 14, color: AppColors.textPrimary))
Text('Açıklama', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
// ❌ Theme.of(context).textTheme KULLANMA — inline TextStyle + AppColors
```

### i18n

```dart
final t = i18nOf(ref);       // Widget içinde
t('pos.title')               // → "POS Satış"
t('common.save')             // → "Kaydet"
t('common.error')            // → "Hata"
// Namespace'ler: common, pos, sales, stock, finance, inventory, product, settings
```

### Import Kuralları

```dart
// Derin klasörlerden (screens/pos/widgets/ gibi) → paket import:
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/services/service_locator.dart';

// Aynı feature içinde → göreceli import OK:
import '../providers/pos_provider.dart';
```

---

## Sektör Konfig Sistemi

| Sektör | Enum | Özel Alanlar |
|--------|------|-------------|
| Yedek Parça | `SectorType.autoParts` | OEM, araç uyumu, çapraz referans, raf kodu |
| Genel Perakende | `SectorType.general` | Temel ürün bilgileri, barkod, depo |
| Teknoloji | `SectorType.technology` | IMEI, seri no, garanti, renk varyantı |
| Ayakkabı/Tekstil | `SectorType.footwear` | Beden/numara, renk, kumaş, sezon |

```dart
final cfg = ref.watch(sectorConfigProvider);
Text(cfg.labels.productName);  // "Parça" / "Ürün" / "Cihaz" / "Model"
if (cfg.fields.showOem) { /* OEM widget'ı göster */ }
```

## POS Ekranı

- **Klavye Kısayolları:** F1/Ctrl+P: Ödeme, F5: Yenile, ESC: Arama temizle, Ctrl+Delete: Sepet sıfırla
- **Varyant Seçimi:** Birden fazla varyantı olan ürünlerde seçim dialogu açılır
- **Stok Kontrolü:** Sepetteki miktar stok miktarını aşamaz
- **Öneri Paneli:** 5 tip badge — CROSS_REFERENCE (kırmızı), SIMILAR (mor), ALTERNATIVE (turuncu), COMPLEMENTARY (turkuaz), FREQUENTLY (yeşil)

## API Yapısı

```
Base: AppConstants.baseUrl
Auth: JWT Bearer token + otomatik refresh
Header: X-Company-Code (her istekte)

Ürünler:      product/api/v1/products
Satış:        product/api/v1/sales
Stok hareket: product/api/v1/stock-movements?variantId=...
Öneriler:     product/api/v1/recommendations/hybrid?productIds=...&variantIds=...
OEM:          product/api/oem-numbers/variant/{variantId}
Çapraz Ref:   product/api/cross-reference/variant/{variantId}
Araç uyumu:   product/api/v1/vehicle-compatibility/variant/{variantId}
```

## Sık Yapılan Hatalar

| Hata | Çözüm |
|------|-------|
| `AppAppBar(title: Text('...'))` | `title` String olmalı: `AppAppBar.standard(title: '...')` |
| `AppButton.text(...)` | `.text()` yok → `AppButton.outline(...)` |
| `AppEmptyState(message: '...')` | `description:` kullan |
| `BorderRadius.circular(AppConstants.borderRadiusMedium)` | Direkt `AppConstants.borderRadiusMedium` |
| `ref.watch(appRouterProvider)` | `routerProvider` kullan |
| `User(fullName: '...')` | `displayName` kullan |
| `AppLoadingIndicator()` | `CircularProgressIndicator()` kullan |
| `import '../../core/widgets/...'` (derin klasör) | `import 'package:project_pos/core/widgets/...'` |
| `Colors.blue` direkt kullanım | `AppColors.info` veya uygun AppColors |
| `catch (_) {}` sessiz hata yutma | `catch (e) { debugPrint('$e'); }` en azından logla |

## Build ve Test

```bash
flutter analyze                              # 0 error, 0 warning hedefi
flutter build apk / web                      # Build
flutter test                                 # Test
cd ../pos-product-manager && mvn compile     # Backend derleme
```

## Backend Hakkında (Kısa Referans)

Detaylar: `../pos-product-manager/CLAUDE.md`

- **Controller:** try { ApiResponse.success(data) } catch(TOpenException) { throw } catch(Exception) { ExceptionMapper.map(e) }
- **Company scoping:** `CompanyContext.get()` her sorguda
- **TMessageType:** Final enum, genişletilemez. Sadece: `FIELD_IS_REQUIRED_1001`, `NOT_EXISTS_IN_THE_RECORDS_1006`, `ENTERED_DATA_IS_NOT_IN_FORMAT_1046`
- **Stok tipleri:** PURCHASE_IN, SALE_OUT, SALE_RETURN_IN, SALE_CANCEL_IN, PURCHASE_RETURN_OUT, TRANSFER_IN/OUT, ADJUSTMENT_IN/OUT
- **Öneri kaynakları:** frequentlyBought + similar/alternative/complementary + crossReference
- **Seed data:** SEDCORE (7 oto varyant) + SEDCORE1 (15 elbise varyant) + 28 cross_references + 9 tip stok hareketi
