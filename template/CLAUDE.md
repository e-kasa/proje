# CLAUDE.md — template (React Admin + Storefront)

Genel kurallar için kök `CLAUDE.md`'e bak.  
**Stack:** React 19 + TypeScript 5 + Redux Toolkit + React Router v7 + Vite

---

## 1. TECH STACK

| Paket | Versiyon | Kullanım |
|-------|----------|---------|
| React | 19.1.1 | UI framework |
| TypeScript | 5.8.3 | Tip güvenliği |
| Vite | 6.3.6 | Build tool |
| Redux Toolkit | 2.10.1 | Global state (auth, cart, stats) |
| Zustand | 5.0.9 | Lokal component state |
| Axios | 1.13.2 | HTTP client |
| React Router DOM | 7.8.2 | Routing + route guard |
| Ant Design | 5.27.3 | UI component library |
| React Bootstrap | 2.10.10 | Grid + layout |
| PrimeReact | 10.9.7 | Data grid, calendar |
| React Query (via axios) | — | Server state caching |
| Chart.js / Apexcharts | — | Dashboard grafikleri |

---

## 2. PROJE YAPISI

```
src/
├── app.router.tsx               # Ana router — tüm route tanımları
├── main.tsx                     # Entry point: Redux Provider, PrimeReact, alert config
├── environment.tsx              # API URL'leri, ortam değişkenleri
├── customStyle.scss             # Global CSS variables + Tailwind override'ları
│
├── core/                        # Altyapı — framework seviyesi, business logic içermez
│   ├── axiosClient/
│   │   └── index.ts             # Axios instance: JWT interceptor, X-Company-Code, 401 refresh
│   ├── context/                 # React context (auth, tenant)
│   ├── endpointBuilder.ts       # Tüm API URL sabitleri — hardcode URL yasak
│   ├── modals/                  # Global modal wrapper'ları
│   ├── pagination/              # Sayfalama hook + bileşeni
│   ├── redux/
│   │   ├── store.tsx            # Redux store konfigürasyonu
│   │   ├── authSlice.ts         # { user, token, companyCode, isAuthenticated }
│   │   ├── sidebarSlice.ts      # Sidebar açık/kapalı state
│   │   └── themeSlice.ts        # Tema ayarları
│   ├── services/                # Axios tabanlı temel servis katmanı
│   ├── types/                   # Global TypeScript arayüzleri
│   └── json/                    # Statik JSON veri (diller, sabit listeler)
│
├── store/                       # Redux Toolkit slice'ları (feature state)
│   ├── cartSlice.ts             # Sepet (POS + storefront)
│   ├── statsSlice.ts            # Dashboard istatistikleri
│   └── wishlistSlice.ts         # Favori listesi (storefront)
│
├── services/                    # API servis fonksiyonları
│   ├── authService.ts           # login(), refreshToken()
│   ├── categoryApi.ts           # Kategori CRUD
│   ├── productApi.ts            # Ürün CRUD
│   ├── statsService.ts          # Dashboard stats
│   └── menuService.ts           # Dinamik menü + i18n
│
├── components/                  # Paylaşılan UI bileşenleri
├── types/                       # Feature bazlı TypeScript tipleri
├── utils/                       # Yardımcı fonksiyonlar
├── assets/                      # Görseller, ikonlar
├── routes/                      # Route guard'lar, layout wrapper'lar
└── feature-module/              # Ana feature modülleri (lazy loaded)
    ├── dashboard/
    ├── pos/                     # POS satış ekranı (web)
    ├── inventory/               # Ürün listesi, detay, ekleme
    ├── stock/                   # Stok yönetimi
    ├── sales/                   # Satış listesi, iade
    ├── purchases/               # Satın alma
    ├── people/                  # Müşteri, tedarikçi, kullanıcı
    ├── finance-accounts/        # Cari hesap, giderler
    ├── Reports/                 # Raporlar (büyük R — mevcut klasör)
    ├── settings/                # Firma, kullanıcı, sistem ayarları
    ├── ecommerce/               # E-ticaret yönetimi
    ├── storefront/              # Müşteri mağaza arayüzü
    ├── super-admin/             # Platform yönetimi (SUPER_ADMIN rolü)
    ├── hrm/                     # İnsan kaynakları
    ├── coupons/                 # İndirim kuponları
    ├── usermanagement/          # Kullanıcı yönetimi
    └── pages/                   # Statik sayfalar (404, hakkında...)
```

