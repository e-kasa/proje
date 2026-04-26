---
title: Pattern — Scoped Feature Wiki (İki-Katmanlı Wiki Hiyerarşisi)
type: concept
source: .claude/wiki/patterns/scoped-feature-wiki.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Scoped Feature Wiki

## Problem
Tek wiki her şeyi kapsamaya çalışırsa ya bilgi seyreldir (feature derinliği kaybolur) ya da ana wiki şişer. SEDCORE büyüyen modüler proje; monolitik wiki uzun vadede yönetilemez.

## Çözüm
**İki katmanlı wiki** — yatay ölçeklenen feature-scoped wiki'ler + merkezi ana wiki.

### Katmanlar

| Katman | Konum | Kapsam | Hedef Kitle |
|---|---|---|---|
| **Ana wiki** | `.claude/wiki/` (legacy) → `.wiki/` (yeni) | Domain modelleri, mimari pattern'lar, cross-cutting kararlar | Proje geneli |
| **Scoped wiki** | `<feature>/<subpath>/_wiki/` | Tek feature'ın UI/widget/provider derinliği, feature-spesifik UX kararları | Feature sahibi |

### SEDCORE'da Mevcut Uygulama

- `project_pos/lib/features/accounts/screens/_wiki/` — accounts UI feature'ı (2026-04-24 kuruldu)
- Gelecek: `project_pos/lib/features/inventory/screens/batch_entry/_wiki/` (plan)
- Gelecek: `project_pos/lib/features/pos/_wiki/` (plan)

## Scoped `_wiki/` Açma Kriterleri

**Üçü birden sağlanmalı**:

1. **Dosya kütlesi**: feature'da **≥5 kaynak dosyası**
2. **Scope disiplini**: UI/state kararları feature-spesifik — ana wiki'ye çıkmaz
3. **Yatay/dikey ayrımı**: Backend domain ana wiki'de, frontend derinlik scoped'da

## Path Konvansiyonu

- **Scoped root**: `<feature>/<subpath>/_wiki/`
- **Neden `_wiki/` underscore prefix?**
  - Dart analyzer meta klasörü göz ardı eder
  - VS Code / IntelliJ dosya ağacında gruplar
  - Git tracked kalır, ama kod tarama araçları skip edebilir
- **Alt dizinler** ana wiki ile aynı taksonomi: `entities/`, `flows/`, `patterns/`, `concepts/`, `decisions/`, `issues/`, `syntheses/`, `archive/` + `raw/` + `sources/`
- **Dosya isimleri**: kebab-case (`accounts-hub-screen.md`)

## Cross-Link Stili

### Scoped → Ana (yukarı akış)

**Yöntem**: göreli markdown link veya backtick path, **wikilink değil**.

```markdown
Backend tarafı: `.wiki/entities/customer-account.md`
```

### Ana → Scoped (aşağı akış — nadir)

**Yöntem**: sadece `syntheses/` veya `issues/` sayfalarından **opsiyonel referans**.

### Çelişki → Ana Wiki

İki wiki arası bilgi uyumsuzluğu → ana `contradictions.md` **tek kayıt yeri**.

## Trade-off

- Feature derinliği ana wiki'yi şişirmez
- Feature sahibi kendi scoped'ını hızlı günceller
- Cross-wiki çelişki tespiti manuel
- Obsidian wikilink ana↔scoped çalışmaz — path syntax karışıklığı
- Yeni developer hangi katmanda arayacağını bilmeli → CLAUDE.md rehberliği kritik

## Ne Zaman Scoped Kapatılır / Merge Edilir

- Feature ölürse → `archive/`
- Feature 2-3 dosyaya düşerse (≥5 kriteri kaybolursa) → içerik ana wiki'ye merge

## Sources

- Konuşma bağlamı 2026-04-24 (plan `agile-noodling-crown.md` W1 bölümü)
- `project_pos/lib/features/accounts/screens/_wiki/` — ilk uygulama (2026-04-24 kuruldu)

## Related

- [[concepts/pattern-denormalization-with-reconcile]]
