---
title: Typed API Contract (OpenAPI Codegen)
tags: [concept, api, typed, codegen, integration]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\patterns\openapi-codegen-flutter.md
date: 2026-04-25
status: stub
---

# Typed API Contract

Backend `Map<String,Object>` output yerine OpenAPI schema'dan generate edilmiş typed DTO'lar. Flutter tarafında compile-time alan ismi + tip garantisi. [[concepts/silent-null-bug]]'ını sınıf olarak çözer.

## Pipeline

Spring `@RestController` + springdoc → `/v3/api-docs` → openapi-generator-cli (dart-dio) → Dart `sedcore_api` package.

## Sources

- [[raw/code-refs/2026-04-25-openapi-codegen-pattern]]
- `.claude/wiki/patterns/openapi-codegen-flutter.md`

## Related

- [[concepts/silent-null-bug]]
- [[decisions/openapi-incremental-migration]]
- [[syntheses/integration-catalog]]
