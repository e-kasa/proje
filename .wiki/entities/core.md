---
title: core (Shared Library)
tags: [entity, library, maven, base]
source: C:\Users\Win11\Documents\GitHub\proje\CLAUDE.md
date: 2026-04-25
status: stub
---

# core

Tüm backend servislerinin paylaştığı Maven kütüphanesi. `TOpenSimpleCompanyEntity` gibi base class'lar, exception mapper, filter, security base burada.

- **Maven coord**: `com.towpen:core:11.3.5`
- **Build sırası**: İlk — `cd core && mvn install -q`
- **Base entity**: `TOpenDbEntity` → `TOpenSimpleDbEntity` → `TOpenSimpleCompanyEntity` (companyCode otomatik)

## Sources

- [[raw/code-refs/2026-04-25-project-root-claude]]
- `core/CLAUDE.md`

## Related

- [[entities/security]]
- [[entities/pos-product-manager]]
- [[concepts/multi-tenant]]
