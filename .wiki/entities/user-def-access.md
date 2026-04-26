---
title: UserDefAccess — login + şifre + IP kısıtlama detayları
type: entity
source: core/src/main/java/com/towpen/base/db/model/security/UserDefAccess.java
ingested: 2026-04-25
last-verified: 2026-04-25
status: stub
---

# UserDefAccess

## Tanım

Kullanıcının login/şifre/IP kısıtlama detaylarını tutan ayrı entity. UserDef ile 1-N: aynı kullanıcı her firma için ayrı erişim kaydı. `(user_def_id, company_code)` compound unique.

## Kod Konumu

- `core/src/main/java/com/towpen/base/db/model/security/UserDefAccess.java:19` — `extends TOpenSimpleCompanyEntity`
- `@NamedEntityGraph` adı: `"user-def-access-entity"`

## Önemli Alanlar

| Alan | Tip | Açıklama |
|---|---|---|
| `userDef` | ManyToOne LAZY | UserDef referansı |
| `canLogin` | boolean | login yetkisi flag |
| `isForcePasswordChange` | boolean | ilk login'de şifre değişikliği zorla |
| `saltKey` | string | bcrypt salt |
| `passwordHash` | varchar(400) | bcrypt çıktısı |
| `lastChangeTime` | timestamp | son şifre değişikliği |
| `hasIpRestriction` + `ipRestriction` | bool + string | IP whitelist (CIDR) |
| `accessType` | AccessType enum | INTERNAL / EXTERNAL / API |

## Kullanım

`AuthenticationService` login adımında:
```java
findByUserDefAndCompanyCode(user, user.getCompanyCode())
```

> Root CLAUDE.md kuralı #4: `companyCode` JWT'den gelen değer ile sorgulanır, `X-Company-Code` header'a güvenilmez.

## Related

- [[entities/user-def]]
- [[concepts/jwt-auth]]
- [[concepts/multi-tenant]]
