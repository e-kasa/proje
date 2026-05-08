---
title: Test Coverage Belirsiz (RESOLVED — Sprint 31)
tags: [issue, resolved, test, quality]
date: 2026-04-25
last-updated: 2026-05-06
resolved: 2026-05-06
status: resolved
priority: low
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\syntheses\accounts-hub-production-readiness.md
---

# Test Coverage Unknown (P2.7) — RESOLVED

Reconcile, drift, applyDebit/Credit, credit limit path'leri için unit+integration test kapsamı wiki'de dokümante değil. Coverage ölçüm yok.

## Mevcut Test Envanteri (2026-05-06)

| Test | Tip | Sprint | Kapsam | Test |
|---|---|---|---|---|
| [`PaymentAllocationRepositoryTest`](pos-product-manager/src/test/java/com/sedcore/finance/repository/PaymentAllocationRepositoryTest.java) | `@DataJpaTest` | 7 WP2 | Allocation insert + findByPaymentId + sumActiveBySaleId (cancelled exclude) | 3 |
| [`AccountAuditServiceTest`](pos-product-manager/src/test/java/com/sedcore/finance/service/AccountAuditServiceTest.java) | `@SpringBootTest` | 30 | AccountAuditService field change + create/delete + sıralama + truncate + segregation + null | 9 |
| [`OverdueNotificationScheduledJobTest`](pos-product-manager/src/test/java/com/sedcore/finance/job/OverdueNotificationScheduledJobTest.java) | `@SpringBootTest` + `@MockBean NotificationService` | 30 | Email/SMS kanal seçimi + email > phone preference + zero overdue skip + no contact filter + queue exception batch resilience | 6 |
| [`CustomerAccountServiceTest`](pos-product-manager/src/test/java/com/sedcore/customer/service/CustomerAccountServiceTest.java) | `@SpringBootTest` | 31 | applyDebit/applyCredit/reverseCredit + cumulative + negative balance (prepaid) + getOrCreate idempotent + recalculate credit-limit | 7 |
| [`PaymentServiceTest`](pos-product-manager/src/test/java/com/sedcore/finance/service/PaymentServiceTest.java) | `@SpringBootTest` | 31 | savePayment defaults + cancelPayment customer/supplier reverseCredit + cancel idempotency + verify + verify-on-cancelled exception | 6 |

**Toplam**: 31 test, hepsi geçer (2026-05-06). Backend `./mvnw.cmd test` → BUILD SUCCESS, 31/31 ✅.

## Sprint 31'in Karşıladığı T1-T4 Talepleri

| Plan kalemi | Durum | Karşılayan test |
|---|---|---|
| **T1** PaymentCreationIntegrationTest | ✅ savePayment + cancel + verify | `PaymentServiceTest` 6 test |
| **T2** ReconcileDriftDetectionTest | ⚠️ kısmi — applyDebit/applyCredit ledger math kapsandı; reconcile sweep `Object[][]` H2 quirk'i nedeniyle skip edildi | `CustomerAccountServiceTest` 7 test |
| **T3** CreditLimitGuardTest | ⚠️ kısmi — `recalculate` `availableCreditLimit` + `isCreditLimitExceeded` boundary kapsandı; full `SaleServiceIntegrated.checkCreditLimit` (Sale + Product fixture gerek) Sprint 32+ | `recalculate_refreshesCalculatedFields` |
| **T4** SalePaymentFkIntegrityTest | ✅ cancelPayment FK reverse (customer + supplier) + verify-on-cancelled guard | `PaymentServiceTest` 4 test |

## Sprint 32+ Backlog (Tam Kapsam)

| Test | Hedef | Tahmin |
|---|---|---|
| Reconcile sweep H2 fix | `ledgerTotalsForCustomer` query'sinin H2'de Object[][] quirk'ini araştır + test ekle | 0.3 gün |
| Full `CreditLimitGuardTest` | `SaleServiceIntegrated.createSale` full fixture (Customer + Product + Variant + Stock) ile boundary kontrolü + `CREDIT_LIMIT_OVERRIDE` role | 0.5 gün |
| `SalePaymentFkIntegrityTest` extended | Multi-payment sum + partial allocation senaryoları | 0.3 gün |
| CI Coverage Gate | JaCoCo + threshold P0 path %80+ + README badge | 0.2 gün |

**Toplam kalan tahmini**: ~1.3 gün — Sprint 32 minor task.

## CI Coverage Gate (Sprint 32+)

- Maven Surefire + JaCoCo plugin
- Threshold: P0 path'ler için %80+ (PaymentService, CustomerAccountService, ReconcileAuditService, NotificationService)
- Coverage badge `README.md`'ye eklenir

## Sources

- [[raw/code-refs/2026-04-25-accounts-hub-production-readiness]]
- [[syntheses/sprint-7-implementation-plan-2026-04-25]] §WP2 (T1-T4 talep)
- [[syntheses/sprint-8-implementation-plan-2026-04-26]] §WP3

## Related

- [[syntheses/accounts-module-overview]]
- [[concepts/optimistic-lock-version]]
