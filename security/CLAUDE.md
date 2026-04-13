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
│   │     ├── createToken(session, expireMin, refreshMin): JWT
│   │     └── parseSessionFromToken(token): TOpenSessionInstance  ← refresh akışında kullanılır
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

## 3. URL NAMING CONVENTION — KRİTİK

### Backend Controller Path'i ≠ Flutter URL

Tüm istekler Flutter → api-manager (8080) → ilgili servis akışıyla gider.  
api-manager, `security/**` path'lerini 8002'ye, `product/**` path'lerini 8001'e yönlendirir.

```
┌─────────────────────────────────────────────────────────────────────┐
│ Backend controller'da    │  Flutter'dan çağırırken                  │
│ @RequestMapping yazar    │  (api-manager prefix eklenir)             │
├──────────────────────────┼──────────────────────────────────────────┤
│ /authenticate            │  security/authenticate                    │
│ /api/v1/auth/...         │  security/api/v1/auth/...                │
│ /api/users               │  security/api/users                      │
│ /api/get-menu-for-user   │  security/api/get-menu-for-user          │
│ /i18n/all                │  security/i18n/all                        │
└──────────────────────────┴──────────────────────────────────────────┘
```

**Kural:** Flutter'da URL her zaman `security/` veya `product/` prefix'iyle başlar.  
Backend controller'da bu prefix **yoktur** — sadece `/api/...` veya `/authenticate` yazar.

```dart
// ✅ DOĞRU
await _apiClient.post('security/authenticate', data: ...);
await _apiClient.post('security/api/v1/auth/refresh-token', data: ...);
await _apiClient.get('security/api/users');
await _apiClient.get('security/i18n/all?lang=TR');

// ❌ YANLIŞ — prefix eksik
await _apiClient.post('authenticate', data: ...);
await _apiClient.post('api/v1/auth/refresh-token', data: ...);

// ❌ YANLIŞ — direkt port
await _apiClient.post('http://localhost:8002/authenticate', data: ...);
```

---

## 3a. TÜM ENDPOINT'LER

### Auth

| Method | Controller Path | Flutter URL | Auth |
|--------|----------------|-------------|------|
| POST | `/authenticate` | `security/authenticate` | ✗ |
| POST | `/api/v1/auth/refresh-token` | `security/api/v1/auth/refresh-token` | ✗ |

### Kullanıcı Yönetimi

> **Controller path** = backend `@RequestMapping` değeri (prefix yok)  
> **Flutter URL** = api-manager üzerinden çağrılırken kullanılan tam path

| Method | Controller Path | Flutter URL | Auth |
|--------|----------------|-------------|------|
| GET | `/api/users` | `security/api/users` | ✓ |
| GET | `/api/users/{id}` | `security/api/users/{id}` | ✓ |
| POST | `/api/users` | `security/api/users` | ✓ |
| PUT | `/api/users/{id}` | `security/api/users/{id}` | ✓ |
| DELETE | `/api/users/{id}` | `security/api/users/{id}` | ✓ |
| PATCH | `/api/users/{id}/toggle-status` | `security/api/users/{id}/toggle-status` | ✓ |
| POST | `/api/users/{id}/change-password` | `security/api/users/{id}/change-password` | ✓ |
| POST | `/api/users/{id}/reset-password` | `security/api/users/{id}/reset-password` | ✓ |
| POST | `/api/users/{id}/roles` | `security/api/users/{id}/roles` | ✓ |
| DELETE | `/api/users/{id}/roles/{roleCode}` | `security/api/users/{id}/roles/{roleCode}` | ✓ |
| GET | `/api/users/{id}/roles` | `security/api/users/{id}/roles` | ✓ |
| GET | `/api/users/available-roles` | `security/api/users/available-roles` | ✓ |

### Firma & Menü

| Method | Controller Path | Flutter URL | Auth |
|--------|----------------|-------------|------|
| POST | `/api/v1/company/register` | `security/api/v1/company/register` | ✗ |
| POST | `/api/save-menu-category` | `security/api/save-menu-category` | ✓ |
| GET | `/api/get-menu-for-user` | `security/api/get-menu-for-user` | ✓ |

### i18n

| Method | Controller Path | Flutter URL | Auth |
|--------|----------------|-------------|------|
| GET | `/i18n/all` | `security/i18n/all` | ✓ |

---

## 4. JWT PAYLOAD YAPISI

