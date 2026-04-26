---
title: DB-Side Aggregate (Java Loop Değil)
type: decision
source: .claude/wiki/decisions/db-side-aggregate-over-java-loop.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
status: active
---

# DB-Side Aggregate (Java Loop Değil)

## Karar
AccountsHub özet kartları (`totalCustomerReceivable`, `totalSupplierPayable`, `totalOverdueAmount`) için backend **JPQL aggregate** kullanır. Entity listesi fetch edip Java'da `.stream().map().sum()` yapma yasak.

## Neden
- N satır için SUM DB'de O(1) network round-trip
- Java loop → tüm entity'ler heap'e geliyor, GC baskı
- `AccountTransaction` ledger binlerce satır olabilir — aggregate olmadan liste endpoint yavaşlar
- PostgreSQL `SUM` index-backed → çok hızlı

## Örnekler
```java
@Query("SELECT new ...SummaryDto(" +
       "COALESCE(SUM(CASE WHEN t.customer IS NOT NULL THEN t.debitAmount - t.creditAmount ELSE 0 END), 0), " +
       "...) " +
       "FROM AccountTransaction t WHERE t.isCancelled = false")
SummaryDto getSummary();
```

## İstisna
- Running balance hesaplaması (ekstre ekranı) — sıralı cumulative; SQL window function alternatif ama Java loop daha okunaklı ve burada N küçük

## Related
- [[entities/account-transaction]]
- [[syntheses/flow-accounts-hub-load]]
- [[sources/code-refs/2026-04-22-accounts-hub-perf]]
