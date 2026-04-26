---
title: Drift Reconcile Backend İmplementasyonu
type: source
source: .claude/wiki/sources/code-refs/2026-04-24-drift-reconcile.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Drift Reconcile Backend İmplementasyonu

## Amaç
Denormalize bakiye (`customer_accounts.current_balance` / `supplier_accounts.current_balance`) ile ledger (`account_transactions` toplamı) arasındaki sapmayı (drift) manuel olarak düzeltecek endpoint + servis katmanı.

## Ne Yapıldı

1. **Repository katmanı**: `AccountTransactionRepository`'ye iki JPQL aggregate:
   - `ledgerTotalsForCustomer(id)` → `[balance, debt, credit, count]`
   - `ledgerTotalsForSupplier(id)` → aynı şema
   - `is_cancelled=false` filtresi uygulanır
2. **Service arayüzü**: `CustomerAccountService` + `SupplierAccountService`'e `reconcile(id)` ve `reconcileAll()` eklendi
3. **Implementation**: Triple eşitlik kontrolü (balance + debt + credit). Drift yoksa `save()` çağrılmaz (idempotent, `@Version` tick etmez)
4. **Admin controller**: `AdminAccountsReconcileControllerImpl` — 3 POST endpoint

## Değişen Dosyalar

- pos-product-manager/src/main/java/com/sedcore/finance/repository/AccountTransactionRepository.java
- pos-product-manager/src/main/java/com/sedcore/customer/service/CustomerAccountService.java
- pos-product-manager/src/main/java/com/sedcore/customer/service/impl/CustomerAccountServiceImpl.java
- pos-product-manager/src/main/java/com/sedcore/supplier/service/SupplierAccountService.java
- pos-product-manager/src/main/java/com/sedcore/supplier/service/impl/SupplierAccountServiceImpl.java
- pos-product-manager/src/main/java/com/sedcore/finance/controller/impl/AdminAccountsReconcileControllerImpl.java (yeni)

## Raw Pointer (commit reference)

`commit: 1b03319` (merge claude/loving-perlman-dbb312) — multi-file backend değişikliği; denormalize cache ↔ ledger senkronizasyonu.

## Kararlar

- [[decisions/manual-reconcile-before-scheduled]] — Scheduled yerine manuel endpoint
- [[decisions/ledger-as-source-of-truth]] — Ledger sapması düzeltilmez, denormalize düzeltilir
- [[decisions/idempotent-reconcile-no-op-guard]] — Drift yoksa save() yapılmaz

## Sorunlar

- [[issues/admin-endpoint-no-preauthorize]] — Endpoint henüz `@PreAuthorize` ile korunmuyor (resolved)
- [[issues/overdue-amount-not-reconciled]] — Reconcile sadece balance/debt/credit (resolved Sprint 2)

## Açık Konular

- Scheduled nightly job (cron) — Sprint 3'te eklendi
- Prometheus/metrics — Sprint 3'te eklendi
- Version bump karşılaştırması (optimistic lock retry davranışı)

## İlgili

- [[entities/customer-account]]
- [[entities/supplier-account]]
- [[entities/account-transaction]]
- [[syntheses/flow-drift-reconciliation]]
- [[concepts/pattern-denormalization-with-reconcile]]
- [[concepts/drift]]
- [[concepts/ledger-vs-denormalize]]
