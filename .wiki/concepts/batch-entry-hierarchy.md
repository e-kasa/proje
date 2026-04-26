---
title: Batch Entry — Ürün Oluşum Hiyerarşisi
type: concept
source: .claude/reference/batch-entry-hierarchy.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# Batch Entry — Ürün Oluşum Hiyerarşisi

> **Bu dosya tek kaynaktır.** Batch entry (toplu ürün girişi) akışında hangi
> entity'ler hangi sırada, hangi parent FK ile oluşuyor — burada tanımlıdır.
>
> Son güncelleme: 2026-04-20

---

## 1. İki Ayrı Akış

Batch entry endpoint (`POST /product/api/v1/products/batch`) iki farklı senaryoyu tek isteğe birleştirir:

### A) YENİ ÜRÜN akışı — `newProducts[]`
Ürün sistemde yok → Product + Variant + Pricing + Barcode + OEM + CrossRef + StockLevel + StockMovement oluştur.

### B) MEVCUT ÜRÜN akışı — `existingProducts[]`
Barkod/OEM eşleşmiş → sadece StockLevel güncelle + StockMovement (PURCHASE_IN) oluştur.

---

## 2. Entity Oluşum Ağacı — Yeni Ürün

```
Purchase (ortak fatura başlığı — batch başında 1 kez oluşur)
│
└─ Product (her yeni satır için 1)
   │  — name, sku, categoryId, brand, unit, sector, metadata
   │
   └─ ProductVariant (footwear: N · diğer: 1)
       │  — sku (globally unique), name, attributes, shelfLocationCode
       │
       ├─ VariantPricing (variant başına 1)
       │   — purchasePrice, salePrice, vatRate, vatIncluded, taxExempt
       │
       ├─ Barcode (variant başına 0-N)
       │   — barcodeCode, barcodeType (EAN13/CODE128), isPrimary
       │
       ├─ StockMovement (PURCHASE_IN, variant × location)
       │   — quantity, unitPrice, purchase FK
       │
       ├─ StockLevel (addStock ile upsert, variant × location × company)
       │   — @Version ile optimistic lock
       │
       ├─ OemNumber (TÜM variantlara × tüm OEM'ler)  ← 2026-04-20: variant[0] yerine tümüne bindirilir
       │   — oemNumber, manufacturer, isPrimary
       │
       └─ CrossReference (TÜM variantlara × tüm CR'ler)  ← aynı fix
           — crossRefNumber, crossRefBrand, notes
```

**Önemli:** Footwear 5 numara (42, 43, 44, 45, 46) + 3 OEM kodu → 5 × 3 = 15 OEM kaydı oluşur. Her varyant OEM'lere sahip olur.

---

## 3. Entity Oluşum Ağacı — Mevcut Ürün

```
Purchase (aynı fatura başlığı — yeni ürünlerle ortak)
│
└─ StockMovement (PURCHASE_IN, mevcut variantId'ye)
   │  — quantity, unitPrice, purchase FK, variant FK
   │
   └─ StockLevel (addStock ile bakiye artır)

✗ Product oluşmaz
✗ ProductVariant oluşmaz
✗ VariantPricing oluşmaz (fiyat sistemde zaten var)
✗ Barcode/OEM/CrossRef oluşmaz
```

---

## 4. SupplierAccount Güncellemesi — Batch Sonunda

Batch tamamlandığında **toplam teslim tutarı** tedarikçi cari hesabına borç olarak eklenir:

```java
// ProductServiceImpl.batchCreateProducts(), Faz 7
if (totalAmount > 0) {
    supplierAccountService.applyDebit(supplier, totalAmount);
    // SupplierAccount:
    //   currentBalance += totalAmount
    //   totalDebt += totalAmount
    //   lastPurchaseDate = NOW
    //   transactionCount++
    //   updateCalculatedFields()  (availableCreditLimit vs.)
}
```

**Tutar seçimi:** `invoiceAmount` değil `totalAmount` (gerçek teslim). Fatura ile teslim arasındaki eksiklik `SupplierClaim` üzerinden ayrıca yönetilir (Faz 6).

---

## 5. Transaction Topolojisi

| Katman | Propagation | Rollback davranışı |
|--------|-------------|---------------------|
| `batchCreateProducts()` outer | `REQUIRED` | Purchase + toplam tutar + SupplierAccount atomik |
| `_createProductWithPurchase()` | `REQUIRES_NEW` | Bağımsız — **bir ürün fail olursa diğerleri devam** |
| `createProduct()` tekil | `REQUIRES_NEW` | Aynı |

**Partial success:** Bir yeni ürün başarısız olursa `BatchItemResult.success=false` dönülür, diğerleri kaydolmaya devam eder. Purchase ortaktır — `totalAmount` sadece başarılı satırların tutarlarını içerir.

---

## 6. Alan Mapping — Flutter Payload → Backend Entity

