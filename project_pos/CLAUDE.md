# Project POS - Flutter POS Uygulaması

## Proje Özeti

Çok platformlu (Android, iOS, Web, Desktop) Flutter POS (Satış Noktası) uygulaması. Yedek parça, genel perakende, teknoloji ve ayakkabı/tekstil sektörlerine uyarlanabilir yapıda. Backend API'ye Dio ile bağlanır, JWT kimlik doğrulama kullanır.

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
│   ├── user_model.dart            # User (id, username, displayName, sectorType)
│   ├── auth_state.dart            # AuthState
│   ├── bulk_import_models.dart    # Toplu import modelleri
│   └── ...
├── providers/                     # Riverpod provider'lar
│   ├── auth_provider.dart         # authProvider (StateNotifierProvider<AuthNotifier, AuthState>)
│   └── sector_provider.dart       # sectorConfigProvider, sectorTypeProvider
├── services/                      # Backend API servisleri (27 dosya)
│   ├── service_locator.dart       # Tüm service provider tanımları
│   ├── sales_service.dart         # Satış CRUD + printReceipt
│   ├── product_service.dart       # Ürün CRUD + arama
│   ├── payment_service.dart       # Ödeme işlemleri
│   └── ...
├── screens/                       # Ekranlar (feature-based organizasyon)
│   ├── pos/                       # POS satış ekranı
│   │   ├── pos_screen.dart        # Ana POS (KeyboardListener, kısayollar)
│   │   ├── providers/pos_provider.dart  # CartItem, PosState, PosNotifier, ParkedOrder
│   │   └── widgets/               # PaymentPanel, CartPanel, ReceiptPreviewDialog vb.
│   ├── inventory/                 # Envanter yönetimi
│   │   ├── product_detail_screen.dart   # Ürün ayrıntı (4 tab: Genel, OEM, ÇaprazRef, Araç)
│   │   └── add_product/           # Ürün ekleme wizard
│   │       ├── models/wizard_state.dart # WizardState (ChangeNotifier, sektör-duyarlı)
│   │       └── steps/             # BasicInfo, Variants, StockBarcode, Preview vb.
│   ├── bulk_import/               # Toplu ürün import
│   ├── finance/                   # Finans (gider, gelir, ödeme, nakit akış)
│   ├── reports/                   # Raporlar
│   ├── sales/                     # Satış listesi, detay, iade
│   ├── purchases/                 # Alım listesi, detay, iade
│   ├── suppliers/                 # Tedarikçi yönetimi
│   ├── customers/                 # Müşteri yönetimi
│   ├── stock/                     # Stok yönetimi (transfer, sayım, hareket, alarm)
│   └── settings/                  # Ayarlar (şirket, sektör, kullanıcı yönetimi)
└── widgets/                       # Ek widget'lar (variant, vehicle)
```

## Kritik Mimari Kurallar

### Sektör Konfig Sistemi

Uygulama 4 sektörü destekler. UI etiketleri, görünür alanlar ve davranışlar sektöre göre değişir:

| Sektör | Enum | Özel Alanlar |
|--------|------|-------------|
| Yedek Parça | `SectorType.autoParts` | OEM, araç uyumu, çapraz referans, raf kodu |
| Genel Perakende | `SectorType.general` | Temel ürün bilgileri, barkod, depo |
| Teknoloji | `SectorType.technology` | IMEI, seri no, garanti, renk varyantı |
| Ayakkabı/Tekstil | `SectorType.footwear` | Beden/numara, renk, kumaş, sezon |

```dart
// Sektör config'e erişim
final cfg = ref.watch(sectorConfigProvider);
Text(cfg.labels.productName);  // "Parça" / "Ürün" / "Cihaz" / "Model"
if (cfg.fields.showOem) { ... }
```

### Tasarım Sistemi Widget'ları

Tüm ekranlarda merkezi widget'lar kullanılır. Parametreleri:

```dart
// AppAppBar - title String olmalı, Text() widget'ı DEĞİL
AppAppBar.standard(title: 'Başlık', actions: [...], elevation: 0)
AppAppBar.primary(title: 'Başlık')
AppAppBar.gradient(title: 'Başlık')
// ❌ backgroundColor, flexibleSpace, foregroundColor, leadingOnPressed YOK

// AppButton
AppButton.primary(text: 'Kaydet', onPressed: () {}, icon: Icons.save)
AppButton.success(text: 'Onayla', onPressed: () {})
AppButton.danger(text: 'Sil', onPressed: () {})
AppButton.outline(text: 'İptal', onPressed: () {})
// ❌ AppButton.text() YOK, .outline() kullan
// ❌ label, style, margin, color parametreleri YOK

