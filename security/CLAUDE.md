# CLAUDE.md — security (JWT Auth Servisi)

Genel kurallar için kök `CLAUDE.md`'e bak.  
**Port:** 8002 · **Context path:** `/security` · **Base package:** `com.sedcore.security`

---

## 1. SORUMLULUKLAR

| İşlev | Açıklama |
|-------|---------|
| Login / JWT üretimi | Kimlik doğrulama → access + refresh token |
| Token yenileme | Refresh token ile yeni access token |
| Firma kaydı | Yeni şirket + admin kullanıcı + varsayılan roller |
| Kullanıcı CRUD | Admin tarafından kullanıcı yönetimi |
| Rol sistemi | ADMIN / STORE_ADMIN / CASHIER / WAREHOUSE / SUPER_ADMIN |
| Dinamik menü | Role göre filtrelenmiş menü ağacı |
| i18n | `data.sql`'deki key:value çiftleri → REST API ile client'a |

---

## 2. PAKET YAPISI

```
com.sedcore.security/
├── config/
│   ├── SecurityConfiguration    # Spring Security — JWT filter, CORS, permitAll yolları
│   └── MessageInitializer       # data.sql'den i18n mesajlarını yükle
│
├── controllers/
│   ├── RestAuthenticateController       # POST /authenticate, POST /refresh-token
│   ├── RestCompanyRegistrationController # POST /company/register
│   ├── RestMenuCategoryController       # Menü yapısı CRUD
│   ├── RestMessageController            # GET /i18n/all (i18n mesajları)
│   └── UserController (IUserController) # Kullanıcı CRUD
│
├── services/
│   ├── IAuthenticationService → imp/AuthenticationServiceImp
│   │     └── authenticate(request) → JWT üretir
│   ├── ITokenService → imp/TokenService
│   │     ├── createToken(session, expireMin, refreshMin): TokenResponse
│   │     ├── validateToken(token): boolean
│   │     └── parseToken(token): TOpenSessionInstance
│   ├── IUserDefService → imp/UserDefService
│   │     ├── login(userName, password): TOpenSessionInstance
│   │     ├── createUser(companyCode, request): UserResponse
│   │     ├── updateUser(id, request): UserResponse
│   │     ├── deleteUser(id): void  (soft delete)
│   │     ├── toggleStatus(id): void
│   │     ├── changePassword(id, request): void
│   │     ├── resetPassword(id, request): void  (admin — force change on next login)
│   │     ├── assignRole(userId, roleCode, companyCode): void
│   │     ├── removeRole(userId, roleCode): void
│   │     └── getRoles(userId): List<String>
│   ├── ICompanyRegistrationService → firma kayıt workflow
│   ├── IMenuService → imp/MenuServiceImpl  (rol bazlı menü)
│   ├── IMenuCategoryService
│   ├── IMenuItemService
│   ├── UserRoleService            # Rol atama/kaldırma
│   └── JWToken                    # JWT yardımcı metotlar
│
├── repos/
│   ├── UserDefRepository          # findByUserName, findAllByCompanyCode
│   ├── CompanyRepository          # findByCompanyCode, findByDomain
│   ├── RoleDefRepository          # findByCodeAndCompanyCode
│   ├── UserRoleRepository         # findByUserDef, findByUserDefAndRoleCode
│   ├── MenuRepository
│   ├── MenuItemRepository
│   ├── RoleMenuRepository         # Rol-menü yetkisi
│   └── UserDefAccessRepository    # Şifre hash, salt, IP kısıtlaması
│
├── models/
│   ├── request/
│   │   ├── AuthenticationRequest      # username, password, companyCode
│   │   ├── CreateUserRequest          # userName, displayName, password, userType, roles
│   │   ├── UpdateUserRequest          # displayName, languageVal, userType, storeId
│   │   ├── AssignRoleRequest          # roleCode
│   │   ├── ChangePasswordRequest      # currentPassword, newPassword
│   │   ├── ResetPasswordRequest       # newPassword
│   │   └── CompanyRegistrationRequest # companyCode, companyName, adminUser, sectorType
│   └── response/
│       └── UserResponse               # id, userName, displayName, roles, userType...
│
└── enums/
    └── UserType   # ADMIN / STORE_ADMIN / CASHIER / WAREHOUSE / SUPER_ADMIN / USER
```

---

## 3. TÜM ENDPOINT'LER

### Auth

| Method | Path | Auth | Açıklama |
|--------|------|------|---------|
| POST | `/security/authenticate` | ✗ | Login → access + refresh token |
| POST | `/security/api/v1/auth/refresh-token` | ✗ | Refresh → yeni access token |

