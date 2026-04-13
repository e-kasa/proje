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

### URL Kuralı — KRİTİK

**Backend controller** sadece `/api/...` yazar — service prefix olmadan.  
**Flutter/React** her zaman service prefix ekler — api-manager (8080) üzerinden geçer.

```
Backend Controller       Flutter/React URL (api-manager üzerinden)
────────────────────────────────────────────────────────────────────
security:
  @RequestMapping("/authenticate")       →  security/authenticate
  @RequestMapping("/api/v1/auth/...")    →  security/api/v1/auth/...
  @RequestMapping("/api/users")          →  security/api/users
  @RequestMapping("/i18n/all")           →  security/i18n/all

pos-product-manager:
  @RequestMapping("/api/v1/products")    →  product/api/v1/products
  @RequestMapping("/api/v1/stores")      →  product/api/v1/stores
  @RequestMapping("/api/v1/categories")  →  product/api/v1/categories
```

**Kural:** Flutter'da hiçbir zaman `localhost:8001` veya `localhost:8002` kullanılmaz.  
Tüm istekler `localhost:8080` (api-manager) üzerinden prefix ile gönderilir.

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

### 5a. CompanyCode Kaynağı — Tek Doğruluk Noktası

**companyCode JWT token içinde zaten vardır** (`sessionInstance → userInformation → selectedCompanyCode`).  
`JwtXUserInfoFilter` → JWT'yi parse eder → `TOpenContextHolder.set(companyCode)` → ThreadLocal'e yazar.  
`CompanyHibernateFilterActivator` → `TOpenContextHolder.get()` → Hibernate `@Filter` parametresini set eder.

```
JWT (sessionInstance.userInformation.selectedCompanyCode)
  └─ JwtXUserInfoFilter.createAuthToken()
       └─ TOpenContextHolder.setContext(companyCode)
            └─ CompanyHibernateFilterActivator (her Session'da)
                 └─ session.enableFilter("companyFilter").setParameter("companyCode", ...)
                      └─ TÜM find* sorgularına otomatik WHERE company_code = 'X' eklenir
```

**Controller'da `@RequestHeader("X-Company-Code")` gereksizdir** — companyCode zaten context'te.  
Servis katmanında `CompanyContext.get()` ile alınır.

```java
// ❌ GEREKSIZ — token'da zaten var
public ResponseEntity<?> getAll(@RequestHeader("X-Company-Code") String companyCode) { ... }

// ✅ DOĞRU — context'ten al
public ResponseEntity<?> getAll() {
    return ResponseEntity.ok(service.getAll());
    // service içinde: CompanyContext.get() veya Hibernate @Filter otomatik
}
```

**Yazma işlemlerinde (entity oluştururken):**
```java
// ✅ DOĞRU — context'ten al
entity.setCompanyCode(CompanyContext.get());
```

### 5b. Hibernate @Filter — TOpenSimpleCompanyEntity'de Tanımlı, Her Subclass Miras Alır

`@FilterDef` ve `@Filter` **`TOpenSimpleCompanyEntity` superclass'ında** tanımlıdır.  
Extend eden her entity otomatik olarak bu filtreyi miras alır — **entity'lere tekrar eklenmez.**

```java
// core kütüphanesinde (TOpenSimpleCompanyEntity):
@MappedSuperclass
@FilterDef(name = "filterByCompanyCode",
           parameters = @ParamDef(name = "cpCode", type = String.class),
           defaultCondition = "company_code in(:cpCode)")
@Filter(name = "filterByCompanyCode", condition = "company_code in(:cpCode)")
public class TOpenSimpleCompanyEntity extends TOpenSimpleDbEntity { ... }

// Entity'de TEKRAR eklenmez — miras yeterli:
@Entity
public class Store extends TOpenSimpleCompanyEntity { ... }  // ✓ filter miras alındı

// ❌ YANLIŞ — entity'ye tekrar @Filter/@FilterDef ekleme → çakışma!
@FilterDef(...)  // GEREKSIZ
@Filter(...)     // GEREKSIZ
@Entity
public class Store extends TOpenSimpleCompanyEntity { ... }
```

