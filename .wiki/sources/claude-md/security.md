---
title: CLAUDE.md — security
type: source
source: security/CLAUDE.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: claude-md
note: Bu Claude Code auto-load dosyasının arşiv kopyasıdır. Orijinal yerinde 1-satır stub vardır.
---

---
module: security
type: Spring Boot Auth Service
port: 8002
context-path: /security
base-package: com.sedcore.security
depends-on: [core]
touch-when: [login, jwt, user-crud, i18n-seed, menu, role]
last-verified: 2026-04-16
---

# CLAUDE.md — security

JWT üretimi, kullanıcı/rol/firma yönetimi, i18n kaynağı.  
Genel kurallar: kök `CLAUDE.md`. URL kuralı: `.wiki/concepts/url-routing.md`. JWT: `.wiki/concepts/jwt-payload.md`.

---

## Sorumluluklar

- Login / JWT üretimi (access + refresh)
- Token yenileme
- Firma kaydı (Company + admin user + roller)
- Kullanıcı CRUD (admin tarafından)
- Rol sistemi (`ADMIN` / `STORE_ADMIN` / `CASHIER` / `WAREHOUSE` / `SUPER_ADMIN`)
- Dinamik menü (role göre filtrelenmiş ağaç)
- i18n — `data.sql`'deki mesajlar REST API ile client'a

---

## Endpoint'ler

### Auth (public)
| Method | Path | Flutter URL |
|--------|------|-------------|
| POST | `/authenticate` | `security/authenticate` |
| POST | `/api/v1/auth/refresh-token` | `security/api/v1/auth/refresh-token` |

### Kullanıcı (JWT zorunlu)
Base: `/api/users` → Flutter: `security/api/users` (v1 yok!)

```
GET    /api/users                           → liste
GET    /api/users/{id}                      → tekil
POST   /api/users                           → oluştur
PUT    /api/users/{id}                      → güncelle
DELETE /api/users/{id}                      → soft delete
PATCH  /api/users/{id}/toggle-status
POST   /api/users/{id}/change-password
POST   /api/users/{id}/reset-password        body: {newPassword}
POST   /api/users/{id}/roles                 body: {roleCode}
DELETE /api/users/{id}/roles/{roleCode}
GET    /api/users/{id}/roles
GET    /api/users/available-roles
```

### Firma & Menü & i18n
```
POST /api/v1/company/register       (public)   → security/api/v1/company/register
POST /api/save-menu-category                   → security/api/save-menu-category
GET  /api/get-menu-for-user                    → security/api/get-menu-for-user
GET  /i18n/all                                 → security/i18n/all
```

---

## Rol Sistemi

| Rol | Yetki | storeId |
|-----|-------|---------|
| `SUPER_ADMIN` | Platform geneli | null |
| `ADMIN` | Firma içi tüm yetkiler | null |
| `STORE_ADMIN` | Mağaza yönetimi | opsiyonel (kilitleme) |
| `CASHIER` | POS satış | **zorunlu (ideal)** |
| `WAREHOUSE` | Stok + transfer | null |

`STORE_MANAGER` → deprecated, data.sql sonu migrasyonla `STORE_ADMIN`'e çevrilir (bkz. `decisions/2026-04-13-store-admin-rename.md`).

**Kullanıcı oluşturma:**
- `userName` unique (3-40 karakter)
- Şifre min 6 karakter, bcrypt
- Admin reset → `isForcePasswordChange=true` (bir sonraki girişte zorunlu değişim)

---

## Şifre Yönetimi

```java
String salt = PasswordUtil.generateSalt();
String hash = PasswordUtil.createHashPassword(rawPassword, salt);  // max 400 karakter

// IP kısıtlaması
userDefAccess.setHasIpRestriction(true);
userDefAccess.setIpRestriction("192.168.1.1;10.0.0.1");  // noktalı virgül
```

---

## Firma Kayıt Akışı

