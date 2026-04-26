---
title: PaymentAllocation — Sale-Payment many-to-many dağıtım kaydı
type: entity
source: pos-product-manager/src/main/java/com/sedcore/finance/entity/PaymentAllocation.java
ingested: 2026-04-25
last-verified: 2026-04-25
sprint: 7
---

# PaymentAllocation

## Tanım

Bir [`Payment`]'in bir veya daha fazla satışa (Sale) yapılan dağıtımını kaydeder. Sprint 7'de eklendi. Tek satışlı durumda da 1 allocation kaydı tutulur — bu, ileride toplu ödeme (B3) için **sıfır şema değişikliği** sağlar (bkz. [[decisions/payment-allocation-from-day-1]]).

## Kod Konumu

- `pos-product-manager/src/main/java/com/sedcore/finance/entity/PaymentAllocation.java`
- Repository: `pos-product-manager/.../finance/repository/PaymentAllocationRepository.java`
- Request DTO: `pos-product-manager/.../finance/model/AllocationRequest.java`
- Service entegrasyonu: `PaymentServiceImpl.createAllocations()` — `createCustomerPayment()`'tan çağrılır

## Şema

| Alan | Tip | Açıklama |
|---|---|---|
| `id` | varchar(36) | UUID — TOpenSimpleCompanyEntity'den |
| `payment` | ManyToOne LAZY | Payment FK, **NOT NULL** |
| `sale` | ManyToOne LAZY | Sale FK, **NULLABLE** (null = "genel ödeme") |
| `amount` | BigDecimal(15,2) | NOT NULL, > 0 |
| `allocated_at` | timestamp | dağıtım anı (audit) |
| `version` | Long | `@Version` optimistic lock |
| `company_code` | varchar(36) | multi-tenant filter (TOpenSimpleCompanyEntity) |

**Index'ler:** `idx_pa_payment`, `idx_pa_sale`, `idx_pa_company`.

## Kurallar (Invariant)

1. **SUM(amount) by paymentId == Payment.amount** — service katmanında `createAllocations()` doğrular, eşleşmezse exception
2. **sale = null** → "genel ödeme" (cari bakiyeye, belirli satışa değil) — geçerli durum, yasak değil
3. **Payment cancellation** → allocation'lar fiziksel silinmez; `Sale.paidAmount` derivasyonu `payment.isCancelled` filtresi uygular (`PaymentAllocationRepository.sumActiveBySaleId`)

## Davranış (Service)

`createCustomerPayment()` sonunda otomatik çağrılır:
- `request.allocations` boş + `request.saleId` boş → 1 allocation oluşur (`sale=null`, `amount=payment.amount`)
- `request.allocations` boş + `request.saleId` dolu → 1 allocation (`sale=saleId`, `amount=payment.amount`) — geriye uyum
- `request.allocations` dolu → SUM kontrolü, çoklu allocation insert (B3, henüz UI'da yok)

## Geriye Uyum (Geçiş Süreci)

`Payment.sale` FK ve `PaymentRequest.saleId` field'ı **deprecated** ama hâlâ kabul ediliyor (Sprint 9'da kaldırılacak). Yeni kod `PaymentRequest.allocations` kullanmalı.

## Kullanım (Reporting)

Sale.paidAmount'u allocation'lardan türet (Sprint 8+):
```java
sale.setPaidAmount(paymentAllocationRepository.sumActiveBySaleId(saleId));
```

Reconcile job da bu derivasyonu kullanmalı (R-WP1 risk: T2 testi bunu kapsayacak).

## Sources

- Entity: `pos-product-manager/.../finance/entity/PaymentAllocation.java`
- Sprint 7 plan: [[syntheses/sprint-7-implementation-plan-2026-04-25]]
- Mimari karar: [[decisions/payment-allocation-from-day-1]]
- Memory: `project_ddl_strategy.md` (PaymentAllocation seed yazılırsa `version=0` zorunlu)

## Related

- [[entities/payment]] (parent)
- [[entities/sale]] (target)
- [[decisions/payment-allocation-from-day-1]]
- [[concepts/optimistic-lock-version]] — `@Version` kullanımı
- [[concepts/append-only]] — allocation_at audit zinciri benzer
- [[syntheses/accounts-development-analysis-2026-04-25-v2]] — B1 yeniden tasarım gerekçesi
