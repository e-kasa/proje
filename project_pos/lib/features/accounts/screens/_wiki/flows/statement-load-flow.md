---
title: Statement Load Flow — Ekstre Yükleme Akışı
tags: [flow, state, accounts]
source: project_pos/lib/features/accounts/providers/accounts_notifiers.dart (AccountStatementNotifier)
date: 2026-04-24
status: verified
---

# Statement Load Flow

## Amaç
Kullanıcı bir hesap seçtiğinde ya da tarih aralığı değiştirdiğinde [[entities/statement-detail-panel]] ekstre verisini yeniden çeker ve render eder.

## Tetikleyiciler

1. **Liste satır tıklama** → [[entities/accounts-hub-screen]] `_selectFromList(args)` → `accountStatementProvider.setAccount(type, id, name)` → auto `load()`
2. **Tarih aralığı picker** → [[entities/statement-detail-panel]] `_pickDateRange` → `setDateRange(start, end)` → auto `load()`
3. **Pull-to-refresh** → `RefreshIndicator.onRefresh` → `load()` (accountId değişmez, yalnız yenile)
4. **Hub genel refresh** → `_refresh()` → `if (hasAccount) accountStatementProvider.load()`

## Call Chain

```
trigger → AccountStatementNotifier.load()
 ├─ state.copyWith(isLoading: true, error: null)
 ├─ accountService.getAccountStatement(type, id, startStr, endStr)
 │    → GET /product/api/v1/account-statements?accountType=...&accountId=...&start=...&end=...
 │    → Backend AccountStatementControllerImpl (DB-side aggregate, per [sources](.../sources/code-refs/2026-04-22-accounts-hub-perf.md))
 │    → Map<String, dynamic> response
 │       {openingBalance, closingBalance, totalDebit, totalCredit, transactions[]}
 ├─ mounted check
 └─ state.copyWith(statement: data, isLoading: false)
```

## Hata Yolları

| Durum | State | UI |
|---|---|---|
| Network fail | `error: e.toString()` | `AppEmptyState.error` + refresh btn |
| Backend 500 | `error: ...` | aynı |
| `hasAccount=false` | `load()` no-op | empty state prompt |
| Mounted false (widget ağaçtan çıktı) | sessizce return | — |

## State Sözleşmesi

```dart
{
  accountType: String?      // CUSTOMER|SUPPLIER (setAccount sonrası)
  accountId: String?        // hesap ID
  accountName: String?      // display only
  startDate: DateTime       // default now()−30
  endDate: DateTime         // default now()
  statement: Map?           // backend response (fields extracted in detail panel)
  isLoading: bool
  error: String?
}
```

## Tarih Formatı

Client → backend: `yyyy-MM-dd` string (`_fmt(DateTime)` helper). Backend `LocalDate` parse.

## Race Koruması

- `mounted` check her await sonrası → widget ağaçtan sökülen notifier sessizce sonlanır
- İki hızlı `setAccount` çağrısı → iki load → son biten kazanır (race). Nadir ama mümkün; state son yazılan değer.

## Sources
- [[entities/accounts-notifiers]] (AccountStatementNotifier sınıfı)
- [[entities/statement-detail-panel]] (tüketici)
- [[entities/account-service]] (HTTP layer)
- `.claude/wiki/sources/code-refs/2026-04-22-accounts-hub-perf.md` (backend aggregate)

## Related
- [[flows/accounts-data-flow]] — tüm flow'ların üst hikayesi
- [[entities/selected-account-provider]]
- [[concepts/sentinel-copy-with]]
- `.claude/wiki/flows/accounts-hub-load.md` (üst seviye zincir)
