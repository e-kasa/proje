---
title: LINT Aksiyon Planı — 2026-04-25 (134 Bulgu Sonrası)
type: synthesis
date: 2026-04-25
status: actionable
based-on: lint-report.md (Pass 2)
total-findings: 134
estimated-effort: 4-7 saat (P1+P2+P3) + uzun vadeli P4 backlog
---

# LINT Aksiyon Planı — 2026-04-25

[[lint-report]] Pass 2 sonucundaki 134 bulguya öncelikli, somut, tahmini efor + kabul kriteri içeren aksiyon planı. Her aksiyon ya **otomatik (sed/script)** ya **manuel kısa (kararlı)** ya **manuel uzun (analiz)** kategorisinde.

## Bulgu Sayım Özeti

| Şiddet | Adet | Tipik Aksiyon |
|---|---|---|
| 🔴 Yüksek | 23 | Otomatik fix + 6 karar |
| 🟠 Orta | 130 | Manuel diff + içerik üretimi |
| 🟡 Düşük | ~76 | Kozmetik / opsiyonel |
| ✅ Çelişki | 0 | — |
| ✅ Eskimiş | 0 | — |

## P1 — Hızlı Kazanç (Toplam: ~1 saat)

### P1.1 — 16 Wikilink Ad Değişimi (sed batch) — **10-15 dk**

Migration sonrası taşınan 3 kategori için tüm `[[X]]` referanslarını yeni adlarına güncelle.

**Replace tablosu:**
```bash
cd .wiki
sed -i 's|\[\[flows/accounts-hub-load\]\]|[[syntheses/flow-accounts-hub-load]]|g' **/*.md
sed -i 's|\[\[flows/batch-entry\]\]|[[syntheses/flow-batch-entry]]|g' **/*.md
sed -i 's|\[\[flows/drift-reconciliation\]\]|[[syntheses/flow-drift-reconciliation]]|g' **/*.md
sed -i 's|\[\[flows/pdf-statement-export\]\]|[[syntheses/flow-pdf-statement-export]]|g' **/*.md
sed -i 's|\[\[flows/purchase-checkout\]\]|[[syntheses/flow-purchase-checkout]]|g' **/*.md
sed -i 's|\[\[flows/sale-checkout\]\]|[[syntheses/flow-sale-checkout]]|g' **/*.md
sed -i 's|\[\[flows/stock-transfer\]\]|[[syntheses/flow-stock-transfer]]|g' **/*.md
sed -i 's|\[\[flows/today-collection-calc\]\]|[[syntheses/flow-today-collection-calc]]|g' **/*.md
sed -i 's|\[\[integrations/prometheus-micrometer\]\]|[[syntheses/integration-prometheus-micrometer]]|g' **/*.md
sed -i 's|\[\[integrations/slack-webhook\]\]|[[syntheses/integration-slack-webhook]]|g' **/*.md
sed -i 's|\[\[patterns/base-entity-list-screen\]\]|[[concepts/pattern-base-entity-list-screen]]|g' **/*.md
sed -i 's|\[\[patterns/denormalization-with-reconcile\]\]|[[concepts/pattern-denormalization-with-reconcile]]|g' **/*.md
sed -i 's|\[\[patterns/dto-tomap-pattern\]\]|[[concepts/pattern-dto-tomap-pattern]]|g' **/*.md
sed -i 's|\[\[patterns/entity-graph-n-plus-one\]\]|[[concepts/pattern-entity-graph-n-plus-one]]|g' **/*.md
sed -i 's|\[\[patterns/openapi-codegen-flutter\]\]|[[concepts/pattern-openapi-codegen-flutter]]|g' **/*.md
sed -i 's|\[\[patterns/optimistic-lock-version\]\]|[[concepts/optimistic-lock-version]]|g' **/*.md
sed -i 's|\[\[patterns/scoped-feature-wiki\]\]|[[concepts/pattern-scoped-feature-wiki]]|g' **/*.md
```

**Kabul kriteri:** Lint Pass 3 koşturulduğunda kırık link sayısı 22'den 6'ya düşer.

