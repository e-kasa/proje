---
title: POS Satış Oluşturma Akışı
tags: [source, sale, pos, checkout, ledger]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\flows\sale-checkout.md
raw: "[[raw/code-refs/2026-04-25-sale-checkout-flow]]"
date: 2026-04-25
status: draft
---

# Sale Checkout İngest Özeti

## Amaç

POS kasasında müşteriye satış yaparken stok düşüşü, cari hesap güncelleme ve ledger kaydını atomik bir şekilde yapmak. Drift kaynaklarından birinci zincir.

## Ne Yapıldı

7 adımlı `createSale` akışı `@Transactional` içinde: (1) saleNumber auto-gen, (2) kalem hesapla, (3) vadeli guard, (4) müşteri + credit limit check (override destekli), (5) Sale + SaleItem save, (6) StockLevel pessimistic decrement + StockMovement audit, (7) vadeli ise CustomerAccount update + AccountTransaction insert.

## Değişenler / Kapsam

- **Entity**: [[entities/sale]], [[entities/sale-item]], [[entities/customer]], [[entities/customer-account]], [[entities/account-transaction]], [[entities/stock-level]], [[entities/stock-movement]]
- **Service**: [[entities/sale-service-integrated]] (createSale + cancelSale + createSaleReturn)
- **Credit Limit**: Sprint 5 P2.5 override mekanizması — `SaleRequest.overrideCreditLimit` + rol check ([[decisions/credit-limit-override-role-based]])

## Alınan Kararlar

- [[decisions/credit-limit-override-role-based]] — ADMIN/STORE_ADMIN override, role-based (authority-based değil, pragmatik)
- [[decisions/stock-level-pessimistic-lock]] — deductStock PESSIMISTIC_WRITE lock (not @Version retry)
- [[decisions/credit-limit-override-role-based]] — vadeli satış müşteri zorunlu

## Karşılaşılan Sorunlar

- [[issues/credit-limit-not-enforced]] → resolved (Sprint 5 P2.5)
- [[issues/stock-concurrency-documented-wrong]] → resolved (deductStock pessimistic, eski dokümantasyon "@Version retry" diyordu)

## Açık Konular

- Concurrent iki setAccount hızlı → race (son kazanır) — nadir, şimdilik tolerans
- `@Async` yok — endpoint bloke (iyileştirme adayı)

## Sources

- `.claude/wiki/flows/sale-checkout.md`
- `pos-product-manager/src/main/java/com/sedcore/sales/service/impl/SaleServiceIntegrated.java`
- [[raw/code-refs/2026-04-25-sale-checkout-flow]]

## Related

- [[syntheses/accounts-module-overview]]
- [[concepts/drift]]
- [[concepts/optimistic-lock-version]]
- [[concepts/write-through-cache]]
