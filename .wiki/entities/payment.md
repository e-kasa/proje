---
title: Payment
type: entity
source: .claude/wiki/entities/payment.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Payment

## Amaç
Tahsilat veya tedarikçi ödemesi kaydı. `customerId != null` → müşteriden gelen tahsilat, `supplierId != null` → tedarikçiye giden ödeme.

## Kritik Alanlar

| Alan | Tip | Anlam |
|---|---|---|
| paymentType | enum | CASH / CREDIT_CARD / BANK_TRANSFER / CHECK / ... |
| paymentDate | LocalDateTime | Ödeme tarihi (filtreleme için) |
| amount | BigDecimal | Tutar |
| customerId | FK | Tahsilat yönü |
| supplierId | FK | Ödeme yönü (ikisi birlikte null olmaz) |
| isCancelled | Boolean | İptal flag'i |

## PaymentResponse (Client Tarafı Önemli)

Flutter'da client `paymentType` ve `paymentDate` alanlarını okur. `type` ve `date` **YOKTUR** (bkz. [[issues/today-collection-always-zero]]).

Income/expense ayrımı da yoktur — yön `customerId != null` (income) vs `supplierId != null` (expense) ile anlaşılır.

## Tuzaklar

- Alan adı yanlışı → client filter hiçbir zaman eşleşmez → "Bugünkü Tahsilat" 0 gösterir
- `isCancelled=true` ödemeler de toplam'a girerse çift sayım olur
- Payment sonrası `PaymentServiceImpl` → `CustomerAccountService.applyCredit()` veya `SupplierAccountService.applyCredit()` çağırır — [[entities/account-transaction]] yazılır

## Sources

- pos-product-manager/src/main/java/com/sedcore/finance/entity/Payment.java
- pos-product-manager/src/main/java/com/sedcore/finance/model/PaymentResponse.java
- pos-product-manager/src/main/java/com/sedcore/finance/service/impl/PaymentServiceImpl.java
- [[sources/code-refs/2026-04-21-accounts-hub-screens]]
- [[sources/code-refs/2026-04-23-batch-entry-4area]]

## Related

- [[entities/customer-account]]
- [[entities/supplier-account]]
- [[entities/account-transaction]]
- [[syntheses/flow-today-collection-calc]]
- [[issues/today-collection-always-zero]]
