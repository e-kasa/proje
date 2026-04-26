---
title: CLAUDE.md — Accounts Screens Wiki
type: source
source: project_pos/lib/features/accounts/screens/_wiki/CLAUDE.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: claude-md
note: Bu Claude Code auto-load dosyasının arşiv kopyasıdır. Orijinal yerinde 1-satır stub vardır.
---

# CLAUDE.md — Accounts Screens Wiki

Bu wiki, Flutter `features/accounts/` modülünün kalıcı bilgi arşividir. Ekran / widget / provider / service bileşenlerinin, akışların ve verilen kararların descriptive dokümantasyonudur.

## Amaç
Cari Hesaplar (AccountsHub) feature'ı için ajanın session-to-session hafızası. Bir dosya / ekran / akışın **ne iş yaptığı**, **hangi verilere dayandığı**, **hangi bug'ların geçmişte çıktığı** sorularına cevap.

## Dil
Tüm sayfalar **Türkçe** (teknik terimler İngilizce: provider, widget, route, state).

## Naming
kebab-case. Örnek: `accounts-hub-screen.md`, `statement-detail-panel.md`.

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

H1 başlık → İçerik → `## Sources` → `## Related`.

## Operasyon Workflow'ları

### Ingest
Kullanıcı bir `.dart` dosyasını işaret ettiğinde:
1. Dosyayı oku, ana konuyu çıkar
2. `sources/screens/YYYY-MM-DD-<slug>.md` yaz
3. Bahsedilen her ekran/widget/provider için `entities/` altında sayfa
4. Her mimari karar için `decisions/`
5. Her bug/öğrenilen ders için `issues/`
6. Her soyut kavram için `concepts/`
7. `log.md` + `index.md` güncelle

### Query
`index.md`'den başla, ilgili sayfaları oku, kaynak referanslı cevap ver. Analiz/sentez ise `syntheses/`'e geri-dosyala.

### Lint
Periyodik — `lint-report.md`'ye çelişki/orphan/eksik cross-ref rapor et.

## Hard Rules

- **`raw/` immutable** — asla değiştirme. Sadece path pointer dosyaları.
- **Kaynaksız iddia yasak** — her cümle path veya wiki sayfası referansı almalı.
- **Silme yasak** — eskimiş sayfa `archive/`'a taşınır.
- **Çelişki işareti** — sayfa içinde `## ÇELİŞKİ` başlığı.

## Dizin Yapısı

```
_wiki/
├── CLAUDE.md                # bu dosya
├── index.md                 # MOC
├── log.md                   # append-only event log
├── lint-report.md           # sağlık taraması (periyodik)
├── raw/screens/             # Flutter kod pointer'ları (immutable)
├── raw/docs/                # doküman pointer'ları
├── sources/screens/         # her kaynak için özet
├── entities/                # ekran/widget/provider/service sayfaları
├── concepts/                # soyut kavramlar
├── decisions/               # atomik kararlar (UI/UX/state)
├── issues/                  # düzeltilen sorunlar + açık maddeler
├── syntheses/               # üst düzey özet
└── archive/                 # eskimiş sayfalar
```

## Üst Wiki ile İlişki

SEDCORE projesinde `.claude/wiki/` backend + domain modelleri için ana wiki'dir. Bu `_wiki/` **scoped** — sadece Flutter accounts feature'ı. Üst wiki'deki ilgili sayfalara cross-link verilir:
- `.claude/wiki/flows/accounts-hub-load.md` (backend zinciri)
- `.claude/wiki/entities/customer-account.md` (domain model)
- `.claude/wiki/syntheses/accounts-overview.md` (uçtan uca)
