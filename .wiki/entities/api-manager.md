---
title: api-manager (Gateway Servisi)
tags: [entity, service, gateway, spring]
source: C:\Users\Win11\Documents\GitHub\proje\CLAUDE.md
date: 2026-04-25
status: stub
---

# api-manager

SEDCORE POS'un API gateway servisi. İstemci (Flutter / React) tek bu servise bağlanır; auth ve domain isteklerini arka servislere yönlendirir.

- **Port**: 8080
- **Context path**: `/` (gateway)
- **Yönlendirme**: `/security/**` → security:8002, `/product/**` → pos-product-manager:8001
- **Modül doküman**: `api-manager/CLAUDE.md`

## Sources

- [[raw/code-refs/2026-04-25-project-root-claude]]
- `api-manager/CLAUDE.md`

## Related

- [[entities/security]]
- [[entities/pos-product-manager]]
- [[concepts/jwt-auth]]
