---
name: SEDCORE POS — Kalıcı Bilgi Arşivi (.wiki)
purpose: Yeni nesil POS projesi için sektör-agnostik, kümülatif, descriptive bilgi vault'u
maintained-by: LLM ajan (Claude Code) — kullanıcı kaynak verir, ajan bookkeeping yapar
language: Türkçe (teknik terimler İngilizce kalabilir)
last-verified: 2026-04-25
---

# SEDCORE POS — Kalıcı Bilgi Arşivi

Bu dizin **descriptive bilgi** arşividir: "X nasıl çalışır?", "Y hangi servislerle etkileşir?", "Z kararı neden alındı?". Kural (CLAUDE.md'lerdeki anayasalar), runbook (tarif) ve kod dosyaları dışındaki **her şey** burada birikir.

## Amaç

**Yeni nesil POS projesi** için sektör bağımsız kalıcı bilgi arşivi. Proje aşağıdaki geniş kapsamı karşılayacak:

- **Sektör bağımsız işletmek**: market, giyim mağazası, yedek parçacılar, teknoloji marketleri, ayakkabıcılar, vb. Her sektörün özel ihtiyaçları konfigürasyonla çözülür; kod tabanı tek.
- **Ana modüller**:
  - Stok (anlık stok, transfer, sayım)
  - Cari hesap (müşteri + tedarikçi; vadeli / peşin; drift reconcile)
  - POS satış + iade (offline kapasiteli)
  - Satın alma (eksik teslimat + claim mekanizması)
  - Raporlar
- **Entegrasyonlar** (çoğaltılabilir):
  - e-Fatura / e-Arşiv otomatik gönderim
  - Pazaryeri senkronizasyonu (Trendyol, Hepsiburada, N11 vb.)
  - Kargo firmaları API'leri
  - Banka POS / ödeme gateway
  - Muhasebe programı export
  - WhatsApp / SMS / email bildirim
  - Barkod cihazları, terazi, yazıcı

Bu wiki her yeni modül / karar / senaryo / entegrasyon öğrenildiğinde büyür. Konuşma arasında kaybolan bilgi burada **kalıcı** hale gelir.

## Dizin Yapısı

```
.wiki/
├── CLAUDE.md                # bu dosya — ajan protokolü
├── index.md                 # MOC (Map of Content)
├── log.md                   # append-only olay log'u
├── raw/
│   ├── code-refs/           # ham kaynak: kod snippet, PR, commit, konuşma çıktısı — DOKUNULMAZ
│   └── docs/                # statik doküman: PDF, teknik spec, dış referans — DOKUNULMAZ
├── sources/
│   └── code-refs/           # her ham kaynağın özet sayfası (YYYY-MM-DD-slug.md)
├── entities/                # dosyalar, fonksiyonlar, servisler, kişiler, firmalar, modüller
├── concepts/                # soyut kavramlar: multi-tenant, sektör-agnostiklik, drift, ...
├── decisions/               # atomik kararlar — HER KARAR = TEK SAYFA
├── issues/                  # düzeltilen sorunlar (kök neden + fix) + açık bakımlar
├── syntheses/               # üst düzey genel bakış sayfaları (modül haritası, mimari özet)
└── archive/                 # eskimiş sayfalar — silinmez, taşınır
```

## Dil

**Tüm wiki sayfaları Türkçe yazılır**. Teknik terimler İngilizce kalabilir:
- `@Transactional`, `@Version`, `@PreAuthorize` — kod anahtar kelimeleri
- `BigDecimal`, `Optimistic Lock`, `N+1`, `JWT` — evrensel teknik terim
- Entity/tablo/kolon adları: `customer_account`, `currentBalance` vb.
- Aksi halde anlam kayıpsız Türkçe: "satın alma" > "purchase", "bakiye" > "balance"

## Naming

- Dosya adları **kebab-case**: `customer-account.md`, `sale-checkout-flow.md`, `2026-04-25-stock-transfer-bug.md`
- Wikilink Obsidian uyumlu: `[[klasör/sayfa-adi]]`
- Tarihli dosyalar (sources, sorun raporları, karar notları): `YYYY-MM-DD-slug.md`

## Sayfa Formatı

Her sayfa bu şablonla başlar:

```markdown
---
title: Sayfa Başlığı (okunaklı)
tags: [entity, module, concept, ...]
source: <dosya path veya kaynak referansı; birden fazla virgülle>
date: YYYY-MM-DD
status: stub | draft | verified | archived
---

# Sayfa Başlığı

(H1 başlık — title ile aynı veya yakın)

## (içerik — sayfanın özü)

## Sources

- `path/to/file.ext`
- [[raw/code-refs/...]]  (veya harici URL)

## Related

- [[entities/...]]
- [[concepts/...]]
```

### Status Seviyeleri

- **stub** — sadece başlık + bir iki cümle (ajan yeni keşfetti, detay yok)
- **draft** — ana içerik yazıldı, doğrulama bekliyor
- **verified** — kod / kaynak ile doğrulandı, `date` güncel
- **archived** — eskimiş, `archive/` altına taşındı; frontmatter `superseded-by: [[yeni/sayfa]]` içerir

## Üç Operasyon Workflow'u

LLM ajan wiki üzerinde 3 ana operasyon yapar. Her biri farklı amaçlı, ayrı davranış seti.

### 1. INGEST — Yeni Kaynak İşle

**Tetikleyici**: Kullanıcı `raw/code-refs/` veya `raw/docs/` altına yeni bir dosya koyar → "ingest et" komutu.

**Davranış**:
1. `raw/code-refs/<yeni-dosya>` içeriği tara (DOKUNMA — read-only)
2. Ana konuyu çıkar: ne yapıldı, hangi dosyalara dokunuldu, hangi kararlar alındı, hangi sorunlar çözüldü/açık kaldı
3. Özet yaz: `sources/code-refs/YYYY-MM-DD-<slug>.md`
   - Frontmatter (title, tags, source: orijinal raw dosya path, date, status=draft)
   - Bölümler: **Amaç**, **Ne Yapıldı**, **Değişen Dosyalar**, **Alınan Kararlar**, **Karşılaşılan Sorunlar**, **Açık Konular**
4. Bahsedilen entity/concept/decision/issue sayfalarını çapraz-güncelle:
   - Sayfa yoksa → yeni stub oluştur, `sources/code-refs/<özet>` referansını ekle
   - Sayfa varsa → ilgili bölüme bir satır + raw kaynak linki ekle
5. `index.md`'yi sync: yeni sayfalar listeye eklenir
6. `log.md`'ye girdi: `## [YYYY-MM-DD] ingest | <kaynak slug>` + dokunulan dosyalar

**Özel kural**: `raw/` altındaki dosya **hiçbir zaman değiştirilmez**. Hata/güncelleme gerekirse kullanıcı yeni bir ham dosya verir.

### 2. QUERY — Wiki'ye Soru Sor

**Tetikleyici**: Kullanıcı "wiki'de X nasıl yapılıyor?" gibi soru sorar.

**Davranış**:
1. İlgili sayfaları bul (entities / concepts / flows / decisions / syntheses)
2. Cevabı sentezle — **mevcut sayfalar referanslı**, uydurma yok
3. Cevap kalıcı değerse → `syntheses/<konu>.md` altına geri-dosyala (varsa güncelle, yoksa yeni sayfa)
4. `log.md`'ye girdi: `## [YYYY-MM-DD] query | <soru özet>`

**Hard rule**: Kaynaksız iddia yasak. Bir bilgi için sayfa yoksa → "bilgi eksik, ilgili kaynağı `raw/` altına koy, ingest edeyim" cevabı.

### 3. LINT — Sağlık Kontrolü

**Tetikleyici**: Kullanıcı `lint <gün>` (varsayılan 30 gün) komutu verir — aylık ritim önerilir.

**Davranış**:
1. Tüm wiki sayfaları tara (archive dahil, eskimiş işareti için)
2. Kategorize et:
   - 🔴 **Çelişki** — aynı konuda iki farklı iddia (bkz. "## ÇELİŞKİ" kuralı)
   - ⚠️ **Eskimiş** — `date` N gün üzeri VE kaynak dosya son N günde değişmiş
   - 🟡 **Yetim** — hiçbir wikilink almıyor (sadece `index`/kategori README'sinden gelmiyor)
   - 🟠 **Eksik Kavram** — 3+ sayfada geçen ama kendi sayfası olmayan kavram
   - 📌 **Kaynak Boşluğu** — `sources:` frontmatter'ı tek path veya boş
   - 🔗 **Tek-Yönlü Cross-Ref** — A → B link var ama B'nin `Related` listesinde A yok
   - 🟤 **Stub** — 30+ gündür `status: stub`
3. `lint-report.md` yaz (overwrite — append değil)
4. `log.md`'ye: `## [YYYY-MM-DD] lint | <bulgu sayısı>`

**Hard rule**: Lint **otomatik düzeltme yapmaz** — sadece raporlar.

## Hard Rules (Değişmez Kurallar)

Bu kurallar her durumda geçerli; istisna **yok**.

1. **raw/ asla değiştirilmez** — ham kaynak ingest edildikten sonra dokunulmaz. Güncelleme gerekirse kullanıcı yeni bir ham dosya (yeni tarih + slug) verir; eski kalır.

2. **Kaynaksız iddia yasak** — her sayfada `## Sources` bölümü dolu olmalı. Ajan bir bilgi üretiyorsa kaynağı göstermeli (raw kaynak, kod path, konuşma referansı). Kaynak yoksa: "kaynak eksik, ingest gerekli" der, uydurmaz.

3. **Sayfa silme yok** — eskimiş veya yanlış sayfa **silinmez**, `archive/` altına taşınır. Frontmatter:
   ```yaml
   status: archived
   archived-date: YYYY-MM-DD
   superseded-by: "[[yeni-konum/sayfa]]"    # varsa
   ```
   Silmek git history'yi kaybettirir + karar izini yok eder.

4. **Çelişki silinmez, işaretlenir** — Bir sayfanın iddiası başka sayfa/kod/kaynakla çelişirse:
   - Sayfaya `## ÇELİŞKİ` bölümü eklenir (tarih + iki taraf + gözlem + status)
   - Çelişki hangisi doğru netleşene kadar **iki iddia da sayfada kalır**
   - Yeni karar alınınca `resolved-date` işlenir, iki iddia tek geçmiş kaydı olarak kalır

5. **Dil Türkçe** — tüm yeni sayfalar Türkçe. Var olan İngilizce bir kaynak (raw) Türkçe özetlenir; sources sayfasına "orijinal İngilizce" notu düşülür.

6. **Naming kebab-case** — `customer_account.md` veya `CustomerAccount.md` yasak.

7. **Log append-only** — `log.md`'ye yazılan girdi **silinmez veya değiştirilmez** (yazım hatası dahi düzeltilmez; yeni girdi alttan düzeltir).

## Sektör-Agnostik Yazım İlkesi

POS projesi birden fazla sektöre hizmet eder. Sayfa yazımında:

- **Genel terimler tercih**: "ürün", "müşteri", "satış"; "parça", "araç", "kumaş", "metrekare" sektör özel konularda açıklanır
- **Sektör özel bilgi açık etiketlenir**:
  ```markdown
  ## Yedek Parça Sektör Özel
  (araç uyumluluk + plaka takibi + OEM numaraları)
  ```
- Temel modüller (stok/cari/satış) sektör bağımsız; sektör genişletmeleri yan eklenti olarak belgelenir
- Entegrasyonlar sektör değil kanal bazlı: e-Fatura, Trendyol, WhatsApp, ... (her sektör kullanabilir)

## İlişki: `.claude/wiki/` ile

Projede iki paralel wiki var:

| Wiki | Kapsam | Ton |
|---|---|---|
| `.claude/wiki/` | AccountsHub + devam eden aktif sprint odaklı; geliştirici referansı | Teknik, sprint-bazlı |
| `.wiki/` (bu) | **Uzun vadeli sektör-agnostik POS vizyonu**; karar arşivi, genel mimari, entegrasyon kataloğu | Stratejik, proje-genel |

İki wiki çakışırsa: `.wiki/` stratejik gerçek, `.claude/wiki/` taktiksel gerçek. Çelişki → `.wiki/contradictions.md` + çapraz referans.

## İlk Adımlar (Kullanıcı için)

1. Bir konuşma / dosya / PR özetini `raw/code-refs/YYYY-MM-DD-<slug>.md` altına yapıştır
2. Bana "ingest et" de — sayfa işlerim
3. Bir konu belirsizse `query` — cevap sentezlerim
4. Ayda bir `lint` çalıştır — sağlık raporu

İlk ingest'i **sen** tetikleyeceksin. Ben otomatik başlatmıyorum.
