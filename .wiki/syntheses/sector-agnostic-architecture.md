---
title: Sektör-Agnostik POS Mimarisi
tags: [synthesis, architecture, sector, multi-tenant]
date: 2026-04-25
status: draft
covers:
  - "[[concepts/sector-agnostic]]"
  - "[[concepts/multi-tenant]]"
  - "[[concepts/prod-ready-guards]]"
---

# Sektör-Agnostik POS Mimarisi

SEDCORE POS tek kod tabanıyla **birden fazla sektöre** hizmet eder: market, giyim, yedek parça, teknoloji, ayakkabı, vb. Fark konfigürasyonla açılır; çekirdek iş mantığı ortak.

## Sektör Kodu

`CompanySetting.sectorType` enum — 4 değer: `autoParts`, `general`, `technology`, `footwear`. Kurulumda set edilir, sonra **değişmez** (prod-ready kural — [[concepts/prod-ready-guards]]).

## Çekirdek vs Sektör-Özel

| Katman | İçerik | Örnek |
|---|---|---|
| **Çekirdek** | Sektör bağımsız | Stok, satış, cari, satın alma, raporlar |
| **Sektör-Özel** | Yan eklenti | Yedek parça için araç uyumu + plaka; giyim için beden/renk; ayakkabı için numara |

## Multi-Tenant İzolasyon

Her tenant ([[concepts/multi-tenant]]) kendi veri alanında:
- Hibernate `@Filter` otomatik `company_code` filtresi
- JWT'den `CompanyContext` thread-local set
- Unique constraint'ler compound `(company_code, X)`
- Scheduled thread'de manuel iteration ([[entities/reconcile-scheduled-job]])

## Entegrasyonlar (Kanal Bazlı, Sektör Bağımsız)

Sektör ne olursa olsun aynı entegrasyonlar devreye girebilir:
- e-Fatura / e-Arşiv
- Pazaryeri (Trendyol, Hepsiburada, N11...)
- Kargo firmaları
- Banka POS / ödeme gateway
- WhatsApp / SMS / Email bildirim
- Muhasebe programı export

Detay: [[syntheses/integration-catalog]].

## Sources

- [[sources/code-refs/2026-04-25-project-root-claude]]

## Related

- [[syntheses/pos-module-map]]
- [[concepts/sector-agnostic]]
- [[concepts/multi-tenant]]