### Kullanıcı Yönetimi

| Method | Path | Auth | Açıklama |
|--------|------|------|---------|
| GET | `/security/api/users` | ✓ | Tüm kullanıcılar (X-Company-Code gerekli) |
| GET | `/security/api/users/{id}` | ✓ | Kullanıcı detayı |
| POST | `/security/api/users` | ✓ | Kullanıcı oluştur |
| PUT | `/security/api/users/{id}` | ✓ | Kullanıcı güncelle |
| DELETE | `/security/api/users/{id}` | ✓ | Kullanıcı sil (soft delete) |
| PATCH | `/security/api/users/{id}/toggle-status` | ✓ | Aktif/pasif toggle |
| POST | `/security/api/users/{id}/change-password` | ✓ | Şifre değiştir (eski şifre gerekli) |
| POST | `/security/api/users/{id}/reset-password` | ✓ | Şifre sıfırla (admin) |
| POST | `/security/api/users/{id}/roles` | ✓ | Rol ata |
| DELETE | `/security/api/users/{id}/roles/{roleCode}` | ✓ | Rol kaldır |
| GET | `/security/api/users/{id}/roles` | ✓ | Kullanıcının rolleri |
| GET | `/security/api/users/available-roles` | ✓ | Firma'ya ait tüm roller (dropdown için) |

### Firma & Menü

| Method | Path | Auth | Açıklama |
|--------|------|------|---------|
| POST | `/security/api/v1/company/register` | ✗ | Firma kaydı + admin kullanıcı |
| POST | `/security/api/save-menu-category` | ✓ | Menü kategorisi kaydet |
| GET | `/security/api/get-menu-for-user` | ✓ | Rol bazlı dinamik menü |

### i18n

| Method | Path | Auth | Açıklama |
|--------|------|------|---------|
| GET | `/security/i18n/all` | ✓ | Tüm çeviriler (param: `lang=TR\|EN`) |

---

## 4. JWT PAYLOAD YAPISI

```json
{
  "sub": "username",
  "iat": 1234567890,
  "exp": 1234567890,
  "sessionInstance": "{
    \"userInformation\": {
      \"id\": \"uuid\",
      \"username\": \"user\",
      \"displayName\": \"Ad Soyad\",
      \"companyCode\": \"FIRMA001\",
      \"languageVal\": \"tr\",
      \"email\": \"user@firma.com\",
      \"dynamicLoginParameters\": {
        \"storeId\": \"store-uuid\",
        \"sectorType\": \"AUTO_PARTS\"
      }
    },
    \"roles\": [
      { \"roleName\": \"ADMIN\" },
      { \"roleName\": \"STORE_ADMIN\" }
    ]
  }",
  "tokenType": "new"
}
```

**ÖNEMLİ:** `sessionInstance` **string** olarak gömülmüştür.  
Flutter: `jsonDecode(payload['sessionInstance'] as String)`  
React: `JSON.parse(claims.sessionInstance)`  
Gateway: `JwtDecoder.parse()` → `X-User-Info` header'ına yazar → downstream servislere iletir

**Token süreleri:**
- Access token: 60 dakika
- Refresh token: 120 dakika

---

## 5. ROL SİSTEMİ VE YETKİLER

```
SUPER_ADMIN    → Platform geneli (birden fazla firma yönetimi)
ADMIN          → Firma içi tüm yetkiler, kullanıcı oluşturma
STORE_ADMIN    → Mağaza yönetimi, raporlar, personel oluşturma (storeId atanabilir)
CASHIER        → Sadece POS satış ekranı — storeId ZORUNLU
WAREHOUSE      → Stok görüntüleme ve transfer işlemleri
USER           → Temel erişim (firma bazlı özelleştirilir)
```

**Kullanıcı oluşturma kuralları:**
- CASHIER → `storeId` verilmezse tüm mağazalara erişim (ideal: storeId verilmeli)
- STORE_ADMIN → `storeId` verilirse o mağazaya kilitlenir, null ise tüm mağazalar
- ADMIN / WAREHOUSE → `storeId` null bırakılır (tüm mağazalar)
- `userName` platform geneli benzersiz (3-40 karakter)
- Şifre en az 6 karakter, bcrypt ile saklanır
- Admin sıfırladığında `isForcePasswordChange=true` → kullanıcı bir sonraki girişte değiştirmek zorunda

**Menü erişimi:**
```
GET /security/api/get-menu-for-user
  → JWT içindeki rollere bakılır
  → RoleMenuRepository: rol + menü item eşleşmesi sorgulanır
  → Kullanıcıya ait menü öğeleri filtrelenmiş döner
  → Flutter: menu_screen.dart render eder
  → React: menuService.getMenu() → Redux store'a yazar
```

