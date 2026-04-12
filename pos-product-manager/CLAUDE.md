# CLAUDE.md — pos-product-manager (Spring Boot Backend)

Genel kurallar ve multi-tenant zorunlulukları için kök `CLAUDE.md`'e bak.  
**Port:** 8001 · **Base package:** `com.sedcore`

---

## 1. PAKET YAPISI

```
com.sedcore/
├── PosProductManagerApplication.java
│
├── common/                          ← Tüm modüllerin ortak altyapısı
│   ├── config/
│   │   ├── SecurityConfiguration    # JWT filter, permitAll path'leri
│   │   ├── MetricsConfiguration     # Prometheus metrics
│   │   └── OpenApiConfig            # Swagger / SpringDoc
│   ├── context/
│   │   └── CompanyContext           # ThreadLocal → mevcut companyCode
│   ├── filter/
│   │   ├── CompanyContextFilter     # X-Company-Code header → ThreadLocal
│   │   └── CompanyHibernateFilterActivator  # Her Session'da @Filter aktif
│   ├── enums/
│   │   ├── ProductStatus            # ACTIVE / INACTIVE / DRAFT
│   │   ├── StockMovementType        # IN / OUT / TRANSFER / ADJUSTMENT
│   │   ├── StockTransactionType
│   │   ├── PaymentType              # CASH / CARD / CREDIT / MIXED
│   │   ├── TransactionType
│   │   ├── CustomerType             # INDIVIDUAL / CORPORATE
│   │   ├── AttributeType            # TEXT / NUMBER / BOOLEAN / LIST
│   │   ├── BarcodeType              # EAN13 / EAN8 / QR / CUSTOM
│   │   ├── MediaType
│   │   ├── ProductRelationType
│   │   └── RiskStatus
│   ├── exception/
│   │   ├── AppExceptionHandler      # @ControllerAdvice → ApiErrorResponse
│   │   ├── BusinessException        # 400 iş kuralı hatası
│   │   ├── NotFoundException        # 404
│   │   ├── ConflictException        # 409
│   │   ├── DataConflictException    # duplicate data
│   │   ├── OperationNotAllowedException
│   │   ├── CompanyIsolationViolationException  # Tenant sızıntısı!
│   │   └── ApiErrorResponse         # { success, message, errorCode }
│   └── util/
│       ├── ExceptionMapper          # TOpenException → BusinessException çevrimi
│       └── EntityAuditHelper        # createdAt/updatedAt otomatik set
│
├── catalog/                         ← Kategori ve nitelik yönetimi
│   ├── entity/
│   │   ├── Category                 # Global kategori ağacı (firma bağımsız)
│   │   ├── CategoryAttribute        # Kategoriye ait özellik tanımı
│   │   ├── CategoryVariant          # Kategoriye ait varyant şablonu
│   │   └── CompanyCategory          # Firma bazlı kategori ataması
│   └── ...
│
├── product/                         ← Ürün kataloğu
│   ├── entity/
│   │   ├── Product                  # Ana ürün kaydı
│   │   ├── ProductVariant           # SKU bazlı varyant (renk, beden...)
│   │   ├── ProductVariantAttributeValue  # Varyant özellik değerleri
│   │   ├── Brand                    # Marka
│   │   └── Unit                     # Birim (adet, kg, lt...)
│   └── service/
│       ├── ProductService           # Ürün CRUD + batch işlemleri
│       ├── ProductVariantService    # Varyant CRUD
│       ├── BrandService
│       ├── UnitService
│       ├── BarcodeService           # Barkod üretimi / doğrulama
│       └── PricingService           # Fiyat hesaplama, KDV
│
├── autoparts/                       ← Yedek parça sektörü özellikleri
│   ├── entity/
│   │   ├── OemNumber                # OEM numarası
│   │   ├── CrossReference           # Çapraz referans
│   │   ├── Vehicle                  # Araç tanımı
│   │   └── VehicleCompatibility     # Ürün ↔ Araç uyumu
│   └── service/
│       ├── OemNumberService
│       ├── CrossReferenceService
│       ├── VehicleService
│       ├── VehicleCompatibilityService
│       └── PartSearchService        # OEM + barkod + isim araması
│
├── sales/                           ← Satış ve iade
│   ├── entity/
│   │   ├── Sale                     # Satış başlığı
│   │   ├── SaleReturn               # İade başlığı
│   │   └── SaleReturnItem
│   └── service/
│       ├── SaleService              # Satış oluştur, iptal, fiş
│       ├── SaleServiceIntegrated    # Stok + cari entegre satış
│       └── SalesReportService       # Satış özeti, ürün analizi, kâr
│
├── purchase/                        ← Satın alma
│   ├── entity/Purchase
│   └── service/PurchaseService      # Alım → stok otomatik güncelleme
│
├── supplier/                        ← Tedarikçi ve cari
│   ├── entity/
│   │   ├── Supplier
│   │   └── SupplierAccount          # Tedarikçi cari hesabı
│   └── service/
│       ├── SupplierService
│       └── SupplierAccountService   # Borç/alacak, ödeme kaydı
│
├── report/                          ← Raporlama ve istatistik
│   └── service/StatsService         # Dashboard stats, revenue, top ürünler
│
└── recommendation/                  ← Ürün öneri motoru
    └── service/RecommendationService
```

