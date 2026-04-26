---
title: Pattern — toMap (Controller → Map<String,Object>)
type: concept
source: .claude/wiki/patterns/dto-tomap-pattern.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
status: deprecated-candidate
superseded-by: "[[concepts/pattern-openapi-codegen-flutter]]"
---

# toMap Pattern — DEPRECATED CANDIDATE (Sprint 4, 2026-04-24)

> **Not**: Sprint 4'te [[concepts/pattern-openapi-codegen-flutter]] infrastruktürü kuruldu. Yeni endpoint'lerde **typed DTO tercih edilir** — toMap pattern'ı tarihsel referans olarak tutulur; aşamalı olarak typed DTO'ya migrate edilir.

## Problem
Controller output için DTO class tanımlamak her alan değişiminde refactoring gerektirir; özellikle denormalize alanları (currentBalance, overdueAmount) entity'den çıkartırken.

## Çözüm
Controller içinde inline `toMap(entity)` metodu `Map<String, Object>` döner. Alan eklemek/çıkarmak tek satır.

```java
private Map<String, Object> toMap(Customer c) {
    Map<String, Object> m = new LinkedHashMap<>();
    m.put("id", c.getId());
    m.put("name", c.getName());
    m.put("creditLimit", c.getCreditLimit());

    // Denormalize alanları (account LAZY — @EntityGraph ile fetch edilmiş)
    var acct = c.getAccount();
    m.put("currentBalance", acct != null ? acct.getCurrentBalance() : BigDecimal.ZERO);
    m.put("overdueAmount", acct != null ? acct.getOverdueAmount() : BigDecimal.ZERO);
    m.put("availableCreditLimit", acct != null ? acct.getAvailableCreditLimit() : BigDecimal.ZERO);
    m.put("isCreditLimitExceeded", acct != null ? acct.getIsCreditLimitExceeded() : Boolean.FALSE);

    return m;
}
```

## SEDCORE'da Uygulanan Yerler

- `CustomerControllerImpl.toMap()`
- `SupplierControllerImpl.toMap()`
- Eski `ProductControllerImpl` (bazı endpoint'lerde)

## Trade-off

- Esneklik — alan eklemek tek satır
- Nested denormalize kolay — FK'dan doğrudan çıkar
- Null-safe fallback (ZERO / FALSE)
- Tip güvenliği yok — Flutter tarafında `c['currentBalance'] as num?` zorunlu
- OpenAPI dokümantasyon zayıf — Swagger `Map` görür, alan yapısını bilmez
- Refactoring riski — alan adı değişirse compiler uyarı vermez, client sessizce kırılır

## Tuzaklar

- Alan atlamak: "yeni alan eklendi ama toMap'e koyulmadı" → client null okur, 0 gösterir (bkz. [[issues/customer-list-balance-zero]])
- Alan rename: backend'de değişir, client'ta `['oldName']` kalırsa sessizce null (bkz. [[issues/supplier-list-balance-zero]])
- LAZY ilişkiler toMap çağrısında fetch edilmemişse `LazyInitializationException` — `@EntityGraph` veya `@Transactional(readOnly=true)` şart

## Alternatif

Typed DTO (Lombok @Data + @Builder). Stabil API'larda tercih edilir; dinamik alan gerektiren liste endpoint'lerinde toMap daha esnek.

## Sources

- [[sources/code-refs/2026-04-22-accounts-hub-perf]]
- pos-product-manager/src/main/java/com/sedcore/customer/controller/impl/CustomerControllerImpl.java

## Related

- [[concepts/pattern-openapi-codegen-flutter]] (successor — önerilen)
- [[concepts/pattern-entity-graph-n-plus-one]]
- [[entities/customer]]
- [[entities/supplier]]
- [[issues/customer-list-balance-zero]]
- [[issues/supplier-list-balance-zero]]
