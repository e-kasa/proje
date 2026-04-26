---
title: Supplier (detailed merge from .claude/wiki/)
type: entity
source: .claude/wiki/entities/supplier.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
note: "MERGE_NEEDED — .wiki/entities/supplier.md is a stub; this is the detailed source."
---

# Supplier

## Amaç
Tedarikçi ana kaydı. Satın alma sürecinde (`Purchase`) kaynak, cari hesap tutan taraf.

## Kritik Alanlar (özet)

| Alan | Anlam |
|---|---|
| name / phone / email / taxNumber | kimlik |
| creditLimit | BigDecimal — tedarikçi tarafından bize tanınan limit |
| account | 1:1 [[entities/supplier-account]] (LAZY) |

## Tuzaklar

- `SupplierResponse.balance` alanı 2026-04-22'ye kadar vardı — `currentBalance`'a rename edildi. Eski client kodu kırılabilir (bkz. [[issues/supplier-list-balance-zero]])
- `account` LAZY — `@EntityGraph` ile birlikte fetch edilmeli

## Sources

- pos-product-manager/src/main/java/com/sedcore/supplier/entity/Supplier.java
- pos-product-manager/src/main/java/com/sedcore/supplier/model/SupplierResponse.java
- [[sources/code-refs/2026-04-22-accounts-hub-perf]]

## Related

- [[entities/supplier-account]]
- [[concepts/pattern-entity-graph-n-plus-one]]
- [[concepts/pattern-dto-tomap-pattern]]
