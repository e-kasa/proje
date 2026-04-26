---
title: CompanyContext — multi-tenant ThreadLocal taşıyıcı
type: concept
source: pos-product-manager/src/main/java/com/sedcore/common/context/CompanyContext.java
ingested: 2026-04-25
last-verified: 2026-04-25
status: stub
---

# CompanyContext

## Tanım

Thread-local taşıyıcı — Gateway'den gelen `X-Company-Code` header'ı tüm katmanlara yayar. **Multi-tenant filtrelemenin kalbi** — Hibernate `@Filter("filterCompany")` parametresi buradan okur.

## Kod Konumu

- `pos-product-manager/src/main/java/com/sedcore/common/context/CompanyContext.java:12`
- Filter: `pos-product-manager/src/main/java/com/sedcore/common/filter/CompanyContextFilter.java:29`

## API

```java
CompanyContext.set(String companyCode);
String code = CompanyContext.get();
boolean has = CompanyContext.hasCompany();
CompanyContext.clear();
```

## Davranış

- `CompanyContextFilter` `@Order(Ordered.HIGHEST_PRECEDENCE + 1)` ile **JwtXUserInfoFilter'dan önce** çalışır.
- `try { ... } finally { CompanyContext.clear(); }` — thread pool leak önlemi (virtual thread reuse).
- Public endpoint'lerde de çalışır (header varsa); JWT olmadan da `X-Company-Code` set edilebilir.
- Hibernate session açılırken `@Filter` parametresi olarak `companyCode` set edilir → `BaseRepository`/Service tüm sorgulara `WHERE company_code = ?` ekler.

## Kullanım

- Tüm controller endpoint'leri — controller `@RequestHeader("X-Company-Code")` **yazma** (root CLAUDE.md kural).
- Service katmanı: `CompanyContext.get()` ile companyCode alır, gerekiyorsa `entity.setCompanyCode(...)` öncesinde kullanır.

## Related

- [[concepts/multi-tenant]]
- [[concepts/multi-tenant-routing]]
- [[concepts/jwt-auth]]
- [[entities/api-manager]] — gateway header injection
