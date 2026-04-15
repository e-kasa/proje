---
module: template
type: React Admin + Storefront
stack: React 19 + TypeScript 5 + Redux Toolkit + React Router v7 + Vite
base-url: localhost:8080 (api-manager gateway)
depends-on: [api-manager, security, pos-product-manager]
touch-when: [new-feature, slice, endpoint, component, route]
last-verified: 2026-04-16
---

# CLAUDE.md — template (React)

Genel kurallar: kök `CLAUDE.md`.  
URL kuralı: `.claude/reference/url-routing.md`. API zarfı: `.claude/reference/api-response.md`.  
JWT parse: `.claude/reference/jwt-payload.md`.

---

## Tech Stack

```
React 19, TypeScript 5.8, Vite 6
Redux Toolkit 2.10   Zustand 5.0   Axios 1.13
React Router v7   Ant Design 5.27   React Bootstrap 2.10   PrimeReact 10.9
Chart.js / Apexcharts
```

---

## Proje Yapısı

```
src/
├── app.router.tsx              # Tüm route tanımları
├── main.tsx                    # Entry (Redux Provider, PrimeReact)
├── environment.tsx             # API URL'leri
├── customStyle.scss            # Global CSS variables + Tailwind override
│
├── core/                       # Altyapı
│   ├── axiosClient/index.ts    # JWT interceptor, X-Company-Code, 401 refresh
│   ├── endpointBuilder.ts      # API URL sabitleri — hardcode YASAK
│   ├── redux/                  # store, authSlice, sidebarSlice, themeSlice
│   └── services/, types/, context/
│
├── store/                      # Feature slice'ları (cart, stats, wishlist)
├── services/                   # authService, categoryApi, productApi...
├── components/                 # Paylaşılan UI
├── routes/                     # Guard + layout wrapper
└── feature-module/             # Lazy loaded features
    ├── dashboard, pos, inventory, stock
    ├── sales, purchases, people, finance-accounts
    ├── Reports, settings, ecommerce, storefront
    ├── super-admin, hrm, coupons, usermanagement, pages
```

---

## Tenant Konfigürasyon

Her request interceptor otomatik header ekler:

```typescript
// core/axiosClient/index.ts
config.headers.Authorization = `Bearer ${token}`;
config.headers["X-Company-Code"] = companyCode;   // state.auth.companyCode

// Response interceptor: res.data.data otomatik unwrap
// 401 → refreshToken → retry → başarısız: logout
```

Firma değişimi:
```typescript
dispatch(setCredentials({ companyCode: newCode }));
```

---

## Redux Store

```typescript
{
  auth:         { token, user, companyCode, isAuthenticated },
  cart:         { items, total, customerId },
  stats:        { revenue, orders, topProducts },
  wishlist:     { items },
  sidebar:      { toggleHeader },
  themeSetting: { dataLayout, dataColorAll, ... }
}
```

Slice şablonu: `createSlice({ name, initialState, reducers })` — `setItems`, `setLoading`, `setError` pattern.

---

## Endpoint Kuralı

```typescript
// core/endpointBuilder.ts — URL sabitleri BURAYA
export const ENDPOINTS = {
  auth:          '/security/authenticate',
  users:         '/security/api/users',
  menu:          '/security/api/get-menu-for-user',
  i18n:          '/security/i18n/all',

  products:      '/product/api/v1/products',
  productsBatch: '/product/api/v1/products/batch',
  categories:    '/product/api/v1/categories',
  brands:        '/product/api/v1/brands',
  units:         '/product/api/v1/units',
  sales:         '/product/api/v1/sales',
  purchases:     '/product/api/v1/purchases',
  stock:         '/product/api/v1/stock-movements',
  suppliers:     '/product/api/v1/suppliers',
};

// ❌ axiosInstance.get('/product/api/v1/products')   — hardcode YASAK
// ✅ axiosInstance.get(ENDPOINTS.products)
```

---

## Servis Şablonu

```typescript
export const MyService = {
  getItems: async (): Promise<MyItem[]> => {
    const res = await axiosInstance.get(ENDPOINTS.myResource);
    return res.data.data ?? [];   // ← her zaman .data.data
  },
  createItem: async (payload): Promise<MyItem> => {
    const res = await axiosInstance.post(ENDPOINTS.myResource, payload);
    return res.data.data;
  },
};
```

---

## Route + Guard

```tsx
// app.router.tsx — lazy zorunlu
const InventoryPage = lazy(() => import('./feature-module/inventory'));

<PrivateRoute roles={['ADMIN', 'STORE_ADMIN']}>
  <InventoryPage />
</PrivateRoute>
// Token yoksa → /signin
// Yetki yoksa → /unauthorized
```

Public: `/signin, /signup, /store, /product-detail`.

---

## CSS Kuralları

```scss
:root {
  --primary: #667eea;  --success: #10b981;  --warning: #f59e0b;
  --danger:  #ef4444;  --info:    #3b82f6;
}

[data-tenant="firma-kodu"] {
  --primary: #firma-rengi;
}
```

**Kural:**
- ✅ Tailwind: `className="text-primary bg-light border-default"`
- ✅ CSS var: `style={{ color: 'var(--primary)' }}`
- ✅ `customStyle.scss` global override
- ❌ Inline hex: `style={{ color: '#667eea' }}`

---

## Sık Yapılan Hatalar

| Hata | Çözüm |
|------|-------|
| `res.data.items` | `res.data.data` |
| Hardcode API URL | `ENDPOINTS.xxx` |
| Hardcode renk | `var(--primary)` veya Tailwind |
| `localStorage` direkt kullanım | Sadece `core/axiosClient` interceptor |
| Tenant kodu elle eklemek | Interceptor otomatik |
| `any` tip | Interface / type tanımla |
| `console.log` production | `if (isDev) console.log(...)` veya sil |
| `sessionInstance` direkt | `JSON.parse(claims.sessionInstance)` |
| Büyük modül lazy değil | Her feature-module lazy import |
| Toplu ürün ayrı çağrı | `ENDPOINTS.productsBatch` — tek POST |
| `'sector': 'genel'` | `'GENERAL'` — bkz. sector-strings.md |
