---
title: CustomerAccount (detailed merge from .claude/wiki/)
type: entity
source: .claude/wiki/entities/customer-account.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
note: "MERGE_NEEDED — .wiki/entities/customer-account.md is a brief draft; this is the verified detailed source. Manuel inceleme önerilir."
---

# CustomerAccount

## Amaç
Müşteri cari bakiyesinin **denormalize özeti**. Ledger ([[entities/account-transaction]]) source of truth; bu entity okuma hızı için cache.

## Kritik Alanlar

| Alan | Tip | Anlam |
|---|---|---|
| currentBalance | BigDecimal(15,2) | Güncel bakiye (+ alacak / − borç) |
| totalDebt | BigDecimal(15,2) | Kümülatif borç (satışlar) |
| totalCredit | BigDecimal(15,2) | Kümülatif alacak (tahsilatlar) |
| overdueAmount | BigDecimal(15,2) | Vadesi geçmiş tutar |
| availableCreditLimit | BigDecimal(15,2) | Hesaplanan: creditLimit − currentBalance |
| isCreditLimitExceeded | Boolean | Hesaplanan: currentBalance > creditLimit |
| totalTransactionCount | Long | Hareket sayısı |
| lastPurchaseDate | LocalDateTime | Son alış tarihi |
| lastPaymentDate | LocalDateTime | Son ödeme tarihi |
| version | Long (@Version) | Optimistic lock — yarış önleme |

## Beslenme Akışı

1. `SaleService` satışta → `applyDebit()` → `currentBalance += amount`, `totalDebt += amount`
2. `PaymentService` tahsilatta → `applyCredit()` → `currentBalance -= amount`, `totalCredit += amount`
3. İptal → `reverseDebit()` / `reverseCredit()` (simetrik)
4. Drift tespit → [[syntheses/flow-drift-reconciliation]] → ledger'dan yeniden hesapla

## Tuzaklar

- **@Version zorunlu** — paralel sale + payment `OptimisticLockException` atabilir, retry davranışı çağıran katmanda
- **[[entities/account-transaction]] üzerinde @Version VAR** (2026-04-24 revize) — defense-in-depth
- `toMap` içinde denormalize alanları doğrudan çıktıya basmalı (bkz. [[concepts/pattern-dto-tomap-pattern]])
- `account` ilişkisi LAZY — `@EntityGraph` olmadan fetch N+1 üretir (bkz. [[concepts/pattern-entity-graph-n-plus-one]])

## Sources

- pos-product-manager/src/main/java/com/sedcore/customer/entity/CustomerAccount.java
- pos-product-manager/src/main/java/com/sedcore/customer/service/impl/CustomerAccountServiceImpl.java
- [[sources/code-refs/2026-04-24-drift-reconcile]]
- [[sources/code-refs/2026-04-22-accounts-hub-perf]]

## Related

- [[entities/customer]]
- [[entities/supplier-account]]
- [[entities/account-transaction]]
- [[syntheses/flow-drift-reconciliation]]
- [[concepts/pattern-denormalization-with-reconcile]]
- [[concepts/ledger-vs-denormalize]]
- [[concepts/drift]]
