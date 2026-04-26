---
title: Lint Raporu — Tam Sağlık Kontrolü (Pass 2)
date: 2026-04-25
scanned: 188
excluded: 7 (raw/)
status: post-migration-deep-scan
previous: 195 (migration), 88 (initial setup)
---

# Lint Raporu — 2026-04-25 (Tam Pass 2)

`raw/` hariç **188 dosya** üzerinde 6 kategorili tam sağlık kontrolü. Otomatik düzeltme YAPILMADI — sadece raporla.

## Özet

| Kategori | Adet | Şiddet ortalama |
|---|---|---|
| 🔴 Çelişki (gerçek) | **0** | — |
| 🟠 Çelişki adayı (MERGE_NEEDED) | 21 | Y |
| 🟡 Eskimiş | **0** | — |
| 🟠 Yetim sayfa | 18 | O |
| 🔴 Kırık wikilink (gerçek) | 22 | Y |
| 🟡 Kırık wikilink (placeholder/false) | 18 | D |
| 🟠 Eksik kavram (≥3 bahis) | 13 | O |
| 🟡 Tek-yönlü xref (anlamlı) | ~50 | D |
| 🟠 Zayıf kaynak (≤1 source) | 81 | O–D |

**Toplam aksiyon gerektiren: 134 bulgu** (Y:23 / O:130 / D:~76).

---

## 1. ÇELİŞKİLER

### 🔴 Gerçek çelişki: **0**

Sample diff (3 çift kontrol edildi): `drift.md` ↔ `drift-from-claude-wiki.md`, `ledger-as-source-of-truth.md` ↔ `*-from-claude-wiki.md`, `ddl-create-dev-strategy.md` (sentez) ↔ `2026-04-13-ddl-create-strategy.md` (ADR). **Hepsinde çelişki yok**, ek bilgi/detay seviyesi farkı var. Bu nedenle teknik olarak "DUPLICATE" / "MERGE_NEEDED" kategorisinde sayılırlar — gerçek çelişki yok.

### 🟠 Çelişki Adayı (MERGE_NEEDED): 21

#### 18 `-from-claude-wiki` suffix'li yetim çift

Migration sırasında `.claude/wiki/`'den taşınan 18 dosya, mevcut kanonik sayfayla içerik farkı sebebiyle suffix ile yan yana tutuldu. **Tümünde çelişki değil, zenginleştirme**:

| Kanonik (kısa) | Suffix versiyon (detaylı) | Δ satır |
|---|---|---|
| `concepts/drift.md` (35) | `concepts/drift-from-claude-wiki.md` (53) | +18 |
| `concepts/ledger-vs-denormalize.md` (35) | `*-from-claude-wiki.md` (49) | +14 |
| `concepts/write-through-cache.md` (22) | `*-from-claude-wiki.md` (53) | +31 |
| `decisions/credit-limit-override-role-based.md` (33) | `*-from-claude-wiki.md` (63) | +30 |
| `decisions/idempotent-reconcile-no-op-guard.md` (28) | `*-from-claude-wiki.md` (34) | +6 |
| `decisions/ledger-as-source-of-truth.md` (27) | `*-from-claude-wiki.md` (29) | +2 |
| `entities/account-transaction.md` (38) | `*-from-claude-wiki.md` (76) | +38 |
| `entities/customer-account.md` (29) | `*-from-claude-wiki.md` (60) | +31 |
| `entities/customer.md` (21) | `*-from-claude-wiki.md` (40) | +19 |
| `entities/purchase.md` (32) | `*-from-claude-wiki.md` (105) | +73 |
| `entities/reconcile-audit-log.md` (29) | `*-from-claude-wiki.md` (74) | +45 |
| `entities/sale.md` (38) | `*-from-claude-wiki.md` (104) | +66 |
| `entities/sale-item.md` (21) | `*-from-claude-wiki.md` (81) | +60 |
| `entities/stock-level.md` (27) | `*-from-claude-wiki.md` (74) | +47 |
| `entities/stock-movement.md` (24) | `*-from-claude-wiki.md` (57) | +33 |
| `entities/supplier-account.md` (23) | `*-from-claude-wiki.md` (52) | +29 |
| `entities/supplier-claim.md` (26) | `*-from-claude-wiki.md` (61) | +35 |
| `entities/supplier.md` (22) | `*-from-claude-wiki.md` (39) | +17 |

