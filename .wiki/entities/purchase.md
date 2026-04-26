---
title: Purchase (Satın Alma)
tags: [entity, purchase, domain]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\entities\purchase.md
date: 2026-04-25
status: draft
---

# Purchase

Tedarikçiden yapılan satın alma. Kritik üçlü tutar ayrımı:

- `invoiceAmount` — fatura brüt (tüm kalemler × invoiceQty × birim)
- `totalAmount` — fiili giren mal (receivedQty × birim); **cari hesaba bu yansır**
- `shortageAmount = invoiceAmount − totalAmount` — açık eksik; [[entities/supplier-claim]] auto-open
- `discountAmount` — iskonto ile kapatılan (cari etkisi yok)

## İnvariant

`invoiceAmount == totalAmount + shortageAmount + discountAmount` (claim lifecycle boyunca).

## Sources

- `.claude/wiki/entities/purchase.md`
- [[raw/code-refs/2026-04-25-purchase-checkout-flow]]

## Related

- [[entities/supplier]]
- [[entities/supplier-account]]
- [[entities/supplier-claim]]
- [[concepts/invoice-vs-total-shortage]]
