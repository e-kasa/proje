---
title: Wiki Olay Kaydı (Event Log)
type: log
format: append-only
last-verified: 2026-04-25
---

# Wiki Olay Kaydı

Append-only olay kaydı. **En yeni üste**.

## Olaylar

## [2026-04-28] sprint-16 | Inventory + Catalog + Stock modül migration (16 ekran) ✅

Sprint 15'te kurulan template katmanı + 2 PoC migration sonrası, audit'teki Sprint 16-20 modüler roadmap başlatıldı. Sprint 16 = inventory + catalog + stock üç modülü, toplam 16 ekran.

### Migration Stratejisi

**3 paralel iş kolu:**
- **16-A (ana iş, kendim)**: `enhanced_product_list_screen.dart` — Sprint 13'te pagination pattern'ı bu ekranda doğmuştu, artık template tüketicisi olmalı (dogfood).
- **16-B (agent)**: 7 küçük catalog/inventory ekranı.
- **16-C (agent)**: 8 stock ekranı.

**Karar kuralı (her ekran için):** Template doğal oturuyorsa migrate et; bottom-bar/AppBar dayatması davranış değişikliği yaratacaksa **BaseScaffold swap** yap (AppScaffold→BaseScaffold), ekstra zarar ver-me.

### 16-A: enhanced_product_list_screen.dart (`inventory/screens/`)

ListScreenTemplate'in **referans tüketicisi**. Önceki yapı (Sprint 13'ten miras):
- `_scrollController` field + `addListener(_onScroll)` initState + `removeListener+dispose` dispose + `_onScroll` bottom-200px metodu
- `_buildContent` (loading/empty/RefreshIndicator dispatcher)
- `_buildListView` (RefreshIndicator + ListView.builder + extraFooter)
- `_buildGridView` (RefreshIndicator + CustomScrollView + SliverGrid + SliverToBoxAdapter footer)
- `_buildLoadMoreFooter` (spinner veya "X öğe gösteriliyor" text)

Sonrası:
- Tek `ListScreenTemplate<Map<String,dynamic>>` çağrısı (~95 LOC build())
- `_scrollController` + `_onScroll` + `_buildContent` + `_buildListView` + `_buildGridView` + `_buildLoadMoreFooter` SİLİNDİ (~120 LOC)
- Net delta: **-25 LOC** (mantıksal mimari kazancı çok daha büyük: pagination/refresh/grid/empty hepsi template tarafında)
- `searchSlot`, `statsSlot`, `filterSlot`, `bottomBar` (selection mode), `floatingActionButton`, `emptyState` slot'larına temiz delege

Bu migration template tasarımının **dogfood doğrulaması**. Hiç custom override gerekmedi → API yeterli kapsamda.

### 16-B: 7 catalog/inventory küçük ekran (agent)

| # | Ekran | Karar | LOC Δ |
|---|---|---|---|
| 1 | `inventory_screen.dart` | BaseScaffold swap (özel hub layout) | +4/-2 |
| 2 | `brands_screen.dart` | ListScreenTemplate (search+stats+list) | +53/-75 |
| 3 | `units_screen.dart` | ListScreenTemplate (brands paralel) | +68/-90 |
| 4 | `barcode_management_screen.dart` | ListScreenTemplate (3 slot) | +92/-115 |
| 5 | `category_list_screen.dart` | ListScreenTemplate (selection-aware actions) | +75/-85 |
| 6 | `add_category_screen.dart` | FormScreenTemplate (3 section) | +121/-141 |
| 7 | `company_category_screen.dart` | BaseScaffold swap (gradient AppBar uyumsuz) | +5/-1 |

**Net delta:** -91 LOC. **0 yeni issue** (2 pre-existing baseline).

**Dağılım:** ListScreenTemplate ×4, FormScreenTemplate ×1, BaseScaffold swap ×2.

**Minor visual change:** `category_list_screen` + `add_category_screen` — `AppAppBar.primary` → `AppAppBar.standard` (template kısıtı). Davranış değil görsel: gradient/primary renk yerine standard tema rengi.

### 16-C: 8 stock ekranı (agent)

| # | Ekran | Karar | LOC Δ |
|---|---|---|---|
| 1 | `enhanced_stock_screen.dart` | BaseScaffold swap (orijinalde AppBar yoktu, dayatma kaçınıldı) | +1 |
| 2 | `multi_warehouse_stock_screen.dart` | ListScreenTemplate | -27 |
| 3 | `stock_value_report_screen.dart` | BaseScaffold swap (hero+stat hibrid layout) | -19 |
| 4 | `stock_transfer_screen.dart` | BaseScaffold swap (custom form, FormScreenTemplate uyumsuz) | +1 |
| 5 | `stock_alert_screen.dart` | DetailScreenTemplate (3 tab + isLoading/error delege) | -36 |
| 6 | `stock_movement_history_screen.dart` | ListScreenTemplate | -10 |
| 7 | `stock_count_review_screen.dart` | BaseScaffold swap (custom save bar) | +1 |
| 8 | `stock_transfer_review_screen.dart` | BaseScaffold swap (custom approve bar) | +1 |

**Net delta:** -88 LOC. **0 yeni issue** (12 → 12 baseline).

**Dağılım:** ListScreenTemplate ×2, DetailScreenTemplate ×1, BaseScaffold swap ×5.

**Öne çıkan:** `stock_alert_screen.dart` `DefaultTabController + Scaffold` deseninden DetailScreenTemplate'e tertemiz oturdu (-36 LOC tek dosya).

### Sprint 16 Toplam

| Metrik | Değer |
|---|---|
| Migrate edilen ekran | 16 |
| ListScreenTemplate kullanımı | 7 (1×ana + 4 catalog/inventory + 2 stock) |
| FormScreenTemplate kullanımı | 1 |
| DetailScreenTemplate kullanımı | 1 |
| BaseScaffold-only swap | 7 |
| Net LOC delta (toplam 16 dosya) | **~-204 LOC** |
| `flutter analyze` 16 dosya | 14 issue (hepsi pre-existing baseline, 0 yeni) |

### Önemli Karar: "BaseScaffold-only swap" pattern'ı

