---
title: BaseScaffold + Feature Template Mimarisi (Sprint 15)
tags: [synthesis, design-system, ui-architecture, templates, sprint-15]
source: project_pos/lib/core/widgets/{base_scaffold,templates}/
date: 2026-04-27
status: draft
---

# BaseScaffold + Feature Template Mimarisi

Sprint 15'te tasarlanan, ekranların tek bir Custom widget hierarchy yerine 5 reusable building block kullanmasını sağlayan template katmanı. Mevcut durum [[sources/code-refs/2026-04-27-design-system-template-audit]] sayfasında.

## Mimari Hiyerarşisi

```
Material Scaffold (Flutter built-in)
    ↑
AppScaffold (gradient bg + clip wrapper, theme-aware) — eskiden beri var
    ↑
BaseScaffold<T> (AsyncValue switcher) — Sprint 15 YENİ
    ↑
4 Feature Template (List/Form/Detail/Dashboard) — Sprint 15 YENİ
    ↑
Concrete Screen (settings_screen, sale_list_screen, ...) — refactor
```

Her ekran şu seviyelerden birinde kalabilir:
- **L0 (legacy)**: doğrudan `Scaffold(...)` — ~79 ekran
- **L1 (modern)**: `AppScaffold(...)` — ~30 ekran
- **L2 (template)**: `ListScreenTemplate / FormScreenTemplate / DetailScreenTemplate / DashboardScreenTemplate` — Sprint 15 sonrası ~10 ekran (settings + reports + Sprint 16+)
- **L3 (custom)**: ekran çok özel (POS, AccountsHub master/detail) — template kullanmaz, BaseScaffold kullanır

## BaseScaffold

**Amaç**: Riverpod `AsyncValue<T>` için tekrarlayan `if (loading) ... if (error) ... else body` pattern'ını ortadan kaldır.

**API:**
```dart
BaseScaffold<List<Sale>>(
  appBar: AppAppBar.standard(title: 'Satışlar'),
  asyncValue: ref.watch(saleListProvider),
  onRetry: () => ref.invalidate(saleListProvider),
  dataBuilder: (sales) => ListView.builder(...),
)
```

Veya senkron:
```dart
BaseScaffold(
  appBar: ...,
  body: const MyView(),  // sync mode
)
```

**Karar:** AsyncValue kullanımını teşvik et — Riverpod paradigması POS modülünde standardize.

## ListScreenTemplate

**Sprint 13 pagination pattern'ını reuse etti.** Pasta tek satır:

```dart
ListScreenTemplate<Sale>(
  title: 'Satışlar',
  items: state.items,
  isLoading: state.isLoading,
  isLoadingMore: state.isLoadingMore,
  hasMore: state.hasMore,
  onRefresh: notifier.loadFirst,
  onLoadMore: notifier.loadMore,
  itemBuilder: (ctx, sale, idx) => SaleCard(sale: sale),
  searchSlot: AppSearchInput(...),
  filterSlot: FilterChipBar(...),
  statsSlot: StatsBar(...),
  floatingActionButton: FloatingActionButton(...),
)
```

