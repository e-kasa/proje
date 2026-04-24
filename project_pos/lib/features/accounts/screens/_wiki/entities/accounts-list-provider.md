---
title: accountsListProvider
tags: [entity, provider, riverpod, state]
source: project_pos/lib/features/accounts/providers/accounts_list_provider.dart
date: 2026-04-24
status: draft
---

# accountsListProvider

## Amaç
[[entities/accounts-list-panel]]'in veri kaynağı. **Birleşik müşteri+tedarikçi listesi**, filter + search + overdue highlight.

## Tip
`StateNotifierProvider<AccountsListNotifier, AccountsListState>` (muhtemelen autoDispose).

## State Şeması (tahmini)

```dart
class AccountsListState {
  final List<Map<String, dynamic>> items;   // merged customer + supplier
  final AccountsListFilter filter;          // ALL | CUSTOMER | SUPPLIER | OVERDUE
  final String search;
  final Set<String> overdueIds;             // accountSummaryProvider.overdueList'ten türetilir
  final bool isLoading;
  final String? error;
}
```

## Load Akışı

```
load() async {
  isLoading = true
  final results = await Future.wait([
    accountService.getCustomers(),
    accountService.getSuppliers(),
  ]);
  // merge + accountType ile zenginleştir
  // overdueIds = ref.read(accountSummaryProvider).overdueList.map((e) => e['accountId']).toSet()
  items = merged; isLoading = false;
}
```

## Filter + Search

- **Filter**: tabs ([[entities/accounts-list-panel]]) → `setFilter(AccountsListFilter)` → state update, re-compute visible
- **Search**: input → `setSearch(String)` → isim/telefon eşleşmesi (case-insensitive contains)
- Birleşik getter: `visibleItems` — filter + search + (OVERDUE ise overdueIds intersect)

## Refresh Tetiği

- [[entities/accounts-hub-screen]] init (summary load sonrası)
- [[entities/accounts-hub-screen]] refresh button
- [[entities/account-edit-form]] onSuccess (create veya update)
- [[flows/payment-recording-from-statement]] Sprint 6a sonrası ödeme → bakiye değişikliği → liste refresh

## Tuzaklar

- `overdueIds` kaynağı `accountSummaryProvider` → summary henüz yüklenmediyse boş set → OVERDUE filter yanlış
- [[decisions/overdue-aware-list-ordering]] summary'yi liste'den önce load etmeyi zorunlu kılar
- Merge sırasında accountType zenginleştirme: backend response her iki listede de `accountType` vermezse Flutter ekler

## Sources
- project_pos/lib/features/accounts/providers/accounts_list_provider.dart
- [[entities/account-service]]

## Related
- [[entities/accounts-list-panel]]
- [[entities/selected-account-provider]]
- [[entities/accounts-notifiers]]
- [[decisions/merged-customer-supplier-list]]
- [[decisions/overdue-aware-list-ordering]]
