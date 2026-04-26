---
title: ReconcileScheduledJob (Gece Reconcile Görevi)
tags: [entity, job, scheduler, multi-tenant]
source: C:\Users\Win11\Documents\GitHub\proje\pos-product-manager\src\main\java\com\sedcore\finance\job\ReconcileScheduledJob.java
date: 2026-04-25
status: stub
---

# ReconcileScheduledJob

`@Scheduled(cron=...)` görevi; multi-tenant iteration ile her gece (default 03:00) tüm aktif tenant'lar için drift reconcile koşturur. Flag `reconcile.scheduled.enabled` default false — safe rollout.

## Akış

1. `CompanySettingRepository.findAllActiveCompanyCodes()` — native query (Hibernate @Filter bypass)
2. Her tenant: `CompanyContext.set` → customer+supplier reconcileAll → `.clear()`
3. Aggregate Slack rapor

## Sources

- `pos-product-manager/src/main/java/com/sedcore/finance/job/ReconcileScheduledJob.java`
- [[raw/code-refs/2026-04-25-drift-reconciliation-flow]]

## Related

- [[entities/slack-notifier]]
- [[decisions/scheduled-reconcile-safe-rollout]]
- [[concepts/multi-tenant]]
