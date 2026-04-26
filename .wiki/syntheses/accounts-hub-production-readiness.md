---
title: AccountsHub — Production-Readiness Gap Analizi
type: synthesis
source: .claude/wiki/syntheses/accounts-hub-production-readiness.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# AccountsHub — Production-Readiness Gap Analizi

Mevcut AccountsHub (Cari Hesaplar) ekosistemi **fonksiyonel** — bug'lar çözüldü, performans optimize edildi. Profesyonel/prod-ready seviyesine çıkarmak için 3 öncelik katmanında boşluklar var.

## P0 — Prod Öncesi Zorunlu (Security + Correctness)

### P0.1 — Admin Reconcile Endpoint Rol Koruması — RESOLVED (2026-04-24)
**Kaynak**: [[issues/admin-endpoint-no-preauthorize]]

`AdminAccountsReconcileControllerImpl` 3 endpoint'i herhangi bir role-check yapmıyor. CASHIER dahi tetikleyebilir.

**Aksiyon**: Class-level `@PreAuthorize("hasRole('ADMIN')")` + SecurityConfig `@EnableMethodSecurity`. Yapıldı.

### P0.2 — Reconcile Audit Log — RESOLVED (2026-04-24)

Kim ne zaman kaç row düzeltti görülmüyor. Finansal veriye dokunan operasyonda kabul edilemez.

**Aksiyon**: `ReconcileAuditLog` entity + `ReconcileAuditService` (REQUIRES_NEW propagation). Her reconcile SINGLE + her sweep ALL kaydı yazar. Bkz. [[entities/reconcile-audit-log]]

### P0.3 — Ledger Tarafı Concurrency — RESOLVED-DECISION (2026-04-24)

[[entities/account-transaction]] üzerinde `@Version` YOK. Paralel sale + payment yarışında ledger'a iki insert, denormalize'a tek update → drift oluşur.

**Karar**: Seçenek **D** — kabul et + reconcile'a güven. ADR: [[decisions/trust-reconcile-no-ledger-version]]. Sprint 3'te scheduled reconcile + alerting devreye girince kapanır.

### P0.4 — Overdue Amount Reconcile — RESOLVED (2026-04-24, Sprint 2)

Reconcile sadece balance/debt/credit düzeltiyor, `overdueAmount` türetilmiyor.

**Aksiyon**: `ledgerTotalsForCustomer` + `ledgerTotalsForSupplier` query'lerine 5. aggregate eklendi. Reconcile'a 4. eşitlik kontrolü + `acct.setOverdueAmount(ledgerOverdue)` + log'da `overdueDrift`.

## P1 — Operasyonel Olgunluk

### P1.1 — Scheduled Reconcile + Alerting — RESOLVED (2026-04-24, Sprint 3)

**Aksiyon tamamlandı**:
- `ReconcileScheduledJob` — `@Scheduled(cron = "${reconcile.scheduled.cron:0 0 3 * * *}")` her gece 03:00
- Flag-kontrollü: `reconcile.scheduled.enabled` (default `false`)
- `SlackNotifier` — drift > 0 veya exception durumunda webhook bildirim
- `@EnableScheduling` ana Application'da aktif

### P1.2 — Client-Side Filter Tip Güvensizliği — INFRA READY (2026-04-24, Sprint 4)

`Map<String,Object>` çıktısı → Flutter `p['paymentDate']` silent null. Tarihsel bug örneği: [[issues/today-collection-always-zero]].

**Sprint 4 kapsamı — infra kuruldu**:
- Backend: `/v3/api-docs` + `/swagger-ui/**` permitAll (dev), springdoc zaten pom.xml'de
- Export script: `pos-product-manager/scripts/export-openapi.sh`
- Flutter config: `project_pos/openapi-generator-config.yaml` (dart-dio generator)
- Pattern sayfası: [[concepts/pattern-openapi-codegen-flutter]]

