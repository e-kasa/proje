---
title: Kod Tabanı Snapshot — 2026-04-25 (Wiki Drift Analizi)
type: synthesis
date: 2026-04-25
status: draft
scope: tüm proje (api-manager, core, security, pos-product-manager, project_pos, template)
purpose: kod ↔ wiki uyum tespiti, eksik alan + sonraki güncelleme yol haritası
---

# Kod Tabanı Snapshot — 2026-04-25

Wiki bilgisinin canlı kodla **uyum durumu** ve **eksik alanlar**. Pragmatik kapsam: lint bulguları + son 15 commit deltası. Tam re-ingest için kapsam sınırlı (1362 kod dosyası).

## Proje Boyutu

| Alan | Dosya | Wiki kapsamı |
|---|---|---|
| Java backend (api-manager) | 8 | ✅ entity sayfası var ([[entities/api-manager]]) |
| Java backend (core) | 99 | ✅ kısmi ([[entities/core]] — TOpenSimpleCompanyEntity vs.) |
| Java backend (security) | 59 | 🟠 entity sayfası var ama UserDef/UserDefAccess detay eksik (lint) |
| Java backend (pos-product-manager) | 381 | 🟠 büyük bölümü kapsanmış, ProductVariant/CompanySetting eksik (lint) |
| Flutter (project_pos/lib) | 290 | 🟠 ana ekranlar kapsanmış, AccountsHub/BatchEntryRow eksik (lint) |
| React (template/src) | 525 | 🔴 wiki kapsamı zayıf (sadece template/CLAUDE.md kopyası) |
| **TOPLAM** | **1362** | — |

## Son 15 Commit'in Wiki'ye Yansıma Durumu

| Commit | Konu | Wiki sayfası | Durum |
|---|---|---|---|
| `5c2b752` | Sprint 6b — vehicle plate tracking (Option A) | [[decisions/2026-04-24-vehicle-plate-tracking-option-a]] | ✅ **Bu turda eklendi** |
| `c57eeaa` | Sprint 6a scoped wiki sync | scoped wiki (project_pos/.../accounts/_wiki/) | ✅ scoped'da var, ana wiki'ye link |
| `6c6280b` | Credit limit override role-based | [[decisions/credit-limit-override-role-based]] | ✅ var |
| `9a8c704` | PDF + email statement export endpoints | [[syntheses/flow-pdf-statement-export]] | ✅ var (flow düzeyi) |
| `4c2a0a9` | OpenAPI → Dart codegen pipeline | [[concepts/pattern-openapi-codegen-flutter]] · [[decisions/openapi-incremental-migration]] · [[decisions/dart-dio-generator-choice]] | ✅ kapsamlı |
| `d53b33e` | Multi-tenant nightly scheduled reconcile | [[entities/reconcile-scheduled-job]] · [[decisions/scheduled-reconcile-safe-rollout]] | ✅ var |
| `dbf8282` | batch-entry 4-area UX & validation | [[sources/code-refs/2026-04-23-batch-entry-4area]] | ✅ source'da var, sentez eksik |
| `8b6ac05` | AccountsHub backend optimization (DB-side aggregates) | [[sources/code-refs/2026-04-22-accounts-hub-perf]] · [[decisions/db-side-aggregate-over-java-loop]] | ✅ var |
| `88a8e08` | units_screen + employee_list_screen modernizasyonu | [[sources/code-refs/2026-04-17-units-employee-modern]] | ✅ var |

**Sonuç:** Son 15 commit'in **9'u kavram/karar olarak wiki'de yansıyor** (vehicle-plate bu turda eklendi). Diğer commit'ler placeholder veya merge ("123", "1", "22" gibi).

## Wiki'de Eksik Domain Kavramları (Lint → Bu Tur Stub Açıldı)

13 kavram için kod referansından stub sayfa açıldı (paralel agent). Liste için bkz. [[lint-report]] §4 ve [[log]] (2026-04-25 query girdisi).

