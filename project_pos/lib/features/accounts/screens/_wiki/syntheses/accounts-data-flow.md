---
title: Accounts Data Flow — Veri Akışı
tags: [synthesis, flow, state]
date: 2026-04-24
status: verified
covers:
  - "[[entities/accounts-hub-screen]]"
  - "[[entities/accounts-notifiers]]"
  - "[[entities/accounts-list-panel]]"
  - "[[entities/statement-detail-panel]]"
---

# Accounts Data Flow

Accounts feature'ının **veri akışı** — init load, seçim, refresh, edit.

## 1. Init Load (Hub açılışında)

```
AccountsHubScreen.initState
 └─ addPostFrameCallback:
     ├─ await accountSummaryProvider.load()
     │     → AccountService.getAccountSummary() + getOverdueAccounts()
     │     → summary + overdueList state'te
     ├─ paymentListProvider.load()  [paralel, await yok]
     │     → finance payments
     └─ accountsListProvider.load()  [summary tamamlanmış]
           → /customers + /suppliers merge
           → summary.overdueList'ten overdueIds set türet
```

Summary **await** edilir çünkü list'in overdueIds'e ihtiyacı var ([[decisions/overdue-aware-list-ordering]]).

## 2. Seçim Akışı

```
User → AccountsListPanel satır tap
 → onSelect(StatementArgs args) callback
 → AccountsHubScreen._selectFromList(args, isWide)
     ├─ selectedAccountProvider.state = args
     ├─ accountStatementProvider.setAccount(type, id, name)
     │     → load() otomatik → /account-statements?start&end
     │     → state.statement = Map (openingBalance, transactions[], ...)
     └─ isWide?
         true:  StatementDetailPanel watch ile yenilenir (aynı ekranda)
         false: Navigator.push(_AccountDetailPage)
                  → pop sonrası selectedAccountProvider = null
```

## 3. Refresh

AppBar refresh → `_refresh()`:
```
Future.wait([summary.load(), payments.load()])
 → await accountsListProvider.load()
 → if selectedAccountProvider != null:
     await accountStatementProvider.load()
```

Pull-to-refresh ([[entities/statement-detail-panel]]) sadece `accountStatementProvider.load()` — lokal.

## 4. Edit Akışı

```
User → StatementDetailPanel header edit button
 → _handleEdit(context, ref, StatementArgs)
     ├─ customerService.getCustomerById / supplierService.getSupplierById
     │     → Map<String,dynamic> (initialData)
     └─ showModalBottomSheet:
         AccountEditForm(initialType, editingId, initialData, onSuccess, onCancel)
           → form submit
               → customerService.update / supplierService.update
               → accountsListProvider.load() [silently refresh list]
               → onSuccess() → Navigator.pop(modal)
```

Create akışı aynı ama `initialData = null`, `editingId = null`, trigger **[[entities/accounts-list-panel]]** "Yeni hesap" butonu.

## 5. Date Range Change

```
User → StatementDetailPanel tarih chip tap
 → showDateRangePicker → DateTimeRange
 → accountStatementProvider.setDateRange(start, end)
     → state update + load()
     → statement refresh
```

## Race Condition Koruması

Her notifier load/setAccount/setDateRange sonrası:
```dart
if (!mounted) return;
```
Widget ağacından sökülen notifier sessizce sonlanır.

## Related
- [[syntheses/accounts-screens-overview]]
- `.claude/wiki/flows/accounts-hub-load.md` (backend zinciri)
- [[entities/accounts-notifiers]]
