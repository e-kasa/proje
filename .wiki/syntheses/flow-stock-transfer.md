---
title: Flow — Stock Transfer
type: synthesis
source: .claude/wiki/flows/stock-transfer.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Stock Transfer Flow

## Amaç

Bir lokasyondaki stoğu başka bir lokasyona aktarmak — StockLevel ayarlaması + iki yönlü audit kaydı.

## Tetikleyici

Flutter transfer ekranı → `POST /product/api/v1/stock-transfers` → `StockTransferServiceIntegrated.createTransfer(request)`.

## Akış (5 Adım, Her Kalem için Döngü)

```
createTransfer(request) [@Transactional]
 ├─ 1. TRANSFER KAYDI
 │     new StockTransfer {
 │       fromLocationId, fromLocationType,
 │       toLocationId,   toLocationType,
 │       notes
 │     }
 │     transfer = save()
 │
 └─ for each StockTransferItemRequest:
      ├─ variant = variantRepository.findById(...)   ← yoksa throw
      │
      ├─ 2. KAYNAKTAN DÜŞ
      │   stockLevelService.deductStock(variantId, fromLocationId, qty)
      │   → PESSIMISTIC lock + "yetersiz stok" guard
      │
      ├─ 3. TRANSFER_OUT HAREKETİ (audit)
      │   StockMovement {
      │     variant, locationId=fromLocationId,
      │     locationType=fromLocationType,
      │     type=TRANSFER_OUT, qty, transfer=transfer
      │   } save
      │
      ├─ 4. HEDEFE EKLE
      │   stockLevelService.addStock(variantId, toLocationId, toLocationType, qty)
      │   → @Modifying atomic increment (veya yeni row oluştur)
      │
      └─ 5. TRANSFER_IN HAREKETİ (audit)
          StockMovement {
            variant, locationId=toLocationId,
            locationType=toLocationType,
            type=TRANSFER_IN, qty, transfer=transfer
          } save
```

## Side Effects

| Tablo | Etki |
|---|---|
| `stock_transfers` | +1 row (transfer başı, 1 kez) |
| `stock_levels` (kaynak) | quantity decrement (pessimistic lock) |
| `stock_levels` (hedef) | quantity increment (atomik) |
| `stock_movements` | +2 row (TRANSFER_OUT + TRANSFER_IN) |

## Atomicity

Tüm flow tek `@Transactional` metodu. Herhangi bir kalem fail olursa tüm transfer rollback.

## Hata Yolları

| Durum | Sonuç |
|---|---|
| Variant bulunamadı | RuntimeException — transaction rollback |
| Kaynakta stok yetersiz | `BusinessException("Stok yetersiz!")` — rollback |
| Kaynak StockLevel kaydı hiç yok | `BusinessException("Stok kaydı bulunamadı")` — rollback |
| Hedef StockLevel yok | `addStock` yeni row oluşturur (normal davranış) |
| DB commit fail | Tüm transfer rollback — consistent |

## Drift İlişkisi

Transfer flow atomik olduğu için **drift yaratmaz**. Eğer StockMovement ledger'ı ile StockLevel denormalize arasında sapma varsa sebep Transfer flow değil — Purchase/Sale/Count flow'larından biri.

## Sektör Notu

Yedek parça zincirinde: merkez depo → şubeler haftalık toplu transfer yaygın.

## Sources

- `pos-product-manager/src/main/java/com/sedcore/inventory/service/impl/StockTransferServiceIntegrated.java`
- `pos-product-manager/src/main/java/com/sedcore/inventory/service/impl/StockLevelServiceImpl.java` (deductStock + addStock mekaniği)

## Related

- [[entities/stock-transfer]]
- [[entities/stock-level]]
- [[entities/stock-movement]]
- [[entities/store]]
- [[entities/warehouse]]
- [[syntheses/flow-sale-checkout]]
- [[concepts/pattern-denormalization-with-reconcile]]
