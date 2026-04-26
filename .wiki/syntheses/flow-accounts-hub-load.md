---
title: Flow — AccountsHub Load
type: synthesis
source: .claude/wiki/flows/accounts-hub-load.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# AccountsHub Load Flow

## Amaç
Cari Hesaplar ekranı açıldığında 4 özet kartı + müşteri/tedarikçi liste + boş detay panel render edilmesi.

## Tetikleyici
Flutter router → `AccountsHubScreen`.

## Call Chain

```
AccountsHubScreen.build()
  ├─ accountsSummaryProvider
  │   → GET /product/api/v1/account-statements/summary
  │   → { totalCustomerReceivable, totalSupplierPayable, totalOverdueAmount, ... }
  │
  ├─ todayPaymentsProvider
  │   → GET /product/api/v1/payments?date=today
  │   → List<PaymentResponse>
  │   → accounts_summary_bar._todayCollection(payments) filter
  │
  ├─ accountsListProvider
  │   → GET /product/api/v1/customers   + GET /product/api/v1/suppliers
  │   → merge + sort
  │   → list panel render (satırda currentBalance)
  │
  └─ selectedAccountProvider (user click)
      → GET /product/api/v1/account-statements?accountId=X
      → openingBalance + transactions[] + closingBalance
      → statement_detail_panel render
```

## Performans Kritik Noktalar

- `/customers` + `/suppliers` `@EntityGraph(attributePaths = "account")` kullanır — tek JOIN, N+1 yok (bkz. [[concepts/pattern-entity-graph-n-plus-one]])
- Summary endpoint DB-side `SUM` yapar — Java loop yok (bkz. [[decisions/db-side-aggregate-over-java-loop]])
- toMap denormalize alanları direkt çıkarır — her satır için ayrı query yok

## Geçmiş Buglar

- [[issues/customer-list-balance-zero]] — toMap `currentBalance` atlıyordu
- [[issues/supplier-list-balance-zero]] — DTO field adı `balance` → `currentBalance` rename
- [[issues/today-collection-always-zero]] — client filter yanlış alan adı okuyordu

## Sources

- [[sources/code-refs/2026-04-21-accounts-hub-screens]]
- [[sources/code-refs/2026-04-22-accounts-hub-perf]]
- project_pos/lib/features/accounts/screens/accounts_hub_screen.dart

## Related

- [[syntheses/flow-today-collection-calc]]
- [[entities/customer]]
- [[entities/supplier]]
- [[entities/customer-account]]
- [[entities/account-transaction]]
- [[syntheses/accounts-overview]]
