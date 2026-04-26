---
title: UserDef — sistem kullanıcısı entity'si
type: entity
source: core/src/main/java/com/towpen/base/db/model/security/UserDef.java
ingested: 2026-04-25
last-verified: 2026-04-25
status: stub
---

# UserDef

## Tanım

Sistem kullanıcısı entity'si — login için temel kayıt. `userName` unique. Kasiyer için opsiyonel `storeId` ataması var (null = tüm mağazalar).

## Kod Konumu

- `core/src/main/java/com/towpen/base/db/model/security/UserDef.java:18` — `extends TOpenSimpleCompanyEntity`
- Repository ve servisler: `security/src/main/java/.../user/` altında

> Towpen base library'de tanımlı; `security/` modülü sadece repository/service kullanır.

## Önemli Alanlar

| Alan | Tip | Kısıt |
|---|---|---|
| `userName` | varchar(40) | unique, not null |
| `userDisplayName` | varchar(200) | |
| `languageVal` | LanguageType enum | |
| `isActive` | boolean | |
| `userType` | UserType enum | USER / ADMIN / SUPER_ADMIN |
| `genericIdentifier` + `userDefGenericIdType` | string + enum | TC kimlik vs |
| `storeId` | varchar | null = tüm mağazalar (ADMIN tipi); kasiyer için belirli mağaza |

## Kullanım

- Authentication akışı (`/security/authenticate`)
- Role atama: `[[entities/user-def-access]]` veya `UserRole`
- Erişim kontrolü: `[[concepts/jwt-auth]]`
- Multi-tenant filter: `companyCode` zorunlu (TOpenSimpleCompanyEntity)

## Related

- [[entities/user-def-access]]
- [[concepts/jwt-auth]]
- [[concepts/multi-tenant]]
- [[entities/security]]
