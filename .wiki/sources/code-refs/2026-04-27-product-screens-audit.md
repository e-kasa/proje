---
title: Ürün Ekran Audit (2026-04-27)
tags: [audit, ui, product, inventory, pos, ux]
source: 3 paralel Explore agent çıktısı (wiki sweep + POS scan + detail screens scan)
date: 2026-04-27
status: verified
---

# Ürün Ekran Audit (2026-04-27)

POS Sprint 12 öncesi, ürün menüsü kartları + ürün detay ekranlarının mevcut durumu. Bu sayfa **audit (mevcut)** — revize planı için bkz. [[syntheses/product-screens-revision-plan]].

## Amaç

Sprint 12'de "ürün menüsü ekranındaki kartlar ve ürün detayındaki bütün ekranlarda kullanım, görünüm ve doğru akışlarla revize" yapılacak. Refactor başlamadan önce mevcut ekranların envanteri, sorunları ve tutarsızlıkları belgelenir.

## Menü Ekranları (2 adet)

### POS Satış Kartları
- **Dosya**: `project_pos/lib/features/pos/screens/pos_screen.dart` (~265 LOC)
- **Kart widget**: `project_pos/lib/features/pos/widgets/product_grid_item.dart` (~200 LOC)
- **Route**: `/pos`
- **Yapı**: Desktop Row(7:3) → sol ürün grid + sağ cart; Mobile FAB ile cart
- **Grid**: childAspectRatio 1.4, mainAxisExtent 160, 4/2/2 col (desktop/tablet/mobile)
- **Kart içeriği**: Icon (36x36), name (2 satır), kategori chip, SKU, ₺, stock badge

