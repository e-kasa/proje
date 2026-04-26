---
title: Write-Through Cache (detailed merge from .claude/wiki/)
type: concept
source: .claude/wiki/concepts/write-through-cache.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
note: "MERGE_NEEDED — .wiki/concepts/write-through-cache.md is a stub; this verified version has write-through vs write-behind comparison + drift causes."
---

# Write-Through Cache

## Tanım
Yazım anında hem source of truth (ledger) hem de cache (denormalize entity) aynı transaction içinde güncellenir.

## SEDCORE Uygulaması

```
SaleService.checkout()
  ├─ AccountTransactionService.record(sale, debit) ← ledger
  └─ CustomerAccountService.applyDebit(customer, amount) ← cache
  (aynı @Transactional bloğu)
```

## Write-Through vs Write-Behind

| Write-Through | Write-Behind |
|---|---|
| Senkron, aynı transaction | Async queue, gecikmeli |
| Tutarlılık güçlü | Performance daha iyi |
| Commit fail → her ikisi rollback | Commit fail → cache kaybı riski |

SEDCORE write-through kullanır — tutarlılık önceliği.

## Neden Drift Yine Mümkün

Write-through aynı transaction içinde olsa bile:
- `@Version` her iki tarafta — concurrent write'larda anlık koruma sağlanır ama kümülatif drift hala mümkün
- Test/seed kod ledger'a yazıp cache adımını atlayabilir
- Manual SQL müdahalesi transaction dışı

Bu yüzden periyodik [[syntheses/flow-drift-reconciliation]] gerekir.

## Sources

- [[sources/code-refs/2026-04-24-drift-reconcile]]

## Related

- [[concepts/ledger-vs-denormalize]]
- [[concepts/drift]]
- [[concepts/pattern-denormalization-with-reconcile]]
- [[concepts/optimistic-lock-version]]
