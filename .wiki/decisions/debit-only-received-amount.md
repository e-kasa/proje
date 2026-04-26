---
title: Karar — Satın Alma Cari Borç = Sadece Gelen Mal
tags: [decision, purchase, accounting]
date: 2026-04-25
status: accepted
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\entities\purchase.md
---

# Cari Borç = totalAmount (invoiceAmount Değil)

## Karar

[[entities/purchase]] cari hesaba yansıyan borç `totalAmount` (fiili gelen mal) — `invoiceAmount` (fatura brüt) değil.

## Gerekçe

Eksik teslim edilen mal için baştan debit yazılmaz; supplier disputed. Açılan [[entities/supplier-claim]] üzerinden yönetilir; teslim tamamlanırsa yeni PURCHASE_IN ile totalAmount artar.

## Sources

- [[raw/code-refs/2026-04-25-purchase-checkout-flow]]

## Related

- [[entities/purchase]]
- [[entities/supplier-claim]]
- [[concepts/invoice-vs-total-shortage]]
- [[decisions/supplier-claim-auto-open]]