---

## 2. ENTITY ŞABLONU

```java
@Entity
@Table(name = "my_table")
@Filter(name = "companyFilter", condition = "company_code = :companyCode")
public class MyEntity extends TOpenSimpleCompanyEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @Column(nullable = false)
    private String name;

    // İlişkiler — HER ZAMAN LAZY
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    @Column(name = "is_deleted")
    private Boolean isDeleted = false;
}
// TOpenSimpleCompanyEntity → companyCode, createdAt, updatedAt, createdBy içerir
```

---

## 3. REPOSITORY ŞABLONU

```java
@Repository
public interface MyRepository extends BaseDaoRepository<MyEntity, String> {

    // HER sorguda companyCode — istisnasız
    List<MyEntity> findByCompanyCodeAndIsDeletedFalse(String companyCode);

    Optional<MyEntity> findByIdAndCompanyCode(String id, String companyCode);

    @Query("SELECT e FROM MyEntity e WHERE e.companyCode = :cc AND e.name LIKE %:q% AND e.isDeleted = false")
    List<MyEntity> searchByName(@Param("cc") String cc, @Param("q") String q);
}
```

---

## 4. SERVİS ŞABLONU

```java
@Service
@Transactional
public class MyServiceImpl extends BaseDbServiceImp<MyEntity, MyRepository>
        implements MyService {

    public MyResponseDto create(String companyCode, MyRequestDto request) {
        MyEntity entity = new MyEntity();
        entity.setCompanyCode(companyCode);  // Tenant izolasyonu
        entity.setName(request.getName());
        entity = repository.save(entity);
        return toDTO(entity);
    }

    public List<MyResponseDto> getAll(String companyCode) {
        return repository.findByCompanyCodeAndIsDeletedFalse(companyCode)
                .stream().map(this::toDTO).toList();  // .toList() — stream().collect() değil
    }

    public void delete(String id, String companyCode) {
        MyEntity entity = repository.findByIdAndCompanyCode(id, companyCode)
                .orElseThrow(() -> new NotFoundException("Kayıt bulunamadı"));
        entity.setIsDeleted(true);  // Soft delete — fiziksel silme yasak
        repository.save(entity);
    }

    private MyResponseDto toDTO(MyEntity e) {
        MyResponseDto dto = new MyResponseDto();
        dto.setId(e.getId());
        dto.setName(e.getName());
        return dto;
    }
}
```

---

## 5. CONTROLLER ŞABLONU

