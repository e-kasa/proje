---
title: Purchase (detailed merge from .claude/wiki/)
type: entity
source: .claude/wiki/entities/purchase.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
note: "MERGE_NEEDED — .wiki/entities/purchase.md is brief; this verified version has full invoiceAmount/totalAmount/shortageAmount triplet detail + relationships + traps."
---

# Purchase

## Amaç

Tedarikçiden yapılan satın almanın **başı** — fatura bilgileri, tutar ayrımları, teslimat durumu. Drift kaynaklarından ikinci zincir: cari hesap + ledger (TransactionType.PURCHASE). Eksik teslimat için [[entities/supplier-claim]] (auto-open) mekanizmasını tetikler.

## InvoiceAmount vs TotalAmount vs ShortageAmount — Kritik Üçlü

Purchase domain'inin **en önemli kavramı**. Üç tutar ayrı yönetilir:

| Alan | Anlam | Formül |
|---|---|---|
| `invoiceAmount` | Faturadaki brüt toplam | Σ (invoiceQty × unitPrice) |
| `totalAmount` | Gerçekte depoya/mağazaya GİREN mal tutarı | Σ (receivedQty × unitPrice) |
| `shortageAmount` | Açık eksik teslimat | `invoiceAmount − totalAmount` (başlangıçta) |
| `discountAmount` | Tedarikçi iskontosu/kredi notu ile kapatılan | applyDiscount birikimli |

**Cari hesaba yansıyan borç = `totalAmount`** — invoiceAmount değil. Eksik mal için baştan borç yazılmaz (çünkü o mal gelmedi); sonradan iskonto ile kapanırsa `shortageAmount` azalır, `discountAmount` artar, `totalAmount` değişmez.

**İnvariant**: `invoiceAmount == totalAmount + shortageAmount + discountAmount` (claim lifecycle boyunca korunur)

## Kritik Alanlar (Diğerleri)

| Alan | Tip | Anlam |
|---|---|---|
| `supplier` | FK Supplier, LAZY, NOT NULL | Tedarikçi zorunlu (peşin yok gibi) |
| `purchaseDate` | LocalDate | Fatura tarihi |
| `invoiceNumber` | String, NOT NULL | Fatura no (unique değil — aynı tedarikçiden aynı no tekrarlanabilir?) |
| `deliveryNoteNumber` | String(100) | İrsaliye no (opsiyonel) |
| `paidAmount` | BigDecimal(15,2) | Tedarikçiye ödenen |
| `locationId` / `locationType` | String(50) / String(10) | Malın teslim alındığı yer — STORE\|WAREHOUSE |
| `purchaseStatus` | enum | COMPLETED / PARTIAL / DISCOUNTED / CANCELLED |
| `isCancelled` | Boolean | Soft cancel |
| `@Version` | Long | Concurrent update koruma (paidAmount, shortageAmount mutate) |

## PurchaseStatus Enum

- **COMPLETED** — tam teslimat, shortage yok
- **PARTIAL** — shortage > 0, claim açık
- **DISCOUNTED** — shortage iskonto ile tamamen kapandı
- **CANCELLED** — purchase iptal

## İlişkiler

```
Purchase ──> Supplier (NOT NULL)
         ──< StockMovement (cascade ALL, mappedBy = purchase)
         ──< SupplierClaim (shortage > 0 ise auto-open)
         ──< AccountTransaction (type = PURCHASE | SUPPLIER_RETURN | DISCOUNT | CANCEL)
```

## Helper Metodlar

```java
BigDecimal getRemainingDebt()  // totalAmount − paidAmount
boolean isOnCredit()           // remainingDebt > 0
```

Sale'den farklı: Purchase'te customer null olma durumu yok — supplier her zaman var. Peşin alım için `paidAmount == totalAmount` set edilir, `isOnCredit() == false`.

## @Version Pattern

Doğru — `paidAmount`, `shortageAmount`, `discountAmount`, `purchaseStatus` **mutate** edilir (claim resolve + applyDiscount + ödeme). İki paralel işlem için koruma.

## İndeksler

```sql
idx_purchase_supplier (supplier_id, purchase_date)   -- tedarikçi ekstresi
idx_invoice_number    (invoice_number)                -- arama (unique değil)
```

`invoice_number` unique değil — aynı tedarikçiden aynı no gelirse çakışma yok. Dev dikkat: aynı fatura iki kere girilebilir.

## Tuzaklar

- **`invoiceAmount == totalAmount` varsayımı yanlış** — eksik teslimat yaygın, iki ayrı tutar takip edilmeli. Raporlarda `totalAmount` kullan (cari etkisi), `invoiceAmount` kullanma (teslim alınmamış mal)
- **`shortageAmount < 0` olmamalı** — applyDiscount guard ediyor ama invariant bozulursa drift
- **Purchase iptal sonrası claim açık kalır mı?** — kod explicit kapatmıyor (incele); claim lifecycle ayrı [[entities/supplier-claim]]
- **`locationId` nullable** — StockMovement'ta null kalırsa stok hareketli görünür ama StockLevel güncellenmez (drift kaynağı)
- **CLAUDE.md prod-ready kural #3**: Purchase → storeId zorunlu (batch entry'de `setStoreId` çağrısı şart)

## Sources

- `pos-product-manager/src/main/java/com/sedcore/purchase/entity/Purchase.java`
- `pos-product-manager/src/main/java/com/sedcore/purchase/service/impl/PurchaseServiceImpl.java` (createPurchase: 81–206, applyDiscount: 430–509)

## Related

- [[entities/supplier]]
- [[entities/supplier-account]]
- [[entities/supplier-claim]] (auto-open on shortage)
- [[entities/stock-movement]]
- [[entities/account-transaction]]
- [[syntheses/flow-purchase-checkout]]
- [[concepts/optimistic-lock-version]]