| Kavram | Konum | Stub yolu |
|---|---|---|
| UserDef | `security/.../entity/UserDef.java` | `entities/user-def.md` |
| UserDefAccess | `security/.../entity/UserDefAccess.java` | `entities/user-def-access.md` |
| ProductVariant | `pos-product-manager/.../entity/ProductVariant.java` | `entities/product-variant.md` |
| CompanyContext | `core/.../CompanyContextFilter.java` | `concepts/company-context.md` |
| PreAuthorize | Spring Security pattern (controller annotations) | `concepts/pre-authorize-guard.md` |
| AccountsHub | `project_pos/.../accounts_hub_screen.dart` | `entities/accounts-hub-screen.md` |
| DocumentItemResult | `pos-product-manager/.../DocumentItemResult.java` | `entities/document-item-result.md` |
| BatchEntryRow | `project_pos/.../batch_entry/.../BatchEntryRow.dart` | `entities/batch-entry-row.md` |
| BatchEntryState | `project_pos/.../batch_entry_provider.dart` | `concepts/batch-entry-state.md` |
| CompanySetting | `pos-product-manager/.../entity/CompanySetting.java` | `entities/company-setting.md` |
| RowStatus | batch entry enum | `concepts/batch-row-status.md` |
| AppColors | `project_pos/lib/core/theme/app_colors.dart` | `concepts/app-colors-palette.md` |
| StateNotifier | Riverpod legacy → AsyncNotifier | `concepts/state-notifier-vs-async.md` |

## Drift Özeti (Bu Snapshot Anında)

| Drift Türü | Sayım | Eylem |
|---|---|---|
| Eksik entity sayfası | 13 (üstte) | Bu turda stub açıldı, sonraki ingest detaylandırır |
| Yetim sayfa | 18 (`-from-claude-wiki`) | MERGE_NEEDED — manuel diff bekliyor |
| Kırık wikilink | 22 (16 ad değişimi + 6 eksik hedef) | sed batch + 6 yeni sayfa kararı |
| Zayıf kaynak | 81 dosya (≤1 source) | Sonraki kod ingest turunda detay |
| Çelişki | 0 | — |
| Eskimiş | 0 | — |

## Wiki'de Hâlâ Boş Bölgeler (Sonraki Ingest Önerisi)

1. **React (template/) modülü** — 525 dosya, wiki sadece CLAUDE.md kopyası. UI bileşenleri, state management (Redux/?), API client kapsanmamış.
2. **Pos-product-manager controller'ları (~50 dosya)** — sadece flow düzeyinde anlatılıyor, controller-bazlı endpoint kataloğu yok.
3. **Core kütüphanesi** — `TOpenDbEntity`, `BaseDbServiceImp`, `TOpenSimpleCompanyEntity`, `@FilterDef` filterCompany — concept sayfaları parçalı.
4. **i18n bundle altyapısı** — `bnd-XX###-...` ID şeması, `message_definitions` tablosu, `MenuService.getTranslations()` (React) ↔ `i18nOf(ref)` (Flutter) — concept sayfası yok.
5. **Hibernate Filter mekanizması** — `@Filter("filterCompany")` ↔ `CompanyContext.get()` ThreadLocal akışı, multi-tenant runtime davranışı detayı eksik.

## Faz Planı (Önerilen Sıra)

1. **Faz 1 — Bu tur (kısmi otomatik)**: ✅ tamamlandı.
   - Vehicle-plate ADR
   - 13 eksik kavram stub (paralel agent)
   - Code-base snapshot bu sayfa
   - Index/log update

2. **Faz 2 — Mid term (insan + agent)**:
   - 18 MERGE_NEEDED dosya manuel diff (lint-report §1)
   - 16 wikilink ad değişimi sed batch (lint-report §7)
   - 6 eksik hedef için karar (yarat / sil / yeniden yönlendir)

3. **Faz 3 — Long term (yoğun ingest)**:
   - React modül kapsama (~525 dosya)
   - Controller-bazlı endpoint kataloğu (~50)
   - Core kütüphane derinleşme

## Sources

- Bu snapshot: kod taraması (2026-04-25) — git log + Glob + Grep
- Lint kapsamlı tarama: [[lint-report]]
- Migration log: [[log]] (2026-04-25 girdileri)
- Vehicle-plate detay: [`project_pos/.../accounts/_wiki/syntheses/payment-recording-and-vehicle-tracking.md`](../../project_pos/lib/features/accounts/screens/_wiki/syntheses/payment-recording-and-vehicle-tracking.md)

## Related

- [[lint-report]]
- [[decisions/2026-04-24-vehicle-plate-tracking-option-a]]
- [[syntheses/pos-module-map]]
- [[syntheses/sector-agnostic-architecture]]
- [[syntheses/integration-catalog]]
