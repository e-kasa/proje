# Faz A Migration — AccountsHub List Ekranı (Pattern Örneği)

Bu dosya Faz A pilot PR'ı için **referans pattern**. Kod değişikliği değil, rehber. Backend çalıştırıp spec üretildikten sonra gerçek migration bu şablonu izler.

## Hedef Ekran: AccountsHub List

**Migrate edilecek call**: `AccountService.getCustomerAccount(customerId)` → `/product/api/v1/customers/{id}/account`

## Before (Mevcut — Untyped Map)

```dart
// lib/features/accounts/services/account_service.dart:13-22
Future<Map<String, dynamic>?> getCustomerAccount(String customerId) async {
  try {
    final resp = await _apiClient.get('$_customerBase/$customerId/account');
    final data = resp.data['data'];
    return data is Map<String, dynamic> ? data : null;
  } catch (e) {
    debugPrint('getCustomerAccount hata: $e');
    rethrow;
  }
}

// Consumer (provider veya widget):
final account = await service.getCustomerAccount(id);
final balance = (account?['currentBalance'] as num?)?.toDouble() ?? 0.0;
final isOverLimit = account?['isCreditLimitExceeded'] as bool? ?? false;
// Risk: 'currentBalance' yazımı yanlışsa silent null → 0.0
// Risk: backend alan adı 'currentBalance' → 'balance' rename edilirse sessizce kırılır
```

## After (Typed — Faz A Hedef)

```dart
// lib/features/accounts/services/account_service.dart
import 'package:sedcore_api/api.dart';  // generated'den gelir
import 'package:sedcore_api/model/customer_account_response.dart';

class AccountService {
  final CustomersApi _customersApi;    // generated Dio-backed client

  AccountService(ApiClient client)
      : _customersApi = CustomersApi(client.dio);

  Future<CustomerAccountResponse?> getCustomerAccount(String customerId) async {
    try {
      final resp = await _customersApi.getCustomerAccount(customerId);
      return resp.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}

// Consumer:
final account = await service.getCustomerAccount(id);
final balance = account?.currentBalance ?? BigDecimal.zero;
final isOverLimit = account?.isCreditLimitExceeded ?? false;
// Compile-time garantili: currentBalance yazımı yanlışsa derleme hatası
// Backend rename edilirse regenerate'de model değişir → kullanım yeri derleme hatası verir
```

## Migration Adımları

### 1. Prerequisite check
`lib/api/README.md` "Faz A Prerequisites" 7 maddesi tamamlanmış olmalı.

### 2. pubspec dep ekle
```yaml
# project_pos/pubspec.yaml
dependencies:
  ...
  sedcore_api:
    path: lib/api/generated
```
`flutter pub get` — generated package'ı local path olarak tanır.

### 3. Tek service migrate
- `account_service.dart` içinde **sadece 1 metod** (`getCustomerAccount`) migrate et
- Diğer metodlar mevcut Map-based kalır (aşamalı geçiş)
- Metod signatur'i değiştiği için consumer'lar (`accountsListProvider`, `accountsSummaryProvider`) da güncellenmelidir

### 4. Consumer'ları güncelle
```dart
// provider dosyası — accountsListProvider veya accountsNotifiers
final response = await service.getCustomerAccount(id);
state = state.copyWith(
  currentBalance: response?.currentBalance?.toDouble() ?? 0.0,
  isOverdue: response?.isCreditLimitExceeded ?? false,
);
```

### 5. Test + smoke
- `flutter analyze` temiz
- `flutter run` — AccountsHub list ekranı: müşteri seç → detay aç → bakiye değerleri doğru görünür
- Network tab'da response schema değişmedi (backend Map → typed dto nedeniyle ufak fark olabilir; acceptance: aynı alanlar aynı değerlerle)

### 6. PR
Tek dosya + tek metod scope → küçük PR. Review friendly. Feature flag'e gerek yok çünkü değişiklik yalnız 1 metod consumer'larını etkiler.

## Dikkat Edilecekler

- **BigDecimal**: Backend `BigDecimal currentBalance` → generated dart `num` veya string tipi. Config'te `useBigDecimalForDouble=true` olabilir; gen output'u kontrol et
- **LocalDate / LocalDateTime**: ISO-8601 string döner; dart `DateTime.parse` manuel veya converter gerekir. Generator'da `DateTime` tipine auto-bind yapılır genellikle
- **Nullable**: Backend DTO'da `@NotNull` yoksa dart tipi `T?`. Nullable propagation consumer'a taşınır
- **Map<String,Object> endpoint'leri**: Controller'da `toMap` pattern kullananlar OpenAPI'de `type: object` olarak görünür — generated'da `Object?` gelir. Bunları typed DTO'ya migrate etmek **ayrı iş** ([[patterns/dto-tomap-pattern]] deprecated-candidate)

## Faz B (Sonraki)

`account_service.dart` kalanı migrate edilir:
- `getSupplierAccount`
- `getCustomerTransactions` / `getSupplierTransactions`
- `getStatement` (AccountStatementControllerImpl endpoint'i)
- `getSummary`
- `getOverdue`

Her biri ayrı commit veya aynı PR — review boyutu karar verir.

## Faz C

Diğer feature'lar (sales, purchase, inventory) — feature başına 1 PR. Sales için `cart_panel` `submitSale` → `SalesApi.createSale`. Purchase için batch-entry. vb.

Her feature migration'u [[patterns/openapi-codegen-flutter]] tuzak listesinde referans alarak başlar.

## Related

- `lib/api/README.md` — infra + prerequisites
- `.claude/wiki/patterns/openapi-codegen-flutter.md` — tam pipeline + risk azaltma
- `.claude/wiki/patterns/dto-tomap-pattern.md` — deprecate edilen pattern
