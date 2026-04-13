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
// @Filter/@FilterDef entity'ye EKLENMEZ — TOpenSimpleCompanyEntity superclass'ında tanımlı,
// miras yoluyla tüm extend eden entity'lere otomatik uygulanır.
@Entity
@Table(name = "my_table")
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

**companyCode JWT token içinden gelir — `@RequestHeader("X-Company-Code")` gereksizdir.**  
Servis, `CompanyContext.get()` ile alır. Hibernate `@Filter` read sorgularını otomatik izole eder.

```java
@RestController
@RequestMapping("/api/v1/my-resource")   // Flutter'dan: product/api/v1/my-resource
@RequiredArgsConstructor
public class MyControllerImpl implements MyController {

    private final MyService myService;

    // READ — @Filter otomatik WHERE company_code = 'X' ekler, companyCode parametresi gereksiz
    @GetMapping
    public ResponseEntity<ApiResponse<List<MyResponseDto>>> getAll() {
        try {
            return ResponseEntity.ok(ApiResponse.success(myService.getAll()));
        } catch (TOpenException e) {
            throw ExceptionMapper.map(e);
        }
    }

    // WRITE — service içinde CompanyContext.get() ile companyCode alınır
    @PostMapping
    public ResponseEntity<ApiResponse<MyResponseDto>> create(
            @RequestBody @Valid MyRequestDto request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(myService.create(request)));
    }
}
```

**Servis içinde yazma:**
```java
public MyResponseDto create(MyRequestDto request) {
    MyEntity entity = new MyEntity();
    entity.setCompanyCode(CompanyContext.get());  // ✅ context'ten — header'dan değil
    entity.setName(request.getName());
    return toDTO(repository.save(entity));
}
```

---

## 6. API NAMING CONVENTION — KRİTİK

### Backend Controller Path'i ≠ Flutter URL

Tüm istekler Flutter → api-manager (8080) → pos-product-manager (8001) akışıyla gider.  
api-manager, `product/**` path'lerini StripPrefix=0 ile 8001'e iletir.

```
┌───────────────────────────────────────────────────────────────────────┐
│ Backend controller'da    │  Flutter'dan çağırırken                    │
│ @RequestMapping yazar    │  (api-manager üzerinden — prefix eklenir)  │
├──────────────────────────┼────────────────────────────────────────────┤
│ /api/v1/products         │  product/api/v1/products                   │
│ /api/v1/products/{id}    │  product/api/v1/products/{id}              │
│ /api/v1/stores           │  product/api/v1/stores                     │
│ /api/v1/categories       │  product/api/v1/categories                 │
│ /api/v1/public/...       │  product/api/v1/public/...  (JWT bypass)   │
└──────────────────────────┴────────────────────────────────────────────┘
```

**Kural:** Flutter'da URL her zaman `product/` prefix'iyle başlar.  
Backend controller'da bu prefix **yoktur** — sadece `/api/v1/...` yazar.

```dart
// ✅ DOĞRU
await _apiClient.get('product/api/v1/products');
await _apiClient.get('product/api/v1/stores');
await _apiClient.post('product/api/v1/products/batch', data: ...);

// ❌ YANLIŞ — prefix eksik
await _apiClient.get('api/v1/products');
await _apiClient.get('/product/api/v1/products');  // başta / olmamalı

// ❌ YANLIŞ — direkt port
await _apiClient.get('http://localhost:8001/api/v1/products');
```

### REST URL Şablonu

```
GET    /api/v1/{resource}           → liste      →  product/api/v1/{resource}
GET    /api/v1/{resource}/{id}      → tekil      →  product/api/v1/{resource}/{id}
POST   /api/v1/{resource}           → oluştur    →  product/api/v1/{resource}
PUT    /api/v1/{resource}/{id}      → güncelle   →  product/api/v1/{resource}/{id}
DELETE /api/v1/{resource}/{id}      → sil (soft) →  product/api/v1/{resource}/{id}
GET    /api/v1/{resource}/search?q= → arama      →  product/api/v1/{resource}/search?q=
POST   /api/v1/{resource}/batch     → toplu      →  product/api/v1/{resource}/batch
```

