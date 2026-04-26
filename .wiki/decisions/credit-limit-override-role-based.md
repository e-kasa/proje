---
title: Karar — Kredi Limiti Override Role-Based
tags: [decision, credit-limit, sales, security]
date: 2026-04-25
status: accepted
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\decisions\credit-limit-override-role-based.md
---

# Kredi Limiti Override — Role-Based

## Karar

Kredi limit aşan satışlar için override `ROLE_ADMIN` veya `ROLE_STORE_ADMIN` tarafından yapılır. Authority-based (`CREDIT_LIMIT_OVERRIDE`) granülarite gelecek iterasyona ertelendi.

## Gerekçe

Mevcut JWT filter authority yüklemediği için authority-based çözüm JWT payload + `role_def` schema + filter değişikliği gerektirir (cross-cutting risk). Role-based pragmatik ve gelecek migration breaking değil (authority string de matching'de dahil).

## Trade-off

- ✅ Mevcut JWT yapısı korundu
- ❌ "Sadece override yetkisi olan ama STORE_ADMIN olmayan" rol imkansız
- 🔜 Fine-grained authority ihtiyacı birikirse RBAC refactor

## Sources

- [[raw/code-refs/2026-04-25-sale-checkout-flow]]
- `.claude/wiki/decisions/credit-limit-override-role-based.md`

## Related

- [[entities/sale-service-integrated]]
- [[entities/customer-account]]
