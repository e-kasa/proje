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

## ~~DashboardScreenTemplate~~ — EMEKLİ (Sprint 20)

> **STATUS: REMOVED 2026-04-28** — 5 sprint (15-19), 0 tüketici. Sprint 20'de file delete. Sebep: hero card + chart + quick action grid + section serpiştirilmesi paterni şablon kalıbına sığmıyor; her dashboard'ın kendi sırası ve KPI dizilimi farklı. BaseScaffold (sync body) ile direkt çalış.

Eski tasarım (ölü kod, referans için):

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

## Sprint 21 Final — 100% MIGRATION TAMAMLANDI 🎉

Sprint 20'de baseline cleanup yapıldıktan sonra Sprint 21 = kalan 8 legacy L1 ekran + supplier_upload Radio<bool> refactor.

### Sonuç: 64 ekrandan 0'ı L0/L1

```
Template (L2):     25 ekran  (39%)
BaseScaffold (L3): 37 ekran  (58%)
Other (modal):      2 ekran   (3%)
L1 (AppScaffold):   0 ekran  ✅
L0 (raw Scaffold):  0 ekran  ✅
```

### Sprint 21 İşler (8 ekran + 1 refactor)

| Ekran | Karar |
|---|---|
| `store_list_screen` | ListScreenTemplate |
| `store_add_screen` | BaseScaffold swap |
| `warehouse_list_screen` | ListScreenTemplate |
| `warehouse_add_screen` | BaseScaffold swap |
| `product_detail_screen` | BaseScaffold swap (×3 dal) |
| `batch_product_screen` | BaseScaffold swap (L3 custom) |
| `customer_sales_analysis_screen` | BaseScaffold swap |
| `product_sales_analysis_screen` | BaseScaffold swap |
| `supplier_upload_wizard` | Radio<bool> → Icon refactor + use_super_parameters fix |

**Kalan Radio<bool>:** Sprint 20'de "Radio<bool> kart-içi → RadioGroup karmaşık" diye atlanmıştı. Sprint 21'de daha temiz çözüm bulundu: kart zaten `GestureDetector(onTap)` ile çalışıyordu, Radio sadece görsel select indicator'dı. **`Icon(radio_button_checked / radio_button_unchecked)` ile değiştirildi** — deprecated API kaldırıldı, davranış aynı.

### Sprint 16-21 FINAL İstatistik

**55 ekran migrate edildi** (Sprint 16-21 boyunca, +cleanup+refactor).

| Template | Adoption | Detay |
|---|---|---|
| **ListScreenTemplate** | **18 ekran** ⭐ en başarılı | S16:7, S17:2, S18:6, S19:1, S21:2 |
| **BaseScaffold swap** | **33 ekran** ⭐ opt-in | S16:7, S17:7, S18:4, S19:9, S21:6 |
| FormScreenTemplate | 3 ekran | S16:1, S18:2 |
| DetailScreenTemplate | 2 ekran | S15:1, S16:1 |
| ~~DashboardScreenTemplate~~ | **0** ❌ EMEKLİ Sprint 20 | — |
| SKIP (modal/sheet) | 5 ekran | S18:1, S19:4 |

**Kümülatif LOC delta:** ~−501 (Sprint 16: −204, S17: −110, S18: −193, S19: ~+1, S20: ~0, S21: ~+5)

**Kümülatif `flutter analyze`:**
- Migration kaynaklı yeni issue: **0** (6 sprint boyunca konfirm)
- Sprint 20-21 baseline cleanup: **−53 issue**
- Project-wide: ~260+ → 165 (≈−37%)

### Final Mimari Hiyerarşisi

```
Material Scaffold (Flutter built-in)
    ↑
AppScaffold (gradient bg + theme wrapper) — DEPRECATED Sprint 22+
    ↑
BaseScaffold<T> (AsyncValue switcher) — Sprint 15
    ↑
3 Feature Template (List, Form, Detail) — Sprint 15-21  [Dashboard EMEKLİ]
    ↑
55 Concrete Screens migrate edildi (100%)
```

### YENİ EKRAN STANDARDI (Kalıcı Kural — Sprint 22+)

> **Hiçbir yeni ekranda raw `Scaffold` veya `AppScaffold` kullanılmaz.**
> Liste? → `ListScreenTemplate`. Form? → `FormScreenTemplate`. Tab detay? → `DetailScreenTemplate`. Custom layout? → `BaseScaffold`.
> 
> **`AppScaffold` artık deprecated** — sadece `BaseScaffold` ve template katmanı resmi API.