---

## 6a. BATCH (TOPLU ÜRÜN GİRİŞİ) ENDPOİNT

```
POST /product/api/v1/products/batch
```

**Amaç:** Flutter toplu ürün giriş ekranından tek HTTP çağrısıyla hem Purchase kaydı oluşturur hem yeni ürünler ekler hem de mevcut ürün stoklarını günceller.

### Request DTOs

```java
// BatchCreateRequest — kök talep
public class BatchCreateRequest {
    @NotBlank private String supplierId;
    @NotBlank private String invoiceNumber;
    private String deliveryNoteNumber;
    @NotNull  private LocalDate purchaseDate;
    @NotBlank private String storeId;
    @NotBlank private String warehouseId;
    private String notes;
    @Valid private List<BatchProductItem> newProducts;      // Yeni ürünler
    @Valid private List<BatchExistingItem> existingProducts; // Mevcut ürün stok girişleri
}

// BatchProductItem — yeni ürün kalemi
public class BatchProductItem {
    private String tempId;            // Flutter'ın BatchEntryRow.id — sonuç eşlemesi için
    private ProductRequest product;
    private List<ProductVariantRequest> variants;
    private List<OemNumberRequest> oemNumbers;
    private List<CrossReferenceRequest> crossReferences;
}

// BatchExistingItem — mevcut ürüne stok ekle
public class BatchExistingItem {
    private String tempId;
    @NotBlank  private String variantId;
    @NotNull @Min(1) private Integer quantity;
    @NotNull @Positive private BigDecimal unitPrice;
    private BigDecimal taxRate;
    private String notes;
}
```

### Response DTOs

```java
// BatchCreateResponse
public class BatchCreateResponse {
    private String purchaseId;
    private String invoiceNumber;
    private int successCount;
    private int failCount;
    private BigDecimal totalAmount;
    private List<BatchItemResult> results;  // Her kalem için ayrı sonuç
}

// BatchItemResult — tekil kalem sonucu
public class BatchItemResult {
    private String tempId;      // Flutter'ın gönderdiği tempId — eşleme için
    private boolean success;
    private String productId;
    private String variantId;
    private String message;     // Hata mesajı (success=false ise)
}
```

### Servis Davranışı

```java
// ProductService.batchCreateProducts(request)
// 1. Purchase kaydı oluşturulur (tek Purchase tüm batch için)
// 2. newProducts: her ürün _createProductWithPurchase() ile işlenir
//    → @Transactional(propagation = REQUIRES_NEW) — her ürün bağımsız transaction
//    → Bir ürün başarısız olursa diğerleri etkilenmez
// 3. existingProducts: StockMovement(IN) kaydı + variant.quantity arttırılır
// 4. Purchase.totalAmount güncellenir
// 5. BatchCreateResponse döner (tempId → sonuç eşlemesi)
```

### ProductVariantRequest — minStockLevel Alanı

```java
public class ProductVariantRequest {
    // ... mevcut alanlar ...
    private Integer minStockLevel;  // Minimum stok uyarı seviyesi — default 10
    // Backend: variantPricing.setMinStockLevel(req.getMinStockLevel() != null ? req.getMinStockLevel() : 10)
}
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

---

## 10. EXCEPTION YÖNETİMİ — KRİTİK KURAL (2026-04-13)

### TOpenException / TOpenMessage KULLANMA — NotFoundException / BusinessException Kullan

`TOpenMessage` sınıfı `toString()` override etmez → log'da nesne referansı görünür → debug imkânsız:

```
ERROR GlobalExceptionHandler : TOpenException: [com.towpen.base.restservice.model.TOpenMessage@5bd0d0d5]
```

**Proje exception'larını kullan — bunlar düzgün mesaj taşır:**

```java
// ✅ DOĞRU — log'da net mesaj, AppExceptionHandler yakalar, doğru HTTP status döner
throw new NotFoundException("CustomerAccount", customerId);
// → log: "CustomerAccount bulunamadı: abc-123"   HTTP 404

