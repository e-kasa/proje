---
title: OpenAPI → Dart Client Codegen Pattern
tags: [source, openapi, codegen, flutter, integration, typed-client]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\patterns\openapi-codegen-flutter.md
raw: "[[raw/code-refs/2026-04-25-openapi-codegen-pattern]]"
date: 2026-04-25
status: draft
---

# OpenAPI Codegen İngest Özeti

## Amaç

Backend Spring controller'ları ile Flutter Dio client arasında typed contract kurmak. `Map<String,dynamic>` silent-null bug'larını compile-time garantiyle çözmek.

## Ne Yapıldı

Pipeline kuruldu (infrastructure-only, migration ayrı PR'lara erteli):
1. Backend `/v3/api-docs` permitAll (dev)
2. `scripts/export-openapi.sh` → curl ile `target/openapi.json`
3. `openapi-generator-config.yaml` (dart-dio generator, skip docs/tests)
4. `scripts/generate-api.sh` → openapi-generator-cli + build_runner
5. Output: `project_pos/lib/api/generated/` (sedcore_api package)

## Değişenler / Kapsam

- **Backend**: `pom.xml` springdoc zaten mevcut; SecurityConfiguration `/v3/api-docs/**` + `/swagger-ui/**` permitAll
- **Scripts**: `pos-product-manager/scripts/export-openapi.sh`, `project_pos/scripts/generate-api.sh`
- **Config**: `project_pos/openapi-generator-config.yaml`
- **Docs**: `project_pos/lib/api/README.md` (Faz A prerequisites 7 maddelik checklist), `MIGRATION_EXAMPLE.md` (before/after örüntü)

## Alınan Kararlar

- [[decisions/dart-dio-generator-choice]] — mevcut Dio dep ile uyumlu
- [[decisions/openapi-incremental-migration]] — Faz A (1 ekran) → Faz B (feature kalanı) → Faz C (diğer feature'lar)
- [[decisions/commit-generated-code]] — CI reproducibility, code review edilebilir
- [[decisions/dto-tomap-deprecated-candidate]] — toMap pattern'ı typed DTO lehine aşamalı bırakılacak

## Karşılaşılan Sorunlar

- [[issues/today-collection-always-zero]] — toMap silent-null (motivasyon örneği)
- [[issues/customer-list-balance-zero]] — aynı (motivasyon)
- [[issues/supplier-list-balance-zero]] — aynı (motivasyon)

## Açık Konular

- Faz A migration henüz yapılmadı (backend up + kullanıcı tetik gerekli)
- Prod'da `/v3/api-docs` sertleştirme (IP whitelist veya admin-only)
- BigDecimal/LocalDate tip adapter tuzakları (ilk generate'te doğrulanacak)

## Sources

- `.claude/wiki/patterns/openapi-codegen-flutter.md`
- `pos-product-manager/scripts/export-openapi.sh`
- `project_pos/scripts/generate-api.sh`
- `project_pos/openapi-generator-config.yaml`
- [[raw/code-refs/2026-04-25-openapi-codegen-pattern]]

## Related

- [[syntheses/integration-catalog]]
- [[concepts/typed-api-contract]]
- [[concepts/silent-null-bug]]
