---
title: pos-product-manager (Domain Servisi)
tags: [entity, service, domain, spring, postgresql]
source: C:\Users\Win11\Documents\GitHub\proje\CLAUDE.md
date: 2026-04-25
status: stub
---

# pos-product-manager

Ana POS domain servisi — ürün / satış / satın alma / stok / cari / raporlar. Tüm iş mantığı burada.

- **Port**: 8001
- **Context path**: `/product`
- **Stack**: Spring Boot 3.5.7, Hibernate, PostgreSQL, Java 25 (virtual threads)
- **Multi-tenant**: Hibernate `@Filter` + `CompanyContext` thread-local
- **Modül doküman**: `pos-product-manager/CLAUDE.md`

## Sources

- [[raw/code-refs/2026-04-25-project-root-claude]]
- `pos-product-manager/CLAUDE.md`

## Related

- [[entities/api-manager]]
- [[entities/core]]
- [[concepts/multi-tenant]]
