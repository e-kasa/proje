---
title: Zeynep Müşterisi DB'de Yok — Sistemik Tanı + Çözüm (2026-04-26)
type: synthesis
date: 2026-04-26
status: actionable
purpose: backend response 4 kayıt, Zeynep yok — POS'ta nasıl görünüyor sorusunun teşhisi + invalidation pattern'i kalıcı düzeltme
---

# Zeynep Müşterisi DB'de Yok

## Kanıt

Kullanıcının paylaştığı backend response (`GET /api/v1/accounts/list`):
```json
{
  "items": [4 kayıt: 2 customer + 2 supplier],
  "nextCursor": null,
  "hasMore": false
}
```

ID prefix'leri `cus-oto1-...` ve `sup-oto1-...` → **SEDCORE tenant'ı** (otomotiv yedek parça). `hasMore=false` → backend **TÜM kayıtları döndürüyor**, Zeynep listede yok.

## Kök Neden Analizi (Hızlı Eleme)

### ❌ Pagination Değil
`hasMore=false` → tüm 4 kayıt geldi. Sprint 8 hot-fix v2 zaten limit 200, auto-prefetch ekledi.

### ❌ Filter Değil
4 kayıttan 2'si CUSTOMER (Adem, Usta Oto). Filter `customer` veya `all` olsa Zeynep gelmeli.

### ❌ Search Query Değil
Eğer search açıksa response 4 kayıt değil 0-1 olur.

