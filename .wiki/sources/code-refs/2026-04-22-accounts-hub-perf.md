---
title: AccountsHub Backend Optimization — DB Aggregates + Indexes
type: source
source: .claude/wiki/sources/code-refs/2026-04-22-accounts-hub-perf.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# AccountsHub Backend Optimization

## Amaç
AccountsHub ekranının özet kartları (`totalCustomerReceivable`, `totalSupplierPayable`, `totalOverdueAmount`) ve liste bakiyelerinin yavaş yüklenme problemini DB-side aggregation ve index'lerle çözmek.

## Ne Yapıldı

1. **Controller `toMap` zenginleştirme**: `CustomerControllerImpl.toMap()` — `currentBalance`, `overdueAmount`, `availableCreditLimit`, `isCreditLimitExceeded` alanları eklendi. Aynısı `SupplierControllerImpl` için.
2. **@EntityGraph**: `CustomerRepository`, `SupplierRepository` sorgularına `@EntityGraph(attributePaths = "account")` — N+1 sorununu tek JOIN ile çözer.
3. **DB-side aggregates**: `AccountTransactionRepository`'de `SUM(debit - credit)` gibi aggregate query'ler. Loop yerine JPQL'e taşındı.
4. **Index'ler**: `AccountTransaction` entity'sine `@Index` annotation'ları (companyCode + customerId/supplierId + isCancelled).

## Değişen Dosyalar

- pos-product-manager/src/main/java/com/sedcore/customer/controller/impl/CustomerControllerImpl.java — toMap zenginleştirme
- pos-product-manager/src/main/java/com/sedcore/customer/repository/CustomerRepository.java — @EntityGraph
- pos-product-manager/src/main/java/com/sedcore/supplier/controller/impl/SupplierControllerImpl.java
- pos-product-manager/src/main/java/com/sedcore/supplier/repository/SupplierRepository.java
- pos-product-manager/src/main/java/com/sedcore/finance/controller/impl/AccountStatementControllerImpl.java
- pos-product-manager/src/main/java/com/sedcore/finance/entity/AccountTransaction.java — @Index
- pos-product-manager/src/main/java/com/sedcore/finance/repository/AccountTransactionRepository.java — aggregate JPQL

## Raw Pointer

`commit: 8b6ac05` — `perf(accounts): AccountsHub backend optimization — DB-side aggregates + indexes`

## Kararlar

- [[decisions/use-entity-graph-for-customer-account-fetch]]
- [[decisions/db-side-aggregate-over-java-loop]]

## Sorunlar (çözüldü)

- [[issues/customer-list-balance-zero]] — toMap'te `currentBalance` yoktu
- [[issues/n-plus-one-customer-account-fetch]] — LAZY account, her row için ayrı query

## İlgili

- [[entities/customer]]
- [[entities/customer-account]]
- [[entities/supplier]]
- [[entities/supplier-account]]
- [[entities/account-transaction]]
- [[concepts/pattern-entity-graph-n-plus-one]]
- [[concepts/pattern-dto-tomap-pattern]]
- [[syntheses/flow-accounts-hub-load]]
