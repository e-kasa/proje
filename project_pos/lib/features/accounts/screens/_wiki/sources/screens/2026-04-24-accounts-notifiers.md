---
title: accounts_notifiers.dart — 3 StateNotifier
tags: [source, providers, riverpod, state]
source: raw/screens/accounts-notifiers.md
date: 2026-04-24
status: verified
---

# accounts_notifiers.dart

## Amaç
Accounts feature'ının **üç ana state notifier**'ı: özet, overdue takibi, ekstre detay. Hepsi `AccountService` injection'ı ile çalışır.

## İçerik

### 1. AccountSummaryNotifier
- State: `summary` (Map<String,dynamic>?) + `overdueList` + loading/error
- `load()` → `Future.wait([getAccountSummary(), getOverdueAccounts()])` paralel
- `mounted` check her await sonrası — race condition koruması

### 2. OverdueTrackingNotifier
- State: `customerOverdue[]` + `supplierOverdue[]` + per-side loading/error
- `loadCustomerOverdue()` / `loadSupplierOverdue()` / `loadAll()`
- Client-side sort: `dueDate` ASC

### 3. AccountStatementNotifier
- State: `accountType` / `accountId` / `accountName` + dateRange (default son 30 gün) + `statement` Map
- `hasAccount` getter — hesap seçili mi
- `setAccount(...)` → state update + auto `load()`
- `setDateRange(start, end)` → state update + auto `load()`
- Constructor accountId dolu ise auto load

## Sentinel Pattern
```dart
const _sentinel = Object();
// copyWith param default = _sentinel
// _sentinel ise this.xxx kullan, değilse cast + yaz
```
`null` ile "reset this field" ayrımı için idiom. Bkz. [[concepts/sentinel-copy-with]].

## Kritik Kod Noktaları
- [accounts_notifiers.dart:36-59](../../../../providers/accounts_notifiers.dart) — AccountSummaryNotifier
- [accounts_notifiers.dart:103-147](../../../../providers/accounts_notifiers.dart) — OverdueTrackingNotifier
- [accounts_notifiers.dart:204-260](../../../../providers/accounts_notifiers.dart) — AccountStatementNotifier
- [accounts_notifiers.dart:262](../../../../providers/accounts_notifiers.dart) — `const _sentinel = Object()`

## Kararlar
- [[decisions/sentinel-object-for-nullable-copy-with]]
- [[decisions/parallel-summary-overdue-fetch]]

## İlgili
- [[entities/accounts-notifiers]]
- [[concepts/sentinel-copy-with]]
- [[concepts/riverpod-statenotifier-pattern]]

## Sources
- `raw/screens/accounts-notifiers.md`
- `project_pos/lib/features/accounts/providers/accounts_notifiers.dart`