### Sprint 22+ İçin Backlog

1. ~165 lint issue (`dart fix --apply` ile %50+ otomatik)
2. `WizardScreenTemplate` veya `BottomSheetTemplate` ihtiyaçları **gerçek müşteri talebi olduktan sonra** inşa et (DashboardScreenTemplate hatası tekrarlanmasın)
3. `bulk_import_review_screen_v2.dart` (2128 LOC) component splitting
4. `AppScaffold` deprecate notice ekle, Sprint 25+ tamamen sil

## Sprint 20 Cleanup — DashboardScreenTemplate Emekli + Flutter Deprecations (FINAL)

Sprint 16-20 boyunca biriken **pre-existing baseline** issue'lar Sprint 20'de tek seferde temizlendi.

### Yapılan İşler

1. **`dashboard_screen_template.dart` SİLİNDİ** — 5 sprint, 0 tüketici, 0 referans.
2. **autoparts hardcoded TR → i18n** (`autoparts.vehicles_title`, `autoparts.part_search_title` data.sql + Flutter migration)
3. **46 baseline issue** temizlendi (Flutter 3.31-3.34 deprecations + async gaps + unused vars):
   - 21x `DropdownButtonFormField.value` → `initialValue`
   - 8x `use_build_context_synchronously` → mounted guard
   - 4x `Radio` → `RadioGroup` (2 form)
   - 1x `Switch.activeColor` → `activeThumbColor`
   - 1x `Matrix4.translate()` → `translateByDouble()`
   - 2x `unused_local_variable`, 2x `unnecessary_cast`, 1x `unnecessary_import`