throw new NotFoundException("Ürün bulunamadı: " + id);
// → log: "Ürün bulunamadı: abc-123"              HTTP 404

throw new BusinessException("Stok yetersiz: mevcut=" + current + ", istenen=" + requested);
// → log: "Stok yetersiz: mevcut=2, istenen=5"    HTTP 400

throw new ConflictException("Bu SKU zaten kayıtlı: " + sku);
// → log: "Bu SKU zaten kayıtlı: ABC-001"         HTTP 409

// ❌ YANLIŞ — TOpenMessage.toString() object reference döner → log okunmaz
throw new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006));
// → log: "TOpenException: [com.towpen.base.restservice.model.TOpenMessage@5bd0d0d5]"
```

**Exception → HTTP status eşlemesi:**

| Exception | HTTP | Kullanım |
|-----------|------|---------|
| `NotFoundException` | 404 | Kayıt bulunamadı |
| `BusinessException` | 400 | İş kuralı ihlali, yetersiz stok, geçersiz durum |
| `ConflictException` | 409 | Duplicate kayıt, SKU çakışması |
| `DataConflictException` | 409 | Veri bütünlüğü ihlali |
| `OperationNotAllowedException` | 403 | İzinsiz işlem |
| `CompanyIsolationViolationException` | 403 | Tenant sızıntısı — KRİTİK |

`AppExceptionHandler` tüm bu exception'ları yakalar → `{ success: false, message: "...", errorCode }` döner.

**`TOpenException` ne zaman kullanılır?**  
Sadece core kütüphanesi (`BaseDbServiceImp.findAndCheckById()` vb.) içinden fırlatılıyorsa ve
doğrudan re-throw ediliyorsa kabul edilebilir. Servis/controller kodunda `new TOpenException(...)` yazma.

---

## 11. PRODUCTION-READY KURALLAR (2026-04-13)

### Sektör İzolasyonu

```java
// ProductServiceImpl.createProduct() — sector her zaman firmadan alınır:
String companySector = companySettingRepository
    .findFirstByCompanyCodeOrderByCreateTimeDesc(CompanyContext.get())
    .map(s -> s.getSectorType())
    .orElse(dto.getProduct().getSector()); // fallback: request'teki değer