**Eski yaklaşım** (`enhanced_product_list_screen.dart` Sprint 13'ten önce 1,778 LOC):
- Manual ScrollController + addListener + onScroll
- Manual RefreshIndicator
- Manual loading footer
- Manual empty state

**Yeni yaklaşım**: tek satır `ListScreenTemplate(...)` çağrısı + builder. Hiçbir boilerplate.

## FormScreenTemplate

`FormSection` listesi ile section header + alanları organize eder:

```dart
FormScreenTemplate(
  title: 'Yeni Müşteri',
  formKey: _formKey,
  isSaving: _isSaving,
  onSave: _handleSave,
  sections: [
    FormSection(
      title: 'Temel Bilgiler',
      icon: Icons.person_outline,
      fields: [
        AppInput(label: 'Ad Soyad', ...),
        AppInput(label: 'Telefon', ...),
      ],
    ),
    FormSection(
      title: 'Adres',
      icon: Icons.location_on_outlined,
      fields: [AppInput(...)],
    ),
  ],
)
```

**Eski yaklaşım**: ListView + manuel section header padding + manuel save Container bottom bar.

## DetailScreenTemplate

Tab-bazlı detay ekranları için TabController boilerplate'ini ortadan kaldırır:

```dart
DetailScreenTemplate(
  title: 'Ürün Detayı',
  appBarActions: [IconButton(icon: Icon(Icons.edit), onPressed: ...)],
  isLoading: state.isLoading,
  error: state.error,
  onErrorRetry: notifier.load,
  onTabChanged: (i) => setState(() => _currentTabIndex = i),  // tab-aware actions için
  headerSlot: DateRangePill(),  // TabBar ile TabBarView arasında
  tabs: [
    DetailTab(label: 'Genel', icon: Icons.info_outline, builder: (_) => GeneralTab()),
    DetailTab(label: 'Varyantlar', icon: Icons.layers, builder: (_) => VariantsTab()),
    DetailTab(label: 'Stok', icon: Icons.inventory_2, builder: (_) => StockTab()),
  ],
)
```

**Eski yaklaşım**: `with SingleTickerProviderStateMixin` + `late TabController _tabController` + initState + dispose + AppAppBar.bottom + TabBarView + manuel loading/error.

**Karar (Sprint 15)**: `headerSlot` slot olarak eklendi (Reports screen ihtiyacı). Sprint 16'da daha fazla esneklik gerekirse `bottomSlot` da eklenebilir.

## DashboardScreenTemplate

Stat cards + section list pattern'ı:

```dart
DashboardScreenTemplate(
  title: 'Dashboard',
  onRefresh: notifier.refresh,
  statCards: [
    AppStatCard(title: 'Bugün', value: '₺1.234', icon: Icons.today, color: AppColors.primary),
    AppStatCard(title: 'Hafta', value: '₺12.345', icon: Icons.calendar_view_week, color: AppColors.success),
    AppStatCard(title: 'Ay', value: '₺125.430', icon: Icons.calendar_month, color: AppColors.info),
    AppStatCard(title: 'İade', value: '%4.2', icon: Icons.keyboard_return, color: AppColors.warning),
  ],
  sections: [
    SalesChart(),
    RecentTransactions(),
    TopCustomers(),
  ],
)
```

## Sprint 15 Migration Sonuçları

| Ekran | Önce | Sonra | Migration |
|---|---|---|---|
| `settings_screen.dart` | AppScaffold + AppAppBar.bottom + TabBar + TabBarView (60 LOC body) | DetailScreenTemplate (25 LOC) | ✅ TabController boilerplate kaldırıldı |
| `reports_screen.dart` | AppScaffold + manual loading/error + TabBar + headerColumn (75 LOC body) | DetailScreenTemplate + headerSlot (60 LOC) | ✅ TabController + loading/error helper |
| 4 settings + 3 reports | (agent migration) | (sürüyor) | 🔄 Sprint 15 son |

## Sprint 16 Migration Sonuçları (Inventory + Catalog + Stock)

16 ekran (6 inventory + 1 catalog + 8 stock + 1 ana ürün listesi):

| Template Kararı | Sayı | Örnek Ekranlar |
|---|---|---|
| ListScreenTemplate | 7 | `enhanced_product_list`, `brands`, `units`, `barcode_management`, `category_list`, `multi_warehouse_stock`, `stock_movement_history` |
| FormScreenTemplate | 1 | `add_category` |
| DetailScreenTemplate | 1 | `stock_alert` |
| BaseScaffold swap | 7 | `inventory` (hub), `company_category` (gradient AppBar), `enhanced_stock` (no AppBar), `stock_value_report` (hero+stat hibrid), `stock_transfer`, `stock_count_review`, `stock_transfer_review` (custom bottom bar) |

**Karar kuralı:** Template doğal oturuyorsa migrate; bottom-bar/AppBar dayatması davranış değiştiriyorsa BaseScaffold swap.

**Sonuç:** ~-204 LOC net, 0 yeni `flutter analyze` issue, 14 baseline issue korunuyor.

**Dogfood doğrulaması:** `enhanced_product_list_screen.dart` (Sprint 13'te ListScreenTemplate'in pattern'ı bu ekranda doğmuştu) artık template tüketicisi. Hiç custom override gerekmedi → API yeterli.

**Sprint 16 patterni `Sprint 17-20`'ye taşıyor:** Template ekran sayısını arttırmak başarı metriği değil; **doğru ekranı doğru L seviyesinde** tutmak asıl değer.

## Riskler

- **Template parametre patlaması**: ListScreenTemplate 18 parametre. Sprint 16'da kullandıkça ek slot ihtiyacı doğacak. Strateji: ek slot ekle, parametreyi kaldırma (backwards compat).
- **Custom ekranlar**: POS (cart-aware), AccountsHub (master/detail split), batch_product_screen (DataTable) template'lere sığmaz — BaseScaffold seviyesinde kalır.
- **TabController self-management kaybı**: bazı ekranlar `_tabController.animateTo(index)` benzeri programatik tab değişimi yapıyor olabilir — Sprint 16 migration'larında dikkat.

## Verification

- `flutter analyze` (5 yeni template dosyası): 0 issue ✅
- 2 PoC migration (settings + reports): 0 yeni issue ✅
- Smoke test bekliyor: kullanıcı `flutter run -d chrome`'la doğrulayacak.

## Sources

- [[sources/code-refs/2026-04-27-design-system-template-audit]] — bu mimarinin doğduğu envanter
- [[sources/code-refs/2026-04-27-product-screens-audit]] — Sprint 12 ProductCard pattern referans
- [[sources/status-snapshots/ui-modernization]] — devam eden migration
- `.claude/plans/polymorphic-gathering-flute.md` — Sprint 15 plan

## Related

- [[concepts/app-colors-palette]]
- [[entities/project-pos]]
- [[syntheses/product-screens-revision-plan]] — Sprint 12-14 öncesi pattern
