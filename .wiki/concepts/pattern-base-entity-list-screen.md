---
title: Pattern — BaseEntityListScreen (Flutter Abstract List Pattern)
type: concept
source: .claude/wiki/patterns/base-entity-list-screen.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# BaseEntityListScreen

## Problem
SEDCORE'da ~15 CRUD list ekranı var (Units, Employees, Brands, Categories, Customers, Suppliers, Stores, Warehouses, ...). Her biri benzer yapı: search bar + filter + list + row + FAB create + edit modal. Kopyala-yapıştır refactor maliyetli; tutarsız UX çıkar.

## Çözüm
**Abstract ConsumerWidget** — `BaseEntityListScreen<T>`. Ortak iskelet sağlar; türetilen sınıf data source + row builder + form widget verir.

## Şema (tahmini API)

```dart
class BaseEntityListScreen<T> extends ConsumerWidget {
  final String title;
  final AutoDisposeStateNotifierProvider<..., ...> listProvider;
  final Widget Function(BuildContext, T item, bool selected) rowBuilder;
  final Widget Function(BuildContext, T? editing, VoidCallback onSuccess) formBuilder;
  final List<Filter> filters;
  final bool searchable;
  // ...
}
```

## SEDCORE'da Türetilen Ekranlar (onaylı/plan)

- [[sources/code-refs/2026-04-17-units-employee-modern]] — UnitsScreen + EmployeeListScreen
- CategoryScreen, BrandsScreen (daha önceki sprint'ler)
- CustomerListScreen, SupplierListScreen (AccountsHub feature'ı farklı — merged list, pattern aktif değil)

## Neden Accounts Hub Kullanmıyor

AccountsHub özel: müşteri+tedarikçi **birleşik** liste + summary bar + detail panel (master-detail). Generic pattern bu üç bölmeyi kaldıramazdı.

## Trade-off

- 15 ekran için tutarlı UX + merkezi bug fix noktası
- Yeni entity eklemek dakikalar sürer
- Özel UX gerektiren (master-detail, 3 panel) feature'lar pattern'i kıramaz — fork edilir
- Generic type `T` erasure nedeniyle bazı compile-time garanti kaybı

## Tuzaklar

- `listProvider` tip parametresi yanlışsa Dart çalışma-zamanı hatası verir — compile-time kontrol zayıf
- `rowBuilder` içinde `Navigator.push` varsa geri dönüşte listeyi refresh etmek provider sorumluluğu
- FAB + create modal akışı 2026-04-24 `inline form → modal` kararı sonrası merkezileştirilmeli (bkz. [[syntheses/account-edit-form-ux]])

## Sources

- `project_pos/lib/core/widgets/common/base_entity_list_screen.dart` _(doğrulanması gereken path)_
- [[sources/code-refs/2026-04-17-units-employee-modern]]

## Related

- [[entities/customer]]
- [[entities/supplier]]
