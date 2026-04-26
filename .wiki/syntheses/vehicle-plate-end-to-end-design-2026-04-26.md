---
title: Plaka Bazlı Satış-Tahsilat Bütünsel Tasarımı (2026-04-26)
type: synthesis
date: 2026-04-26
status: design-proposal
sector: autoParts (sektör-aware)
purpose: parçacı sektör senaryosu — satış sırasında plaka kayıt + müşteri görünümünde plaka arama + tahsilatta plaka bazlı geçmiş seçimi
sprint-target: 9-11 (3 sprint, ~7-10 gün)
supersedes: decisions/2026-04-24-vehicle-plate-tracking-option-a (Opsiyon A → C geçişi tetiklendi)
---

# Plaka Bazlı Satış-Tahsilat — Bütünsel Tasarım

## Senaryo (Kullanıcı Feedback'i 2026-04-26)

> Parçacı sektörü kullanıcısı:
> 1. Satış yaparken ekrana **plaka alanı** açılsın (sektör-aware)
> 2. Satılan malzeme hangi plakaya alındı kaydedilsin (not veya yapısal alan)
> 3. Gün sonunda müşterinin **birden fazla plakaya** parça aldığı görülsün
> 4. Tahsilat: cari hesap ekranında **müşteri seç → plaka ara → satış geçmişi → ödeme**
>
> "Şu an ödeme kartında plaka alanı var ama süreci bütünsel ele al"

## Mevcut Durum (Önceki ADR — Opsiyon A)

[[decisions/2026-04-24-vehicle-plate-tracking-option-a]] Sprint 6b'de Opsiyon A (description prepend) kabul edildi:
- PaymentRecordModal'a opsiyonel `_plateCtrl` TextField eklendi
- `_normalizePlate()` ile boşluk/çizgi temizle + uppercase
- `Payment.description` alanına `"Plaka: 34ABC123 | <orijinal>"` prepend
- **Backend sıfır değişiklik** — yapısal alan yok

