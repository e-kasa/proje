---
title: SupplierClaim (detailed merge from .claude/wiki/)
type: entity
source: .claude/wiki/entities/supplier-claim.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
note: "MERGE_NEEDED — .wiki/entities/supplier-claim.md is a stub; this draft has lifecycle table + financial nuance (anti-pattern protection)."
---

# SupplierClaim

## Amaç

Bir [[entities/purchase]]'ta eksik teslimat (shortageAmount > 0) saptandığında **otomatik açılan** tedarikçiye karşı talep kaydı. Lifecycle: OPEN → RESOLVED_DELIVERY / RESOLVED_DISCOUNT / CANCELLED.

## Açılma

`PurchaseServiceImpl.createPurchase` içinde `shortageAmount > 0` olunca:

```java
supplierClaimService.openClaim(purchase, shortageLines, desc)
```

`shortageLines` her kalem için: `invoiceQty`, `receivedQty`, `shortageQty = invoiceQty − receivedQty`, reason = `SHORTAGE`.

## Kapanma Yolları

| Status | Tetikleyici | Finansal Etki |
|---|---|---|
| `RESOLVED_DELIVERY` | Tedarikçi eksik malı sonradan getirdi → yeni PURCHASE_IN | Yeni stock movement + totalAmount artışı |
| `RESOLVED_DISCOUNT` | `PurchaseServiceImpl.applyDiscount` — iskonto/kredi notu | Purchase.discountAmount ↑, shortageAmount ↓; **SupplierAccount etkisi YOK** (çünkü baştan o tutar debit yazılmamıştı) |
| Kısmi iskonto | applyDiscount shortageAmount > 0 kalırsa | Claim açık kalır, claimAmount güncellenir |
| `CANCELLED` | Manuel iptal | — |

## İlişkiler

```
SupplierClaim ──> Purchase (FK)
              ──> Supplier (FK, redundant — Purchase üzerinden de erişilir)
              ──< SupplierClaimLine (OneToMany — her eksik kalem detay)
```

## Finansal Nüans (Anti-Pattern Koruma)

**Yanlış yaklaşım**: shortage başladığında supplier'a invoiceAmount kadar debit yaz, iskonto gelince credit yaz.
**Doğru yaklaşım (SEDCORE)**: shortage için debit yazma — sadece gelen mal (totalAmount) debit'e girer. İskonto zaten "olmayan borcu kapatıyor" semantiği; SupplierAccount'a etki etmez, sadece Purchase.shortageAmount ile discountAmount swap.

Audit için `AccountTransaction(DISCOUNT)` yazılır — bakiyeye etki yok, sadece ledger'da görünsün diye.

## Sources

- `pos-product-manager/src/main/java/com/sedcore/purchase/entity/SupplierClaim.java`
- `pos-product-manager/src/main/java/com/sedcore/purchase/service/impl/SupplierClaimServiceImpl.java`
- `pos-product-manager/src/main/java/com/sedcore/purchase/service/impl/PurchaseServiceImpl.java:applyDiscount` (430–509)

## Related

- [[entities/purchase]]
- [[entities/supplier]]
- [[syntheses/flow-purchase-checkout]]
