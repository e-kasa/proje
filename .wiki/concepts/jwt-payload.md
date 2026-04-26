---
title: JWT Payload Yapısı — Tek Kaynak
type: concept
source: .claude/reference/jwt-payload.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# JWT Payload Yapısı — Tek Kaynak

Bu bilgi **yalnızca burada** tutulur. Diğer CLAUDE.md'ler buraya link verir.

---

## Token Yapısı

```json
{
  "sub": "username",
  "iat": 1234567890,
  "exp": 1234567890,
  "sessionInstance": "<stringified JSON>",
  "tokenType": "new"
}
```

`sessionInstance` **string** olarak gömülüdür (Gson serializer). Önce string olarak alınır, sonra parse edilir.

---

## sessionInstance İçeriği

```json
{
  "userInformation": {
    "userId": "uuid",
    "userName": "user",
    "displayName": "Ad Soyad",
    "selectedCompanyCode": "FIRMA001",
    "languageVal": "tr",
    "email": "user@firma.com",
    "sessionId": null,
    "dynamicLoginParameters": {
      "storeId": "store-uuid",
      "sectorType": "AUTO_PARTS"
    }
  },
  "roles": [
    { "roleName": "ADMIN" }
  ]
}
```

---

## Alan Adları — KRİTİK

JSON alan adları **Gson field adlarından** gelir (getter değil). Yanlış isim → TypeError.

| ✅ Doğru | ❌ Yanlış |
|---------|----------|
| `userId` | `id` |
| `userName` | `username` |
| `displayName` | `fullName`, `name` |
| `selectedCompanyCode` | `companyCode` |
| `roles[].roleName` | `roles[]` (string) |

---

## Parse — Flutter

```dart
final payload    = jwtDecode(token);
final sessionStr = payload['sessionInstance'] as String;
final session    = jsonDecode(sessionStr);
final userInfo   = session['userInformation'];

User(
  id:                  userInfo['userId'] as String? ?? '',
  username:            userInfo['userName'] as String? ?? '',
  displayName:         userInfo['displayName'] as String? ?? '',
  selectedCompanyCode: userInfo['selectedCompanyCode'] as String? ?? '',
  languageVal:         userInfo['languageVal'] as String? ?? 'tr',
  roles: (session['roles'] as List?)
      ?.map((e) => (e as Map)['roleName'] as String? ?? '')
      .toList() ?? [],
  storeId:    userInfo['dynamicLoginParameters']?['storeId'] as String?,
  sectorType: userInfo['dynamicLoginParameters']?['sectorType'] as String?,
);

// sessionId null-safe — backend her zaman set etmez
final sessionId = payload['sessionId'] as String? ?? '';
```

## Parse — React

```typescript
const claims     = jwtDecode<any>(token);
const session    = JSON.parse(claims.sessionInstance);
const userInfo   = session.userInformation;
const roles: string[] = session.roles.map((r: any) => r.roleName);
```

## Parse — Java (gateway/downstream)

`X-User-Info` header tam `sessionInstance` string'ini taşır. `TOpenSessionInstance` sınıfına Gson ile parse edilir.

---

## Token Süreleri

- Access token: **60 dakika**
- Refresh token: **120 dakika**

---

## Secret Paylaşımı

`security` ve `api-manager` **aynı** `jwt.secret` değerini kullanır.

```properties
jwt.secret=${JWT_SECRET:BuCokGizliVeUzunBirAnahtarOlmalidir12345!}
```

Değiştirince **iki serviste birden** güncelle.

---

## JJWT API (0.12.x)

```java
// ✅ Doğru
Jwts.parser()
    .verifyWith((SecretKey) key)
    .build()
    .parseSignedClaims(token)
    .getPayload();

// ❌ Yanlış (0.11.x — kaldırıldı)
Jwts.parserBuilder()...parseClaimsJws(token).getBody();
```

---

## Sık Yapılan Hatalar

| Hata | Çözüm |
|------|-------|
| `sessionInstance` direkt object gibi kullanmak | `jsonDecode` / `JSON.parse` zorunlu |
| `payload['sessionId'] as String` | `as String? ?? ''` — null-safe |
| `roles.map((e) => e.toString())` | `(e as Map)['roleName']` |
| `userInfo['companyCode']` | `userInfo['selectedCompanyCode']` |
| `userInfo['username']` | `userInfo['userName']` (U büyük) |
