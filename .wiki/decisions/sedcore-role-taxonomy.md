---
title: Karar — STORE_ADMIN Standardı (STORE_MANAGER Deprecated)
tags: [decision, roles, auth]
date: 2026-04-25
status: accepted
source: C:\Users\Win11\Documents\GitHub\proje\CLAUDE.md
---

# STORE_ADMIN Standardı

## Karar

5 ana rol: `ADMIN`, `STORE_ADMIN`, `CASHIER`, `WAREHOUSE`, `SUPER_ADMIN`. Eski `STORE_MANAGER` deprecated — tüm migration `STORE_ADMIN`'e geçiş yapar.

## Gerekçe

- Naming tutarlılık (ADMIN ile paralel)
- Backend @PreAuthorize string eşleşmesi basit

## Sources

- [[raw/code-refs/2026-04-25-project-root-claude]]

## Related

- [[decisions/credit-limit-override-role-based]]
