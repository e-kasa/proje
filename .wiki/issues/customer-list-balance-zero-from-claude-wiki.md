---
title: Müşteri Liste Bakiyesi Her Zaman 0 TL (detailed merge from .claude/wiki/)
type: issue
source: .claude/wiki/issues/customer-list-balance-zero.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
status: resolved
note: "MERGE_NEEDED — .wiki/issues/customer-list-balance-zero.md is brief; this resolved version has full toMap code snippet + EntityGraph note."
---

# Müşteri Liste Bakiyesi Her Zaman 0 TL

## Belirti
AccountsHub müşteri liste panelinde her satırda bakiye = 0 TL, gerçek değer DB'de olsa bile.

## Kök Neden
`CustomerControllerImpl.toMap(Customer)` metodu yalnızca master kayıt alanlarını (`id`, `name`, `phone`, `creditLimit`) set ediyordu. Denormalize `currentBalance` ([[entities/customer-account]]'tan gelen) **çıktıda yoktu**. Client `c['currentBalance']` okuyordu → null → `?? 0` → 0 TL.

## Fix
`toMap()`'e `CustomerAccount` ilişkisinden gelen 4 alan eklendi:
```java
var acct = c.getAccount();
m.put("currentBalance", acct != null ? acct.getCurrentBalance() : BigDecimal.ZERO);
m.put("overdueAmount", ...);
m.put("availableCreditLimit", ...);
m.put("isCreditLimitExceeded", ...);
```

Ek olarak `CustomerRepository.search()` üzerine `@EntityGraph(attributePaths = "account")` — aksi halde her row için ayrı query (N+1, bkz. [[issues/n-plus-one-customer-account-fetch]]).

## İlgili Dosyalar
- pos-product-manager/src/main/java/com/sedcore/customer/controller/impl/CustomerControllerImpl.java
- pos-product-manager/src/main/java/com/sedcore/customer/repository/CustomerRepository.java

## Öğrenilen
[[concepts/pattern-dto-tomap-pattern]] esnek ama alan eklemek açık refactor gerektirir — compiler uyarmaz, client sessizce 0 okur. Kod review checklist'te "yeni entity alanı eklendiyse toMap güncellendi mi?" maddesi olmalı.

## Related
- [[entities/customer]]
- [[entities/customer-account]]
- [[concepts/pattern-dto-tomap-pattern]]
- [[concepts/pattern-entity-graph-n-plus-one]]
- [[sources/code-refs/2026-04-22-accounts-hub-perf]]
