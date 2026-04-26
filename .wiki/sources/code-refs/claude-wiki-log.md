---
title: Wiki Event Log (claude-wiki)
type: source
source: .claude/wiki/log.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Wiki Event Log

Append-only olay kaydı. En yeni üste. Her ingest / query / lint / sentez işlemi buraya girer.

> **Girdi formatı**:
> ```
> ## [YYYY-MM-DD] <operasyon> | <kısa başlık>
> - Dokunulan dosyalar: `entities/x.md`, `flows/y.md`
> - Kaynak: dosya path / PR # / commit sha
> - Not: opsiyonel
> ```

## Olaylar

## [2026-04-24] post-sprint | Kalan iş parçaları sırayla kapatıldı
- **1. PDF email endpoint (ertelenmiş mini-sprint tamamlandı)**:
  - `pom.xml` → `spring-boot-starter-mail` eklendi
  - Yeni `com.sedcore.common.notification.EmailService` — JavaMailSender-based, `@ConditionalOnProperty(mail.enabled)` pattern değil ama `isEnabled()` guard + no-op fallback (JavaMailSender bean yoksa sessiz atlar)
  - `AccountStatementPdfControllerImpl` genişletildi: ortak `buildStatementPdf` helper + `record StatementPdf` + yeni `POST /email?accountType=&accountId=&startDate=&endDate=&to=&subject=` endpoint
  - `application.properties` → `mail.enabled=false` (default, no-op) + `mail.from` + `spring.mail.*` yorumlu config
- **2. Multi-tenant scheduled reconcile**:
  - `CompanySettingRepository.findAllActiveCompanyCodes()` native query eklendi (Hibernate @Filter bypass)
  - `ReconcileScheduledJob` refactor: tenant listesi iterate + her biri için `CompanyContext.set` → reconcileAll → clear; exception'a dayanıklı (bir tenant fail diğerleri devam) + aggregate Slack raporu
- **3. @Version ADR revize (contradictions RESOLVED)**:
  - `.claude/decisions/2026-04-24-ledger-no-version-accept-reconcile-guard.md` tamamen yeniden yazıldı: karar "A-only yerine A+D defense-in-depth" (kod gerçeğine uyumlu)
  - `wiki/contradictions.md` 2026-04-24 girdisi → **RESOLVED**
- **4. OpenAPI Faz A**:
  - Migration backend running gerektirir → kullanıcı ortamında yapılacak iş olarak belgelendi
  - `project_pos/lib/api/README.md` → 7 adımlı "Faz A Prerequisites" checklist eklendi (backend up → export → generator install → generate → pubspec path dep → pub get)
- Backend `mvn clean compile` → BUILD SUCCESS

## [2026-04-24] sprint-6b | Vehicle Tracking — Seçenek A (pragmatik plaka)
- **Karar**: Plan C seçeneği W2 Sales ingest'te çürüdü. Schema eklemek yerine A pragmatik seçimi: description içinde "Plaka: XX" string.
- `payment_record_modal.dart` → opsiyonel plaka TextField + `_normalizePlate` helper + `_submit` plaka prepend
- `security/src/main/resources/data.sql` → yeni i18n anahtarları
- Backend: sıfır değişiklik

## [2026-04-24] sprint-6a | Payment UX — verification & wiki sync
- Implementasyon bulgusu: plan Sprint 6a hedefi transactions card P0.3 kapsamında zaten yapılmış
- Scoped wiki sync ve yeni sayfa
- Sprint 6a kod işi yapıldığı için yeni implementation yok

## [2026-04-24] sprint-5 | Credit limit enforcement (P2.5) + PDF export (P2.3 partial)
- P2.5 Credit limit RESOLVED: SaleRequest.overrideCreditLimit + SecurityContextHolder rol check + audit log
- P2.3 PDF export PARTIAL: PDFBox minimum viable + Türkçe ASCII sanitize
- Email endpoint ayrı mini-sprint'e bırakıldı

## [2026-04-24] sprint-4 | OpenAPI codegen INFRA (P1.2)
- Sadece infra kur, mevcut ekranları dokunma. Migration Faz A/B/C ayrı PR'lara
- SecurityConfiguration → /v3/api-docs/** + /swagger-ui/** permitAll
- scripts/export-openapi.sh + Flutter generate-api.sh + lib/api/README.md

## [2026-04-24] sprint-3 | Scheduled reconcile + Micrometer metrics (P1.1 + P1.4)
- P1.1: SlackNotifier + ReconcileScheduledJob (cron, enabled=false default)
- P1.4: MetricsConfiguration + reconcile counter/timer enstrumantasyonu
- application.properties → reconcile.scheduled.{enabled,cron} + slack.webhook.url

## [2026-04-24] w3 | Operasyon hijyeni kural seti
- commands/wiki-lint.md "Cadence" + wiki/README.md "Operasyon Hijyeni"

## [2026-04-24] w2-purchase | Purchase + POS domain ingest (3 sayfa)
- Yeni: entities/purchase, entities/supplier-claim, flows/purchase-checkout

## [2026-04-24] w2-inventory | Inventory derinlik ingest (4 sayfa + 2 düzeltme)
- Yeni: entities/store, entities/warehouse, entities/stock-transfer, flows/stock-transfer
- Düzeltme: stock-level + sale-checkout concurrency mekanizması (PESSIMISTIC_WRITE)

## [2026-04-24] w2-sales | Sales domain ingest (4 sayfa)
- Yeni: entities/sale, entities/sale-item, entities/vehicle, flows/sale-checkout

## [2026-04-24] w2 | İçerik dolum — 9 eksik sayfa kapatıldı
- 4 ana wiki + 5 scoped wiki

## [2026-04-24] w1 | Yapısal kurallar — iki-katmanlı wiki hiyerarşisi
- README + CLAUDE.md + patterns/scoped-feature-wiki

## [2026-04-24] sprint-2 | AccountsHub prod-readiness Sprint 2 (P0.4)
- AccountTransactionRepository → 5. aggregate (overdueAmount)
- reconcile servisleri → totals[4] okuma + 4. eşitlik kontrolü
- Çelişki tespit: AccountTransaction.@Version

## [2026-04-24] sprint-1 | AccountsHub prod-readiness Sprint 1 implementation
- P0.1 — @PreAuthorize("hasRole('ADMIN')") + @EnableMethodSecurity
- P0.2 — ReconcileAuditLog entity + service (REQUIRES_NEW)
- P0.3 — ADR yazıldı

## [2026-04-24] setup+ingest | otomatik setup pass
- Faz 1 — yapı tamamlandı
- Faz 2 — 5 kaynak seçildi
- Faz 3 — ingest edildi: 5 raw + 5 source + 6 entity + 3 concept + 4 flow + 3 pattern + 6 decision + 7 issue
- Faz 4 — 2 sentez
- Faz 5 — lint-report (9 bulgu)
- Faz 6 — rapor + log güncellemesi

## [2026-04-24] setup | wiki iskelet kuruldu
- README + index + glossary + contradictions + entities/README + flows/README + patterns/README + integrations/README + log + syntheses/README + archive/README
