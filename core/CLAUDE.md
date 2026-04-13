# CLAUDE.md — core (Paylaşılan Java Kütüphanesi)

Genel kurallar için kök `CLAUDE.md`'e bak.  
**Maven koordinatı:** `com.towpen:base` · `security` ve `pos-product-manager` bu kütüphaneye bağımlıdır.  
**Build komutu:** `mvn install -q` — diğer servislerden ÖNCE build edilmeli.

---

## 1. KÜTÜPHANENIN AMACI

`core`, `security` ve `pos-product-manager` modülleri arasında paylaşılan:
- Entity base class'ları (kalıtım şablonu)
- Multi-tenant izolasyon altyapısı (Hibernate filter)
- JWT/session modelleri
- Base service ve repository soyutlamaları
- i18n yönetim sınıfları

---

## 2. TEMEL SINIF HİYERARŞİSİ

```
TOpenDbEntity (abstract)
  │  id: String (UUID, @Id @GeneratedValue UUID)
  └─ TOpenSimpleDbEntity
       │  createTime: Date
       │  lastModifiedTime: Date
       │  createUser: String
       │  updateUser: String
       └─ TOpenSimpleCompanyEntity
              companyCode: String  ← Tenant izolasyon anahtarı
              @Filter(name = "companyFilter", condition = "company_code = :companyCode")
```

**Kural:** Tüm entity'ler `TOpenSimpleCompanyEntity`'den extend eder.  
`Company` entity'si `TOpenDbEntity`'den extend eder (companyCode yoktur, firmalar arası değildir).

---

## 3. ENTITY ŞABLONU (Tüm Servislerde Standart)

```java
@Entity
@Table(name = "my_table")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@FilterDef(name = "companyFilter", parameters = @ParamDef(name = "companyCode", type = String.class))
@Filter(name = "companyFilter", condition = "company_code = :companyCode")
public class MyEntity extends TOpenSimpleCompanyEntity {

    @Column(nullable = false, length = 500)
    private String name;

    @Enumerated(EnumType.STRING)
    private MyStatus status;

    // İlişkiler — HER ZAMAN LAZY
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    private ParentEntity parent;

    @OneToMany(mappedBy = "myEntity", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ChildEntity> children = new ArrayList<>();

    // JSONB için (PostgreSQL)
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private Map<String, Object> metadata;

    @Column(name = "is_deleted")
    private Boolean isDeleted = false;

    @Version
    private Long version;  // Optimistic locking — concurrent düzenleme koruması
}
```

---

## 4. BASE SERVICE — BaseDbServiceImp

```java
// Tüm servisler bu sınıftan extend eder
public abstract class BaseDbServiceImp<R extends BaseDaoRepository<T, String>, T extends TOpenSimpleDbEntity>
        implements BaseDbService<T> {

    protected R repository;   // inject edilir

    // CRUD metotları:
    T save(T entity)
    T update(T entity)
    void delete(String id)
    Optional<T> findById(String id)
    List<T> findAll()

    // Dönüşüm — her servis override eder:
    abstract Object toDTO(T entity)
    abstract Class<?> getDTOClassForService()

    // Yardımcı:
    T findAndCheckById(String id)   // bulamazsa NotFoundException fırlatır
    boolean existsById(String id)
}
```

**Kullanım:**
```java
@Service
@Transactional
public class MyServiceImpl extends BaseDbServiceImp<MyRepository, MyEntity>
        implements MyService {

    @Override
    public Class<?> getDTOClassForService() {
        return MyResponseDto.class;
    }

    @Override
    protected MyResponseDto toDTO(MyEntity entity) {
        return MyResponseDto.builder()
            .id(entity.getId())
            .name(entity.getName())
            .build();
    }
}
```

---

## 5. BASE REPOSITORY — BaseDaoRepository