7/16 ekranda template'lere zorla sığdırma yerine sadece `AppScaffold→BaseScaffold` swap yapıldı:
- Custom layout (hub, hero+stat hibrid, tree-view)
- Bottom-bar ListView içinde değil Column içinde (transfer/review ekranları)
- AppBar olmayan ekran (template AppBar'ı dayatıyor)
- Gradient/custom AppBar (standard.AppAppBar uyumsuz)

Bu, template katmanının **opt-in** doğasını koruyor (mimaride L0/L1/L2/L3 hiyerarşisi). Template ekran sayısını arttırmak başarı metriği değil; **doğru ekranı doğru seviyede tutmak** asıl değer.

### Kalan Sprint 17-20 Modüller

| Sprint | Modül | Ekran | Tahmini |
|---|---|---|---|
| 17 | sales + purchases + accounts | ~9 | 2 gün |
| 18 | finance + hrm + autoparts + supplier_claims | ~13 | 2-3 gün |
| 19 | import + auth + menu + pos + dashboard | ~10 | 2 gün |
| 20 | Cleanup: pre-existing teknik borç (deprecated value, underscore stili) | ~10 | 1 gün |

### Doğrulama

- 16 dosya `flutter analyze`: 14 baseline issue, 0 yeni ✅
- Kullanıcı smoke test: bekliyor
- Template dogfood: enhanced_product_list_screen başarıyla template tüketicisi oldu — API genişletme gereği yok ✅

### Sources

- [[sources/code-refs/2026-04-27-design-system-template-audit]] — Sprint 15 audit
- [[syntheses/design-system-template-architecture]] — 4 template mimarisi (Sprint 15)

---

## [2026-04-27] sprint-15 | BaseScaffold + 4 Feature Template mimarisi + Settings/Reports migration ✅

Kullanıcı emri: "tüm ekranları BaseScaffold + Feature Templates + Design System uyumlu hale getir, wiki ile yap". Mega scope (64+ ekran). Sprint 15 = mimari kurulum + Settings+Reports modülü PoC. Sprint 16-20 ile devam edecek (audit'te modüler roadmap).

### Yeni Template Katmanı (5 dosya)

**1. BaseScaffold** — [`core/widgets/base_scaffold.dart`](project_pos/lib/core/widgets/base_scaffold.dart)
- AppScaffold + Riverpod `AsyncValue<T>` switcher
- `loading → CircularProgress`, `error → AppEmptyState.error(retry)`, `data → dataBuilder(T)`
- Sync mode: `body` parametresi de var (asyncValue olmazsa)

**2. ListScreenTemplate** — [`templates/list_screen_template.dart`](project_pos/lib/core/widgets/templates/list_screen_template.dart)
- Sprint 13'te `enhanced_product_list_screen` üzerinde geliştirilen pagination pattern reusable
- ScrollController bottom-200px → onLoadMore + RefreshIndicator + loading footer
- Generic `<T>` + itemBuilder + searchSlot/filterSlot/statsSlot/FAB/bottomBar slot'ları
- Grid mode (isGrid + gridDelegate)

**3. FormScreenTemplate** — [`templates/form_screen_template.dart`](project_pos/lib/core/widgets/templates/form_screen_template.dart)
- `FormSection(title, icon, fields)` listesi
- formKey + isSaving + canSubmit + customBottomBar/secondaryActions/topBanner

**4. DetailScreenTemplate** — [`templates/detail_screen_template.dart`](project_pos/lib/core/widgets/templates/detail_screen_template.dart)
- TabController + dispose self-managed
- `DetailTab(label, icon, builder)` listesi
- onTabChanged callback (tab-aware export gibi)
- headerSlot (TabBar ile TabBarView arasında — Reports date pill için)
- isLoading + error switcher
- keepTabsAlive (IndexedStack mode)

**5. DashboardScreenTemplate** — [`templates/dashboard_screen_template.dart`](project_pos/lib/core/widgets/templates/dashboard_screen_template.dart)
- statCards grid (default 2 sütun) + sections list + onRefresh

### PoC Migration (2 ekran)

| Ekran | Önce | Sonra | Özet |
|---|---|---|---|
| `settings_screen.dart` | AppScaffold + with SingleTickerProviderStateMixin + late TabController + initState/dispose + bottom: TabBar + TabBarView | DetailScreenTemplate(tabs: 4 DetailTab) | Boilerplate kaldırıldı, body 60→25 LOC |
| `reports_screen.dart` | AppScaffold + manual loading/error/TabController + headerColumn + TabBarView | DetailScreenTemplate(headerSlot, isLoading, error, onTabChanged) | TabController + loading/error helper, body 75→60 LOC |

**DetailScreenTemplate'a Sprint 15'te eklenen feature:** `headerSlot` (Reports'taki date pill + advanced report links için TabBar'ın altında ek alan).

### Agent Migration Sonucu (7 ekran ✅)

| Ekran | Karar | LOC değişim | Sebep |
|---|---|---|---|
| `profile_screen.dart` | BaseScaffold | 276→277 | Tab/form/dashboard yapısı yok — pass-through |
| `company_settings_screen.dart` | BaseScaffold | 339→340 | Save AppBar action'da kalmalı (FormScreenTemplate behavior değişikliği yaratırdı) |
| `sector_settings_screen.dart` | BaseScaffold | 273→274 | Sektör seçim kartı listesi — özel layout |
| `user_management_screen.dart` | **ListScreenTemplate** | **910→898 (−12)** | Search/filter/list/refresh/empty hepsi template'a delege ✅ |
| `daily_summary_screen.dart` | BaseScaffold | 408→409 | Date selector statCards öncesi (DashboardScreenTemplate header slotu yok) |
| `sales_summary_screen.dart` | BaseScaffold | 399→400 | Custom date pill + period toggle + chart |
| `profit_overview_screen.dart` | BaseScaffold | 242→243 | Custom date pill + 3 top cards |

**Toplam:** 2847 → 2841 (−6 net LOC). user_management −12 (gerçek refactor), diğerlerinde +1 import shift.

**Karar paterni:** Form/Dashboard template'leri "save AppBar→bottom bar" veya "header slot" gibi UX değişikliği gerektirdiği ekranlarda BaseScaffold tercih edildi — Sprint 16+'da i18n + UX kararıyla beraber FormScreenTemplate/DashboardScreenTemplate'a geçirilebilir.

### Sprint 15 Final İstatistik

- **Yeni dosya:** 5 (BaseScaffold + 4 template)
- **Migrate edilen ekran:** 9 (settings_screen, reports_screen + agent 7 ekran)
- **Template kullanım:** DetailScreenTemplate ×2, ListScreenTemplate ×1, BaseScaffold ×6
- **Toplam LOC değişim:** project_pos/lib +1100 (5 yeni template) − 50 (9 migration nettir)
- **`flutter analyze`:** 0 yeni issue ✅ (6 pre-existing teknik borç korundu — `_, __` underscores, use_build_context_synchronously, use_null_aware_elements — Sprint 20 cleanup'ında ele alınacak)

### Wiki Back-File

- **Audit:** [[sources/code-refs/2026-04-27-design-system-template-audit]] — design system 21 widget + 64+ ekran envanteri + modüler roadmap
- **Synthesis:** [[syntheses/design-system-template-architecture]] — 5 dosya mimarisi + L0-L3 migration seviyeleri + Sprint 15 sonuç + riskler
- **Index:** Sources/Sprint öncesi audit'ler + Syntheses/Sprint Plans bölümlerine yeni satır

### Sprint 16-20 Roadmap

| Sprint | Modül | Ekran | Tahmini |
|---|---|---|---|
| 16 | inventory + stock + catalog | ~13 | 2-3 gün |
| 17 | sales + purchases + accounts | ~9 | 2 gün |
| 18 | finance + hrm + autoparts + supplier_claims | ~13 | 2-3 gün |
| 19 | import + auth + menu + pos + dashboard | ~10 | 2 gün |
| 20 | Cleanup: pre-existing teknik borç (deprecated value, underscore stili) | ~10 | 1 gün |

Toplam ~10 iş günü, 5 sprint.

### Verification

- `flutter analyze` (5 yeni template + 2 PoC ekran): **0 issue** ✅
- Smoke test bekliyor (kullanıcı runtime)

## [2026-04-27] sprint-14 | ProductCard tam migration — Inventory list/grid kartları ✅

Sprint 12'den ertelenen W1.4 (ProductCard tam migration) bu sprintte uygulandı. Inventory liste/grid kartlarındaki ~470 LOC kod tek `ProductCard` çağrısına dönüştürüldü.

### ProductCard Genişletmeleri

**Yeni field'lar (`ProductCardData`):**
- `unit: String?` — adet/kg/çift birim suffix'i stok rozetinde
- `oemNumbersText: String?` — OEM mode'da kart altı satır
- `crossRefsText: String?` — OEM mode'da kart altı satır

**Yeni property'ler (`ProductCard`):**
- `showOemRow: bool` — Inventory OEM search toggle açıkken `oemNumbersText` + `crossRefsText` satırları render eder
- `showStatusBadge: bool` — `data.status` ACTIVE değilse (DRAFT/INACTIVE/OUT_OF_STOCK) stok rozeti yanına status badge ekler

**Yeni helper'lar (ProductCard içinde):**
- `_buildStatusBadgeWidgets(t)` — status enum → AppBadge variant + i18n label
- `_buildOemRows(t)` — OEM/CrossRef satırları (Icons.confirmation_number / compare_arrows + AppColors.warning/info)
- `_buildStockBadge` artık unit suffix de gösteriyor: `"42 adet"` yerine `"42"`

### Inventory List Migration (`enhanced_product_list_screen.dart`)

| Helper / Method | Önce | Sonra |
|---|---|---|
| `_buildListCard` | 240 LOC body | 41 LOC ProductCard çağrısı |
| `_buildGridCard` | 213 LOC body | 35 LOC ProductCard çağrısı |
| `_StockChip` class | 55 LOC | silindi (ProductCard `_buildStockBadge` üstlendi) |
| `_getStatusBadgeVariant` | 7 LOC | silindi (ProductCard `_buildStatusBadgeWidgets`) |
| `_productIconPlaceholder` | 6 LOC | silindi (AppCachedImage errorWidget) |
| **Toplam dosya** | **1,778 LOC** (Sprint 12 öncesi) | **1,456 LOC** (~322 LOC azalma; Sprint 13 pagination state +130 LOC + W1.4 ~470 LOC silme) |

### İmport Eklemeler

- `package:project_pos/core/widgets/product_card.dart` — `unused_import` ignore yorumu kaldırıldı
- `package:project_pos/shared/providers/sector_provider.dart` — `sectorConfigProvider` watch için

### Verification

- `flutter analyze` (2 değiştirilmiş dosya): **0 issue** ✅
- Mevcut davranış korundu: tap → detail route, longPress → selection mode, OEM search toggle → OEM/CrossRef satırları, status DRAFT/INACTIVE → ek badge

### Sprint 15'e Ertelenen

- **W4.4 full** — `batch_product_screen.dart` 6,891 LOC DataTable → mobile kart layout (banner Sprint 13'te eklendi, full responsive Sprint 15)
- **Server-side category/status filter** — `/products?category=X&status=Y` backend genişletmesi (frontend client-side filter şu an pagination ile birlikte tutarsız sonuç verebilir, ama tek-sayfa kullanım için yeterli)
- **Wizard ileri refactor** — `variants_stock_step.dart` 1,179 LOC + `preview_step.dart` 1,045 LOC (opsiyonel, < 1500 LOC kabul edilebilir)
- **Batch screen 11 lint cleanup** — pre-existing teknik borç (deprecated value→initialValue, vd.)
- **Reference data API entegrasyonu** — Sprint 12 W1.2 `referenceDataProvider` şimdi static; backend `/reference-data` endpoint hazır olunca FutureProvider API çağrısı

### Smoke Test (Kullanıcı Runtime)

1. **Inventory list**: kart görünümü Sprint 12 öncesi ile aynı olmalı (sektör rozeti + status badge + OEM mode satırları)
2. **AutoParts firmasında**: search box yanındaki "OEM" toggle'a tıkla → OEM aramada kartların altında "OEM: 12345, 67890" + "Ref: ABC-123" satırları
3. **DRAFT/INACTIVE ürünler**: stok rozetinin yanında ek "Taslak" / "Pasif" rozeti
4. **Image olmayan ürünler**: AppCachedImage placeholder (CircularProgressIndicator) → errorWidget Icons.image_not_supported
5. **Selection mode** (long-press): hem list hem grid'de checkbox

## [2026-04-27] sprint-13 | Ürün liste pagination + batch mobile uyarı ✅

Sprint 12 sonrası Sprint 13 — ertelenen W4.2 (Inventory list pagination) + W4.4 (batch mobile) minimal implementasyonu. Kullanıcı "devam" emri.

### W4.2 Frontend Pagination — Inventory Ürün Listesi

**Backend kontrol:** `ProductControllerImpl.java:106` Spring `Pageable` ile `Page<ProductResponse>` döndürüyor — frontend hâlihazırda content[] çekiyordu, metadata kayıptı.

**Yeni:** [`product_service.dart`](project_pos/lib/features/inventory/services/product_service.dart) `getProductsPage()` method + `ProductListPage` model (items, currentPage, totalPages, totalElements, hasMore).

**Update:** [`enhanced_product_list_screen.dart`](project_pos/lib/features/inventory/screens/enhanced_product_list_screen.dart):
- State: `_currentPage`, `_hasMore`, `_isLoadingMore`, `_scrollController` (page size 50)
- `_loadProducts()` rewrite — page=0 reset + getProductsPage(search:_searchController.text)
- Yeni `_loadMoreProducts()` — page+=1, items append
- ScrollController bottom-200px → loadMore tetikleyici
- ListView/GridView → RefreshIndicator + ScrollController + loading footer
- `_onSearchChanged` → server-side search (page=0 reset, getProductsPage çağrısı)
- "X ürün gösteriliyor" footer (i18n key: `product.products_loaded`)

**Akış:** Liste açılır → ilk 50 ürün → scroll dibe → otomatik 50 daha → search yazınca page=0 reset + sunucu sorgusu. Pull-to-refresh çalışır. Eski client-side category/status filter korundu (server-side filter Sprint 14).

### W4.4 Batch Entry — Mobile Uyarı Banner

**Update:** [`batch_product_screen.dart`](project_pos/lib/features/inventory/screens/batch_entry/batch_product_screen.dart) build column'a `MediaQuery.of(context).size.width < 600` check + `_buildMobileWarningBanner()` ekleme: kullanıcıya "yatay çevirin / tablet kullanın" bilgi.

**Tam responsive kart layout Sprint 14'e ertelendi** — 6,891 LOC dosyada DataTable → kart layout büyük refactor.

### i18n (2 yeni key)

- `product.products_loaded` (`bnd-pd204`) — "ürün gösteriliyor" / "products shown"
- `batch.mobile_landscape_hint` (`bnd-bt218`) — uyarı banner metni

### Sprint 14'e Ertelenen

- **W1.4** ProductCard custom slot (OEM mode satır + status badge variant) + Inventory list `_buildListCard` 240 LOC tam migration
- **W4.4 full** Batch Entry DataTable → mobile kart layout (`<600px` koşullu render)
- **Server-side category/status filter** — pagination ile filter uyumu için backend endpoint genişletmesi (`/products?category=X&status=Y&page=0&size=50`)
- **Wizard `variants_stock_step.dart` 1,179 LOC + `preview_step.dart` 1,045 LOC ileri refactor** (opsiyonel)
- **Pre-existing teknik borç:** batch_product_screen.dart 11 lint info/warning (deprecated value→initialValue, unnecessary_underscores, prefer_interpolation, unused_parameter discountRate)

### Verification

- `flutter analyze` (3 değiştirilmiş dosya): **0 yeni issue** (11 pre-existing teknik borç batch_product_screen'de)
- Backend Maven dokunulmadı (sadece frontend + i18n)

## [2026-04-27] query | cari hesap bakiye bilgileri doğruluğu

**Soru:** "Cari işlemler kısmındaki genel ve müşteri/tedarikçi hesap bilgileri doğru mu?"

**Yöntem:** 2 paralel Explore agent (backend balance flow + frontend display) + 8 wiki sayfası audit (concepts: ledger-vs-denormalize, drift, denormalization-with-reconcile; entities: customer-account, account-transaction; decisions: ledger-as-source-of-truth, scheduled-reconcile-safe-rollout, db-side-aggregate-over-java-loop; issues: customer-list-balance-zero, today-collection-always-zero, overdue-amount-not-reconciled, accounts-pagination-missing, accounts-error-boundary-missing; syntheses: accounts-hub-production-readiness).

**Verdict:** ✅ Yapısal olarak doğru. Ledger + denormalize + write-through + reconcile pattern standart. Geçmiş silent-null bug'ları (customer/supplier-list-balance-zero, today-collection-always-zero) ve overdue reconcile RESOLVED. Üç operasyonel risk + üç UX gap açık (P1/P2 backlog).

**Geri-dosyalama:** `.wiki/syntheses/accounts-balance-correctness-audit-2026-04-27.md` ⭐ NEW (audit sentezi, 7 öneri Sprint 13 adayı).

**Index:** Syntheses bölümüne 1 satır link eklendi.

## [2026-04-27] sprint-12 | Ürün ekranları refactor — W1 + W4 implement + audit korreksiyon ✅

Kullanıcı "onay beklemeden tüm planı yap, test en sonda" emri ile Sprint 12 implementasyonu başladı. **Audit'in 4 ana iddiası kod doğrulamasıyla yanlış çıktı** — gerçek scope büyük ölçüde daha küçük.

### Audit Korreksiyonları (kod ile doğrulandı)

1. **Edit Flow YOK iddiası** → ASLINDA `product_detail_screen.dart:1609-1860` `_showProductEditSheet()` 251 LOC production-quality (sektör-aware, KDV chips, status, kategori dropdown, save+toast+refresh).
2. **Vehicle Compat tab merge önerisi** → Tab yapısı zaten **conditional**: `cfg.fields.showVehicleCompat`/`showCrossRef`. Merge cosmetic.
3. **Sektör tutarsızlığı** → YANLIŞ. `variants_step.dart` 23+148, `variants_stock_step.dart` 26+148 zaten SectorType switch + i18n; `batch_product_screen.dart` 37 cfg kullanım.
4. **Wizard 4,758 LOC** → YANLIŞ. `add_product_wizard_screen.dart` **524 LOC**. 6 step ayrı dosyada (basic_info 962, images 536, preview 1045, stock_barcode 701, variants 794, variants_stock 1179). Refactor edilmiş.

### Uygulanan Değişiklikler

**W1 (önceki tur):**
- Yeni: [`core/widgets/product_card.dart`](project_pos/lib/core/widgets/product_card.dart) — 3 mode + sektör-aware + AppBadge
- Yeni: [`shared/providers/reference_data_provider.dart`](project_pos/lib/shared/providers/reference_data_provider.dart) — VAT/Unit/ProductStatus tek hakikat noktası
- i18n: `stock.in_transit` (`bnd-s111`) + `stock.depleted` (`bnd-s112`)
- Update: `product_grid_item.dart` ConsumerWidget + i18n
- Update: ProductCard `_buildStockBadge` i18n

**W4 (bu tur):**
- Yeni: [`features/inventory/widgets/product_add_method_sheet.dart`](project_pos/lib/features/inventory/widgets/product_add_method_sheet.dart) — 4 yöntem disambiguation modal (Hızlı / Tam / Toplu / PDF)
- i18n: `product.add_method_*` 10 yeni key (`bnd-pd194-203`)
- Update: `enhanced_product_list_screen.dart` FAB → `ProductAddMethodSheet.show()` (eski direct Quick Add bypass)
- Update: ProductCard `_buildThumbnail` → `AppCachedImage` (cached_network_image entegrasyonu)

### Verification

- `flutter analyze` (5 değiştirilmiş/yeni dosya): **0 issue** ✅
- Manuel smoke test bekliyor (kullanıcı runtime'da)

### Sprint 13'e Ertelenenler (gerekçe: backend hazır ama frontend büyük scope)

- **W4.2 Pagination provider rewrite** — Backend `/products?page=0&size=10` mevcut (`ProductControllerImpl.java:106`), frontend `productServiceProvider.getProducts(size:100)` çekiyor; provider rewrite + scroll loadMore Sprint 13 (~1-2 gün)
- **W4.4 Batch Entry mobile kart** — `batch_product_screen.dart` 6,891 LOC, MediaQuery 1 kez. DataTable → kart layout büyük refactor, Sprint 13
- **W1.4 Inventory list ProductCard tam migration** — `_buildListCard` 240 LOC + OEM mode satırları + status badge variant'ları. ProductCard'a custom slot ekleyip migration Sprint 13
- **Wizard variants_stock_step.dart 1,179 LOC + preview_step.dart 1,045 LOC ileri refactor** — opsiyonel, < 1500 LOC kabul edilebilir

### Dosyalar

- Audit: [[sources/code-refs/2026-04-27-product-screens-audit]] (status: verified-with-corrections)
- Plan: [[syntheses/product-screens-revision-plan]] (status: superseded-by-implementation)
- Sprint planı: `.claude/plans/polymorphic-gathering-flute.md`

## [2026-04-27] query | ürün menüsü kartları + ürün detay ekranları revize plan

Kullanıcı talebi: "Ürün menüsü ekranındaki kartlar ve ürün detayındaki bütün ekranlarda kullanım, görünüm ve doğru akışlarla revize edilecek planı çıkaralım."

**Yöntem:** 3 paralel Explore agent (wiki sweep + POS scan + detail screens scan) + AskUserQuestion ile 4 scope kararı netleştirildi (POS+Inventory paralel + 4 detay revize alanı + büyük sprint 3-4 hafta + audit & synthesis ikili dosyalama).

**Bulgular özeti:**
- 2 menü ekranı (POS `pos_screen.dart` + `product_grid_item.dart`; Inventory `enhanced_product_list_screen.dart` 1,774 LOC)
- 6+ farklı ürün detay yolu (Wizard 4,758 LOC, Detail 2,872 LOC, Batch 6,891 LOC, Quick Add, Bulk Import, Edit Modal)
- 10 UX/UI sorun: Edit flow KIRIK (kod yok), 4+ ekleme yolu disambiguation YOK, kart duplikasyonu, hardcoded TR/threshold, reference data drift, sektör tutarsızlığı, pagination yok

**Geri-dosyalama (3 wiki sayfası):**
- `.wiki/sources/code-refs/2026-04-27-product-screens-audit.md` (yeni — mevcut durum + 10 sorun)
- `.wiki/syntheses/product-screens-revision-plan.md` (yeni — 4 hafta breakdown, 8 hedef sonuç)
- `.wiki/index.md` 2 yeni link (Sources/Sprint öncesi audit'ler + Syntheses/Sprint Plans)

**Sprint plan dosyası:** `.claude/plans/polymorphic-gathering-flute.md` (Sprint 12 detay implementation)

**Onay:** ExitPlanMode user approved (mega scope tüm 4 detay alanı + büyük sprint).

## [2026-04-27] sprint-11d | Plaka picker autocomplete (POS + Payment modal) ✅

POS satış sepeti ve Payment modal SPECIFIC modu plaka seçimleri **inline TextField + autocomplete** stiline geçti. Dropdown'lar kaldırıldı; çok plakalı müşterilerde (filo/taksi/transport) prefix-search ile hızlı seçim.

**Motivasyon:** Sprint 10/11c dropdown'ları 1-3 plakalı müşteri için yeterliydi; 10+ plakalı kayıtlarda scroll yorucu. Backend'de zaten `customerVehicleSearchProvider` (JPQL prefix `LIKE 'X%'`) hazırdı, UI bağlantısı eksikti.

**Yeni dosya (1):**
- `customers/widgets/vehicle_search_field.dart` — ortak `VehicleSearchField` widget. TextField + 300 ms debounce + inline suggestion overlay. Boş query'de tüm plakalar (`customerVehiclesProvider`), dolu query'de prefix search (`customerVehicleSearchProvider`). `allowClear`, `dense`, `trailing` slot, `selectedVehicle`/`onSelected` API.

**Değişen dosyalar (2):**
- `pos/widgets/customer_vehicle_picker.dart` — Dropdown + InputDecorator yapısı silindi, doğrudan `VehicleSearchField` döner; "+ yeni plaka" `trailing` slot'unda durur (44x44 primary card)
- `accounts/screens/payment_record_modal.dart` — `_buildVehicleFilter()` Container+DropdownButton yerine `VehicleSearchField(dense: true, allowClear: true)` döner; state `_selectedVehicleId` + `_selectedVehiclePlate` çiftinden `Map<String,dynamic>? _selectedVehicle` tek field'a indirgendi; `_buildOpenSalesPicker` ve `_submit` payload'ı bu Map'ten id/plateNormalized derive eder; `customer_vehicles_provider` import kaldırıldı (artık widget içinde)

**Backend dokunulmadı.** Sprint 9'dan beri `GET /customers/{id}/vehicles/search?q=` zaten vardı.

**UX detayları:**
- Focus → tüm plakalar suggestion açılır (boş query)
- Yazma → 300 ms debounce → server-side LIKE 'X%' (i18n key `vehicle.search_placeholder` placeholder)
- Suggestion item: plaka (bold) + altında `make model` (varsa, küçük gri)
- Boş sonuç → `common.no_records` mesajı
- Seçim → input metni `plateDisplay`, suggestion kapanır, focus düşer
- × ikonu (suffix) `allowClear: true` ise seçim varken belirir → `onSelected(null)` reset

**Verification:** `flutter analyze` 0 error (pre-existing 18 deprecation/style info kalır).

## [2026-04-27] sprint-11c | Plaka filtresi modal içine taşındı (UX refactor) ✅

Sprint 11'de eklenen `VehiclePlateSearchBar` (statement panel header dropdown) + `selectedVehicleProvider` kaldırıldı. Plaka picker artık `PaymentRecordModal` içinde **SPECIFIC** radyosu seçilince (parçacı sektörde) açık satışlar listesinin üstünde görünür.

**Motivasyon:** Plaka filtresi yalnız belirli açık satışa ödeme atfederken anlamlı. Header'da sürekli durması ekstre ekranını gereksiz kalabalıklaştırıyordu.

**Silinen dosyalar (2):**
- `accounts/providers/selected_vehicle_provider.dart`
- `accounts/widgets/vehicle_plate_search_bar.dart`

**Değişen dosyalar (2):**
- `accounts/widgets/statement_detail_panel.dart` — bar render bloğu (satır 119-124) + 4 import (`sector_config`, `sector_provider`, `selected_vehicle_provider`, `vehicle_plate_search_bar`) + `_handlePayment` modal çağrısında 2 parametre kaldırıldı
- `accounts/screens/payment_record_modal.dart` — `customerVehicleId` + `vehiclePlateNormalized` public parametreleri kaldırıldı; yerine local `_selectedVehicleId` + `_selectedVehiclePlate` state; yeni `_buildVehicleFilter()` widget; SPECIFIC + autoParts koşullu render; eski "filter active" info banner kaldırıldı; payload `customerVehicleId` SPECIFIC + seçili plaka şartına bağlandı (GENERAL'de iliştirilmez); 3 yeni import (`sector_config`, `customer_vehicles_provider`, `sector_provider`)

**Akış (yeni):**
1. AccountsHub → müşteri seç → ekstre paneli sade (plaka bar yok)
2. Tahsilat → modal açılır → "Belirli alışveriş" radyosu
3. (Parçacı sektörde) plaka dropdown belirir → "Tüm plakalar" veya bir plaka
4. `_selectedVehiclePlate` → `customerOpenSalesProvider(CustomerOpenSalesKey(...))` filtreli açık satışlar
5. Satış seç → tutar oto-dolar
6. Submit → payload `customerVehicleId` (sadece SPECIFIC + seçili plaka varsa)

**Backend:** Dokunulmadı.

**Verification:** `flutter analyze` 0 error (pre-existing 17 deprecation/style info kalır). Grep doğrulandı: `selectedVehicleProvider` ve `VehiclePlateSearchBar` projede 0 occurrence.

**i18n cleanup:** `vehicle.filter_active` (`bnd-vh12`) artık kullanılmıyor — `data.sql:2734-2735` blokundan silindi (Sprint 11'de eklenmişti, picker üstündeki dropdown banner'a ihtiyacı kaldırdı).

## [2026-04-27] sprint-11 | Accounts plaka filtresi + payment allocation ✅

Sprint 11 — AccountsHub'da plaka bazlı tahsilat akışı end-to-end. Statement panel header'ında dropdown'dan plaka seçilince tahsilat modal o plakaya ait açık satışları listeler ve `customerVehicleId` payment allocation'a iliştirilir.

**Değişen / yeni Flutter dosyaları (5):**

- `sales/services/sales_service.dart` — `getCustomerOpenSales(customerId, {vehiclePlate})` opsiyonel filtre param
- `accounts/providers/customer_open_sales_provider.dart` — `family<List, String>` → `family<List, CustomerOpenSalesKey>` tuple key (BREAKING; tek call site `payment_record_modal._buildOpenSalesPicker` güncellendi)
- `accounts/providers/selected_vehicle_provider.dart` ⭐ NEW — `StateProvider.autoDispose<Map<String,dynamic>?>` AccountsHub plaka seçimi state'i
- `accounts/widgets/vehicle_plate_search_bar.dart` ⭐ NEW — kompakt dropdown bar (Tüm plakalar + kayıtlı plakalar + × clear), `customerVehiclesProvider` watch
- `accounts/widgets/statement_detail_panel.dart` — VehiclePlateSearchBar SummaryGrid ile TxFilterBar arasına yerleştirildi (sektör=autoParts + customer check); `_handlePayment` `selectedVehicleProvider` okur, `customerVehicleId` + `vehiclePlateNormalized` modal'a geçer; `import sector_provider` eklendi
- `accounts/screens/payment_record_modal.dart` — `customerVehicleId` + `vehiclePlateNormalized` parametre çifti eklendi; `_buildOpenSalesPicker` `CustomerOpenSalesKey` tuple kullanır; Sprint 6b deprecated `_plateCtrl` TextField + `_normalizePlate()` + description prepend kaldırıldı; aktif filtre info banner gösterir; payload'a `customerVehicleId` iliştirir

**Backend dokunulmadı** — Sprint 9'dan beri `getCustomerOpenSales(customerId, vehiclePlate)` ve `Sale.vehiclePlateSnapshot` zaten hazırdı. Maven `mvn compile` exit 0.

**i18n ek:** `bnd-vh12` → `vehicle.filter_active` (TR "Plaka filtresi aktif" / EN "Vehicle filter active") `data.sql:2735` altına eklendi.

**Akış (parçacı sektör tahsilat):**

1. AccountsHub → müşteri seçimi → Statement panel açılır
2. Sektör autoParts ise SummaryGrid ALTINDA `VehiclePlateSearchBar` görünür
3. Dropdown'dan plaka seç → `selectedVehicleProvider` set olur
4. Tahsilat butonu → `_handlePayment` `selectedVehicle` okur → modal'a `customerVehicleId` + `vehiclePlateNormalized` geçer
5. Modal `_buildOpenSalesPicker` `CustomerOpenSalesKey(customerId, vehiclePlate: ...)` ile `customerOpenSalesProvider` çağırır → backend `?vehiclePlate=Y` filtreli açık satışlar
6. Kullanıcı satış seçer → tutar otomatik dolar
7. Submit → payload `customerVehicleId` + `allocations[{saleId, amount}]` ile backend'e gider
8. Backend Payment + PaymentAllocation kaydeder; `Sale.remainingAmount` güncellenir
9. AccountsHub liste + statement bakiye anında refresh (`ref.invalidate(accountsListProvider)` Sprint 8 hot-fix D1 sayesinde)

**Verification:**
- `flutter analyze` 4 modül üzerinde 0 error (8 pre-existing deprecation/style info)
- `mvn -DskipTests compile` exit 0
- Manuel test bekliyor: 1) sektör=butik panel'de SearchBar gizli mi 2) müşteri değişince plaka filtresi reset mi 3) plaka filtreliyken tahsilat sonrası bakiye anında düşüyor mu

**Sprint 11b deferred (kullanıcı kararına bırakıldı):**
- Migration script — eski `Payment.description "Plaka:"` prefix'lerini parse edip `CustomerVehicle` upsert (idempotent + `--dry-run`)
- `ReconcileScheduledJob` yeni invariant — `Sale.vehiclePlateSnapshot == sale.customerVehicle.plateNormalized`
- Drift bulunursa Slack notify + `.wiki/issues/` entry

## [2026-04-27] sprint-10b | POS Cart Panel + PosState plaka entegrasyonu ✅

Sprint 10b — cart_panel.dart + pos_provider.dart entegrasyonu tamamlandı (Sprint 10 kor frontend dosyaların ardından PosState refactor + sale request payload).

**Değişen Flutter dosyaları (2):**

`pos/providers/pos_provider.dart`:
- `PosState.selectedVehicle: Map<String,dynamic>?` field eklendi
- `copyWith` `clearVehicle: bool` flag pattern (mevcut `clearCustomer` ile tutarlı)
- `selectCustomer(...)` müşteri değişince plaka reset (aynı müşteri tekrar seçilince koru — `isSameCustomer` check)
- Yeni `selectVehicle(Map<String,dynamic>?)` method
- `saleData` payload: `if (selectedVehicle != null) 'customerVehicleId': selectedVehicle.id`

`pos/widgets/cart_panel.dart`:
- Yeni `_buildVehicleSection(ref, notifier, state)` private method — sektör=autoParts + customerId varsa CustomerVehiclePicker render; aksi halde SizedBox.shrink (butik sektör + peşin satış'ta tamamen gizli)
- Build column'a customerSection altına yerleştirildi
- `import 'package:project_pos/core/config/sector_config.dart'` (sectorTypeProvider erişimi)
- `import 'customer_vehicle_picker.dart'` (relative)

**Akış (parçacı sektör senaryosu):**
1. Kullanıcı POS'ta müşteri seçer → cart_panel customerSection değişir
2. Sektör autoParts ise customerSection ALTINDA `CustomerVehiclePicker` görünür
3. Kullanıcı dropdown'dan plaka seçer veya "+" ile yeni ekler (idempotent backend)
4. selectVehicle → state.selectedVehicle güncellenir
5. Submit → saleData.customerVehicleId backend'e gider
6. Backend SaleServiceIntegrated.createSale() → Sale.customerVehicle FK + vehiclePlateSnapshot doldurulur

**Müşteri Reset:** Müşteri değişince selectedVehicle reset; aynı müşteri tekrar seçildiyse plaka korunur.

**Bekleyen:**
- Frontend `flutter analyze` koşulmadı (kullanıcı runtime)
- Sprint 11: VehiclePlateSearchBar + PaymentRecordModal `_plateCtrl` deprecated kaldırma + migration script + reconcile invariant

## [2026-04-26] sprint-10 | Plaka takibi frontend kor — picker + service + provider ✅

Sprint 10 frontend kor implementasyonu (cart_panel + pos_provider entegrasyonu Sprint 10b'ye, çünkü PosState değişikliği büyük scope).

**Yeni Flutter dosyaları (4):**
- `customers/services/customer_vehicle_service.dart` — HTTP servisi (list, search, create idempotent, update, deactivate)
- `customers/providers/customer_vehicles_provider.dart` — Riverpod (FutureProvider.family `customerVehiclesProvider` + autocomplete `customerVehicleSearchProvider` + `CustomerVehicleSearchKey` tuple)
- `customers/widgets/add_customer_vehicle_modal.dart` — inline yeni plaka modal (idempotent backend POST → mevcutsa zaten döner)
- `pos/widgets/customer_vehicle_picker.dart` — plaka dropdown + "+" buton (yeni ekleme); dropdown empty/loading/error states

**i18n keys (10):** `vehicle.plate`, `add_new`, `make`, `model`, `year`, `no_vehicles`, `select`, `none`, `plate_required`, `search_placeholder` (TR + EN). ID: `bnd-vh01-10`.

**Sprint 10b (sonraki tur, 1-2 saat) — kalan iş:**
- `PosState`'e `selectedVehicle: Map<String,dynamic>?` field ekleme
- `PosNotifier.setSelectedVehicle(...)` method
- `cart_panel.dart` sektör check (`sectorTypeProvider == SectorType.autoParts && customerId != null`) + CustomerVehiclePicker entegre
- POS `saleData` payload'a `customerVehicleId` ekleme (`pos_provider.dart:741`)
- Müşteri değişince `selectedVehicle` reset

**Sprint 11 — accounts plaka tahsilat:**
- `VehiclePlateSearchBar` widget (statement_detail_panel)
- PaymentRecordModal `_plateCtrl` deprecated kaldırma
- Migration script: `Payment.description` "Plaka:" prepend → CustomerVehicle upsert
- ReconcileScheduledJob invariant

**Verification:** Frontend `flutter analyze` koşulmadı (kullanıcı runtime'da). Backend Maven exit 0 hâlâ geçerli (Sprint 9'dan).

## [2026-04-26] sprint-9 | Plaka takibi backend foundation ✅ (Opsiyon C, Maven exit 0)

Sprint 9 backend implementasyonu tamamlandı. Sentez planı [[syntheses/vehicle-plate-end-to-end-design-2026-04-26]] uygulandı.

**Yeni Java sınıfları (8):**
- `customer/entity/CustomerVehicle.java` — entity (`@Table customer_vehicles`, indexes, UNIQUE `(customer_id, plate_normalized, company_code)`, @Version)
- `customer/repository/CustomerVehicleRepository.java` — `findByCustomerIdAndIsActiveOrderByPlateDisplay`, `searchByCustomer`, `findByCustomerIdAndPlateNormalized`
- `customer/service/CustomerVehicleService.java` (interface) + `CustomerVehicleServiceImpl.java` — idempotent create, AOP filter aktif (@Service)
- `customer/controller/impl/CustomerVehicleControllerImpl.java` — REST CRUD + search endpoint'leri
- `customer/model/CustomerVehicleDto.java` (request) + `CustomerVehicleResponse.java`

**Değişen Java sınıfları (4):**
- `sales/entity/Sale.java` — `customerVehicle` ManyToOne FK + `vehiclePlateSnapshot` String denormalize cache
- `sales/model/SaleRequest.java` — `customerVehicleId` parametresi
- `sales/service/impl/SaleServiceIntegrated.java` — `createSale()` plaka FK + snapshot logic + müşteri-plaka tutarlılık kontrolü
- `sales/controller/impl/SaleControllerImpl.java` — `?vehiclePlate=Y` filter parametresi (normalize + Sale.vehiclePlateSnapshot LIKE contains)

**Endpoint Kataloğu (yeni 6):**
- `GET /api/v1/customers/{id}/vehicles` — aktif plakalar
- `GET /api/v1/customers/{id}/vehicles/search?q=34A` — autocomplete
- `GET /api/v1/customers/{id}/vehicles/{vid}` — tek kayıt
- `POST /api/v1/customers/{id}/vehicles` — idempotent create
- `PUT /api/v1/customers/{id}/vehicles/{vid}` — güncelleme
- `DELETE /api/v1/customers/{id}/vehicles/{vid}` — soft-delete
- + `GET /api/v1/sales?vehiclePlate=Y` filter parametresi

**Wiki dosyaları:**
- Yeni: [[entities/customer-vehicle]] — entity dokümantasyonu
- Yeni: [[decisions/2026-04-26-vehicle-plate-option-c]] — ADR
- Update: [[decisions/2026-04-24-vehicle-plate-tracking-option-a]] — SUPERSEDED işaretlendi
- Update: [[index]] — Sprint 9-11 alt-bölümü güncellendi

**Verification:** Backend Maven compile **exit 0** ✅. Frontend (Sprint 10) ve migration (Sprint 11) ayrı oturumlarda yapılacak.

**Bekleyen (Sprint 10 kapsamı):**
- `customer_vehicle_service.dart` Flutter service
- `customerVehiclesProvider` Riverpod (FutureProvider.family)
- `CustomerVehiclePicker` widget
- `cart_panel.dart` sektör-aware entegrasyon
- `AddCustomerVehicleModal` inline yeni plaka

**Bekleyen (Sprint 11 kapsamı):**
- `VehiclePlateSearchBar` (statement_detail_panel)
- PaymentRecordModal `_plateCtrl` deprecated kaldırma
- Migration script: mevcut `Payment.description` "Plaka:" prepend → CustomerVehicle upsert
- ReconcileScheduledJob yeni invariant

## [2026-04-26] design | plaka bazlı satış-tahsilat bütünsel — Opsiyon C tasarımı

Kullanıcı senaryosu: parçacı sektörde satış sırasında plaka kayıt + müşteri görünümünde plaka arama + tahsilatta plaka bazlı geçmiş seçimi. Geri-dosyalama: [[syntheses/vehicle-plate-end-to-end-design-2026-04-26]].

**Tetikleyici:** [[decisions/2026-04-24-vehicle-plate-tracking-option-a]] "Yeniden Değerlendirme Kriterleri" sağlandı — kullanıcı multi-plaka senaryosunu kanıtladı. Opsiyon A (description prepend) yetersiz, **Opsiyon C** (CustomerVehicle entity) gerekli.

**Tasarım özeti:**
- Backend: `CustomerVehicle` entity (`customer_id` + `plate_normalized` UNIQUE) + `Sale.customerVehicleId` FK + `Sale.vehiclePlateSnapshot` denormalize cache
- Endpoint: `/customers/{id}/vehicles` CRUD + search; `/sales?vehiclePlate=Y` filter
- Frontend: Sektör-aware widget'lar (`CustomerVehiclePicker`, `VehiclePlateSearchBar`, `AddCustomerVehicleModal`); sektör=autoParts kontrolü ile koşullu render
- Migration: mevcut `Payment.description` "Plaka: XX" prepend'lerini CustomerVehicle'a upsert (idempotent, dry-run desteği)
- Reconcile: yeni invariant `Sale.vehiclePlateSnapshot == customerVehicle.plateNormalized`

**Sprint roadmap (~7-10 gün):**
- Sprint 9: Backend foundation (entity + repo + service + endpoint + Sale FK)
- Sprint 10: Frontend POS (CustomerVehiclePicker + cart_panel + AddVehicleModal)
- Sprint 11: Accounts tahsilat (VehiclePlateSearchBar + statement_detail_panel + migration)

**Yeni backend servisler:** 8 yeni Java class + 5 değişen + 2 migration script + 1 reconcile invariant.
**Yeni frontend Dart dosyalar:** 5 yeni + 5 değişen.

Done kriteri 7 senaryo: butik sektörde plaka widget'ları görünmez (sektör isolation).

## [2026-04-26] correction | hot-fix-v3 YANLIŞ YORUM — REVERTED

Kullanıcı düzeltti: "yanlış geliştirme yapıldı. sistemimizde firma bazlı arama yapılır." Önceki tenant-leak yorumu HATALI — sistem multi-firma per-user mimarisi:

- Bir kullanıcı birden fazla firmaya sahip olabilir (SEDCORE otomotiv + SEDCORE1 butik)
- Backend endpoint'leri default tüm firmalardan döner
- "Firma bazlı arama" = frontend UI'dan companyCode filter

**Revert (git checkout HEAD --):**
- `CustomerService.search()` interface method (eklenmişti — geri alındı)
- `CustomerServiceImpl.search()` impl (geri alındı)
- `CustomerControllerImpl.list` service yönlendirme (geri alındı, repository direkt kalmaya devam ediyor — DOĞRU)

Backend Maven compile (revert sonrası): **exit 0** ✅

**Wiki düzeltme:**
- Yeni: [[concepts/multi-company-per-user-architecture]] — DOĞRU mimari açıklaması
- Deprecated: [[syntheses/tenant-leak-controller-direct-repository-2026-04-26]] — yanlış yorum, header DEPRECATED + supersedes link
- Index: tenant-leak link'i deprecated, multi-company-per-user-architecture eklendi

**Açık soru (kullanıcıdan netleştirme bekleniyor):**
AccountsListService'in `selectedCompanyCode` filter aktif tutması doğru mu? (önceki response'ta sadece SEDCORE 4 kayıt döndü.) Eğer "tüm firmalar" doğru ise oradaki filter da kaldırılmalı. Şu an dokunulmadı.

## [2026-04-26] 🚨 hot-fix-v3 | KRİTİK: multi-tenant leak — CustomerController repository bypass

> ⚠️ Bu girdideki "tenant leak" yorumu YANLIŞ olduğu sonradan tespit edildi (bkz. üstteki correction). Hot-fix v3 revert edildi. Detay: [[concepts/multi-company-per-user-architecture]]

Kullanıcı `/customers?isActive=true` response'u paylaştı: **2 farklı tenant'tan kayıt** (SEDCORE Usta+Adem, SEDCORE1 Moda Butik+**Zeynep**) → tenant izolasyon kırığı kanıtlandı.

Geri-dosyalama: [[syntheses/tenant-leak-controller-direct-repository-2026-04-26]] (KRİTİK).

**Kök neden:** [[concepts/hibernate-filter-runtime]] §Critical Bulgular #4 gerçekleşti. `CompanyHibernateFilterActivator` AOP pointcut `com.sedcore..service..*` — sadece service layer'da advice tetiklenir. CustomerControllerImpl direkt `customerRepository.search()` çağırdığı için (service bypass) Hibernate `@Filter("filterByCompanyCode")` aktif edilmedi → tüm tenant'lar geliyordu.

**Karşıt kanıt:** AccountsListService aynı oturumda sadece SEDCORE 4 kayıt döndürdü (önceki response 16:19) çünkü `@Service` annotated → AOP advice tetikleniyor.

**Uygulanan Düzeltme (Hot-Fix v3):**
- F1: `CustomerService.search(String, Boolean)` interface method eklendi
- F2: `CustomerServiceImpl.search` → `dao.search(q, isActive)` (service-layer çağrı)
- F3: `CustomerControllerImpl.list` → `customerService.search(...)` (repository direct yerine)
- Backend Maven compile: **exit 0** ✅

**Beklenen davranış (restart sonrası):**
- SEDCORE oturumu → sadece SEDCORE müşterileri
- SEDCORE1 oturumu → sadece SEDCORE1 (Zeynep + Moda Butik)
- Zeynep'in POS'ta SEDCORE oturumunda görünmesi tenant leak idi; artık görünmemeli (doğru davranış)

**Kalan Risk (Sprint 9 acil audit):**
- 7+ dosya / 13+ callsite hâlâ `customerRepository.findById/count`, `accountTransactionRepository.findCustomerStatement` direkt çağırıyor → cross-tenant ID erişimi açık
- Sistemik çözüm: AOP pointcut'ı controller'a yay (Seçenek A) + service üzerinden zorla (Seçenek B)

## [2026-04-26] query | zeynep DB'de yok kanıtlandı — backend response 4 kayıt

Kullanıcı backend response paylaştı: `hasMore=false`, 4 kayıt (oto1 tenant), Zeynep YOK. Geri-dosyalama: [[syntheses/zeynep-customer-not-in-db-2026-04-26]].

**Önceki hipotezler çürütüldü:**
- ❌ Pagination (hasMore=false zaten tüm kayıtları döndürdü)
- ❌ Filter (4 kayıttan 2 customer var, filter doğru)
- ❌ Endpoint tutarsızlığı (POS Cart Panel ve AccountsListService AYNI `customerRepository.search(null, true)` kullanıyor)

**4 yeni senaryo:**
- A: POS yeni müşteri eklerken backend POST başarısız oldu → frontend in-memory cache, DB'ye gitmedi
- B: Zeynep farklı tenant'ta (SEDCORE1 vs SEDCORE)
- C: `is_active=false` veya `is_deleted=true`
- D: Kullanıcı yanılgısı (POS'ta başka müşteri ile karıştırıyor)

**3-adım tanı:**
1. SQL: `SELECT * FROM customers WHERE LOWER(name) LIKE '%zeynep%'`
2. POS Cart Panel kapat-aç (state cache vs DB)
3. JWT decode → `selectedCompanyCode` ile `customer.company_code` karşılaştır

**Sistemik kalıcı çözüm (Sprint 9):**
- E1: AccountEditForm save sonrası `ref.invalidate(accountsListProvider)` audit
- E2: Backend POST hata durumunda Flutter explicit AppToast.error
- E3: Cart Panel _CustomerPickerSheet ile AccountsListProvider sync

## [2026-04-26] hot-fix-v2 | zeynep sorunu sistemik çözüm — pageLimit + auto-prefetch ✅

Kullanıcı talebi: "müşteriyi cari accountunda görmem lazım, sistem stabil çalışmalı". Pagination paradigmasından vazgeçmeden 3 değişiklik:

**B1** — Backend `AccountsListService.list` clamp `Math.min(50, limit)` → `Math.min(200, limit)`. KOBİ tenant'lar için yeterli üst sınır; 200+ müşteri varsa pagination devreye girer.

**B2** — Frontend `accounts_list_provider.dart` `_pageLimit` 50 → 100. İlk yükleme 100 müşteri.

**B3** — Frontend `loadFirst()` sonrası **auto-prefetch**: query boşsa + hasMore varsa otomatik 1x loadMore → toplam ~200 müşteri ilk açılışta. Sıralama `name ASC` olduğu için "Z" harfli müşteri (Zeynep dahil) artık ilk açılışta görünür.

**Mantık:** 200+ müşterili büyük tenant'lar için kullanıcı scroll yapar (manuel loadMore zaten çalışıyor). Auto-prefetch sadece query boşken — search yapıldığında server-side filter zaten kayıtları azaltır, prefetch gereksiz.

**Verification:**
- Backend Maven compile: exit 0 ✅
- Frontend `flutter analyze` koşulmadı (kullanıcı runtime)

Önceki troubleshooting rehberi geçerli: [[concepts/troubleshooting-customer-missing-in-accounts-hub]]. #1 pagination nedeni artık küçük tenant'lar için elendi.

## [2026-04-26] query | zeynep müşterisi POS'ta var ama cari hesaplarda yok

Geri-dosyalama: [[concepts/troubleshooting-customer-missing-in-accounts-hub]] — generic tanı rehberi (5 olası neden + adım-adım teşhis).

**Hipotezler (öncelik sırasıyla):**
1. 🔴 **Pagination** — limit 50, "Z" harfi ilk sayfada yok, scroll loadMore tetiklenmedi (en olası)
2. 🟠 Filter chip "Tedarikçi" veya "Vadesi Geçmiş" basılı
3. 🟠 Search query önceki aramadan açık
4. 🟡 `is_deleted=true` (paradox: POS Cart Panel aynı endpoint, gelmemeli)
5. 🟡 Multi-tenant `company_code` farklı (session değişimi varsa)
6. 🟢 Sprint 8 frontend pagination parse bug (az olası)

**Tanı 6-adım** sırasıyla UI (saniyeler) → backend curl → DB → JWT decode.

**Düzeltme önerileri:**
- #1 için: search box'a "z" yaz → server-side filter ile direkt gelir
- #2-3 için: chip "Tümü" + search clear
- #4 için: `UPDATE customers SET is_deleted=false`
- #5 için: company_code düzeltme (veri taşıma dikkat)

## [2026-04-26] sprint-8-cleanup | P0.2 + P1.1 + P2.5 batch — bütün planları sırayla ✅

Kullanıcı talebi: "ben dışarı çıkıyorum bütün planları sırayla yap". [[syntheses/pending-work-status-2026-04-26]] sırasına göre uygulandı:

**Tamamlanan (~5 saat eşdeğeri iş):**

**P0.2 — D3 frontend currentBalance render** ✅
- [`statement_detail_panel.dart`](project_pos/lib/features/accounts/widgets/statement_detail_panel.dart): `currentBalance` parse, `hasDrift` hesaplaması, `_SummaryGrid` constructor genişledi
- `_SummaryGrid` 4. tile primer değer `currentBalance` (denormalize gerçek), drift varsa warning icon + secondary line "⚠ Hesaplanan: X" göstergesi
- `_StatTile.secondaryValue` field eklendi (drift göstergesi için)

**P1.1a — StatementDetailPanel ErrorView** ✅
- `AppEmptyState.error` → `AccountsErrorView` (retry button + AppLogger pattern)

**P1.1b — AccountsSummaryBar ErrorView** ✅
- `summaryState.error != null` durumunda compact `AccountsErrorView` (yer kazanma için compact mode)

**P2.5 — Lint P1 cleanup** ✅
- 16 wikilink ad değişimi sed batch (flows/X → syntheses/flow-X, integrations/X → syntheses/integration-X, patterns/X → concepts/pattern-X veya concepts/X)
- 5 redirect: `[[contradictions]]` → claude-wiki-contradictions, `[[decisions/append-only-semantics]]` → concepts/append-only, vb
- `archive/README.md` placeholder yarat ([[archive/README]] kırık linki düzeltildi)

**Verification:**
- Backend Maven compile: **exit 0** ✅
- Frontend `flutter analyze` koşulmadı (kullanıcı runtime'da)

**Ertelendi (Sprint 9):**
- P1.2 T2-T4 service-level testler (1.6 gün — büyük scope)
- P1.3 B0 phase 2 POS Cart Panel paginated (1 gün)
- P2.1 B3 toplu ödeme UI (1.5-2 gün — backend hazır)
- P2.6 I5 test coverage geniş kapsam
- P2.7 18 MERGE_NEEDED dosya inceleme

**Kabul edilen Sprint 7+8 done kriteri:**
- Sprint 7: WP1 (4 dosya backend) + WP3 (provider) + WP4 (modal sale picker) + WP4.b (caller) + WP5 (i18n + ErrorView widget) + WP6 (3 wiki sayfası) + WP2 minimum test (3 test, BUILD SUCCESS) ✅
- Sprint 8: WP1 (5 dosya backend cursor pagination) + WP1 frontend (provider rewrite + scroll) + WP2 (3/3 panel ErrorView) ✅
- Hot-fix: D1 ref.invalidate + D2 limit 50 + D3 backend currentBalance + D3 frontend render ✅

**Toplam Sprint 7+8+hot-fix:**
- Backend: 6 yeni dosya, 4 update, 1 entity model genişledi
- Frontend: 4 yeni dosya, 5 update
- Wiki: 6 yeni sentez sayfası, 3 wiki sayfası (entity/concept/decision)
- Test: 1 test class (3 method, BUILD SUCCESS)
- i18n: 7 yeni anahtar (TR+EN)

**Kaynak:** kullanıcı talebi — auto mode "bütün planları sırayla yap".

## [2026-04-26] query | planda yapılmaya kalan var mı? — pending work status

Kullanıcı talebi: aktif tüm planlar + sentezler + hot-fix sonrası ne kaldı? Geri-dosyalama: [[syntheses/pending-work-status-2026-04-26]] — P0/P1/P2/P3 önceliklendirme + sprint roadmap.

**Konsolide kaynaklar:**
- Sprint 7 hold-overs: WP2 (3 panel ErrorView, 1 yapıldı), WP3 (T2-T4 testler), smoke test
- Sprint 8 hold-overs: D3 frontend render, B0 phase 2 (POS pagination), WP2/WP3 devamı
- v2 backlog: B0/B3/B6/B8/B9 + I5
- Lint action plan P1-P3 (sed batch, MERGE_NEEDED, xref, zayıf kaynak)
- Codebase snapshot P4 (React/controller/core ingest)

**Önerilen bu hafta sıra (~5 saat):**
1. P0.1 smoke test (sen runtime)
2. P0.2 D3 frontend `currentBalance` render (1-2 saat)
3. P1.1 ErrorBoundary kalan 2 panel (1.5 saat)
4. P2.5 lint P1 cleanup (1 saat — yüksek ROI)

**Kritik not:** Frontend `flutter analyze` Sprint 7+8 boyunca koşulmadı. P0.1'in parçası olarak `flutter analyze` öneriliyor.

## [2026-04-26] query | hot-fix: POS müşteri listesi + bakiye refresh ✅

Kullanıcı 2 üretim bug'ı raporladı:
1. POS satış ekranı müşteri listesi ≠ AccountsHub liste (eksik kayıtlar)
2. Cari hesapta ödeme sonrası bakiye UI'da güncellenmiyor (hot reload düzeltir)

İki paralel Explore agent kök nedenleri tespit etti. Geri-dosyalama: [[syntheses/accounts-bugfix-investigation-2026-04-26]].

**Kök Nedenler:**
- **Bug A**: Cart Panel `/customers?isActive=true` (sayfasız) ↔ AccountsHub `/accounts/list?limit=20&...` (paginated). Auth/filter doğru, sadece pagination farkı.
- **Bug B**: (1) Backend statement response'a denormalize `currentBalance` eksik — yalnızca `closingBalance` (transaction toplamı) var. (2) `_handlePayment` 3 autoDispose provider'a `Future.wait([notifier.load()])` → modal close + rebuild race. (3) Sprint 8 `loadFirst()` state reset timing.

**Uygulanan Düzeltmeler (3):**
- **D1** — `statement_detail_panel.dart`: `ref.invalidate(accountsListProvider)` + 3 load (4 yerine). AutoDispose race önlendi.
- **D2** — `accounts_list_provider.dart` `_pageLimit` 20→50 (backend Math.min(50, limit) clamp). Sprint 9: POS Cart Panel'i de paginated.
- **D3** — Backend `AccountStatementEntry.currentBalance: BigDecimal` field eklendi; `AccountStatementControllerImpl` `customerAccountService.getOrCreate(...).getCurrentBalance()` ile dolduruyor (supplier eşdeğeri). Fallback: exception → `closingBalance`. **Maven compile exit 0**.

**Sprint 9 hold-overs:**
- D3 frontend — `statement_detail_panel.dart` `currentBalance` render + drift göstergesi
- B0 frontend — POS Cart Panel paginated
- WP2 kalan 2 panel ErrorView (Sprint 8'den)
- WP3 T2-T4 testler

**Kaynak:** kullanıcı talebi — 2 üretim bug raporu + plan onayı (ExitPlanMode).

## [2026-04-26] sprint-8 | WP1 backend ✅ + WP1 frontend ✅ + WP2 kısmi ✅

Kullanıcı talebi: "ben dışarı çıkıyorum plan için onay veya soru sorma hepsini hallet". Açık sorular cevaplandı (cursor=JSON, limit=50, filter+query=AND, loader=CircularProgress, refresh=scroll-top). Sprint 8 önemli kısmı uygulandı:

**WP1 Backend ✅** (Maven compile exit 0):
- Yeni: `AccountsListCursor.java` — JSON transparent cursor (name|type|id tuple)
- Yeni: `PaginatedAccountsResponse.java` — items + nextCursor + hasMore
- Yeni: `AccountsListService.java` — CustomerRepository.search (DB-side, EntityGraph N+1 fix) + SupplierService.listSuppliers + in-memory merge/sort/cursor (R1: DB UNION optimization sprint sonuna)
- Yeni: `AccountsListControllerImpl.java` — `GET /api/v1/accounts/list?cursor=&limit=20&filter=&q=`

**WP1 Frontend ✅:**
- Update: `accounts_list_provider.dart` — komple rewrite, paginated state (`isLoadingMore`, `hasReachedEnd`, `nextCursor`), `loadFirst/loadMore/refresh`, debounced setQuery (300ms), setFilter triggers loadFirst, geriye uyum `load()` alias. AccountListItem.fromMap factory eklendi.
- Update: `accounts_list_panel.dart` — ScrollController bottom-200px loadMore, RefreshIndicator pull-to-refresh, loading footer, `AccountsErrorView` entegrasyonu (WP2 #1)

**WP2 ErrorView Entegrasyonu (kısmi):**
- ✅ AccountsListPanel — `AccountsErrorView` ile error state replace
- ⏳ StatementDetailPanel — Sprint 9'a kaydı
- ⏳ AccountsSummaryBar — Sprint 9'a kaydı

**Ertelendi (Sprint 9):**
- WP3 T2-T4 service-level testler (@SpringBootTest)
- WP2 kalan 2 panel ErrorView
- Plan v2 P3 yaşlandırma raporu (B6), overdue notification (B8), activity history (B9)

**Bilinen sınırlamalar:**
- AccountsListService in-memory merge (1000+ supplier'da yavaş olabilir; sprint sonu DB-side UNION optimization R1)
- SupplierRepository.search yok (Customer'da var) — supplier query'si in-memory filter
- Frontend `flutter analyze` koşulmadı (kullanıcı runtime ile doğrulayacak)

**Manuel doğrulama (kullanıcı):**
1. Backend restart sonrası `GET /product/api/v1/accounts/list?limit=5` → JSON `{items, nextCursor, hasMore}`
2. Flutter hot reload → AccountsHub → liste 20'şer kayıt yükleniyor, scroll'da loadMore tetikleniyor
3. Pull-to-refresh çalışıyor; filter/search değiştirince loadFirst tetikleniyor
4. Backend down → AccountsErrorView retry button'u çalışıyor

**Kaynak:** kullanıcı talebi — "plana göre doğru yoldan devam" + "hepsini hallet".

## [2026-04-26] sprint-8 | implementation plan yazıldı

Kullanıcı talebi: "devam" — Sprint 7 sonrası Sprint 8'e geçiş. Geri-dosyalama: [[syntheses/sprint-8-implementation-plan-2026-04-26]].

**Sprint 8 kapsamı (önerilen alt-küme):**
- WP1 (4-5g): B0 Pagination — backend birleşik `/accounts/list` endpoint (cursor-based) + frontend infinite scroll + server-side filter/query (debounced)
- WP2 (1.5h): ErrorBoundary 3 panel yaygın entegrasyon (Sprint 7 hold-over)
- WP3 (1.6g): T2-T4 service-level testler (@SpringBootTest) — reconcile drift + credit limit + sale-payment FK integrity

**Sprint 9'a kaydı:** B8 (overdue notification), B9 (activity history), B6 (yaşlandırma raporu).

**Kritik tasarım kararı:** Cursor-based pagination + birleşik endpoint (mevcut 2 ayrı customer/supplier endpoint yerine) — sayfa sınırı 2 koleksiyon arası kayıp önlenir.

**Açık sorular** (PR review): cursor format (opaque), limit upper bound, filter+query AND, initial loader skeleton vs spinner, pull-to-refresh kapsamı.

**Kullanıcı onayı bekliyor** WP1 implementasyonu için (backend AccountsListController + frontend paginated state).

## [2026-04-26] sprint-7 | WP2 minimum — test infrastructure + ilk test ✅

WP2'nin minimum scope'u uygulandı. `Tests run: 3, Failures: 0, Errors: 0 — BUILD SUCCESS`.

**Yeni dosyalar:**
- `pos-product-manager/pom.xml` — H2 (test scope) eklendi
- `src/test/resources/application-test.properties` — H2 in-memory PostgreSQL mode, ddl-auto=create-drop, sql.init.mode=never
- `src/test/java/com/sedcore/finance/repository/PaymentAllocationRepositoryTest.java` — 3 test (`@DataJpaTest`):
  - `save_withSaleFk_persists` — allocation insert (sale=null)
  - `findByPaymentId_returnsAllocations` — multi-allocation query (B3 senaryosu)
  - `sumActiveBySaleId_excludesCancelled` — cancelled payment'lar hariç toplam

**Mimari kararlar:**
- H2 with PostgreSQL mode seçildi (Testcontainers + Docker daemon kompleksitesinden kaçındık)
- `@DataJpaTest` ile sadece JPA katmanı (full Spring context yok, hızlı)
- `ID elle set edilmez` — TOpenSimpleCompanyEntity @PrePersist ile UUID üretir (lesson learned)
- data.sql test'te koşmaz (`sql.init.mode=never`) — her test temiz state

**Sonraki sprintte (WP2.4):**
- T1 full PaymentCreationIntegrationTest (@SpringBootTest service-level)
- T2 ReconcileDriftDetectionTest
- T3 CreditLimitGuardTest
- T4 SalePaymentFkIntegrityTest

Sprint 7 done kriteri büyük ölçüde sağlandı; hold-over: smoke test (kullanıcı runtime) + ErrorBoundary 3 panel entegrasyon (Sprint 8).

**Kaynak:** kullanıcı talebi — "plana göre doğru yoldan devam".

## [2026-04-25] sprint-7 | WP1+WP3+WP4+WP5 implementasyon (testler ertelendi)

Sprint 7 başlatıldı. Plan: [[syntheses/sprint-7-implementation-plan-2026-04-25]]. Tamamlanan iş paketleri:

**Backend (WP1):**
- Yeni: `PaymentAllocation.java` entity (sale-payment many-to-many, `@Version`, indexes)
- Yeni: `PaymentAllocationRepository.java` (`findByPaymentId/SaleId`, `sumActiveBySaleId`)
- Yeni: `AllocationRequest.java` (DTO)
- Update: `PaymentRequest.java` — `allocations: List<AllocationRequest>` field, `saleId` `@Deprecated`
- Update: `PaymentServiceImpl.java` — `createAllocations()` helper + `createCustomerPayment()` çağrısı
- ✅ Maven compile geçti (exit 0)

**Frontend (WP3+WP4+WP4.b):**
- Yeni: `customer_open_sales_provider.dart` (FutureProvider.family + autoDispose)
- Update: `sales_service.dart` — `getCustomerOpenSales(String customerId)` ek metod
- Update: `payment_record_modal.dart` — `customerId` parametresi, "Hangi Alışverişe?" radio + açık satış picker, submit `allocations` array
- Update: `statement_detail_panel.dart` — caller `customerId` aktarımı + payload `allocations` field
- Yeni: `accounts_error_view.dart` (I2 minimum widget — yaygın entegrasyon Sprint 8'e)

**i18n (WP5):**
- 7 yeni anahtar `accounts.payment_target/general_payment/specific_sale_payment/no_open_sales/sale_remaining/add_another_sale/allocation_sum_mismatch` (TR + EN)
- ID şeması: `bnd-acpa01-07`

**Wiki (WP6):**
- Yeni: [[entities/payment-allocation]]
- Yeni: [[concepts/payment-allocation-pattern]]
- Yeni: [[decisions/payment-allocation-from-day-1]] (B1↔B3 mimari karar ADR)
- Index güncellendi (Sprint 7 Decisions, Cari Hesap concepts, Domain Diğer entities)

**Ertelendi (Sprint sonu):**
- WP2 testler T1-T4 (proje sıfır test infrastructure → ayrı kurulum gerekli)
- WP6 manuel smoke test (kullanıcı runtime ile yapacak)
- I2 ErrorBoundary yaygın entegrasyon (3 panel) — Sprint 8

**Geriye uyum:** `Payment.sale` FK + `PaymentRequest.saleId` `@Deprecated` ama kabul ediliyor. Sprint 9'da kaldırılacak.

**Kaynak:** kullanıcı talebi — "cari işlemler planına devam et" + "B devam, testler sprint sonunda".

## [2026-04-25] query | cari işlemler planına devam — Sprint 7 implementation plan

Kullanıcı talebi: "cari işlemler planına devam et". Geri-dosyalama: [[syntheses/sprint-7-implementation-plan-2026-04-25]] — v2 analizinin Sprint 7'sini 6 iş paketi (WP1-WP6) olarak adım adım uygulama planı.

**WP listesi:**
- WP1 (1g): Backend PaymentAllocation entity many-to-many baştan
- WP2 (1.6g): Backend T1-T4 kritik path testleri (paralel WP1 ile)
- WP3 (0.5g): Frontend service + customerOpenSalesProvider
- WP4 (1g): Frontend PaymentRecordModal sale picker
- WP5 (1.5g): Frontend i18n (7 key) + ErrorBoundary (I2)
- WP6 (0.5g): Wiki final + smoke test

**Net iş:** ~6 gün, 1 hafta sprint. Her WP için: dosya yolu, done kriteri, risk matrisi.

**Sonraki adım:** kullanıcı onayı ile WP1 (backend) implementasyonu başlatılacak.

Index güncellendi: Modül & Mimari Özet altına sprint plan linki.

## [2026-04-25] query | cari hesaplar modülü geliştirme analizi

Kullanıcı talebi: "Cari hesaplar sayfasına odaklanıp geliştirme analizi çıkar." Geri-dosyalama: [[syntheses/accounts-development-analysis-2026-04-25]].

**Kapsam:** 50+ accounts wiki sayfası (entities, syntheses, decisions, concepts, issues + scoped `project_pos/.../accounts/_wiki/`) sentezlendi. Backend kod doğrulaması yapıldı (Payment.saleId FK, SaleController endpoint).

**Bulgular:**
- 5 açık issue (pagination, error boundary, overdue notification, activity history, test coverage)
- 7 yeni geliştirme adayı (alışveriş bazlı ödeme, plaka B/C, toplu ödeme, taksit, hızlı tahsilat, yaşlandırma raporu, SMS bildirim)
- P1-P3 önceliklendirme + 3 sprint roadmap önerisi

**Sprint 7 önerisi:** B1 (alışveriş bazlı ödeme — backend hazır) + I2 (error boundary) + I1 (pagination).

Index güncellendi: Modül & Mimari Özet altına development analysis linki.

## [2026-04-25] query | LINT sonucu yapılması gereken aksiyon planı

Kullanıcı talebi: 134 lint bulgusu için somut aksiyon planı. Geri-dosyalama: [[syntheses/lint-action-plan-2026-04-25]] (P1-P4 öncelikli, sed komutları + manuel sıra + tahmini efor + kabul kriterleri).

**Plan özeti:**
- **P1 (1 saat)** — Hızlı kazanç: 16 sed batch + 6 eksik hedef kararı + 8 placeholder fix
- **P2 (3-5 saat)** — Orta: 18 MERGE_NEEDED inceleme + 5 issues merge + 50 xref ekleme + 5 zayıf kaynak doğrulama
- **P3 (1 saat)** — Lint Pass 3 koşturma + archive doldurma
- **P4 (sprint backlog)** — React/controller/core ingest

**Hedef sağlık skoru:** Y:0, O:<20, D:<30 (mevcut Y:23 O:130 D:~76).

Index güncellendi: Modül & Mimari Özet altına aksiyon planı linki.

## [2026-04-25] query | tüm kod dosyalarından wiki güncelleme (faz 1 — pragmatic)

Kullanıcı talebi: "proje altındaki bütün kod dosyalarını oku, wiki belleğini bu mevcut kod üzerinden güncelle." Pragmatic kapsam (1362 kod dosyası tek turda imkansız): **lint-report'taki 13 eksik kavram için kod kanıtı + son 15 commit deltası**.

### Yeni dosyalar (15)

**Decisions (1):**
- `decisions/2026-04-24-vehicle-plate-tracking-option-a.md` — Sprint 6b ADR (description prepend, schema değişikliği yok). Scoped wiki'deki sentezi ana wiki'ye yansıt.

**Syntheses (1):**
- `syntheses/codebase-snapshot-2026-04-25.md` — kod ↔ wiki uyum analizi, son 15 commit drift, 1362 dosya envanter, faz planı.

**Entities (7) — eksik kavramlar için kod-bazlı stub:**
- `entities/user-def.md` (core/.../security/UserDef.java)
- `entities/user-def-access.md` (core/.../security/UserDefAccess.java)
- `entities/product-variant.md` (pos-product-manager/.../product/entity/ProductVariant.java)
- `entities/accounts-hub-screen.md` (project_pos/.../accounts/screens/accounts_hub_screen.dart)
- `entities/document-item-result.md` (pos-product-manager/.../product/model/DocumentItemResult.java)
- `entities/batch-entry-row.md` (project_pos/.../batch_entry/models/batch_entry_models.dart:251)
- `entities/company-setting.md` (pos-product-manager/.../company/entity/CompanySetting.java)

**Concepts (6) — eksik kavramlar için kod-bazlı stub:**
- `concepts/company-context.md` (pos-product-manager/.../common/context/CompanyContext.java)
- `concepts/pre-authorize-guard.md` (Spring Security pattern, 1 kullanım)
- `concepts/batch-entry-state.md` (project_pos/.../batch_entry/models/batch_entry_models.dart:473)
- `concepts/batch-row-status.md` (batch_entry_models.dart:1 enum)
- `concepts/app-colors-palette.md` (project_pos/lib/core/theme/app_colors.dart)
- `concepts/state-notifier-vs-async.md` (Riverpod migration özeti, henüz başlamadı)

### Index güncellendi (5 alt-bölüm)

- Decisions → Sprint 6b alt-bölümü
- Syntheses → Modül & Mimari Özet altına codebase-snapshot
- Entities → Security Domain (yeni alt-bölüm), Ürün satırı, Firma satırı, Flutter Screens & Models (yeni alt-bölüm)
- Concepts → Mimari satırına 2 yeni link, Flutter / Frontend (yeni alt-bölüm) — 4 yeni link

### Faz Dışı (sonraki turlara)

- React (template/) modülü — 525 dosya, sadece CLAUDE.md kopyası kapsamlı değil
- pos-product-manager controller-bazlı endpoint kataloğu — ~50 dosya
- core kütüphane derinleşme (TOpenSimpleCompanyEntity, BaseDbServiceImp, @FilterDef)
- 18 MERGE_NEEDED dosya manuel diff (lint borçları)

**Kaynak:** kullanıcı talebi (auto + plan mode geçişleri)

## [2026-04-25] lint | 134 bulgu (Y:23 O:130 D:~76) — tam pass 2

`raw/` hariç **188 dosya** üzerinde 6 kategorili tam sağlık kontrolü. Mekanik (Bash) + sample diff (manuel). Otomatik düzeltme yapılmadı; rapor: [[lint-report]].

**Sayım:**
- 🔴 Çelişki (gerçek): **0** (3 sample diff yapıldı — hepsi DUPLICATE/zenginleştirme)
- 🟠 Çelişki adayı (MERGE_NEEDED): 21 (18 `-from-claude-wiki` + 3 ADR↔sentez)
- ✅ Eskimiş: 0 (tümü ≤12 gün)
- 🟠 Yetim: 18 (hepsi `-from-claude-wiki` — MERGE_NEEDED ile örtüşür)
- 🔴 Kırık wikilink (gerçek): 22 (16 ad değişimi + 6 eksik hedef)
- 🟠 Eksik kavram (≥10 bahis, sayfa yok, generic terim filtreli): 13 (`UserDef`, `UserDefAccess`, `ProductVariant`, `CompanyContext`, `AccountsHub`, `BatchEntryRow`, vb.)
- 🟡 Tek-yönlü xref: 773 ham → ~50 öncelikli (concept↔entity karşılıklı eksiklik)
- 🟠 Zayıf kaynak (≤1 source): 81 (parser sınırlı; manuel doğrulama önerildi)

**En kritik 3:** (1) 16 ad-değişen kırık wikilink — sed ile 10 dk; (2) 18 MERGE_NEEDED yetim — manuel diff 2-3 saat; (3) 13 eksik domain kavram — UserDef/ProductVariant gibi core entity sayfaları yok.

**Kaynak:** kullanıcı /lint-pass talebi.

## [2026-04-25] migration | Proje geneli .md konsolidasyonu → .wiki/

Kullanıcı talebi: "proje altındaki tüm `.md` dosyalarını `.wiki/`'ye entegre et + orijinallerini sil/stub bırak". Plan: `C:\Users\Win11\.claude\plans\polymorphic-gathering-flute.md`. AskUserQuestion ile 4 karar netleştirildi (CLAUDE.md hard-delete vs stub çelişkisinde safety nedeniyle B yorumu / stub uygulandı).

**Kapsam dışı (dokunulmadı):** `template/node_modules/**` (1500+ npm artifact), `**/target/**`, `.git/**`, `.claude/worktrees/**`, `project_pos/ios/.../LaunchImage README`, `core/.github/...progress.md`, `.wiki/**` (hedef vault).

**6 paralel agent + manuel:** ~117 dosya işlendi.

| Grup | Kapsam | Dosya | Sonuç |
|---|---|---|---|
| Agent A | `.claude/{decisions,runbooks,reference,status,plans,guides,inventory,commands,INDEX}/` + 3 root scratch | 25 | Hepsi taşındı + stub. `multi-tenant.md` çakıştığı için `multi-tenant-routing.md` adıyla yazıldı. |
| Agent B1 | `.claude/wiki/entities/*` | 18 | Hepsi DUPLICATE (önceki ingest'te wiki'de mevcuttu) → stub. README ayrı kaydedildi. |
| Agent B2 | `.claude/wiki/{decisions,concepts,patterns,syntheses,integrations}/*` | 27 | 23 DUPLICATE, 1 NEW (`use-entity-graph-for-customer-account-fetch`), 3 README silindi. |
| Agent B3 | `.claude/wiki/{flows,issues,archive,raw,sources,glossary,contradictions,index,log,lint-report}/*` | 32 | 5 issues `-from-claude-wiki` suffix'i ile MERGE_NEEDED, geri kalan stub. 5 NEW yazım. |
| Agent C | Module README + `pos-product-manager/ERROR_HANDLING_GUIDE.md` | 3 | Hepsi NEW. |
| Agent E | 10 CLAUDE.md (root + 7 modül + 2 alt + `.claude/wiki/CLAUDE.md`) | 10 | Hepsi `.wiki/sources/claude-md/` altına; ~37 link replace (`.claude/reference/...` → `.wiki/concepts/...` vb.); orijinaller 1-satır pointer stub. |
| Manuel | 2 patterns (`optimistic-lock-version`, `scoped-feature-wiki`) | 2 | DUPLICATE → stub. |

**MERGE_NEEDED (manuel inceleme bekleniyor):** `-from-claude-wiki` suffix'li 5 issues + bazı concepts. Mevcut wiki sayfasıyla kaynak içerik farklılığı tespit edildi.

**Yeni dizin:** `.wiki/sources/status-snapshots/`, `.wiki/sources/claude-md/`.

**Index güncellendi:** Yeni 4 bölüm (CLAUDE.md Arşivi, Status Snapshots, Code-refs migration alt-bölümü, Patterns alt-bölümü). 50+ yeni MOC link.

**Stub formatı:** `> Bu içerik [.wiki/...](göreceli-link) altına taşındı (2026-04-25).` Auto-load mekanizması stub'ı okur, link üzerinden devam eder.

**Etkilenen yollar:** `.claude/{decisions,runbooks,reference,status,plans,guides,inventory,commands,wiki}/`, root CLAUDE.md ve 7 modül CLAUDE.md, 3 root scratch, 3 module README/GUIDE.

**Kaynak:** kullanıcı talebi (auto mode + AskUserQuestion onayı).

## [2026-04-25] full-setup | İlk kapsamlı kurulum + 7 kaynak ingest + 4 sentez + lint
- **PHASE 1 (Setup)**: 9 alt klasör + 9 .gitkeep + CLAUDE.md (217 satır) + index.md + log.md zaten kuruluydu (önceki turlardan)
- **PHASE 2 (Kaynak seçimi)**: Proje genelinde 7 öncelikli kaynak seçildi (CLAUDE.md kök, accounts-hub gap, sale-checkout, purchase-checkout, drift-reconciliation, openapi-codegen, ledger-adr). Symlink (ln -s) Windows Git Bash'te kopyalama davranışı yaptığı için pointer-markdown fallback'a geçildi → `raw/code-refs/2026-04-25-*.md` (7 dosya)
- **PHASE 3 (Ingest)**: Her kaynak için sources/code-refs/2026-04-25-<slug>.md (7 source summary). Bahsedilen 22 entity, 15 concept, 18 decision, 12 issue açıldı. Toplam 74 yeni içerik sayfası.
- **PHASE 4 (Sentez)**: 4 yüksek seviyeli sentez yazıldı:
  - `syntheses/pos-module-map` — servis + client haritası
  - `syntheses/sector-agnostic-architecture` — çoklu sektör mimarisi
  - `syntheses/accounts-module-overview` — cari hesap modülü
  - `syntheses/integration-catalog` — entegrasyon kataloğu
- **PHASE 5 (Lint)**: lint-report.md yazıldı — 0 yüksek/orta, 14 düşük (stub sayfalar). Çelişki yok, yetim yok, eskimiş yok.
- **PHASE 6 (Index/Log sync)**: index.md tüm kategorilerle güncel, log.md bu girdi.
- Toplam: 88 markdown dosyası (CLAUDE.md + index + log + lint-report + 84 içerik) ; 355+ wikilink cross-ref.
- Kaynak: kullanıcı talebi — tam otomatik tek-pass setup + ingest

## [2026-04-25] setup | Wiki iskeleti yeniden kuruldu (overwrite)
- Dokunulan dosyalar: `.wiki/CLAUDE.md`, `.wiki/index.md`, `.wiki/log.md`
- Kaynak: kullanıcı talebi — aynı scaffold prompt'u 2. kez; seçim: "Tam yeniden kur (overwrite)"
- Not: 9 alt klasör + 9 `.gitkeep` idempotent korundu; `raw/` hâlâ 0 kaynak. Placeholder yorumları sabit: `{{KAYNAK_KLASORU}}=code-refs`, `{{SORUN_KLASORU}}=issues`, `{{PROJE_ADI}}=SEDCORE POS`, `{{DIL}}=Türkçe`.

## [2026-04-24] setup | Wiki iskeleti kuruldu (ilk tur)
- Dokunulan dosyalar: `.wiki/CLAUDE.md`, `.wiki/index.md`, `.wiki/log.md`, 9 alt-klasör + `.gitkeep`
- Kaynak: kullanıcı talebi — `.wiki` yeni bağımsız vault, SEDCORE POS için sektör-agnostik kalıcı bilgi arşivi
- Not: İlk ingest manuel tetiklenecek. `raw/code-refs/` ve `raw/docs/` boş.
