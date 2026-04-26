---
title: Flow — Batch Entry
type: synthesis
source: .claude/wiki/flows/batch-entry.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Batch Entry Flow

## Amaç
Toplu ürün/varyant/fiyat/barkod girişi — tek submit ile birden çok ürün+varyant sisteme eklenir.

## 4-Area UX (2026-04-23 revizyonu)

```
┌─────────────────────────────────────┐
│ HEADER — supplier, invoice, category │  ← BatchEntryState.categoryId
├─────────────────────────────────────┤
│ BARCODE SEARCH INPUT                │  ← multi-match → picker sheet
├─────────────────────────────────────┤
│ VARIANT LIST (eklenenler)           │  ← fiyat + stok + barkod
├─────────────────────────────────────┤
│ SUBMIT (toplu kaydet)               │  ← validation + POST
└─────────────────────────────────────┘
```

## Call Chain (submit)

```
BatchProductScreen.submit()
  → batchEntryProvider.submitAll()
    → validate state (invoice, supplier, items.length > 0)
    → POST /product/api/v1/purchases (header + items)
      → PurchaseService → Stock + StockMovement + AccountTransaction
    → POST /product/api/v1/payments (opsiyonel peşin ödeme)
    → reset state
```

## State Yönetimi

`batch_entry_provider.dart` (882 satır) — StateNotifier, `BatchEntryState` immutable:
- `headerState` — supplier, invoice, date, **categoryId**, **categoryName**, **headerCollapsed**
- `items` — eklenen variant listesi
- `submitStatus` — idle/loading/success/error

## Tuzaklar

- State'te `categoryId` 2026-04-23'te eklendi — eski kod `updateHeader(categoryId:)` kırılır (bkz. [[issues/batch-entry-provider-truncated]])
- Submit sırasında `storeId` **zorunlu** (prod-ready kural)
- Paralel barkod arama race condition — debounce uygulanmış

## Sources

- [[sources/code-refs/2026-04-23-batch-entry-4area]]
- project_pos/lib/features/inventory/screens/batch_entry/providers/batch_entry_provider.dart

## Related

- [[concepts/pattern-base-entity-list-screen]]
- [[issues/batch-entry-provider-truncated]]
- [[syntheses/flow-purchase-checkout]]