**Filter parametreleri:**
- Filter adı: `filterByCompanyCode` (`CompanyFilterStatics.FILTER_COMPANY`)
- Parametre: `cpCode` (dikkat: `companyCode` değil!)
- Koşul: `company_code in(:cpCode)`

**`CompanyHibernateFilterActivator` — AOP ile tüm servis metodlarını yakalar:**
```java
// Doğru pointcut — com.sedcore altındaki tüm modül servisleri:
@Around("execution(public * com.sedcore..service..*(..))")
// ✓ com.sedcore.inventory.service.impl.StoreServiceImpl
// ✓ com.sedcore.product.service.impl.ProductServiceImpl

// ❌ YANLIŞ (eski hatalı pattern):
@Around("execution(public * com.sedcore.service..*(..))")
// → com.sedcore.service.* paketi yok → filter hiç çalışmaz → TÜM firmalar görünür!
```

**Repository — companyCode parametresi GEREKMEZ (Hibernate halleder):**
```java
List<Store> findByIsActiveTrue();     // → WHERE is_active=true AND company_code IN('X')
Optional<Store> findById(String id);  // → WHERE id=? AND company_code IN('X')
```

### 5c. Tenant İzolasyon Akışı

```
1. HTTP Request → CompanyContextFilter: X-Company-Code header → CompanyContext.set(code)
2. Service metodu çağrılır → CompanyHibernateFilterActivator AOP devreye girer
3. session.enableFilter("filterByCompanyCode").setParameter("cpCode", companyCode)
4. Tüm find* sorguları: WHERE company_code IN('X') otomatik eklenir
5. Yazma: entity.setCompanyCode(CompanyContext.get())
6. Metod biter → session.disableFilter() (AOP finally bloğu)
7. Request biter → CompanyContext.clear() (ThreadLocal temizlenir)
```

### 5d. Yeni Entity Eklerken Kontrol Listesi

```java
// ✓ TOpenSimpleCompanyEntity extend et — @Filter miras alınır, tekrar yazma
@Entity
public class MyEntity extends TOpenSimpleCompanyEntity { ... }

// ✓ Servis paketi com.sedcore.{modul}.service altında olmalı
// → CompanyHibernateFilterActivator AOP pointcut'u yakalar
package com.sedcore.mymodule.service.impl;  // ✓
package com.sedcore.service.impl;           // ❌ böyle paket yok
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
      \"userId\": \"uuid\",
      \"userName\": \"user\",
      \"displayName\": \"Ad Soyad\",
      \"selectedCompanyCode\": \"FIRMA001\",
      \"languageVal\": \"tr\",
      \"sessionId\": null,
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

**JWT parse kritik kuralları (Flutter):**
```dart
// ✅ DOĞRU — JSON alan adları TOpenLoginUser Java field adlarından gelir (Gson)
userInfo['userId']              // id değil
userInfo['userName']            // username değil
userInfo['selectedCompanyCode'] // companyCode değil
userInfo['sessionId'] as String? ?? ''  // nullable — null cast YASAK

// ✅ DOĞRU — roller [{roleName: "ADMIN"}] formatında gelir
(session['roles'] as List).map((e) => (e as Map)['roleName'] as String).toList()

// ❌ YANLIŞ
payload['sessionId'] as String  // sessionId null olabilir → TypeError
e.toString()                    // {roleName: ADMIN} string'i üretir — YANLIŞ
```

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

---

## 14. PRODUCTION-READY KURALLAR (2026-04-13 eklendi)

### 1 Firma = 1 Sektör (Değiştirilemez)

```java
// CompanySettingServiceImpl.updateSettings() → sectorType güncellenmez
// Firma kurulumunda (CompanyRegistrationService) bir kez set edilir
// Değiştirmek isteyenler: firmayı yeniden kaydetmelidir
```

`sectorType` kaynağı: `CompanySetting.sectorType` (Company tablosu değil)

### Ürün Sektörü Zorunlu Eşleşmesi

```java
// ProductServiceImpl.createProduct() → sector firmadan otomatik alınır
// dto.getProduct().getSector() override edilir — cross-sector contamination önlenir
String companySector = companySettingRepository
    .findFirstByCompanyCodeOrderByCreateTimeDesc(CompanyContext.get())
    .map(s -> s.getSectorType())
    .orElse(dto.getProduct().getSector());