```java
// Tüm repository'ler bu interface'den extend eder
public interface BaseDaoRepository<T extends TOpenDbEntity, ID>
        extends PagingAndSortingRepository<T, ID>,
                CrudRepository<T, ID> {
    // Spring Data JPA metotlarının tamamı kullanılabilir
}

// Uygulama:
@Repository
public interface MyRepository extends BaseDaoRepository<MyEntity, String> {

    // HER sorguda companyCode zorunlu — istisnasız
    List<MyEntity> findByCompanyCodeAndIsDeletedFalse(String companyCode);

    Optional<MyEntity> findByIdAndCompanyCodeAndIsDeletedFalse(String id, String companyCode);

    @Query("SELECT e FROM MyEntity e " +
           "WHERE e.companyCode = :cc AND e.name LIKE %:q% AND e.isDeleted = false " +
           "ORDER BY e.createTime DESC")
    List<MyEntity> searchByName(@Param("cc") String cc, @Param("q") String q);
}
```

---

## 6. GÜVENLİK MODELLERİ

### TOpenSessionInstance
JWT payload'unun `sessionInstance` alanına yazılan nesne:

```java
TOpenSessionInstance {
    TOpenLoginUser userInformation;
    List<RoleInfo> roles;
}

TOpenLoginUser {
    String userId;
    String userName;
    String displayName;
    String selectedCompanyCode; // JSON key: "selectedCompanyCode" (Gson field adını kullanır)
    String languageVal;         // "tr" | "en"
    String email;
    String sessionId;           // nullable — null-safe cast zorunlu
    Map<String, Object> dynamicLoginParameters;
    // dynamicLoginParameters: {"storeId": "uuid", "sectorType": "AUTO_PARTS"}
}

RoleInfo {
    String roleName;            // "ADMIN" | "STORE_ADMIN" | "CASHIER" | "WAREHOUSE"
}

TOpenCompanyInfo {
    boolean isSelected;
    String companyCode;
    String companyName;
}
```

---

## 6a. JwtXUserInfoFilter — KRITIK DAVRANIŞ KURALI

`com.towpen.base.security.filter.JwtXUserInfoFilter` — tüm `/api/**` path'lerinde JWT zorunluluğu uygular.

```java
// Çalışma mantığı:
if (isPublicPath(requestURL))   → chain.filter() // bypass
else if (path.startsWith("/api"))
    if (xUserInfo == null)      → 401 prepareNoAccessError()
    else                        → SecurityContext set, devam
else                            → chain.filter() // /authenticate gibi non-/api path'ler

// PUBLIC_PATHS (token gerektirmeyen /api path'leri):
"/api/rest/sso-log"
"/i18n"
"/api/v1/auth/refresh-token"   // ← Refresh endpoint — JWT olmadan erişilmeli
// ⚠️ "/api/v1/company/" EKLEME — pos-product-manager'da CompanySetting endpointi var,
//    eklenmesi HER İKİ SERVİSTE company endpointlerini JWT'siz açar (güvenlik açığı)!
```

**Kritik kural:** Yeni bir `/api/**` public endpoint eklendiğinde:
1. `core/JwtXUserInfoFilter.PUBLIC_PATHS`'e ekle
2. `security/SecurityConfiguration.requestMatchers().permitAll()`'a ekle
3. `api-manager/JwtAuthFilter.PUBLIC_PATHS`'e ekle
4. `api-manager/CompanyResolutionFilter.isPublicPath()`'e ekle
5. `core` → `mvn install -q` → `security` restart

**Neden `/authenticate` bu sorundan etkilenmiyor?**
`/authenticate` `/api` ile başlamıyor → filter'ın else branch'inden direkt geçiyor.
`/api/v1/auth/refresh-token` `/api` ile başladığı için filter aktif olur.

---

## 6b. COMPANYCODE KAYNAĞI — MİMARİ KURAL

**companyCode JWT içinde zaten vardır.** `@RequestHeader("X-Company-Code")` controller'larda gereksizdir.

