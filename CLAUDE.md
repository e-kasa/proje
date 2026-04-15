---
project: SEDCORE POS
type: multi-tenant POS backend + Flutter/React frontend
sector-default: autoParts
last-verified: 2026-04-16
---

# CLAUDE.md — SEDCORE POS · Proje Kökü

> **Önce `/.claude/INDEX.md`'yi aç** — görev bazlı doküman navigasyonu oradadır.  
> Tekrar eden bilgi `/.claude/reference/` altında tek kaynakta tutulur.

---

## 1. PROJE ÖZETİ

**SEDCORE POS** — küçük/orta ölçekli perakende için çok kiracılı kurumsal yönetim sistemi.  
Öncelikli sektör: **yedek parçacılar**.

Modüller: POS / Satış, Stok, Satın Alma, Toplu Ürün Girişi, Cari Hesap, Raporlar, Araç Uyumu, Çok Kiracı.  
Roller: `ADMIN` → `STORE_ADMIN` → `CASHIER` → `WAREHOUSE` → `SUPER_ADMIN`.  
Sektörler: `autoParts` / `general` / `technology` / `footwear` — detay: `.claude/reference/sector-strings.md`.

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

- **URL / prefix kuralı:** `.claude/reference/url-routing.md`
- **Multi-tenant akışı:** `.claude/reference/multi-tenant.md`
- **JWT payload:** `.claude/reference/jwt-payload.md`
- **API response zarfı:** `.claude/reference/api-response.md`
- **Sektör stringleri:** `.claude/reference/sector-strings.md`

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
                   │              └──< Barcode
                   └──< OemNumber
                   └──< CrossReference
                   └──< VehicleCompatibility >── Vehicle

Company ──< Category ──< CategoryAttribute
Company ──< Purchase ──< StockMovement
Company ──< Sale ──< SaleItem
Company ──< Supplier ──< SupplierAccount

Kalıtım: TOpenSimpleCompanyEntity → TOpenSimpleDbEntity → TOpenDbEntity
```

Detay: modül CLAUDE.md'leri (ör. `pos-product-manager/CLAUDE.md`).

---

## 6. RUNBOOK'LAR

Tekrarlayan işler için hazır tarifler:

- Yeni endpoint: `.claude/runbooks/new-endpoint.md`
- Yeni entity: `.claude/runbooks/new-entity.md`
- Yeni Flutter feature: `.claude/runbooks/new-feature-flutter.md`
- Tenant sızıntısı debug: `.claude/runbooks/debug-tenant-leak.md`

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

Arşiv: `.claude/decisions/`. Yeni karar eklerken tarihli dosya aç.

Aktif kararlar özeti:
- DDL stratejisi: `create` (dev), `update` (prod ileride)
- Rol kodu: `STORE_ADMIN` standart, `STORE_MANAGER` deprecated
- Lokasyon: `locationId + locationType` (storeId/warehouseId kaldırıldı)
- State management: Riverpod 2.x `StateNotifier` → `AsyncNotifier` (sprint 3)
- Multi-tenant: Hibernate `@Filter` + PostgreSQL RLS (sprint 3)
- PDF: PDFBox sync → Async + Tesseract OCR (sprint 2) → LLM (sprint 4)

---

## 9. SPRINT DURUMU

Güncel sprint + roadmap: `.claude/status/sprint.md`

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