```
POST /security/api/v1/company/register
  { companyCode (max 8), companyName, sectorType, adminUser }
  ↓
1. Company oluştur (unique kontrolü)
2. Admin UserDef (userType=ADMIN)
3. UserDefAccess (salt + hash)
4. ADMIN rolü ata
5. Varsayılan menü yetkileri
6. JWT üret → doğrudan giriş
```

---

## i18n — data.sql

`security/src/main/resources/data.sql` — tüm UI metinlerinin kayıt yeri.

```sql
INSERT INTO message_definitions (id, created_at, created_by, updated_at, deleted_at,
                                  message_key, message_value_tr, message_value_en)
VALUES
('bnd-bt001-0000-0000-000000000001', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
 'batch.bulk_product_entry', 'Toplu Ürün Girişi', 'Bulk Product Entry')
ON CONFLICT (id) DO NOTHING;
```

- `spring.sql.init.mode=always` → her startup
- `ON CONFLICT DO NOTHING` → var olanı ezmez (ama compound unique zorunlu, bkz. aşağı)

Modül prefix: `bt, wz, pd, st, sl, pu, cu, su, rp, fn, se, au, cm, db`.

### ON CONFLICT + Unique Tuzağı

Tek kolon unique (ör. `name unique`) + `ON CONFLICT DO NOTHING` → farklı firmalar aynı ismi insert edemez, satır atlanır, FK kırılır.  
**Kural:** Unique her zaman compound `(company_code, alan)`.

---

## DDL Stratejisi (dev)

```properties
spring.jpa.hibernate.ddl-auto=create   # Her startup DROP+CREATE
```

Detay: `decisions/2026-04-13-ddl-create-strategy.md`.

---

## data.sql Sorumluluk Ayrımı

**security/data.sql** (tek yer):
- `company`, `role_def`, `user_def`, `user_def_access`, `user_role`
- `ext_messages`, `ext_bundles` (i18n + menü)

**pos-product-manager/data.sql** (kullanıcı/rol ASLA):
- `stores`, `warehouses`, `products`, `categories`...
- `UPDATE user_def SET store_id` (mağazalar sonra)

---

## UserDefAccess — Multi-Tenant Sorgu

```java
// ✅ Login dahil TÜM durumlarda
userDefAccessRepository.findByUserDefAndCompanyCode(user, user.getCompanyCode());

// ❌ IncorrectResultSizeDataAccessException riski
userDefAccessRepository.findByUserDef(user);
userDefAccessRepository.findFirstByUserDef(user);  // sadece companyCode bilinmiyorsa fallback
```

Detay: `.wiki/syntheses/runbook-debug-tenant-leak.md`.

---

## JWT Secret

`api-manager/application.yml` ile **aynı** değer:

```properties
jwt.secret=${JWT_SECRET:BuCokGizliVeUzunBirAnahtarOlmalidir12345!}
```

---

## JJWT 0.12.x API

```java
// ✅ Doğru
Jwts.parser().verifyWith((SecretKey) key).build()
    .parseSignedClaims(token).getPayload();

// ❌ 0.11.x — kaldırıldı
Jwts.parserBuilder()...parseClaimsJws(token).getBody();
```

---

## Sık Yapılan Hatalar

| Hata | Çözüm |
|------|-------|
| `sessionInstance` direkt object | `jsonDecode` / `JSON.parse` |
| `/security/` prefix'i unutmak | Gateway prefix korur — tam path yaz |
| Yeni ekrana i18n key eklemeyi unutmak | `data.sql`'e INSERT ekle |
| `Jwts.parserBuilder()` kullanmak | 0.12.x: `Jwts.parser()...parseSignedClaims()` |
| `payload['sessionId'] as String` | Null olabilir: `as String? ?? ''` |
| `security/api/v1/users` (v1 var) | v1 yok: `security/api/users` |
| `findByUserDef(...)` | `findByUserDefAndCompanyCode(...)` |
| pos-product-manager/data.sql'e user INSERT | Yalnızca security/data.sql'de |