```
JWT sessionInstance.userInformation.selectedCompanyCode
  └─ JwtXUserInfoFilter.createAuthToken()
       └─ TOpenContextHolder.setContext(ctx)   ← companyCode ThreadLocal'e yazılır
            └─ CompanyHibernateFilterActivator  ← her Session'da @Filter'ı aktive eder
                 └─ find* sorguları            ← otomatik WHERE company_code = 'X'
```

**@Filter olan entity'de find* = otomatik izolasyon:**
```java
// @Filter var → tüm sorgulara WHERE company_code=? otomatik eklenir
List<Store> findByIsActiveTrue();       // → WHERE is_active=true AND company_code='SEDCORE'
Optional<Product> findById(String id); // → WHERE id=? AND company_code='SEDCORE'

// ❌ @Filter YOKSA → tüm firmaların verisi döner → tenant sızıntısı!
```

**Yazma işlemleri — CompanyContext.get() kullan:**
```java
entity.setCompanyCode(CompanyContext.get());  // ✅ context'ten
// entity.setCompanyCode(companyCodeFromHeader);  // ❌ gereksiz
```

## 7. HİBERNATE MULTI-TENANT FİLTRESİ

### TOpenSimpleCompanyEntity — Filter Tanımı Burada

```java
// core/TOpenSimpleCompanyEntity.java — tüm subclass'lar bu filtreyi miras alır
@MappedSuperclass
@FilterDef(
    name = "filterByCompanyCode",                        // CompanyFilterStatics.FILTER_COMPANY
    parameters = @ParamDef(name = "cpCode", type = String.class),
    defaultCondition = "company_code in(:cpCode)"
)
@Filter(name = "filterByCompanyCode", condition = "company_code in(:cpCode)")
public class TOpenSimpleCompanyEntity extends TOpenSimpleDbEntity {
    @Column(name = "company_code", nullable = false, updatable = false, length = 8)
    protected String companyCode;
}
```

**Kritik bilgiler:**
- Filter adı: `"filterByCompanyCode"` (`CompanyFilterStatics.FILTER_COMPANY` sabiti)
- Parametre adı: `"cpCode"` ← dikkat: `"companyCode"` değil!
- Entity'lere **tekrar eklenmez** — `extends TOpenSimpleCompanyEntity` yeterli

### CompanyHibernateFilterActivator — AOP ile Aktive Edilir

```java
// pos-product-manager/CompanyHibernateFilterActivator.java
@Around("execution(public * com.sedcore..service..*(..))")  // tüm modül servisleri
public Object applyCompanyFilter(ProceedingJoinPoint jp) throws Throwable {
    session.enableFilter(CompanyFilterStatics.FILTER_COMPANY)
           .setParameter("cpCode", CompanyContext.get());  // ← "cpCode" parametresi
    try {
        return jp.proceed();
    } finally {
        session.disableFilter(CompanyFilterStatics.FILTER_COMPANY);
    }
}

// ⚠️ AOP pointcut kritik — yanlış paket adı filter'ı tamamen devre dışı bırakır:
// ✓ DOĞRU: "execution(public * com.sedcore..service..*(..)) "
//   → com.sedcore.inventory.service.impl.StoreServiceImpl ✓
//   → com.sedcore.product.service.impl.ProductServiceImpl ✓
// ❌ YANLIŞ: "execution(public * com.sedcore.service..*(..)) "
//   → com.sedcore.service.* paketi mevcut değil → filter hiç aktif olmaz!
```

### CompanyContext — ThreadLocal Wrapper

```java
// pos-product-manager/CompanyContext.java — X-Company-Code header'dan set edilir
CompanyContext.set(companyCode);  // CompanyContextFilter tarafından
CompanyContext.get();             // CompanyHibernateFilterActivator tarafından
CompanyContext.clear();           // Request sonunda CompanyContextFilter finally bloğu
```

---

## 8. i18n ALTYAPISI

```java
// TOpenMessageManager — mesaj kayıt ve alma
// AbstractMessageManager — temel i18n implementasyonu

// Kullanım (security servisinde):
@Autowired
private TOpenMessageManager messageManager;

// data.sql'den yüklenen mesajlara erişim:
String msg = messageManager.getMessage("batch.save_success", "TR");
```

