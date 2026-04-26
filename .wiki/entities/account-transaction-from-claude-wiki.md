---
title: AccountTransaction (detailed merge from .claude/wiki/)
type: entity
source: .claude/wiki/entities/account-transaction.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
note: "MERGE_NEEDED — .wiki/entities/account-transaction.md is brief; this verified version has aggregate query examples + concurrency notes."
---

# AccountTransaction

## Amaç
**Ledger** — tüm hesap hareketlerinin append-only kaydı. SEDCORE'da cari hesap gerçeğinin **source of truth**'u. [[entities/customer-account]] ve [[entities/supplier-account]] buradan türer.

## Kritik Alanlar

| Alan | Tip | Anlam |
|---|---|---|
| customer / supplier | FK | İki taraftan biri dolu; diğeri null |
| debitAmount | BigDecimal | Borç (artışı) |
| creditAmount | BigDecimal | Alacak (ödeme/azalış) |
| runningBalance | BigDecimal | **Hesaplanan** — ekstre görünümünde Java loop'ta dolar |
| isCancelled | Boolean | İptal flag'i — aggregate'lerde `false` filtresi zorunlu |
| transactionDate | LocalDateTime | Hareket tarihi |
| referenceType | enum | SALE / PAYMENT / RETURN / ADJUSTMENT / ... |
| referenceId | String | İlgili Sale/Payment ID |

## Append-Only Semantiği

- Kayıt insert sonrası **değiştirilmez**
- İptal için `isCancelled=true` set edilir — row silinmez
- Ters kayıt atılmaz (yanlış pattern — soft cancel doğru)

## Aggregate Sorguları

```java
// [[sources/code-refs/2026-04-24-drift-reconcile]]
SELECT COALESCE(SUM(t.debitAmount - t.creditAmount), 0),
       COALESCE(SUM(t.debitAmount), 0),
       COALESCE(SUM(t.creditAmount), 0),
       COUNT(t)
FROM AccountTransaction t
WHERE t.isCancelled = false
  AND t.customer.id = :id
```

Bu Object[] tuple → [[entities/customer-account]] denormalize alanlarıyla karşılaştırılır ([[syntheses/flow-drift-reconciliation]]).

## Concurrency Koruması (2026-04-24 ADR revize)

**@Version var** (defense-in-depth). [[decisions/trust-reconcile-no-ledger-version]] ADR revize edildi — A + D kararı: `@Version` runtime lost-update + reconcile kümülatif drift düzeltme.

- Insert anında `version=0` → append-only semantiğinde zararsız (UPDATE yok → hiç tetiklenmez)
- Eğer bir satır gerçekten UPDATE edilirse (`cancel(user)` gibi) @Version runtime'da çakışmayı yakalar

## Tuzaklar

- `isCancelled=false` filtresi UNUTULURSA iptal edilen hareketler de sayıya girer — bakiye şişer
- `runningBalance` DB'de değil, Java loop'ta hesaplanır — aggregate sorgusunda bu alan kullanılmaz
- `cancel(user)` çağrısı `isCancelled=true` UPDATE'i — append-only semantiği "insert-only" değil, "logical append-only" (soft cancel). @Version bu UPDATE'leri korur.

## Sources

- pos-product-manager/src/main/java/com/sedcore/finance/entity/AccountTransaction.java
- pos-product-manager/src/main/java/com/sedcore/finance/repository/AccountTransactionRepository.java
- [[sources/code-refs/2026-04-24-drift-reconcile]]
- [[sources/code-refs/2026-04-22-accounts-hub-perf]]

## Related

- [[entities/customer-account]]
- [[entities/supplier-account]]
- [[concepts/ledger-vs-denormalize]]
- [[concepts/pattern-denormalization-with-reconcile]]
- [[syntheses/flow-drift-reconciliation]]
