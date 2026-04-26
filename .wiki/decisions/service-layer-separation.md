---
title: Karar — 3 Servis Ayrımı (Gateway + Auth + Domain)
tags: [decision, architecture, services]
date: 2026-04-25
status: accepted
source: C:\Users\Win11\Documents\GitHub\proje\CLAUDE.md
---

# 3 Servis Ayrımı

## Karar

Backend 3 ayrı servis: [[entities/api-manager]] (gateway :8080), [[entities/security]] (auth :8002), [[entities/pos-product-manager]] (domain :8001).

## Gerekçe

- Auth ayrı servis — compliance (token secret ayrı deploy), scale farklı
- Gateway tek giriş — cross-cutting (rate limit, log, CORS) tek yerde
- Domain tek servis (microservice karşıtı monolith) — transaction tutarlılığı kritik

## Sources

- [[raw/code-refs/2026-04-25-project-root-claude]]

## Related

- [[entities/api-manager]]
- [[entities/security]]
- [[entities/pos-product-manager]]
