---
title: Wiki İçerik Kataloğu (MOC)
type: index
last-verified: 2026-04-25
---

# SEDCORE POS — Wiki İçerik Kataloğu

Bu dosya, wiki'nin **Map of Content (MOC)** giriş noktasıdır. Yeni sayfa eklendikçe kategorisi altına tek satır olarak buraya işlenir.

> **Önce oku**: [CLAUDE.md](CLAUDE.md) — ajan protokolü, amaç, kurallar.
> **Migration notu**: 2026-04-25'te proje genelindeki ~117 `.md` dosyası bu wiki'ye konsolide edildi. Kaynak yerlerde 1-satır pointer stub bırakıldı. Detay: [[log]] (2026-04-25 girişi).

## Genel

- [[log]] — append-only olay kaydı
- [[lint-report]] — son sağlık taraması (2026-04-25)
- [[archive/README]] — eskimiş sayfaların taşıma yeri (placeholder, MERGE_NEEDED 18 dosya hedefi) — eskimiş sayfaların taşıma yeri

## Operasyonlar (Workflow)

- `ingest` — `raw/code-refs/` içindeki yeni kaynakları işle
- `query` — wiki'ye soru sor; iyi cevaplar `syntheses/`'e geri-dosyalanır
- `lint` — sağlık taraması (çelişki, yetim sayfa, eskimiş kaynak, kaynak boşluğu)

## CLAUDE.md Arşivi (auto-load kopya)

Proje genelinde Claude Code tarafından otomatik yüklenen CLAUDE.md'lerin içerik kopyaları. Orijinaller yerinde stub olarak kalır ve buraya pointer verir.

- [[sources/claude-md/root]] — proje kökü (mimari + 11 bölüm)
- [[sources/claude-md/api-manager]] · [[sources/claude-md/core]] · [[sources/claude-md/security]] · [[sources/claude-md/pos-product-manager]]
- [[sources/claude-md/project-pos]] · [[sources/claude-md/template]]
- [[sources/claude-md/project-pos-batch-entry]] · [[sources/claude-md/project-pos-accounts-wiki]]
- [[sources/claude-md/claude-wiki-protocol]] — eski `.claude/wiki/` ajan protokolü

## Status Snapshots

`.claude/status/` altından taşınan tarihli proje durum raporları.

- [[sources/status-snapshots/sprint]] — aktif sprint + roadmap
- [[sources/status-snapshots/ui-modernization]] — UI modernizasyon ilerlemesi
- [[sources/status-snapshots/live-status-2026-04-23]] — 23 Nisan canlı durum

## Sources (İşlenen Kaynaklar)

### Code-refs — orijinal ingest (2026-04-25)
- [[sources/code-refs/2026-04-25-project-root-claude]] — proje mimarisi + servisler
- [[sources/code-refs/2026-04-25-accounts-hub-production-readiness]] — cari hesap prod gap
- [[sources/code-refs/2026-04-25-sale-checkout-flow]] — POS satış akışı
- [[sources/code-refs/2026-04-25-purchase-checkout-flow]] — satın alma + claim
- [[sources/code-refs/2026-04-25-drift-reconciliation-flow]] — drift senkron
- [[sources/code-refs/2026-04-25-openapi-codegen-pattern]] — typed client codegen
- [[sources/code-refs/2026-04-25-ledger-version-adr]] — concurrency ADR

### Code-refs — migration (eski tarihli code snapshots)
- [[sources/code-refs/2026-04-17-units-employee-modern]]
- [[sources/code-refs/2026-04-21-accounts-hub-screens]]
- [[sources/code-refs/2026-04-22-accounts-hub-perf]]
- [[sources/code-refs/2026-04-23-batch-entry-4area]]
- [[sources/code-refs/2026-04-24-drift-reconcile]]

