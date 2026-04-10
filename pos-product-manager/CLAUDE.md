# POS Product Manager — Spring Boot Backend

## Proje Özeti

Çok şirketli (multi-tenant) yedek parça / perakende POS backend servisi. JWT auth, company scoping (`X-Company-Code` header), PostgreSQL.

**Flutter projesi:** `../project_pos/` (aynı parent dizinde, kendi CLAUDE.md'si var)

## Teknoloji Stack

- **Framework:** Spring Boot 3.x (Java 17+)
- **ORM:** Spring Data JPA / Hibernate
- **Base Library:** `com.towpen:core:11.3.5` (TOpenSimpleCompanyEntity, BaseDaoRepository, TOpenException, TMessageType)
- **Build:** Maven
- **DB:** PostgreSQL, `ddl-auto=create`, `spring.sql.init.mode=always` (data.sql her başlatmada çalışır)

## Proje Yapısı

```
src/main/java/com/sedcore/
├── controller/impl/         # REST controller implementasyonları
├── controller/              # Controller interface'leri
├── service/impl/            # Service implementasyonları
├── service/                 # Service interface'leri
├── repository/              # Spring Data JPA repository'leri
├── entity/                  # JPA entity'leri
├── model/                   # DTO / Request / Response sınıfları
├── enums/                   # Enum'lar (StockMovementType, ProductRelationType, ProductStatus)
├── context/CompanyContext    # ThreadLocal company code
└── util/                    # ExceptionMapper, EntityAuditHelper
```

---

## KOD YAZIM STİLİ (Yeni oturumda ilk oku!)

### 1. Controller Şablonu

```java
@RestController
@RequestMapping("/api/v1/items")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Items")
@SecurityRequirement(name = "Bearer Authentication")
public class ItemControllerImpl {

    private final ItemService itemService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<ItemResponse>>> list() {
        try {
            List<ItemResponse> items = itemService.getAll();
            return ResponseEntity.ok(ApiResponse.success(items));
        } catch (TOpenException e) {
            throw e;                          // ← ASLA modify etme
        } catch (Exception e) {
            log.error("Item listeleme hatası", e);
            throw ExceptionMapper.map(e);     // ← genel hatalar için
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ItemResponse>> getById(@PathVariable String id) {
        try {
            ItemResponse item = itemService.getById(id);
            return ResponseEntity.ok(ApiResponse.success(item));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Item getirme hatası: id={}", id, e);
            throw ExceptionMapper.map(e);
        }
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ItemResponse>> create(@Valid @RequestBody ItemRequest request) {
        try {
            ItemResponse response = itemService.create(request);
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Item oluşturma hatası", e);
            throw ExceptionMapper.map(e);
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ItemResponse>> update(
            @PathVariable String id, @Valid @RequestBody ItemRequest request) {
        try {
            ItemResponse response = itemService.update(id, request);
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Item güncelleme hatası: id={}", id, e);
            throw ExceptionMapper.map(e);
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable String id) {
        try {
            itemService.delete(id);
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Item silme hatası: id={}", id, e);
            throw ExceptionMapper.map(e);
        }
    }
}
```

### 2. Service Şablonu

```java
@Service
@Slf4j
@Transactional
@RequiredArgsConstructor
public class ItemServiceImpl extends BaseDbServiceImp<ItemRepository, Item>
        implements ItemService {

    @Override
    public Class<?> getDTOClassForService() { return ItemResponse.class; }

    // Okuma — readOnly
    @Override
    @Transactional(readOnly = true)
    public List<ItemResponse> getAll() {
        return dao.findByIsActiveTrueOrderByNameAsc().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    // Oluşturma — Builder pattern
    @Override
    public ItemResponse create(ItemRequest request) {
        Item item = Item.builder()
                .name(request.getName())
                .code(request.getCode())
                .isActive(request.getIsActive() != null ? request.getIsActive() : true)
                .build();
        Item saved = save(item);
        log.info("Item oluşturuldu: {} ({})", saved.getName(), saved.getId());
        return toResponse(saved);
    }

    // Güncelleme — find → set → save
    @Override
    public ItemResponse update(String id, ItemRequest request) {
        Item item = findById(id)
                .orElseThrow(() -> new RuntimeException("Item bulunamadı: " + id));
        item.setName(request.getName());
        if (request.getIsActive() != null) item.setIsActive(request.getIsActive());
        Item saved = save(item);
        log.info("Item güncellendi: {} ({})", saved.getName(), saved.getId());
        return toResponse(saved);
    }

    // Silme
    @Override
    public void delete(String id) {
        Item item = findById(id)
                .orElseThrow(() -> new RuntimeException("Item bulunamadı: " + id));
        delete(item);
        log.info("Item silindi: {}", id);
    }

    // Mapping — private helper
    private ItemResponse toResponse(Item item) {
        return ItemResponse.builder()
                .id(item.getId())
                .name(item.getName())
                .code(item.getCode())
                .isActive(item.getIsActive())
                .build();
    }
}
```

### 3. Entity Şablonu

```java
@Entity
@Table(name = "items", indexes = {
    @Index(name = "idx_item_name", columnList = "name")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Item extends TOpenSimpleCompanyEntity {

    @Column(name = "name", nullable = false, length = 200)
    private String name;

    @Column(name = "code", length = 50)
    private String code;

    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Builder.Default
    @Column(name = "is_deleted")
    private Boolean isDeleted = false;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 20)
    private ProductStatus status;

    // İlişkiler — LAZY
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    @OneToMany(mappedBy = "item", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<SubItem> subItems;
}
```

### 4. Repository Şablonu

```java
@Repository
public interface ItemRepository extends BaseDaoRepository<Item> {

    // Derived method — basit sorgular için
    List<Item> findByIsActiveTrueOrderByNameAsc();
    Optional<Item> findByCode(String code);
    boolean existsBySlugAndIdNot(String slug, String id);

    // Custom JPQL — karmaşık sorgular için
    @Query("SELECT i FROM Item i WHERE i.category.id = :categoryId AND i.isDeleted = false ORDER BY i.name")
    List<Item> findByCategoryId(@Param("categoryId") String categoryId);

    // Native SQL — çok karmaşık JOIN'ler için
    @Query(value = """
        SELECT p.id, p.name, COUNT(*) as cnt
        FROM items i
        JOIN products p ON i.product_id = p.id
        WHERE i.company_code = :companyCode
        GROUP BY p.id, p.name
        ORDER BY cnt DESC
        """, nativeQuery = true)
    List<Object[]> findTopItems(@Param("companyCode") String companyCode);
}
```

### 5. DTO Şablonu

```java
// Request (validasyonlu)
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class ItemRequest {
    @NotBlank(message = "Ad zorunludur")
    private String name;
    private String code;
    private Boolean isActive;
}

// Response
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class ItemResponse {
    private String id;
    private String name;
    private String code;
    private Boolean isActive;
    private String companyCode;
}
```

### 6. Controller'da Map dönüş (Entity → Map)

```java
// Bazı controller'lar Response DTO yerine Map<String, Object> döner
private Map<String, Object> toMap(StockMovement m) {
    Map<String, Object> map = new HashMap<>();
    map.put("id",           m.getId());
    map.put("movementType", m.getMovementType());
    map.put("quantity",     m.getQuantity());
    map.put("createTime",   m.getCreateTime());
    if (m.getVariant() != null) {
        map.put("variantId",   m.getVariant().getId());
        map.put("variantSku",  m.getVariant().getSku());
    }
    if (m.getSale() != null) {
        map.put("saleId",     m.getSale().getId());
    }
    return map;
}
```

---

## Kritik Kurallar

### Company Scoping — HER sorguda

```java
String companyCode = CompanyContext.get();
if (companyCode == null || companyCode.isBlank()) companyCode = "syste";
// Repository'ye parametre olarak geç:
repository.findByVariantId(variantId, companyCode);
```

### TMessageType Enum (com.towpen:core JAR)

**Final enum — genişletilemez!** Kullanılabilir değerler:
- `FIELD_IS_REQUIRED_1001` — zorunlu alan
- `NOT_EXISTS_IN_THE_RECORDS_1006` — kayıt bulunamadı
- `ALREADY_EXISTS_1004` — zaten mevcut
- `SAME_AS_DB_CAN_NOT_UPDATE_1050` — değişiklik yok
- `ENTERED_DATA_IS_NOT_IN_FORMAT_1046` — format hatası
- `UNEXPECTED_ERROR_9999` — genel hata

**❌ Custom değerler (BRAND_CREATE_ERROR_1301 vb.) YOK.** → `ExceptionMapper.map(e)` kullan.

### Entity Kaydetme

```java
// Kendi service'inin entity'si → save(entity)  (BaseDbServiceImp'ten)
// Başka service'in entity'si → prepareAndSave(repository, entity)
//   companyCode + createTime + createUser set eder
```

### Loglama

```java
// @Slf4j ile otomatik logger
log.info("Marka oluşturuldu: {} ({})", saved.getName(), saved.getId());  // Başarılı işlem
log.error("Marka oluşturma hatası", e);                                   // Hata (controller catch)
log.warn("Eşleşmeyen exception: {} - {}", e.getClass(), e.getMessage()); // Uyarı
// ❌ String concatenation KULLANMA → {} placeholder kullan
```

### Adlandırma

```
Sınıf:     BrandController (interface) → BrandControllerImpl (impl)
           BrandService → BrandServiceImpl
Metot:     create*, get*, update*, delete*, find*, exists*
Entity:    Tekil (Brand, Category, Product)
Tablo:     Çoğul snake_case (brands, categories, products)
Sütun:     snake_case (is_active, parent_id, company_code)
Field:     camelCase (isActive, parentId, companyCode)
Boolean:   is* veya has* prefix (isActive, isDeleted, hasReturn)
Enum:      UPPER_SNAKE (PURCHASE_IN, SALE_OUT, ACTIVE)
Endpoint:  kebab-case (/api/cross-reference, /toggle-status)
```

---

## Önemli Akışlar

### Satış Oluşturma

```
POST /api/v1/sales (SaleRequest)
  → SaleControllerImpl.create()
  → SaleServiceIntegrated.createSale(request)
    1. Sale entity oluştur + save
    2. Her item için: StockMovement(SALE_OUT) + prepareAndSave
    3. Veresiye ise: CustomerAccount + AccountTransaction güncelle
```

### Öneri Sistemi

```
GET /api/v1/recommendations/hybrid?productIds=...&variantIds=...
  → RecommendationServiceImpl.getHybridRecommendations()
    1. getFrequentlyBoughtTogether(variantIds) — sale_id JOIN
    2. getSimilarProducts(productIds) — product_relationship
    3. getCrossReferencedProducts(variantIds) — cross_references self-join
    → Dedupe → Weighted score → limit
```

### Stok Hareketi Tipleri

`PURCHASE_IN`, `PURCHASE_RETURN_OUT`, `SALE_OUT`, `SALE_RETURN_IN`, `SALE_CANCEL_IN`, `TRANSFER_IN`, `TRANSFER_OUT`, `ADJUSTMENT_IN`, `ADJUSTMENT_OUT`

## Seed Data (data.sql)

- **SEDCORE** (Parçacı): 5 ürün, 7 varyant (var-oto1-...-001→007), STORE-01, WH-01
- **SEDCORE1** (Elbise): 5 ürün, 15 varyant (var-elb1-...-001→015), STORE-02, WH-02
- **cross_references**: 28 kayıt, 5 paylaşılan OEM grubu
- **stock_movements**: 9 farklı hareket tipi (tarih aralıklı)
- **product_relationship**: COMPLEMENTARY, SIMILAR, ALTERNATIVE örnekleri

## Sık Yapılan Hatalar

| Hata | Çözüm |
|------|-------|
| `TMessageType.BRAND_CREATE_ERROR_1301` | Yok → `ExceptionMapper.map(e)` |
| `throw ExceptionMapper.map(e)` try içinde | `e` tanımsız → `throw new TOpenException(new TOpenMessage(TMessageType.FIELD_IS_REQUIRED_1001))` |
| `findBySaleId(saleId)` tek parametre | `findBySaleId(saleId, companyCode)` — 2 param |
| `io.swagger.v3.oas.models.components.Components` | `io.swagger.v3.oas.models.Components` |
| Null bytes dosyalarda | `tr -d '\0' < file > file.clean && mv file.clean file` |
| `catch (Exception e)` boş bırakmak | En az `log.error("...", e); throw ExceptionMapper.map(e);` |
| `log.error("hata: " + e)` | `log.error("hata: {}", e)` — placeholder kullan |

## Build

```bash
mvn compile          # Derleme (0 error hedefi)
mvn spring-boot:run  # Çalıştır
mvn test             # Test
```