```json
{
  "sub": "username",
  "iat": 1234567890,
  "exp": 1234567890,
  "sessionInstance": "{
    \"userInformation\": {
      \"userId\": \"uuid\",
      \"userName\": \"user\",
      \"displayName\": \"Ad Soyad\",
      \"selectedCompanyCode\": \"FIRMA001\",
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
| `findByUserDef()` ile UserDefAccess sorgulamak | `IncorrectResultSizeDataAccessException`: aynı kullanıcı birden fazla firmada access kaydına sahip olabilir. Her zaman `findByUserDefAndCompanyCode(user, user.getCompanyCode())` kullan. `findFirstByUserDef` sadece login öncesi (companyCode bilinmediğinde) fallback'tir — artık login'de de `findByUserDefAndCompanyCode` kullanılıyor. |
| Flutter'dan `security/api/v1/users` çağırmak | Path `/v1` içermiyor — doğrusu `security/api/users` |
| data.sql'e `STORE_MANAGER` kullanıcı atamak | Standart kod `STORE_ADMIN`. `STORE_MANAGER` backward compat — data.sql sonu migrasyonla STORE_ADMIN'e çevrilir |
| `Jwts.parserBuilder()` kullanmak | **JJWT 0.12.x'te kaldırıldı.** Doğru API: `Jwts.parser().verifyWith((SecretKey) key).build().parseSignedClaims(token).getPayload()` |
| `parseClaimsJws().getBody()` kullanmak | 0.12.x'te: `parseSignedClaims().getPayload()` |
| `payload['sessionId'] as String` cast etmek | Backend `sessionId` null dönebilir. Null-safe: `payload['sessionId'] as String? ?? ''` |

---

## 12. DDL STRATEJİSİ VE DATA.SQL SORUMLULUKLARI

### DDL Modu

```properties
# security/application.properties
spring.jpa.hibernate.ddl-auto=create
```

`create` → her startup'ta tüm tablolar **DROP + CREATE** → data.sql temiz INSERT'lerle çalışır.

| Mod | Startup | Shutdown | Kullanım |
|-----|---------|----------|----------|
| `create` | DROP+CREATE | — | **Dev** (şu an) |
| `create-drop` | CREATE | DROP | ⚠️ Crash sonrası eski data kalır — KULLANMA |
| `update` | Sadece yeni kolon | — | Production |

### data.sql Sorumlulukları

security/data.sql **tek ve tek yer**:
- `company` (SEDCORE, SEDCORE1)
- `role_def` (her firma için tüm roller)
- `user_def` (tüm kullanıcılar — admin, kasiyer, depo, kasiyer2, magaza_admin, giyim_kasiyer, giyim_depo)
- `user_def_access` (PBKDF2WithHmacSHA1 hash'ler — sabit salt'larla üretildi)
- `user_role` (tüm rol atamaları)
- `ext_messages`, `ext_bundles` (i18n ve menü seed)

**DevPasswordSeeder.java KALDIRILDI** — tüm seed data.sql'de. Yeni kullanıcı eklemek için:
1. Python ile hash üret: `hashlib.pbkdf2_hmac('sha1', pwd.encode(), base64.b64decode(salt), 1024, dklen=32)`
2. data.sql'e INSERT ekle

**Kural:** pos-product-manager/data.sql'e kullanıcı/rol INSERT'i ekleme. Çift INSERT → çakışma.

### ON CONFLICT + Unique Constraint Tuzağı

`ON CONFLICT DO NOTHING` sadece PK değil **tüm UNIQUE constraint** ihlallerini sessizce yutar.  
Eğer bir tabloda tek kolon unique varsa (ör. `name unique`), farklı firmalar aynı ismi insert edemez → satır atlanır → FK kırılır.

**Kural:** Her entity'deki unique → `(company_code, alan)` compound unique olmalı. (Bkz. core/CLAUDE.md §10)

### 13. USERDEFACCESS — MULTI-TENANT SORGU KURALI

`user_def_access` tablosunda `UNIQUE(user_def_id, company_code)` constraint var.  
Aynı kullanıcı birden fazla firmada erişim kaydına sahip olabilir.

```java
// ✅ DOĞRU — login dahil tüm durumlarda
userDefAccessRepository.findByUserDefAndCompanyCode(userDef, userDef.getCompanyCode())

// ❌ YANLIŞ — IncorrectResultSizeDataAccessException riski
userDefAccessRepository.findByUserDef(userDef)          // ESKİ — silinmiştir
userDefAccessRepository.findFirstByUserDef(userDef)     // Sadece gerçek fallback durumlarında
```
