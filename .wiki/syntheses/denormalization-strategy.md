---
title: Denormalizasyon Stratejisi — Proje Geneli
type: synthesis
source: .claude/wiki/syntheses/denormalization-strategy.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Denormalizasyon Stratejisi — Proje Geneli

SEDCORE POS'ta "append-only ledger + denormalize özet + reconcile" pattern'inin kullanıldığı tüm yerler ve ortak prensipler.

## Prensipler

1. **Ledger source of truth** — [[decisions/ledger-as-source-of-truth]]
2. **Write-through cache** — [[concepts/write-through-cache]]
3. **@Version opt-lock** — sadece denormalize katmanda, ledger append-only
4. **Reconcile idempotent** — [[decisions/idempotent-reconcile-no-op-guard]]
5. **Manuel tetik ilk fazda** — scheduled'a geçmeden önce gözlem ([[decisions/manual-reconcile-before-scheduled]])

## Uygulama Alanları

### Tamamlandı — Accounts
- Ledger: [[entities/account-transaction]]
- Cache: [[entities/customer-account]], [[entities/supplier-account]]
- Reconcile: [[syntheses/flow-drift-reconciliation]]
- Admin endpoint var, manuel çalışıyor

### Kısmi — Inventory
- Ledger: StockMovement (append-only)
- Cache: StockLevel (denormalize quantity)
- Reconcile: **YOK** — drift tespit edilirse manuel SQL gerek
- Gelecek sprint: `StockLevel.reconcile()` endpoint

### Henüz Yok — Reports
- Sales aggregate'ler her query'de JPQL SUM (denormalize yok)
- Yüksek hacimde materialized view düşünülmeli

## Risk Yönetimi

[[concepts/drift]] her denormalize katmanın doğal riski. Tespit + düzeltme stratejisi:

| Katman | Tespit | Düzeltme |
|---|---|---|
| CustomerAccount | Ledger diff query | `/admin/accounts/reconcile/customer/{id}` |
| SupplierAccount | Ledger diff query | `/admin/accounts/reconcile/supplier/{id}` |
| StockLevel | Movement sum vs StockLevel | Henüz yok |

## Ortak Pattern

- [[concepts/pattern-denormalization-with-reconcile]] — temel şablon
- [[concepts/optimistic-lock-version]] — @Version kullanımı
- [[concepts/pattern-dto-tomap-pattern]] — controller çıktı şekli

## Related

- [[syntheses/accounts-overview]]
- [[concepts/ledger-vs-denormalize]]
- [[concepts/drift]]
