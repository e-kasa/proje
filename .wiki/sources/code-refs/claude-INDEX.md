---
title: SEDCORE POS — CLAUDE Dokümantasyon İndeksi
type: source
source: .claude/INDEX.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# SEDCORE POS — CLAUDE Dokümantasyon İndeksi

Bu dosya, **hangi göreve başlarken hangi dokümanı okumak gerektiğini** gösterir.  
Kök `CLAUDE.md` kısa tutulmuştur — detaylar buraya taşındı.

---

## Görev Bazlı Navigasyon

| Görev | Önce Oku | Ayrıca |
|-------|----------|--------|
| Yeni backend endpoint eklemek | `runbooks/new-endpoint.md` | `reference/url-routing.md`, `reference/api-response.md` |
| Yeni entity + tablo eklemek | `runbooks/new-entity.md` | `reference/multi-tenant.md`, `core/CLAUDE.md` |
| Yeni Flutter feature eklemek | `runbooks/new-feature-flutter.md` | `project_pos/CLAUDE.md` |
| JWT / auth sorunu | `reference/jwt-payload.md` | `security/CLAUDE.md` |
| Tenant sızıntısı / multi-tenant debug | `reference/multi-tenant.md` | `runbooks/debug-tenant-leak.md` |
| API response zarf standardı | `reference/api-response.md` | — |
| URL / prefix / route | `reference/url-routing.md` | `api-manager/CLAUDE.md` |
| Sektör (autoParts/footwear) | `reference/sector-strings.md` | — |
| Batch (toplu) ürün girişi | `project_pos/lib/features/inventory/screens/batch_entry/CLAUDE.md` | `pos-product-manager/CLAUDE.md` §6a |
| PDF fatura analizi | `pos-product-manager/CLAUDE.md` §12 | batch_entry CLAUDE.md §14 |
| Mimari karar arşivi | `decisions/` | — |
| Aktif sprint / roadmap | `status/sprint.md` | — |

---

## Referans Dosyaları — Tek Kaynak (Single Source of Truth)

Aşağıdaki konular **sadece** `reference/` altında tutulur. Modül CLAUDE.md'leri buraya link verir, **tekrar yazmaz**.

- `reference/jwt-payload.md` — JWT token yapısı, sessionInstance parse
- `reference/url-routing.md` — Gateway prefix kuralı, controller path vs Flutter URL
- `reference/multi-tenant.md` — companyCode akışı, Hibernate @Filter, CompanyContext
- `reference/api-response.md` — `{success, data, message}` zarfı standardı
- `reference/sector-strings.md` — SectorType.apiValue standart değerleri

---

## Runbook'lar — Adım Adım İş Akışı

Tekrarlayan işler için hazır tarifler. Her runbook **kopyala-yapıştır-düzenle** şeklinde kullanılır.

- `runbooks/new-endpoint.md`
- `runbooks/new-entity.md`
- `runbooks/new-feature-flutter.md`
- `runbooks/debug-tenant-leak.md`

---

## Modül CLAUDE.md'leri

Her modül kendi CLAUDE.md'sinde **yalnızca o modüle özgü** kuralları tutar:

| Modül | Ana Odak |
|-------|----------|
| `api-manager/` | Gateway, JWT filter, CORS |
| `core/` | Shared entity base, filter superclass |
| `security/` | Auth, user mgmt, i18n seed |
| `pos-product-manager/` | Ürün, stok, satış, PDF |
| `project_pos/` | Flutter feature-first |
| `template/` | React admin panel |

---

## Kararlar (ADR)

Mimari kararlar `decisions/` altında tarihli dosyalarda tutulur — kök CLAUDE.md'yi şişirmesin.

- `decisions/2026-04-13-ddl-create-strategy.md`
- `decisions/2026-04-13-store-admin-rename.md`
- `decisions/2026-04-13-location-id-unification.md`

---

## Durum (Status)

Zamana bağlı bilgi — sprint durumu, yapılacaklar — `status/` altında:

- `status/sprint.md` — Aktif sprint, ilerleme

---

## Wiki (Kümülatif Bilgi Arşivi)

Descriptive bilgi — "X nasıl çalışır, Y hangi servislerle etkileşir" — `wiki/` altında. Kural/karar/tarif değil, açıklama.

- `wiki/README.md` — ajan protokolü, sayfa formatı
- `wiki/index.md` — MOC (map of content)
- `wiki/log.md` — append-only event log
- `wiki/glossary.md` — terim sözlüğü
- `wiki/contradictions.md` — çelişen bilgi kayıtları
- `wiki/entities/` — domain modelleri
- `wiki/flows/` — uçtan uca akışlar
- `wiki/patterns/` — mimari desenler
- `wiki/integrations/` — dış servis davranışları
- `wiki/syntheses/` — üst düzey özet sayfaları
- `wiki/archive/` — eskimiş sayfalar (silinmez, taşınır)

**Slash commands** (`.claude/commands/`):
- `/wiki-ingest <kaynak>` — yeni kod/PR/doc entegrasyonu
- `/wiki-query <soru>` — wiki sorgusu, sentezler geri-dosyalanır
- `/wiki-lint [gün]` — sağlık taraması

Katman farkı: `reference/` = kural, `decisions/` = karar, `runbooks/` = tarif, **`wiki/` = açıklama**.

---

## Dokümantasyon Kuralları

1. **Tekrar yazma** — Bir bilgi iki yerde varsa, biri referansa link versin.
2. **Tarihli notları temizle** — 3 aydan eski "eklendi" notları `decisions/`'a arşivle.
3. **Örnek kod minimize** — 20 satırdan uzun örnek → runbook'a taşı.
4. **Frontmatter** — Her modül CLAUDE.md başında YAML meta olsun (modül, port, bağımlılık).