// AppEmptyState
AppEmptyState.noData(title: '...', description: '...', actionText: '...', onAction: () {})
AppEmptyState.error(title: '...', description: '...', actionText: '...', onAction: () {})
// ❌ message → description kullan
// ❌ actionLabel → actionText kullan
// ❌ onRetry → onAction kullan
```

### AppConstants (lib/core/theme/app_constants.dart)

```dart
// Spacing: spacing4, spacing8, spacing12, spacing16, spacing20, spacing24, spacing32, spacing48
// Radius double: radiusSmall (8), radiusMedium (12), radiusLarge (16)
// BorderRadius getter: borderRadiusSmall, borderRadiusMedium, borderRadiusLarge
// ⚠️ borderRadiusMedium bir BorderRadius nesnesidir, double DEĞİL!
// ❌ BorderRadius.circular(AppConstants.borderRadiusMedium) YANLIŞ
// ✅ AppConstants.borderRadiusMedium DOĞRU

// Padding: paddingSmall, paddingMedium, paddingLarge, pagePadding, cardPadding
// ❌ pagePaddingValue, paddingAllMedium, paddingSymmetricSmall YOK
```

### State Management Pattern

```dart
// Provider tanımı (service_locator.dart'ta)
final salesServiceProvider = Provider<SalesService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SalesService(apiClient);
});

// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) { ... });

// Router provider
final routerProvider = Provider<GoRouter>((ref) { ... });
// ❌ appRouterProvider DEĞİL, routerProvider kullan

// User model
User(id: '', username: '', displayName: '', email: '', selectedCompanyCode: '');
// ❌ fullName DEĞİL → displayName
// ❌ role parametresi YOK
```

### Import Kuralları

```dart
// Derinlikte gömülü dosyalar (screens/pos/widgets/, screens/bulk_import/modals/ vb.)
// için göreceli import YERİNE paket importu kullan:
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/services/service_locator.dart';

// Aynı feature klasöründe göreceli import kullanılabilir:
import '../providers/pos_provider.dart';  // pos/widgets/ → pos/providers/
```

## POS Ekranı Özellikleri

- **Klavye Kısayolları:** F1/Ctrl+P: Ödeme, F5: Yenile, ESC: Arama temizle, Ctrl+Delete: Sepet sıfırla
- **Varyant Seçimi:** Birden fazla varyantı olan ürünlerde seçim dialogu açılır
- **Stok Kontrolü:** Sepetteki miktar stok miktarını aşamaz
- **Park Edilmiş Siparişler:** Sepet park edilebilir, badge ile gösterilir, geri yüklenebilir
- **Hızlı Müşteri:** POS'tan yeni müşteri oluşturulabilir
- **Fiş Yazdırma:** Satış sonrası fiş önizleme ve backend'e yazdırma komutu

## API Yapısı

- **Base URL:** `AppConstants.baseUrl` ile konfigüre edilir
- **Auth:** JWT Bearer token, otomatik refresh
- **Company Header:** `X-Company-Code` her istekte gönderilir
- **Ürün endpoint:** `product/api/v1/products`
- **Satış endpoint:** `product/api/v1/sales`
- **OEM endpoint:** `product/api/oem-numbers/variant/{variantId}`
- **Araç uyumu:** `product/api/vehicle-compatibility/variant/{variantId}`

## Sık Yapılan Hatalar ve Çözümleri

| Hata | Çözüm |
|------|-------|
| `AppAppBar(title: Text('...'))` | `title` String olmalı: `AppAppBar.standard(title: '...')` |
| `AppButton.text(...)` | `.text()` yok, `AppButton.outline(...)` kullan |
| `AppEmptyState(message: '...')` | `description:` kullan |
| `BorderRadius.circular(AppConstants.borderRadiusMedium)` | Direkt `AppConstants.borderRadiusMedium` kullan |
| `ref.watch(appRouterProvider)` | `routerProvider` kullan |
| `User(fullName: '...')` | `displayName` kullan |
| `AppLoadingIndicator()` | `CircularProgressIndicator()` kullan |
| `size: 18` (AppButton) | `size: ButtonSize.small` kullan |
| `import '../../core/widgets/widgets.dart'` (derin klasörden) | `import 'package:project_pos/core/widgets/widgets.dart'` kullan |

## Build ve Test

```bash
# Analiz
flutter analyze

# Build (Android)
flutter build apk

# Build (Web)
flutter build web

# Test
flutter test
```

## Planlanan Mimari İyileştirme: Section-Based Product Details

Mevcut sabit 4 tab yapısı yerine, sektöre göre dinamik section/tab üretimi planlanmaktadır. Detaylar `Sektor_Urun_Ayrintilari_Tasarim_Plani.docx` dokümanındadır.

Ana fikir:
- `DetailSectionType` enum: Her bölüm tipi (generalInfo, pricing, oemNumbers, imeiSerial, warranty, sizeColor vb.)
- `SectorDetailSection` model: type, title, icon, isTab, collapsible, sortOrder, fields
- `SectorConfig.detailSections`: Her sektör kendi bölüm listesini tanımlar
- Section Widget Registry: `DetailSectionType → Widget` mapping
- Yeni sektör = sadece yeni config, widget kodu değişmez
