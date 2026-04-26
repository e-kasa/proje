---
title: Proje Kökü CLAUDE.md — Mimari + Servisler
tags: [source, architecture, services, multi-tenant]
source: C:\Users\Win11\Documents\GitHub\proje\CLAUDE.md
raw: "[[raw/code-refs/2026-04-25-project-root-claude]]"
date: 2026-04-25
status: draft
---

# Proje Kökü CLAUDE.md İngest Özeti

## Amaç

SEDCORE POS projesinin üst düzey mimari ve operasyon kuralları belgesi. Geliştirme ortamı, servis iskeleti, domain özeti ve çalışma tarzı tek bir yerde.

## Ne Yapıldı

Proje kökündeki CLAUDE.md dosyası, mikroservis mimarisini, port ayrımlarını, build sırasını ve temel referansları özetler. Ayrıca sektör bağımsızlığı, multi-tenant izolasyon ve production-ready kuralları belgeler.

## Değişenler / Kapsam

- **Servisler**: [[entities/api-manager]] (gateway, :8080), [[entities/security]] (auth, :8002), [[entities/pos-product-manager]] (domain, :8001), [[entities/core]] (shared lib), [[entities/project-pos]] (Flutter), [[entities/template]] (React)
- **Ortak altyapı**: PostgreSQL (ekalem db), JWT token, Java 25 virtual threads, DDL=create (dev)
- **Domain özeti**: Company → UserDef → Role, Product → Variant → Pricing/Barcode/Vehicle, Purchase/Sale/Account tabloları
- **Roller**: ADMIN / STORE_ADMIN / CASHIER / WAREHOUSE / SUPER_ADMIN
- **Sektörler**: autoParts / general / technology / footwear

## Alınan Kararlar

- [[decisions/service-layer-separation]] — 3 servis (gateway + auth + domain)
- [[decisions/ddl-create-dev-strategy]] — dev'de `ddl-auto=create`, prod'da update planlı
- [[decisions/sedcore-role-taxonomy]] — STORE_ADMIN standardı (STORE_MANAGER deprecated)
- [[decisions/location-id-type-unified]] — `storeId`+`warehouseId` kaldırıldı, `locationId`+`locationType`

## Karşılaşılan Sorunlar

Yok (bu özet referans doküman; operasyonel sorunlar diğer source'larda).

## Açık Konular

- [[concepts/multi-tenant]] — Hibernate @Filter + PostgreSQL RLS geçişi (Sprint 3 planlı)
- [[concepts/i18n]] — i18n tablosu security'de, Flutter `i18nOf(ref)` pattern

## Sources

- `C:\Users\Win11\Documents\GitHub\proje\CLAUDE.md`
- [[raw/code-refs/2026-04-25-project-root-claude]]

## Related

- [[syntheses/pos-module-map]]
- [[syntheses/sector-agnostic-architecture]]
- [[concepts/multi-tenant]]
- [[concepts/jwt-auth]]
