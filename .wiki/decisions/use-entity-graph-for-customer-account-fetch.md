---
title: Customer/Supplier Account Fetch için @EntityGraph
type: decision
source: .claude/wiki/decisions/use-entity-graph-for-customer-account-fetch.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
status: active
---

# Customer/Supplier Account Fetch için @EntityGraph

## Karar
`Customer.account` ve `Supplier.account` LAZY ilişkilerini liste endpoint'lerinde fetch etmek için repository metodu üzerine `@EntityGraph(attributePaths = "account")`.

## Neden
- `@OneToOne(fetch = LAZY)` → default davranış: her row için ayrı query ([[issues/n-plus-one-customer-account-fetch]])
- `FetchType.EAGER` entity-level → her sorguda JOIN, istenmeyen yerde de — kötü
- `@EntityGraph` sadece ilgili sorguda JOIN ekler — noktasal kontrol
- DTO projection alternatifi daha kontrollü ama her field rename refactor gerektirir

## Alternatif Değerlendirildi
- **JOIN FETCH JPQL** — aynı etki, syntax daha açık ama @Query annotation içinde
- **@NamedEntityGraph** — entity üzerinde tanımlı, birden fazla sorguda tekrar kullanılabilir; SEDCORE'da tek sorgu yeterli

## Related
- [[concepts/pattern-entity-graph-n-plus-one]]
- [[issues/n-plus-one-customer-account-fetch]]
