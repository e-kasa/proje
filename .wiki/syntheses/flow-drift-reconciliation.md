---
title: Flow — Drift Reconciliation
type: synthesis
source: .claude/wiki/flows/drift-reconciliation.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Drift Reconciliation

## Amaç
Denormalize bakiye ↔ ledger arasındaki [[concepts/drift]]'i düzeltir. Ledger kabul edilir, denormalize üstüne yazılır.

## Tetikleyici

İki yol — **manuel** admin endpoint (her zaman açık) veya **scheduled** gece 03:00 cron (Sprint 3, flag-kontrollü).

### Manuel (admin endpoint)
Operator kontrolünde, drift'in ne zaman düzeltildiği takip edilebilir.

### Scheduled (Sprint 3, P1.1 — 2026-04-24)

`ReconcileScheduledJob` (`com.sedcore.finance.job`):
- Cron: `reconcile.scheduled.cron` (default `0 0 3 * * *` — her gece 03:00)
- Flag: `reconcile.scheduled.enabled` (**default `false`**)
- Çağrı: `customerAccountService.reconcileAll()` + `supplierAccountService.reconcileAll()`
- Drift > 0 veya hata varsa [[syntheses/integration-slack-webhook]] bildirimi gönderir
- **Multi-tenant**: `CompanySettingRepository.findAllActiveCompanyCodes()` iterate + per-tenant `CompanyContext.set/clear`

## Endpoint'ler

| Method | Path | Kullanım |
|---|---|---|
| POST | `/product/api/v1/admin/accounts/reconcile` | customer + supplier hepsi |
| POST | `/product/api/v1/admin/accounts/reconcile/customer/{id}` | tek müşteri |
| POST | `/product/api/v1/admin/accounts/reconcile/supplier/{id}` | tek tedarikçi |

## Güvenlik (2026-04-24)

Controller class-level `@PreAuthorize("hasRole('ADMIN')")` — sadece ADMIN rol tetikleyebilir.

## Call Chain

```
POST /reconcile
  → AdminAccountsReconcileControllerImpl [@PreAuthorize hasRole(ADMIN)]
  → CustomerAccountService.reconcileAll()
    → findAll() : List<CustomerAccount>
    → her hesap için:
        → reconcile(customerId)
          → accountTransactionRepository.ledgerTotalsForCustomer(id) → Object[5]
            tuple: [balance, debt, credit, count, overdueAmount]
          → previousBalance − ledgerBalance = drift
          → quadruple eşitlik (balance + debt + credit + overdueAmount)
          → eşitse NO-OP (save() yok, @Version tick yok)
          → farklıysa override + save() — 4 alan birden senkronize
          → reconcileAuditService.recordSingle(...) → SINGLE audit satırı
    → reconcileAuditService.recordSweep(CUSTOMER, corrected) → ALL özet satırı
  → SupplierAccountService.reconcileAll() (simetrik)
  → { customerCorrected, supplierCorrected, totalCorrected }
```

### Overdue Amount Aggregate (Sprint 2, 2026-04-24)

5. aggregate query'sinde:

```jpql
COALESCE(SUM(CASE WHEN (t.isOverdue = true
                        OR (t.dueDate IS NOT NULL
                            AND t.dueDate < CURRENT_DATE
                            AND t.debitAmount > 0))
                   THEN t.debitAmount - t.creditAmount
                   ELSE 0 END), 0)
```

`fetchSummaryAggregates` (AccountsHub özet kartları) ile aynı overdue koşulu — iki kod yolu arasında tutarlılık.

## Audit Trail

Her reconcile çağrısı [[entities/reconcile-audit-log]] entity'sine satır yazar. `ReconcileAuditServiceImpl` **`@Transactional(REQUIRES_NEW)`** kullanır — asıl reconcile rollback olsa bile audit korunur.

## Metrics (Sprint 3, P1.4 — 2026-04-24)

`CustomerAccountServiceImpl.reconcile` + `SupplierAccountServiceImpl.reconcile` Micrometer ile enstrumante:

| Metric | Tip | Tag'ler |
|---|---|---|
| `reconcile.runs.total` | Counter | `entity_type` (CUSTOMER\|SUPPLIER), `scope` (SINGLE\|ALL), `status` (ok\|drift\|error) |
| `reconcile.drift.total` | Counter | `entity_type` |
| `reconcile.duration.seconds` | Timer | `entity_type`, `scope` |

Expose: `/actuator/prometheus`. Detay: [[syntheses/integration-prometheus-micrometer]].

## Kritik Kararlar

- [[decisions/ledger-as-source-of-truth]] — ledger sapması düzeltilmez
- [[decisions/idempotent-reconcile-no-op-guard]] — drift yoksa save yok
- [[decisions/manual-reconcile-before-scheduled]] — scheduled EKLENDİ (Sprint 3, 2026-04-24) ama `enabled=false` default

## Hata Yolları

- `Customer not found` → RuntimeException → `ExceptionMapper.map(e)` → 500
- Ledger query null dönerse → `COALESCE(..., 0)` ile ZERO garanti
- `save()` başarısız → transaction rollback, çağıran loop devam eder

## Kapsam Dışı

- `lastPurchaseDate` / `lastPaymentDate` ledger'dan türetilmiyor
- Ledger yanlışlığını düzeltmez (mantık gereği — gerçek sayılır)
- Cross-company reconcile yok (her tenant kendi `@Filter` kapsamında)

## Sources

- [[sources/code-refs/2026-04-24-drift-reconcile]]
- pos-product-manager/src/main/java/com/sedcore/finance/controller/impl/AdminAccountsReconcileControllerImpl.java
- pos-product-manager/src/main/java/com/sedcore/customer/service/impl/CustomerAccountServiceImpl.java:reconcile

## Related

- [[concepts/drift]]
- [[concepts/ledger-vs-denormalize]]
- [[concepts/pattern-denormalization-with-reconcile]]
- [[entities/customer-account]]
- [[entities/supplier-account]]
- [[entities/account-transaction]]
- [[syntheses/integration-slack-webhook]] (drift alert)
- [[syntheses/integration-prometheus-micrometer]] (metrics export)