4. **1 Radio<bool> intentional skip** (supplier_upload_wizard kart-içi kullanım — Sprint 21+'da `Checkbox` geçişi daha temiz)

### Sprint 16-20 FINAL İstatistik

**47 ekran migrate edildi** (Sprint 16-19 boyunca).

| Template | Adoption | Sprint Bazlı Tüketici |
|---|---|---|
| **ListScreenTemplate** | **16 ekran** ⭐ | S16:7, S17:2, S18:6, S19:1 |
| **BaseScaffold swap** | **27 ekran** ⭐ | S16:7, S17:7, S18:4, S19:9 |
| FormScreenTemplate | 3 ekran | S16:1, S18:2 |
| DetailScreenTemplate | 2 ekran | S15:1 (settings PoC), S16:1 (stock_alert) |
| ~~DashboardScreenTemplate~~ | **0 ekran** ❌ EMEKLİ | — |
| SKIP (modal/sheet) | 5 ekran | S18:1 (claim_resolve), S19:4 (import modals) |

**Kümülatif LOC delta:** ~−506

**`flutter analyze` durumu:**
- Migration sırasında yaratılan **yeni issue: 0** (her sprint'te konfirm)
- Sprint 20'de **−46 baseline issue** temizlendi
- Project-wide: 214 → 168 (Sprint 20 scope dışı 168 issue services/utils/widgets'da — Sprint 21+)

### Mimari Öğretiler

1. **"Template kullanım sayısı = başarı metriği DEĞİL."** Doğru ekranı doğru L seviyesinde tutmak asıl değer (BaseScaffold swap %57 oranında — bu **planlı, doğal bir tercih**).
2. **DashboardScreenTemplate öğretisi:** Gerçek tüketici talebi olmadan template inşa ETME. Hipotetik kullanıcı/use-case'e göre tasarlanan template ölü kod olarak kalır.
3. **Multi-step wizard pattern (5 ekran)** kalıcı olarak template scope DIŞI:
   - Step indicator + custom bottom action bar + state-based UI dinamiği
   - FormScreenTemplate'in section-only paterne uymaz
   - Sprint 22+'da `WizardScreenTemplate` ihtiyacı doğarsa **gerçek müşteri olduktan sonra** inşa et
4. **Bottom sheet'ler (5 modal)** template scope DIŞI — `Container` + `BorderRadius.vertical(top:)` + `MediaQuery.viewInsets.bottom` paterni Scaffold değil. `BottomSheetTemplate` Sprint 22+ ihtiyaç doğarsa.

### Tüm Migration İş Akışının Mimarisi (FINAL)

```
Material Scaffold (Flutter built-in)
    ↑
AppScaffold (gradient bg + clip wrapper, theme-aware)
    ↑
BaseScaffold<T> (AsyncValue switcher) — Sprint 15
    ↑
4 Feature Template (List/Form/Detail) — Sprint 15-20  [DashboardTemplate EMEKLİ Sprint 20]
    ↑
Concrete Screen — 47 ekran migrate edildi
```

L seviyesi dağılımı (Sprint 20 sonu, ~120 ekran tahmini):
- **L2 (template)**: ~21 ekran (List+Form+Detail)
- **L3 (BaseScaffold custom)**: ~27 ekran
- **L1 (AppScaffold legacy)**: ~30 ekran (Sprint 22+ ele alınmamış)
- **L0 (raw Scaffold)**: ~40 ekran (Sprint 22+)

### Yeni Ekran Standardı (Sprint 21+ için kural)

> **L0 (raw `Scaffold`) yasak.**
> **L1 (`AppScaffold`)** yerine **L2 (template)** veya **L3 (`BaseScaffold` custom)** tercih edilmeli.
> Liste ekranı? → ListScreenTemplate. Form? → FormScreenTemplate. Tab detay? → DetailScreenTemplate. Custom? → BaseScaffold.

## Sprint 19 Migration Sonuçları (Import + Auth + Menu + POS + Dashboard) — DashboardScreenTemplate Emekli Kararı

10 ekran migrate, 4 modal/sheet SKIP.

| Template Kararı | Sayı | Ekranlar |
|---|---|---|
| ListScreenTemplate | 1 | `supplier_import_review` |
| BaseScaffold swap | 9 | `menu`, `login`, `registration`, `barcode_scanner`, `bulk_import_review_v2`, `bulk_import_upload`, `supplier_import_upload`, `modern_dashboard`, `pos` |
| **SKIP** (modal/sheet) | 4 | `edit_product_modal`, `manual_match_modal`, `match_confirm_modal`, `update_stock_modal` |

**Template adoption oranı %10** (Sprint 19'da en düşük). Sebep: import workflow ekranları multi-step wizard ağırlıklı; auth ekranları custom split layout; POS L3 custom; dashboard chart-heavy.

### KRİTİK: DashboardScreenTemplate Emekli Edildi

**5 sprint, 0 tüketici.** Sprint 19'da `modern_dashboard_screen` (843 LOC, en güçlü aday) bile reddetti:

1. Hero header AppBar değil — full-width gradient kart, içine refresh+profile gömülü
2. Section title'lar bloklar arasına serpiştirilmiş — template `sections: [...]` monolithic block bekler
3. KPI cards `AppStatCard` değil — gradient ikon + raw değer + onTap (lowStock → alerts)
4. KPI 4 sütun, cardlar birbirinden farklı — template `statCardColumns=2` default
5. Custom skeleton template'in `isLoading` spinner'ına sığmaz

`finance_dashboard_screen` (Sprint 18) aynı sebeplerle reddetmişti. **POS dashboard'larda ortak desen yok** — herkesin hero card'ı, KPI dizilimi, section sırası farklı.

**Sprint 20 task:** `lib/core/widgets/templates/dashboard_screen_template.dart` SİL.

### Multi-Step Wizard Pattern Doğrulandı (Template Scope Dışı)

Sprint 17 (`supplier_upload_wizard`) + Sprint 19 (4 ekran daha):
- `company_registration_screen` (3-step)
- `bulk_import_review_screen_v2` (3-step + custom bottom bar)
- `bulk_import_upload_screen` (4-state UI: idle/uploading/success/error)
- `supplier_import_upload_screen` (2-state: form/progress)

Step indicator + custom bottom action bar + state-based UI dinamiği FormScreenTemplate'in section-only paterne uymaz. **Multi-step wizard kalıcı olarak template scope dışı.** İhtiyaç doğarsa `WizardScreenTemplate` Sprint 21+'da, ama gerçek müşteri olmadan inşa etmeyeceğiz (DashboardScreenTemplate hatasını tekrarlama).

### Sprint 16-19 Kümülatif İstatistik

| Template | Adoption (47 ekran) |
|---|---|
| ListScreenTemplate | **16 ekran** ✅ |
| BaseScaffold swap | **27 ekran** ✅ |
| FormScreenTemplate | 3 ekran |
| DetailScreenTemplate | 2 ekran |
| **DashboardScreenTemplate** | **0 ekran** ❌ EMEKLİ |

Toplam Net LOC delta: ~−506

## Sprint 18 Migration Sonuçları (Finance + HRM + Autoparts + Supplier Claims)

12 ekran migrate edildi, 1 ekran (`claim_resolve_sheet`) intentional skip.

| Template Kararı | Sayı | Ekranlar |
|---|---|---|
| ListScreenTemplate | 6 | `expense_list`, `employee_list`, `supplier_claims_list`, `part_search`, `vehicle_compatibility`, `vehicle_list` |
| FormScreenTemplate | 2 | `add_income`, `add_employee` |
| BaseScaffold swap | 4 | `add_expense` (gradient AppBar), `cash_flow` (chart), `finance_dashboard` (hero+grid), `supplier_claim_detail` |
| **SKIP (bottom sheet)** | 1 | `claim_resolve_sheet` |

**Template adoption oranı %67** (Sprint 16: %56, Sprint 17: %22). Sebep: bu modüller list-heavy.

**Yeni öğreti — Bottom sheet'ler template scope dışında:** `claim_resolve_sheet` `showModalBottomSheet(builder: (_) => ...)` ile çağrılıyor; `Container` + `BorderRadius.vertical(top:)` + `MediaQuery.viewInsets.bottom` padding pattern'ı = bottom sheet, Scaffold değil. Tüm template katmanı (BaseScaffold dahil) tam-ekran Scaffold için tasarlandı. İleride ihtiyaç doğarsa `BottomSheetTemplate` ayrı bir Sprint'te eklenebilir.

**DashboardScreenTemplate adoption oranı 0/0/0/0 (Sprint 15-18):** `cash_flow` ve `finance_dashboard` aday gibi görünüyordu ama:
- Hero net-income card (full-width, conditional renkli) `statCards` simetrisine sığmıyor
- Chart-heavy ekranlar (custom `_BarRow`) template grid'e sığmıyor
- Quick action grid + kategori breakdown custom layout

**Karar:** DashboardScreenTemplate Sprint 19'da (dashboard modülü) son şansını alacak — ya gerçek tüketici bulur ya da emekli edilir.

**FormScreenTemplate'in iki yüzü:**
- ✅ Başarı: `add_income` 246→206 (−40 LOC) — 2 temiz section, klasik save
- ❌ Başarısızlık: `add_expense` AppAppBar.primary (gradient) korunmalı → BaseScaffold swap
- 🔀 Hibrid: `add_employee` FormScreenTemplate + loading için BaseScaffold fallback dalı

**Sonuç:** ~−193 LOC net, 0 yeni `flutter analyze` issue, 1 baseline issue temizlendi (rewrite sırasında).

## Sprint 17 Migration Sonuçları (Sales + Purchases + Accounts)

9 ekran (sales: 3, purchases: 4, accounts: 1, suppliers: 1 wizard):

| Template Kararı | Sayı | Ekranlar |
|---|---|---|
| ListScreenTemplate | 2 | `sale_list`, `purchase_list` |
| BaseScaffold swap | 7 | `sale_detail`, `purchase_detail`, `sale_return`, `add_purchase`, `purchase_return`, `accounts_hub`, `supplier_upload_wizard` |

**BaseScaffold swap oranı %78** (Sprint 16: %44). Sebep: sales/purchases/accounts doğası gereği **transaction-based** — özel bottom bar (iade tutarı + danger button), dynamic AppBar action (grandTotal chip), master-detail split (accounts_hub), multi-step wizard (supplier_upload).

**Form-look-alike → Form-uyumsuz öğretisi:** `add_purchase`, `sale_return`, `purchase_return` form gibi görünüyor ama:
- AppBar action chip (`if (_grandTotal > 0)`)
- Custom bottom bar (toplam iade hesabı + warning gradient)
- Body içinde inline submit + dinamik expansion list

Bu davranışlar `FormScreenTemplate.sections` API'sine sığmıyor → BaseScaffold swap doğru karar.

**Detail ekranları 800-1000 LOC:** `sale_detail` + `purchase_detail` büyük ama **tab tabanlı değil** (single-view scroll). DetailScreenTemplate tab odaklı, fayda yok. BaseScaffold swap.

**Sonuç:** ~−110 LOC net, 0 yeni `flutter analyze` issue, 19 baseline issue (Sprint 20 cleanup).

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