```

### Purchase → storeId Zorunlu

`purchases` tablosunda `store_id` kolonu var.  
`PurchaseRequest.storeId` → `Purchase.storeId` → DB'ye yazılır.  
`ProductServiceImpl` içindeki batch Purchase'da da `setStoreId()` çağrılır.

### UserDefAccess Multi-Tenant Sorgusu

```java
// GİRİŞ (login): findByUserDefAndCompanyCode(userDef, userDef.getCompanyCode())
//   → findFirstByUserDef değil! Her user için companyCode filtresi zorunlu
// Aynı kullanıcı birden fazla firmada UserDefAccess'e sahip olabilir (dev seed durumu)
```

### Mağaza Silme (Soft Delete)

```java
// StoreService.deleteStore(id, companyCode) → isActive = false
// StoreRepository.findByIdAndCompanyCode(id, companyCode) kullanır
```

### Rol Kodu Standardı

| Kod | Açıklama | is_system_role |
|-----|---------|---------------|
| `ADMIN` | Firma yöneticisi | true |
| `STORE_ADMIN` | Mağaza yöneticisi (**standart**) | true |
| `CASHIER` | Kasiyer | false |
| `WAREHOUSE` | Depo sorumlusu | false |
| `SUPER_ADMIN` | Platform geneli | true |
| `STORE_MANAGER` | ESKİ — data.sql migrasyon ile STORE_ADMIN'e geçirilir | false |

`data.sql` sonunda `UPDATE user_role SET role_def_id=STORE_ADMIN WHERE role_def_id=STORE_MANAGER` çalışır.

### DDL Stratejisi (Dev)

```properties
spring.jpa.hibernate.ddl-auto=create   # Her startup DROP+CREATE → data.sql temiz çalışır
```

`create-drop` **KULLANMA** — sadece startup'ta CREATE, shutdown'da DROP yapar. Crash sonrası eski data kalır → ON CONFLICT tuzakları tetiklenir.

### Multi-Tenant Unique Constraint

Entity'lerde `unique = true` → **global unique** → farklı firmalar aynı değeri kullanamaz → multi-tenant kırar.  
Her unique constraint **`(company_code, alan)` compound** olmalı. Bkz. `core/CLAUDE.md §10`.

**Örnek hata:** `RoleDef.name unique=true` → SEDCORE1 rolleri SEDCORE'dan sonra `ON CONFLICT DO NOTHING` ile atlandı → FK violation. Düzeltildi: `@Table(uniqueConstraints = @UniqueConstraint(columnNames = {"company_code", "name"}))`.

### Seed Data Sorumlulukları

| Tablo | Hangi servis |
|-------|-------------|
| company, role_def, user_def, user_def_access, user_role | **security/data.sql** |
| stores, warehouses, products, categories, vb. | **pos-product-manager/data.sql** |
| UPDATE user_def SET store_id | **pos-product-manager/data.sql** (mağazalar sonra) |

pos-product-manager/data.sql'e **kullanıcı/rol INSERT'i ekleme.**

---

## 15. MİMARİ KARAR KAYITLARI (ADR) — 2026-04-13

### 15.1 Flutter State Management

**Karar:** Riverpod 2.x `StateNotifier` devam — `AsyncNotifier`'a kademeli geçiş.

```
StateNotifier → load() barındıran ekranlarda AsyncNotifier ile replace edilecek.
BLoC / GetX / MobX: denenmeyecek (Riverpod yatırımı korunuyor).
freezed paketi: copyWith() boilerplate azaltmak için sprint 3'te eklenecek.
Riverpod 3.x (@riverpod annotation): stabil olduğunda migrate edilecek.
```

### 15.2 Flutter Mimari Pattern

**Karar:** Feature-First devam + Repository Layer sprint 3'te eklenir.

```
Şu an:   Service → ApiClient (direkt)
Sprint 3: Service → Repository → ApiClient
         Repository: API transformation, mock testability, tek sorumluluk

