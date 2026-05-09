---
title: Kategori Sistemi Sağlık Denetimi (2026-05-09)
tags: [audit, category, product-category, company-category, multi-tenant, pos, sprint-30-followup]
source: 3 paralel Explore agent çıktısı (frontend catalog scan + backend catalog/product scan + POS-Category integration deep-dive)
date: 2026-05-09
status: verified
---

# Kategori Sistemi Sağlık Denetimi (Sprint 30 sonrası genel sağlık kontrolü)

Sprint 30 yazıcı + barkod okuyucu işi tamamlandı. Kullanıcı: *"şimdi ürün kategorileri hakkında ekran ve backendden bilgi toplap analiz et"* → genel sağlık check niyetiyle kategori modülü envanteri + tespit edilen eksiklerin gelecek sprint'lere referans olarak belgelenmesi.

> **Önemli:** Bu sayfa **audit-only** — 14 eksik tespit edildi ama kod değişikliği YAPILMADI. Kullanıcı talebi: ileride iş listesi olarak kalsın. Her bir gap için ayrı sprint planı, talep geldiğinde yazılır.

## Yönetici Özeti

- **Genel modül olgunluğu:** %85 — CRUD tam, hierarchy + multi-tenant solid
- **POS entegrasyonu olgunluğu:** **%50** — temel düzey çalışıyor, backend'de tasarlanan ileri özellikler frontend'e taşınmamış
- **14 eksik tespit edildi:** A. Genel (9) — 5 backend + 4 frontend; B. POS-Category uyumu (5)
- **Kritik bug:** Soft-delete kod **yorum satırında** ([CategoryServiceImpl.java:199](pos-product-manager/src/main/java/com/sedcore/catalog/service/impl/CategoryServiceImpl.java#L199)) — DELETE çağrısı kaydı silmiyor
- **Yarısı yapılmış feature:** `ProductCategory` Amazon-style multi-kategori tablosu backend'de var ama `ProductResponse.categories[]` API'de döndürülmediği için frontend kullanamıyor

## Tetikleyici

Kullanıcı (2026-05-08): *"şimdi ürün kategorileri hakkında ekran ve backendden bilgi toplap analiz et"* + takip sorusu *"peki pos ekranındaki kategori ile uyumlumu yapı tam anlamıyıla?"*

`AskUserQuestion` ile niyet netleştirildi:
- **Yön:** Sadece analiz raporu — kod değişikliği yok
- **Bağlam:** Genel sağlık check (Sprint 30'dan sonra başka bir modülün durumunu anlamak)

## A. Genel Modül Envanteri

### Backend ([pos-product-manager/](pos-product-manager/))

#### 3 Entity

**1. `Category` (global pool — tenant-scoped DEĞİL):**
- Path: `src/main/java/com/sedcore/catalog/entity/Category.java`
- Alanlar: `id`, `name`, `slug` (unique), `description`, `imageUrl`, `icon`, `sortOrder`, `level`, `path`
- Status enum: `DRAFT`, `ACTIVE`, `INACTIVE`, `ARCHIVED`
- Hierarchy: `parent_id` (`@ManyToOne`), `children` (`@OneToMany`, cascade=ALL, LAZY)
- Relations: `variants`, `attributes` (her ikisi `@OneToMany`, LAZY)
- Soft delete: `isSoftDeleted` boolean
- SEO: `metaTitle`, `metaDescription`, `metaKeywords`
- Metadata: JSONB field
- Transient: `childrenCount`, `variantCount`, `attributeCount`, `productCount`

**2. `CompanyCategory` (tenant-binding — junction):**
- Path: `src/main/java/com/sedcore/catalog/entity/CompanyCategory.java`
- Base: `extends TOpenSimpleCompanyEntity` → otomatik `@Filter company_code`
- Alanlar: `categoryId` (FK), `isActive`, `displayOrder`
- Index: `idx_cc_company_code`, unique constraint (`company_code` + `categoryId`)
- ManyToOne: `category` (LAZY)
- Amaç: SEDCORE firmaları sadece kendi seçtiği kategorileri görür

**3. `ProductCategory` (Amazon-style multi-kategori):**
- Path: `src/main/java/com/sedcore/product/entity/ProductCategory.java`
- Base: `extends TOpenSimpleCompanyEntity` → tenant-scoped
- Alanlar: `productId`, `categoryId`, `isPrimary` (kategori-utama), `isFeatured`, `displayOrder`
- Custom fields: `customName`, `customDescription` (kategori-spesifik product naming)
- Status: `isActive`

#### 16 Endpoint (`@RequestMapping("/api/category")`)

| Method | Path | İşlev |
|---|---|---|
| `POST` | `/api/category` | createCategory(DtoCategoryUI) |
| `PUT` | `/api/category/{id}` | updateCategory(id, DtoCategoryUI) |
| `DELETE` | `/api/category/{id}` | deleteCategory(id) — **bug**: yorum satırında |
| `GET` | `/api/category/{id}` | getCategoryById |
| `GET` | `/api/category` | getAllCategories |
| `GET` | `/api/category/status/{status}` | getCategoriesByStatus |
| `GET` | `/api/category/root` | getRootCategories |
| `GET` | `/api/category/children/{parentId}` | getChildCategories |
| `GET` | `/api/category/tree` | getCategoryTree (3-level nested) |
| `GET` | `/api/category/path/{categoryId}` | getCategoryPath (breadcrumb) |
| `GET` | `/api/category/generate-slug` | generateSlug(name) |
| `PUT` | `/api/category/{categoryId}/sort-order` | updateSortOrder |
| `GET` | `/api/category/{categoryId}/with-relations` | getCategoryWithRelations(flags) |
| `GET` | `/api/category/tree-with-relations` | getCategoryTreeWithRelations |
| `GET` | `/api/category/{categoryId}/with-children` | getCategoryWithChildren(recursive) |
| `POST` | `/api/category/{id}/variants` | addVariantToCategory |

Ek `CompanyCategoryController` (`/product/api/company-category`):
- `GET /list` — tenant flat (POS'ta kullanılan)
- `GET /my-categories` — tenant tree (firma render)
- `GET /all-with-selection` — global + selection flags

### Frontend ([project_pos/](project_pos/))

#### 3 Ekran (`lib/features/catalog/screens/`)

| Dosya | Görev |
|---|---|
| [category_list_screen.dart](project_pos/lib/features/catalog/screens/category_list_screen.dart) | Kategori listele/düzenle/sil — 3 seviye hiyerarşi, arama, status filtre |
| [add_category_screen.dart](project_pos/lib/features/catalog/screens/add_category_screen.dart) | Kategori oluştur/düzenle — form, icon seçimi, parent dropdown |
| [company_category_screen.dart](project_pos/lib/features/catalog/screens/company_category_screen.dart) | Firma-kategori seçimi (global pool → firma seçimi, checkbox tree) |

#### 2 Servis (`lib/features/inventory/services/`)

| Dosya | Endpoint | Kullanan |
|---|---|---|
| [category_service.dart](project_pos/lib/features/inventory/services/category_service.dart) | `/api/category` (global) | catalog ekranları |
| [company_category_service.dart](project_pos/lib/features/inventory/services/company_category_service.dart) | `/product/api/company-category` (tenant) | POS chip filter, ürün ekleme wizard |

#### 1 Notifier

- [company_category_notifier.dart](project_pos/lib/features/catalog/providers/company_category_notifier.dart) — `CompanyCategoryState` + `toggle` / `bulkSet`

#### 4 Route

```
/inventory/categories      → CategoryListScreen (CRUD UI)
/categories/add            → AddCategoryScreen (create)
/categories/edit/:id       → AddCategoryScreen (edit, extra={category})
/categories/company-setup  → CompanyCategoryScreen (firma seçimi) ⚠️ menüde link YOK
```

#### Kullanım Noktaları

| Ekran | Biçim | Dosya |
|---|---|---|
| POS | Yatay chip filter (root kategoriler) | [category_filter_bar.dart:26-42](project_pos/lib/features/pos/widgets/category_filter_bar.dart#L26-L42) |
| Ürün Ekleme Wizard | Modal bottom sheet (hiyerarşik tree, arama, pulse anim) | `lib/features/inventory/.../category_picker.dart:1-509` |
| Firma Kategori Setup | Checkbox tree + select-all/deselect | [company_category_screen.dart:11-100+](project_pos/lib/features/catalog/screens/company_category_screen.dart#L11-L100) |

## B. POS ↔ Kategori Uyumu Deep-Dive

### 10 Kontrol Maddesi Tablosu

| # | Kontrol | Durum | Kanıt |
|---|---|---|---|
| 1 | Servis seçimi (tenant vs global) | ✅ Uyumlu | [pos_provider.dart:367](project_pos/lib/features/pos/providers/pos_provider.dart#L367) → `companyCategoryServiceProvider.getMyCategoryList()` |
| 2 | Endpoint | ✅ Uyumlu | [company_category_service.dart:35](project_pos/lib/features/inventory/services/company_category_service.dart#L35) → `/product/api/company-category/list` |
| 3 | Hierarchy desteği | ⚠️ Kısmen | `level`/`parentId` parse ediliyor ama `category_filter_bar.dart` düz chip listesi render ediyor; root seçince child'lar dahil değil |
| 4 | Status filter (ACTIVE/DRAFT/INACTIVE/ARCHIVED) | ❌ Uyumsuz | Backend `getMyCategoryList()` `isActive` server-side check yok; frontend `pos_provider.dart` filter yok |
| 5 | `isSoftDeleted` filtresi | ❌ Uyumsuz | `Category.java:55-56` alan var ama backend/frontend filter yok |
| 6 | Product-Category eşleşme | ⚠️ Kısmen | `ProductResponse.java:30-31` sadece tek `categoryId`. `ProductCategory.java` multi-kategori tablo var ama API'de `categories[]` döndürülmüyor |
| 7 | `isPrimary` handling | ❌ Uyumsuz | `ProductCategory.isPrimary` var ama `ProductResponse`'ta gelmediği için frontend kullanamıyor |
| 8 | Empty state | ✅ Uyumlu | [pos_screen.dart:335](project_pos/lib/features/pos/screens/pos_screen.dart#L335) kategori boşsa chip bar gizleniyor; `pos_screen.dart:370` "Henüz ürün yok" mesajı |
| 9 | State management (selection) | ✅ Uyumlu | Single-select, `pos_provider.dart:132` `selectedCategoryId`, toggle deselect ([pos_provider.dart:941-947](project_pos/lib/features/pos/providers/pos_provider.dart#L941-L947)) |
| 10 | Sort order (`displayOrder`) | ⚠️ Kısmen | `company_category_service.dart:46` `displayOrder` parse ediliyor ama [pos_provider.dart:369-374](project_pos/lib/features/pos/providers/pos_provider.dart#L369-L374) sort uygulanmıyor; `category_filter_bar.dart:20` ListView unsorted |

### POS Olgunluk Yüzdesi: **%50**

```
Servis & Endpoint (Temel):           ✅ ✅            → 20%
Boş State & State Management:        ✅ ✅            → 8%
Hierarchy Desteği:                    ⚠️                → 5%
Sort Order:                           ⚠️                → 2%
Product-Category Multi:               ⚠️                → 5%
Status/SoftDelete Filter:             ❌ ❌            → 0%
isPrimary Support:                    ❌                → 0%
                                                ────────
                                              Toplam: %50
```

### Kritik Gözlem

Backend'de `ProductCategory` Amazon-style multi-kategori tablosu **tasarlanmış** (entity, FK, `isPrimary`, `isFeatured`, `customName`, `customDescription`, `isActive`) ama `ProductResponse` DTO'sunda `categories[]` döndürülmediği için frontend bu altyapıyı **kullanamıyor**. Yarısı yapılmış feature.

## 14 Detected Gaps

### Genel Kategori Modülü (9 madde)

| # | Katman | Sorun | Konum | Öncelik | Çözüm Önerisi | İş Yükü |
|---|---|---|---|---|---|---|
| 1 | Backend | Soft delete kod **yorum satırında** | [CategoryServiceImpl.java:199](pos-product-manager/src/main/java/com/sedcore/catalog/service/impl/CategoryServiceImpl.java#L199) `setIsDeleted(true)` commented | **P0** | Yorum kaldır + repository `findByIsSoftDeleted(false)` filter doğrulaması | 30 dk |
| 2 | Backend | Product cascade yok — kategori silince `ProductCategory` orphan | `deleteCategory` içinde child cascade yok | **P0** | `ProductCategoryRepository.deleteByCategoryId(id)` eklemesi + soft-delete | 1-2 saat |
| 3 | Backend | Tree endpoint pagination yok | `/api/category/tree` tüm ağacı döner | **P3** | Pagination cursor (level depth limit + page size); günümüzde kataloglar küçük, riskleyen ileride | 4-6 saat |
| 4 | Backend | `@Valid` validation eksik | tüm controller method imzaları | **P2** | `@Valid @RequestBody` + DTO `@NotBlank`/`@Size` annotations | 2-3 saat |
| 5 | Backend | Audit trail yok | tüm entity'ler | **P3** | `@CreatedBy`/`@LastModifiedBy` (`@EnableJpaAuditing` + AuditorAware) — proje çapında etki | 4-6 saat (kategori için 1 saat) |
| 6 | Frontend | `Category` data class yok — `Map<String, dynamic>` her yerde | tüm catalog ekranları + provider | **P1** | `lib/features/catalog/models/category.dart` + `Category.fromJson` + tüm `Map` referansları migrate | 1 gün |
| 7 | Frontend | `/categories/company-setup` menüde link yok | route var, settings/admin'de UI yok | **P2** | `lib/features/settings/screens/settings_screen.dart` veya catalog menü kartına ekle | 1 saat |
| 8 | Frontend | i18n: `categories.*` kullanımı, `bnd-cat-*` patern uyumsuz | catalog ekranları | **P2** | i18n bundle key migration (memory `feedback_project_code_structure.md`) | 2 saat |
| 9 | Mimari | İki paralel servis sınırı net değil | `CategoryService` (admin) vs `CompanyCategoryService` (tenant) | **P3** | Servis kullanım klavuzu (`.wiki/syntheses/` veya inline doc); kod ayrımı zaten doğru | 30 dk doc-only |

### POS-Category Uyumu (5 madde)

| # | Tip | Sorun | Konum | Öncelik | Çözüm Önerisi | İş Yükü |
|---|---|---|---|---|---|---|
| 10 | Status filter | DRAFT/INACTIVE/ARCHIVED kategoriler chip'te görünebilir | [company_category_service.dart:33-53](project_pos/lib/features/inventory/services/company_category_service.dart#L33-L53) (`isActive` parse var, server filter yok); `pos_provider.dart:367` sonrası filter yok | **P0** | Backend `CompanyCategoryServiceImpl.getMyCategoryList()` `WHERE isActive=true` + frontend de defansif filter | 2-3 saat |
| 11 | Multi-kategori | `ProductResponse.categoryId` tek değer, `categories[]` array dönmüyor | [ProductResponse.java:30-31](pos-product-manager/src/main/java/com/sedcore/product/response/ProductResponse.java#L30-L31) vs [ProductCategory.java:8-10](pos-product-manager/src/main/java/com/sedcore/product/entity/ProductCategory.java#L8-L10) | **P1** | `ProductResponse.categories: List<ProductCategoryResponse>` ekle + frontend `filteredProducts` logic update + `category_filter_bar` multi-kategori kontrolü | 1-2 gün |
| 12 | Hierarchy render | `level`/`parentId` parse'leniyor ama düz chip; root seçince child'lar dahil değil | [category_filter_bar.dart:26-42](project_pos/lib/features/pos/widgets/category_filter_bar.dart#L26-L42); `pos_provider.dart:268` (single categoryId match) | **P2** | Tree-aware filter widget (root chip → child chips collapse) + `filteredProducts` descendant logic | 1 gün |
| 13 | Sort order | `displayOrder` parse'leniyor ama liste sıralaması apply'lenmiyor | [pos_provider.dart:369-374](project_pos/lib/features/pos/providers/pos_provider.dart#L369-L374) (sort yok); `category_filter_bar.dart:20` (unsorted) | **P3** | `categories.sort((a,b) => a.displayOrder.compareTo(b.displayOrder))` | 1 saat |
| 14 | isPrimary | `ProductCategory.isPrimary` flag var ama API'de gelmediği için kullanılamıyor | `ProductResponse.java` (alanlar yok); `ProductCategory.java:36-73` (entity'de var) | **P3** | #11 ile birlikte (`ProductCategoryResponse.isPrimary` field) | #11 ile dahil |

## Tavsiye Edilen Sprint Sırası

```
Sprint 31 — P0 Bug-Fix Sprint
  → #1: Soft-delete unyorum (30 dk)
  → #2: Product cascade (1-2 saat)
  → #10: Status filter — POS'ta yanlış kategori gösterimi (2-3 saat)

Sprint 32 — P1 Feature Sprint
  → #11: Multi-kategori categories[] API + frontend (1-2 gün)
  → #6: Frontend Category data class (1 gün)

Sprint 33 — P2 UX/Polish Sprint
  → #12: Hierarchy render (1 gün)
  → #7: Company-setup menü linki (1 saat)
  → #4: @Valid validation (2-3 saat)
  → #8: i18n bnd-cat-* migration (2 saat)

Sprint 34+ Backlog (P3)
  → #3, #5, #9, #13, #14 (audit, pagination, sort, isPrimary, doc)
```

**Not:** Bu sıra önerisi — kullanıcı talebine göre değişebilir. Her sprint için ayrı plan dosyası, talep geldiğinde yazılır.

## Cross-References

- [[syntheses/integrations-hub-architecture]] — 3-katman extension paterni (kategori sistemi de benzer global+tenant ayrımı kullanıyor)
- [[entities/product-variant]] — variant tarafı (kategori-variant ilişkisi `Category.variants` üzerinden)
- [[entities/company-setting]] — sektör + profil (sektöre göre default kategori önerisi gelecek özelliği için)
- [[concepts/multi-tenant]] — `TOpenSimpleCompanyEntity` paterni (CompanyCategory + ProductCategory bunu kullanıyor; Category global pool dışında)
- [[log]] — 2026-05-09 sprint-30-category-audit entry

## Kullanılan Kaynaklar

- 3 paralel Explore agent çıktısı:
  1. Frontend catalog scan (`project_pos/lib/features/catalog/`, `inventory/services/`, `pos/widgets/`)
  2. Backend catalog/product scan (`pos-product-manager/src/main/java/com/sedcore/catalog/`, `product/`)
  3. POS-Category integration deep-dive (10 kontrol maddesi `pos_screen.dart` + `pos_provider.dart` + `category_filter_bar.dart` + `ProductResponse.java`)
