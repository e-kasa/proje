---
title: CategoryService vs CompanyCategoryService — Sınır
type: concept
tags: [category, multi-tenant, service-boundary, sprint-31, sprint-34]
date: 2026-05-09
status: stable
---

# CategoryService vs CompanyCategoryService — Servis Sınırı

İki paralel servis hangi durumda hangisi kullanılır? Sprint 30 sonrası kategori sağlık denetiminde [[sources/code-refs/2026-05-09-category-system-health-audit]] gap #9: "iki servisin sorumluluk sınırı net değil — yeni geliştirici karışık çağırma riski". Bu doküman ayrımı netleştirir.

## Tek Bakışta

| Servis | Tablo | Tenant-scoped? | Kullanım Senaryosu |
|---|---|---|---|
| `CategoryService` | `categories` (global pool) | ❌ Hayır | Master kategori kataloğu — admin oluşturur, tüm firmalar bu havuzu görür |
| `CompanyCategoryService` | `company_categories` (junction) | ✅ Evet (`@Filter company_code`) | Firma seçimi — her firma global havuzdan kendi gösterdiklerini seçer |

## Kural

> **POS / wizard / runtime ekranları → her zaman `CompanyCategoryService`.**
> **Admin / sektör katalogu kurulumu → `CategoryService` (genelde sadece kurulum scriptleri ve admin UI).**

POS'ta `CategoryService.getCategoryTree()` çağırırsanız tenant filtresi devreye girmez ve berkspt gibi tek-sektör firmalar başka sektörlerin kategorilerini de görür → veri sızıntısı.

## Endpoint Eşlemesi

### `CategoryService` (`/api/category/*`)

- `POST /api/category` — yeni master kategori (admin)
- `PUT /api/category/{id}` — master kategori güncelle (admin)
- `DELETE /api/category/{id}` — soft-delete + cascade `ProductCategory` (admin)
- `GET /api/category/tree` — global ağaç (admin / kategori tanımla ekranı)
- diğerleri için bkz. [[entities/pos-product-manager]]

### `CompanyCategoryService` (`/product/api/company-category/*`)

- `GET /product/api/company-category/list` — firmanın aktif + ACTIVE kategorileri (POS chip)
- `GET /product/api/company-category/my-categories` — firmanın aktif kategorileri ağaç olarak (wizard)
- `GET /product/api/company-category/all-with-selection` — global ağaç + `isSelected` flag (kategori tanımla ekranı)
- `POST /product/api/company-category` — firmaya kategori ekle
- `PUT /product/api/company-category/bulk` — toplu güncelleme
- `DELETE /product/api/company-category/{categoryId}` — firmadan kategori çıkar

## Frontend Karşılığı

```dart
// POS chip / wizard: tenant servisi
ref.read(companyCategoryServiceProvider).getMyCategoryList();

// "Kategori Tanımla" admin ekranı: global ağaç + selection
ref.read(companyCategoryServiceProvider).getAllCategoriesWithSelection();

// Yeni kategori ekleme/düzenleme (admin):
ref.read(categoryServiceProvider).createCategory(...);
```

`CompanyCategoryService` global tarafa ihtiyaç duyduğunda kendi içinde `CategoryService.getCategoryTree()` çağırır (`getMyCategories`, `getAllCategoriesWithSelection`). Frontend sadece tenant servisi tüketir.

## Tipik Hatalar

1. **POS'ta `CategoryService.getAllCategories()` çağırmak** → tenant filtresiz, başka sektör kategorileri sızar.
2. **Admin'de `CompanyCategoryService.bulkSet` ile global kategori "yaratmaya" çalışmak** → `bulkSet` zaten var olan global kategorilerden seçer, yenisini yaratmaz.
3. **`CategoryService.deleteCategory` çağırınca `ProductCategory` orphan kalmasın diye manuel cascade** → Sprint 31 #2 sonrası bu otomatik (`productCategoryService.deactivateAllForCategory(id)`).

## Soft-Delete Akışı

```
DELETE /api/category/{id}
  ├─ children kontrol (varsa hata)
  ├─ ProductCategory cascade: tüm ürün-kategori bağları isActive=false
  └─ Category.isSoftDeleted = true
```

`CompanyCategory` satırları silinmez; çünkü zaten `Category.isSoftDeleted=true` olduğu için `getMyCategoryList` filtresi tarafından elenirler. Firma istediğinde tekrar aktifleşse otomatik çıkar.

## Cross-References

- [[sources/code-refs/2026-05-09-category-system-health-audit]] — gap #9 kaynağı
- [[entities/product-variant]] — variant ↔ category ilişkisi
- [[concepts/multi-tenant]] — `TOpenSimpleCompanyEntity` paterni
- [[concepts/multi-tenant-routing]] — `@Filter company_code` davranışı