lib/screens/ → lib/features/ migration: batch_entry + wizard taşınacak (router güncellenecek)
DDD: Stok hareketi domain logic için düşünülebilir (sprint 4)
```

### 15.3 Backend Servis Mimarisi

**Karar:** Modular Monolith devam — Event-Driven raporlama için sprint 4.

```
api-manager (Gateway) → Spring Cloud Gateway (değişmeyecek)
pos-product-manager   → Modular Monolith (şimdilik tek JAR)
Event-Driven (Kafka)  → Sprint 4: satış raporlama async, batch değil
CQRS                  → Lite (inventory_view zaten var) — full sprint 4+
Full Microservices    → 1000+ transaction/gün olunca değerlendirilecek
```

### 15.4 Multi-Tenant Mimari

**Karar:** Row-level (Hibernate @Filter) devam + PostgreSQL RLS sprint 3.

```
Şu an:    Hibernate @Filter (application-level)
Sprint 3: PostgreSQL RLS double-safety eklenecek:
          CREATE POLICY tenant_policy ON products
            USING (company_code = current_setting('app.current_company_code'));

Schema-per-tenant: GDPR zorunlu olursa değerlendirilecek
Database-per-tenant: over-engineering, planlanmıyor
Redis tenant-aware cache: Sprint 2 (kategori/marka/birim listeleri)
```

### 15.5 Stok Concurrent Update

**Karar:** Optimistic Locking (@Version) — Sprint 2.

```
Şu an:  Direkt write → lost update riski (2 kasiyer aynı ürün → ghost update)
Sprint 2: ProductVariant'a @Version Long version alanı eklenir
          ObjectOptimisticLockingFailureException → max 3 retry + exponential backoff
          Pessimistic Lock kullanılmayacak (POS latency problemi)
```

### 15.6 Gerçek Zamanlı Bildirim

**Karar:** WebSocket (SSE fallback) — Sprint 2.

```
Şu an:  REST polling (5-10s interval)
Sprint 2: Spring WebSocket (/topic/stock/{companyCode})
          Flutter: web_socket_channel paketi
          SSE: WebSocket unavailable olunca fallback
          Multi-tenant: channel namespace = companyCode
```

### 15.7 PDF/Belge İşleme

**Karar:** PDFBox (sync) → Async job + Tesseract fallback (sprint 2) → LLM (sprint 4).

```
Şu an:  PDFBox sync (metin PDF ✅, taranmış ❌)
Sprint 1: KDV + birim extract, loading spinner, hata detayı (TAMAMLANMADI)
Sprint 2: Async job (polling), Tesseract OCR fallback (taranmış PDF)
Sprint 4: LLM fallback (Claude/GPT-4o) — PDFBox başarısız ise
          Scoped: invoice data privacy → önce self-hosted (Ollama) değerlendir

iText: Ticari lisans gerektirir ($$$) → kullanılmayacak
Google Vision / AWS Textract: KVKK sorunu, maliyet → sprint 4'te değerlendirilecek
```

### 15.8 Offline Destek

**Karar:** sqflite var, sync stratejisi sprint 4.

```
Şu an:  sqflite (cart local storage, sync yok)
Sprint 4: SyncQueue tablosu → offline işlemleri kuyruğa al → online → gönder
          Conflict resolution:
            stok yetersiz → partial accept (kullanıcıya sor)
            fiyat değişti → online fiyat kullan, kullanıcıya bildir
            ürün silinmiş → sync engelle, kullanıcıya uyar
```

### 15.9 Aktif Sprint Durumu (2026-04-13)

```
SPRINT 1 — DEVAM EDİYOR:
  ✅ PDF altyapısı (PDFBox, Flutter servis, result sheet, upload butonu)
  🔴 KDV + birim extract (backend + flutter)
  🔴 Loading spinner + hata detayı
  🔴 İsim eşleşmesi kullanıcı onay UI
  🔴 Gerçek fatura ile uçtan uca test

SPRINT 2 — PLANLI:
  - Optimistic locking (@Version)
  - Redis cache (kategori/marka listeleri)
  - Async PDF analiz
  - Tesseract OCR fallback
  - WebSocket stok alarm

SPRINT 3 — PLANLI:
  - lib/screens/ → lib/features/ migration
  - AsyncNotifier geçişi + freezed
  - Repository Layer
  - PostgreSQL RLS

SPRINT 4 — UZUN VADE:
  - LLM PDF fallback
  - Offline sync
  - Event-Driven raporlama
  - Full CQRS
```
