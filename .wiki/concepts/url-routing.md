---
title: URL Routing & Prefix Kuralı — Tek Kaynak
type: concept
source: .claude/reference/url-routing.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# URL Routing & Prefix Kuralı — Tek Kaynak

Tüm istekler **api-manager (8080)** üzerinden geçer. Hiçbir client direkt 8001/8002'ye bağlanmaz.

---

## Temel Kural

> **Backend controller** `/api/...` yazar — service prefix olmadan.  
> **Client (Flutter/React)** her zaman service prefix ekler.

```
Backend @RequestMapping              Client URL (api-manager üzerinden)
─────────────────────────────────────────────────────────────────────
security servisi:
  /authenticate                  →   security/authenticate
  /api/v1/auth/refresh-token     →   security/api/v1/auth/refresh-token
  /api/users                     →   security/api/users
  /i18n/all                      →   security/i18n/all

pos-product-manager servisi:
  /api/v1/products               →   product/api/v1/products
  /api/v1/products/batch         →   product/api/v1/products/batch
  /api/v1/stores                 →   product/api/v1/stores
  /api/v1/categories             →   product/api/v1/categories
```

---

## Gateway Route Tanımı

```yaml
# api-manager/application.yml
spring.cloud.gateway.routes:
  - id: security-service
    uri: http://localhost:8002
    predicates: [ Path=/security/** ]
    filters: [ StripPrefix=0 ]     # prefix korunur

  - id: product-public
    uri: http://localhost:8001
    predicates: [ Path=/product/api/v1/public/** ]
    filters: [ StripPrefix=0 ]     # JWT bypass

  - id: product-service
    uri: http://localhost:8001
    predicates: [ Path=/product/** ]
    filters: [ StripPrefix=0 ]
```

---

## Client Kullanım Örnekleri

```dart
// ✅ Flutter
await _apiClient.get('product/api/v1/products');
await _apiClient.post('security/authenticate', data: ...);
await _apiClient.get('security/i18n/all?lang=TR');

// ❌ YANLIŞ — prefix eksik
await _apiClient.get('api/v1/products');

// ❌ YANLIŞ — direkt port
await _apiClient.get('http://localhost:8001/api/v1/products');

// ❌ YANLIŞ — başta slash
await _apiClient.get('/product/api/v1/products');
```

```typescript
// ✅ React — endpointBuilder üzerinden, hardcode yasak
axiosInstance.get(ENDPOINTS.products);   // = '/product/api/v1/products'
```

---

## REST URL Şablonu

```
GET    /api/v1/{resource}          → liste
GET    /api/v1/{resource}/{id}     → tekil
POST   /api/v1/{resource}          → oluştur
PUT    /api/v1/{resource}/{id}     → güncelle
DELETE /api/v1/{resource}/{id}     → soft delete
GET    /api/v1/{resource}/search?q → arama
POST   /api/v1/{resource}/batch    → toplu
```

---

## JWT Bypass (Public) Path'ler

Token olmadan erişilen yollar — 3 yerde birden tanımlı, hepsini senkron tut:

1. `api-manager/JwtAuthFilter.PUBLIC_PATHS`
2. `api-manager/CompanyResolutionFilter.isPublicPath()`
3. `security/SecurityConfiguration.requestMatchers().permitAll()`
4. `core/JwtXUserInfoFilter.PUBLIC_PATHS` (eğer `/api/**` ise)

Mevcut public path'ler:

```
/security/authenticate
/security/api/v1/auth/refresh-token
/security/api/v1/company/register
/security/i18n/**
/product/api/v1/public/**
/actuator/health
/actuator/info
```

> ⚠️ `/api/v1/company/` EKLEME — pos-product-manager'da `CompanySetting` endpoint var, eklenirse tenant sızıntısı açar.

---

## Downstream Header Enjeksiyonu

Gateway her authenticated request'e ekler:

```
X-Company-Code: <selectedCompanyCode>
X-User-Info:    <sessionInstance JSON string>
```

pos-product-manager'da `CompanyContextFilter` bu header'ı okur → `CompanyContext.set(code)` → ThreadLocal.

---

## Sık Yapılan Hatalar

| Hata | Çözüm |
|------|-------|
| Flutter `api/v1/stores` | `product/api/v1/stores` — prefix zorunlu |
| Flutter `/product/...` (başta slash) | Slash'sız: `product/...` |
| `http://localhost:8001/...` | Gateway üzerinden: `product/...` |
| React hardcode URL | `ENDPOINTS.xxx` sabitini kullan |
| Public endpoint 401 dönüyor | 4 filter listesi de güncel mi? |
| `/api/v1/company/` public yapmak | **Yapma** — tenant sızıntısı |
