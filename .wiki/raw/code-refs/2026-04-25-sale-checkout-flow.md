---
title: POS Sale Checkout Flow (pointer)
original-path: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\flows\sale-checkout.md
captured-at: 2026-04-25
type: pointer
---

# Pointer → Sale Checkout Flow

**Orijinal**: `.claude/wiki/flows/sale-checkout.md`

POS satış oluşturma akışı — 7 adımlı createSale:
1. saleNumber auto-gen, 2. kalem hesapla, 3. vadeli guard, 4. müşteri + credit limit check (override ile),
5. Sale + SaleItem save, 6. StockMovement + StockLevel atomic decrement, 7. vadeli → CustomerAccount + AccountTransaction.

Drift kaynak #1 — ledger → denormalize write-through.
