---
title: ADR — DDL Stratejisi: `create` (dev)
type: decision
source: .claude/decisions/2026-04-13-ddl-create-strategy.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# ADR — DDL Stratejisi: `create` (dev)

**Tarih:** 2026-04-13  
**Durum:** Kabul edildi (dev)

## Karar

```properties
spring.jpa.hibernate.ddl-auto=create
```

Her startup'ta tüm tablolar DROP + CREATE. data.sql temiz INSERT'lerle çalışır.

## Alternatifler

| Mod | Sorun |
|-----|-------|
| `create-drop` | Sadece startup'ta CREATE, shutdown'da DROP. Crash sonrası eski data kalır → `ON CONFLICT` tuzakları tetiklenir. **KULLANMA.** |
| `update` | Yeni kolon ekler ama eski data kalır — dev'de seed çakışır. Production için uygun. |

## Sonuç

- Dev: `create` — clean slate her startup.
- Prod: `update` (ileride).
- data.sql'de `ALTER TABLE` **yazma** — Hibernate schema'yı yönetir.
