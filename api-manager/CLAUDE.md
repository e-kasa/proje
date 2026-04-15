---
module: api-manager
type: Spring Cloud Gateway
port: 8080
depends-on: []
touch-when: [new-service, new-public-path, cors, jwt-secret-change]
last-verified: 2026-04-16
---

# CLAUDE.md — api-manager

Tek giriş noktası. Tüm client'lar (Flutter, React) **yalnızca `localhost:8080`**'e bağlanır.  
Genel kurallar: kök `CLAUDE.md`. URL kuralı: `.claude/reference/url-routing.md`. JWT: `.claude/reference/jwt-payload.md`.

---

## Sorumluluklar

- Tek giriş noktası (Flutter/React → 8080)
- JWT doğrulama (yerel — security çağrılmaz)
- Route yönlendirme (path prefix'e göre)
- Header enjeksiyonu (`X-Company-Code`, `X-User-Info` → downstream)
- CORS (dev: localhost + sedcore.com + bertspot.com)

---

## Route Tanımı

```yaml
spring.cloud.gateway.routes:
  - id: security-service
    uri: http://localhost:8002
    predicates: [ Path=/security/** ]
    filters: [ StripPrefix=0 ]       # prefix korunur

  - id: product-public
    uri: http://localhost:8001
    predicates: [ Path=/product/api/v1/public/** ]
    filters: [ StripPrefix=0 ]       # JWT bypass

  - id: product-service
    uri: http://localhost:8001
    predicates: [ Path=/product/** ]
    filters: [ StripPrefix=0 ]
```

Yeni servis ekleme: `application.yml`'a benzer route + public endpoint varsa ayrı route.

---

## JWT Filter Akışı

```
Request → JwtAuthFilter (GlobalFilter)
  ├── Public path mi? → bypass
  └── JWT doğrulama:
        1. Authorization: Bearer {token}
        2. JwtDecoder (Nimbus, HMAC-SHA256)
        3. Expiration kontrolü (manuel)
        4. sessionInstance parse
        5. selectedCompanyCode çıkar
        6. X-User-Info header eklenir (tam sessionInstance)
        7. X-Company-Code header eklenir
        8. Downstream'e ilet
```

---

## Public Path'ler (JWT Bypass)

```
/security/authenticate
/security/api/v1/auth/refresh-token
/security/api/v1/company/register
/product/api/v1/public/**
/actuator/health
/actuator/info
```

Yeni public endpoint eklenirse **4 yer senkron** olmalı — bkz. `.claude/reference/url-routing.md`.

---

## JWT Secret

```yaml
jwt.secret: ${JWT_SECRET:BuCokGizliVeUzunBirAnahtarOlmalidir12345!}
```

`security/application.properties` ile **aynı** değer. Değiştirince ikisini birden güncelle.

---

## Sık Yapılan Hatalar

| Hata | Çözüm |
|------|-------|
| 401 doğru token ile | `jwt.secret` iki serviste farklı olabilir |
| 404 endpoint var ama yanıt yok | Route predicate Path yanlış |
| `X-Company-Code` downstream'e gitmiyor | JwtAuthFilter header injection |
| CORS hatası | `allowedOriginPatterns`'a origin ekle |
| Public endpoint JWT istiyor | 4 filter listesi güncel mi? |
| Flutter direkt 8001/8002'ye gidiyor | `product/` veya `security/` prefix kullan |
