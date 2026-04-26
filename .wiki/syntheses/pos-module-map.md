---
title: POS Modül Haritası — Üst Düzey
tags: [synthesis, architecture, modules]
date: 2026-04-25
status: draft
covers:
  - "[[entities/api-manager]]"
  - "[[entities/security]]"
  - "[[entities/pos-product-manager]]"
  - "[[entities/core]]"
  - "[[entities/project-pos]]"
  - "[[entities/template]]"
---

# POS Modül Haritası

SEDCORE POS üst seviyede 3 backend servis + 2 client'tan oluşur. Tüm modüller çok kiracılı ([[concepts/multi-tenant]]) ve sektör-agnostik ([[concepts/sector-agnostic]]) çalışır.

## Backend Servisleri

| Servis | Port | Rol |
|---|---|---|
| [[entities/api-manager]] | 8080 | Gateway — tek giriş, route + JWT doğrulama |
| [[entities/security]] | 8002 | Auth — login, kullanıcı, rol, i18n |
| [[entities/pos-product-manager]] | 8001 | Domain — satış, satın alma, stok, cari, raporlar |
| [[entities/core]] | — | Shared lib (base entity, filter, exception) |

## İstemciler

| Client | Teknoloji | Hedef |
|---|---|---|
| [[entities/project-pos]] | Flutter | Kasiyer + depo + mobil admin |
| [[entities/template]] | React | Web yönetici panel |

## Domain Modülleri (pos-product-manager İçinde)

- **Satış**: [[entities/sale]], [[entities/sale-item]], [[entities/sale-service-integrated]] — [[sources/code-refs/2026-04-25-sale-checkout-flow]]
- **Satın Alma**: [[entities/purchase]], [[entities/supplier-claim]], [[entities/purchase-service-impl]] — [[sources/code-refs/2026-04-25-purchase-checkout-flow]]
- **Stok**: [[entities/stock-level]], [[entities/stock-movement]]
- **Cari**: [[entities/customer]], [[entities/customer-account]], [[entities/supplier]], [[entities/supplier-account]], [[entities/account-transaction]], [[entities/reconcile-audit-log]] — [[syntheses/accounts-module-overview]]
- **Scheduled**: [[entities/reconcile-scheduled-job]], [[entities/slack-notifier]]

## Ortak Altyapı

- **DB**: PostgreSQL (ekalem db)
- **Auth**: JWT ([[concepts/jwt-auth]])
- **i18n**: security `message_definitions` ([[concepts/i18n]])
- **DDL**: create (dev — [[decisions/ddl-create-dev-strategy]])

## Sources

- [[sources/code-refs/2026-04-25-project-root-claude]]

## Related

- [[syntheses/sector-agnostic-architecture]]
- [[syntheses/accounts-module-overview]]
- [[syntheses/integration-catalog]]
