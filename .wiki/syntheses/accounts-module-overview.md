---
title: Cari Hesap Modülü Genel Bakış
tags: [synthesis, accounts, drift, reconcile]
date: 2026-04-25
status: draft
covers:
  - "[[entities/customer-account]]"
  - "[[entities/supplier-account]]"
  - "[[entities/account-transaction]]"
  - "[[entities/reconcile-audit-log]]"
  - "[[entities/reconcile-scheduled-job]]"
  - "[[sources/code-refs/2026-04-25-sale-checkout-flow]]"
  - "[[sources/code-refs/2026-04-25-purchase-checkout-flow]]"
  - "[[sources/code-refs/2026-04-25-drift-reconciliation-flow]]"
---

# Cari Hesap Modülü

Müşteri + tedarikçi cari hesaplarının POS'taki ana modülü. İki katman ([[concepts/ledger-vs-denormalize]]):

- **Ledger**: [[entities/account-transaction]] — append-only, source of truth
- **Denormalize özet**: [[entities/customer-account]] + [[entities/supplier-account]]

## Yazma Akışları (Drift Kaynakları)

1. [[sources/code-refs/2026-04-25-sale-checkout-flow]] — müşteri vadeli satış → CustomerAccount + AccountTransaction.SALE
2. [[sources/code-refs/2026-04-25-purchase-checkout-flow]] — tedarikçi alımı → SupplierAccount + AccountTransaction.PURCHASE (invoice vs total ayrımı)
3. Ödeme (COLLECTION/PAYMENT), iade (RETURN/SUPPLIER_RETURN), iptal (CANCEL), iskonto (DISCOUNT)

## Drift & Reconcile

Write-through cache + periyodik audit ([[concepts/denormalization-with-reconcile]]):
- Manuel endpoint `/admin/accounts/reconcile` (ADMIN rolü)
- Scheduled nightly ([[entities/reconcile-scheduled-job]]) — multi-tenant, flag-kontrollü
- [[sources/code-refs/2026-04-25-drift-reconciliation-flow]]

## Concurrency

Defense-in-depth ([[decisions/ledger-concurrency-defense-in-depth]]):
- `@Version` runtime (customer-account, supplier-account, account-transaction)
- Reconcile kümülatif (tüm drift kaynakları)

## Operasyonel Olgunluk

| Gap | Durum |
|---|---|
| @PreAuthorize admin endpoint | ✅ Sprint 1 |
| ReconcileAuditLog | ✅ Sprint 1 |
| overdueAmount reconcile | ✅ Sprint 2 |
| Scheduled cron + Slack | ✅ Sprint 3 |
| Micrometer metrics | ✅ Sprint 3 |
| Multi-tenant iterate | ✅ Post-sprint |
| Credit limit enforce + override | ✅ Sprint 5 |
| PDF + email export | ✅ Sprint 5 + mini |
| Pagination ([[issues/accounts-pagination-missing]]) | 🟠 Open |
| Error boundary ([[issues/accounts-error-boundary-missing]]) | 🟠 Open |
| Overdue notification ([[issues/overdue-notification-missing]]) | 🟠 Open |
| Activity log ([[issues/activity-history-missing]]) | 🟡 Open |
| Test coverage ([[issues/test-coverage-unknown]]) | 🟡 Open |

## Sources

- [[raw/code-refs/2026-04-25-accounts-hub-production-readiness]]
- [[raw/code-refs/2026-04-25-sale-checkout-flow]]
- [[raw/code-refs/2026-04-25-purchase-checkout-flow]]
- [[raw/code-refs/2026-04-25-drift-reconciliation-flow]]
- [[raw/code-refs/2026-04-25-ledger-version-adr]]

## Related

- [[syntheses/pos-module-map]]
- [[concepts/drift]]
- [[concepts/ledger-vs-denormalize]]
- [[concepts/denormalization-with-reconcile]]
- [[decisions/ledger-concurrency-defense-in-depth]]
