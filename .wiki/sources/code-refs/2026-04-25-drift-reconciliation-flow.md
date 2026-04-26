---
title: Drift Reconciliation Akışı
tags: [source, drift, reconcile, ledger, scheduled, multi-tenant]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\flows\drift-reconciliation.md
raw: "[[raw/code-refs/2026-04-25-drift-reconciliation-flow]]"
date: 2026-04-25
status: draft
---

# Drift Reconciliation İngest Özeti

## Amaç

Denormalize cari hesap (CustomerAccount/SupplierAccount) ile ledger (AccountTransaction) arasındaki sapmayı (drift) tespit et ve düzelt. Ledger kabul edilir, denormalize üstüne yazılır.

## Ne Yapıldı

İki tetikleyici: (1) manuel admin endpoint `/admin/accounts/reconcile` (ADMIN rolü gerekli, @PreAuthorize), (2) scheduled nightly cron (multi-tenant iterate, flag-kontrollü default `enabled=false`). Her reconcile 5-aggregate query kullanır (balance, debt, credit, count, overdueAmount). Drift > 0 varsa override + save + ReconcileAuditLog (REQUIRES_NEW propagation). Micrometer counter + timer + Slack webhook alert.

## Değişenler / Kapsam

- **Service**: `CustomerAccountServiceImpl.reconcile` / `reconcileAll`, simetrik SupplierAccountServiceImpl
- **Job**: [[entities/reconcile-scheduled-job]] — @Scheduled cron, multi-tenant: `CompanySettingRepository.findAllActiveCompanyCodes()` + per-tenant CompanyContext.set/clear
- **Notification**: [[entities/slack-notifier]] — JDK HttpClient, no-op fallback
- **Metrics**: `reconcile.runs.total{entity_type,scope,status}`, `reconcile.drift.total{entity_type}`, `reconcile.duration.seconds{entity_type,scope}`
- **Config**: `reconcile.scheduled.{enabled,cron}`, `slack.webhook.url`

## Alınan Kararlar

- [[decisions/ledger-as-source-of-truth]] — drift'te ledger kabul
- [[decisions/idempotent-reconcile-no-op-guard]] — drift 0 ise save yok (@Version tick yok)
- [[decisions/ledger-concurrency-defense-in-depth]] — @Version + reconcile birlikte (A+D)
- [[decisions/scheduled-reconcile-safe-rollout]] — enabled=false default, ilk hafta manuel gözlem

## Karşılaşılan Sorunlar

- [[issues/overdue-amount-not-reconciled]] → resolved (Sprint 2, 5. aggregate eklendi)
- [[issues/admin-endpoint-no-preauthorize]] → resolved (Sprint 1)

## Açık Konular

- Prod'da drift insidansı ölçümü (ilk hafta gözlem sonrası karar)
- Büyük tenant sayısında cron süresi (paralel tenant işleme adayı)

## Sources

- `.claude/wiki/flows/drift-reconciliation.md`
- `pos-product-manager/src/main/java/com/sedcore/finance/job/ReconcileScheduledJob.java`
- `pos-product-manager/src/main/java/com/sedcore/customer/service/impl/CustomerAccountServiceImpl.java`
- [[raw/code-refs/2026-04-25-drift-reconciliation-flow]]

## Related

- [[syntheses/accounts-module-overview]]
- [[concepts/drift]]
- [[concepts/denormalization-with-reconcile]]
- [[concepts/ledger-vs-denormalize]]
