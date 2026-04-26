---
title: Admin Reconcile Endpoint @PreAuthorize Yok (detailed merge from .claude/wiki/)
type: issue
source: .claude/wiki/issues/admin-endpoint-no-preauthorize.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
status: resolved
note: "MERGE_NEEDED — overlap; this resolved version has 2-step fix detail + checklist."
---

# Admin Reconcile Endpoint @PreAuthorize Yok

## Belirti (Potansiyel)
`AdminAccountsReconcileControllerImpl` endpoint'leri (`/api/v1/admin/accounts/reconcile/**`) herhangi bir rol kontrolü yapmıyor. Sadece path prefix `admin/` ama Spring Security filter chain'de zorunlu role-check yok.

## Risk
- CASHIER rolü bile reconcile tetikleyebilir (drift yoksa zararsız ama `@Version` tick ettirir + log doldurur)
- Drift varsa finansal veri üzerinde etkisi olan bir operasyon — sadece ADMIN rolüne açık olmalı

## Fix (2026-04-24)

İki değişiklik:

1. `AdminAccountsReconcileControllerImpl`'a **class-level** `@PreAuthorize("hasRole('ADMIN')")` + import `org.springframework.security.access.prepost.PreAuthorize`.
2. `pos-product-manager/src/main/java/com/sedcore/common/config/SecurityConfiguration.java` — `@EnableMethodSecurity` anotasyonu (Spring Security 6+ method-level security için zorunlu).

## Pre-production Checklist

- [x] @PreAuthorize ekle
- [x] `@EnableMethodSecurity` açık olduğundan emin ol
- [x] Audit log — bkz. [[entities/reconcile-audit-log]] (P0.2)
- [ ] Role hierarchy testi (CASHIER → 403, ADMIN → 200) — Sprint 1 verification matrisi

## İlgili Dosyalar

- pos-product-manager/src/main/java/com/sedcore/finance/controller/impl/AdminAccountsReconcileControllerImpl.java:30 — `@PreAuthorize`
- pos-product-manager/src/main/java/com/sedcore/common/config/SecurityConfiguration.java:21 — `@EnableMethodSecurity`

## Related

- [[syntheses/flow-drift-reconciliation]]
- [[entities/reconcile-audit-log]]
- [[sources/code-refs/2026-04-24-drift-reconcile]]