---

## 3. TENANT KONFİGÜRASYON — NASIL ÇALIŞIR

**Her API isteğine otomatik eklenir:**
```typescript
// core/axiosClient/index.ts — request interceptor
const state = store.getState();
const token = state.auth.token;
const companyCode = state.auth.companyCode ?? localStorage.getItem("companyCode") ?? "syste";

if (token) {
  config.headers.Authorization = `Bearer ${token}`;
}
config.headers["X-Company-Code"] = companyCode;  // her istekte otomatik

// Response interceptor: res.data.data otomatik unwrap edilir (backend standart zarfı)
```

**Token yenileme (401 durumunda):**
```typescript
// Axios interceptor 401 yakalar
// → refreshToken() çağrılır
// → Yeni token ile request retry edilir
// → Refresh da başarısız olursa → logout
```

**Firma değişimi:**
```typescript
dispatch(setCredentials({ companyCode: newCode }));
// Sonraki tüm istekler yeni companyCode ile gider
```

---

## 4. REDUX STORE YAPISI

```typescript
{
  auth:        { token, user, companyCode, isAuthenticated },
  cart:        { items, total, customerId },       // cartSlice.ts
  stats:       { revenue, orders, topProducts },   // statsSlice.ts
  wishlist:    { items },                          // wishlistSlice.ts
  sidebar:     { toggleHeader },                   // sidebarSlice.ts
  themeSetting:{ dataLayout, dataColorAll, ... }   // themeSlice.ts
}
```

**Slice şablonu:**
```typescript
// store/mySlice.ts
import { createSlice, PayloadAction } from '@reduxjs/toolkit';

interface MyState {
  items: MyItem[];
  isLoading: boolean;
  error: string | null;
}

const initialState: MyState = { items: [], isLoading: false, error: null };

const mySlice = createSlice({
  name: 'my',
  initialState,
  reducers: {
    setItems: (state, action: PayloadAction<MyItem[]>) => {
      state.items = action.payload;
    },
    setLoading: (state, action: PayloadAction<boolean>) => {
      state.isLoading = action.payload;
    },
    setError: (state, action: PayloadAction<string | null>) => {
      state.error = action.payload;
    },
  },
});

export const { setItems, setLoading, setError } = mySlice.actions;
export default mySlice.reducer;
```

---

## 5. SERVİS ŞABLONU

```typescript
// services/myService.ts
import axiosInstance from '../core/axiosClient';
import { ENDPOINTS } from '../core/endpointBuilder';

export const MyService = {
  getItems: async (): Promise<MyItem[]> => {
    const res = await axiosInstance.get(ENDPOINTS.myResource);
    return res.data.data ?? [];   // ← her zaman .data.data
  },

  createItem: async (payload: CreateMyItemDto): Promise<MyItem> => {
    const res = await axiosInstance.post(ENDPOINTS.myResource, payload);
    return res.data.data;
  },

  updateItem: async (id: string, payload: UpdateMyItemDto): Promise<MyItem> => {
    const res = await axiosInstance.put(`${ENDPOINTS.myResource}/${id}`, payload);
    return res.data.data;
  },

  deleteItem: async (id: string): Promise<void> => {
    await axiosInstance.delete(`${ENDPOINTS.myResource}/${id}`);
  },
};
```

---

## 6. API ENDPOINT KURALI

