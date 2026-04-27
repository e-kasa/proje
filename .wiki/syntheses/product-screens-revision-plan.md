---
title: Ürün Ekranları Revize Planı (Sprint 12)
tags: [synthesis, plan, ui-refactor, product, sprint-12]
source: ".claude/plans/polymorphic-gathering-flute.md"
date: 2026-04-27
status: superseded-by-implementation
---

## ⚠️ IMPLEMENTASYON GERÇEKLEŞTİ — Sprint 12 Revize Sonucu

Plan onaylandıktan sonra kod doğrulamasında **W2 + W3 scope'unun büyük çoğunluğunun zaten yapılmış olduğu** tespit edildi (Edit modal, sektör-aware step'ler, wizard refactor). Detay: [[log]] 2026-04-27 sprint-12 girişi.

**Gerçek Sprint 12 sonucu:**
- **W1 ✅**: ProductCard ortak component + referenceDataProvider + POS i18n purge
- **W2 ❌ → ZATEN VARDI**: Edit Flow / tab consol / sektör tutarlılığı kod gerçeğinde mevcut
- **W3 ❌ → ZATEN VARDI**: Wizard `add_product_wizard_screen.dart` 524 LOC coordinator + 6 step ayrı
- **W4 ✅ kısmi**: ProductAddMethodSheet + AppCachedImage entegrasyon. Pagination provider + Batch mobile Sprint 13'e ertelendi (backend hazır, frontend scope büyük)

Aşağıdaki orijinal plan referans olarak korundu — **gelecek sprint planları için** (W4.2/W4.4) kullanılabilir.

---

# Ürün Ekranları Revize Planı (Sprint 12)

3-4 haftalık tam refactor: 2 menü ekranı + 4 detay revize alanı. Mevcut durum için bkz. [[sources/code-refs/2026-04-27-product-screens-audit]].

## Amaç

POS satış kartları ve Inventory yönetim listesindeki kullanım/görünüm/akış sorunlarını çöz; ürün detayındaki 6+ farklı yolu tutarlı hale getir; Add Product Wizard'ın 4,758 LOC monolitiğini modüler yap; "ürün ekleme" disambiguation kur.

## Hedef Sonuçlar (8 madde)

1. **Tek `ProductCard` component** — POS + Inventory'de aynı, layout sektör config'inden okunur (autoParts → OEM rozeti, footwear → beden chip, vd.)
2. **Çalışan Edit flow** — `ProductDetailScreen` edit ikonu → `ProductEditSheet.show()` modal aç + kaydet
3. **Variant Edit tab'i** — `ProductDetailScreen` Variants tab'ine inline edit (stock/barcode) + add variant
4. **Wizard refactor** — 4,758 LOC → her step ayrı dosya, < 800 LOC per file
5. **Tek "Ürün Ekle" entry** — modal: Hızlı / Tam / Toplu / PDF Yükle disambiguation
6. **Reference data tek kaynak** — `referenceDataProvider` (KDV/birim/durum); tüm ekranlar buradan okur
7. **Pagination + responsive mobile** — Inventory list (50/page infinite scroll), Batch Entry mobile kart layout
8. **Wiki belge** — bu plan + audit sayfaları + log

## Sprint Breakdown (4 hafta özet)

### Hafta 1 — Ortak Kart Component + Reference Data
- `core/widgets/product_card.dart` (yeni) — `mode: posSale | inventoryListView | inventoryGridView`, `sector: SectorType`, `data: ProductCardData`
- `shared/providers/reference_data_provider.dart` (yeni) — VAT/unit/status async + cache
- POS hardcoded i18n purge: "Tükendi" → `t('stock.out_of_stock')`, "Transferde" → `t('stock.in_transit')`
- Stock threshold config'lenebilir (`product.minStockLevel ?? appConfig.defaultLowStockThreshold`)
- Inventory list ilk migration: List card → `ProductCard`

### Hafta 2 — Edit Flow + Detail Tab Konsolidasyonu
- `ProductEditSheet.show(context, productId)` (yeni veya `edit_product_modal.dart` modülerleştir)
- `ProductDetailScreen` tab standardı: General / Variants / Pricing / OEM (autoParts) / History / Relationships
- Variant tab inline edit (`variant_inline_editor.dart`)
- Vehicle Compat → OEM tab altına merge
- Sektör alan tutarlılığı: VariantsStep + StockBarcodeStep + BatchEntry sector check ekle

### Hafta 3 — Wizard Refactor (4,758 → modular)
- `add_product_wizard_screen.dart` → 300 LOC coordinator (TabController + state)
- Her step max 800 LOC (basic_info / variants / variants_stock / images / preview)
- `WizardStateProvider` (Riverpod) + sub-providers per step
- Auto-save draft (30s)
- Bulk import seed: typed `WizardSeed` model

### Hafta 4 — Unified Entry + Pagination + Mobile
- `ProductAddMethodSheet.show()` — 4 yöntem disambiguation modal
- `enhanced_product_list_screen.dart` → `PagedListView` (50/page)
- Mobile (<600px): Grid toggle gizle, sadece List
- Selection mode "İptal" chip + back override
- `cached_network_image` + lazy load
- Batch Entry mobile kart layout

## Riskler

| Risk | Etki | Mitigation |
|---|---|---|
| Wizard refactor regression | Yüksek | Feature branch + smoke test her step |
| Sektör eşleştirme yanlış | Orta | Golden file test 3 sektör |
| Pagination backend uyumsuz | Orta | W4 başında API kontrol |
| 4 hafta yetmez | Yüksek | Haftalık retro, hafta 4 esnek |

## Verification (sprint sonu)

- POS arama → karta tıkla → varyant → sepete ekle ✓
- Inventory list → grid/list → search/filter/sort → karta tıkla → detail → edit → kaydet ✓
- FAB → "Ürün Ekle" modal → 4 yöntem hepsi çalışır ✓
- Wizard 4 step + kaydet → listede yeni ürün ✓
- Mobile (<600px) batch entry kart layout ✓
- 3 sektör (autoParts/footwear/general) doğru gösterim ✓
- `flutter analyze` 0 error, tek dosya max 800 LOC, hardcoded TR YOK

## Sources

- [[sources/code-refs/2026-04-27-product-screens-audit]] — mevcut durum
- [[concepts/app-colors-palette]] — renk sistemi
- [[concepts/sector-agnostic]] — sektör mimarisi
- [[concepts/batch-entry-hierarchy]] — batch entity akışı
- [[syntheses/transactions-card-improvements]] — benzer kart iyileştirme paterni
- [[sources/status-snapshots/ui-modernization]] — devam eden modernizasyon
- `.claude/plans/polymorphic-gathering-flute.md` — sprint detay planı

## Related

- [[entities/product]]
- [[entities/product-variant]]
- [[concepts/sector-agnostic]]
- [[concepts/app-colors-palette]]
