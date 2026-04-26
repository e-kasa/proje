---
title: Admin Reconcile Endpoint @PreAuthorize Eksik (RESOLVED)
tags: [issue, resolved, security, accounts]
date: 2026-04-25
status: resolved
resolved-date: 2026-04-24
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\issues\admin-endpoint-no-preauthorize.md
---

# Admin Reconcile Endpoint @PreAuthorize Eksik

**Kök neden**: `AdminAccountsReconcileControllerImpl` 3 endpoint role check yapmıyordu — CASHIER dahi tetikleyebiliyor.

**Fix**: Class-level `@PreAuthorize("hasRole('ADMIN')")` + SecurityConfig `@EnableMethodSecurity` (Sprint 1).

## Sources

- [[raw/code-refs/2026-04-25-accounts-hub-production-readiness]]
- `.claude/wiki/issues/admin-endpoint-no-preauthorize.md`

## Related

- [[syntheses/accounts-module-overview]]
