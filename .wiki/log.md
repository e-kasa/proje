---
title: Wiki Olay Kaydı (Event Log)
type: log
format: append-only
last-verified: 2026-04-25
---

# Wiki Olay Kaydı

Append-only olay kaydı. **En yeni üste**.

## Olaylar

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
