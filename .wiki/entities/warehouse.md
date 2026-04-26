---
title: Warehouse — Depo (Lokasyon Master)
type: entity
source: .claude/wiki/entities/warehouse.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Warehouse

## Amaç

İç depo kaydı — stok barındıran, satışın yapılmadığı lokasyon. Bir [[entities/store]]'a bağlı olabilir (`storeCode` alanı).

## Alanlar

| Alan | Tip | Anlam |
|---|---|---|
| `code` | String(50), **unique** | `WH-01` gibi dışa referans anahtarı |
| `name` | String(200), NOT NULL | Depo adı |
| `storeCode` | String(50), nullable | Bağlı olduğu mağaza (ör. merkez depo → STORE-01) |
| `address` | TEXT | Adres |
| `isActive` | Boolean | Soft delete |

## Kullanım Noktaları

`Warehouse.code` **plain String** olarak (Store ile aynı desen):

| Tablo | Alan | Not |
|---|---|---|
| [[entities/stock-movement]] | `locationId` + `locationType=WAREHOUSE` | |
| [[entities/stock-level]] | `locationId` | |
| [[entities/stock-transfer]] | `fromLocationId` / `toLocationId` | Transfer uçları — Warehouse→Store veya tam tersi |

**Kasada satış YAPILMAZ** — Sale.locationType = `WAREHOUSE` mantıken mümkün ama iş kuralı kasa mağazada çalışır. Flutter POS tarafı bu ayrımı bilir.

## İndeksler

```sql
uk_warehouse_code (warehouse_code)
idx_warehouse_code (warehouse_code)
```

## Warehouse → Store Hiyerarşisi (opsiyonel)

`Warehouse.storeCode` ile depo bir mağazanın altında gruplanabilir. Örnek:
- `STORE-01` (İstanbul Merkez Mağaza)
  - `WH-01` (İstanbul merkez depo — `storeCode = STORE-01`)
  - `WH-02` (Yan bina ek depo)
- `STORE-02` (Ankara Mağaza)
  - `WH-03` (Ankara depo)

Bu ilişki **zorunlu değil** — bağımsız depo da kayıt edilebilir (storeCode = null).

## Tuzaklar

- `storeCode` nullable → bağımsız depolar çıkabilir; rapor filtrelerinde dikkat
- Depo silme yasak (Store ile aynı kural)
- Transfer endpoint'i WAREHOUSE → STORE veya STORE → STORE arasında çalışır; tip kontrolü yapılmaz (mantıksal olarak her iki yön mümkün)

## Sources

- `pos-product-manager/src/main/java/com/sedcore/inventory/entity/Warehouse.java`
- `pos-product-manager/src/main/java/com/sedcore/inventory/service/impl/WarehouseServiceImpl.java`

## Related

- [[entities/store]]
- [[entities/stock-level]]
- [[entities/stock-transfer]]
- [[syntheses/flow-stock-transfer]]
