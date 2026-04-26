---
title: Prod-Ready Guards (Kısa Kurallar)
tags: [concept, guards, production]
source: C:\Users\Win11\Documents\GitHub\proje\CLAUDE.md
date: 2026-04-25
status: stub
---

# Prod-Ready Guards

SEDCORE production için işler kuralı koyduğumuz guard'lar:

1. **1 firma = 1 sektör** — `CompanySetting.sectorType` kurulumda set, sonra değişmez
2. **Ürün sektörü otomatik firmadan** — `ProductServiceImpl.createProduct` override
3. **Purchase → storeId zorunlu** — batch flow'da da
4. **UserDefAccess sorgusu** — `findByUserDefAndCompanyCode(user, user.getCompanyCode())`
5. **Store silme** — `isActive=false`; fiziksel silme yasak (soft delete)

## Sources

- [[raw/code-refs/2026-04-25-project-root-claude]]

## Related

- [[concepts/sector-agnostic]]
- [[concepts/multi-tenant]]