### ❌ Endpoint Tutarsızlığı Değil (Önceki Hipotez Çürüdü)
[`cart_panel.dart:262`](project_pos/lib/features/pos/widgets/cart_panel.dart#L262) `customerService.getCustomers(isActive: true)` → `GET /customers?isActive=true` → `customerRepository.search(null, true)`

[`AccountsListService.java:61`](pos-product-manager/src/main/java/com/sedcore/finance/service/AccountsListService.java#L61) → **AYNI** `customerRepository.search(query, true)`.

İki ekran AYNI repository method'unu kullanıyor → DB'den aynı sonuç gelmeli.

### ✅ En Olası — DB'de Zeynep Yok veya Farklı Tenant'ta

**Senaryolar:**

| # | Senaryo | Doğrulama |
|---|---|---|
| **A** | POS'ta "Zeynep" eklendi ama backend POST başarısız oldu (500/network) → frontend state in-memory tuttu, DB'ye gitmedi | POS Cart Panel'i kapat aç. Zeynep yok ise: senaryo doğrulandı. |
| **B** | Zeynep farklı tenant'ta (örn. SEDCORE1) kayıtlı; POS başka tenant session'unda görüldü | `SELECT * FROM customers WHERE LOWER(name) LIKE '%zeynep%'` |
| **C** | Zeynep `is_active=false` veya `is_deleted=true` → her iki ekranda da görünmemeli (paradox: POS'ta görünüyor diyorsa kullanıcının hatırası yanlış olabilir) | Aynı SQL + `SELECT id, is_active, is_deleted FROM customers WHERE LOWER(name) LIKE '%zeynep%'` |
| **D** | Kullanıcı yanılgısı — POS'ta başka isim ile karıştırıyor | POS Cart Panel açıkken müşteri listesini kontrol et: gerçekten Zeynep var mı? |

## Tanı Sırası (3 Adım)

### Adım 1 — DB Sorgu (10 saniye)

```sql
SELECT id, name, is_active, is_deleted, company_code, create_time
  FROM customers
  WHERE LOWER(name) LIKE '%zeynep%';
```

**Yorumlama:**
- **0 satır** → Zeynep DB'de yok → **Senaryo A veya D**
- **1+ satır, `is_active=false` veya `is_deleted=true`** → **Senaryo C**
- **1+ satır, farklı `company_code`** → **Senaryo B**
- **1+ satır, doğru tenant + active** → backend filter problemi (nadiren — başka mekanizma)

### Adım 2 — POS Cart Panel'i Kapat-Aç

Kullanıcı POS satış ekranını kapatıp tekrar açsın. Zeynep hâlâ görünüyorsa → DB'de var. Yok ise → POS state in-memory cache idi, DB'ye yazılmamıştı (Senaryo A doğrulandı).

### Adım 3 — JWT Tenant Doğrulama

```javascript
// Browser console'da JWT token'ını decode et:
JSON.parse(atob(localStorage.getItem('token').split('.')[1]))
// selectedCompanyCode field'ını kontrol et
```

Bu kod ile Adım 1'deki `customers.company_code` eşleşmeli.

## Sistemik Kalıcı Çözüm (Senaryo A için)

**Sorun:** "Yeni müşteri ekle" akışında backend POST başarısız olursa frontend kullanıcıya **belirsiz feedback** veriyor. `customerService.createCustomer()` exception fırlatırsa caller catch etmeli + hata göstermeli.

### Düzeltme E1 — Yeni Müşteri Ekleme Akışında AccountsList Invalidation

[`statement_detail_panel.dart`](project_pos/lib/features/accounts/widgets/statement_detail_panel.dart) Sprint 7 hot-fix'te `_handlePayment` sonrası `ref.invalidate(accountsListProvider)` ekledik. **Aynı pattern yeni müşteri/tedarikçi ekleme akışında da uygulanmalı:**

| Akış | Mevcut | Olması Gereken |
|---|---|---|
| AccountsHub `_NewAccountButton` → AccountEditForm save | invalidate var mı? | `ref.invalidate(accountsListProvider)` |
| POS Cart Panel "Yeni Müşteri Ekle" → AddCustomerScreen save | direkt POST | `ref.invalidate(accountsListProvider)` (POS context'inde de aynı provider) |
| Customers screen create | benzer | invalidate |

### Düzeltme E2 — POS "Yeni Müşteri" Akışında Backend Doğrulama

POS Cart Panel'de yeni müşteri ekleme:
1. AddCustomerScreen formu → submit
2. Backend POST `/customers` → response check
3. **Başarılı** ise: `ref.invalidate(accountsListProvider)` + Cart Panel _customers listesini yenile
4. **Başarısız** ise: kullanıcıya net hata göster, listeye ekleme

Eğer mevcut akışta sadece success path'te liste güncelleniyor ama hata feedback'i yoksa, kullanıcı eklemiş gibi görür.

### Düzeltme E3 — Cart Panel _CustomerPickerSheet Refresh Pattern

[`cart_panel.dart:259-265`](project_pos/lib/features/pos/widgets/cart_panel.dart#L259-L265) `_load()` metodu sadece `_customers` state'ini günceller. Yeni müşteri eklendiğinde **hem AccountsList provider invalidate edilmeli hem _CustomerPickerSheet `_load()` çağrılmalı**.

## Önerilen Aksiyonlar

### Hemen (sen, manuel test)
1. Adım 1 SQL koştur — Zeynep DB'de var mı?
2. Adım 2 POS Cart Panel kapat aç — hâlâ görünüyor mu?

### Sprint 9 (sistemik düzeltme)
- E1 — AccountEditForm save sonrası `ref.invalidate(accountsListProvider)` audit (mevcut callsite'lar)
- E2 — Backend POST hata durumunda Flutter'da explicit AppToast.error
- E3 — `_CustomerPickerSheet` ile AccountsListProvider sync mekanizması

## Sources

- Backend response: kullanıcı paylaşımı 2026-04-26 16:19
- [`accounts_list_provider.dart`](project_pos/lib/features/accounts/providers/accounts_list_provider.dart) — Sprint 8+hot-fix v2
- [`AccountsListService.java`](pos-product-manager/src/main/java/com/sedcore/finance/service/AccountsListService.java)
- [`cart_panel.dart`](project_pos/lib/features/pos/widgets/cart_panel.dart) `_CustomerPickerSheet`
- [`customer_service.dart`](project_pos/lib/features/customers/services/customer_service.dart) — `getCustomers({isActive})` API
- [`CustomerControllerImpl.java`](pos-product-manager/src/main/java/com/sedcore/customer/controller/impl/CustomerControllerImpl.java) — `GET /customers?search=...&isActive=...`
- [`CustomerRepository.java`](pos-product-manager/src/main/java/com/sedcore/customer/repository/CustomerRepository.java) `search(q, active)`

## Related

- [[concepts/troubleshooting-customer-missing-in-accounts-hub]] — generic 5 olası neden (bu sayfa o rehberin spesifik kanıt-bazlı uygulaması)
- [[syntheses/accounts-bugfix-investigation-2026-04-26]] — autoDispose race + invalidate pattern (Sprint 7 hot-fix)
- [[concepts/hibernate-filter-runtime]] — multi-tenant filter (Senaryo B için)
- [[entities/customer]] · [[entities/customer-account]]
