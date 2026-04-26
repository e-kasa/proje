---
title: Wiki Ingest — Yeni Kaynak İşle
type: source
source: .claude/commands/wiki-ingest.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# Wiki Ingest — Yeni Kaynak İşle

HEDEF: `C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\`

Kullanıcı bir kaynak verdi: kod dosyası, PR, commit, teknik doc veya konuşma notu. Bu kaynağı SEDCORE POS wiki'sine entegre et.

Kaynak: $ARGUMENTS

## Adımlar

1. **Kaynağı oku** (path verildiyse Read, yoksa son konuşma bağlamından).

2. **Çıkar**:
   - Ana konu / amaç
   - Bahsedilen **entity**'ler (domain model: Customer, SupplierAccount, StockMovement, ...)
   - **Flow**'lar (uçtan uca akış: sale-checkout, drift-reconciliation, ...)
   - **Pattern**'lar (mimari desen: denormalization, multi-tenant-filter, ...)
   - **Integration**'lar (dış servis: PostgreSQL, Tesseract, ...)
   - Yeni **kavramlar** (glossary eklemesi)
   - **Çelişki** (mevcut wiki ile çakışma)

3. **5 maddeli özet göster** — kullanıcı onaylamadan yazma.

4. **Onay sonrası** (kullanıcı "evet/ok/yap" derse):

   a. Her entity için:
      - `wiki/entities/<kebab-case>.md` yoksa aç, varsa güncelle
      - Frontmatter: `title, type: entity, status, last-verified, sources[], related[]`
      - Kısa kod snippet (<10 satır), path referansı ile
      - İki yönlü wikilink: `[[entities/other]]`, `[[flows/x]]`

   b. Her flow için aynısını `wiki/flows/` altında
   c. Her pattern için `wiki/patterns/` altında
   d. Her integration için `wiki/integrations/` altında
   e. Yeni terim çıktıysa `wiki/glossary.md`'ye ekle
   f. Çelişki varsa `wiki/contradictions.md`'ye tarihli girdi

5. **`wiki/index.md` sync** — yeni sayfa varsa MOC'a ekle.

6. **`wiki/log.md`'ye girdi** (en üste):
   ```
   ## [YYYY-MM-DD] ingest | <kısa başlık>
   - Dokunulan dosyalar: liste
   - Kaynak: $ARGUMENTS
   ```

7. **Özet rapor**:
   - Kaç sayfa oluşturuldu / güncellendi
   - Kaç cross-reference kuruldu
   - Açık uçlar (doğrulama gereken noktalar)

## Kurallar

- Kod dosyasını wiki'ye kopyalama — **path link** ver (`pos-product-manager/src/.../X.java:120`)
- Her iddia için kaynak path ver — kaynaksız yazı yasak
- Tekrar yazma — `reference/` veya `decisions/`'da varsa oraya link ver, kopya yapma
- Silme yasak — eskimiş bilgi varsa `wiki/archive/`'a taşı

## Katman Farkı (dikkat)

- **Kural** (prescriptive) → `.claude/reference/` (wiki'ye yazma)
- **Karar** (ADR, tarihli) → `.claude/decisions/` (wiki'ye yazma)
- **Tarif** (how-to) → `.claude/runbooks/` (wiki'ye yazma)
- **Açıklama** (descriptive) → `.claude/wiki/` ✅ (buraya yaz)

Dil: Türkçe (teknik terimler İngilizce kalabilir).
