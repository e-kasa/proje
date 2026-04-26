---
title: Karar — toMap Pattern Deprecated Candidate
tags: [decision, dto, deprecated, api]
date: 2026-04-25
status: accepted
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\patterns\dto-tomap-pattern.md
---

# toMap Pattern Deprecated-Candidate

## Karar

Controller'da inline `Map<String,Object> toMap(entity)` pattern'ı **yeni kodda kullanılmaz**. Mevcut kullanım kademeli olarak typed DTO'ya taşınır ([[decisions/openapi-incremental-migration]]).

## Gerekçe

3+ silent-null bug'a neden oldu (bkz. [[concepts/silent-null-bug]]). OpenAPI codegen infra kuruldu — yeni endpoint'ler typed DTO ile, mevcut endpoint'ler Faz A/B/C ile migrate.

## Sources

- `.claude/wiki/patterns/dto-tomap-pattern.md`
- [[raw/code-refs/2026-04-25-openapi-codegen-pattern]]

## Related

- [[concepts/typed-api-contract]]
- [[concepts/silent-null-bug]]
- [[decisions/openapi-incremental-migration]]
