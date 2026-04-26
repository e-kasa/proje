---
title: CLAUDE.md — SEDCORE POS · Proje Kökü
type: source
source: CLAUDE.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: claude-md
note: Bu Claude Code auto-load dosyasının arşiv kopyasıdır. Orijinal yerinde 1-satır stub vardır.
---

---
project: SEDCORE POS
type: multi-tenant POS backend + Flutter/React frontend
sector-default: autoParts
last-verified: 2026-04-16
---

# CLAUDE.md — SEDCORE POS · Proje Kökü

> **Önce `.wiki/sources/code-refs/claude-INDEX.md`'yi aç** — görev bazlı doküman navigasyonu oradadır.  
> Tekrar eden bilgi `/.claude/reference/` altında tek kaynakta tutulur.

---

## 1. PROJE ÖZETİ

**SEDCORE POS** — küçük/orta ölçekli perakende için çok kiracılı kurumsal yönetim sistemi.  
Öncelikli sektör: **yedek parçacılar**.

Modüller: POS / Satış, Stok, Satın Alma, Toplu Ürün Girişi, Cari Hesap, Raporlar, Araç Uyumu, Çok Kiracı.  
Roller: `ADMIN` → `STORE_ADMIN` → `CASHIER` → `WAREHOUSE` → `SUPER_ADMIN`.  
Sektörler: `autoParts` / `general` / `technology` / `footwear` — detay: `.wiki/concepts/sector-strings.md`.

**Karar kriteri:** "Bu, kasiyerin işini hızlandırır mı, işletmecinin kararını kolaylaştırır mı, ya da veri bütünlüğünü korur mu?"

---

## 2. ÇALIŞMA TARZI — ZORUNLU

**Onay isteme, doğrudan yap.** Dosya taşıma, yeniden adlandırma, silme, refactoring → sormadan yap. "Yapalım mı?", "Emin misiniz?" sorma.

---

## 3. SERVİS MİMARİSİ

```
Flutter / React  →  api-manager:8080  →  security:8002 (/security/**)
                                     →  pos-product-manager:8001 (/product/**)
```

| Servis | Port | Context Path | Modül CLAUDE.md |
|--------|------|-------------|-----------------|
| `api-manager` | 8080 | `/` gateway | `api-manager/CLAUDE.md` |
| `security` | 8002 | `/security` | `security/CLAUDE.md` |
| `pos-product-manager` | 8001 | `/product` | `pos-product-manager/CLAUDE.md` |
| `core` | — | Maven lib | `core/CLAUDE.md` |
| `project_pos` (Flutter) | — | — | `project_pos/CLAUDE.md` |
| `template` (React) | — | — | `template/CLAUDE.md` |

### Build Sırası

```bash
cd core && mvn install -q                        # 1. Core (shared lib — önce)
cd security && mvn spring-boot:run               # 2. Auth (8002)
cd pos-product-manager && mvn spring-boot:run    # 3. Backend (8001)
cd api-manager && mvn spring-boot:run            # 4. Gateway (8080)
flutter run -d chrome                            # 5. Flutter
```

### Ortak Altyapı

```
PostgreSQL  : localhost:5432 · db/user/pass: ekalem/ekalem/ekalem
JWT Secret  : BuCokGizliVeUzunBirAnahtarOlmalidir12345! (dev)
Java        : Java 25, Virtual Threads aktif
DDL (dev)   : spring.jpa.hibernate.ddl-auto=create  (bkz. decisions/2026-04-13-ddl-create-strategy.md)
data.sql    : spring.sql.init.mode=always (her startup)
```

---

## 4. TEMEL REFERANSLAR

Bu dosyalar tekrar yerine **tek kaynaktır** — modül CLAUDE.md'leri buraya link verir:

- **URL / prefix kuralı:** `.wiki/concepts/url-routing.md`
- **Multi-tenant akışı:** `.wiki/concepts/multi-tenant-routing.md`
- **JWT payload:** `.wiki/concepts/jwt-payload.md`
- **API response zarfı:** `.wiki/concepts/api-response.md`
- **Sektör stringleri:** `.wiki/concepts/sector-strings.md`

### Kritik Kısa Kurallar

- Backend controller `/api/...` yazar; client `product/` veya `security/` prefix ekler.
- `companyCode` JWT'den gelir — controller'da `@RequestHeader("X-Company-Code")` **yazma**.
- Tüm entity'ler `TOpenSimpleCompanyEntity` extend eder; `@Filter` miras alınır, tekrar eklenmez.
- API zarfı `{success, data, message}` — client `res.data['data']` okur.
- Para alanı `BigDecimal(15,2)`. Soft delete zorunlu.
- Unique constraint compound `(company_code, X)` — tek kolon **yasak**.

