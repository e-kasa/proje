---
title: accounts_notifiers.dart — State Yönetimi
tags: [entity, providers, riverpod]
source: project_pos/lib/features/accounts/providers/accounts_notifiers.dart
date: 2026-04-24
status: verified
---

# accounts_notifiers.dart

## Amaç
Accounts feature'ının **üç ana StateNotifier**'ını içerir. Hepsi `AccountService` injection'ıyla çalışır.

## Notifier'lar

### 1. AccountSummaryNotifier
**State**: `summary` (toplam bakiye, overdue tutarlar) + `overdueList` + loading/error.

**load()**: `Future.wait([getAccountSummary(), getOverdueAccounts()])` paralel. Özet + overdue tek çağrıda gelir.

**Kullanım**: [[entities/accounts-hub-screen]] initState, [[entities/accounts-summary-bar]] watch, list panel overdueIds source.

### 2. OverdueTrackingNotifier
**State**: `customerOverdue[]` + `supplierOverdue[]` ayrık + per-side loading/error.

**loadCustomerOverdue() / loadSupplierOverdue() / loadAll()**: Bağımsız tetiklenebilir.

**Sort**: client-side `dueDate` ASC.

**Kullanım**: `OverdueTrackingScreen` (ayrı route, bu wiki kapsamı dışı).

### 3. AccountStatementNotifier
**State**: `accountType` + `accountId` + `accountName` + `startDate` + `endDate` (default son 30 gün) + `statement` Map + loading/error.

**hasAccount getter**: `accountId != null && notEmpty`.

**setAccount(type, id, name?)**: state update + auto load.
**setDateRange(start, end)**: state update + auto load.

**Constructor**: `accountId` dolu ise auto load (sonradan `setAccount` gelirse iki load olur — önemsiz).

**Kullanım**: [[entities/statement-detail-panel]] watch + setDateRange.

## Sentinel Pattern

```dart
const _sentinel = Object();

copyWith({Object? summary = _sentinel}) {
  summary: summary == _sentinel ? this.summary : summary as Map<String, dynamic>?;
}
```

`null` (reset et) ile default (değiştirme) ayrımı için idiom. Bkz. [[concepts/sentinel-copy-with]].

## Tuzaklar

- `if (!mounted) return` her await sonrası — asenkron race koruması
- `startDate`/`endDate` copyWith'te sentinel DEĞİL — DateTime default ile reset edilemez (kasıtlı)
- Constructor'da otomatik load — `AccountStatementNotifier(..., accountId: x)` DI yaparsan extra çağrı olur; hub'da `setAccount` sonradan gelir, sorun yok

## Sources
- [[sources/screens/2026-04-24-accounts-notifiers]]
- `project_pos/lib/features/accounts/providers/accounts_notifiers.dart`

## Related
- [[concepts/sentinel-copy-with]]
- [[concepts/riverpod-statenotifier-pattern]]
- [[entities/account-service]]
- [[decisions/parallel-summary-overdue-fetch]]
