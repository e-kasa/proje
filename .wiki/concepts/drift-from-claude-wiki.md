---
title: Drift (detailed merge from .claude/wiki/)
type: concept
source: .claude/wiki/concepts/drift.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
note: "MERGE_NEEDED — .wiki/concepts/drift.md is brief; this verified version has detection SQL + correction strategy detail."
---

# Drift

## Tanım
Denormalize özet alan (örn. `CustomerAccount.currentBalance`) ile ledger gerçeği (`SUM(AccountTransaction.debit - credit)`) arasındaki sapma.

## Nedenler

1. **Transaction commit fail** — servis exception'ı ledger yazıp denormalize update yapamadan
2. **Manuel SQL müdahalesi** — doğrudan DB'de `UPDATE customer_accounts ...`
3. **Concurrent race** — paralel sale + payment; `@Version` yalnız denormalize'da, ledger'da yok → ledger her iki insert'i yazar, denormalize sadece birini
4. **Code path atlama** — test veya seed data ledger'a yazıp denormalize güncellemeden
5. **İptal yanlış yapılması** — `isCancelled=true` set edildi ama denormalize'da geri alınmadı

## Tespit

```sql
SELECT c.id, c.name,
  ca.current_balance AS denorm,
  COALESCE(SUM(t.debit_amount - t.credit_amount), 0) AS ledger
FROM customer c
LEFT JOIN customer_accounts ca ON ca.customer_id = c.id
LEFT JOIN account_transactions t ON t.customer_id = c.id AND t.is_cancelled = false
GROUP BY c.id, c.name, ca.current_balance
HAVING ca.current_balance <> COALESCE(SUM(t.debit_amount - t.credit_amount), 0);
```

## Düzeltme

[[syntheses/flow-drift-reconciliation]] — ledger'dan yeniden hesapla, denormalize üstüne yaz.

Kural: **Ledger source of truth kabul edilir** — drift varsa denormalize düzeltilir, ledger'a dokunulmaz.

## Sources

- [[sources/code-refs/2026-04-24-drift-reconcile]]

## Related

- [[concepts/ledger-vs-denormalize]]
- [[syntheses/flow-drift-reconciliation]]
- [[concepts/pattern-denormalization-with-reconcile]]
- [[entities/account-transaction]]
- [[entities/customer-account]]