---

## 5. DOMAIN ÖZETİ

```
Company ──< UserDef ──< UserRole >── RoleDef
                  └─< UserDefAccess

Company ──< Product ──< ProductVariant ──< VariantPricing
                                       ├──< Barcode
                                       ├──< OemNumber
                                       ├──< CrossReference
                                       └──< VehicleCompatibility >── Vehicle

Category (GLOBAL — TOpenSimpleDbEntity) ──< CategoryAttribute
                                         └──< CategoryVariant
Company ──< CompanyCategory (firma → kategori seçimi)

Company ──< Purchase ──< StockMovement >── ProductVariant
Company ──< Sale ──< SaleItem
                └─< StockMovement
Company ──< Supplier ──< SupplierAccount (@Version)
Company ──< Customer ──< CustomerAccount (@Version)
Company ──< StockLevel (variant × location anlık bakiye, @Version)
Company ──< Store / Warehouse (lokasyon kodları)

Kalıtım: TOpenDbEntity → TOpenSimpleDbEntity → TOpenSimpleCompanyEntity
         (companyCode + @FilterDef "filterCompany" otomatik)
```

Detay:
- Batch entry akışı: `docs/batch-entry-hierarchy.md`
- Modül CLAUDE.md'leri (ör. `pos-product-manager/CLAUDE.md`)

---

## 6. RUNBOOK'LAR

Tekrarlayan işler için hazır tarifler:

- Yeni endpoint: `.wiki/syntheses/runbook-new-endpoint.md`
- Yeni entity: `.wiki/syntheses/runbook-new-entity.md`
- Yeni Flutter feature: `.wiki/syntheses/runbook-new-feature-flutter.md`
- Tenant sızıntısı debug: `.wiki/syntheses/runbook-debug-tenant-leak.md`

---

## 7. i18n

- Tüm UI metinler `security/src/main/resources/data.sql`'de (`message_definitions` tablosu).
- `GET /security/i18n/all?lang=TR` → anahtar:metin map döner.
- Flutter: `i18nOf(ref)` → `t('key')`.
- React: `menuService.getTranslations()` → i18n store.
- Anahtar format: `prefix.snake_case`. ID: `bnd-XX000-0000-0000-NNNNNNNNNNNN`.
- Modül prefix: `bt, wz, pd, st, sl, pu, cu, su, rp, fn, se, au, cm, db`.

---

## 8. MİMARİ KARARLAR (ADR)

Arşiv: `.wiki/decisions/`. Yeni karar eklerken tarihli dosya aç.

Aktif kararlar özeti:
- DDL stratejisi: `create` (dev), `update` (prod ileride)
- Rol kodu: `STORE_ADMIN` standart, `STORE_MANAGER` deprecated
- Lokasyon: `locationId + locationType` (storeId/warehouseId kaldırıldı)
- State management: Riverpod 2.x `StateNotifier` → `AsyncNotifier` (sprint 3)
- Multi-tenant: Hibernate `@Filter` + PostgreSQL RLS (sprint 3)
- PDF: PDFBox sync → Async + Tesseract OCR (sprint 2) → LLM (sprint 4)

---

## 9. SPRINT DURUMU

Güncel sprint + roadmap: `.wiki/sources/status-snapshots/sprint.md`

---

## 10. PRODUCTION-READY KURALLAR (kısa)

1. **1 firma = 1 sektör** — `CompanySetting.sectorType` kurulumda set, sonra değişmez.
2. **Ürün sektörü otomatik firmadan** — `ProductServiceImpl.createProduct()` override eder.
3. **Purchase → storeId zorunlu** — batch flow'da da `setStoreId()` çağrılır.
4. **UserDefAccess sorgusu** — `findByUserDefAndCompanyCode(user, user.getCompanyCode())`.
5. **Store silme** — `isActive=false`, fiziksel silme yasak.

Detaylar ilgili modül CLAUDE.md'sinde.

---

## 11. DOKÜMANTASYON BAKIM KURALLARI

1. **Tekrar yazma** — Bilgi `reference/` altındaysa link ver, kopyalama.
2. **Tarihli notları arşivle** — "2026-04-13 eklendi" gibi notlar `decisions/`'a taşınır.
3. **Örnek kodu 20 satır tutma** — Uzun örnek → runbook'a çıkar.
4. **Frontmatter güncel kalsın** — `last-verified` değişiklik sonrası güncelle.
