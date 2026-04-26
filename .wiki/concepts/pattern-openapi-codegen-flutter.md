---
title: Pattern — OpenAPI Codegen → Flutter Typed Client
type: concept
source: .claude/wiki/patterns/openapi-codegen-flutter.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# OpenAPI Codegen → Flutter Typed Client

## Problem

Backend Spring `@RestController` + Flutter Dio client arasında **typed contract yok**. Controller'lar inline `Map<String, dynamic>` döndürüyor ([[concepts/pattern-dto-tomap-pattern]]), Flutter `res.data['field']` silent null okuyor. Alan yeniden adlandırıldığında compile hatası yok — runtime'da null.

Tarihsel bug'lar:
- [[issues/today-collection-always-zero]] — `paymentDate` → `transactionDate` rename
- [[issues/customer-list-balance-zero]] / [[issues/supplier-list-balance-zero]] — field şema farkı

## Çözüm

**OpenAPI schema → Dart client codegen**:

```
Spring Controller + springdoc
    ↓  /v3/api-docs (JSON)
openapi.json
    ↓  openapi-generator-cli (dart-dio)
lib/api/generated/  ← typed model + Dio client
    ↓  import
Widget/Provider → typed response (nullable alan açıkça nullable)
```

Compile-time garantili alan ismi + tip. Silent-null sınıf olarak ortadan kalkar.

## Pipeline Bileşenleri

| Bileşen | Yol | Rol |
|---|---|---|
| **Backend dep** | `pos-product-manager/pom.xml` — `springdoc-openapi-starter-webmvc-ui` (v2.3.0, zaten var) | `/v3/api-docs` + Swagger UI |
| **Security** | `SecurityConfiguration` `/v3/api-docs/**` + `/swagger-ui/**` permitAll (dev) | Codegen erişimi |
| **Export script** | `pos-product-manager/scripts/export-openapi.sh` | Çalışan serverdan cURL → `target/openapi.json` |
| **Config** | `project_pos/openapi-generator-config.yaml` | dart-dio generator, pubName, skip docs |
| **Gen script** | `project_pos/scripts/generate-api.sh` | openapi-generator-cli çağırır + build_runner |
| **Output** | `project_pos/lib/api/generated/` | Auto-generated, edit yasak |

## Generator Seçimi — `dart-dio`

Alternatifler:
- `dart` — vanilla HTTP client (Dio kullanmaz)
- `dart-dio` — Dio + built_value + json_serializable (mevcut Dio ile uyumlu)
- `dart-dio-next` — newer, henüz stable değil

Karar: **dart-dio** — mevcut `pubspec.yaml`'da `dio: ^5.4.3` zaten var, ekosistem uyumu.

## Aşamalı Migration (Faz A/B/C)

```
Faz A (1 PR)      → AccountsHub list — tek ekran, typed client pilot
Faz B (1 PR)      → Accounts feature kalanı (transactions, payments, reconcile)
Faz C (N PR)      → Diğer feature'lar — sales, purchase, inventory, …
```

**Kural**: tek PR'da tüm client taşınmaz. Her Faz review edilebilir boyutta.

## Prod Uyarısı — Security

Dev'de `/v3/api-docs` + `/swagger-ui/**` permitAll. Prod için üç seçenek:

1. **IP whitelist** — VPN/intranet'ten erişim
2. **Admin-only** — `@PreAuthorize("hasRole('ADMIN')")` (kontrollü)
3. **Disable** — prod profilinde `springdoc.api-docs.enabled=false`; codegen sadece CI ortamında (staging spec ile)

Önerilen: **2 veya 3**, env-specific.

## Tuzaklar

- **BigDecimal → double** — generator default serialization kayıplı. `additionalProperties: useBigDecimalForDouble=true` şart olabilir
- **LocalDate / LocalDateTime → String** — ISO-8601 çevirimi dart tarafında manuel; model adapter
- **Generated kod commit mi?** — Commit: CI reproducibility, code review edilebilir. Tercih edilir.
- **Generator versiyon drift'i** — `openapi-generator-cli --version X.Y.Z` pinle
- **`modelDocs=false, apiDocs=false`** — çıktı küçülür ama migration sırasında dokümantasyon yok

## Sources

- `pos-product-manager/pom.xml` (springdoc-openapi-starter-webmvc-ui)
- `pos-product-manager/src/main/java/com/sedcore/common/config/SecurityConfiguration.java`
- `pos-product-manager/scripts/export-openapi.sh`
- `project_pos/openapi-generator-config.yaml`
- `project_pos/scripts/generate-api.sh`
- `project_pos/lib/api/README.md`

## Related

- [[concepts/pattern-dto-tomap-pattern]] — codegen ile deprecate edilecek pattern
- [[issues/today-collection-always-zero]] — silent-null bug (motivasyon)
- [[syntheses/accounts-hub-production-readiness]] (P1.2)