```typescript
// core/endpointBuilder.ts — URL sabitlerini BURAYA ekle
export const ENDPOINTS = {
  auth:        '/security/authenticate',
  users:       '/security/api/users',
  menu:        '/security/api/get-menu-for-user',
  i18n:        '/security/i18n/all',

  products:    '/product/api/v1/products',
  categories:  '/product/api/v1/categories',
  brands:      '/product/api/v1/brands',
  units:       '/product/api/v1/units',
  sales:       '/product/api/v1/sales',
  purchases:   '/product/api/v1/purchases',
  stock:       '/product/api/v1/stock-movements',
  suppliers:   '/product/api/v1/suppliers',
};

// ❌ axiosInstance.get('/product/api/v1/products')  → hardcode URL yasak
// ✅ axiosInstance.get(ENDPOINTS.products)
```

---

## 7. COMPONENT ŞABLONU

```tsx
// feature-module/inventory/components/ProductCard.tsx
import React from 'react';
import { useDispatch } from 'react-redux';
import { Product } from '../../../types/product';

interface Props {
  product: Product;
  onEdit: (id: string) => void;
  onDelete: (id: string) => void;
}

const ProductCard: React.FC<Props> = ({ product, onEdit, onDelete }) => {
  return (
    <div className="card border-default">
      <h3 className="text-primary font-semibold">{product.name}</h3>
      <button className="btn-primary" onClick={() => onEdit(product.id)}>
        Düzenle
      </button>
    </div>
  );
};

export default ProductCard;
```

---

## 8. ROUTE YAPISI

```tsx
// app.router.tsx — lazy loading zorunlu (feature bazlı bundle splitting)
const InventoryPage = lazy(() => import('./feature-module/inventory'));
const POSPage = lazy(() => import('./feature-module/pos'));
const DashboardPage = lazy(() => import('./feature-module/dashboard'));

// Route kategorileri:
// 1. Public (token gerekmez): /signin, /signup, /store, /product-detail
// 2. Protected (token gerekir): /dashboard, /inventory, /pos, /sales, /purchases...
// 3. Super Admin (SUPER_ADMIN rolü): /super-admin/**
```

**Route guard:**
```tsx
// routes/ klasöründe PrivateRoute bileşeni
<PrivateRoute roles={['ADMIN', 'STORE_ADMIN']}>
  <InventoryPage />
</PrivateRoute>
// Token yoksa → /signin
// Yetki yoksa → /unauthorized
```

---

## 9. CSS / SCSS KURALLARI

```scss
// customStyle.scss — global özel stiller + CSS variables

:root {
  --primary:   #667eea;
  --success:   #10b981;
  --warning:   #f59e0b;
  --danger:    #ef4444;
  --info:      #3b82f6;
}

// Tenant tema override (firma bazlı):
[data-tenant="firma-kodu"] {
  --primary: #firma-rengi;
}
```

**Kural:**
```
✅ Tailwind class: className="text-primary bg-light border-default"
✅ CSS variable: style={{ color: 'var(--primary)' }}
✅ customStyle.scss'e global override
❌ inline style={{ color: '#667eea' }}  → hardcode renk yasak
❌ inline style={{ color: '#ef4444' }}  → CSS variable kullan
```

---

## 10. SIK YAPILAN HATALAR

| Hata | Çözüm |
|------|-------|
| `res.data.items` | `res.data.data` (backend standart) |
| Hardcode API URL string | `ENDPOINTS.xxx` kullan |
| Hardcode renk `#667eea` | `var(--primary)` veya Tailwind |
| `localStorage` token her yerden | sadece `core/axiosClient` interceptor'dan |
| Tenant kodu request'e elle ekleme | Interceptor otomatik ekler |
| `any` tip kullanımı | Interface veya type tanımla |
| `console.log` production'da | `if (isDev) console.log(...)` veya kaldır |
| `sessionInstance` direkt kullanmak | `JSON.parse(claims.sessionInstance)` ile parse et |
| Lazy import olmadan büyük modül | Her feature-module lazy import olmalı |
