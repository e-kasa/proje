# SEDCORE API Client Codegen (Sprint 4 — Infra)

> **Durum**: infra kuruldu, **hiçbir mevcut ekran migrate edilmedi**. Faz A planlı.

## Amaç

Backend (pos-product-manager) ile Flutter client arasında **typed contract**. `Map<String,dynamic>` silent-null bug'larını (bkz. `../../.claude/wiki/issues/today-collection-always-zero.md`) köklü çözer.

## Pipeline

```
pos-product-manager (@RestController + springdoc)
    ↓  GET /product/v3/api-docs
pos-product-manager/target/openapi.json        ← export-openapi.sh
    ↓  openapi-generator-cli (dart-dio)
project_pos/lib/api/generated/                 ← generate-api.sh
    ↓  pubspec path dependency
ekran.dart → TypedApiClient()                  ← Faz A/B/C (migration)
```

## Kullanım

### 1. Backend'i çalıştır
```bash
cd ../pos-product-manager
mvn spring-boot:run
```

### 2. OpenAPI spec export
```bash
cd ../pos-product-manager
bash scripts/export-openapi.sh
# → target/openapi.json oluşur
```

### 3. Dart client generate
```bash
cd ../project_pos
bash scripts/generate-api.sh
# → lib/api/generated/ oluşur (built_value + Dio)
```

VEYA tek komutla:
```bash
REFRESH=1 bash scripts/generate-api.sh
```

## Faz A Prerequisites (2026-04-24 notu)

Faz A başlatmak için gerekli adımlar — **ilk pilot PR çalışmaya başlamadan önce** kullanıcı ortamında bir kere yapılmalı:

- [ ] Backend up: `cd pos-product-manager && mvn spring-boot:run`
- [ ] Spec export: `bash pos-product-manager/scripts/export-openapi.sh` → `target/openapi.json` (`> 50KB` beklenir)
- [ ] `openapi-generator-cli` kurulu: `npm i -g @openapitools/openapi-generator-cli` (veya `npx` ile)
- [ ] Generate: `bash project_pos/scripts/generate-api.sh`
- [ ] `lib/api/generated/pubspec.yaml` oluştu, model + api class'ları dolu
- [ ] `project_pos/pubspec.yaml` path dep eklendi: `sedcore_api: path: lib/api/generated`
- [ ] `flutter pub get` temiz geçer

Bu 7 adım geçtikten sonra Faz A ekran migrasyon PR'ı başlatılabilir (AccountsHub list).

## Faz A/B/C Migration

### Faz A — 1 ekran pilot (önerilen ilk PR)
- AccountsHub list (`project_pos/lib/features/accounts/screens/accounts_hub_screen.dart`)
- Bu ekrandaki `accountsListProvider` → `AccountsApi.getCustomerAccounts()` typed call
- **Mevcut service / provider değişmesin** — sadece typed model deserialization
- Acceptance: ekran çalışır + derleme temiz + `flutter analyze` uyarısız

### Faz B — accounts feature kalanı
- Transactions, payments, reconcile
- Typed client feature-scoped

### Faz C — diğer feature'lar
- Sales, purchase, inventory... ayrı PR başına

## Kurallar

1. **Generated kodu EDİTLEME** — `lib/api/generated/` otomatik üretilir, manual değişiklik bir sonraki generate'te silinir
2. **Migration tek ekran/tek PR** — büyük PR riskli, küçük + review edilebilir
3. **Feature flag olursa** — eski/yeni code path switch için `appFeatureFlagsProvider` (var olanı kullan)
4. **Backend değişirse** — yeniden generate + migration impact varsa changelog

## Risk & Azaltma

| Risk | Azaltma |
|---|---|
| Generated kod mevcut handmade model'lerle çakışır | Ayrı paket (`sedcore_api`), ayrı klasör (`lib/api/generated/`); pubspec path dep ile import edilir |
| Generator versiyon farkı | `openapi-generator-cli` versiyonu pinle (script içinde `--version X.Y.Z` — TODO) |
| Büyük generated dosya sayısı | `globalProperties` ile `modelDocs=false, apiDocs=false, tests=false` — zaten config'te |
| Build süresi artar | dart-dio + build_runner: ilk seferde yavaş, sonrası cached |

## İlgili Wiki

- `.claude/wiki/patterns/openapi-codegen-flutter.md` — pattern referansı
- `.claude/wiki/issues/today-collection-always-zero.md` — silent-null bug (motivasyon)
- `.claude/wiki/patterns/dto-tomap-pattern.md` — mevcut anti-pattern (codegen ile deprecate edilir)
- `.claude/wiki/syntheses/accounts-hub-production-readiness.md` — P1.2 item
