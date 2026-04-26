---
title: ADR — Rol Kodu: STORE_MANAGER → STORE_ADMIN
type: decision
source: .claude/decisions/2026-04-13-store-admin-rename.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# ADR — Rol Kodu: STORE_MANAGER → STORE_ADMIN

**Tarih:** 2026-04-13  
**Durum:** Kabul edildi

## Karar

Mağaza yönetici rolü için standart kod **`STORE_ADMIN`**.  
`STORE_MANAGER` backward compat olarak tutuldu, `data.sql` sonu migrasyonla otomatik dönüştürülür:

```sql
UPDATE user_role SET role_def_id = 'STORE_ADMIN'
WHERE role_def_id = 'STORE_MANAGER';
```

## Rol Kodu Standardı

| Kod | Açıklama | is_system_role |
|-----|---------|---------------|
| `ADMIN` | Firma yöneticisi | true |
| `STORE_ADMIN` | Mağaza yöneticisi (**standart**) | true |
| `CASHIER` | Kasiyer | false |
| `WAREHOUSE` | Depo sorumlusu | false |
| `SUPER_ADMIN` | Platform geneli | true |

## Sebep

`STORE_MANAGER` isminin anlamı belirsizdi — "mağazadaki yönetici" mi yoksa "mağaza yönetim yetkisi" mi? `STORE_ADMIN` ADMIN hiyerarşisine daha iyi uyar.