---

## 9. EXCEPTION SİSTEMİ

```java
// TOpenException — temel exception (checked)
// Tüm custom exception'lar buradan türer

// pos-product-manager'da bu exception'lar tanımlıdır:
BusinessException              → 400
NotFoundException              → 404
ConflictException              → 409
DataConflictException          → 409
OperationNotAllowedException   → 403
CompanyIsolationViolationException → 403 (kritik — tenant sızıntısı)

// ExceptionMapper — TOpenException'ı business exception'a çevirir:
public class ExceptionMapper {
    public static BusinessException map(TOpenException e) {
        return new BusinessException(e.getMessage());
    }
}

// Controller'da kullanım:
try {
    return ResponseEntity.ok(ApiResponse.success(service.doSomething()));
} catch (TOpenException e) {
    throw ExceptionMapper.map(e);
}
```

---

## 10. MULTI-TENANT UNIQUE CONSTRAINT KURALI

Entity'lerdeki unique constraint'ler **HER ZAMAN `(company_code, alan)` ikilisi** üzerinde olmalıdır.  
Tek kolon `unique = true` → global unique → farklı firmalar aynı değeri kullanamaz → **YANLIŞ**.

```java
// ❌ YANLIŞ — global unique, multi-tenant kırar
@Column(name = "name", unique = true)
private String name;

// ✅ DOĞRU — firma bazlı unique
@Table(name = "my_table",
       uniqueConstraints = @UniqueConstraint(columnNames = {"company_code", "name"}))
// @Column(name = "name") → unique = true OLMADAN
```

**Gerçek hata:** `RoleDef.name` alanı `unique = true` ile tanımlıydı.  
SEDCORE rolleri ('Yönetici', 'Kasiyer'...) insert edilince SEDCORE1 aynı isimleri `ON CONFLICT DO NOTHING` ile atlıyordu → role_def satırları oluşmuyordu → `user_role` FK violation.  
**Düzeltme (2026-04-13):** `@Table(uniqueConstraints = @UniqueConstraint(columnNames = {"company_code", "name"}))` eklendi.

**Core değişince:** `mvn install -q` → bağımlı tüm servisleri restart et.

---

## 10a. GELİŞTİRME KURALLARI

### Core'a EKLENECEK şeyler:
- Tüm servislerde paylaşılan utility'ler
- Yeni bir entity base class gereksinimi
- Ortak interceptor veya filter

### Core'a EKLENMEYECEKler:
- Business logic (servis özgü kurallar)
- Feature'e özgü entity'ler
- Controller veya DTO'lar

### Değişiklik sonrası:
```bash
cd core && mvn install -q   # Her değişiklikten sonra install et
# Bağımlı servisleri restart et
```

---

## 11. PAKET YAPISI (99 Java Dosyası)

```
com.towpen.base/
├── db/
│   ├── model/
│   │   ├── TOpenDbEntity.java
│   │   ├── TOpenSimpleDbEntity.java
│   │   ├── TOpenSimpleCompanyEntity.java
│   │   └── security/
│   │       ├── UserDef.java
│   │       ├── UserDefAccess.java
│   │       ├── RoleDef.java
│   │       ├── UserRole.java
│   │       ├── Company.java
│   │       ├── Menu.java
│   │       ├── MenuItem.java
│   │       └── MenuCategory.java
│   └── repository/
│       └── BaseDaoRepository.java
│
├── security/
│   ├── BaseDbServiceImp.java
│   ├── TOpenSessionInstance.java
│   ├── TOpenLoginUser.java
│   ├── TOpenCompanyInfo.java
│   └── model/
│       └── (DTO sınıfları)
│
├── i18n/
│   ├── TOpenMessageManager.java
│   └── AbstractMessageManager.java
│
└── hibernate/
    ├── CompanyFilterInterceptor.java
    ├── CompanyFilterStatics.java
    └── CompanyHibernateFilterActivator.java
```
