---
title: Toplu Ürün Girişinde Eksik Mal Takip Sistemi — Tasarım Taslağı
module: batch-entry + purchase.supplier-claim
audience: backend + flutter
status: draft
last-verified: 2026-04-22
owner: Sedat
related:
  - docs/batch-entry-flow.md
  - docs/batch-entry-hierarchy.md
  - project_pos/lib/features/inventory/screens/batch_entry/CLAUDE.md
  - pos-product-manager/CLAUDE.md
---

# Toplu Ürün Girişinde Eksik Mal Takip Sistemi — Tasarım Taslağı

> Kasiyerin/depocunun tedarikçi faturasını toplu girerken **fatura vs. fiilen teslim alınan miktar** farkını
> sistemin otomatik algılaması, kayıt altına alması ve tedarikçiye karşı alacak olarak takip etmesi.

---

## 1. SORUN ÖZETİ (Why)

Batch girişte sık karşılaşılan senaryolar:

1. Fatura 100 adet yazar, **kargoda 80 geldi** → 20 adet eksik kayıt gerekir.
2. Fatura 50 adet yazar, **10 adedi hasarlı** → sağlam 40'ı stoka al, 10 için claim aç.
3. Eksik gelen mal **2 gün sonra ayrı irsaliye** ile tamamlanır → eski claim kapanmalı.
4. Tedarikçi eksiği **kredi notu/iskonto** ile kapatır → para üzerinden çözülür.

Sistem bu senaryolarda üç soruya cevap vermeli:

- **Ne kadar eksik?** (miktar + tutar)
- **Neden eksik?** (SHORTAGE / DAMAGE)
- **Ne oldu sonunda?** (OPEN / teslimat ile kapandı / iskonto / iade / iptal)

---

## 2. MEVCUT DURUM (As-is)

Backend + Flutter tarafında **önemli kısmı zaten inşa edilmiş**. Boşluklar REST/UI katmanlarında.

### 2.1 Var olan (çalışıyor)

| Katman | Parça | Lokasyon |
|--------|-------|----------|
| DB/Entity | `Purchase.invoiceAmount` vs `totalAmount` ayrımı | [Purchase.java:57-67](pos-product-manager/src/main/java/com/sedcore/purchase/entity/Purchase.java) |
| DB/Entity | `Purchase.shortageAmount`, `discountAmount` | [Purchase.java:77-87](pos-product-manager/src/main/java/com/sedcore/purchase/entity/Purchase.java) |
| DB/Entity | `Purchase.purchaseStatus` (PurchaseStatus enum) | [Purchase.java:109-112](pos-product-manager/src/main/java/com/sedcore/purchase/entity/Purchase.java) |
| DB/Entity | `SupplierClaim` entity (supplier, sourcePurchase, claimAmount, reason, status, resolve alanları) | [SupplierClaim.java](pos-product-manager/src/main/java/com/sedcore/purchase/entity/SupplierClaim.java) |
| Enum | `ClaimReason` (SHORTAGE, DAMAGE) | [ClaimReason.java](pos-product-manager/src/main/java/com/sedcore/common/enums/ClaimReason.java) |
| Enum | `ClaimStatus` (OPEN, RESOLVED_DELIVERY, RESOLVED_DISCOUNT, RESOLVED_RETURN, CANCELLED) | [ClaimStatus.java](pos-product-manager/src/main/java/com/sedcore/common/enums/ClaimStatus.java) |
| Enum | `PurchaseStatus` (COMPLETED, PARTIAL, DISCOUNTED, CANCELLED) | [PurchaseStatus.java](pos-product-manager/src/main/java/com/sedcore/common/enums/PurchaseStatus.java) |
| DTO | `BatchExistingItem.invoiceQuantity` + `shortageQty()` helper | [BatchExistingItem.java:30-56](pos-product-manager/src/main/java/com/sedcore/product/model/BatchExistingItem.java) |
| DTO | `BatchProductItem.invoiceQuantity` | [BatchProductItem.java:37](pos-product-manager/src/main/java/com/sedcore/product/model/BatchProductItem.java) |
| Servis | `SupplierClaimService.openClaim()` + `resolveClaim()` | [SupplierClaimServiceImpl.java](pos-product-manager/src/main/java/com/sedcore/purchase/service/impl/SupplierClaimServiceImpl.java) |
| Servis | Batch akışında `shortageAmount > 0` → **otomatik claim açılıyor** | [ProductServiceImpl.java:482-486](pos-product-manager/src/main/java/com/sedcore/product/service/impl/ProductServiceImpl.java) |
| Servis | Batch akışı `purchaseStatus = PARTIAL` set ediyor | [ProductServiceImpl.java:475-476](pos-product-manager/src/main/java/com/sedcore/product/service/impl/ProductServiceImpl.java) |
| Flutter Model | `BatchEntryRow.invoiceQuantity`, `shortageQty`, `hasShortage` | [batch_entry_models.dart:258-313](project_pos/lib/features/inventory/screens/batch_entry/models/batch_entry_models.dart) |
| Flutter Model | `BatchEntryState.shortageItems`, `hasAnyShortage` | [batch_entry_models.dart:430-431](project_pos/lib/features/inventory/screens/batch_entry/models/batch_entry_models.dart) |
| Flutter Provider | `invoiceQuantity` payload'a yazılıyor | [batch_entry_provider.dart:392](project_pos/lib/features/inventory/screens/batch_entry/providers/batch_entry_provider.dart) |
| Flutter UI (aktif path) | Satır başına invoiceQuantity input + "N eksik" chip + banner | [batch_product_screen.dart:664,1188-1198,1803-1821](project_pos/lib/screens/inventory/batch_entry/batch_product_screen.dart) |

