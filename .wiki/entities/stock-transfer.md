---
title: StockTransfer — Lokasyonlar Arası Transfer
type: entity
source: .claude/wiki/entities/stock-transfer.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# StockTransfer

## Amaç

İki lokasyon (Store veya Warehouse) arasında stok hareketinin **başı**. Her StockTransfer iki yönlü hareket yaratır: kaynak TRANSFER_OUT + hedef TRANSFER_IN.

## Alanlar

| Alan | Tip | Anlam |
|---|---|---|
| `fromLocationId` | String(50) | Kaynak — Store.code veya Warehouse.code |
| `fromLocationType` | String(10) | `STORE` \| `WAREHOUSE` |
| `toLocationId` | String(50) | Hedef kod |
| `toLocationType` | String(10) | Hedef tipi |
| `notes` | String(500) | Serbest not |
| `@Version` | Long | Concurrent transfer state koruma |
| `movements` | `@OneToMany List<StockMovement>` | Bu transfer'in yarattığı tüm hareketler (cascade ALL) |

## İlişkiler

```
StockTransfer ──< StockMovement (mappedBy = "transfer", type = TRANSFER_OUT | TRANSFER_IN)
              ──> Store / Warehouse (indirect via location codes — plain String, FK yok)
```

Not: `from*` ve `to*` tarafları String — Store/Warehouse entity'ye JOIN değil. Silinen lokasyon orphan transfer bırakır (soft-delete ile azaltılır).

## @Version Pattern

Doğru — `notes` alanı güncellenebilir, `movements` listesi cascade'li değişir. İki paralel update için koruma.

## İndeksler
Tabloda explicit index yok (sadece PK + companyCode filter). Rapor sorguları `createTime` + `from_location_id` üzerinden yaygın; büyük hacimde index adayı.

## Sektör Notu

Yedek parça: merkez depo → şube mağaza transferi yaygın senaryo. Raf sayımı + fire düşüşü ile StockLevel farkı oluştuğunda düzeltme için **StockCount** kullanılır (ayrı flow).

## Tuzaklar

- `fromLocationType == toLocationType` olabilir (Store→Store veya WH→WH) — iş mantığı bunu yasaklamıyor
- Aynı lokasyon kendine transfer açıkça engellenmemiş (ör. `from=STORE-01, to=STORE-01`) — uygulama katmanı guard etmeli
- Transfer iptal endpoint'i YOK — yanlış transfer için ters transfer manuel girilmeli

## Sources

- `pos-product-manager/src/main/java/com/sedcore/inventory/entity/StockTransfer.java`
- `pos-product-manager/src/main/java/com/sedcore/inventory/service/impl/StockTransferServiceIntegrated.java`

## Related

- [[entities/stock-movement]]
- [[entities/stock-level]]
- [[entities/store]]
- [[entities/warehouse]]
- [[syntheses/flow-stock-transfer]]
