---
title: Wiki Olay Kaydı (Event Log)
type: log
format: append-only
last-verified: 2026-04-25
---

# Wiki Olay Kaydı

Append-only olay kaydı. **En yeni üste**.

## Olaylar

## [2026-04-26] sprint-7 | WP2 minimum — test infrastructure + ilk test ✅

WP2'nin minimum scope'u uygulandı. `Tests run: 3, Failures: 0, Errors: 0 — BUILD SUCCESS`.

**Yeni dosyalar:**
- `pos-product-manager/pom.xml` — H2 (test scope) eklendi
- `src/test/resources/application-test.properties` — H2 in-memory PostgreSQL mode, ddl-auto=create-drop, sql.init.mode=never
- `src/test/java/com/sedcore/finance/repository/PaymentAllocationRepositoryTest.java` — 3 test (`@DataJpaTest`):
  - `save_withSaleFk_persists` — allocation insert (sale=null)
  - `findByPaymentId_returnsAllocations` — multi-allocation query (B3 senaryosu)
  - `sumActiveBySaleId_excludesCancelled` — cancelled payment'lar hariç toplam

**Mimari kararlar:**
- H2 with PostgreSQL mode seçildi (Testcontainers + Docker daemon kompleksitesinden kaçındık)
- `@DataJpaTest` ile sadece JPA katmanı (full Spring context yok, hızlı)
- `ID elle set edilmez` — TOpenSimpleCompanyEntity @PrePersist ile UUID üretir (lesson learned)
- data.sql test'te koşmaz (`sql.init.mode=never`) — her test temiz state

**Sonraki sprintte (WP2.4):**
- T1 full PaymentCreationIntegrationTest (@SpringBootTest service-level)
- T2 ReconcileDriftDetectionTest
- T3 CreditLimitGuardTest
- T4 SalePaymentFkIntegrityTest

Sprint 7 done kriteri büyük ölçüde sağlandı; hold-over: smoke test (kullanıcı runtime) + ErrorBoundary 3 panel entegrasyon (Sprint 8).

**Kaynak:** kullanıcı talebi — "plana göre doğru yoldan devam".

## [2026-04-25] sprint-7 | WP1+WP3+WP4+WP5 implementasyon (testler ertelendi)

Sprint 7 başlatıldı. Plan: [[syntheses/sprint-7-implementation-plan-2026-04-25]]. Tamamlanan iş paketleri:

**Backend (WP1):**
- Yeni: `PaymentAllocation.java` entity (sale-payment many-to-many, `@Version`, indexes)
- Yeni: `PaymentAllocationRepository.java` (`findByPaymentId/SaleId`, `sumActiveBySaleId`)
- Yeni: `AllocationRequest.java` (DTO)
- Update: `PaymentRequest.java` — `allocations: List<AllocationRequest>` field, `saleId` `@Deprecated`
- Update: `PaymentServiceImpl.java` — `createAllocations()` helper + `createCustomerPayment()` çağrısı
- ✅ Maven compile geçti (exit 0)

