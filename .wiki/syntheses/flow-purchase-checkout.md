---
title: Flow — Purchase Checkout
type: synthesis
source: .claude/wiki/flows/purchase-checkout.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Purchase Checkout Flow

## Amaç

Tedarikçiden alınan malı sisteme kaydetmek — stok artışı (sadece gelen mal) + cari hesap borç (sadece gelen mal tutarı) + ledger entry + eksik teslimat varsa otomatik claim.

## Tetikleyici

Flutter batch_entry ekranı → `POST /product/api/v1/purchases` → `PurchaseControllerImpl.createPurchase(PurchaseRequest)` → `PurchaseServiceImpl.createPurchase`.

## Akış (6 Adım)

```
createPurchase(request) [@Transactional]
 ├─ 1. SUPPLIER DOĞRULA → yoksa NotFoundException
 │
 ├─ 2. TUTAR HESAPLA — 3 ayrı toplam
 │     invoiceAmount  = Σ (item.invoiceQty  × item.unitPrice)   ← fatura brüt
 │     totalAmount    = Σ (item.receivedQty × item.unitPrice)   ← gelen mal
 │     shortageAmount = invoiceAmount − totalAmount
 │     status = shortage > 0 ? PARTIAL : COMPLETED
 │     purchase = save()
 │
 ├─ 3. STOK HAREKETLERİ — sadece receivedQty kadar
 │     for each PurchaseItemRequest where receivedQty > 0:
 │       stockLevelService.addStock(variantId, locationId, locationType, receivedQty)
 │       StockMovement(PURCHASE_IN, qty=receivedQty) save
 │
 ├─ 4. SUPPLIER ACCOUNT DEBIT — sadece totalAmount
 │     supplierAccount.applyDebit(totalAmount)  → @Version save
 │
 ├─ 5. LEDGER KAYDI
 │     AccountTransaction { type=PURCHASE, debit=totalAmount, ... } save
 │
 └─ 6. SHORTAGE VARSA CLAIM OTOMATIK AÇ
       if (shortageAmount > 0):
         supplierClaimService.openClaim(purchase, shortageLines, ...)
```

## Side Effects

| Tablo | Etki |
|---|---|
| `purchases` | +1 row |
| `stock_levels` | N row increment (sadece receivedQty > 0 olanlar) |
| `stock_movements` | +N row (type=PURCHASE_IN) |
| `supplier_accounts` | 1 row update (currentBalance += totalAmount, @Version) |
| `account_transactions` | +1 row (type=PURCHASE) |
| `supplier_claims` | 0 veya +1 row (shortage varsa) |
| `supplier_claim_lines` | +N row (her eksik kalem) |

## İnvariant: İnvoiceAmount Ayrışması

**Kritik**: cari hesaba yansıyan borç `totalAmount` — `invoiceAmount` değil. Çünkü eksik gelen mal fiilen teslim alınmadı; o tutar için zorlamak yanlış (open claim mekanizması kurulu).

Eğer sonradan:
- **Teslimat tamamlanırsa** → yeni PURCHASE_IN (ayrı transaction) → totalAmount artar, shortage azalır
- **İskonto alınırsa** → `applyDiscount(purchaseId, amount)` → shortage azalır, discount birikir, **SupplierAccount etkisi yok**, DISCOUNT tipi audit transaction yazılır

## Race / Concurrency

- **StockLevel.addStock**: atomic increment (`@Modifying`) — race yok
- **SupplierAccount** (`@Version`): iki paralel purchase aynı supplier → lost update korur
- **Purchase** (`@Version`): applyDiscount vs cancel paralel gelirse opt-lock yakalar

## İptal ve İade

- `cancelPurchase(id)` → PURCHASE_RETURN_OUT stok düşüş + SupplierAccount reverseDebit + cancel mevcut PURCHASE transactions
- `createPurchaseReturn(id, request)` → kısmi iade, stok düşüş + SupplierAccount applyCredit + SUPPLIER_RETURN transaction
- `applyDiscount(id, amount)` → shortage kapatma, cari etkisiz, DISCOUNT transaction audit

## Batch Entry Bağlantısı

Flutter [[syntheses/flow-batch-entry]] akışı bu endpoint'e POST eder — tek submit ile header + N kalem + opsiyonel peşin ödeme.

## Sources

- `pos-product-manager/src/main/java/com/sedcore/purchase/service/impl/PurchaseServiceImpl.java` (createPurchase: 81–206)
- `pos-product-manager/src/main/java/com/sedcore/purchase/model/PurchaseRequest.java`
- `pos-product-manager/src/main/java/com/sedcore/supplier/service/impl/SupplierAccountServiceImpl.java`

## Related

- [[entities/purchase]]
- [[entities/supplier]]
- [[entities/supplier-account]]
- [[entities/supplier-claim]]
- [[entities/stock-movement]]
- [[entities/account-transaction]]
- [[syntheses/flow-batch-entry]]
- [[syntheses/flow-drift-reconciliation]]
- [[syntheses/flow-sale-checkout]]
