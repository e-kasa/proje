---
title: Pattern — @EntityGraph ile N+1 Önleme
type: concept
source: .claude/wiki/patterns/entity-graph-n-plus-one.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# @EntityGraph ile N+1 Önleme

## Problem
`Customer.account` (1:1 to [[entities/customer-account]]) ilişkisi LAZY. Controller `findAll()` → her row için ayrı `SELECT * FROM customer_accounts WHERE customer_id=?` → N+1 query.

## Çözüm
Repository metodunun üzerine `@EntityGraph(attributePaths = "account")` — Hibernate sorguya JOIN FETCH ekler.

```java
@EntityGraph(attributePaths = "account")
@Query("SELECT c FROM Customer c WHERE c.isActive = true AND c.isDeleted = false")
List<Customer> search(...);
```

## SEDCORE'da Uygulanan Yerler

- `CustomerRepository.search()` — AccountsHub liste ekranı
- `SupplierRepository.findByIsActiveAndIsDeleted()` — tedarikçi listesi
- `SupplierRepository.findByIsDeleted()` — admin filter

## Ne Zaman Kullanılmaz

- Liste ekranında `account` alanı GEREKMİYORSA — ekstra JOIN gereksiz yük
- Çok-to-çok ilişkilerde cartesian product riski — `@EntityGraph` yerine DTO projection

## Alternatifler

- **JOIN FETCH** JPQL içinde — aynı etki, daha açık
- **DTO projection** — `SELECT new CustomerDto(c.id, c.name, ca.currentBalance) FROM Customer c LEFT JOIN c.account ca` — tam kontrol
- **EAGER fetch (entity-level)** — her sorguda JOIN, kötü pratik

## Tuzaklar

- `LAZY` alanını hala `@Transactional(readOnly=true)` olmayan controller'dan okuma → `LazyInitializationException`. `@EntityGraph` sorgu anında fetch eder ama hala transaction kapsamında olmak gerekir
- Nested path: `@EntityGraph(attributePaths = {"account", "account.user"})`
- `@NamedEntityGraph` alternatif syntax — entity üzerinde tanımlı

## Sources

- [[sources/code-refs/2026-04-22-accounts-hub-perf]]
- pos-product-manager/src/main/java/com/sedcore/customer/repository/CustomerRepository.java

## Related

- [[entities/customer]]
- [[entities/supplier]]
- [[syntheses/flow-accounts-hub-load]]
- [[concepts/pattern-dto-tomap-pattern]]
