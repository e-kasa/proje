---
title: Idempotent Reconcile — No-Op Guard (detailed merge from .claude/wiki/)
type: decision
source: .claude/wiki/decisions/idempotent-reconcile-no-op-guard.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
status: active
note: "MERGE_NEEDED — overlap; this version has Java code snippet + reasoning detail."
---

# Idempotent Reconcile — No-Op Guard

## Karar
Reconcile metodunda drift yoksa `save()` **çağrılmaz**. Triple eşitlik kontrolü (balance + debt + credit) ile karar verilir.

```java
if (drift.compareTo(BigDecimal.ZERO) != 0
    || acct.getTotalDebt().compareTo(ledgerDebt) != 0
    || acct.getTotalCredit().compareTo(ledgerCredit) != 0) {
    // override + save
}
// else: NO-OP
```

## Neden
- `@Version` tick etmesin — gereksiz optimistic lock bump yok
- `updatedAt` timestamp bozulmasın — gerçek değişim zamanı korunur
- `reconcileAll()` 1000 hesaplık koleksiyonda 1000 save yerine 0-5 save → I/O düşük
- Idempotent çağrı güvenli — aynı endpoint 10 kez arka arkaya tetiklenebilir

## Related
- [[syntheses/flow-drift-reconciliation]]
- [[concepts/optimistic-lock-version]]
