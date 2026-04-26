---
title: Sektör-Agnostik Mimari
tags: [concept, architecture, configuration]
source: C:\Users\Win11\Documents\GitHub\proje\CLAUDE.md
date: 2026-04-25
status: draft
---

# Sektör-Agnostik Mimari

POS projesi tek bir kod tabanıyla birden fazla sektöre hizmet eder (market, giyim, yedek parça, teknoloji, ayakkabı, vb.). Sektöre özel davranışlar konfigürasyonla devreye girer.

## Prensip

- **Çekirdek modüller** (stok, cari, satış, satın alma, raporlar) sektör bağımsız
- **Sektör genişletmeleri** yan eklenti olarak belgelenir (örn. yedek parça için araç uyumu + plaka)
- **Sektör kodları**: `autoParts` / `general` / `technology` / `footwear` (`CompanySetting.sectorType`)
- **Kurulumda set, sonra değişmez** — tenant bir sektörle kurulur; runtime değişimi yok (prod-ready kuralı)

## Uygulama

- `CompanySetting.sectorType` enum
- `ProductServiceImpl.createProduct` otomatik firma sektörünü override eder (ürün sektörü=firma sektörü kuralı)

## Sources

- [[raw/code-refs/2026-04-25-project-root-claude]]

## Related

- [[concepts/multi-tenant]]
- [[syntheses/sector-agnostic-architecture]]
