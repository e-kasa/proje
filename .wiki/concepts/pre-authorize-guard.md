---
title: "@PreAuthorize — Spring Security method-level rol kontrolü"
type: concept
source: pos-product-manager/src/main/java/com/sedcore/finance/controller/impl/AdminAccountsReconcileControllerImpl.java
ingested: 2026-04-25
last-verified: 2026-04-25
status: stub
---

# @PreAuthorize Guard

## Tanım

Spring Security method/class-level rol kontrolü annotation'ı (`@PreAuthorize("hasRole('ADMIN')")`). Hassas endpoint'lerde JWT rolüne göre erişimi sınırlar.

## Kod Konumu

- pos-product-manager içinde **tek kullanım** (2026-04-25 tarama):
  - `pos-product-manager/src/main/java/com/sedcore/finance/controller/impl/AdminAccountsReconcileControllerImpl.java:31` — class-level `@PreAuthorize("hasRole('SUPER_ADMIN')")`
- Diğer admin endpoint'lerde **eksik** (resolved issue: [[issues/admin-endpoint-no-preauthorize]])

## Davranış

- `SecurityConfig` üstünde `@EnableMethodSecurity` aktif olmalı; aksi halde annotation görmezden gelinir.
- JWT'den çıkan `selectedRole` veya benzeri claim Spring Security context'e atanmalı.
- Sprint 1'de `AdminAccountsReconcileController` için kapatıldı (issue çözümü).

## Kullanım

- `/product/api/v1/admin/accounts/reconcile/**` rotaları — `SUPER_ADMIN` koruması.
- **Eksik kapsama**: Diğer admin endpoint'ler (örn. company create, role assign) hâlâ `@PreAuthorize`'sız — yaygınlaştırılması gereken pattern.

## Defense-in-Depth Bağlamı

`@PreAuthorize` tek başına yeterli değil — mimari savunma:
1. Gateway JWT doğrulama (api-manager)
2. Backend filter chain (security)
3. Method annotation (`@PreAuthorize`)
4. Repository tenant filter (`@Filter`)

Her katman bağımsız çalışır → biri atlanırsa diğer yakalar.

## Related

- [[issues/admin-endpoint-no-preauthorize]]
- [[concepts/jwt-auth]]
- [[concepts/defense-in-depth]]
