---
title: AccountService (Flutter client)
tags: [entity, service, http, flutter]
source: project_pos/lib/features/accounts/services/account_service.dart
date: 2026-04-24
status: draft
---

# AccountService

## Amaç
Flutter client — accounts backend endpoint'leri için HTTP adapter. `Dio` tabanlı, `service_locator.dart` üzerinden provide edilir.

## API (tahmini metot listesi)

```dart
class AccountService {
  Future<Map<String, dynamic>?> getAccountSummary();
  Future<List<Map<String, dynamic>>> getOverdueAccounts({String? accountType});
  Future<Map<String, dynamic>?> getAccountStatement({
    required String accountType,
    required String accountId,
    required String startDate,  // yyyy-MM-dd
    required String endDate,
  });
  // Opsiyonel: getCustomers, getSuppliers — ya ayrı service'lerde ya da burada
}
```

## Endpoint Mapping

| Metot | HTTP |
|---|---|
| getAccountSummary | `GET /product/api/v1/account-statements/summary` |
| getOverdueAccounts | `GET /product/api/v1/account-statements/overdue?accountType=X` |
| getAccountStatement | `GET /product/api/v1/account-statements?accountType=X&accountId=Y&start=...&end=...` |

Backend: [`AccountStatementControllerImpl`](.claude/wiki/sources/code-refs/2026-04-22-accounts-hub-perf.md)

## Çıktı Formatı

Tüm metotlar `Map<String, dynamic>` veya `List<Map<String, dynamic>>` döner — [[concepts/untyped-map-api]] pattern. Typed DTO yok (Sprint 4 OpenAPI codegen planlı).

## Hata İşleme

- Network hata → `DioException` → provider `catch` → state `error` alanı → UI `AppEmptyState.error`
- 4xx/5xx → backend `ApiResponse.error` zarfı → `res.data['message']` okunup exception

## Kullanım

- [[entities/accounts-notifiers]] constructor'ında inject (AccountSummaryNotifier, AccountStatementNotifier, OverdueTrackingNotifier)
- [[entities/accounts-list-provider]] da `getCustomers`/`getSuppliers` için kullanabilir (veya ayrı service)

## Tuzaklar

- Base URL `product/` prefix — gateway api-manager üzerinden — `.claude/wiki/reference/url-routing.md` (ana repo)
- JWT header otomatik interceptor ile eklenir (service_locator seviyesi)
- Map çıktısı → client field adı yazımı hatası silent (`p['paymentType']` yerine `p['type']` → null) — bkz. [[issues/today-collection-always-zero-ref]]

## Sources
- project_pos/lib/features/accounts/services/account_service.dart
- project_pos/lib/services/service_locator.dart (provider)
- `.claude/wiki/entities/account-transaction.md`

## Related
- [[entities/accounts-notifiers]]
- [[entities/accounts-list-provider]]
- [[concepts/untyped-map-api]]
- [[flows/accounts-data-flow]]
