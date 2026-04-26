---
title: Karar — Scheduled Reconcile Default Disabled (Safe Rollout)
tags: [decision, reconcile, rollout]
date: 2026-04-25
status: accepted
source: C:\Users\Win11\Documents\GitHub\proje\pos-product-manager\src\main\java\com\sedcore\finance\job\ReconcileScheduledJob.java
---

# Scheduled Reconcile Safe Rollout

## Karar

`reconcile.scheduled.enabled` property **default false**. Prod'a çıkışta kullanıcı explicit flip yapar; ilk 1 hafta manuel gözlem.

## Gerekçe

- İlk prod'da cron beklenmedik drift miktarı raporlayabilir
- Manuel günlük run + log gözlem ile baseline oluşur
- Sonra cron'a güven artar

## Sources

- `pos-product-manager/src/main/java/com/sedcore/finance/job/ReconcileScheduledJob.java`
- [[raw/code-refs/2026-04-25-drift-reconciliation-flow]]

## Related

- [[entities/reconcile-scheduled-job]]