| Flutter alan | Backend entity.alan | Not |
|-------|---------------------|-----|
| `supplierId` | `Purchase.supplier_id` | @ManyToOne |
| `invoiceNumber` | `Purchase.invoice_number` | Unique |
| `purchaseDate` | `Purchase.purchase_date` | LocalDate |
| `locationId` + `locationType` | `Purchase.location_id`, `StockMovement.location_id` | STORE/WAREHOUSE |
| `newProducts[].product.{name,sku,...}` | `Product.*` | SKU globally unique |
| `newProducts[].variants[].sku` | `ProductVariant.sku` | Flutter `_generateSku()` → timestamp + Random.secure() |
| `newProducts[].variants[].attributes` | `ProductVariant.attributes` (JSONB) | Map<String,String> |
| `newProducts[].variants[].pricing.*` | `VariantPricing.*` | Variant başına 1 kayıt |
| `newProducts[].variants[].barcodes[]` | `Barcode` (N adet per variant) | isPrimary=true max 1 |
| `newProducts[].variants[].initialStocks[]` | `StockMovement` + `StockLevel` | addStock upsert |
| `newProducts[].oemNumbers[]` | `OemNumber` (TÜM variantlara) | 2026-04-20 düzeltildi |
| `newProducts[].crossReferences[]` | `CrossReference` (TÜM variantlara) | 2026-04-20 düzeltildi |
| `existingProducts[].variantId` | `StockMovement.variant_id` | Sadece stok güncelle |
| `existingProducts[].quantity` | `StockMovement.quantity` | + StockLevel.addStock |
| `existingProducts[].unitPrice` | `StockMovement.unit_price` | Purchase.totalAmount'a katılır |
| `existingProducts[].invoiceQuantity` | `Purchase.shortage_amount` hesabı | quantity ≠ invoiceQuantity → shortage |

---

## 7. SKU Üretimi — Güvenli Unique ID

Flutter `batch_entry_provider.dart:_generateSku()`:

```dart
static final Random _skuRandom = Random.secure();  // CSPRNG

String _generateSku() {
  final ms = DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase();
  final rand = _skuRandom.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0').toUpperCase();
  return 'SKU-$ms-$rand';  // örn: SKU-18F8A12CD45-8A3F2B1C
}
```

- **Format:** `SKU-<ms-hex>-<rand-hex>` (yaklaşık 20 karakter)
- **Çakışma olasılığı:** 2^32 rastgele + timestamp → pratik olarak sıfır
- **Öncesi:** timestamp substring + microsecond (çakışma olabilirdi)

---

## 8. Kritik Düzeltmeler (2026-04-20)

### P1-1: Footwear OEM/CrossRef tüm variantlara bindirilir
- **Öncesi:** `firstVariant = product.getVariants().get(0)` → sadece ilk variant
- **Sonrası:** `for (ProductVariant v : targetVariants)` → her variant için her OEM/CR

### P1-2: SupplierAccount otomatik borç
- **Öncesi:** Batch sonunda cari hesap güncellenmiyordu → out-of-sync
- **Sonrası:** `supplierAccountService.applyDebit(supplier, totalAmount)` çağrısı eklendi

### P1-3: SKU UUID-benzeri
- **Öncesi:** `timestamp.substring(7) + microsecond%1000` → collision riski var
- **Sonrası:** `millisecondsSinceEpoch + Random.secure().nextInt(2^32)` → collision sıfıra yakın

---

## 9. Bilinen Kısıtlamalar (P2/P3)

- **Primary barcode constraint yok** — Payload'da 2 `isPrimary=true` gelirse ikisi de kaydolur
- **VariantPricing validFrom null** — pricing history için eklenmeli (şu an sadece create_time audit)
- **Partial success → Purchase.totalAmount** — başarılı satırların toplamı yazılır, fatura toplamından düşük olabilir
- **N+1 product reload** — OEM/CR bölümünde product reload gerekiyor (JOIN FETCH ile optimize edilebilir)

---

## 10. İlgili Dosyalar

| Dosya | Rol |
|-------|-----|
| `pos-product-manager/src/main/java/com/sedcore/product/service/impl/ProductServiceImpl.java` | batchCreateProducts, _createProductWithPurchase |
| `pos-product-manager/src/main/java/com/sedcore/product/model/BatchCreateRequest.java` | Request DTO |
| `pos-product-manager/src/main/java/com/sedcore/product/model/BatchProductItem.java` | Yeni ürün item DTO |
| `pos-product-manager/src/main/java/com/sedcore/product/model/BatchExistingItem.java` | Mevcut ürün item DTO |
| `pos-product-manager/src/main/java/com/sedcore/product/model/BatchItemResult.java` | Sonuç DTO |
| `pos-product-manager/src/main/java/com/sedcore/supplier/service/impl/SupplierAccountServiceImpl.java` | applyDebit / applyCredit |
| `project_pos/lib/screens/inventory/batch_entry/providers/batch_entry_provider.dart` | Flutter `submitAll()` payload üretimi |

---

## İlgili CLAUDE.md Bölümleri

- Kök `CLAUDE.md` §5 — Domain Özeti (diyagram: OEM/CrossRef ProductVariant altında)
- `project_pos/lib/screens/inventory/batch_entry/CLAUDE.md` — Flutter tarafı akışı
- `pos-product-manager/CLAUDE.md` §6a — Backend batch endpoint
