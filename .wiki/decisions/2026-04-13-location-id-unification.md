---
title: ADR — Lokasyon: storeId + warehouseId → locationId + locationType
type: decision
source: .claude/decisions/2026-04-13-location-id-unification.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# ADR — Lokasyon: storeId + warehouseId → locationId + locationType

**Tarih:** 2026-04-13  
**Durum:** Kabul edildi

## Karar

Eski ikili alan kaldırıldı. Tüm stok lokasyonları tek alanla temsil edilir:

```dart
'locationId':   'STORE-01'        // Store.code veya Warehouse.code
'locationType': 'STORE'           // 'STORE' | 'WAREHOUSE'
```

## Etkilenen Alanlar

| Alan | Eski | Yeni |
|------|------|------|
| initialStocks payload | `storeId + warehouseId` | `locationId + locationType` |
| BatchCreateRequest | `storeId + warehouseId` | `locationId + locationType` |
| PurchaseRequest | `storeId + warehouseId` | `locationId + locationType` |
| SaleRequest | `storeId` | `locationId + locationType` |
| InventoryResponse | `storeId + warehouseId` | `locationId + locationType` |
| PosState | `activeStoreId + availableStoreIds` | `activeLocationId + availableLocationIds` |
| BatchEntryState | `storeId + warehouseId` | `locationId + locationType` |

## KARIŞTIRMA — User.storeId Farklı

```dart
// user.storeId → kasiyerin atandığı mağaza (JWT'den, DEĞİŞMEDİ)
final jwtStoreId = ref.read(authProvider).user?.storeId;

// stock locationId → stok hareketi yapılan lokasyon (yeni)
'locationId': state.activeLocationId
```

## Unified Dropdown — Store + Warehouse

```dart
final combined = [
  ...stores.map((s) => {'code': s['code'], 'name': s['name'], 'type': 'STORE'}),
  ...warehouses.map((w) => {'code': w['code'], 'name': w['name'], 'type': 'WAREHOUSE'}),
];
```
