---
title: Drift Reconciliation Flow (pointer)
original-path: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\flows\drift-reconciliation.md
captured-at: 2026-04-25
type: pointer
---

# Pointer → Drift Reconciliation

**Orijinal**: `.claude/wiki/flows/drift-reconciliation.md`

Denormalize cari hesap ↔ ledger arasındaki sapmayı düzeltir. Ledger kabul edilir, denormalize üstüne yazılır. Manuel admin endpoint + scheduled job (flag-kontrollü, multi-tenant iterate). 5-aggregate query (balance, debt, credit, count, overdueAmount). Micrometer metrics + Slack alert.

A+D defense-in-depth: @Version runtime + reconcile kümülatif.