**Risk:** Çok düşük — replace tablosu kaynak/hedef map'i lint-report'tan alındı.

---

### P1.2 — 6 Gerçek Eksik Wikilink Hedefi (Karar) — **30 dk**

| Eksik wikilink | Önerilen aksiyon | Karar |
|---|---|---|
| `[[contradictions]]` | `[[sources/code-refs/claude-wiki-contradictions]]`'e replace (taşınan dosya var) | sed batch |
| `[[decisions/append-only-semantics]]` | İçerik [[concepts/append-only]]'da var → silinen 2 referansı `[[concepts/append-only]]`'e yönlendir | sed |
| `[[decisions/base-entity-list-screen-adoption]]` | `[[concepts/pattern-base-entity-list-screen]]`'e yönlendir | sed |
| `[[decisions/defensive-credit-sale-customer-required]]` | İçerik [[decisions/credit-limit-override-role-based]]'in alt başlığı; yönlendir veya yeni 5-satır sayfa | yönlendir |
| `[[README]]` | `[[index]]`'e yönlendir (vault root MOC) | sed |
| `[[archive/README]]` | `archive/` boş — referansı sil veya `archive/README.md` placeholder yarat | placeholder yarat |

**Kabul kriteri:** Lint Pass 3'te 6 eksik hedef → 0.

---

### P1.3 — 8 Placeholder Wikilink Code-Block'a Sar — **10 dk**

