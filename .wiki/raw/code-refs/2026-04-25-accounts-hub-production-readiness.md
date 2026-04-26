---
title: AccountsHub Production-Readiness Gap Analysis (pointer)
original-path: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\syntheses\accounts-hub-production-readiness.md
captured-at: 2026-04-25
type: pointer
---

# Pointer → AccountsHub Prod-Readiness

**Orijinal**: `.claude/wiki/syntheses/accounts-hub-production-readiness.md`

Cari hesaplar ekosisteminin production'a çıkış öncesi gap analizi. P0/P1/P2 öncelikli ~15 madde:
- P0: @PreAuthorize, ReconcileAuditLog, ledger concurrency ADR, overdue reconcile
- P1: scheduled reconcile + alert, OpenAPI codegen, pagination, metrics, error boundary
- P2: PDF/email export, overdue notification, credit limit enforcement, activity log, test coverage
