---
title: CLAUDE.md — SEDCORE Wiki
type: source
source: .claude/wiki/CLAUDE.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: claude-md
note: Bu Claude Code auto-load dosyasının arşiv kopyasıdır. Orijinal yerinde 1-satır stub vardır.
---

# CLAUDE.md — SEDCORE Wiki

Bu dizin **descriptive bilgi arşividir** — kural değil, açıklama. Ajan bağlamı: [`README.md`](README.md).

## Dil
Tüm sayfalar **Türkçe**. Teknik terimler İngilizce kalabilir (multi-tenant, @Filter, @Version).

## Naming
kebab-case. Örnek: `customer-account.md`, `drift-reconciliation.md`.

## Sayfa Formatı

```yaml
---
title: Sayfa Başlığı
tags: [entity|flow|pattern|integration|concept|decision|issue|source|synthesis]
source: path/to/raw/source
date: YYYY-MM-DD
status: stub | draft | verified | archived
---
```

H1 başlık + içerik + `## Sources` + `## Related`.

## Operasyon Workflow'ları

Slash command'lar ile: `.claude/commands/`
- `/wiki-ingest <kaynak>` — yeni kaynak entegre et
- `/wiki-query <soru>` — soru sor, sentez geri-dosyala
- `/wiki-lint [gün]` — sağlık taraması

## Hard Rules

- **`raw/` immutable** — asla değiştirme, sadece oku. Yeni kaynaklar pointer/symlink olarak eklenir.
- **Kaynaksız iddia yasak** — her cümle için kaynak path veya wiki sayfası referansı.
- **Silme yasak** — eskimiş sayfa `archive/`'a taşınır.
- **Çelişkiler işaretlenir** — sayfa içinde `## ÇELİŞKİ` başlığı + `contradictions.md`'ye girdi.
- **Katman ihlali yok** — kural `reference/`'a, karar `.wiki/decisions/`'a, tarif `runbooks/`'a gider.

## Katman Farkı

| Katman | İçerik |
|---|---|
| `.claude/reference/` | Kural (prescriptive) — "companyCode JWT'den gelir" |
| `.wiki/decisions/` | ADR (stratejik, tarihli) — "DDL=create seçildi" |
| `.claude/runbooks/` | Tarif (how-to) — "Yeni endpoint eklerken..." |
| `wiki/decisions/` | Taktik karar (kod seviyesi) — "Bu sayfada @EntityGraph kullanıldı" |
| `wiki/` (diğer) | Açıklama (descriptive) — "Customer nasıl çalışır" |

## İki Katmanlı Wiki

- **Ana wiki** = `.claude/wiki/` (bu dizin) — proje-genel bilgi
- **Scoped wiki** = `<feature>/<subpath>/_wiki/` — feature-spesifik derinlik
- Scoped açma kriterleri, cross-link stili, path konvansiyonu: bkz. [`README.md`](README.md) "İki Katmanlı Wiki Hiyerarşisi" + [[concepts/pattern-scoped-feature-wiki]]
- Bilgi akışı: yukarı tek yönlü (scoped `.claude/wiki/<path>` referans verir; ana MOC scoped'u bilmez)
- İki wiki arası çelişki → ana wiki `contradictions.md`

## Dizin Yapısı

```
wiki/
├── CLAUDE.md               # bu dosya
├── README.md               # detaylı protokol (ajan için)
├── index.md                # MOC
├── log.md                  # append-only event log
├── glossary.md             # terim sözlüğü
├── contradictions.md       # çelişki kayıtları
├── raw/code-refs/          # kod kaynak pointer'ları (immutable)
├── raw/docs/               # doküman pointer'ları (immutable)
├── sources/code-refs/      # her kaynak için özet sayfası
├── entities/               # domain modelleri
├── concepts/               # soyut kavramlar
├── flows/                  # uçtan uca akışlar
├── patterns/               # mimari desenler
├── integrations/           # dış servis davranışları
├── decisions/              # taktik kararlar (kod seviyesi)
├── issues/                 # düzeltilen sorunlar (kök neden + fix)
├── syntheses/              # üst düzey özet sayfaları
└── archive/                # eskimiş sayfalar (silinmez)
```