---

## 6. ŞİFRE YÖNETİMİ

```java
// Kayıt sırasında:
String salt = PasswordUtil.generateSalt();
String hash = PasswordUtil.createHashPassword(rawPassword, salt);
userDefAccess.setSaltKey(salt);
userDefAccess.setPasswordHash(hash);   // max 400 karakter

// Doğrulama sırasında:
boolean valid = PasswordUtil.isExpectedPassword(rawPassword, salt, hash);

// IP kısıtlaması:
userDefAccess.setHasIpRestriction(true);
userDefAccess.setIpRestriction("192.168.1.1;10.0.0.1");  // noktalı virgülle ayrılır

// Force şifre değiştirme:
userDefAccess.setIsForcePasswordChange(true);  // reset sonrası set edilir
// → Flutter/React login sonrası bunu kontrol eder, zorunlu değişim ekranına yönlendirir
```

---

## 7. FİRMA KAYIT WORKFLOW'U

```
POST /security/api/v1/company/register
  {
    companyCode: "FIRMA01",   // max 8 karakter, unique
    companyName: "Firma Adı",
    sectorType: "AUTO_PARTS", // GENERAL | TECHNOLOGY | FOOTWEAR
    adminUser: {
      userName: "admin@firma.com",
      password: "...",
      displayName: "Admin Ad"
    }
  }

  ↓ CompanyRegistrationService:
  1. Company kaydı oluştur (companyCode unique kontrolü)
  2. Admin UserDef oluştur (userType = ADMIN)
  3. UserDefAccess oluştur (şifre hash + salt)
  4. ADMIN rolü ata
  5. Varsayılan menü yetkilerini ata
  6. JWT üret → doğrudan giriş yapılır (token döner)
```

---

## 8. JWT SECRET PAYLAŞIMI

`security` ve `api-manager` **aynı secret**'ı kullanır. Değişince ikisi birden güncellenir:

```properties
# security/src/main/resources/application.properties
jwt.secret=${JWT_SECRET:BuCokGizliVeUzunBirAnahtarOlmalidir12345!}

# api-manager/src/main/resources/application.yml
jwt.secret: ${JWT_SECRET:BuCokGizliVeUzunBirAnahtarOlmalidir12345!}
```

---

## 9. i18n — DATA.SQL YÖNETİMİ

`security/src/main/resources/data.sql` — tüm UI metinlerinin kayıt yeri.

```sql
-- Format:
INSERT INTO message_definitions (id, created_at, created_by, updated_at, deleted_at,
                                  message_key, message_value_tr, message_value_en)
VALUES
('bnd-bt001-0000-0000-000000000001', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
 'batch.bulk_product_entry', 'Toplu Ürün Girişi', 'Bulk Product Entry')
ON CONFLICT (id) DO NOTHING;
```

**Kurallar:**
- `spring.sql.init.mode=always` → her startup'ta çalışır
- `ON CONFLICT DO NOTHING` → var olanı ezmez
- Her yeni ekran/bileşen için eksik anahtarlar buraya eklenir
- ID prefix: `bnd-` + modül kodu + sıra numarası

**Modül prefix kodları:**
```
bt=batch  wz=wizard  pd=product  st=stock   sl=sale  pu=purchase
cu=customer  su=supplier  rp=report  fn=finance  se=settings
au=auth  cm=common  db=dashboard
```

---

## 10. SPRING SECURITY YAPILANDIRMASI

```java
// Permit All (JWT bypass):
"/security/authenticate"
"/security/api/v1/auth/refresh-token"
"/security/api/v1/company/register"
"/security/i18n/**"
"/actuator/**"

// Diğer tüm path'ler: JWT zorunlu
// Session: STATELESS
// CSRF: disabled
// Filter: JwtXUserInfoFilter → X-User-Info header'ından session okur
```

---

## 11. SIK YAPILAN HATALAR

| Hata | Çözüm |
|------|-------|
| `sessionInstance` direkt object gibi kullanmak | JSON.parse / jsonDecode ile parse et |
| `/security/` prefix'ini unutmak | Gateway prefix koruyor — tam path yazılmalı |
| i18n key eklemeyi unutmak | Her yeni ekranda data.sql'e kayıt ekle |
| Token expire kontrolünü atlamak | 401 → refresh-token endpoint → yeni token |
| data.sql'de `ON CONFLICT` olmadan INSERT | Uygulama her başlangıçta crash olur |
