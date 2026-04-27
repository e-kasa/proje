---
title: Cari Hesap Bakiye Bilgileri Doğruluğu — Audit (2026-04-27)
type: synthesis
date: 2026-04-27
status: verified
question: "Cari işlemler kısmındaki genel ve müşteri/tedarikçi hesap bilgileri doğru mu?"
scope: AccountsHub üst özet bar + cari kart listesi + ekstre paneli + backend balance flow
methodology: 2 paralel Explore agent (backend + frontend) + wiki sayfası audit (entities + concepts + decisions + syntheses + issues)
---

# Cari Hesap Bakiye Bilgileri Doğruluğu — Audit (2026-04-27)

## Verdict (Tek Cümlede)

**EVET — yapısal olarak doğru ve sistemle uyumlu.** SEDCORE iki-katmanlı (ledger + denormalize) write-through + reconcile pattern'ı standart finansal yazılım yaklaşımıdır; geçmiş bilinen bug'ların hepsi RESOLVED; ancak **3 operasyonel risk** ve **3 UX gap'i** mevcut (P1/P2 backlog).

## Mimari Doğruluğu

### İki Katman: Ledger (Source of Truth) + Denormalize (Cache)

Sistem cari bakiyeyi iki tabakada tutar — kaynak: [[concepts/ledger-vs-denormalize]] (raw: `.claude/wiki/concepts/ledger-vs-denormalize.md`).

| Katman | Tablo | Rol |
|---|---|---|
| **Ledger** | [[entities/account-transaction]] | Append-only gerçek — tüm hareketler tek tek |
| **Denormalize** | [[entities/customer-account]], [[entities/supplier-account]] | Özet bakiye (`currentBalance`, `totalDebt`, `totalCredit`, `overdueAmount`) — hızlı okuma |

**Karar:** Drift tespit edildiğinde ledger doğru kabul edilir, denormalize üstüne yazılır — kaynak: [[decisions/ledger-as-source-of-truth]] (raw: `.claude/wiki/decisions/ledger-as-source-of-truth.md`). Ters yön yasak.

**Pattern:** Write-through (her satış/ödeme/iade aynı `@Transactional` içinde önce denormalize bakiye → sonra ledger insert) + periyodik reconcile audit — kaynak: [[concepts/denormalization-with-reconcile]] (raw: `.claude/wiki/patterns/denormalization-with-reconcile.md`).

**Concurrency:** `CustomerAccount` + `SupplierAccount` `@Version` optimistic locking var; ledger üzerinde de `@Version` (defense-in-depth) — kaynak: [[entities/account-transaction]], [[decisions/ledger-concurrency-defense-in-depth]].

