---
title: Sale (Satış Kaydı)
tags: [entity, sale, pos, domain]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\entities\sale.md
date: 2026-04-25
status: draft
---

# Sale

Müşteriye yapılan satışın ana kaydı. Peşin veya vadeli olabilir; vadeli ise [[entities/account-transaction]] üzerinden cari hesaba yansır.

## Kritik Alanlar

- `saleNumber` (unique), `saleDate`, `customer` (nullable = peşin)
- `subtotalAmount`, `totalDiscount`, `totalTax`, `totalAmount`, `paidAmount`
- `locationId` + `locationType` — kasiyer JWT'sinden
- `isCancelled`, `returnedAmount`, `hasReturn` — lifecycle flag'leri
- `@Version` — concurrent cancel/return koruması

## Yardımcı

- `getRemainingAmount()` = `totalAmount − paidAmount`
- `isOnCredit()` = `customer != null && remainingAmount > 0`

## Sources

- [[raw/code-refs/2026-04-25-sale-checkout-flow]]
- `pos-product-manager/src/main/java/com/sedcore/sales/entity/Sale.java`
- `.claude/wiki/entities/sale.md`

## Related

- [[entities/sale-item]]
- [[entities/customer]]
- [[entities/customer-account]]
- [[entities/account-transaction]]
- [[sources/code-refs/2026-04-25-sale-checkout-flow]]