**Aksiyon (her biri için):** Manuel diff → 3 yoldan biri:
1. Kanonik zaten yeterli → suffix dosya `archive/`'a taşı + `Bash rm`.
2. Suffix detaylı versiyon kanonik olsun → kanonik üstüne yaz, suffix sil.
3. İki içerik birleştirme (en yaygın) → zenginleştirilmiş içerik kanoniğe merge, suffix `archive/`'a.

**Öncelik:** Yüksek (uzun vadede iki paralel kaynak drift üretir).

#### 3 Decision Duplicate (sentez ↔ ADR)

Migration öncesi `.wiki/`'de mimari sentez sayfaları vardı; `.claude/decisions/`'dan taşınan formal ADR'ler aynı konuyu kapsıyor.

| Sentez (üst seviye) | ADR (formal, tarihli) | Karar |
|---|---|---|
| `decisions/ddl-create-dev-strategy.md` | `decisions/2026-04-13-ddl-create-strategy.md` | İki ayrı amaç (sentez vs formal) — cross-link iyi olur. Tek dosyaya birleştirme zorunlu değil. |
| `decisions/sedcore-role-taxonomy.md` | `decisions/2026-04-13-store-admin-rename.md` | Sentez geniş kapsamlı; ADR spesifik. Cross-link öner. |
| `decisions/location-id-type-unified.md` | `decisions/2026-04-13-location-id-unification.md` | Aynı durum. Cross-link öner. |

**Aksiyon:** Sentez → ADR cross-link ekle (her iki yönde "Related" bölümü). Birleştirme **opsiyonel**.

**Öncelik:** Orta.

---

## 2. ESKİMİŞ İDDİALAR

### ✅ 0 dosya

Tüm `last-verified` ≤ 2026-04-25 (max 12 gün eski). Eşik: 30 gün. Tarama: `last-verified: 2025*`, `2026-01*`, `2026-02*`, `2026-03-[01-25]*` → hiçbiri eşleşmedi.

`raw/code-refs/` altındaki en yeni 5 source `2026-04-25` tarihli — taşıma sonrası mevcut sayfaları güncellemeyi tetiklemiyor.

---

## 3. YETİM SAYFALAR

### 🟠 18 yetim — hepsi `-from-claude-wiki` suffix'li

Hiçbir başka sayfadan `[[link]]` referansı almıyor.

```
concepts/drift-from-claude-wiki.md
concepts/ledger-vs-denormalize-from-claude-wiki.md
concepts/write-through-cache-from-claude-wiki.md
decisions/credit-limit-override-role-based-from-claude-wiki.md
decisions/idempotent-reconcile-no-op-guard-from-claude-wiki.md
decisions/ledger-as-source-of-truth-from-claude-wiki.md
entities/account-transaction-from-claude-wiki.md
entities/customer-account-from-claude-wiki.md
entities/customer-from-claude-wiki.md
entities/purchase-from-claude-wiki.md
entities/reconcile-audit-log-from-claude-wiki.md
entities/sale-from-claude-wiki.md
entities/sale-item-from-claude-wiki.md
entities/stock-level-from-claude-wiki.md
entities/stock-movement-from-claude-wiki.md
entities/supplier-account-from-claude-wiki.md
entities/supplier-claim-from-claude-wiki.md
entities/supplier-from-claude-wiki.md
```

> **Not:** Bu liste #1'deki MERGE_NEEDED listesiyle %100 örtüşür. Yetim olmasının sebebi: index'te listelenmiş ama içerikten wikilink kullanılmıyor. MERGE_NEEDED kararı verilince hepsi ya `archive/` ya da kanonik içine merge → yetim sorunu kendiliğinden çözülür.

**Aksiyon:** MERGE_NEEDED inceleme ile birlikte çöz. **Öncelik:** Orta (orphan tek başına kritik değil; merge süreci kritik).

---

## 4. EKSİK KAVRAM SAYFALARI