### 2.2 Boşluklar (bu tasarımın hedefi)

| # | Boşluk | Etki |
|---|--------|------|
| G1 | **`SupplierClaimController` yok** — REST endpoint yok | Claim açılıyor ama Flutter/React hiç listeleyemez, çözemez. Arka planda birikip "karanlık borç" oluşur. |
| G2 | **`BatchCreateResponse` claim bilgisi taşımıyor** | Batch biter; kullanıcı "şu anda bir claim açıldı" bilgisini ekranda göremez — sadece banner "açılır" diyor, ID/tutar yok. |
| G3 | **Flutter'da Tedarikçi Talepleri (claims) ekranı yok** | Listele/filtrele/çözümle akışı yok. `project_pos/lib/features/purchases/` var ama claims alt dizini yok. |
| G4 | **`StockMovement` satır bazında expectedQty/receivedQty tutmuyor** | Shortage sadece Purchase aggregate düzeyinde (tek tutar). Hangi variant'tan kaç adet eksik geldiği geriye dönük olarak StockMovement'tan **çıkarılamaz** (sadece SupplierClaim.notes'ta yazılı, parse gerektirir). |
| G5 | **`SupplierClaim` satır detayı (line items) yok** | Claim "toplam tutar" seviyesinde. Hangi kalem(ler) eksik, teslimat geldiğinde hangisinin kapandığı takip edilemez. |
| G6 | **Duplicate UI: `features/` kopyası shortage UI'sı içermiyor** | Sprint 3'te migration yapılırken `lib/features/inventory/screens/batch_entry/batch_product_screen.dart` eksik mal bölümünü taşımıyor → regresyon riski. |
| G7 | **Kısmi çözüm (partial resolve) sözleşmesi belirsiz** | 20 eksik → 12 adedi yeni irsaliyeyle geldi, 8 adedi iskonto ile → tek claim iki yöntemle çözülüyor: veri modeli tek `status` tutuyor, akış tarif edilmemiş. |
| G8 | **Hasarlı mal (DAMAGE) girişi için UI yok** | Enum değeri var ama batch ekranında "eksik" dışında bir sebep seçilemiyor. |
| G9 | **Yeni ürün (BatchProductItem) için shortage path'i test edilmemiş** | `invoiceQuantity` alanı DTO'da var, servis hesaplama yapıyor ama yeni ürün satırında Flutter UI'ı input göstermiyor; test kapsamı yok. |
| G10 | **Claim ↔ StockMovement ilişkisi tek yönlü** | Eksik teslimat kapandığında "kapatan StockMovement" hangisi? Backtrace zor. |

---

## 3. TEMEL İLKELER

Tasarım boyunca korunacak dört invariant:

1. **Fatura tutarı ≠ Cari borç.** `invoiceAmount` faturanın yazdığı, `totalAmount` (=`receivedAmount`) cari hesaba yansıyan. Aralarındaki fark `shortageAmount`.
2. **Gelen mal kadar stok, çıkan mal kadar borç.** Eksik mal için **asla fiktif StockMovement** üretilmez. Stok yalnızca fiilen teslim alınan miktarı gösterir.
3. **Claim = cari hesap lensi.** Tedarikçi cari özet/ekstrede: `borç − iskonto − iadeler = net borç`. Açık claim ise "bize borçlu olduğu" kısımdır.
4. **Çözüm yolunu sistem seçmez, kullanıcı seçer.** Sistem sadece eksiği görür ve claim açar. RESOLVED_DELIVERY / RESOLVED_DISCOUNT / RESOLVED_RETURN / CANCELLED geçişleri **kullanıcı aksiyonudur**.

---

## 4. HEDEF MİMARİ (To-be)

### 4.1 Uçtan uca akış

```
┌─────────────────────────┐      POST /product/api/v1/products/batch
│ Flutter Batch Entry     │ ───────────────────────────────────────────┐
│ - invoiceQuantity input │                                            │
│ - shortage banner       │                                            ▼
└─────────────────────────┘                            ┌─────────────────────────────┐
         ▲                                             │ ProductServiceImpl          │
         │ BatchCreateResponse                         │  .batchCreateProducts()     │
         │ + claim:{id,amount,status}                  │                             │
         │                                             │ 1. Purchase kaydı           │
         │                                             │ 2. newProducts → ürün+stok  │
         │                                             │ 3. existingProducts→stok    │
         │                                             │ 4. Purchase tutarları hes.  │
         │                                             │    - invoiceAmount          │
         │                                             │    - totalAmount (received) │
         │                                             │    - shortageAmount         │
         │                                             │ 5. status = PARTIAL         │
         │                                             │ 6. SupplierClaimService     │
         │                                             │    .openClaim(lines[])   ◀── YENİ: satır detayı
         │                                             └──────────┬──────────────────┘
         │                                                        ▼
         │                                           ┌─────────────────────────────┐
         │                                           │ supplier_claims             │
         │                                           │  + supplier_claim_lines     │  ◀── YENİ
         │                                           │  (variant, expectedQty,     │
         │                                           │   receivedQty, reason,      │
         │                                           │   unit_price, line_amount)  │
         │                                           └─────────────────────────────┘
         │
         │
         │       GET  /product/api/v1/supplier-claims?supplierId=...&status=OPEN
         │       GET  /product/api/v1/supplier-claims/{id}
         │       POST /product/api/v1/supplier-claims/{id}/resolve
         │       POST /product/api/v1/supplier-claims/{id}/cancel
         │                                           ◀── YENİ: SupplierClaimController
┌─────────┴──────────────────────────┐
│ Flutter Supplier Claims Screen     │
│  - Açık/kapanmış talepler listesi  │   ◀── YENİ
│  - Detay: satır satır eksikler     │
│  - Çözüm dialog:                   │
│     □ Yeni irsaliye ile gelecek    │
│     □ İskonto/kredi notu           │
│     □ Para iade                    │
│     □ İptal et                     │
└────────────────────────────────────┘
```

### 4.2 Sorumluluk matrisi

| Sorumluluk | Sahip |
|------------|-------|
| Satır bazında `invoiceQuantity` vs `quantity` girişi | Flutter batch_entry (✅ var) |
| `invoiceAmount`, `totalAmount`, `shortageAmount` hesabı | `ProductServiceImpl.batchCreateProducts` (✅ var) |
| Claim açma kararı (shortage > 0) | `ProductServiceImpl` → `SupplierClaimService.openClaim()` (✅ var, ama line detayı yok) |
| Claim satır kayıtları (variant bazında) | `SupplierClaimService` (❌ YENİ) |
| Batch response'a claim özeti koyma | `ProductServiceImpl` → `BatchCreateResponse` (❌ YENİ) |
| Claim REST API | `SupplierClaimController` (❌ YENİ) |
| Claim listele/çöz Flutter UI | `features/supplier_claims/` (❌ YENİ) |
| Batch sonrası "Claim açıldı" toast + Purchase detayında chip | `batch_product_screen` + `purchase_detail_screen` (❌ YENİ bölüm) |

---

## 5. KATMAN TASARIMI

### 5.1 Veritabanı şeması değişiklikleri

**DDL ddl-auto=create olduğu için entity değişikliği → şema otomatik güncellenir.** Manuel SQL yazmıyoruz, ancak `data.sql` seed'lerine dokunulacaksa not edilecek.

**Yeni entity:** `SupplierClaimLine`

```
supplier_claim_lines
  id                  UUID PK
  company_code        VARCHAR(50)   (TOpenSimpleCompanyEntity — @Filter miras)
  claim_id            FK → supplier_claims.id (NOT NULL)
  variant_id          FK → product_variants.id (NULLABLE — yeni ürün henüz yoksa)
  variant_sku         VARCHAR(100)  (denormalize: ürün silinse bile kayıt korunur)
  product_name        VARCHAR(255)  (aynı sebeple denormalize)
  expected_qty        INTEGER       (fatura miktarı)
  received_qty        INTEGER       (fiilen teslim alınan)
  shortage_qty        INTEGER       (expected − received, generated veya hesapla)
  unit_price          DECIMAL(15,2) (fatura birim fiyatı)
  line_amount         DECIMAL(15,2) (shortage_qty × unit_price)
  reason              VARCHAR(20)   (ClaimReason)
  notes               TEXT
  resolved_qty        INTEGER       DEFAULT 0  (kısmi çözümde birikimli artar)
  resolved_amount     DECIMAL(15,2) DEFAULT 0
  is_resolved         BOOLEAN       DEFAULT FALSE
  created_at/updated_at/version
  INDEX (claim_id), INDEX (company_code, variant_id)
```

**`Purchase` → hafif dokunuş:**
- `completion_rate` hesaplanmış alan olarak entity'de `@Transient` (gerekmez, görünümdekinde hesaplanır).

**`supplier_claims` → küçük ekleme:**
- `is_fully_resolved` BOOLEAN — sadece satırların tümü is_resolved olduğunda true. Aggregate sorgular hızlansın.
- `aggregate_reason` değişmez (mevcut `claim_reason` kalır — çoğunlukla tüm satırlar aynı sebeptir; karışık durumda `MIXED` enum değeri eklenebilir).

### 5.2 Backend değişiklikleri

#### 5.2.1 Entity

```java
// pos-product-manager/src/main/java/com/sedcore/purchase/entity/SupplierClaimLine.java  (YENİ)
@Entity
@Table(name = "supplier_claim_lines")
public class SupplierClaimLine extends TOpenSimpleCompanyEntity {
    @ManyToOne(optional=false) private SupplierClaim claim;
    @ManyToOne(fetch=LAZY) private ProductVariant variant;   // yeni ürün ise null olabilir
    private String variantSku;
    private String productName;
    private Integer expectedQty;
    private Integer receivedQty;
    private BigDecimal unitPrice;
    private BigDecimal lineAmount;
    @Enumerated(STRING) private ClaimReason reason;
    private String notes;
    @Builder.Default private Integer resolvedQty = 0;
    @Builder.Default private BigDecimal resolvedAmount = BigDecimal.ZERO;
    @Builder.Default private Boolean isResolved = false;
    public int shortageQty() { return expectedQty - receivedQty; }
    public int remainingQty() { return shortageQty() - resolvedQty; }
}
```

```java
// SupplierClaim.java — collection eklenir
@OneToMany(mappedBy="claim", cascade=ALL, orphanRemoval=true)
private List<SupplierClaimLine> lines;

@Builder.Default
private Boolean isFullyResolved = false;
```

#### 5.2.2 Servis imzası (SupplierClaimService)

```java
// Eski (çalışıyor):
SupplierClaim openClaim(Purchase src, BigDecimal amount, ClaimReason reason, String notes);

// YENİ — line-aware versiyon:
SupplierClaim openClaim(Purchase src, List<ClaimLineSpec> lines, String notes);

record ClaimLineSpec(
    ProductVariant variant,       // null olabilir (yeni ürün path'i)
    String variantSku,             // fallback
    String productName,
    int expectedQty,
    int receivedQty,
    BigDecimal unitPrice,
    ClaimReason reason,
    String lineNote
) {}

// Resolve metodları satır-bazlı:
SupplierClaim resolveByDelivery(String claimId, List<LineDeliverySpec> deliveries, Purchase newPurchase);
SupplierClaim resolveByDiscount(String claimId, BigDecimal amount, String creditNoteNo);
SupplierClaim resolveByRefund  (String claimId, BigDecimal amount, String paymentRef);
SupplierClaim cancelClaim      (String claimId, String reason);
```

#### 5.2.3 ProductServiceImpl.batchCreateProducts — yapılacak değişiklik

`ProductServiceImpl.java:482-486` şu an toplam tutar ile claim açıyor. Satır bazlı spec üretmeye çevrilir:

```java
List<ClaimLineSpec> shortageLines = new ArrayList<>();

// existingProducts iterasyonu
for (BatchExistingItem item : req.getExistingProducts()) {
    if (item.shortageQty() > 0) {
        ProductVariant v = variantRepo.findById(item.getVariantId()).orElseThrow(...);
        shortageLines.add(new ClaimLineSpec(
            v, v.getSku(), v.getProduct().getName(),
            item.resolvedInvoiceQty(), item.getQuantity(),
            item.getUnitPrice(), ClaimReason.SHORTAGE, item.getNotes()
        ));
    }
}

// newProducts iterasyonu — invoiceQuantity ile initialStocks toplamı kıyaslanır
for (BatchProductItem item : req.getNewProducts()) {
    int initialTotal = item.getVariants().stream()
        .flatMap(v -> v.getInitialStocks().stream())
        .mapToInt(s -> s.getQuantity()).sum();
    int invoiceQty = item.getInvoiceQuantity() != null ? item.getInvoiceQuantity() : initialTotal;
    int shortage = invoiceQty - initialTotal;
    if (shortage > 0) {
        // ilk variant'a bağlı bir claim line oluştur (çoklu variant için opsiyonel:
        // ağırlıklı dağıt — v1'de ilk variant yeterli)
        ProductVariant firstCreated = ... (createProduct sonucu);
        shortageLines.add(new ClaimLineSpec(
            firstCreated, firstCreated.getSku(), item.getProduct().getName(),
            invoiceQty, initialTotal,
            firstCreated.getPricing().getPurchasePrice(),
            ClaimReason.SHORTAGE, "Yeni ürün eksik teslimat"
        ));
    }
}

if (!shortageLines.isEmpty()) {
    SupplierClaim claim = supplierClaimService.openClaim(
        purchase, shortageLines,
        "Toplu giriş — fatura ile teslim arasında " + shortageLines.size() + " kalem fark"
    );
    response.setClaim(SupplierClaimSummary.of(claim));
}
```

#### 5.2.4 `BatchCreateResponse` — claim özeti taşısın

```java
// BatchCreateResponse.java'ya eklenecek alan:
private SupplierClaimSummary claim;   // null → claim açılmadı

// YENİ model:
public record SupplierClaimSummary(
    String claimId,
    BigDecimal claimAmount,
    int lineCount,
    ClaimStatus status,
    ClaimReason reason
) {
    public static SupplierClaimSummary of(SupplierClaim c) { ... }
}
```

Bu sayede Flutter **purchaseId + claimId** çifti aldığında toast'u zenginleştirir:
> "Satın alma kaydedildi · 2 kalemde 450 TL eksik → Talep #CLM-241 açıldı"

#### 5.2.5 REST — SupplierClaimController (YENİ)

```
GET    /product/api/v1/supplier-claims                  ?status=OPEN&supplierId=&page=&size=
GET    /product/api/v1/supplier-claims/{id}             → detay + lines
GET    /product/api/v1/supplier-claims/by-purchase/{pid}→ purchase'a bağlı claim(ler)
POST   /product/api/v1/supplier-claims/{id}/resolve/delivery   body: { newPurchaseId, lineDeliveries[] }
POST   /product/api/v1/supplier-claims/{id}/resolve/discount   body: { amount, creditNoteNumber, date }
POST   /product/api/v1/supplier-claims/{id}/resolve/refund     body: { amount, paymentRef, date }
POST   /product/api/v1/supplier-claims/{id}/cancel             body: { reason }
GET    /product/api/v1/suppliers/{sid}/open-claims-total       → özet sayaç
```

URL kuralı: controller `/api/v1/...` yazar, client `product/` prefix ekler (bkz. `.claude/reference/url-routing.md`).

Yetki:
- `ADMIN`, `STORE_ADMIN`, `WAREHOUSE` → tüm işlemler
- `CASHIER` → sadece listele (read-only)

### 5.3 Flutter değişiklikleri

#### 5.3.1 Batch entry — hali hazırda olan (aktif path)

`lib/screens/inventory/batch_entry/batch_product_screen.dart` zaten:
- Satır başına `invoiceQuantity` input ([1783](project_pos/lib/screens/inventory/batch_entry/batch_product_screen.dart:1783))
- "N adet eksik" chip ([1188-1198](project_pos/lib/screens/inventory/batch_entry/batch_product_screen.dart:1188))
- Header banner "N üründe eksik teslimat" ([664](project_pos/lib/screens/inventory/batch_entry/batch_product_screen.dart:664))

**Ekleneceklar:**

1. **Sebep seçici** (chip dropdown: `SHORTAGE` / `DAMAGE`) — satır başına. Default SHORTAGE. DAMAGE için opsiyonel notes.
2. **Yeni ürün satırında invoiceQuantity input** — şu an sadece existing'de var, newProduct path'inde gizli. (Gap G9)
3. **submitAll sonrası yeni toast/dialog**:
   - `BatchCreateResponse.claim != null` ise → Success toast + action button: "Talebi görüntüle" → `/supplier-claims/{id}`.

#### 5.3.2 `features/` duplicate path (Sprint 3 migration hedefi)

`lib/features/inventory/screens/batch_entry/batch_product_screen.dart` shortage UI'ını henüz **barındırmıyor** (Gap G6). Migration yapılırken aktif path'ten port edilmeli. Alternatif: Sprint 3'ten önce dokunulmasın — aktif dosya `lib/screens/`. Bu taslak, `lib/screens/` kopyayı güncelleyecek.

#### 5.3.3 YENİ feature — `features/supplier_claims/`

```
features/supplier_claims/
├── di/supplier_claims_di.dart
├── models/
│   ├── supplier_claim.dart            # id, supplierId/Name, sourcePurchaseId, claimAmount, status, reason, lines[]
│   ├── supplier_claim_line.dart       # variantId, sku, productName, expected, received, shortage, unitPrice, lineAmount
│   └── claim_resolve_request.dart
├── providers/
│   ├── supplier_claims_list_provider.dart   # AsyncNotifier + filter (status, supplier, date range)
│   └── supplier_claim_detail_provider.dart
├── services/
│   └── supplier_claims_service.dart         # ApiClient → REST çağrıları
├── screens/
│   ├── supplier_claims_list_screen.dart     # tablo + filtre bar + "Çöz" buton
│   ├── supplier_claim_detail_screen.dart    # satır satır + resolve sheet
│   └── claim_resolve_sheet.dart             # 3 tab: Delivery / Discount / Refund
└── widgets/
    ├── claim_status_chip.dart
    └── claim_line_row.dart
```

Menü: `db` modülü (Dashboard) → side-bar'a "Tedarikçi Talepleri" eklenir. i18n prefix: `su` (supplier).

#### 5.3.4 Purchase detay ekranında claim chip'i

`features/purchases/screens/purchase_detail_screen.dart` (varsa) ya da listede:
- `purchase.purchaseStatus == PARTIAL` → kırmızı rozet "Eksik"
- `purchase.shortageAmount > 0` → "₺ XX eksik — Talep #ID" chip'i, tıklanınca claim detayına

---

## 6. ÖRNEK END-TO-END AKIŞ

**Senaryo:** Tedarikçi Adem A.Ş. faturası `FTR-2026-118`, 3 kalem:

| Kalem | Ürün | Fatura | Gelen | Durum |
|-------|------|--------|-------|-------|
| 1 | DEB-Diz Balatası (mevcut) | 50 | 50 | Tam |
| 2 | BOS-Silecek (mevcut) | 30 | 20 | **10 eksik** (SHORTAGE) |
| 3 | YENI-Kampanya Şampuanı (yeni) | 20 | 15 | **5 eksik** (SHORTAGE) |

**Birim fiyatlar:** 1=₺100, 2=₺25, 3=₺40.

### Akış

1. **Kasiyer Flutter'da girer:**
   - Satır 2 → `quantity=20`, `invoiceQuantity=30`, `unitPrice=25`
   - Satır 3 → yeni ürün, `invoiceQuantity=20`, initialStocks toplamı=15
   - Banner görür: "2 üründe eksik teslimat — kayıt sonrası talep otomatik açılır"

2. **submitAll → POST /products/batch**  
   Request body özet:
   ```json
   {
     "existingProducts":[
       {"variantId":"DEB-DB-01","quantity":50,"unitPrice":100},
       {"variantId":"BOS-SL-01","quantity":20,"invoiceQuantity":30,"unitPrice":25}
     ],
     "newProducts":[
       {"product":{...}, "variants":[{"initialStocks":[{"quantity":15,...}],...}],
        "invoiceQuantity":20}
     ]
   }
   ```

3. **Backend `ProductServiceImpl.batchCreateProducts`:**
   - Purchase oluştur: `invoiceAmount = 50×100 + 30×25 + 20×40 = 6550`
   - Stok hareketleri: 50 + 20 + 15 (fiilen gelen) = 85 adet
   - `totalAmount = 50×100 + 20×25 + 15×40 = 6100`
   - `shortageAmount = 6550 − 6100 = 450`
   - `purchaseStatus = PARTIAL`
   - `shortageLines`:
     - `{variant:BOS-SL-01, expected:30, received:20, unitPrice:25, lineAmount:250, SHORTAGE}`
     - `{variant:(yeni şampuan varyantı), expected:20, received:15, unitPrice:40, lineAmount:200, SHORTAGE}`
   - `SupplierClaim` açılır: `claimAmount=450`, `lines.size()=2`, `status=OPEN`

4. **Response:**
   ```json
   {
     "purchaseId":"PUR-2041",
     "invoiceNumber":"FTR-2026-118",
     "successCount":3,"failCount":0,"totalAmount":6100,
     "claim":{
       "claimId":"CLM-241","claimAmount":450,"lineCount":2,
       "status":"OPEN","reason":"SHORTAGE"
     },
     "results":[...]
   }
   ```

5. **Flutter toast:** "Satın alma kaydedildi · ₺450 eksik → Talep #CLM-241" [Görüntüle]

6. **3 gün sonra:** Tedarikçi eksik 10 silecek + 5 şampuanı yeni irsaliye (FTR-2026-141) ile gönderir.

7. **Depocu yeni bir batch girişi yapar, Purchase `PUR-2048` oluşur. Supplier Claim detayında "Çöz" → "Yeni irsaliye ile" → referans `PUR-2048` seçer.**
   - Backend `resolveByDelivery`:
     - `line[0].resolvedQty += 10` → remaining = 0 → `isResolved=true`
     - `line[1].resolvedQty += 5` → remaining = 0 → `isResolved=true`
     - Tüm lines resolved → `claim.status = RESOLVED_DELIVERY`, `resolvedByPurchase = PUR-2048`
     - `sourcePurchase.purchaseStatus` → `COMPLETED` (shortageAmount 0'a düşer)

8. **Cari hesap etkisi:** İlk Purchase PUR-2041 cariye **6100** yazdı (shortage için borç yazılmadı). Yeni Purchase PUR-2048 cariye **450** yazar. Toplam net borç = faturanın gerçeği.

---

## 7. EDGE CASE'LER

| # | Senaryo | Tasarım |
|---|---------|---------|
| E1 | Fazla teslimat (received > invoice) | `shortageQty()` zaten `Math.max(0, ...)`; fazla gelenler normal stok girişi. Uyarı toast'u gösterilir; claim açılmaz. |
| E2 | Kısmi iskonto çözümü (12 adet delivery + 8 adet iskonto) | Line'lar ayrı ayrı çözülür. Bazı line'lar `resolvedQty < shortageQty` kalırsa `isResolved=false`. Claim status "mixed-resolved" olmaz; hem delivery hem discount log'u için `resolution_events` tablosu v2'ye ertelenir (v1: status son yapılan aksiyonu gösterir). |
| E3 | Tedarikçi değişikliği (yanlış tedarikçi seçilmişti) | Claim `CANCELLED` + yeni claim açılır. Purchase.supplier değiştirilmez (audit). |
| E4 | Purchase iptali | `isCancelled=true` set edilince tüm bağlı claim'ler otomatik `CANCELLED`. Stok geri alma ayrı concern (bkz. purchase return flow). |
| E5 | Yeni ürün claim'inde `variantId=null` olur (ürün hâlâ oluşturulmamış olsaydı) | `ProductServiceImpl` akışı ürün/variant'ı claim açılmadan önce oluşturuyor → variantId her zaman dolu. Bu yüzden `supplier_claim_lines.variant_id NOT NULL` yapabiliriz. Ama denormalize alanlar (sku/name) ürün sonradan silinirse bile rapor için kalır. |
| E6 | İki concurrent batch aynı purchaseId'yi aynı anda işliyor | Purchase.`@Version` (şu an var) + claim açma `@Transactional REQUIRED`. Çakışma → `OptimisticLockException` → Flutter retry. |
| E7 | Kullanıcı sebepsiz `invoiceQuantity` girip quantity değiştirmedi (shortage=0) | Claim açılmaz. Server `BatchExistingItem.shortageQty()` = 0 → filtre. |
| E8 | DAMAGE girişi | Flutter'da per-line "Eksik / Hasarlı" chip dropdown. Payload'a `reason` alanı eklenir. Backend line spec'ine taşınır. Tek claim içinde hem SHORTAGE hem DAMAGE olabilir; `claim.claimReason` → `MIXED` (enum'a eklenir) veya çoğunluğa göre set edilir. v1: hepsi SHORTAGE, DAMAGE v2 (bkz. §8). |
| E9 | Çoklu variant'lı yeni ürün (footwear) eksik geldi | `invoiceQuantity` ürün seviyesinde (satır). Variant başına kırılım v1'de ağırlıklı dağıtılmaz, ilk variant'a bağlanır. v2: variant × quantity satır başına giriş. |
| E10 | `purchaseStatus = DISCOUNTED` ne zaman set edilir? | Tüm claim satırları `resolveByDiscount` ile kapandığında ve shortageAmount 0'a düştüğünde. Karışık çözümde `COMPLETED` olur (shortage kalmadı, iskonto da uygulandı → her ikisi de sıfır noktaya ulaşır). |

---

## 8. UYGULAMA SIRASI (Sprint planı)

Mevcut gövde zaten oluşmuş durumda. Kalan işler:

### Sprint A (1 hafta, must-have)
1. **Backend:** `BatchCreateResponse.claim` alanı + `SupplierClaimSummary` modeli → ProductServiceImpl dön.
2. **Backend:** `SupplierClaimController` + 4 temel endpoint (list, detail, resolve/discount, cancel).
3. **Backend:** `SupplierClaimServiceImpl.openClaim(List<ClaimLineSpec>)` overload'ı — mevcut aggregate versiyon deprecated (not silinmiş).
4. **Backend:** `SupplierClaimLine` entity + repository.
5. **Flutter:** `features/supplier_claims/` minimum — list + detail + discount resolve dialog.
6. **Flutter:** Batch toast'a claim linki.
7. **i18n:** `su.claim_*` anahtarları `security/data.sql`'e eklenir.

### Sprint B (1 hafta)
8. **Backend:** `resolveByDelivery` — satır bazlı kısmi kapatma.
9. **Flutter:** Resolve sheet → 3 tab (Delivery / Discount / Refund).
10. **Flutter:** Purchase detay ekranında shortage chip.
11. **Test:** integration — 3 senaryo (tam / eksik→iskonto / eksik→delivery).

### Sprint C (opsiyonel, 2-3 gün)
12. DAMAGE reason UI + backend line-level reason.
13. `resolution_events` tablosu (audit log — kim ne zaman hangi çözüm uygulamış).
14. Dashboard widget: "Açık talep: N adet / ₺ toplam".
15. Export: Açık claim listesi PDF/Excel (xlsx skill).

---

## 9. TEST SENARYOLARI

```
Unit — backend
  ✓ shortageAmount hesabı: invoice=100, received=80, unit=10 → claim=200 ₺
  ✓ openClaim(lines): 2 line → persist 2 supplier_claim_lines
  ✓ resolveByDelivery: line.remainingQty = 0 → isResolved=true
  ✓ resolveByDiscount: claim.resolvedAmount += amount, status=RESOLVED_DISCOUNT
  ✓ cancelClaim: tüm line'lar isResolved=true işaretlenir mi? (HAYIR — status=CANCELLED yeterli)

Integration — end-to-end
  ✓ batch ile 3 kalemde 2 eksik → Purchase.PARTIAL + SupplierClaim açıldı + response.claim dolu
  ✓ aynı fatura tekrar submit → idempotency? (Sprint C, ayrı concern)
  ✓ eksik sonra delivery → eski claim RESOLVED_DELIVERY + yeni Purchase.resolvedByClaim doldu

Flutter — widget
  ✓ invoiceQuantity > quantity → shortage chip görünür
  ✓ submitAll sonrası response.claim ≠ null → toast'ta "Talep #X" linki
  ✓ ClaimsListScreen: status filter çalışır
  ✓ ResolveSheet: discount tab'ta amount > claimAmount → validation hatası

Manuel — UX
  ✓ Banner: "2 üründe eksik" → saymanın batch submit ettiği anda claim oluştuğunu hissetmesi
  ✓ Claim listesi → detay → Çöz butonu akışı ≤ 4 tıklamada bitebiliyor mu?
```

---

## 10. RİSK VE AÇIK SORULAR

1. **Kısmi çözüm status'ü tek alanda tutulabilir mi?** — Öneri: `status` ClaimStatus en son uygulanan büyük aksiyona göre set edilir, detay `supplier_claim_lines.resolvedQty + resolvedAmount` okunur. `resolution_events` (ayrı tablo) gerçek audit v2'ye bırakılır.
2. **DAMAGE için stok hareketi ne olur?** — Hasarlı mal geldi ve stoka koymak istemiyorsak: `quantity` fiilen alınan (sağlam) miktar, `invoiceQuantity` fatura, `reason=DAMAGE`. Hasarlı mal iade sürecinde ayrı `PurchaseReturn` üretmek gerekebilir → **ayrı tasarım gerektirir**, bu tasarım sadece kaydı açar.
3. **Tedarikçi cari hesabı: claim açıldığı anda borç düşer mi?** — **HAYIR**. `Purchase.totalAmount` zaten fiilen gelen maldır ve cari borç bu. Claim = ayrı alacak kalemi; resolve edilince ya yeni Purchase yazılır (delivery) ya da iskonto/iade ile tedarikçinin bize iade edeceği tutar düşer (`SupplierAccount.credit += resolvedAmount`).
4. **Çoklu lokasyon:** Bir batch tek `locationId`'ye teslim alır (mevcut tasarım). Eksik mal tedarikçi seviyesinde olduğu için lokasyon problemi yok.
5. **Yetki ayrımı:** CASHIER batch yapıp claim açabilir ama resolve edemez (iskonto/iade finansal karar) — STORE_ADMIN+ gerekir. Backend'de `@PreAuthorize` veya filter kontrolü.

---

## 11. DOKÜMAN LİNKLERİ

- Mevcut akış detayı: [docs/batch-entry-flow.md](docs/batch-entry-flow.md)
- Hiyerarşi: [docs/batch-entry-hierarchy.md](docs/batch-entry-hierarchy.md)
- Flutter batch entry kuralları: [project_pos/lib/features/inventory/screens/batch_entry/CLAUDE.md](project_pos/lib/features/inventory/screens/batch_entry/CLAUDE.md)
- URL kuralı: `.claude/reference/url-routing.md`
- API zarfı: `.claude/reference/api-response.md`
- Yeni entity runbook: `.claude/runbooks/new-entity.md`
- Yeni endpoint runbook: `.claude/runbooks/new-endpoint.md`

---

_Tasarım taslağı — uygulanmadan önce PR öncesi Sprint A checklist'ine dönüştürülecek._