product.setSector(companySector); // request'teki sector override edilir
```

`CompanySettingServiceImpl.updateSettings()` → `sectorType` alanı artık güncellenmez.  
Firma sektörü kurulumda belirlenir, sonradan değiştirilemez.

### Purchase → storeId

```java
// Purchase entity'ye store_id kolonu eklendi
// PurchaseServiceImpl.createPurchase() → purchase.setStoreId(request.getStoreId())
// ProductServiceImpl batch flow → purchase.setStoreId(dto.getPurchase().getStoreId())
```

### Store Silme

```java
// StoreService.deleteStore(String id, String companyCode)
//   → StoreRepository.findByIdAndCompanyCode(id, companyCode)
//   → store.setIsActive(false) — fiziksel silme yasak
```

---

## 11. DATA.SQL SORUMLULUKLARI VE KURALLARI

### Bu servise ait seed verileri
```
company          → ON CONFLICT DO NOTHING (security zaten insert eder — FK güvencesi)
stores           → Ana ve şube mağazalar
warehouses       → Depolar
categories       → Global kategori ağacı
company_categories
brands, units
products, product_variants, vb.
stock_movements  → Test senaryosu verisi
```

### Bu servise AİT DEĞİL — security/data.sql'e eklenmeli
```
role_def         ← EKLEME
user_def         ← EKLEME
user_def_access  ← EKLEMA
user_role        ← EKLEME
```

### inventory_view Yönetimi

```sql
-- data.sql'in ilk 3 satırı — sıra önemli:
DROP TABLE IF EXISTS inventory_view;   -- Hibernate bazen tablo olarak oluşturur
DROP VIEW IF EXISTS inventory_view;    -- Önceki run'da view olarak oluşturulmuşsa
CREATE VIEW inventory_view AS ...;
```

### store_id Ataması

```sql
-- Kasiyerlerin store_id'si mağazalar oluşturulduktan SONRA set edilir
-- user_def kaydı security'de, store_id ataması burada yapılır
UPDATE user_def SET store_id = 'STORE-01' WHERE user_name = 'kasiyer';
UPDATE user_def SET store_id = 'SUBE-01'  WHERE user_name = 'kasiyer2';
UPDATE user_def SET store_id = 'STORE-02' WHERE user_name = 'giyim_kasiyer';
```

### DDL Not

```properties
# pos-product-manager/application.properties
spring.jpa.hibernate.ddl-auto=create   # Her startup'ta DROP+CREATE
```

`ALTER TABLE ... ADD COLUMN` ifadelerini data.sql'e **ekleme** — Hibernate schema'yı yönetir.

---

## 12. PDF FATURA ANALİZİ — MİMARİ VE ALAN DETAYLARI

### Endpoint

```
POST /api/v1/document/analyze   (multipart/form-data, field: "file")
Flutter URL: product/api/v1/document/analyze
```

### Dosya Lokasyonları

```
model/DocumentItemResult.java        ← Tek satır sonuç DTO
model/DocumentAnalyzeResponse.java   ← Tüm belge sonuç DTO
service/DocumentAnalyzeService.java  ← Interface
service/impl/DocumentAnalyzeServiceImpl.java  ← PDFBox parse + ürün match
controller/DocumentAnalyzeController.java     ← Interface (@Tag, @RequestMapping)
controller/impl/DocumentAnalyzeControllerImpl.java
```

### DocumentAnalyzeResponse Yapısı

```java
// DocumentAnalyzeResponse
String fileName;       // Yüklenen dosyanın adı
int totalItems;        // Toplam çıkarılan kalem sayısı
int foundItems;        // Sistemde eşleşen kalem sayısı
int notFoundItems;     // Eşleşmeyen (yeni ürün) kalem sayısı
List<DocumentItemResult> items;

// DocumentItemResult — her fatura satırı
int rowIndex;              // Parse sırası (1, 2, 3...)
String rawText;            // Ham satır metni (debug için)
String extractedName;      // Temizlenmiş ürün adı
String extractedCode;      // Barkod veya OEM numarası
Double extractedQuantity;  // Miktar
Double extractedUnitPrice; // Birim fiyat
String matchStatus;        // "FOUND" | "NOT_FOUND"
String matchedProductId;   // Eşleşen ürün ID (FOUND ise)
String matchedVariantId;   // Eşleşen varyant ID (FOUND ise) — Flutter'da existingVariantId olur
String matchedProductName; // Eşleşen ürün adı
String matchedSku;         // Eşleşen SKU
String matchType;          // "BARCODE" | "OEM" | "NAME"
Double matchedCurrentStock; // Mevcut stok (0.0 sabit — TODO: gerçek stok)

// ❌ EKSİK — Sprint 1 tamamlama için eklenecek:
// String unit;           // "ADET" | "KG" | "MT" vb.
// Double vatRate;        // 8.0 | 18.0 | 20.0
// Boolean vatIncluded;   // fiyat KDV dahil mi?
// Double totalPrice;     // satır toplamı
```

### Parse Akışı (DocumentAnalyzeServiceImpl)

```
1. PDFBox → PDFTextStripper.setSortByPosition(true) → tüm metin
2. "\r?\n" ile satırlara böl
3. Her satır için:
   a. shouldSkipLine() → başlık/footer satırları atla
   b. extractLineInfo():
      - EAN13 (13 rakam) → result.code, result.codeType="BARCODE"
      - OEM (harf+rakam 4-20 karakter) → result.code, result.codeType="OEM"
      - Türkçe sayılar normalize (1.234,56 → 1234.56)
      - Tam sayı 1-9999 → result.quantity
      - En küçük pozitif ondalıklı → result.unitPrice
      - Kodu ve sayıları temizle → result.name
   c. matchToProduct():
      - Barkod → barcodeRepository.findByBarcodeCode()
      - OEM   → oemNumberRepository.findByOemNumberIgnoreCase()
      - İsim  → productRepository.searchProducts(ilk 2-3 kelime)
      - Bulunamadı → NOT_FOUND