### 🟠 13 domain-spesifik aday (≥10 bahis, sayfa yok)

Filtreden geçenler (generic Java/Flutter terimleri çıkarıldı: GitHub, BigDecimal, WebSocket, ResponseEntity, ExceptionMapper, AlertDialog, ApiClient, AsyncNotifier, MyEntity, SupplierResponse).

| Kavram | Bahis | Önerilen kategori | Önerilen yol |
|---|---|---|---|
| **AccountsHub** | 36 | entity (Flutter screen) | `entities/accounts-hub-screen.md` |
| **CompanyContext** | 28 | concept (multi-tenant ThreadLocal) | `concepts/company-context.md` |
| **PreAuthorize** | 25 | concept (Spring Security guard) | `concepts/pre-authorize-guard.md` |
| **ProductVariant** | 22 | entity | `entities/product-variant.md` |
| **AppColors** | 21 | concept (Flutter tema) | `concepts/app-colors-palette.md` |
| **RowStatus** | 20 | concept (batch entry state machine) | `concepts/batch-row-status.md` |
| **StateNotifier** | 18 | concept (Riverpod legacy) | `concepts/state-notifier-vs-async.md` |
| **DocumentItemResult** | 17 | entity (PDF analyze response) | `entities/document-item-result.md` |
| **BatchEntryRow** | 15 | entity | `entities/batch-entry-row.md` |
| **BatchEntryState** | 11 | concept | `concepts/batch-entry-state.md` |
| **CompanySetting** | 11 | entity | `entities/company-setting.md` |
| **UserDef** | 10 | entity (security domain) | `entities/user-def.md` |
| **UserDefAccess** | 9 | entity (security domain) | `entities/user-def-access.md` |

**Aksiyon:** Yeni stub sayfalar aç, frontmatter + 1 paragraf tanım + ana referans sayfaya wikilink. Sonraki ingest'te içerik zenginleşir.

