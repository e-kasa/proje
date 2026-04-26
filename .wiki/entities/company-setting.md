---
title: CompanySetting — firma profil ve sektör tipi
type: entity
source: pos-product-manager/src/main/java/com/sedcore/company/entity/CompanySetting.java
ingested: 2026-04-25
last-verified: 2026-04-25
status: stub
---

# CompanySetting

## Tanım

Firma profil/ayar entity'si — başlangıçta sektör (`sectorType`) burada set edilir ve **sonradan değiştirilmez** (production-ready kural #1). Fatura/yazıcı bilgisi de bu kayıtta.

## Kod Konumu

- `pos-product-manager/src/main/java/com/sedcore/company/entity/CompanySetting.java:11`

## Alanlar

| Alan | Tip | Açıklama |
|---|---|---|
| `companyName` | varchar(200) | |
| `taxNumber` | string | VKN/TCKN |
| `taxOffice` | string | Vergi dairesi |
| `phone` | string | |
| `email` | string | |
| `address` | TEXT | |
| `city` | string | |
| `country` | string default "Türkiye" | |
| `website` | string | |
| `logoUrl` | string | |
| `currency` | string default "TRY" | |
| `sectorType` | varchar(50) | `autoParts` / `general` / `technology` / `footwear` |

## Kritik Kurallar (Production-Ready)

1. **1 firma = 1 sektör** — `sectorType` kurulumda set edilir, sonra değişmez.
2. **Ürün sektörü otomatik firmadan** — `ProductServiceImpl.createProduct()` `sectorType`'ı CompanySetting'ten override eder. UI'dan gönderilen sectorType yok sayılır.

## Kullanım

- POS UI: yedek parça için araç uyumluluğu, footwear için beden, technology için garanti gibi sektör-bağımlı widget'lar bu alana bakar.
- Backend `[[concepts/sector-strings]]` map'i bu alandaki değer üzerinden çalışır.

## Related

- [[concepts/sector-strings]]
- [[concepts/sector-agnostic]]
- [[entities/pos-product-manager]]
- [[syntheses/sector-agnostic-architecture]]
