---
title: Design System & Template Audit (2026-04-27)
tags: [audit, ui, design-system, templates, sprint-15]
source: project_pos/lib/core/widgets/ + lib/features/**/screens/ envanter
date: 2026-04-27
status: verified
---

# Design System & Template Audit (Sprint 15 Öncesi)

Sprint 15 başında "tüm ekranları BaseScaffold + Feature Templates + Design System uyumlu yap" emri ile başlatılan envanter.

## Amaç

Mevcut design system bileşenleri + ekran tipleri + standardizasyon eksikliklerini belgelemek. Sprint 15+ migration planı için temel.

## Mevcut Design System (`core/widgets/` — 21 dosya)

| Bileşen | Amaç | Status |
|---|---|---|
| `app_scaffold.dart` | Tema-aware gradient wrapper Scaffold | ✅ Var (kullanım: 79+ ekran sırada) |
| `app_app_bar.dart` | Standard/primary/gradient varyantlı AppBar | ✅ Var |
| `app_card.dart` | Modern kart + tema uyumu (AppCard, AppStatCard, AppSectionCard) | ✅ Var |
| `app_input.dart` | Form input — TextFormField replacement | ✅ Var |
| `app_button.dart` | Variant'lı buton (primary/success/danger/outline/...) | ✅ Var |
| `app_badge.dart` | Status/Count/Custom badge | ✅ Var |
| `app_confirmation_dialog.dart` | Standard confirmation modal | ✅ Var |
| `app_empty_state.dart` | noData/search/error/offline factory'leri | ✅ Var |
| `app_toast.dart` | success/error/info/warning toast | ✅ Var |
| `app_shimmer.dart` | Loading skeleton | ✅ Var |
| `app_cached_image.dart` | cached_network_image wrapper + AppAvatar | ✅ Var (Sprint 12 kullanım başladı) |
| `app_bottom_sheet.dart` | Standard bottom sheet | ✅ Var |
| `app_optimized_list.dart` | Lazy-load liste | ✅ Var |
| `app_text.dart` | Typography helpers | ✅ Var |
| `app_glass_card.dart`, `app_gradient_button.dart`, `success_screen.dart`, `section_header.dart`, `stat_card.dart` | Yardımcılar | ✅ Var |
| `product_card.dart` | Sprint 12-14 ortak ürün kartı (3 mode) | ✅ Sprint 14 |
| **`base_scaffold.dart`** | **Sprint 15 YENİ** — AppScaffold + AsyncValue helper | ⭐ Sprint 15 |
| **`templates/list_screen_template.dart`** | **Sprint 15 YENİ** — search/filter/pagination | ⭐ Sprint 15 |
| **`templates/form_screen_template.dart`** | **Sprint 15 YENİ** — sections + save toolbar | ⭐ Sprint 15 |
| **`templates/detail_screen_template.dart`** | **Sprint 15 YENİ** — TabController + headerSlot + isLoading | ⭐ Sprint 15 |
| **`templates/dashboard_screen_template.dart`** | **Sprint 15 YENİ** — statCards grid + sections list | ⭐ Sprint 15 |

## BaseScaffold + Feature Templates Tasarımı (Sprint 15)

### BaseScaffold
`AppScaffold` üstüne ince `AsyncValue<T>` switcher ekler. Eski pattern:
```dart
AppScaffold(
  body: state.isLoading
      ? Center(child: CircularProgressIndicator())
      : state.error != null
          ? AppEmptyState.error(...)
          : ListView(...),
)
```
Yeni pattern:
```dart
BaseScaffold<List<Foo>>(
  asyncValue: ref.watch(fooListProvider),
  onRetry: () => ref.invalidate(fooListProvider),
  dataBuilder: (data) => ListView(...),
)
```

### ListScreenTemplate
Sprint 13 `enhanced_product_list_screen` pagination pattern'ı reusable hale getirildi:
- ScrollController bottom-200px → `onLoadMore` tetikleyici
- RefreshIndicator + pull-to-refresh
- searchSlot / filterSlot / statsSlot / FAB / bottomBar slotları
- Generic `<T>` tipiyle herhangi liste verisi
- Grid mode (isGrid + gridDelegate)

