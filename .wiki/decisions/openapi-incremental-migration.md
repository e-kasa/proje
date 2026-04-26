---
title: Karar — OpenAPI Codegen Aşamalı Migration
tags: [decision, openapi, migration, risk]
date: 2026-04-25
status: accepted
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\patterns\openapi-codegen-flutter.md
---

# OpenAPI Aşamalı Migration

## Karar

Infrastructure kuruldu; migration Faz A (1 ekran) → Faz B (feature kalanı) → Faz C (diğer feature'lar) sırasıyla ayrı PR'larda. Tek büyük PR'da tüm migration yasak (risk).

## Gerekçe

Generated kod tüm client model'ini bozabilir. İzole generated package (`sedcore_api`) + tek ekran pilot + küçük PR → review edilebilir, rollback kolay.

## Sources

- [[raw/code-refs/2026-04-25-openapi-codegen-pattern]]
- `.claude/wiki/patterns/openapi-codegen-flutter.md`

## Related

- [[concepts/typed-api-contract]]
- [[decisions/commit-generated-code]]
- [[decisions/dart-dio-generator-choice]]
