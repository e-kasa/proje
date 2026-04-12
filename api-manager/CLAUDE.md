# CLAUDE.md — api-manager (Spring Cloud Gateway)

Genel kurallar için kök `CLAUDE.md`'e bak.  
**Port:** 8080 · Tüm client'lar (Flutter, React) **sadece bu porta** bağlanır.

---

## 1. SORUMLULUKLAR

| İşlev | Açıklama |
|-------|---------|
| Tek giriş noktası | Flutter ve React sadece `localhost:8080`'i bilir |
| JWT doğrulama | Her request'te token yerel olarak kontrol edilir (security servisi çağrılmaz) |
| Route yönlendirme | Path prefix'e göre doğru servise iletir |
| Header enjeksiyonu | JWT'den `X-Company-Code` ve `X-User-Info` çıkarılır, downstream'e eklenir |
| CORS | Tüm client origin'lere izin verir (dev ortamı) |

---

## 2. ROUTE KURALLARI

```yaml
spring.cloud.gateway.routes:

  - id: security-service
    uri: http://localhost:8002
    predicates:
      - Path=/security/**
    filters:
      - StripPrefix=0   # /security/ prefix korunur — 8002'ye aynen iletilir

  - id: product-public
    uri: http://localhost:8001
    predicates:
      - Path=/product/api/v1/public/**
    filters:
      - StripPrefix=0   # JWT bypass — public endpoint'ler

  - id: product-service
    uri: http://localhost:8001
    predicates:
      - Path=/product/**
    filters:
      - StripPrefix=0   # /product/ prefix korunur — 8001'e aynen iletilir
```

**Flutter'da URL kullanım kuralı:**
```dart
// ✅ Doğru — prefix ile gateway üzerinden
await _apiClient.get('product/api/v1/products');
await _apiClient.get('security/authenticate');

// ❌ Yanlış — direkt servis portuna bağlanma
await _apiClient.get('http://localhost:8001/api/v1/products');
```

**React'te:**
```typescript
// ✅ Doğru
axiosInstance.get('/product/api/v1/products');

// ❌ Yanlış
axiosInstance.get('http://localhost:8001/api/v1/products');
```

---

## 3. JWT FİLTRE AKIŞI

```
HTTP Request → JwtAuthFilter (GlobalFilter)
  │
  ├── Public path mi? (permitAll listesi)
  │     → Evet: JwtDecoder'ı atla, doğrudan downstream
  │
  └── Hayır: JWT doğrulama
        1. Authorization: Bearer {token} header'ından token al
        2. JwtDecoder → HMAC-SHA256 imza doğrulaması
        3. Expiration kontrolü (manuel — Nimbus auto-check yapmaz)
        4. `sessionInstance` claim parse et
        5. `selectedCompanyCode` çıkar
        6. X-User-Info header'ı ekle (tam sessionInstance string)
        7. X-Company-Code header'ı ekle
        8. Downstream servise ilet
```

**JwtDecoder (Nimbus Jose kütüphanesi):**
```java
// HMAC-SHA256 ile imza doğrulama
// SecretKey: jwt.secret property'den alınır
// security ve api-manager AYNI secret'ı kullanır
```

---

## 4. PERMIT ALL — JWT BYPASS YOLLARI

Aşağıdaki path'lere token olmadan erişilebilir:

```
/security/authenticate
/security/api/v1/auth/refresh-token
/security/api/v1/company/register
/product/api/v1/public/**
/actuator/health
/actuator/info
```

**Diğer tüm yollar → JWT zorunlu**

---

## 5. DOWNSTREAM'E İLETİLEN HEADER'LAR

Gateway her authenticated request'e şu header'ları ekler:

```
X-Company-Code: {JWT'den alınan companyCode}
X-User-Info:    {sessionInstance JSON string'i — tam JWT claim}
```

**pos-product-manager'da kullanım:**
```java
// Controller'da:
@RequestHeader("X-Company-Code") String companyCode

// CompanyContextFilter: X-Company-Code → CompanyContext.set(code) → ThreadLocal
// Tüm @Filter'lar bu ThreadLocal'i kullanır
```

---

## 6. CORS YAPILANDIRMASI

```yaml
# Dev ortamı — tüm origin'lere izin
spring.cloud.gateway.globalcors:
  corsConfigurations:
    '[/**]':
      allowedOriginPatterns:
        - "http://localhost:*"
        - "https://*.sedcore.com"
        - "https://*.bertspot.com"
      allowedMethods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
      allowedHeaders: ["*"]
      allowCredentials: true
```

---

## 7. JWT SECRET

```yaml
# api-manager/src/main/resources/application.yml
jwt:
  secret: ${JWT_SECRET:BuCokGizliVeUzunBirAnahtarOlmalidir12345!}
  # Prod'da JWT_SECRET env variable ile override et

# security servisiyle AYNI değer — değiştirince ikisini birden güncelle
```

---

## 8. UYGULAMA YAPILANDIRMASI

```yaml
server:
  port: 8080

spring:
  application:
    name: api-manager
  cloud:
    gateway:
      discovery:
        locator:
          enabled: false   # Eureka kullanılmıyor, statik route'lar
```

---

## 9. YENİ SERVİS EKLEME

Yeni bir microservis eklendiğinde `application.yml`'a route eklenir:

```yaml
- id: my-new-service
  uri: http://localhost:8003
  predicates:
    - Path=/my-prefix/**
  filters:
    - StripPrefix=0
```

Public endpoint varsa ayrı route tanımlanır (`/my-prefix/public/**` → JWT bypass).

---

## 10. SIK YAPILAN HATALAR

| Hata | Çözüm |
|------|-------|
| 401 Unauthorized — doğru token ile | jwt.secret iki serviste farklı olabilir |
| 404 — endpoint var ama yanıt yok | Route predicate Path yanlış, prefix kontrolü |
| `X-Company-Code` downstream'e gitmiyor | JwtAuthFilter'ın header injection kısmı |
| CORS hatası tarayıcıdan | allowedOriginPatterns'a origin ekle |
| Public endpoint JWT istiyor | Permit all listesine `/path/**` ekle |
| Flutter direkt 8001/8002'ye bağlanıyor | baseUrl'i 8080 yap, path prefix kullan |