### Code-refs — proje dokümanları (taşıma)
- [[sources/code-refs/development-features-roadmap]] — özellik roadmap
- [[sources/code-refs/screens-inventory]] — ekran envanteri
- [[sources/code-refs/vscode-setup-implementation]] — VSCode kurulum rehberi
- [[sources/code-refs/claude-INDEX]] — eski `.claude/INDEX.md` (proje navigation)
- [[sources/code-refs/claude-command-wiki-ingest]] · [[sources/code-refs/claude-command-wiki-query]]
- [[sources/code-refs/claude_code_komutlari]] · [[sources/code-refs/claude_code_toplu_urun_ekleme]]
- [[sources/code-refs/flutter_iyilestirme_analizi]]
- [[sources/code-refs/project-pos-readme]] · [[sources/code-refs/template-readme]]
- [[sources/code-refs/claude-wiki-contradictions]] · [[sources/code-refs/claude-wiki-index]] · [[sources/code-refs/claude-wiki-log]] · [[sources/code-refs/claude-wiki-lint-report]]
- [[sources/code-refs/claude-wiki-entities-readme]]

## Entities (Servis / Dosya / Domain)

### Servisler
- [[entities/api-manager]] · [[entities/security]] · [[entities/pos-product-manager]] · [[entities/core]] · [[entities/project-pos]] · [[entities/template]]

### Security Domain
- [[entities/user-def]] · [[entities/user-def-access]] — sistem kullanıcısı + erişim kaydı

### Domain
- Satış: [[entities/sale]] · [[entities/sale-item]]
- Ürün: [[entities/product-variant]] — SKU bazlı satış birimi
- Müşteri: [[entities/customer]] · [[entities/customer-account]]
- Tedarikçi: [[entities/supplier]] · [[entities/supplier-account]] · [[entities/supplier-claim]]
- Satın alma: [[entities/purchase]]
- Stok: [[entities/stock-level]] · [[entities/stock-movement]] · [[entities/stock-transfer]] · [[entities/store]] · [[entities/warehouse]]
- Ledger: [[entities/account-transaction]] · [[entities/reconcile-audit-log]]
- Firma: [[entities/company-setting]] — sektör + profil
- Diğer: [[entities/payment]] · [[entities/payment-allocation]] · [[entities/vehicle]]

### Flutter Screens & Models
- [[entities/accounts-hub-screen]] — cari hesap master/detail hub
- [[entities/batch-entry-row]] — toplu giriş satır modeli
- [[entities/document-item-result]] — PDF analiz kalem DTO

### Servis-Impl & Job
- [[entities/sale-service-integrated]] · [[entities/purchase-service-impl]]
- [[entities/reconcile-scheduled-job]] · [[entities/slack-notifier]]

## Concepts (Soyut Kavramlar)

### Mimari
- [[concepts/multi-tenant]] · [[concepts/multi-tenant-routing]] · [[concepts/company-context]] — ThreadLocal taşıyıcı · [[concepts/sector-agnostic]] · [[concepts/jwt-auth]] · [[concepts/jwt-payload]] · [[concepts/pre-authorize-guard]] — Spring Security guard · [[concepts/i18n]] · [[concepts/prod-ready-guards]]
- [[concepts/url-routing]] — URL prefix sözleşmesi · [[concepts/api-response]] — yanıt zarfı · [[concepts/sector-strings]] — sektör string sabitleri

### Flutter / Frontend
- [[concepts/app-colors-palette]] — tasarım sistem rengi
- [[concepts/state-notifier-vs-async]] — Riverpod migration notu
- [[concepts/batch-entry-state]] — toplu giriş Riverpod state
- [[concepts/batch-row-status]] — satır durum makinesi

### Tanı / Troubleshooting
- [[concepts/troubleshooting-customer-missing-in-accounts-hub]] — POS'ta görünüp AccountsHub'da görünmeyen müşteri (5 olası neden)
- ⚠️ [[concepts/multi-company-per-user-architecture]] — DOĞRU yorum: sistem multi-firma per-user, "firma bazlı arama" UI filter ile
- ❌ [[syntheses/tenant-leak-controller-direct-repository-2026-04-26]] — DEPRECATED (yanlış tenant-leak yorumu, hot-fix v3 revert edildi)

