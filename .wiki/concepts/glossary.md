---
title: Glossary (Terim Sözlüğü)
type: concept
source: .claude/wiki/glossary.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Glossary

SEDCORE POS bağlamında tekrarlayan terimler. Kısa tanım + kaynak link.

> Terim eklerken: ilk tanımı kısa tut (1-2 cümle), gerekiyorsa wiki sayfasına link ver.

## A

- **AccountTransaction** — Ledger kaydı (source of truth). Müşteri/tedarikçi bakiyesinin gerçek hareketi. Bkz. [[entities/account-transaction]]
- **ADR (Architecture Decision Record)** — Mimari karar dosyası, `.claude/decisions/` altında tarihli.

## C

- **companyCode** — Multi-tenant izolasyon anahtarı. JWT'den gelir, controller'da header olarak okunmaz. Bkz. `reference/multi-tenant.md`
- **CustomerAccount** — Müşteri bakiye agregasyonu (denormalize). `@Version` optimistic lock.

## D

- **Denormalization** — Ledger'dan türetilmiş özet alanların (`current_balance`, `total_debt`, ...) entity'de tutulması. Drift riski için [[syntheses/flow-drift-reconciliation]]
- **Drift** — Denormalize alan ile ledger gerçeği arasındaki sapma.

## L

- **Ledger** — Tüm hareketlerin append-only kaydı. SEDCORE'da `account_transactions` tablosu.
- **locationType / locationId** — Stok lokasyon referansı; `storeId`/`warehouseId` yerine birleştirilmiş model. ADR: `decisions/2026-04-13-location-id-unification.md`

## M

- **MOC (Map of Content)** — Obsidian terimi; wiki giriş sayfası. Bu wiki'de [[index]]

## R

- **Reconcile** — Denormalize alanları ledger'dan yeniden hesaplayıp senkronize etme işlemi.

## S

- **sectorType** — Firma sektör enum'u (`autoParts` / `general` / `technology` / `footwear`). `CompanySetting`'de kurulumda set, değişmez. Bkz. `reference/sector-strings.md`
- **Soft delete** — `is_deleted=true` ile pasifleştirme. Fiziksel delete yasak. Unique constraint'ler compound `(company_code, X)` olduğu için re-insert çakışır — dikkat.

## T

- **Tenant** — Kiracı = firma. `company_code` ile izole.
- **TOpenSimpleCompanyEntity** — companyCode + @FilterDef "filterCompany" otomatik ekleyen base class. `core` modülünde.

## V

- **@Version** — Hibernate optimistic lock anotasyonu. SEDCORE'da `CustomerAccount`, `SupplierAccount`, `StockLevel` üzerinde var; `AccountTransaction` üzerinde **yok** (append-only).