### FormScreenTemplate
add_customer/add_supplier/add_store gibi form ekranları için:
- `FormSection(title, icon, fields)` listesi
- formKey opsiyonel
- save toolbar (loading + canSubmit + customBottomBar)
- topBanner (uyarı), secondaryActions (silme/iptal)

### DetailScreenTemplate
Tab-bazlı detay ekranları için:
- `DetailTab(label, icon, builder)` listesi
- TabController self-managed (with vsync)
- onTabChanged callback (export gibi tab-aware işlemler için)
- headerSlot (TabBar ile TabBarView arasında — date pill, kısayol)
- isLoading + error switcher
- keepTabsAlive (IndexedStack mode)

### DashboardScreenTemplate
Stat cards grid + section list pattern'ı:
- `statCards` (default 2 sütun)
- `sections` (Card-bazlı bloklar)
- onRefresh (pull-to-refresh)

## Ekran Envanteri (Migration Hedefi)

`lib/features/**/screens/*.dart` altında **64+ ana ekran** (alt-screens hariç). Modülere göre dağılım:

| Modül | Ekran Sayısı | Tipik Tipler |
|---|---|---|
| auth | 2 | Form (login, registration) |
| autoparts | 3 | List + Detail |
| dashboard | 1 | Dashboard |
| finance | 5 | Dashboard + Form + List |
| hrm | 2 | Form + List |
| import | 5 | Multi-step + Modal |
| inventory | 4 | List + Detail (✅ Sprint 12-14 ProductCard) |
| menu | 1 | Dashboard |
| pos | 1 | Custom (Sale + Cart layout) |
| purchases | 4 | List + Form + Detail |
| reports | 6 | Dashboard + Detail (✅ Sprint 15) |
| sales | 3 | List + Detail |
| settings | 6 | Detail (✅ Sprint 15) + Form |
| stock | 6 | List + Form + Dashboard |
| store/warehouse | 4 | List + Form (✅ Sprint 11 modernize) |
| supplier_claims | 3 | List + Detail |
| catalog | 3 | List + Form |
| accounts | 2 | Custom hub + Modal |

## Mevcut Modernizasyon Durumu (2026-04-27 başında)

[[sources/status-snapshots/ui-modernization]] — 2026-04-22'de başlayan migration:
- 8 ekran tamamlandı (store_list, warehouse_list, add_store, add_warehouse, add_customer, category_list, add_supplier, app_input genişletmesi)
- Hedef: ~79 raw `Scaffold` kullanan ekran tamamen migrate

Sprint 12-14 çıktıları:
- ProductCard tam migration (Sprint 12-14)
- ProductAddMethodSheet (Sprint 12)
- referenceDataProvider (Sprint 12)
- Pagination provider rewrite (Sprint 13)

## Sprint 15 Hedefi (Bu Sprint)

1. **5 yeni template dosyası** → ✅ tamamlandı
2. **2 PoC migration** (settings + reports) → ✅ tamamlandı
3. **7 ekran toplu migration** (4 settings + 3 reports) → 🔄 agent çalışıyor
4. **Wiki audit + synthesis + log** → ✅ bu sayfa

## Sprint 16+ Kalan İş (Modüler Plan)

| Sprint | Modül | Ekran | Tahmini Efor |
|---|---|---|---|
| 16 | inventory + stock + catalog | ~13 | 2-3 gün |
| 17 | sales + purchases + accounts | ~9 | 2 gün |
| 18 | finance + hrm + autoparts + supplier_claims | ~13 | 2-3 gün |
| 19 | import + auth + menu + pos + dashboard | ~10 | 2 gün |
| 20 | Cleanup: pre-existing teknik borç (deprecated value, underscore stili) | ~10 | 1 gün |

Toplam tahmini ~10 iş günü 5 sprint'e yayılır.

## Sources

- `project_pos/lib/core/widgets/` envanter (Glob)
- `project_pos/lib/features/**/screens/*.dart` (Glob)
- [[sources/status-snapshots/ui-modernization]] — devam eden modernizasyon
- [[sources/code-refs/screens-inventory]] — eski 73 ekran envanteri
- [[sources/code-refs/2026-04-27-product-screens-audit]] — Sprint 12 product ekran audit

## Related

- [[syntheses/design-system-template-architecture]] — BaseScaffold + 4 template mimarisi (Sprint 15)
- [[concepts/app-colors-palette]]
