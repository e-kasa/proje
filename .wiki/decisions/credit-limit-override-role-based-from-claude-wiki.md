---
title: Credit Limit Override — Role-Based (detailed merge from .claude/wiki/)
type: decision
source: .claude/wiki/decisions/credit-limit-override-role-based.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
status: accepted
note: "MERGE_NEEDED — overlap with .wiki/decisions/credit-limit-override-role-based.md. This version has full ADR context + when-to-revisit + code sample."
---

# Decision: Credit Limit Override — Role-Based

## Context

Plan `agile-noodling-crown.md` Sprint 5 P2.5 maddesi `CREDIT_LIMIT_OVERRIDE` authority istedi: STORE_ADMIN role'üne bu authority eklenip `@PreAuthorize("hasAuthority('CREDIT_LIMIT_OVERRIDE')")` ile override kontrolü.

Sorun: mevcut JWT filter (`JwtXUserInfoFilter`) authority'leri `Authentication` objesine **yüklemiyor** — sadece role bilgisi geliyor. Authority-based kontrol implement edilirse:
1. JWT payload schema genişletilmeli (authority claims)
2. `role_def` tablosuna ek `authorities` kolonu + seed migration
3. JwtXUserInfoFilter güncellenip authority parse etmeli

Bu 3 değişiklik çarpraz kesen + yan etki riski yüksek (tüm endpoint'ler etkilenir).

## Decision

**Role-based kontrol**: `SaleServiceIntegrated.currentUserHasCreditLimitOverride()` metodunda `ROLE_ADMIN` + `ROLE_STORE_ADMIN` kontrol et. İleride authority desteği eklenirse `CREDIT_LIMIT_OVERRIDE` string'i zaten matching'de dahil — kodsuz migration.

```java
boolean currentUserHasCreditLimitOverride() {
    auth = SecurityContextHolder...
    for each authority:
        if role in ["ROLE_ADMIN", "ROLE_STORE_ADMIN", "CREDIT_LIMIT_OVERRIDE"]
            return true
    return false
}
```

## Consequences

- Minimal değişiklik: mevcut JWT yapısı korundu
- STORE_ADMIN'in her zaman override yetkisi var (plan'ın niyeti)
- Authority-based'a gelecek migration breaking change değil
- Granülarite düşük: STORE_ADMIN'den override yetkisini ayıramazsın (all-or-nothing)
- Yeni "sadece override yetkisi olan ama STORE_ADMIN olmayan" rol tanımı imkansız

## When to Revisit

Şu durumlardan biri olursa:
- Bir kullanıcıya sadece CREDIT_LIMIT_OVERRIDE verilmek istenirse (mağaza yöneticisi olmadan)
- Başka fine-grained authority ihtiyaçları birikirse (ör. DISCOUNT_OVERRIDE, VOID_SALE)
- Compliance denetimi authority-based RBAC isterse

Bu durumda:
1. `JwtXUserInfoFilter` authority loading
2. `role_def` + join tablosu
3. Controller'larda `@PreAuthorize("hasAuthority(...)")` migrate

## Related

- [[syntheses/flow-sale-checkout]] (credit limit bölümü)
- [[entities/customer-account]] (isCreditLimitExceeded alanı)
- [[syntheses/accounts-hub-production-readiness]] P2.5