Yer tutucu `[[concepts/...]]`, `[[entities/other]]`, `[[flows/x]]`, `[[klasör/sayfa-adi]]`, `[[yeni/sayfa]]`, `[[yeni-konum/sayfa]]`, `[[raw/code-refs/...]]` literal'ları lint'i false-trigger ediyor. Bunlar kod örneği veya şablon olduğu için inline code (`` ` ``) ile sarılmalı.

**Aksiyon:** Her birini içeren dosyayı bul, literal'ı `` ` `` ile sar:
```bash
grep -rl "\[\[concepts/\.\.\.\]\]" .wiki/ | xargs sed -i 's|\[\[concepts/\.\.\.\]\]|`[[concepts/...]]`|g'
# (diğerleri için tekrarla)
```

**Kabul kriteri:** Lint Pass 3'te placeholder false-positive → 0.

---

## P2 — Orta İş (Toplam: 3-5 saat)

### P2.1 — 18 MERGE_NEEDED Dosya İncelemesi — **2-3 saat**

`.claude/wiki/`'den taşınan ve mevcut kanonik ile içerik farkı olan dosyalar `-from-claude-wiki` suffix'iyle yan yana duruyor. Sample diff (drift, ledger-as-source-of-truth, ddl): hepsinde **çelişki yok**, suffix versiyonlar daha **detaylı**.

**Standart Karar Algoritması (her dosya için):**

```
1. Read kanonik + Read suffix
2. İçerik karşılaştır (10 dk/dosya):
   ├── %95 aynı + suffix bilgi sağlamıyor → DELETE suffix
   ├── %95 aynı + suffix ek detay var → MERGE detay→kanonik, DELETE suffix
   └── Farklı bakış açıları → CROSS-LINK her ikisinden, KEEP suffix
3. Index'te yetim sayfa kalmasın
```

**Önerilen Sıra (kolaydan zora):**

| Sıra | Dosya çifti | Tahmin |
|---|---|---|
| 1 | `concepts/drift{,-from-claude-wiki}.md` | MERGE — kanoniğe detay ekle (tespit SQL) |
| 2 | `concepts/ledger-vs-denormalize{,-from-claude-wiki}.md` | MERGE — case study ekle |
| 3 | `concepts/write-through-cache{,-from-claude-wiki}.md` | MERGE — failure mode ekle |
| 4 | `decisions/credit-limit-override-role-based{,-from-claude-wiki}.md` | MERGE — implementasyon detayı ekle |
| 5 | `decisions/idempotent-reconcile-no-op-guard{,-from-claude-wiki}.md` | MERGE — minimal fark |
| 6 | `decisions/ledger-as-source-of-truth{,-from-claude-wiki}.md` | MERGE — exceptions list ekle |
| 7-18 | 12 entity (`account-transaction`, `customer`, `customer-account`, `purchase`, `reconcile-audit-log`, `sale`, `sale-item`, `stock-level`, `stock-movement`, `supplier`, `supplier-account`, `supplier-claim`) | Çoğu MERGE — entity şema/davranış detayı suffix'te |

**Kabul kriteri:** 18 yetim → 0. `.wiki/archive/` 18 dosya alır (suffix'ler).

---

### P2.2 — 5 Issues `-from-claude-wiki` İncelemesi — **30 dk**

| Dosya | Aksiyon |
|---|---|
| `issues/admin-endpoint-no-preauthorize-from-claude-wiki.md` | Lint Pass 1'de `-from-claude-wiki` suffix'li versiyon detay içeriyor → kanoniğe merge, suffix archive'a |
| `issues/customer-list-balance-zero-from-claude-wiki.md` | Aynı yöntem |
| `issues/overdue-amount-not-reconciled-from-claude-wiki.md` | Aynı |
| `issues/supplier-list-balance-zero-from-claude-wiki.md` | Aynı |
| `issues/today-collection-always-zero-from-claude-wiki.md` | Aynı |

---

### P2.3 — 50 Karşılıklı Tek-Yönlü Xref Eksikliği — **1-1.5 saat**

`concepts/X` → `entities/Y` link veriyor ama `entities/Y` "Related" listesinde `concepts/X`'i saymıyor. **Sample 10**:

| Eksik xref (eklenecek "Related" satırı) |
|---|
| `entities/customer-account.md` → `[[concepts/optimistic-lock-version]]` |
| `entities/stock-level.md` → `[[concepts/optimistic-lock-version]]` |
| `entities/sale.md` → `[[concepts/optimistic-lock-version]]` |
| `entities/account-transaction.md` → `[[concepts/optimistic-lock-version]]` |
| `entities/reconcile-audit-log.md` → `[[concepts/denormalization-with-reconcile]]` |
| `entities/api-manager.md` → `[[concepts/multi-tenant]]` |
| `concepts/optimistic-lock-version.md` → `[[concepts/append-only]]` |
| `concepts/ledger-vs-denormalize.md` → `[[concepts/append-only]]` |
| `concepts/drift.md` → `[[concepts/defense-in-depth]]` |
| `entities/supplier-claim.md` → `[[concepts/invoice-vs-total-shortage]]` |

**Strateji:** Her entity sayfasının sonuna standart `## Related Concepts` bölümü ekle, oradan ilgili concept'lere wikilink ver. Bash script'le yarı-otomatik:
```bash
# Tek-yönlü tespiti zaten /tmp/lint-oneway-real.txt'te
# Manuel inceleme + Edit
```

---

### P2.4 — 81 Zayıf Kaynak Doğrulama — **1 saat (sample)** + sürekli

Lint'te `≤1 source` rapor edildi (parser sınırı — bazı dosyalarda body `## Sources` farklı format). **Sample 5 kritik dosya** manuel kontrol et:

- `entities/sale.md` — `SaleServiceIntegrated.createSale()` link'i ekle
- `entities/customer-account.md` — `UserDefAccess` + drift fix kaynağı
- `entities/stock-level.md` — `StockLevelService.deductStock()` + atomic test
- `entities/api-manager.md` — `application.yml` route definitions
- `entities/security.md` — `data.sql` user seed kaynağı

**Sürekli aksiyon:** Yeni entity sayfası açılırken minimum 2 kaynak (bir kod, bir doküman) zorunlu — wiki CLAUDE.md protokolüne ekle.

---

## P3 — Backlog Düşük (Toplam: 1-2 saat)

### P3.1 — Lint Pass 3 Koşma — **15 dk**

P1 + P2 tamamlandıktan sonra lint script'i tekrar koş. Beklenen sayım:

| Kategori | P2 öncesi | P2 sonrası beklenen |
|---|---|---|
| Yetim sayfa | 18 | 0 |
| Kırık wikilink (gerçek) | 22 | 0 |
| Tek-yönlü xref (anlamlı) | ~50 | ~10 (kalan opsiyoneller) |
| Eksik kavram | 13 | 0 (bu turda stub açıldı) |
| Zayıf kaynak | 81 | ~70 (sample 5+ düzeltildi) |

### P3.2 — `.wiki/archive/` Doldur — **30 dk**

P2.1 + P2.2 sonucu 18+5 = 23 dosya `archive/`'a taşınacak. Klasör şu an boş (`archive/README.md` yok).

```bash
# Her -from-claude-wiki dosyası için:
mv .wiki/<kategori>/<dosya>-from-claude-wiki.md .wiki/archive/<dosya>-from-claude-wiki-2026-04-25.md
```

`archive/README.md` placeholder yarat (P1.2'de zaten kapsamda).

---

## P4 — Faz 3 Backlog (Uzun Vadeli — Sprint Bazında)

[[syntheses/codebase-snapshot-2026-04-25]] içindeki "Hâlâ Boş Bölgeler" listesi:

| # | Alan | Tahmin | Öncelik |
|---|---|---|---|
| 1 | **React (template/) modülü ingest** | 1-2 sprint | O |
| 2 | **pos-product-manager controller-bazlı endpoint kataloğu** (~50 controller) | 1 sprint | Y |
| 3 | **Core kütüphane derinleşme** (TOpenDbEntity, BaseDbServiceImp, @FilterDef) | 3-5 gün | Y |
| 4 | **i18n bundle altyapısı** (bnd-XX###, message_definitions, runtime resolution) | 2 gün | O |
| 5 | **Hibernate Filter mekanizması runtime** (`@Filter("filterCompany")` ↔ `CompanyContext.get()` akışı) | 1 gün | O |

---

## Tahmini Takvim

| Faz | Süre | İçerik |
|---|---|---|
| **Bugün (1 saat)** | P1 (1.1 + 1.2 + 1.3) | sed batch + 6 karar + placeholder fix |
| **Yarın (3-5 saat)** | P2 (2.1 + 2.2 + 2.3 + 2.4 sample) | MERGE_NEEDED + xref + zayıf kaynak |
| **Bu hafta (1 saat)** | P3 (3.1 + 3.2) | Lint Pass 3 + archive |
| **Sonraki sprint(ler)** | P4 | React, controller, core ingest |

**Toplam Faz 1-3:** ~5-7 saat. Faz 4 backlog (esnek).

---

## Bağımlılıklar

- P1.1 (sed) → P1.2'den önce çalışırsa P1.2'deki bazı kararlar gereksiz olur. **Sıra: P1.1 → P1.2 → P1.3.**
- P2.1 (MERGE_NEEDED) → P2.3'ten önce; çünkü 18 dosya silinince xref haritası küçülür.
- P3.1 (Lint Pass 3) → P2 tamamlandıktan sonra; öncesinde anlamsız.

## Kabul Kriterleri (Tüm Plan)

P1+P2+P3 sonucu **lint sağlık skoru**:

| Metrik | Mevcut | Hedef |
|---|---|---|
| 🔴 Yüksek bulgu | 23 | **0** |
| 🟠 Orta bulgu | 130 | **<20** |
| 🟡 Düşük bulgu | ~76 | **<30** |
| Yetim sayfa | 18 | **0** |
| Kırık wikilink | 22 | **0** |

## Sources

- Bu plan: [[lint-report]] Pass 2 (2026-04-25)
- Migration özeti: [[syntheses/codebase-snapshot-2026-04-25]]
- Önceki migration log: [[log]] (2026-04-25 girdileri)
- Ham bulgu data: `/tmp/lint-{orphans,broken,oneway-real,weak-source,missing-concepts}.txt` (lint Bash script çıktısı)

## Related

- [[lint-report]]
- [[syntheses/codebase-snapshot-2026-04-25]]
- [[log]]
- [[CLAUDE]] — wiki ajan protokolü (yeni içerik üretirken min 2 kaynak kuralı, P2.4'te belirtildi)