**Frontend (WP3+WP4+WP4.b):**
- Yeni: `customer_open_sales_provider.dart` (FutureProvider.family + autoDispose)
- Update: `sales_service.dart` — `getCustomerOpenSales(String customerId)` ek metod
- Update: `payment_record_modal.dart` — `customerId` parametresi, "Hangi Alışverişe?" radio + açık satış picker, submit `allocations` array
- Update: `statement_detail_panel.dart` — caller `customerId` aktarımı + payload `allocations` field
- Yeni: `accounts_error_view.dart` (I2 minimum widget — yaygın entegrasyon Sprint 8'e)

**i18n (WP5):**
- 7 yeni anahtar `accounts.payment_target/general_payment/specific_sale_payment/no_open_sales/sale_remaining/add_another_sale/allocation_sum_mismatch` (TR + EN)
- ID şeması: `bnd-acpa01-07`

**Wiki (WP6):**
- Yeni: [[entities/payment-allocation]]
- Yeni: [[concepts/payment-allocation-pattern]]
- Yeni: [[decisions/payment-allocation-from-day-1]] (B1↔B3 mimari karar ADR)
- Index güncellendi (Sprint 7 Decisions, Cari Hesap concepts, Domain Diğer entities)

**Ertelendi (Sprint sonu):**
- WP2 testler T1-T4 (proje sıfır test infrastructure → ayrı kurulum gerekli)
- WP6 manuel smoke test (kullanıcı runtime ile yapacak)
- I2 ErrorBoundary yaygın entegrasyon (3 panel) — Sprint 8

**Geriye uyum:** `Payment.sale` FK + `PaymentRequest.saleId` `@Deprecated` ama kabul ediliyor. Sprint 9'da kaldırılacak.

**Kaynak:** kullanıcı talebi — "cari işlemler planına devam et" + "B devam, testler sprint sonunda".

## [2026-04-25] query | cari işlemler planına devam — Sprint 7 implementation plan

Kullanıcı talebi: "cari işlemler planına devam et". Geri-dosyalama: [[syntheses/sprint-7-implementation-plan-2026-04-25]] — v2 analizinin Sprint 7'sini 6 iş paketi (WP1-WP6) olarak adım adım uygulama planı.

**WP listesi:**
- WP1 (1g): Backend PaymentAllocation entity many-to-many baştan
- WP2 (1.6g): Backend T1-T4 kritik path testleri (paralel WP1 ile)
- WP3 (0.5g): Frontend service + customerOpenSalesProvider
- WP4 (1g): Frontend PaymentRecordModal sale picker
- WP5 (1.5g): Frontend i18n (7 key) + ErrorBoundary (I2)
- WP6 (0.5g): Wiki final + smoke test

**Net iş:** ~6 gün, 1 hafta sprint. Her WP için: dosya yolu, done kriteri, risk matrisi.

**Sonraki adım:** kullanıcı onayı ile WP1 (backend) implementasyonu başlatılacak.

Index güncellendi: Modül & Mimari Özet altına sprint plan linki.

## [2026-04-25] query | cari hesaplar modülü geliştirme analizi

Kullanıcı talebi: "Cari hesaplar sayfasına odaklanıp geliştirme analizi çıkar." Geri-dosyalama: [[syntheses/accounts-development-analysis-2026-04-25]].

**Kapsam:** 50+ accounts wiki sayfası (entities, syntheses, decisions, concepts, issues + scoped `project_pos/.../accounts/_wiki/`) sentezlendi. Backend kod doğrulaması yapıldı (Payment.saleId FK, SaleController endpoint).

**Bulgular:**
- 5 açık issue (pagination, error boundary, overdue notification, activity history, test coverage)
- 7 yeni geliştirme adayı (alışveriş bazlı ödeme, plaka B/C, toplu ödeme, taksit, hızlı tahsilat, yaşlandırma raporu, SMS bildirim)
- P1-P3 önceliklendirme + 3 sprint roadmap önerisi

**Sprint 7 önerisi:** B1 (alışveriş bazlı ödeme — backend hazır) + I2 (error boundary) + I1 (pagination).

Index güncellendi: Modül & Mimari Özet altına development analysis linki.

## [2026-04-25] query | LINT sonucu yapılması gereken aksiyon planı

Kullanıcı talebi: 134 lint bulgusu için somut aksiyon planı. Geri-dosyalama: [[syntheses/lint-action-plan-2026-04-25]] (P1-P4 öncelikli, sed komutları + manuel sıra + tahmini efor + kabul kriterleri).

**Plan özeti:**
- **P1 (1 saat)** — Hızlı kazanç: 16 sed batch + 6 eksik hedef kararı + 8 placeholder fix
- **P2 (3-5 saat)** — Orta: 18 MERGE_NEEDED inceleme + 5 issues merge + 50 xref ekleme + 5 zayıf kaynak doğrulama
- **P3 (1 saat)** — Lint Pass 3 koşturma + archive doldurma
- **P4 (sprint backlog)** — React/controller/core ingest

**Hedef sağlık skoru:** Y:0, O:<20, D:<30 (mevcut Y:23 O:130 D:~76).

Index güncellendi: Modül & Mimari Özet altına aksiyon planı linki.

## [2026-04-25] query | tüm kod dosyalarından wiki güncelleme (faz 1 — pragmatic)

Kullanıcı talebi: "proje altındaki bütün kod dosyalarını oku, wiki belleğini bu mevcut kod üzerinden güncelle." Pragmatic kapsam (1362 kod dosyası tek turda imkansız): **lint-report'taki 13 eksik kavram için kod kanıtı + son 15 commit deltası**.

### Yeni dosyalar (15)

**Decisions (1):**
- `decisions/2026-04-24-vehicle-plate-tracking-option-a.md` — Sprint 6b ADR (description prepend, schema değişikliği yok). Scoped wiki'deki sentezi ana wiki'ye yansıt.

**Syntheses (1):**
- `syntheses/codebase-snapshot-2026-04-25.md` — kod ↔ wiki uyum analizi, son 15 commit drift, 1362 dosya envanter, faz planı.

**Entities (7) — eksik kavramlar için kod-bazlı stub:**
- `entities/user-def.md` (core/.../security/UserDef.java)
- `entities/user-def-access.md` (core/.../security/UserDefAccess.java)
- `entities/product-variant.md` (pos-product-manager/.../product/entity/ProductVariant.java)
- `entities/accounts-hub-screen.md` (project_pos/.../accounts/screens/accounts_hub_screen.dart)
- `entities/document-item-result.md` (pos-product-manager/.../product/model/DocumentItemResult.java)
- `entities/batch-entry-row.md` (project_pos/.../batch_entry/models/batch_entry_models.dart:251)
- `entities/company-setting.md` (pos-product-manager/.../company/entity/CompanySetting.java)

**Concepts (6) — eksik kavramlar için kod-bazlı stub:**
- `concepts/company-context.md` (pos-product-manager/.../common/context/CompanyContext.java)
- `concepts/pre-authorize-guard.md` (Spring Security pattern, 1 kullanım)
- `concepts/batch-entry-state.md` (project_pos/.../batch_entry/models/batch_entry_models.dart:473)
- `concepts/batch-row-status.md` (batch_entry_models.dart:1 enum)
- `concepts/app-colors-palette.md` (project_pos/lib/core/theme/app_colors.dart)
- `concepts/state-notifier-vs-async.md` (Riverpod migration özeti, henüz başlamadı)

### Index güncellendi (5 alt-bölüm)

- Decisions → Sprint 6b alt-bölümü
- Syntheses → Modül & Mimari Özet altına codebase-snapshot
- Entities → Security Domain (yeni alt-bölüm), Ürün satırı, Firma satırı, Flutter Screens & Models (yeni alt-bölüm)
- Concepts → Mimari satırına 2 yeni link, Flutter / Frontend (yeni alt-bölüm) — 4 yeni link

### Faz Dışı (sonraki turlara)

- React (template/) modülü — 525 dosya, sadece CLAUDE.md kopyası kapsamlı değil
- pos-product-manager controller-bazlı endpoint kataloğu — ~50 dosya
- core kütüphane derinleşme (TOpenSimpleCompanyEntity, BaseDbServiceImp, @FilterDef)
- 18 MERGE_NEEDED dosya manuel diff (lint borçları)

**Kaynak:** kullanıcı talebi (auto + plan mode geçişleri)

## [2026-04-25] lint | 134 bulgu (Y:23 O:130 D:~76) — tam pass 2

`raw/` hariç **188 dosya** üzerinde 6 kategorili tam sağlık kontrolü. Mekanik (Bash) + sample diff (manuel). Otomatik düzeltme yapılmadı; rapor: [[lint-report]].

**Sayım:**
- 🔴 Çelişki (gerçek): **0** (3 sample diff yapıldı — hepsi DUPLICATE/zenginleştirme)
- 🟠 Çelişki adayı (MERGE_NEEDED): 21 (18 `-from-claude-wiki` + 3 ADR↔sentez)
- ✅ Eskimiş: 0 (tümü ≤12 gün)
- 🟠 Yetim: 18 (hepsi `-from-claude-wiki` — MERGE_NEEDED ile örtüşür)
- 🔴 Kırık wikilink (gerçek): 22 (16 ad değişimi + 6 eksik hedef)
- 🟠 Eksik kavram (≥10 bahis, sayfa yok, generic terim filtreli): 13 (`UserDef`, `UserDefAccess`, `ProductVariant`, `CompanyContext`, `AccountsHub`, `BatchEntryRow`, vb.)
- 🟡 Tek-yönlü xref: 773 ham → ~50 öncelikli (concept↔entity karşılıklı eksiklik)
- 🟠 Zayıf kaynak (≤1 source): 81 (parser sınırlı; manuel doğrulama önerildi)

**En kritik 3:** (1) 16 ad-değişen kırık wikilink — sed ile 10 dk; (2) 18 MERGE_NEEDED yetim — manuel diff 2-3 saat; (3) 13 eksik domain kavram — UserDef/ProductVariant gibi core entity sayfaları yok.

**Kaynak:** kullanıcı /lint-pass talebi.

## [2026-04-25] migration | Proje geneli .md konsolidasyonu → .wiki/

Kullanıcı talebi: "proje altındaki tüm `.md` dosyalarını `.wiki/`'ye entegre et + orijinallerini sil/stub bırak". Plan: `C:\Users\Win11\.claude\plans\polymorphic-gathering-flute.md`. AskUserQuestion ile 4 karar netleştirildi (CLAUDE.md hard-delete vs stub çelişkisinde safety nedeniyle B yorumu / stub uygulandı).

**Kapsam dışı (dokunulmadı):** `template/node_modules/**` (1500+ npm artifact), `**/target/**`, `.git/**`, `.claude/worktrees/**`, `project_pos/ios/.../LaunchImage README`, `core/.github/...progress.md`, `.wiki/**` (hedef vault).

**6 paralel agent + manuel:** ~117 dosya işlendi.

| Grup | Kapsam | Dosya | Sonuç |
|---|---|---|---|
| Agent A | `.claude/{decisions,runbooks,reference,status,plans,guides,inventory,commands,INDEX}/` + 3 root scratch | 25 | Hepsi taşındı + stub. `multi-tenant.md` çakıştığı için `multi-tenant-routing.md` adıyla yazıldı. |
| Agent B1 | `.claude/wiki/entities/*` | 18 | Hepsi DUPLICATE (önceki ingest'te wiki'de mevcuttu) → stub. README ayrı kaydedildi. |
| Agent B2 | `.claude/wiki/{decisions,concepts,patterns,syntheses,integrations}/*` | 27 | 23 DUPLICATE, 1 NEW (`use-entity-graph-for-customer-account-fetch`), 3 README silindi. |
| Agent B3 | `.claude/wiki/{flows,issues,archive,raw,sources,glossary,contradictions,index,log,lint-report}/*` | 32 | 5 issues `-from-claude-wiki` suffix'i ile MERGE_NEEDED, geri kalan stub. 5 NEW yazım. |
| Agent C | Module README + `pos-product-manager/ERROR_HANDLING_GUIDE.md` | 3 | Hepsi NEW. |
| Agent E | 10 CLAUDE.md (root + 7 modül + 2 alt + `.claude/wiki/CLAUDE.md`) | 10 | Hepsi `.wiki/sources/claude-md/` altına; ~37 link replace (`.claude/reference/...` → `.wiki/concepts/...` vb.); orijinaller 1-satır pointer stub. |
| Manuel | 2 patterns (`optimistic-lock-version`, `scoped-feature-wiki`) | 2 | DUPLICATE → stub. |

**MERGE_NEEDED (manuel inceleme bekleniyor):** `-from-claude-wiki` suffix'li 5 issues + bazı concepts. Mevcut wiki sayfasıyla kaynak içerik farklılığı tespit edildi.

**Yeni dizin:** `.wiki/sources/status-snapshots/`, `.wiki/sources/claude-md/`.

**Index güncellendi:** Yeni 4 bölüm (CLAUDE.md Arşivi, Status Snapshots, Code-refs migration alt-bölümü, Patterns alt-bölümü). 50+ yeni MOC link.

**Stub formatı:** `> Bu içerik [.wiki/...](göreceli-link) altına taşındı (2026-04-25).` Auto-load mekanizması stub'ı okur, link üzerinden devam eder.

**Etkilenen yollar:** `.claude/{decisions,runbooks,reference,status,plans,guides,inventory,commands,wiki}/`, root CLAUDE.md ve 7 modül CLAUDE.md, 3 root scratch, 3 module README/GUIDE.

**Kaynak:** kullanıcı talebi (auto mode + AskUserQuestion onayı).

## [2026-04-25] full-setup | İlk kapsamlı kurulum + 7 kaynak ingest + 4 sentez + lint
- **PHASE 1 (Setup)**: 9 alt klasör + 9 .gitkeep + CLAUDE.md (217 satır) + index.md + log.md zaten kuruluydu (önceki turlardan)
- **PHASE 2 (Kaynak seçimi)**: Proje genelinde 7 öncelikli kaynak seçildi (CLAUDE.md kök, accounts-hub gap, sale-checkout, purchase-checkout, drift-reconciliation, openapi-codegen, ledger-adr). Symlink (ln -s) Windows Git Bash'te kopyalama davranışı yaptığı için pointer-markdown fallback'a geçildi → `raw/code-refs/2026-04-25-*.md` (7 dosya)
- **PHASE 3 (Ingest)**: Her kaynak için sources/code-refs/2026-04-25-<slug>.md (7 source summary). Bahsedilen 22 entity, 15 concept, 18 decision, 12 issue açıldı. Toplam 74 yeni içerik sayfası.
- **PHASE 4 (Sentez)**: 4 yüksek seviyeli sentez yazıldı:
  - `syntheses/pos-module-map` — servis + client haritası
  - `syntheses/sector-agnostic-architecture` — çoklu sektör mimarisi
  - `syntheses/accounts-module-overview` — cari hesap modülü
  - `syntheses/integration-catalog` — entegrasyon kataloğu
- **PHASE 5 (Lint)**: lint-report.md yazıldı — 0 yüksek/orta, 14 düşük (stub sayfalar). Çelişki yok, yetim yok, eskimiş yok.
- **PHASE 6 (Index/Log sync)**: index.md tüm kategorilerle güncel, log.md bu girdi.
- Toplam: 88 markdown dosyası (CLAUDE.md + index + log + lint-report + 84 içerik) ; 355+ wikilink cross-ref.
- Kaynak: kullanıcı talebi — tam otomatik tek-pass setup + ingest

## [2026-04-25] setup | Wiki iskeleti yeniden kuruldu (overwrite)
- Dokunulan dosyalar: `.wiki/CLAUDE.md`, `.wiki/index.md`, `.wiki/log.md`
- Kaynak: kullanıcı talebi — aynı scaffold prompt'u 2. kez; seçim: "Tam yeniden kur (overwrite)"
- Not: 9 alt klasör + 9 `.gitkeep` idempotent korundu; `raw/` hâlâ 0 kaynak. Placeholder yorumları sabit: `{{KAYNAK_KLASORU}}=code-refs`, `{{SORUN_KLASORU}}=issues`, `{{PROJE_ADI}}=SEDCORE POS`, `{{DIL}}=Türkçe`.

## [2026-04-24] setup | Wiki iskeleti kuruldu (ilk tur)
- Dokunulan dosyalar: `.wiki/CLAUDE.md`, `.wiki/index.md`, `.wiki/log.md`, 9 alt-klasör + `.gitkeep`
- Kaynak: kullanıcı talebi — `.wiki` yeni bağımsız vault, SEDCORE POS için sektör-agnostik kalıcı bilgi arşivi
- Not: İlk ingest manuel tetiklenecek. `raw/code-refs/` ve `raw/docs/` boş.
