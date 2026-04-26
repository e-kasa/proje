---
title: Ledger vs Denormalize (detailed merge from .claude/wiki/)
type: concept
source: .claude/wiki/concepts/ledger-vs-denormalize.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
note: "MERGE_NEEDED — .wiki/concepts/ledger-vs-denormalize.md is brief; this verified version has comparison table + SEDCORE mapping."
---

# Ledger vs Denormalize

## Temel Ayrım

| Ledger | Denormalize |
|---|---|
| Source of truth | Cache / özet |
| Append-only | Write-through update |
| Tüm hareketler (satır düzeyi) | Toplamlar (entity düzeyi) |
| Okuma yavaş (SUM gerekir) | Okuma hızlı (tek row) |
| @Version VAR (defense-in-depth) | @Version VAR |

## SEDCORE'da

- **Ledger**: [[entities/account-transaction]] — customer/supplier id + debit/credit/cancelled
- **Denormalize**: [[entities/customer-account]], [[entities/supplier-account]] — currentBalance, totalDebt, totalCredit

## Neden İki Katman?

- Ledger olmadan → tarihsel audit yok, iptal yapılamaz
- Denormalize olmadan → her liste ekranı SUM query yapar, yavaş
- İkisi birlikte → hızlı okuma + tam history

## Risk: Drift

İki katman senkron tutulmalı; olmazsa → [[concepts/drift]]

## Sources

- Proje mimari gözlemi
- [[sources/code-refs/2026-04-24-drift-reconcile]]

## Related

- [[concepts/drift]]
- [[concepts/write-through-cache]]
- [[concepts/pattern-denormalization-with-reconcile]]
- [[entities/account-transaction]]
- [[entities/customer-account]]
