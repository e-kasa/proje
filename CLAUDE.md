# CLAUDE.md — SEDCORE POS · Proje Kökü

Her modülün kendi `CLAUDE.md` dosyası var. Buraya **tüm modülleri ilgilendiren** kurallar girer.

---

## 1. PROJE AMACI

**SEDCORE POS** — küçük/orta ölçekli perakende işletmeleri için çok kiracılı (multi-tenant) kurumsal yönetim sistemi. Öncelikli sektör: **yedek parçacılar**.

| Modül | Ne Yapar |
|-------|---------|
| POS / Satış | Barkodlu satış, ödeme, fiş |
| Stok | Gerçek zamanlı seviye, kritik alarm, transfer |
| Satın Alma | Tedarikçi alımı → stok otomatik güncellenir |
| Toplu Ürün Girişi | Batch ekran → tek HTTP çağrısı → Purchase + N ürün/stok |
| Cari Hesap | Borç-alacak, ödeme kaydı |
| Raporlar | Günlük kapanış, satış trendi, kâr analizi |
| Araç Uyumu | OEM / çapraz referans (yedek parça sektörü) |
| Çok Kiracı | Firma kodlarıyla tam izolasyon |

**Roller:** `ADMIN` → `STORE_ADMIN` → `CASHIER` → `WAREHOUSE` → `SUPER_ADMIN`  
**Sektörler:** `autoParts` / `general` / `technology` / `footwear`

> **Karar kriteri:** "Bu, kasiyerin işini hızlandırır mı, işletmecinin kararını kolaylaştırır mı, ya da veri bütünlüğünü korur mu?"

---

## 2. ÇALIŞMA TARZI — ZORUNLU

**Onay isteme, doğrudan yap.**

- Dosya taşıma, yeniden adlandırma, silme, refactoring → sormadan yap.
- Kodu yaz, değişikliği uygula, sonucu raporla.
- "Yapalım mı?", "Emin misiniz?" gibi sorular sorma.

---

## 3. SERVİS MİMARİSİ

```
Flutter / React (baseUrl: localhost:8080)
  └─ /security/**  → api-manager:8080 → security:8002
  └─ /product/**   → api-manager:8080 → pos-product-manager:8001
```

| Servis | Port | Context Path | Modül CLAUDE.md |
|--------|------|-------------|-----------------|
| `api-manager` | **8080** | `/` (gateway) | api-manager/CLAUDE.md |
| `pos-product-manager` | **8001** | `/product` | pos-product-manager/CLAUDE.md |
| `security` | **8002** | `/security` | security/CLAUDE.md |
| `core` | — | Maven lib | core/CLAUDE.md |
| `project_pos` (Flutter) | — | — | project_pos/CLAUDE.md |
| `template` (React) | — | — | template/CLAUDE.md |

### Build Sırası

```bash
cd core && mvn install -q                          # 1. Core (shared lib — önce olmalı)
cd security && mvn spring-boot:run                 # 2. Auth (8002)
cd pos-product-manager && mvn spring-boot:run      # 3. Backend (8001)
cd api-manager && mvn spring-boot:run              # 4. Gateway (8080)
flutter run -d chrome                              # 5. Flutter son
```

### Ortak Altyapı

```
PostgreSQL  : localhost:5432 · db/user/pass: ekalem/ekalem/ekalem
JWT Secret  : BuCokGizliVeUzunBirAnahtarOlmalidir12345!  (dev)
             JWT_SECRET env var (prod)
Java        : Java 25, Virtual Threads aktif (spring.threads.virtual.enabled=true)
DDL         : spring.jpa.hibernate.ddl-auto=update (tablo otomatik güncellenir)
Data.sql    : spring.sql.init.mode=always (her startup'ta çalışır — i18n kayıtlar)
```

---

## 4. DOMAIN MODELİ — TEMEL VARLIKLAR

```
Company ──< UserDef ──< UserRole >── RoleDef
                  └─< UserDefAccess

Company ──< Product ──< ProductVariant ──< VariantPricing
                   │              └──< Barcode
                   └──< OemNumber
                   └──< CrossReference
                   └──< VehicleCompatibility >── Vehicle

Company ──< Category ──< CategoryAttribute
        └──< CompanyCategory

Company ──< Purchase ──< StockMovement >── ProductVariant
Company ──< Sale ──< SaleItem >── ProductVariant
Company ──< Supplier ──< SupplierAccount
Company ──< StockTransfer
Company ──< InventoryView (read-only DB view)

Kalıtım: Tüm entity'ler TOpenSimpleCompanyEntity → TOpenSimpleDbEntity → TOpenDbEntity
```

---

## 5. MULTI-TENANT KURALLARI

Bu kurallar **tüm servisler** için geçerlidir — istisnası yoktur.

