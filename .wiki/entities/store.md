---
title: Store — Mağaza (Lokasyon Master)
type: entity
source: .claude/wiki/entities/store.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Store

## Amaç

Fiziksel mağaza kaydı — satışın yapıldığı lokasyon. POS kasasındaki kasiyer JWT'sinde bulunan `storeId` (veya `locationId`) bu tablodaki `Store.code` değerine karşılık gelir.

## Alanlar

| Alan | Tip | Anlam |
|---|---|---|
| `code` | String(50), **unique** | `STORE-01` gibi dışa referans anahtarı |
| `name` | String(200), NOT NULL | Mağaza adı |
| `address` | TEXT | Açık adres |
| `phone` | String(20) | Telefon |
| `isActive` | Boolean | Soft delete (zorunlu — fiziksel silme yasak) |

## Kullanım Noktaları

`Store.code` **plain String** olarak diğer tablolarda saklanır (FK değil):

| Tablo | Alan | Not |
|---|---|---|
| [[entities/sale]] | `locationId` + `locationType=STORE` | Kasiyer JWT'den gelir |
| [[entities/purchase]] | `storeId` | Batch entry'de zorunlu kural |
| [[entities/stock-movement]] | `locationId` + `locationType=STORE` | Her stok hareketi |
| [[entities/stock-level]] | `locationId` | Variant × location unique |
| [[entities/warehouse]] | `storeCode` | Bir deponun hangi mağazaya bağlı olduğu |
| [[entities/stock-transfer]] | `fromLocationId` / `toLocationId` | Transfer uçları |

**Neden FK değil?** Legacy + JOIN kaçınma performans tercihi. Trade-off: silinen mağaza kodu orphan bırakır (bu yüzden soft delete zorunlu).

## İndeksler

```sql
uk_store_code (store_code)      -- unique
idx_store_code (store_code)     -- arama
```

`code` unique olduğu için tek tenant'ta `STORE-01` bir kere. Multi-tenant'ta `company_code + store_code` unique compound — `TOpenSimpleCompanyEntity` base filter ile doğal izolasyon (bkz. CLAUDE.md "unique constraint compound").

## Store vs Warehouse

Her ikisi de lokasyon master. Fark:
- **Store** = satış noktası (müşteri girer, kasa vardır)
- **Warehouse** = stok barındıran iç depo (`storeCode` ile bir mağazaya bağlanabilir)

`locationType` ayrımı tüm stok/satış tablolarında: `STORE` veya `WAREHOUSE`.

## Tuzaklar

- **Store silme yasak** (CLAUDE.md prod-ready kural #5): `isActive=false` set edilir; fiziksel delete stock movement orphan yapar
- `storeId` alanı artık **kaldırılmış** — onun yerine `locationId` + `locationType` ikilisi (ADR 2026-04-13)
- ProductVariant × Store eşleşmesi yok — stok `StockLevel(variantId, locationId)` üzerinden

## Sources

- `pos-product-manager/src/main/java/com/sedcore/inventory/entity/Store.java`
- `.claude/decisions/2026-04-13-location-id-unification.md` (locationId + locationType birleşimi)

## Related

- [[entities/warehouse]]
- [[entities/stock-level]]
- [[entities/stock-movement]]
- [[entities/sale]]
- [[entities/purchase]]
