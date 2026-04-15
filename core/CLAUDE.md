---
module: core
type: Maven shared library (com.towpen:base)
port: —
depends-on: []
touch-when: [entity-base-change, multi-tenant-filter-change, shared-model-change]
last-verified: 2026-04-16
---

# CLAUDE.md — core

Paylaşılan Java kütüphanesi. `security` ve `pos-product-manager` buna bağımlıdır.  
**Build:** `mvn install -q` — diğer servislerden ÖNCE.

Genel kurallar: kök `CLAUDE.md`. Multi-tenant: `.claude/reference/multi-tenant.md`. JWT modelleri: `.claude/reference/jwt-payload.md`.

---

## Amaç

- Entity base class'ları (kalıtım şablonu)
- Multi-tenant izolasyon altyapısı (Hibernate filter superclass)
- JWT/session modelleri (`TOpenSessionInstance`, `TOpenLoginUser`)
- Base service ve repository soyutlamaları
- i18n yönetim sınıfları

---

## Sınıf Hiyerarşisi

```
TOpenDbEntity (abstract)
  │  id: String (UUID)
  └─ TOpenSimpleDbEntity
       │  createTime, lastModifiedTime, createUser, updateUser
       └─ TOpenSimpleCompanyEntity
              companyCode: String  ← tenant izolasyon anahtarı
              @Filter (miras alınır) — bkz. reference/multi-tenant.md
```

**Kural:** Tüm entity'ler `TOpenSimpleCompanyEntity`'den extend eder.  
`Company` entity'si `TOpenDbEntity`'den extend eder (companyCode yoktur).

---

## Base Service

```java
public abstract class BaseDbServiceImp<R extends BaseDaoRepository<T, String>, T extends TOpenSimpleDbEntity>
        implements BaseDbService<T> {
    protected R repository;
    T save(T entity);  T update(T entity);  void delete(String id);
    Optional<T> findById(String id);  List<T> findAll();
    abstract Object toDTO(T entity);
    T findAndCheckById(String id);   // NotFoundException fırlatır
}
```

---

## Base Repository

```java
public interface BaseDaoRepository<T extends TOpenDbEntity, ID>
        extends PagingAndSortingRepository<T, ID>, CrudRepository<T, ID> { }
```

Multi-tenant filter aktif iken `findById(id)`, `findByIsActiveTrue()` vb. otomatik izole.

---

## JwtXUserInfoFilter — Kritik Kural

`com.towpen.base.security.filter.JwtXUserInfoFilter` — tüm `/api/**` path'lerinde JWT zorunluluğu.

```
if (isPublicPath(url))            → bypass
else if (path.startsWith("/api"))
    if (xUserInfo == null)        → 401
    else                          → SecurityContext set
else                              → bypass  (/authenticate gibi)
```

**PUBLIC_PATHS (kod içinde):**
```
/api/rest/sso-log
/i18n
/api/v1/auth/refresh-token
```

> ⚠️ `/api/v1/company/` **EKLEME** — pos-product-manager'da `CompanySetting` endpoint var, eklenirse her iki serviste company endpoint'leri açılır (güvenlik açığı).

Yeni `/api/**` public endpoint eklerken **4 yer senkron**: `.claude/reference/url-routing.md`.

---

## Exception Sistemi

```
TOpenException → (checked) temel exception, core içinden fırlar
```

Modüllerde proje exception'larını kullan (`NotFoundException`, `BusinessException` vb.) — `.claude/reference/api-response.md`.

`ExceptionMapper.map(TOpenException)` → `BusinessException` çevrimi.

---

## i18n Altyapısı

`TOpenMessageManager` / `AbstractMessageManager` — mesaj kayıt ve alma.

```java
@Autowired private TOpenMessageManager messageManager;
String msg = messageManager.getMessage("batch.save_success", "TR");
```

Seed: `security/data.sql`.

---

## Geliştirme Kuralları

**Core'a ekle:**
- Tüm servislerde paylaşılan utility'ler
- Yeni entity base class
- Ortak interceptor/filter

**Ekleme:**
- Business logic (servis özgü)
- Feature entity'leri
- Controller / DTO

**Değişiklik sonrası:**
```bash
cd core && mvn install -q
# Bağımlı servisleri restart et
```

---

## Paket Yapısı (Özet)

```
com.towpen.base/
├── db/
│   ├── model/                   # TOpenDbEntity, TOpenSimpleCompanyEntity, Company, UserDef...
│   └── repository/BaseDaoRepository
├── security/
│   ├── BaseDbServiceImp
│   └── TOpenSessionInstance, TOpenLoginUser, TOpenCompanyInfo
├── i18n/                        # TOpenMessageManager, AbstractMessageManager
└── hibernate/                   # CompanyFilterStatics, CompanyHibernateFilterActivator
```

---

## Sık Yapılan Hatalar

| Hata | Çözüm |
|------|-------|
| Entity'de `@Filter` tekrar ekli | Superclass'ta var, entity'den sil |
| Filter parametresi `companyCode` | Doğrusu `cpCode` |
| Core'a business logic eklemek | Modüle taşı |
| `RoleDef.name unique=true` | Compound: `(company_code, name)` |
| `mvn install` unutmak | Bağımlı servisler eski binary'yi kullanır |