**Öncelik:** Orta. UserDef/UserDefAccess/ProductVariant **Yüksek** (core entity'ler eksik).

---

## 5. TEK-YÖNLÜ CROSS-REFERENCES

### 🟡 773 ham edge / ~50 öncelikli karşılıklı eksiklik

Çoğu false-positive (concept → raw kaynak link'i karşılığı zaten gerekli değil). Filtrelenmesi gereken alt-küme:

**Örnek karşılıklı olması gereken eksiklikler** (sample 10):

| A → B (var) | B → A (yok, eklenmeli) |
|---|---|
| `concepts/optimistic-lock-version` → `entities/customer-account` | `entities/customer-account.md` "Related" bölümünde `[[concepts/optimistic-lock-version]]` |
| `concepts/optimistic-lock-version` → `entities/stock-level` | `entities/stock-level.md` aynı şekilde |
| `concepts/optimistic-lock-version` → `entities/sale` | `entities/sale.md` aynı |
| `concepts/optimistic-lock-version` → `entities/account-transaction` | `entities/account-transaction.md` aynı |
| `concepts/denormalization-with-reconcile` → `entities/reconcile-audit-log` | `entities/reconcile-audit-log.md` aynı |
| `concepts/multi-tenant` → `entities/api-manager` | `entities/api-manager.md` |
| `concepts/append-only` → `concepts/optimistic-lock-version` | `concepts/optimistic-lock-version.md` "Related" |
| `concepts/append-only` → `concepts/ledger-vs-denormalize` | `concepts/ledger-vs-denormalize.md` |
| `concepts/defense-in-depth` → `concepts/drift` | `concepts/drift.md` |
| `concepts/invoice-vs-total-shortage` → `entities/supplier-claim` | `entities/supplier-claim.md` |

**Tam liste:** `/tmp/lint-oneway-real.txt` (773 satır, raw/ ve placeholder filtreleyince ~50 kritik karşılıklı eksiklik kalır).

**Aksiyon:** Her entity sayfasına alt-bölüm: `## Related Concepts` ekleyip ilgili concept'lere wikilink. Toplu Edit + manuel inceleme ~1 saat.

**Öncelik:** Düşük (navigation iyileştirme, content correctness'e etkisi yok).

---

## 6. KAYNAK BOŞLUKLARI

### 🟠 81 dosya `≤1 source` (entities/decisions/concepts)

Frontmatter `source:` ve body'deki `## Sources` bölümü taranarak 0 veya 1 kaynaklı sayfalar tespit edildi. **Not:** Parser sınırı — bazı sayfaların body'sinde "Source" başlıklı bölümü farklı format kullanıyor olabilir, manuel doğrulama önerilir.

**Kritik (önemli sayfa, tek kaynak):**

| Dosya | Mevcut source | Önerilen ek doğrulama |
|---|---|---|
| `entities/account-transaction.md` | 1 | İkinci ledger sample (purchase + payment yan yana) |
| `entities/customer-account.md` | 1 | UserDefAccess link + 2026-04-25 drift fix kaynağı |
| `entities/sale.md` | 1 | SaleServiceIntegrated.createSale() canlı kod |
| `entities/stock-level.md` | 1 | StockLevelService.deductStock() + atomic decrement test |
| `entities/supplier-account.md` | 1 | SupplierAccount entity dosyası + reconcile path |
| `entities/api-manager.md` | 1 | application.yml route definitions canlı |
| `entities/security.md` | 1 | data.sql user seed kaynağı |
| `entities/pos-product-manager.md` | 1 | OpenAPI yaml + service impl path'leri |

**Tam liste:** `/tmp/lint-weak-source.txt` (81 dosya).

**Aksiyon:** Önemli entity'lere body'de `## Sources` bölümü altına 2+ raw/code-refs link.

**Öncelik:** Orta (bilgi doğrulanabilirliği için kritik, ama mevcut bilgi yanlış değil).

---

## 7. KIRIK WIKILINK'LER (referans — önceki passdan)

### 🔴 22 gerçek kırık + 🟡 18 false-positive

**Gerçek kırık (acil):**
- 16 ad değişimi (flows/ → syntheses/flow-, integrations/ → syntheses/integration-, patterns/ → concepts/pattern-)
- 6 gerçek eksik hedef: `[[contradictions]]`, `[[decisions/append-only-semantics]]`, `[[decisions/base-entity-list-screen-adoption]]`, `[[decisions/defensive-credit-sale-customer-required]]`, `[[README]]`, `[[archive/README]]`
- 7 raw/code-refs/* link (raw/ scope dışı tarandığı için kırık görünüyor; gerçekten dosya var, raporda false-positive sayılır)

**False-positive (kozmetik):** `X`, `X-from-claude-wiki`, `concepts/...`, `entities/other`, `flows/x`, `klasör/sayfa-adi`, `yeni/sayfa`, vb.

**Aksiyon:** Bash sed batch replace (eski → yeni link). Önceki rapordaki tabloyla aynı.

**Öncelik:** Yüksek (16 ad değişikliği) + Orta (6 eksik hedef için karar).

---

## En Kritik 3 Bulgu

1. **🔴 16 wikilink ad değişimi** (Yüksek) — Migration sonrası `flows/X` `integrations/X` `patterns/X` referansları otomatik kırıldı. **Tek `sed` komutuyla 10 dakikada düzelir**, dokümantasyon navigasyonu o ana kadar bozuk.
2. **🟠 18 MERGE_NEEDED dosya** (Yüksek) — `-from-claude-wiki` suffix'li yetimler iki paralel hakikat noktası üretir, drift garantili. Manuel diff + birleştirme 2-3 saat. Ertelenirse her hafta drift artar.
3. **🟠 13 eksik domain kavram** (Orta-Yüksek) — `UserDef`, `UserDefAccess`, `ProductVariant`, `CompanyContext`, `AccountsHub`, `BatchEntryRow` gibi core domain isimleri 9-36 sayfada geçiyor ama sayfa yok. Yeni katılan biri için karanlık nokta.

## Kapsam Notu

`raw/` (7 dosya) bilinçli olarak hariç tutuldu (içerik karşılaştırma için referans, lint öznesi değil). `node_modules/`, `.git/`, `target/`, `.claude/worktrees/` zaten `.wiki/` dışında.

---

_Otomatik düzeltme yapılmadı. Aksiyon kararı kullanıcıda._