**Aşamalı migration** (sonraki PR'lar):
- Faz A: AccountsHub list — 1 ekran typed client pilot
- Faz B: Accounts feature kalanı
- Faz C: Diğer feature'lar

### P1.3 — Pagination Yok

`/customers` + `/suppliers` tüm satırları döner. 1000+ müşteri/tedarikçi varsa liste yüklemesi yavaşlar.

**Aksiyon**: `?page=0&size=50` + `Pageable` repository + Flutter infinite scroll.

### P1.4 — Reconcile Metrics — RESOLVED (2026-04-24, Sprint 3)

Micrometer enstrumantasyonu:
- `reconcile.runs.total{entity_type, scope, status}` — Counter
- `reconcile.drift.total{entity_type}` — Counter
- `reconcile.duration.seconds{entity_type, scope}` — Timer

Expose: `/product/actuator/prometheus`.

### P1.5 — Loading State / Error Boundary

Her provider bağımsız yüklenir; biri fail olursa ekran kısmi hatalı görünür.

**Aksiyon**: Koordineli loading — özet bar fail durumunda banner + retry.

## P2 — UX / Feature Olgunluk

### P2.1 — AccountEditForm Wiki Kapsamı (mostly resolved)

[[syntheses/account-edit-form-ux]] sayfası açıldı.

### P2.2 — Currency Desteği Tek (TRY Varsayılan)

`BigDecimal(15,2)` currency alanı yok.

**Aksiyon**: `currency: VARCHAR(3)` AccountTransaction + CustomerAccount'a ekleme, default 'TRY'.

### P2.3 — Ekstre PDF Export + Email — RESOLVED (2026-04-24, Sprint 5 + mini)

**Sprint 5 — PDF**:
- Yeni `AccountStatementPdfControllerImpl`: `GET /product/api/v1/account-statements/pdf?...`
- PDFBox ile minimum viable tablo

**Post-sprint mini — Email**:
- `pom.xml` → `spring-boot-starter-mail`
- Yeni `EmailService` — JavaMailSender-based
- Aynı controller'a `POST /email?...&to=&subject=`

### P2.4 — Overdue Bildirimi

`overdueAmount > 0` tespit edildi ama kullanıcıya bildirim yok.

**Aksiyon**: Scheduled job + `NotificationService` + sektör bazlı template.

### P2.5 — Credit Limit Sale Flow Enforcement — RESOLVED (2026-04-24, Sprint 5)

**Aksiyon tamamlandı**:
- `SaleRequest.overrideCreditLimit` (Boolean, default false)
- `SaleServiceIntegrated.checkCreditLimit` refactor: limit aşımında override flag + role check
- Override başarılıysa `log.warn` ile audit trail
- Flutter `PosNotifier.submitSale({bool overrideCreditLimit})` + confirm dialog fallback

ADR: [[decisions/credit-limit-override-role-based]]

### P2.6 — Activity / Change History

Customer/Supplier düzenlemelerinin tarihsel kaydı yok.

**Aksiyon**: Hibernate Envers (`@Audited`) veya custom `AuditLog` entity.

### P2.7 — Test Kapsamı

Reconcile, drift, applyDebit/Credit path'leri için test kapsamı belirsiz.

**Aksiyon**: Test matrix'i dokümante et + eksikleri doldur.

## P3 — Düşük Öncelik / Gelecek

- Multi-tenant tenant_code header audit (sızıntı testi)
- GraphQL endpoint
- AccountsHub widget lazy load (micro-frontend)

## Aksiyon Planı (Önerilen Sıra)

| Hafta | P0 | P1 | P2 |
|---|---|---|---|
| 1 | P0.1 (PreAuthorize) · P0.2 (audit log) | — | — |
| 2 | P0.4 (overdue reconcile) | P1.4 (metrics) | — |
| 3 | — | P1.1 (scheduled) · P1.2 (OpenAPI) | P2.1 (ingest) |
| 4-5 | — | P1.3 (pagination) · P1.5 (error boundary) | P2.3 (PDF export) |
| 6+ | P0.3 karar + impl | — | P2.2 (currency) · P2.5 (credit limit enforce) · P2.4 (notif) |

## Related

- [[syntheses/accounts-overview]]
- [[syntheses/denormalization-strategy]]
- [[syntheses/flow-drift-reconciliation]]
- [[concepts/pattern-denormalization-with-reconcile]]
- [[concepts/pattern-dto-tomap-pattern]]

## Sources

- [[sources/code-refs/2026-04-24-drift-reconcile]]
- [[sources/code-refs/2026-04-22-accounts-hub-perf]]
- [[sources/code-refs/2026-04-21-accounts-hub-screens]]