### Cari Hesap & Ledger
- [[concepts/drift]] · [[concepts/ledger-vs-denormalize]] · [[concepts/write-through-cache]] · [[concepts/denormalization-with-reconcile]] · [[concepts/append-only]] · [[concepts/payment-allocation-pattern]] (Sprint 7)

### Concurrency
- [[concepts/optimistic-lock-version]] · [[concepts/defense-in-depth]]

### Patterns (taşınan)
- [[concepts/pattern-base-entity-list-screen]] · [[concepts/pattern-denormalization-with-reconcile]] · [[concepts/pattern-dto-tomap-pattern]] · [[concepts/pattern-entity-graph-n-plus-one]] · [[concepts/pattern-openapi-codegen-flutter]] · [[concepts/pattern-optimistic-lock-version-from-claude-wiki]] · [[concepts/pattern-scoped-feature-wiki]]

### API & Diğer
- [[concepts/typed-api-contract]] · [[concepts/silent-null-bug]] · [[concepts/invoice-vs-total-shortage]]
- [[concepts/batch-entry-hierarchy]] — toplu ürün giriş akışı
- [[concepts/glossary]] — terim sözlüğü

## Decisions (Atomik Kararlar)

### Mimari (orijinal sentezler)
- [[decisions/service-layer-separation]] · [[decisions/ddl-create-dev-strategy]] · [[decisions/sedcore-role-taxonomy]] · [[decisions/location-id-type-unified]]

### Mimari (taşınan ADR'ler — `.claude/decisions/`)
- [[decisions/2026-04-13-ddl-create-strategy]] · [[decisions/2026-04-13-store-admin-rename]] · [[decisions/2026-04-13-location-id-unification]]

### Sprint 6b
- [[decisions/2026-04-24-vehicle-plate-tracking-option-a]] — plaka takibi pragmatik karar (description prepend) **[superseded by vehicle-plate-end-to-end-design]**

### Sprint 9-11 — Plaka Takibi Bütünsel
- [[syntheses/vehicle-plate-end-to-end-design-2026-04-26]] — Opsiyon C: CustomerVehicle entity + sektör-aware POS+Accounts entegrasyonu (3 sprint)

### Sprint 7
- [[decisions/payment-allocation-from-day-1]] — Sale-Payment many-to-many baştan (B1↔B3 mimari karar)

### Concurrency
- [[decisions/ledger-concurrency-defense-in-depth]] · [[decisions/stock-level-pessimistic-lock]] · [[decisions/trust-reconcile-no-ledger-version]]

### Cari
- [[decisions/ledger-as-source-of-truth]] · [[decisions/idempotent-reconcile-no-op-guard]] · [[decisions/scheduled-reconcile-safe-rollout]] · [[decisions/manual-reconcile-before-scheduled]] · [[decisions/rename-balance-to-currentbalance]]
- [[decisions/db-side-aggregate-over-java-loop]] · [[decisions/use-entity-graph-for-customer-account-fetch]]

### Satış / Satın alma
- [[decisions/credit-limit-override-role-based]]
- [[decisions/debit-only-received-amount]] · [[decisions/supplier-claim-auto-open]] · [[decisions/discount-no-account-effect]]

### API/Codegen
- [[decisions/openapi-incremental-migration]] · [[decisions/dart-dio-generator-choice]] · [[decisions/commit-generated-code]] · [[decisions/dto-tomap-deprecated-candidate]]

### Export
- [[decisions/pdf-backend-over-client]]

## Issues