4. DocumentAnalyzeResponse döner
```

### Türkçe Fatura Formatı — Atlanan Satırlar (SKIP_PREFIXES)

```java
// Şu an atlanıyor (başlık/footer):
"sıra", "sira", "satır", "satir", "miktar", "birim", "adet",
"toplam", "genel", "kdv", "vergi", "iban", "banka",
"sayfa", "page", "tarih", "fatura", "irsaliye", "alıcı",
"alici", "satıcı", "satici", "müşteri", "musteri", "tc kimlik",
"adres", "telefon", "e-posta", "email", "web"

// Ayrıca:
// - 5 karakterden kısa satırlar
// - Sadece rakam/özel karakter içeren satırlar
// - Boş satırlar
```

### Ürün Eşleştirme Kritik Notlar

```java
// BARCODE: barcodeRepository.findByBarcodeCode(code)
// → Barcode entity'de: getVariant() (object, NOT String ID)
// → variant.getProduct() (object, NOT String ID)

// OEM: oemNumberRepository.findByOemNumberIgnoreCase(code)
// → OemNumber entity'de: getVariant() (object)

// NAME: productRepository.searchProducts(keyword)
// → İlk 2-3 anlamlı kelime (≥3 karakter) aranır
// → İlk sonuç alınır → variants[0] → FOUND
// ⚠️ UYARI: İsim eşleşmesi belirsiz — "YAĞ FİLTRESİ" → yanlış ürün bulabilir
// Flutter'da NAME eşleşmesinde kullanıcı onayı gerekli

// matchedCurrentStock: Şu an 0.0 sabit
// TODO: inventoryRepository.getCurrentStock(variantId, companyCode)
```

### Sprint 1 Tamamlama — Eklenecekler

```java
// 1. DocumentItemResult.java'ya yeni alanlar:
private String unit;           // extract edilen birim
private Double vatRate;        // extract edilen KDV oranı
private Boolean vatIncluded;   // KDV dahil mi?

// 2. DocumentAnalyzeServiceImpl.extractLineInfo():
// Birim extract:
Pattern UNIT_PATTERN = Pattern.compile(
  "\\b(ADET|ADT|KG|KGR|LT|LTR|MT|MTR|M2|PAKET|PKT|KUTU|KTU|PCS|GR|GRAM)\\b",
  Pattern.CASE_INSENSITIVE);
// → Matcher.find() → result.unit = match

// KDV extract:
Pattern VAT_PATTERN = Pattern.compile("\\b(1|8|10|18|20)\\s*%");
// → Satırda "%18", "18%" vb. → result.vatRate = Double.parseDouble(match)

// 3. matchedCurrentStock gerçek stok:
// inventoryRepository.findByVariantIdAndCompanyCode(variantId, CompanyContext.get())
//   .map(inv -> inv.getTotalStock()).orElse(0.0)
```

### Desteklenen / Desteklenmeyen Formatlar

```
✅ Dijital PDF (metin seçilebilir, PDFBox doğrudan okur)
✅ Türkçe fatura formatı (1.234,56 virgüllü sayı)
✅ Çok sayfalı PDF (her sayfa parse edilir)
❌ Taranmış/görüntü PDF → OCR gerekli (Sprint 2: Tesseract)
❌ Şifreli/korumalı PDF → Exception fırlatır
❌ Excel/Word fatura → BusinessException ("Sadece PDF desteklenmektedir")
```
