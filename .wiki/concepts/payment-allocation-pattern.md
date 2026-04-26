---
title: PaymentAllocation Pattern — One Payment, N Sales
type: concept
source: pos-product-manager/.../finance/{entity,service}
ingested: 2026-04-25
last-verified: 2026-04-25
sprint: 7
---

# Payment Allocation Pattern

## Problem

Bir ödeme (Payment) bir veya birden fazla satışa (Sale) karşılık olabilir:
- **Tek satış**: müşteri belirli bir alışverişin borcunu öder
- **Genel ödeme**: müşteri cari bakiyeye genel ödeme yapar (belirli satışa değil)
- **Toplu ödeme** (B3, gelecek): tek ödemeyi birden fazla satışa böler

Tek-FK (`Payment.sale_id`) modeli sadece ilk durumu kapsar; diğerleri için ya `null` ya da migration gerekir.

## Çözüm

Ara tablo: `PaymentAllocation` (`payment_id`, `sale_id` nullable, `amount`, `allocated_at`).

Davranışlar:

| Senaryo | Allocation kayıtları |
|---|---|
| Tek satışa ödeme | 1 kayıt: `(payment, sale, amount=payment.amount)` |
| Genel ödeme | 1 kayıt: `(payment, sale=null, amount=payment.amount)` |
| Toplu ödeme (B3) | N kayıt: `[(payment, sale_A, amount_A), (payment, sale_B, amount_B), ...]`, `SUM == payment.amount` |

## Invariant

- `SUM(allocations.amount) by paymentId == Payment.amount`
- `Sale.paidAmount = SUM(PaymentAllocation.amount WHERE sale_id = X AND payment.isCancelled = false)`

## SEDCORE Implementasyonu

- Entity: [[entities/payment-allocation]]
- Karar: [[decisions/payment-allocation-from-day-1]] (many-to-many baştan, B1↔B3 bağımlılığı)
- Service: `PaymentServiceImpl.createAllocations()` — Payment insert sonrası otomatik çağrılır
- Repository helper: `sumActiveBySaleId(saleId)` — cancelled hariç toplam

## Trade-off

- ✅ B3 (toplu ödeme) sıfır migration ile gelir
- ✅ Audit zinciri net (her allocation `allocated_at`'li)
- ✅ Reporting tutarlı (tek kaynak)
- ❌ Tek satışlı durumda 1 fazla insert (kabul edilir cost, milyonlar değil binlerce)
- ❌ `Payment.sale` deprecated geçiş süreci 1-2 sprint kod karmaşası

## Related Patterns

- **PurchaseAllocation** (gelecek, simetrik) — Payment.purchase için aynı pattern
- **Order/Invoice splitting** (genel pattern) — bir kaynak yapı, N hedef yapıya bölünme

## Related

- [[entities/payment-allocation]]
- [[decisions/payment-allocation-from-day-1]]
- [[entities/payment]]
- [[entities/sale]]
- [[concepts/append-only]] — benzer audit
- [[concepts/denormalization-with-reconcile]] — `Sale.paidAmount` derived