**Kabul edilen kısıtlar (Sprint 6b'de):**
- Plaka arama yok
- Plaka raporlama yok
- Tutarlı yazım garantisi yok
- B/C opsiyonları "müşteri feedback'i bekliyor" notuyla ertelenmiş

## Yeniden Değerlendirme — Opsiyon A YETERSİZ

ADR'deki yeniden değerlendirme kriterleri:
1. ✅ Müşteriler "plaka ile ödeme geçmişi getir" istiyor → kullanıcı feedback'i bunu kanıtlıyor
2. ✅ Tek müşterinin >5 plakası senaryosu → "birden fazla plakaya parça" ifadesi bunu içeriyor
3. ⚠️ Plaka bazlı vergi/işletme raporu → henüz açık değil ama mantıklı

**Karar:** Opsiyon C'ye geç. **Opsiyon B (`Payment.vehicle_plate` tek kolon) reddedildi** — multi-plaka per müşteri senaryosu yapısal entity gerektiriyor.

## Tasarım — Opsiyon C: `CustomerVehicle` Entity

### Backend Entity Şeması

```java
@Entity
@Table(name = "customer_vehicles", indexes = {
    @Index(name = "idx_cv_customer", columnList = "customer_id"),
    @Index(name = "idx_cv_plate_normalized", columnList = "plate_normalized"),
    @Index(name = "idx_cv_company", columnList = "company_code")
}, uniqueConstraints = {
    @UniqueConstraint(name = "uk_cv_customer_plate",
                      columnNames = {"customer_id", "plate_normalized", "company_code"})
})
public class CustomerVehicle extends TOpenSimpleCompanyEntity {
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "customer_id", nullable = false)
    private Customer customer;

    @Column(name = "plate_display", nullable = false, length = 20)
    private String plateDisplay;        // "34 ABC 123" (kullanıcı girişi)

    @Column(name = "plate_normalized", nullable = false, length = 20)
    private String plateNormalized;     // "34ABC123" (search index)

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vehicle_id")
    private Vehicle vehicle;            // optional — katalog (make/model/year)

    @Column(name = "make", length = 50)
    private String make;                // "Ford", "Toyota" (fallback eğer Vehicle FK yoksa)

    @Column(name = "model", length = 100)
    private String model;

    @Column(name = "year_of_manufacture")
    private Integer yearOfManufacture;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @Version
    private Long version;
}
```

### Sale Entity Genişletme

```java
@Entity
@Table(name = "sales", ...)
public class Sale extends ... {
    // ... mevcut alanlar

    /**
     * Sprint 9 — plaka bazlı takip (Opsiyon C).
     * Nullable — peşin/genel satışta plaka yok.
     * Müşteri seçili + parçacı sektör + UI plaka picker → bu FK doldurur.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_vehicle_id")
    private CustomerVehicle customerVehicle;

    /**
     * Denormalize cache (search performance + reporting).
     * Eşitlik invariant: customerVehicle != null → plateSnapshot = customerVehicle.plateNormalized.
     * Reconcile job kontrol etmeli (drift detection).
     */
    @Column(name = "vehicle_plate_snapshot", length = 20)
    private String vehiclePlateSnapshot;
}
```

### Repository

```java
public interface CustomerVehicleRepository extends JpaRepository<CustomerVehicle, String> {
    List<CustomerVehicle> findByCustomerIdAndIsActiveOrderByPlateDisplay(String customerId, Boolean isActive);

    @Query("SELECT cv FROM CustomerVehicle cv " +
           "WHERE cv.customer.id = :customerId " +
           "  AND cv.isActive = true " +
           "  AND LOWER(cv.plateNormalized) LIKE LOWER(CONCAT('%', :q, '%'))")
    List<CustomerVehicle> searchByCustomer(@Param("customerId") String customerId, @Param("q") String q);

    Optional<CustomerVehicle> findByCustomerIdAndPlateNormalized(String customerId, String plateNormalized);
}
```

### Endpoint Kataloğu (Yeni)

| Endpoint | Amaç |
|---|---|
| `GET /customers/{id}/vehicles` | Müşterinin kayıtlı plakaları (active) |
| `GET /customers/{id}/vehicles/search?q=34A` | Plaka prefix arama (autocomplete) |
| `POST /customers/{id}/vehicles` | Yeni plaka kaydı (request: plateDisplay, make, model, year, notes) |
| `PUT /customers/{id}/vehicles/{vid}` | Güncelleme |
| `DELETE /customers/{id}/vehicles/{vid}` | Soft-delete (isActive=false) |
| `GET /sales?customerId=X&vehiclePlate=Y` | **Mevcut endpoint'e yeni filter** — Sale.vehiclePlateSnapshot LIKE |
| `GET /sales/by-plate/{plateNormalized}?customerId=Y` | Plaka odaklı satış listesi (alternatif yol) |

### Service Akışı

**Yeni satış (parçacı sektör + müşteri seçili):**
```
1. UI: cart_panel.dart sale builder
   - Sektör check: companySetting.sectorType == 'autoParts'
   - Müşteri seçili: customerId != null
   - Plaka picker görünür: customerVehicleProvider(customerId)
2. User flow:
   a. Existing plaka seç (dropdown) → Sale.customerVehicleId set
   b. Yeni plaka ekle → POST /customers/{id}/vehicles → response.id → Sale.customerVehicleId
3. POST /sales request:
   - customerVehicleId: cv-...
   - (vehiclePlateSnapshot backend service'te otomatik dolar)
4. SaleServiceIntegrated.createSale():
   - if (customerVehicleId != null) → load CV → sale.vehiclePlateSnapshot = cv.plateNormalized
```

**Tahsilat (plaka bazlı geçmiş):**
```
1. AccountsHub StatementDetailPanel: müşteri seçili
2. Yeni widget: VehiclePlateSearchBar (sektör=autoParts ise görünür)
   - Autocomplete: typing → GET /customers/{id}/vehicles/search?q=...
   - Seç: plateNormalized state'e
3. Plaka seçilince:
   - GET /sales?customerId=X&vehiclePlate=Y → o plakaya ait satışlar
   - Ödeme akışı: mevcut PaymentRecordModal + allocations
   - Allocations array: [{saleId, amount}, ...] → Payment.allocations
4. Mevcut Sprint 7 PaymentAllocation entity'si bu akışla doğal çalışır:
   - SUM(allocations.amount where sale.vehiclePlate=X) = "şu plakaya ödenmiş tutar"
```

## Frontend Komponentleri (Yeni / Değişen)

### Yeni Widget'lar
| Widget | Konum | Sektör |
|---|---|---|
| `CustomerVehiclePicker` | `lib/features/pos/widgets/` | autoParts only |
| `VehiclePlateSearchBar` | `lib/features/accounts/widgets/` | autoParts only |
| `AddCustomerVehicleModal` | `lib/features/customers/widgets/` | autoParts only |
| `CustomerVehiclesList` | `lib/features/customers/screens/customer_detail_screen.dart` (sekme) | autoParts only |

### Değişen Widget'lar
| Widget | Değişiklik |
|---|---|
| [`cart_panel.dart`](project_pos/lib/features/pos/widgets/cart_panel.dart) | Sektör=autoParts + müşteri seçili → `CustomerVehiclePicker` göster |
| [`statement_detail_panel.dart`](project_pos/lib/features/accounts/widgets/statement_detail_panel.dart) | Header altına `VehiclePlateSearchBar` (sektör+isCustomer) — seçili plaka filter satışları |
| [`payment_record_modal.dart`](project_pos/lib/features/accounts/screens/payment_record_modal.dart) | Mevcut `_plateCtrl` (Sprint 6b) **deprecated** — bunun yerine plaka picker (allocations zaten seçilen satışları gösterir) |

### Sektör Awareness
[[entities/company-setting]] `sectorType` field ile:
```dart
final isAutoParts = ref.watch(companySettingProvider).sectorType == 'autoParts';
if (isAutoParts) {
  // plaka widget'ları göster
}
```

## Migration Stratejisi

### Veri Migration (Sprint 9)
1. Mevcut `Payment.description` içinde "Plaka: XX" prepend'li kayıtlar mevcut.
2. Migration script: regex ile plaka çıkar → `CustomerVehicle` upsert (customer_id + plate_normalized) → `PaymentAllocation`'a o satışın allocation'ı varsa Sale.customerVehicleId güncelle.
3. Idempotent: `INSERT ... ON CONFLICT (customer_id, plate_normalized) DO NOTHING`.

### Geriye Uyumluluk
- Sprint 6b'nin `Payment.description` plate prepend kodu **kaldırılacak** (Sprint 11)
- PaymentRecordModal'daki `_plateCtrl` **kaldırılacak** (yerine picker)
- Eski payment kayıtlarında description'daki plaka bilgisi okuma-only olarak kalır (history korunur)

## Sprint Roadmap

### Sprint 9 — Backend Foundation (~3-5 gün)
- ✅ `CustomerVehicle` entity + repository + service
- ✅ `Sale.customerVehicleId` FK + `vehiclePlateSnapshot` migration
- ✅ Endpoint'ler: `/customers/{id}/vehicles` CRUD + search
- ✅ `SaleServiceIntegrated.createSale` plate snapshot logic
- ✅ `GET /sales?customerId=X&vehiclePlate=Y` filter
- Wiki: `entities/customer-vehicle.md` + `decisions/2026-04-26-vehicle-plate-option-c.md`

### Sprint 10 — Frontend POS (~2-3 gün)
- ✅ `CustomerVehiclePicker` widget (autocomplete + new plate modal)
- ✅ `cart_panel.dart` sektör-aware integration
- ✅ POS sale request payload `customerVehicleId`
- ✅ AddCustomerVehicleModal
- ✅ Sektör-aware visibility tüm placalı widget'larda

### Sprint 11 — Accounts Plaka Tahsilat (~1-2 gün)
- ✅ `VehiclePlateSearchBar` widget (`statement_detail_panel.dart`)
- ✅ Plaka filter ile sales fetch + sale picker (PaymentRecordModal'a entegre)
- ✅ Mevcut `_plateCtrl` deprecated kaldırma
- ✅ Migration script (description'dan CustomerVehicle'a)
- ✅ Test: T5 plate-based payment allocation integration

## Done Kriteri (Senaryo Doğrulama)

| Senaryo | Beklenen Davranış |
|---|---|
| Parçacı sektör + satış: müşteri seç → plaka alanı görünür | ✅ |
| Yeni plaka ekleme inline (modal) | ✅ |
| Müşterinin satışlarında 3 farklı plaka var → AccountsHub'da plaka bazında ayrı görünür | ✅ |
| Tahsilat: müşteri → plaka ara "34A" → 2 sonuç → biri seç → o plakaya ait açık satışlar listelenir | ✅ |
| PaymentAllocation seçilen satışları kapsar | ✅ |
| Genel ödeme (plaka seçilmez) hâlâ çalışır (geriye uyum) | ✅ |
| Butik sektör (companyCode=SEDCORE1) plaka widget'ları **görünmez** | ✅ |

## Riskler

| Risk | Önlem |
|---|---|
| Migration script eski description'dan plaka çıkarırken hata | Idempotent + dry-run + rollback script + manuel review log |
| Sektör-aware UI logic'i her yerde tutarsız uygulanır | Single `useAutoParts` hook/getter — tüm widget'lar bu üzerinden bakar |
| `Sale.vehiclePlateSnapshot` ve `customerVehicle.plateNormalized` drift | Reconcile job'a yeni invariant ekle |
| Plaka picker autocomplete performance | Index `plate_normalized` + LIMIT 20; debounced 300ms |
| Eski Payment kayıtlarında plate description prepend olarak kalır → kullanıcı kafası karışır | Read-only history; yeni kayıtlarda picker zorunlu (sektör=autoParts ve müşteri seçili) |

## Sources

- Kullanıcı senaryosu: 2026-04-26
- [[decisions/2026-04-24-vehicle-plate-tracking-option-a]] (Sprint 6b — superseded olacak)
- [[entities/payment-allocation]] (Sprint 7 — many-to-many bağ; plaka filter doğal genişleme)
- [[entities/sale]] · [[entities/customer]] · [[entities/vehicle]] (mevcut katalog)
- [[entities/company-setting]] (sektör-aware kararı için sectorType)
- [[concepts/sector-agnostic]] · [[concepts/sector-strings]]
- [[syntheses/sprint-7-implementation-plan-2026-04-25]] (PaymentAllocation pattern)
- [[concepts/payment-allocation-pattern]] (allocations array doğal plate-filtered olur)

## Yeni Backend Servisleri / Endpoint'leri Listesi

### Yeni Java Sınıflar
- `pos-product-manager/.../customer/entity/CustomerVehicle.java` (entity)
- `pos-product-manager/.../customer/repository/CustomerVehicleRepository.java`
- `pos-product-manager/.../customer/service/CustomerVehicleService.java` (interface)
- `pos-product-manager/.../customer/service/impl/CustomerVehicleServiceImpl.java`
- `pos-product-manager/.../customer/controller/CustomerVehicleController.java` (interface)
- `pos-product-manager/.../customer/controller/impl/CustomerVehicleControllerImpl.java`
- `pos-product-manager/.../customer/model/CustomerVehicleDto.java` (request)
- `pos-product-manager/.../customer/model/CustomerVehicleResponse.java`

### Değişen Java Sınıflar
- `Sale.java` — yeni FK + snapshot field
- `SaleRequest.java` — `customerVehicleId` parametresi
- `SaleServiceIntegrated.java` — createSale içinde plate snapshot logic
- `SaleControllerImpl.java` — `GET /sales?vehiclePlate=Y` filter parametresi
- `data.sql` — i18n keys: `vehicle.plate`, `vehicle.add_new`, `vehicle.search_placeholder`, `vehicle.no_vehicles`

### Migration / Reconcile
- `db/migration/V20260427__customer_vehicles.sql` (Flyway varsa) veya Hibernate `ddl-auto=create` otomatik
- `db/migration/V20260427_2__sale_customer_vehicle_fk.sql`
- `ReconcileScheduledJob` — yeni invariant: `Sale.vehiclePlateSnapshot == Sale.customerVehicle.plateNormalized`
- One-shot migration script: `Payment.description` "Plaka: XX" → CustomerVehicle upsert

### Yeni Frontend Dart Dosyaları
- `project_pos/lib/features/customers/services/customer_vehicle_service.dart`
- `project_pos/lib/features/customers/providers/customer_vehicles_provider.dart`
- `project_pos/lib/features/pos/widgets/customer_vehicle_picker.dart`
- `project_pos/lib/features/accounts/widgets/vehicle_plate_search_bar.dart`
- `project_pos/lib/features/customers/widgets/add_customer_vehicle_modal.dart`

### Değişen Frontend Dart Dosyaları
- `cart_panel.dart` — plate picker entegrasyonu
- `statement_detail_panel.dart` — plate search bar
- `payment_record_modal.dart` — `_plateCtrl` kaldır, picker entegre
- `sale_request.dart` veya benzer — `customerVehicleId` field
- `sales_service.dart` — `getCustomerOpenSales` parametresine `vehiclePlate` ekle

## Related

- [[decisions/2026-04-24-vehicle-plate-tracking-option-a]] (superseded)
- [[entities/payment-allocation]]
- [[concepts/payment-allocation-pattern]]
- [[entities/customer]]
- [[entities/sale]]
- [[entities/vehicle]]
- [[concepts/sector-agnostic]]
