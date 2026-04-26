---
title: Customer (detailed merge from .claude/wiki/)
type: entity
source: .claude/wiki/entities/customer.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
note: "MERGE_NEEDED — .wiki/entities/customer.md is a stub; this is the detailed source. Manuel inceleme: birleştir veya stub'ı bunu işaret edecek şekilde güncelle."
---

# Customer

## Amaç
Müşteri ana kaydı. POS'ta satış anında seçilebilir, cari hesap ekstresi tutan taraflardan biri.

## Kritik Alanlar (özet)

| Alan | Anlam |
|---|---|
| name / phone / email | kimlik |
| creditLimit | BigDecimal(15,2) — kredi limiti |
| address | nakliye / fatura adresi |
| account | 1:1 [[entities/customer-account]] (LAZY) |

## Tuzaklar

- `account` ilişkisi **LAZY** — controller tarafında `@Transactional(readOnly=true)` + `@EntityGraph` olmadan N+1 üretir
- `toMap` çıktısına denormalize `currentBalance` eklenmeli (bkz. [[issues/customer-list-balance-zero]], [[concepts/pattern-dto-tomap-pattern]])

## Sources

- pos-product-manager/src/main/java/com/sedcore/customer/entity/Customer.java
- pos-product-manager/src/main/java/com/sedcore/customer/controller/impl/CustomerControllerImpl.java
- [[sources/code-refs/2026-04-22-accounts-hub-perf]]

## Related

- [[entities/customer-account]]
- [[concepts/pattern-entity-graph-n-plus-one]]
- [[concepts/pattern-dto-tomap-pattern]]
