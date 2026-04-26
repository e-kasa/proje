---
title: SupplierAccount (detailed merge from .claude/wiki/)
type: entity
source: .claude/wiki/entities/supplier-account.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
note: "MERGE_NEEDED — .wiki/entities/supplier-account.md is a stub; this is verified detailed source."
---

# SupplierAccount

## Amaç
Tedarikçi cari bakiyesinin **denormalize özeti**. [[entities/customer-account]] ile simetrik — işaret anlamı ters: pozitif `currentBalance` = bize borç (tedarikçiye ödemediğimiz).

## Kritik Alanlar

[[entities/customer-account]] ile aynı şema. Ek alan: `creditLimit` `Supplier` FK üzerinden gelir, SupplierAccount'ta kopya yok.

## Beslenme Akışı

1. `PurchaseService` satın almada → `applyDebit()` → bize borç artar (currentBalance ↑)
2. `PaymentService` tedarikçiye ödemede → `applyCredit()` → bize borç azalır (currentBalance ↓)
3. İptal → `reverseDebit` / `reverseCredit`

## İşaret Konvansiyonu

| Durum | currentBalance |
|---|---|
| Biz tedarikçiye borçluyuz | pozitif |
| Tedarikçi bize avans borçlu (nadiren) | negatif |

Bu müşteri tarafıyla **ters** (müşteride pozitif = müşteri bize borçlu).

## Tuzaklar

- Müşteri tarafıyla işaret simetrisi kafa karıştırır — özet kartlarda etiket dikkatli ("Tedarikçi Borcu" = pozitif supplier balance toplamı)
- `SupplierResponse.balance` → `currentBalance` rename 2026-04-22'de yapıldı (bkz. [[issues/supplier-list-balance-zero]])

## Sources

- pos-product-manager/src/main/java/com/sedcore/supplier/entity/SupplierAccount.java
- pos-product-manager/src/main/java/com/sedcore/supplier/service/impl/SupplierAccountServiceImpl.java
- [[sources/code-refs/2026-04-24-drift-reconcile]]

## Related

- [[entities/supplier]]
- [[entities/customer-account]]
- [[entities/account-transaction]]
- [[syntheses/flow-drift-reconciliation]]
- [[concepts/pattern-denormalization-with-reconcile]]
