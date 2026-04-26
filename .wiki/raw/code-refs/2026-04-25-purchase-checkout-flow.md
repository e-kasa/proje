---
title: Purchase Checkout Flow (pointer)
original-path: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\flows\purchase-checkout.md
captured-at: 2026-04-25
type: pointer
---

# Pointer → Purchase Checkout Flow

**Orijinal**: `.claude/wiki/flows/purchase-checkout.md`

Satın alma oluşturma akışı — 6 adım. Kritik domain nüansı: invoiceAmount (fatura brüt) vs totalAmount (fiili gelen) ayrımı; cari hesaba sadece totalAmount yansır. Eksik teslimat için SupplierClaim otomatik açılır. İskonto ile kapatılırsa SupplierAccount etkisiz (audit trail için DISCOUNT transaction).

Drift kaynak #2.
