---
title: Entities — Domain Modelleri (README template)
type: code-ref
source: .claude/wiki/entities/README.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
note: "Entity sayfa şablonu + 'ne yazılır / ne yazılmaz' kuralları + aday sayfa listesi. Klasör tanım dosyası + iç template."
---

# Entities

Domain modelleri (JPA entity'leri ve onların semantik anlamı). Kod yapısını değil, **davranışını** anlatır.

## Ne Yazılır

- Entity'nin iş anlamı ("Customer niye var, ne zaman oluşur?")
- Önemli alanların semantiği (denormalize vs hesaplanan, @Version, @Filter)
- Hangi servislerle beslenir, hangi event'lerde güncellenir
- FK ilişkileri ve cascade davranışı
- Soft delete / unique constraint tuzakları

## Ne Yazılmaz

- `@Column` listesi (kod zaten söyler)
- Migration detayları (DDL=create modunda anlamsız)
- Getter/setter listesi

## Sayfa Şablonu

```markdown
---
title: CustomerAccount
type: entity
status: draft
last-verified: 2026-04-24
sources:
  - pos-product-manager/src/main/java/com/sedcore/customer/entity/CustomerAccount.java
related:
  - "[[entities/customer]]"
  - "[[entities/account-transaction]]"
  - "[[flows/drift-reconciliation]]"
---

# CustomerAccount

## Amaç
Müşteri cari bakiyesinin **denormalize özeti**. Ledger (AccountTransaction) source of truth, bu entity cache görevinde.

## Kritik Alanlar
| Alan | Anlam | Kaynak |
|---|---|---|
| currentBalance | Güncel bakiye (+ alacak / − borç) | Denormalize — her sale/payment'ta güncellenir |
| totalDebt | Kümülatif borç toplamı | Denormalize |
| ... | ... | ... |

## Beslenme Akışı
1. `SaleService` satış sonunda `applyDebit()` çağırır
2. `PaymentService` tahsilatta `applyCredit()` çağırır
3. Drift tespit edildiğinde `reconcile()` ledger'dan senkronize eder

## Tuzaklar
- `@Version` var — paralel yazımda OptimisticLockException patlayabilir
- `account_transactions` üzerinde `@Version` YOK — ledger tarafı koruma yok

## İlgili
- [[entities/account-transaction]]
- [[flows/drift-reconciliation]]
```

## Aday Sayfalar

- `customer-account.md`
- `supplier-account.md`
- `account-transaction.md`
- `stock-movement.md`
- `stock-level.md`
- `sale.md` / `sale-item.md`
- `purchase.md`
- `product.md` / `product-variant.md`
- `company.md` / `company-setting.md`