### Çözülmüş
- [[issues/admin-endpoint-no-preauthorize]] · [[issues/admin-endpoint-no-preauthorize-from-claude-wiki]]
- [[issues/overdue-amount-not-reconciled]] · [[issues/overdue-amount-not-reconciled-from-claude-wiki]]
- [[issues/credit-limit-not-enforced]]
- [[issues/stock-concurrency-documented-wrong]]
- [[issues/today-collection-always-zero]] · [[issues/today-collection-always-zero-from-claude-wiki]]
- [[issues/customer-list-balance-zero]] · [[issues/customer-list-balance-zero-from-claude-wiki]]
- [[issues/supplier-list-balance-zero]] · [[issues/supplier-list-balance-zero-from-claude-wiki]]
- [[issues/n-plus-one-customer-account-fetch]]
- [[issues/batch-entry-provider-truncated]]

### Açık
- [[issues/accounts-pagination-missing]] (P1.3)
- [[issues/accounts-error-boundary-missing]] (P1.5)
- [[issues/overdue-notification-missing]] (P2.4)
- [[issues/activity-history-missing]] (P2.6)
- [[issues/test-coverage-unknown]] (P2.7)

> **Not (overlap):** `-from-claude-wiki` suffix'li dosyalar `.claude/wiki/` migration'ından geldi ve mevcut sayfa ile içerik farklılığı tespit edildi (MERGE_NEEDED). Manuel inceleme + birleştirme gelecek bir bakım iterasyonunda yapılacak.

## Syntheses (Üst Düzey Genel Bakış)

### Modül & Mimari Özet
- [[syntheses/codebase-snapshot-2026-04-25]] — kod ↔ wiki uyum + drift özeti (2026-04-25)
- [[syntheses/lint-action-plan-2026-04-25]] — 134 lint bulgusu için P1-P4 aksiyon planı
- [[syntheses/pos-module-map]] — modül haritası
- [[syntheses/sector-agnostic-architecture]] — çoklu sektör mimarisi
- [[syntheses/accounts-module-overview]] — cari hesap modülü
- [[syntheses/integration-catalog]] — entegrasyon kataloğu
- [[syntheses/pending-work-status-2026-04-26]] — Açık iş kalemleri konsolide listesi (P0-P3 önceliklendirme)
- [[syntheses/accounts-bugfix-investigation-2026-04-26]] — Hot-fix: POS müşteri listesi + bakiye refresh (3 düzeltme uygulandı)
- [[syntheses/sprint-8-implementation-plan-2026-04-26]] — Sprint 8 plan (B0 pagination + ErrorBoundary + T2-T4 testler)
- [[syntheses/sprint-7-implementation-plan-2026-04-25]] — Sprint 7 adım adım uygulama planı (B1+T1-T4+I2, 6 WP)
- [[syntheses/accounts-development-analysis-2026-04-25-v2]] — geliştirme analizi v2 (review-revize: test+mimari+efor+sprint düzeltmeleri)
- [[syntheses/accounts-development-analysis-2026-04-25]] — v1 (superseded by v2)
- [[syntheses/accounts-overview]] · [[syntheses/accounts-hub-production-readiness]] · [[syntheses/account-edit-form-ux]] · [[syntheses/transactions-card-improvements]]
- [[syntheses/denormalization-strategy]]
- [[syntheses/error-handling-guide]] — hata yönetim rehberi (pos-product-manager)

### Runbook'lar (taşınan — `.claude/runbooks/`)
- [[syntheses/runbook-new-endpoint]] · [[syntheses/runbook-new-entity]] · [[syntheses/runbook-new-feature-flutter]] · [[syntheses/runbook-debug-tenant-leak]]

### Akış Diyagramları (taşınan — `.claude/wiki/flows/`)
- [[syntheses/flow-accounts-hub-load]] · [[syntheses/flow-batch-entry]] · [[syntheses/flow-drift-reconciliation]] · [[syntheses/flow-pdf-statement-export]]
- [[syntheses/flow-purchase-checkout]] · [[syntheses/flow-sale-checkout]] · [[syntheses/flow-stock-transfer]] · [[syntheses/flow-today-collection-calc]]

### Entegrasyonlar (taşınan — `.claude/wiki/integrations/`)
- [[syntheses/integration-prometheus-micrometer]] · [[syntheses/integration-slack-webhook]]

## Archive

_(Boş)_
