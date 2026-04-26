---
title: Wiki Query — Wiki'ye Soru Sor
type: source
source: .claude/commands/wiki-query.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# Wiki Query — Wiki'ye Soru Sor

HEDEF: `C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\`

SEDCORE POS wiki'sine soru sor. İyi cevaplar `wiki/syntheses/` altına geri-dosyalanır (birikim).

SORU: $ARGUMENTS

## Adımlar

1. **`wiki/index.md` oku** — hangi kategoride aranacağını belirle.

2. **İlgili sayfaları bul ve oku**:
   - `wiki/entities/`
   - `wiki/flows/`
   - `wiki/patterns/`
   - `wiki/integrations/`
   - `wiki/syntheses/` (önceki sentezler)
   - `wiki/glossary.md` (terim tanımı)
   - Gerekirse `.claude/reference/`, `.claude/decisions/`, `.claude/runbooks/`

3. **Cevabı sentezle**. Her önemli iddia için kaynak referansı:
   - Wiki sayfası adı: `[[entities/customer-account]]`
   - O sayfanın dayandığı kod path: `pos-product-manager/src/.../X.java:120`

4. **Wiki'de cevap yoksa**:
   - Hangi bilgi eksik söyle
   - Hangi dosya/kaynağı `/wiki-ingest` etmen gerektiğini öner
   - Sayfa yazma, sadece eksiklik bildir

5. **Cevap bir karşılaştırma / analiz / yeni sentez içeriyorsa**:
   - `wiki/syntheses/<slug>.md` olarak yaz
   - Frontmatter: `title, type: synthesis, status: draft, last-verified, covers[], related[]`
   - Kullandığın tüm kaynak sayfalara link ver
   - Basit lookup ise (tek sayfadan çekilen) geri-dosyalama yapma

6. **`wiki/log.md`'ye girdi**:
   ```
   ## [YYYY-MM-DD] query | <kısa soru özeti>
   - Kullanılan sayfalar: liste
   - Geri-dosyalama: syntheses/<slug>.md (varsa) veya "yok"
   ```

7. **Cevabı göster** + yeni/güncellenmiş sayfaların listesi.

## Kurallar

- Kaynaksız iddia yazma — her cümle için wiki sayfası veya kod path referansı
- Wiki'deki bilgi koda karşı doğrulanmamışsa **"wiki'ye göre X (last-verified: Y)"** diyerek belirt
- Tarih damgalı memory'den (MEMORY.md) çekilen bilgi varsa "memory'ye göre" de
- Çelişki gördüysen `wiki/contradictions.md`'ye girdi aç, cevapta belirt

Dil: Türkçe.