**Sorunlar**:
- "Tükendi" (line 181), "Transferde" (line 185) **hardcoded Türkçe** — i18n'e geçirilmeli
- Stock threshold **5 hardcoded** — `product.minStockLevel` veya app config'den okunmalı
- Image yok → `Icons.inventory_2_outlined` placeholder; image URL desteği yok
- OEM rozeti yok (autoParts sektöründe gerekli — şu an cart'ta plaka picker var ama kart üzerinde OEM gizli)
- Pagination yok — `size: 100` ile tüm ürünler tek seferde yüklenir
- Desktop layout'ta sağ-sol bağımsız scroll yok

### Inventory Yönetim Listesi
- **Dosya**: `project_pos/lib/features/inventory/screens/enhanced_product_list_screen.dart` (**1,774 LOC**)
- **Route**: `/inventory/products` → detail `/inventory/products/:id`
- **Yapı**: List + Grid view toggle, selection mode (bulk delete), filter (category + status), sort (6 seçenek), search (300ms debounce), OEM toggle, CSV export
- **Kart**: List card (`_buildListCard()` line 997) + Grid card (`_buildGridCard()` line 1249) — 2 ayrı widget

**Sorunlar**:
- Stock threshold **10 hardcoded** (line 70)
- Pagination yok — tüm ürünler client-side filtre/sort
- Selection mode exit yok — back button zorunlu, "İptal" UI'sı yok
- Image network blocker yok → slow network'te lag
- Kategori dropdown her açılışta yeniden fetch — cache yok
- OEM search toggle (`_isOemSearching`) UI'da label yok, sadece icon
- List+Grid kart 2 ayrı widget — kod duplikasyonu
- Sektör desteği YOK (POS'ta `sectorTypeProvider` var, burada yok)

## Detay Ekranları & Yolları (6+ farklı yol)

### Add Product Wizard
- **Dosya**: `features/inventory/screens/add_product/add_product_wizard_screen.dart` (**4,758 LOC** — kritik refactor)
- **Route**: `/inventory/add-product`
- **Yapı**: TabController, 3 step (Basic / Variants / Preview)
- **Step dosyaları**: `steps/basic_info_step.dart`, `steps/variants_step.dart`, `steps/variants_stock_step.dart`, `steps/preview_step.dart`
- **State**: tek monolitik `WizardState`
- **Açılış**: List FAB (Quick Add yerine), bulk import "Düzenle & Kaydet" action

**Sorunlar**:
- Tek dosya 4,758 LOC — modernizasyon raporunda **BLOCKER #2**
- Sector awareness sadece BasicInfoStep'te (`isParcaci`, `isGiyim`, `isTechnology` flag) — Variants/Stock step'lerde yok
- Bulk import pre-population: `extra: {...}` map (typed model yok)

### Product Detail Screen
- **Dosya**: `features/inventory/screens/product_detail_screen.dart` (**2,872 LOC**)
- **Route**: `/inventory/products/:id`
- **Yapı**: 5-6 tab — General / OEM (koşullu) / Cross-References (koşullu) / Vehicle Compat (koşullu) / History / Relationships
- **Edit**: AppAppBar'da edit icon var **AMA `_showProductEditSheet()` implementasyonu YOK** ⚠️

**Sorunlar**:
- Edit modal kod yok — UI buton var, çalışmıyor
- Variant tab'ine edit yok (sadece liste, inline stok/barcode düzenleme yok)
- Vehicle compat tab edit/delete yok
- Back navigation deep link desteklemez (filter state preserve etmez)
- 6 tab fazla — Vehicle Compat → OEM altına merge edilebilir (autoParts'ta tek panel)

### Batch Entry (Toplu Ürün Girişi)
- **Dosya**: `features/inventory/screens/batch_entry/batch_product_screen.dart` (**6,891 LOC**)
- **Route**: `/inventory/batch-entry`
- **Yapı**: Tab bar (All/New/Existing/Error/Saved) + DataTable (desktop) / Card (mobile responsive — kısmen)
- **PDF analiz**: `DocumentAnalyzeResultSheet` modal entegrasyonu

**Sorunlar**:
- OEM no field her sektörde görünür — sadece autoParts'ta olmalı
- Existing match flow belirsiz (otomatik öneri yok, manuel)
- Mobile DataTable scroll hell — kart layout kısmen var ama eksik
- Error row fix için inline edit zorunlu (modal yok)

### Bulk Import Review V2
- **Dosya**: `features/import/screens/bulk_import_review_screen_v2.dart`
- **Yapı**: Status filtreleri (NEW/CONFLICT/ADD_VARIANT/UPDATE_VARIANT/NEEDS_VARIANTS/ERROR), action butonları (CREATE/UPDATE_STOCK/UPDATE_PRICE/MATCH)

**Sorunlar**:
- "Select All" + bulk action UI var ama logic eksik
- Existing product match list tıklanamaz (manuel seçim sadece)
- Error detayları kartta gösterilmiyor (sadece status icon)

### Edit Product Modal
- **Dosya**: `features/import/screens/edit_product_modal.dart`
- **Yapı**: 800px Dialog, segmented mode (Match / Edit)
- **Kullanım**: SADECE bulk import çakışmasından çağrılır; ProductDetailScreen'den çağrılmıyor

**Sorunlar**:
- Reference data hardcoded: KDV `[%0, %1, %8, %10, %18, %20]`, birim `[Adet, Kg, Lt, Mt, Paket, Kutu]`
- Kategori API'den ama brand/tax/unit hardcoded → drift riski
- Match mode'da existing product card'ları tıklanamaz

### Quick Add Modal
- **Açılış**: `enhanced_product_list_screen.dart` FAB → `showQuickAddProductModal(context)`
- **Form**: name, SKU, price, category, unit, stock (minimal)

**Sorunlar**:
- Variant/resim/OEM olmadan kayıt → silsileli problem (sonradan variant eklenince inconsistency)

### Variants Yönetimi
- **Dosyalar**: `add_product/steps/variants_step.dart`, `variants_stock_step.dart`
- **Yapı**: Wizard içinde 2 step, attribute builder + variant matrix + per-variant stock/barcode/image
- **Eksik**: ProductDetailScreen'de variant edit tab yok — sadece add zamanı düzenlenebilir

### Barcode Management Screen
- **Dosya**: `features/inventory/screens/barcode_management_screen.dart` (~738 LOC)
- **Route**: `/inventory/barcodes`
- **Sorunlar**: Kart tap → action mapping yok (detay aç/edit yok)

## Ana UX/UI Sorunları (Özet)

### 1. Edit Flow Kırık
ProductDetailScreen'de edit ikonu var ama implementasyon eksik. EditProductModal sadece bulk import çakışması için. Sonuç: kullanıcı listeden ürüne girip değiştiremiyor.

### 2. 6+ Farklı "Ürün Ekleme" Yolu
Quick Add / Wizard / Batch Entry / Bulk Import / EditProductModal / Detail Edit (kırık). Ne zaman hangisi? Disambiguation YOK.

### 3. Kart Duplikasyonu
- POS `product_grid_item.dart` (1 kart)
- Inventory list `_buildListCard` + `_buildGridCard` (2 kart)
- 3 farklı widget, 3 farklı layout, ortak component yok

### 4. Hardcoded Türkçe (POS)
`product_grid_item.dart`: "Tükendi" (181), "Transferde" (185). i18n bypass.

### 5. Hardcoded Threshold
- POS: 5
- Inventory: 10
- `product.minStockLevel` veya app config'den okunmalı

### 6. Reference Data Drift
- Wizard: API'den (kategori, brand, unit, tax)
- EditProductModal: hardcoded (tax, unit)
- Aynı listeler farklı yerlerde farklı değerler — risk

### 7. Sektör-spesifik Alan Tutarsızlığı
- BasicInfoStep: `isParcaci/isGiyim/isTechnology` flag check var
- VariantsStep / VariantsStockStep / Batch Entry: sector check YOK
- Sonuç: AutoParts firmasında OEM kartta yok ama wizard step'inde var; Footwear'da beden matrix tutarsız

### 8. Pagination Yok
Inventory listesi 1000+ ürün ile lag riski — tüm ürünler client-side bellekte.

### 9. Selection Mode Exit Eksik
Inventory list selection mode'a girer, çıkış için sadece back button. UI'da "İptal" chip yok.

### 10. Image Optimization
`cached_network_image` veya placeholder/errorWidget kullanım tutarsız. Slow network'te lag.

## Modernizasyon Durumu (2026-04-22 başladı)

8 ekran tamamlanmış (`store_list`, `warehouse_list`, `add_store`, `add_warehouse`, `add_customer`, `category_list`, `add_supplier`, vd.). Tasarım sistemi:

| Legacy | Modern |
|---|---|
| `Scaffold` | `AppScaffold` |
| `TextField` (arama) | `AppSearchInput` |
| `TextFormField` | `AppInput` |
| `Card` | `AppCard` |
| `AlertDialog` | `AppConfirmationDialog.show*` |
| `Colors.blue/grey` | `AppColors.info/textMuted` |

**Ürün ekranları henüz dokunulmadı** — Sprint 12 hedefi.

## Sources

- 3 explore agent raporu (2026-04-27, conversation transcript)
- `.wiki/sources/status-snapshots/ui-modernization.md`
- `.wiki/sources/code-refs/screens-inventory.md`
- `.wiki/sources/code-refs/flutter_iyilestirme_analizi.md`
- `.wiki/concepts/batch-entry-hierarchy.md`
- `.wiki/concepts/sector-agnostic.md`
- `.wiki/concepts/app-colors-palette.md`
- `.wiki/sources/claude-md/project-pos.md`

## Related

- [[syntheses/product-screens-revision-plan]] — Sprint 12 revize planı
- [[entities/product]]
- [[entities/product-variant]]
- [[concepts/sector-agnostic]]
- [[concepts/app-colors-palette]]
- [[syntheses/transactions-card-improvements]]
- [[sources/status-snapshots/ui-modernization]]