```java
@RestController
@RequestMapping("/product/api/v1/my-resource")
@RequiredArgsConstructor
public class MyControllerImpl implements MyController {

    private final MyService myService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<MyResponseDto>>> getAll(
            @RequestHeader("X-Company-Code") String companyCode) {
        try {
            return ResponseEntity.ok(ApiResponse.success(myService.getAll(companyCode)));
        } catch (TOpenException e) {
            throw ExceptionMapper.map(e);  // TOpenException → BusinessException
        }
    }

    @PostMapping
    public ResponseEntity<ApiResponse<MyResponseDto>> create(
            @RequestHeader("X-Company-Code") String companyCode,
            @RequestBody @Valid MyRequestDto request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(myService.create(companyCode, request)));
    }
}
```

---

## 6. API NAMING CONVENTION

```
GET    /product/api/v1/{resource}           → liste
GET    /product/api/v1/{resource}/{id}      → tekil
POST   /product/api/v1/{resource}           → oluştur
PUT    /product/api/v1/{resource}/{id}      → güncelle
DELETE /product/api/v1/{resource}/{id}      → sil (soft)
GET    /product/api/v1/{resource}/search?q= → arama
GET    /product/api/v1/{resource}/{id}/sub  → alt kayıt listesi

Prefix: /product/**  (api-manager bu prefix'i yönlendirir)
```

---

## 7. DTO KURALLARI

```java
// Request DTO — validasyon zorunlu
public class MyRequestDto {
    @NotBlank(message = "İsim zorunludur")
    private String name;

    @NotNull
    @Positive
    private Double price;
}

// Response DTO — extends DtoBaseModel (id, companyCode, createdAt)
public class MyResponseDto extends DtoBaseModel {
    private String name;
    private Double price;
    // ❌ companyCode frontend'e dönme — güvenlik
}
```

---

## 8. DB ŞEMASI ÖZETİ

```
products              → ürün başlık bilgisi, sektör tipi, soft delete
product_variants      → SKU bazlı varyantlar, fiyat, stok miktarı
product_variant_attr  → varyant özellik değerleri (renk: kırmızı vb.)
brands                → marka tanımları
units                 → birim tanımları (adet, kg...)
categories            → global kategori ağacı
company_categories    → firma bazlı kategori ataması
category_attributes   → kategoriye ait özellik şablonları

oem_numbers           → OEM numaraları (yedek parça)
cross_references      → çapraz referanslar
vehicles              → araç tanımları
vehicle_compatibility → ürün-araç uyum matrisi

sales                 → satış başlıkları
sale_items            → satış kalemleri (variant → quantity, price)
sale_returns          → iade başlıkları

purchases             → alım başlıkları
purchase_items        → alım kalemleri

suppliers             → tedarikçi
supplier_accounts     → tedarikçi cari (borç/alacak)

stock_movements       → stok hareket logu (her değişim kayıt altında)
```

**Tüm tablolarda:** `company_code`, `created_at`, `updated_at`, `is_deleted`

---

## 9. TENANT İZOLASYON PATTERN'İ

```
1. HTTP Request gelir
   ↓
2. CompanyContextFilter → X-Company-Code header → CompanyContext.set(code)
   ↓
3. CompanyHibernateFilterActivator → Hibernate Session açıldığında
   @Filter("companyFilter") parametresi set edilir
   ↓
4. Tüm Entity sorguları otomatik WHERE company_code = 'X' ile filtrelenir
   ↓
5. Service katmanı yine de companyCode parametresiyle çalışır (double safety)
   ↓
6. CompanyIsolationViolationException: farklı firma kaydına erişilirse fırlatılır
   ↓
7. Request biter → CompanyContext.clear() (ThreadLocal temizlenir)
```

**✅ Güvenlik kontrolü:**
```java
if (!entity.getCompanyCode().equals(companyCode)) {
    throw new CompanyIsolationViolationException("Yetkisiz erişim");
}
```
