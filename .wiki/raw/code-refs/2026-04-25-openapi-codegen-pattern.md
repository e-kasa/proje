---
title: OpenAPI → Dart Client Codegen Pattern (pointer)
original-path: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\patterns\openapi-codegen-flutter.md
captured-at: 2026-04-25
type: pointer
---

# Pointer → OpenAPI Codegen Pattern

**Orijinal**: `.claude/wiki/patterns/openapi-codegen-flutter.md`

Backend springdoc `/v3/api-docs` → openapi.json → openapi-generator-cli (dart-dio) → Flutter `sedcore_api` typed client. toMap pattern'ının silent-null bug'larını (today-collection, balance-zero) compile-time garanti ile çözer. Aşamalı migration Faz A (1 ekran) → Faz B (feature kalanı) → Faz C (diğer feature'lar).
