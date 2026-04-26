---
title: Customer → Account LAZY Fetch N+1
type: issue
source: .claude/wiki/issues/n-plus-one-customer-account-fetch.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
status: resolved
---

# Customer → Account LAZY Fetch N+1

## Belirti
AccountsHub müşteri liste endpoint'i yavaştı — N satır için N adet ayrı `SELECT * FROM customer_accounts WHERE customer_id = ?` sorgusu. Hibernate SQL log'ta görünür.

## Kök Neden
`Customer.account` ilişkisi `@OneToOne(fetch = FetchType.LAZY)`. Controller `findAll()` sonrası `toMap` içinde `c.getAccount().getCurrentBalance()` çağrılıyor → Hibernate her row için LAZY fetch tetikler.

## Fix
`CustomerRepository.search()` üzerine:
```java
@EntityGraph(attributePaths = "account")
@Query(...)
List<Customer> search(...)
```

Tek SELECT + JOIN, N+1 kayboldu.

## Related
- [[concepts/pattern-entity-graph-n-plus-one]]
- [[entities/customer]]
- [[issues/customer-list-balance-zero]]
- [[sources/code-refs/2026-04-22-accounts-hub-perf]]
