---
title: Flutter UI Modernizasyon Günlüğü
type: source
source: .claude/status/ui-modernization.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# Flutter UI Modernizasyon Günlüğü

Scheduled task `fluter-dizayn` her gün 1-3 ekranı tarar ve legacy
widget'ları (`Scaffold`, `Card`, `TextField`, `AlertDialog`, ...) proje
tasarım sistemiyle (`App*`) değiştirir.

## Hedef Metrikleri

- **Raw `Scaffold(` kullanan ekran:** 79 (başlangıç 2026-04-22)
- **Raw `Card(` kullanan ekran:** TBD
- **Raw `AlertDialog` kullanan ekran:** TBD

## Tamamlanan Ekranlar

| Tarih | Ekran | Değişiklik Özeti |
|-------|-------|------------------|
| 2026-04-22 | `features/store/screens/store_list_screen.dart` | Search `TextField` → `AppSearchInput`; delete `AlertDialog` → `AppConfirmationDialog.showDelete`; liste `Card` → `AppCard` |
| 2026-04-22 | `features/warehouse/screens/warehouse_list_screen.dart` | Search `TextField` → `AppSearchInput`; delete `AlertDialog` → `AppConfirmationDialog.showDelete`; liste `Card` → `AppCard` |
| 2026-04-22 | `features/store/screens/add_store_screen.dart` | 12 `TextFormField` → `AppInput`; tip seçim `Card` → `AppCard` (dark-mode uyumlu) |
| 2026-04-22 | `features/warehouse/screens/add_warehouse_screen.dart` | 8 `TextFormField` → `AppInput`; tip seçim `Card` → `AppCard` |
| 2026-04-22 | `core/widgets/app_input.dart` | **Tasarım sistemine ekleme:** `AppInput` → `suffixText` + `inputFormatters` parametreleri (form ekranlarındaki `TextFormField` migrasyonunu mümkün kıldı) |
| 2026-04-22 | `features/customers/screens/add_customer_screen.dart` | `Theme.of(context)` / `Color(0xFF10B981/0xFFEF4444)` → `AppColors.success/danger/primary/border/textMuted/textSecondary`; TODO i18n hardcoded TR → 12 yeni `customers.*` anahtarı (data.sql), `t()` ile bağlandı |
| 2026-04-22 | `features/catalog/screens/category_list_screen.dart` | Search `TextField` → `AppSearchInput`; delete/bulk delete `AlertDialog` → `AppConfirmationDialog.showDelete`; inline empty state → `AppEmptyState.search/noData`; tile `Card` → `AppCard`; `Colors.blue/orange/purple/grey` → `AppColors.*`; popup menu hardcoded 'Düzenle'/'Sil'/'Aktif'/'Pasif' → `t('common.*')` |
| 2026-04-22 | `features/suppliers/screens/add_supplier_screen.dart` | `_showPaymentDialog` + `_showCreditLimitDialog` — `AlertDialog` + raw `TextField` → `Dialog` + `AppInput` + `AppButton.success/outline`; modern header (icon badge + title), loading state built-in via `AppButton.isLoading` |
| 2026-04-22 | `security/data.sql` | 12 yeni `customers.*` i18n anahtarı (status, active_description, passive_description, basic_info, address, corporate_info, tax_number, tax_office, notes, notes_optional, email_invalid, name_required) |

## Sıradaki Adaylar (yüksek etki)

- `features/settings/screens/user_management_screen.dart`
- `features/catalog/screens/add_category_screen.dart`
- `features/sales/screens/sale_list_screen.dart`
- `features/purchases/screens/purchase_list_screen.dart`
- `features/hrm/screens/add_employee_screen.dart`
- `features/accounts/screens/payment_record_modal.dart`
- `features/finance/screens/add_income_screen.dart` / `add_expense_screen.dart`
- `features/inventory/screens/brands_screen.dart` / `units_screen.dart`

## Modernizasyon Kuralları (özet)

| Legacy | Modern |
|--------|--------|
| `Scaffold(...)` | `AppScaffold(...)` |
| `AppBar(...)` | `AppAppBar.standard(...)` |
| `TextField` (arama) | `AppSearchInput` |
| `TextFormField` (form) | `AppInput` |
| `Card(elevation,...)` | `AppCard(onTap,...)` |
| `AlertDialog` (confirm) | `AppConfirmationDialog.show*` |
| `SnackBar` | `AppToast.success/error` |
| `showDialog(...)` basit | `AppConfirmationDialog.showAlert` |
| Inline loading `CircularProgressIndicator` | `AppShimmer` (liste) |
| Inline empty state | `AppEmptyState.noData/error` |
| `Colors.blue`, `Colors.grey` | `AppColors.info`, `AppColors.textMuted` |
| `.withOpacity()` | `.withValues(alpha:)` |
