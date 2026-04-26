---
title: Flow — Sale Checkout
type: synthesis
source: .claude/wiki/flows/sale-checkout.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Sale Checkout Flow

## Amaç

POS kasasında bir satışı kaydederken stok düşüşü + cari hesap hareketi + ledger entry'yi atomik bir transaction içinde yapmak.

## Tetikleyici

Flutter `POS cart_panel` → `POST /product/api/v1/sales` → `SaleControllerImpl.createSale(SaleRequest)` → `SaleServiceIntegrated.createSale(request)`.

## Akış (7 Adım)

```
createSale(request) [@Transactional]
 ├─ 1. saleNumber oto-doldur (POS-yyyyMMdd-XXXXXX)
 │
 ├─ 2. KALEMLERİ HESAPLA (mem — henüz save yok)
 │     for each SaleItemRequest:
 │       gross = unitPrice × qty
 │       discAmt = gross × discountRate/100
 │       net = gross − discAmt
 │       taxAmt = net × taxRate/100
 │       lineTotal = net + taxAmt
 │
 ├─ 3. DEFANSİF GUARD — vadeli satış için müşteri zorunlu
 │     if (customerId == null && paid < grandTotal) throw
 │
 ├─ 4. MÜŞTERİ KONTROL (customerId varsa)
 │     customer = customerRepository.findById(...)
 │     checkCreditLimit(customer, grandTotal, overrideRequested)
 │
 ├─ 5. SALE KAYDET (save + items)
 │
 ├─ 6. STOK HAREKETLERİ + StockLevel atomik decrement
 │     for each savedItem:
 │       stockLevelService.deductStock(variantId, locationId, qty) ← PESSIMISTIC_WRITE
 │       StockMovement(SALE_OUT, sale=sale) save
 │
 └─ 7. VERESİYE → CARİ + LEDGER
       if (sale.isOnCredit()):
         account.applyDebit(remaining)
         AccountTransaction { type=SALE, debit=remaining, ... } save
```

## Side Effects

| Tablo | Etki |
|---|---|
| `sales` | +1 row |
| `sale_items` | +N row |
| `stock_movements` | +N row (type=SALE_OUT) |
| `stock_levels` | N row update (quantity decrement) |
| `customer_accounts` | 1 row update (sadece vadeli) |
| `account_transactions` | +1 row (sadece vadeli, type=SALE) |

## Credit Limit Check (Sprint 5 P2.5)

```java
checkCreditLimit(customer, saleAmount, overrideRequested):
  if (c.creditLimit == null || == 0) return;
  balance = customerAccountRepository.currentBalance or 0
  if (balance + saleAmount <= c.creditLimit) return;

  if (!overrideRequested) throw "Kredi limiti yetersiz! (override gerekli)"
  if (!currentUserHasCreditLimitOverride()) throw "override yetkisi yok"

  log.warn("Kredi limiti OVERRIDE: ...")
```

`currentUserHasCreditLimitOverride` → `SecurityContextHolder.auth.authorities` içinde **`ROLE_ADMIN` \| `ROLE_STORE_ADMIN` \| `CREDIT_LIMIT_OVERRIDE`** arar.

**Flutter entegrasyonu**: `SaleRequest.overrideCreditLimit` Boolean. Backend "Kredi limiti..." hata → `PaymentPanel._submitWithCreditLimitFallback` confirm dialog → `submitSale(overrideCreditLimit: true)`.

Bkz. [[decisions/credit-limit-override-role-based]].

## Race / Concurrency

- **StockLevel**: `deductStock` **PESSIMISTIC_WRITE lock** — iki paralel satış aynı variant × location'a çakışırsa biri bekler
- **CustomerAccount** (`@Version`): paralel vadeli satış aynı müşteri → lost update'ten opt-lock korur
- **AccountTransaction**: `@Version` + append-only semantiği. A+D defense-in-depth

## Hata Yolları

| Durum | Davranış | Rollback? |
|---|---|---|
| Variant yok | `RuntimeException` | Evet |
| Vadeli ama customer null | `RuntimeException` | Evet |
| Credit limit aşım | `RuntimeException` | Evet |
| StockLevel quantity yetersiz | `TOpenException` | Evet |
| Transaction kopuk | JPA rollback | Tam rollback |

## İptal ve İade

- `cancelSale(saleId, reason)` → stok ters kayıt + soft cancel + AccountTransaction `CANCEL` tipi
- `createSaleReturn(saleId, request)` → kısmi iade, stok geri ekleme + `RETURN` transaction

## Sources

- `pos-product-manager/src/main/java/com/sedcore/sales/service/impl/SaleServiceIntegrated.java` (70–200, 417–463)
- `pos-product-manager/src/main/java/com/sedcore/sales/model/SaleRequest.java`
- `pos-product-manager/src/main/java/com/sedcore/inventory/service/StockLevelService.java` (deductStock)

## Related

- [[entities/sale]]
- [[entities/sale-item]]
- [[entities/customer-account]]
- [[entities/account-transaction]]
- [[syntheses/flow-drift-reconciliation]]
- [[concepts/optimistic-lock-version]]
- [[concepts/pattern-denormalization-with-reconcile]]
- [[syntheses/accounts-hub-production-readiness]] (P2.5 credit limit)