```
Her HTTP isteğinde   : X-Company-Code: {companyCode} header'ı zorunlu
Backend ThreadLocal  : CompanyContext.get() → mevcut firmayı verir
Repository           : HER sorguda companyCode filtresi — Hibernate @Filter
Veri sızıntısı       : CompanyIsolationViolationException fırlatılır
```

**Hibernate Filter (tüm entity'lerde zorunlu):**
```java
@Entity
@Filter(name = "companyFilter", condition = "company_code = :companyCode")
public class MyEntity extends TOpenSimpleCompanyEntity { ... }
// CompanyHibernateFilterActivator → her Session'da otomatik aktif edilir
```

**Flutter / React (her request'e otomatik eklenir):**
```dart
// ApiClient interceptor → X-Company-Code: user.selectedCompanyCode
```
```typescript
// axiosClient interceptor → config.headers['X-Company-Code'] = companyCode
```

**Tenant izolasyon akışı (pos-product-manager):**
```
1. HTTP Request → CompanyContextFilter: X-Company-Code → CompanyContext.set(code)
2. JPA Session açılır → CompanyHibernateFilterActivator: @Filter parametresi set edilir
3. Tüm Entity sorguları: WHERE company_code = 'X' otomatik eklenir
4. Servis katmanı da companyCode parametresiyle çalışır (double safety)
5. CompanyIsolationViolationException: farklı firmaya erişilirse fırlatılır
6. Request biter → CompanyContext.clear() (ThreadLocal temizlenir)
```

---

## 6. API RESPONSE STANDARTI

Tüm backend endpoint'leri **aynı zarfı** döner:

```json
// Başarı (tekil):
{ "success": true, "data": { ... }, "message": null }

// Başarı (liste):
{ "success": true, "data": [ ... ], "message": null }

// Hata:
{ "success": false, "data": null, "message": "Hata mesajı", "errorCode": "XXXX" }
```

**Flutter'da her zaman:**
```dart
final items = List<Map<String,dynamic>>.from(response.data['data'] ?? []);
// ❌ response.data['items']  → YANLIŞ
// ✅ response.data['data']   → HER ZAMAN bu key
```

**React/TypeScript'te:**
```typescript
const items = (res.data.data ?? []) as MyType[];
// axios interceptor res.data.data'yı otomatik unwrap edebilir — axiosClient'e bak
```

---

## 7. HATA YÖNETİMİ ZİNCİRİ

```
Backend  → throw TOpenException / BusinessException
         → AppExceptionHandler (@ControllerAdvice)
         → ApiErrorResponse { success: false, message, errorCode }
         → HTTP 400 / 404 / 409 / 500

Flutter  → DioException
         → service: debugPrint + rethrow
         → notifier: state.copyWith(error: e.toString())
         → UI: AppEmptyState.error() veya AppToast.error()

React    → axios catch → dispatch(setError(e.message))
         → component: error state → alert veya toast
```

**Exception hiyerarşisi (pos-product-manager):**
```
BusinessException          → 400 (iş kuralı ihlali)
NotFoundException          → 404 (kayıt bulunamadı)
ConflictException          → 409 (çakışma)
DataConflictException      → 409 (duplicate data)
OperationNotAllowedException → 403 (işlem yasak)
CompanyIsolationViolationException → 403 (tenant sızıntısı — kritik!)
```

---

## 8. SOFT DELETE

```java
// Fiziksel silme yasak — sadece soft delete
entity.setIsDeleted(true);
repo.save(entity);

// Listeleme: findByCompanyCodeAndIsDeletedFalse(...)
// Hibernate filter de isDeleted=false filtreler
```

---

## 9. JWT PAYLOAD YAPISI

```json
{
  "sub": "username",
  "iat": 1234567890,
  "exp": 1234567890,
  "sessionInstance": "{
    \"userInformation\": {
      \"id\": \"uuid\",
      \"username\": \"user\",
      \"displayName\": \"Ad Soyad\",
      \"companyCode\": \"FIRMA001\",
      \"languageVal\": \"tr\",
      \"dynamicLoginParameters\": {
        \"storeId\": \"store-uuid\",
        \"sectorType\": \"AUTO_PARTS\"
      }
    },
    \"roles\": [
      { \"roleName\": \"ADMIN\" }
    ]
  }",
  "tokenType": "new"
}
```

**Kritik:** `sessionInstance` string olarak JWT'ye gömülmüştür.  
Flutter'da: `jsonDecode(payload['sessionInstance'] as String)`  
React'te: `JSON.parse(claims.sessionInstance)`

---

## 10. SEKTÖR YAPISI

| SectorType | apiValue | Özel Alanlar |
|------------|----------|-------------|
| `autoParts` | `AUTO_PARTS` | OEM, çapraz ref, raf kodu, araç uyumu |
| `general` | `GENERAL` | depo konumu |
| `technology` | `TECHNOLOGY` | IMEI, seri no, garanti |
| `footwear` | `FOOTWEAR` | renk, beden/numara |

Sektör tipi `Company.sectorType` alanında saklanır ve JWT `dynamicLoginParameters.sectorType` ile client'a iletilir.

**Kritik kural — sektör string tutarlılığı:**
```dart
// Flutter (wizard_state.dart ve batch_entry_provider.dart):
// ✅ DOĞRU
String get sector => sectorType.apiValue;  // → 'AUTO_PARTS' | 'FOOTWEAR' vb.

// ❌ YANLIŞ — eski Türkçe legacy değerler, veritabanında yanlış depolanır
// 'parcaci', 'giyim', 'genel'  → KULLANMA
```

**Birim (unit) standardı:**
```
Varsayılan birim: 'adet'  (hem wizard hem batch tutarlı kullanır)
Backend Unit tablosunda karşılığı olan kod gönderilmelidir.
```

---

## 11. i18n SİSTEMİ

- Tüm UI metinler `security` servisindeki `data.sql`'de saklanır
- `GET /security/i18n/all?lang=TR` → anahtar:metin map döner
- Flutter: `i18nOf(ref)` → `t('key')` pattern
- React: `menuService.getTranslations()` → i18n store
- `data.sql` her startup'ta çalışır (`spring.sql.init.mode=always`) — `INSERT IF NOT EXISTS`

**Anahtar format:** `prefix.snake_case` (örn: `batch.bulk_product_entry`)  
**ID format:** `bnd-XX000-0000-0000-NNNNNNNNNNNN`

**Modül prefix kodları:**
```
bt=batch, wz=wizard, pd=product, st=stock, sl=sale, pu=purchase
cu=customer, su=supplier, rp=report, fn=finance, se=settings
au=auth, cm=common, db=dashboard
```

---

## 12. YENİ ÖZELLİK EKLEME AKIŞI

```
Backend:
1. Entity         → TOpenSimpleCompanyEntity extends, LAZY ilişkiler, @Filter
2. Repository     → BaseDaoRepository, companyCode parametreli sorgular
3. DTO            → Request (@NotBlank zorunlu alanlar), Response (DtoBaseModel extends)
4. Service        → BaseDbServiceImp, toDTO() mapping, companyCode her metoda
5. Controller     → @RequestHeader("X-Company-Code"), TOpenException → ExceptionMapper
6. data.sql       → i18n mesaj anahtarları ekle

Flutter (Feature-First Mimari):
7. features/<name>/services/<name>_service.dart   → ApiClient inject, response.data['data']
8. features/<name>/di/<name>_di.dart              → Provider<XService> tanımı
9. core/di/service_locator.dart                   → export '<name>_di.dart' ekle
10. features/<name>/providers/<name>_provider.dart → StateNotifier + autoDispose
11. features/<name>/screens/<name>_screen.dart     → ConsumerStatefulWidget, i18n, AppScaffold
12. core/router/app_router.dart                   → GoRoute ekle
13. data.sql                                      → i18n anahtarları ekle
```

---

## 12a. FLUTTER PROJE MİMARİSİ — ÖZET

```
lib/core/      → Altyapı (api, di, router, theme, widgets, utils)
lib/shared/    → Cross-feature (auth/i18n/menu providers, services, models)
lib/features/  → 20 business feature
  ├── auth, dashboard, menu, pos
  ├── inventory (add_product wizard + batch_entry alt yapısı korunur)
  ├── catalog, stock, sales, purchases
  ├── suppliers (upload/ merge dahil), customers, accounts
  ├── finance, reports, import (bulk + scanner merge)
  ├── autoparts (OEM/araç/parça arama)
  ├── warehouse, store, hrm, settings
```

**Eski path'ler (lib/services/, lib/screens/, lib/models/, lib/providers/):**  
Backward compat re-export shim olarak kaldı. Yeni kod her zaman `features/` path'lerini kullanmalı.

**apiClientProvider:** `lib/core/api/api_client.dart`'ta tanımlı.  
**Servis provider'ları:** Her feature'ın `di/<name>_di.dart`'ında tanımlı.  
**Router:** `lib/core/router/app_router.dart`

---

## 13. VERİTABANI ORTAK KURALLARI

Tüm tablolarda zorunlu kolonlar:
```sql
company_code  VARCHAR(8)  NOT NULL   -- tenant izolasyonu
created_at    TIMESTAMP   NOT NULL
updated_at    TIMESTAMP   NOT NULL
is_deleted    BOOLEAN     DEFAULT false
```

Para alanları: `DECIMAL(15,2)` — `double` veya `float` kullanma.  
UUID primary key: `@GeneratedValue(strategy = GenerationType.UUID)`  
Optimistic locking: `@Version Long version` — concurrent düzenleme koruması.