**Kanıt (kod düzeyinde, Explore agent ile doğrulanmış):**
- Write-through: [`PaymentServiceImpl.java:157`](pos-product-manager/src/main/java/com/sedcore/finance/service/impl/PaymentServiceImpl.java#L157), [`SaleServiceIntegrated.java:510-517`](pos-product-manager/src/main/java/com/sedcore/sales/service/impl/SaleServiceIntegrated.java#L510-L517)
- Reconcile: [`CustomerAccountServiceImpl.java:150-217`](pos-product-manager/src/main/java/com/sedcore/customer/service/impl/CustomerAccountServiceImpl.java#L150-L217) — ledger aggregate query → bakiye karşılaştırma → drift varsa `setCurrentBalance(ledgerBalance)` + audit log
- Audit log: `ReconcileAuditLog` her run kaydedilir (drift 0 olsa bile, "ne zaman kontrol edildi" trail'i)

## Genel Özet (Üst Bar) Doğruluğu

**Backend `/account-statements/summary` endpoint** ([`AccountStatementControllerImpl.java:170-197`](pos-product-manager/src/main/java/com/sedcore/finance/controller/impl/AccountStatementControllerImpl.java#L170-L197)) tek JPQL aggregate query ile döner:
- `totalCustomerReceivable` — `SUM(debit-credit) WHERE customer IS NOT NULL`
- `totalSupplierPayable` — `SUM(debit-credit) WHERE supplier IS NOT NULL`
- `totalOverdueAmount` — `SUM(debit-credit) WHERE isOverdue=true OR (dueDate < today AND debit > 0)`
- `overdueTransactionCount`, `totalTransactionCount`

**Karar:** DB-side aggregate, Java loop yasak — kaynak: [[decisions/db-side-aggregate-over-java-loop]] (raw: `.claude/wiki/decisions/db-side-aggregate-over-java-loop.md`). PostgreSQL SUM index-backed.

**Geçmiş bug'lar (hepsi fix):**
- [[issues/customer-list-balance-zero]] (RESOLVED) — `CustomerControllerImpl.toMap` `currentBalance` eklemeyi atlamıştı → fix: `@EntityGraph(attributePaths = "account")` eklendi
- [[issues/supplier-list-balance-zero]] (RESOLVED) — aynı pattern, fix
- [[issues/n-plus-one-customer-account-fetch]] (RESOLVED) — EntityGraph ile çözüldü, hem customer hem supplier'da var (raw doğrulama: [`CustomerRepository.java:28`](pos-product-manager/src/main/java/com/sedcore/customer/repository/CustomerRepository.java#L28), [`SupplierRepository.java:14`](pos-product-manager/src/main/java/com/sedcore/supplier/repository/SupplierRepository.java#L14))

**⚠️ Mevcut UX gap (P2):**
- `todayCollection` summary endpoint'inde **YOK** — frontend [`accounts_summary_bar.dart:94-105`](project_pos/lib/features/accounts/widgets/accounts_summary_bar.dart#L94-L105) client-side `paymentDate.startsWith("YYYY-MM-DD")` ile fold yapıyor. `DateTime.now()` lokal saat → timezone hatası riski. Tarihsel olarak benzer pattern bug üretmişti: [[issues/today-collection-always-zero]] (silent-null bug ailesi, RESOLVED ama yeni başka client-side filter eklendi).

## Müşteri / Tedarikçi Hesap Kart Doğruluğu

**Backend `/accounts/list` endpoint** (Sprint 8, cursor-based pagination) her kart için döner:
- `id`, `name`, `type` (CUSTOMER|SUPPLIER), `currentBalance`, `hasOverdue`

**Frontend kart** ([`accounts_list_panel.dart:253-347`](project_pos/lib/features/accounts/widgets/accounts_list_panel.dart#L253-L347)):
- Müşteri: mavi person ikonu | Tedarikçi: turuncu business ikonu
- `currentBalance` direkt gösterilir
- `hasOverdue=true` → kırmızı uyarı ikonu + kırmızı metin
- Infinite scroll: 200px threshold → `loadMore()`, `_pageLimit=100`

**Türev alanlar (entity tanımı):**
- `availableCreditLimit = creditLimit - currentBalance`
- `isCreditLimitExceeded = availableCreditLimit < 0`

Kaynak: [[entities/customer-account]] (raw: `.claude/wiki/entities/customer-account.md`).

**⚠️ Mevcut UX gap (P2):**
- `creditLimit` + `availableCredit` UI'da gösterilmiyor — entity'de hesap formülü var, satış öncesi limit görünürlüğü yok (kullanıcı limit aşımını ancak `SaleServiceIntegrated.checkCreditLimit` reddedince anlıyor — bkz. [[decisions/credit-limit-override-role-based]])

## Ekstre Paneli (Statement Detail) Doğruluğu

**Backend `/account-statements` endpoint** ([`AccountStatementControllerImpl.java:64-79`](pos-product-manager/src/main/java/com/sedcore/finance/controller/impl/AccountStatementControllerImpl.java#L64-L79)) **iki** bakiye döner:
- `closingBalance` — ledger transactions'tan computed (running balance)
- `currentBalance` — denormalize field (`CustomerAccount.currentBalance`)

**Frontend `_SummaryGrid`** ([`statement_detail_panel.dart:472-477`](project_pos/lib/features/accounts/widgets/statement_detail_panel.dart#L472-L477)):
- Primer: `currentBalance` (Sprint 8 hot-fix D3 sayesinde)
- `hasDrift = abs(currentBalance - closingBalance) > 0.01` → warning ikonu + secondary text "statement_calc: {closingBalance}"

Bu drift göstergesi kullanıcıya **denormalize ↔ ledger sapma**'yı şeffaf gösterir — [[concepts/drift]] (raw: `.claude/wiki/concepts/drift.md`) tanımıyla uyumlu.

**Geçmiş bug (RESOLVED):**
- [[issues/overdue-amount-not-reconciled]] (RESOLVED 2026-04-24, Sprint 2) — Reconcile sadece balance/debt/credit/count düzeltiyordu, `overdueAmount` drift içinde kalıyordu. Fix: 5. aggregate eklendi (`COALESCE(SUM(CASE WHEN ...overdue) ELSE 0 END), 0)`).

**⚠️ Mevcut UX gap (P2):** Drift uyarısı **net değil** — "statement_calc" label kullanıcıya bir şey ifade etmiyor; reconcile butonu yok, kullanıcı drift'i nasıl çözeceğini bilmiyor.

## Operasyonel Riskler (Henüz Açık)

### Risk 1: Scheduled Reconcile Default Disabled
- **Karar:** [[decisions/scheduled-reconcile-safe-rollout]] — `reconcile.scheduled.enabled=false` default (prod safe rollout)
- **Doğrulama:** [`application.properties:68`](pos-product-manager/src/main/resources/application.properties#L68), [`ReconcileScheduledJob.java:38-44`](pos-product-manager/src/main/java/com/sedcore/finance/job/ReconcileScheduledJob.java#L38-L44)
- **Risk:** Prod'a deploy ederken bu flag unutulursa drift birikir; gece reconcile çalışmaz; manuel tetiklenmesi gerekir
- **Mitigasyon:** Deploy checklist'e flag ekleme önerisi (wiki'de henüz dokümante değil)

### Risk 2: Pagination Açık Issue
- **Issue:** [[issues/accounts-pagination-missing]] (P1.3) — Sprint 8 B0 ile kısmi çözüldü (`/accounts/list` cursor-based, `_pageLimit=100`), ama **kullanıcı tercih edebilir limit yok** (50/100/200 setting önerisi)
- **Etki:** 200+ müşterili tenant'ta 1. sayfa görüntüsü dar

### Risk 3: Error Boundary Bağımsız Fail
- **Issue:** [[issues/accounts-error-boundary-missing]] (P1.5)
- **Etki:** AccountsHub'da summary/list/detail birbirinden bağımsız fail eder; bir provider patlarsa diğerleri boş görünür ama koordineli error mesajı yok → debugging zor, kullanıcı kaybolur

## Bilinmeyen: Test Coverage
- **Issue:** [[issues/test-coverage-unknown]] (P2.7) — Reconcile, drift, applyDebit/Credit path'leri için test yazılmış olabilir ama envanter yok
- **Aksiyon önerisi:** `ReconcileDriftDetectionTest`, `CustomerAccountServiceImplTest` gibi dosyaları arama + Sprint 13 test coverage matrix'i

## Özet Tablo: Doğru / Risk / Eksik

| Alan | Durum | Kaynak |
|---|---|---|
| Mimari (ledger + denormalize) | ✅ Doğru | [[concepts/ledger-vs-denormalize]] |
| Write-through pattern | ✅ Doğru | [[concepts/denormalization-with-reconcile]] |
| Optimistic locking | ✅ Doğru | [[entities/customer-account]] |
| Drift detection + audit | ✅ Doğru | [[entities/reconcile-audit-log]] |
| DB-side aggregate (özet bar) | ✅ Doğru | [[decisions/db-side-aggregate-over-java-loop]] |
| EntityGraph N+1 fix (cust+sup) | ✅ Doğru | [[issues/n-plus-one-customer-account-fetch]] |
| Cursor pagination (Sprint 8) | ✅ Doğru | (audit doğrulaması) |
| `currentBalance` ekstre yanıtında | ✅ Doğru (Sprint 8 hot-fix) | (audit doğrulaması) |
| Drift göstergesi UI | ✅ Var | [`statement_detail_panel.dart:472-477`](project_pos/lib/features/accounts/widgets/statement_detail_panel.dart#L472-L477) |
| Customer-list-balance-zero | ✅ Fix | [[issues/customer-list-balance-zero]] |
| Supplier-list-balance-zero | ✅ Fix | [[issues/supplier-list-balance-zero]] |
| Today-collection-always-zero | ✅ Fix (silent-null) | [[issues/today-collection-always-zero]] |
| Overdue-amount-not-reconciled | ✅ Fix (5. aggregate) | [[issues/overdue-amount-not-reconciled]] |
| Scheduled reconcile prod toggle | ⚠️ Risk (deploy checklist eksik) | [[decisions/scheduled-reconcile-safe-rollout]] |
| `todayCollection` client-side filter | ⚠️ Risk (timezone) | [`accounts_summary_bar.dart:94-105`](project_pos/lib/features/accounts/widgets/accounts_summary_bar.dart#L94-L105) |
| Drift göstergesi UX | ⚠️ Gap (label net değil, sync butonu yok) | (audit) |
| `creditLimit`/`availableCredit` UI | ⚠️ Gap | [[entities/customer-account]] |
| Pagination kullanıcı tercihi | ⚠️ Gap | [[issues/accounts-pagination-missing]] |
| Error boundary koordinasyonu | ⚠️ Gap | [[issues/accounts-error-boundary-missing]] |
| Test coverage | ❓ Bilinmiyor | [[issues/test-coverage-unknown]] |

## Öneriler (Aksiyon Yol Haritası — Sprint 13 Adayı)

1. **Backend `/summary` endpoint'e `todayCollection` ekle** — server-side `CURRENT_DATE` filter, client-side fold sil
2. **Drift göstergesi UX iyileştir** — Tooltip + "Senkronize et" admin butonu (`POST /admin/accounts/reconcile/...`)
3. **Deploy checklist** — `application-prod.properties` içinde `reconcile.scheduled.enabled=true` zorunlu kıl, [[decisions/scheduled-reconcile-safe-rollout]] sayfasına not düş
4. **`creditLimit` + `availableCredit` UI** — kart subtitle + statement header
5. **Pagination kullanıcı tercihi** — settings 50/100/200
6. **Error boundary koordinasyonu** — AccountsHub üst banner "1 bileşen yüklenemedi" + tek "Tümünü Yenile"
7. **Test coverage envanteri** — mevcut test'leri katalogla, eksik path'leri Sprint 13'e ekle

Bu öneriler `.claude/plans/polymorphic-gathering-flute.md` Sprint 13 plan taslağında detaylanmıştı (kullanıcı interrupt etti, plan dondu).

## Sources

### Wiki sayfaları (bu sentezde kullanılan)
- **Concepts:** [[concepts/ledger-vs-denormalize]], [[concepts/drift]], [[concepts/denormalization-with-reconcile]], [[concepts/write-through-cache]], [[concepts/append-only]], [[concepts/optimistic-lock-version]], [[concepts/silent-null-bug]]
- **Entities:** [[entities/customer-account]], [[entities/supplier-account]], [[entities/account-transaction]], [[entities/payment]], [[entities/reconcile-audit-log]], [[entities/reconcile-scheduled-job]]
- **Decisions:** [[decisions/ledger-as-source-of-truth]], [[decisions/scheduled-reconcile-safe-rollout]], [[decisions/db-side-aggregate-over-java-loop]], [[decisions/use-entity-graph-for-customer-account-fetch]], [[decisions/idempotent-reconcile-no-op-guard]], [[decisions/trust-reconcile-no-ledger-version]], [[decisions/ledger-concurrency-defense-in-depth]], [[decisions/credit-limit-override-role-based]], [[decisions/rename-balance-to-currentbalance]]
- **Issues (RESOLVED):** [[issues/customer-list-balance-zero]], [[issues/supplier-list-balance-zero]], [[issues/today-collection-always-zero]], [[issues/overdue-amount-not-reconciled]], [[issues/n-plus-one-customer-account-fetch]], [[issues/credit-limit-not-enforced]], [[issues/admin-endpoint-no-preauthorize]]
- **Issues (OPEN):** [[issues/accounts-pagination-missing]], [[issues/accounts-error-boundary-missing]], [[issues/test-coverage-unknown]], [[issues/overdue-notification-missing]], [[issues/activity-history-missing]]
- **Syntheses:** [[syntheses/accounts-overview]], [[syntheses/accounts-hub-production-readiness]], [[syntheses/accounts-development-analysis-2026-04-25-v2]]

### Raw kaynaklar (wiki sayfalarının dayandığı)
- `.claude/wiki/` (orijinal scoped wiki, 2026-04-25 migration ile `.wiki/` altına taşındı)
- [[raw/code-refs/2026-04-25-drift-reconciliation-flow]]
- [[raw/code-refs/2026-04-25-accounts-hub-production-readiness]]
- [[raw/code-refs/2026-04-22-accounts-hub-perf]]
- [[raw/code-refs/2026-04-25-ledger-version-adr]]

### Kod düzeyinde doğrulama (Explore agent + grep, 2026-04-27)
- [`AccountStatementControllerImpl.java:64-79, 170-197`](pos-product-manager/src/main/java/com/sedcore/finance/controller/impl/AccountStatementControllerImpl.java)
- [`CustomerAccountServiceImpl.java:150-217`](pos-product-manager/src/main/java/com/sedcore/customer/service/impl/CustomerAccountServiceImpl.java)
- [`SaleServiceIntegrated.java:510-517`](pos-product-manager/src/main/java/com/sedcore/sales/service/impl/SaleServiceIntegrated.java)
- [`PaymentServiceImpl.java:157`](pos-product-manager/src/main/java/com/sedcore/finance/service/impl/PaymentServiceImpl.java)
- [`AccountTransactionRepository.java:121-138`](pos-product-manager/src/main/java/com/sedcore/finance/repository/AccountTransactionRepository.java)
- [`ReconcileScheduledJob.java:38-44`](pos-product-manager/src/main/java/com/sedcore/finance/job/ReconcileScheduledJob.java)
- [`application.properties:68`](pos-product-manager/src/main/resources/application.properties)
- [`CustomerRepository.java:28`](pos-product-manager/src/main/java/com/sedcore/customer/repository/CustomerRepository.java)
- [`SupplierRepository.java:14`](pos-product-manager/src/main/java/com/sedcore/supplier/repository/SupplierRepository.java)
- [`statement_detail_panel.dart:472-477`](project_pos/lib/features/accounts/widgets/statement_detail_panel.dart)
- [`accounts_summary_bar.dart:94-105`](project_pos/lib/features/accounts/widgets/accounts_summary_bar.dart)
- [`accounts_list_panel.dart:253-347`](project_pos/lib/features/accounts/widgets/accounts_list_panel.dart)

## Related

- [[syntheses/accounts-overview]]
- [[syntheses/accounts-hub-production-readiness]]
- [[syntheses/accounts-development-analysis-2026-04-25-v2]]
- [[concepts/multi-company-per-user-architecture]] — multi-firma per-user mimarisi (bakiye sorgu firma-filter'lı)
