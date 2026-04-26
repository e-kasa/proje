---
title: Invoice vs Total vs Shortage (Satın Alma Tutar Ayrımı)
tags: [concept, purchase, accounting]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\entities\purchase.md
date: 2026-04-25
status: draft
---

# Invoice vs Total vs Shortage

Satın almada 3 ayrı tutar tutulur — cari hesaba yansıyan sadece fiili gelen maldır.

- `invoiceAmount` — faturadaki brüt
- `totalAmount` — fiili depoya giren mal (`receivedQty × birim`)
- `shortageAmount = invoiceAmount − totalAmount` — açık eksik (otomatik [[entities/supplier-claim]])
- `discountAmount` — iskonto ile kapatılan

## Finansal Kural

Cari borç = `totalAmount`. Eksik için baştan debit yazılmaz. Sonradan:
- Teslim tamamlanırsa → yeni PURCHASE_IN → totalAmount artar
- İskonto gelirse → shortage ↓, discount ↑, SupplierAccount etkisiz

İnvariant: `invoiceAmount == totalAmount + shortageAmount + discountAmount`.

## Sources

- [[raw/code-refs/2026-04-25-purchase-checkout-flow]]
- `.claude/wiki/entities/purchase.md`

## Related

- [[entities/purchase]]
- [[entities/supplier-claim]]
- [[decisions/debit-only-received-amount]]
- [[decisions/discount-no-account-effect]]
