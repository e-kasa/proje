---
title: Müşteri AccountsHub'da Görünmüyor — Tanı Rehberi
type: concept
date: 2026-04-26
status: actionable
purpose: POS Cart Panel'de görünen ama AccountsHub'da görünmeyen müşteri sorunlarının tanı sırası
trigger: kullanıcı şikayeti "X müşterisi cari hesaplarda yok"
---

# Müşteri AccountsHub'da Görünmüyor — Tanı Rehberi

## Bağlam

[[entities/accounts-hub-screen]] (AccountsHub) Sprint 8'den itibaren yeni `GET /api/v1/accounts/list` endpoint'i kullanıyor (cursor-based pagination). [POS Cart Panel müşteri seçimi](project_pos/lib/features/pos/widgets/cart_panel.dart) hâlâ eski `GET /customers?isActive=true` endpoint'inde (sayfasız).

İki ekran **aynı `customerRepository.search()`** sorgusunu kullanır ama farklı yollar:
- **POS Cart Panel**: `customerRepository.search(null, true)` — tüm aktif müşteriler tek seferde
- **AccountsHub**: [`AccountsListService.list(...)`](pos-product-manager/src/main/java/com/sedcore/finance/service/AccountsListService.java) — aynı `customerRepository.search(query, true)` + filter + cursor pagination

Bu rehber: **POS'ta görünen ama AccountsHub'da görünmeyen** müşteri için olası nedenleri öncelik sırasıyla listeler.

## 5 Olası Neden (Olasılık Sırasıyla)

### 🔴 #1 (En Olası) — Pagination İlk Sayfada Yok
[`accounts_list_provider.dart:_pageLimit = 50`](project_pos/lib/features/accounts/providers/accounts_list_provider.dart) Sprint 8 hot-fix sonrası limit 50. Sıralama: **`name ASC, type ASC, id ASC`**.

**Senaryo:** 50+ aktif müşteri varsa, alfabetik olarak sondaki harflerle başlayan müşteriler (örn. "Z", "Y", "V") **ilk sayfada gözükmez**. Kullanıcı listeyi scroll etmediyse `loadMore()` tetiklenmemiştir.

**Doğrulama:**
- AccountsHub liste'ye **alta scroll yap** → Z harfli müşteri yüklenmeli (200px bottom → loadMore otomatik)
- Backend doğrulama: `curl GET /api/v1/accounts/list?limit=50&filter=customer&q=zeynep` → response.items içinde mi?

**Düzeltme:** Search box'a baş harfini yaz → server-side filter ile direkt gelir. Veya scroll alta kaydır.

### 🟠 #2 — Aktif Filter "Tedarikçi" veya "Vadesi Geçmiş"
AccountsHub üst chip'lerinde aktif filtre yanlış olabilir:
- `Tedarikçi` chip'i basılı → sadece SUPPLIER görünür, customer eleniyor
- `Vadesi Geçmiş` → `customerAccount.overdueAmount = 0` ise eleniyor

**Doğrulama:** Üst chip bar'ında **`Tümü`** veya **`Müşteri`** chip'i seçili olmalı.

**Düzeltme:** Doğru chip'e bas.

### 🟠 #3 — Search Query Açık (Önceki Aramadan)
Search box'ta önceki bir filtre kalıyor (örn. "ali"). Server-side query active → Zeynep eleniyor.

**Doğrulama:** Search box'ı kontrol et, varsa temizle (X butonu).

### 🟡 #4 — Müşteri Soft-Deleted (`isDeleted = true`)
[`CustomerRepository.search(q, active)`](pos-product-manager/src/main/java/com/sedcore/customer/repository/CustomerRepository.java) WHERE clause'unda `isActive` filter var ama `isDeleted` ayrı kontrol gerekiyor.

Eğer Zeynep `isDeleted=true` ama `isActive=true` ise:
- **POS Cart Panel** `customerService.getCustomers(isActive: true)` → soft-deleted da gelebilir (CustomerControllerImpl `toMap` filter etmiyor olabilir)
- **AccountsHub** aynı search → aynı sonuç gelmeli (paradox değil)

**Doğrulama:**
```sql
SELECT id, name, is_active, is_deleted, company_code
  FROM customers
  WHERE LOWER(name) LIKE '%zeynep%';
```

**Düzeltme:** `is_deleted=true` ise → ya kaydı geri yükle (`UPDATE customers SET is_deleted=false WHERE id=...`) ya da kalıcı silmek için yeniden ekle.

### 🟡 #5 — Multi-Tenant `company_code` Uyumsuzluğu
Zeynep farklı şirkette (`SEDCORE` vs `SEDCORE1` vb) eklendi. JWT'deki `selectedCompanyCode` ile eşleşmediyse [[concepts/hibernate-filter-runtime]] (filter `filterByCompanyCode`, parametre `cpCode`) eler.

POS Cart Panel ve AccountsHub aynı tenant'ta çalışır → ikisinde de gelmemeli. Ama session değiştiyse veya kullanıcı farklı şirket seçtiyse "POS'ta gördüm" o session'daydı, "AccountsHub" başka session olabilir.

**Doğrulama:**
```sql
SELECT name, company_code FROM customers WHERE LOWER(name) LIKE '%zeynep%';
```
JWT decode → `selectedCompanyCode`. İkisi eşleşmeli.

**Düzeltme:** `UPDATE customers SET company_code='DOĞRU_TENANT' WHERE id=...` — ama bu veri taşıma, dikkat.

### 🟢 #6 — Sprint 8 Frontend Pagination Bug (Az Olası)
[`accounts_list_provider.dart`](project_pos/lib/features/accounts/providers/accounts_list_provider.dart) `_fetch` response parse hatası. `accounts.list` cevabını doğru handle etmiyorsa kayıp kayıt olabilir.

**Doğrulama:** Backend response'unu doğrudan curl ile çek → AccountsHub'a gelmeyen kayıt response'ta var mı?

## Tanı Sırası (Pratik)

```
1. Search box'ı kontrol → query temiz mi?
2. Üst chip → "Tümü" veya "Müşteri" mi?
3. Liste'ye en alta scroll → Z harfi yükleniyor mu?
4. Backend curl → response.items içinde var mı?
5. DB query → is_active, is_deleted, company_code
6. JWT decode → selectedCompanyCode = customer.company_code mi?
```

İlk 3 adım UI'da çözülür (saniyeler). 4-6 backend doğrulaması.

## Sources

- [[entities/accounts-hub-screen]] — master/detail hub yapısı
- [[entities/customer]] + [[entities/customer-account]] — entity şeması
- [[syntheses/sprint-8-implementation-plan-2026-04-26]] §B0 — pagination tasarımı
- [[syntheses/accounts-bugfix-investigation-2026-04-26]] — POS picker vs AccountsList endpoint farklılığı
- [[concepts/hibernate-filter-runtime]] — multi-tenant filter
- Kod: [`accounts_list_provider.dart`](project_pos/lib/features/accounts/providers/accounts_list_provider.dart), [`AccountsListService.java`](pos-product-manager/src/main/java/com/sedcore/finance/service/AccountsListService.java), [`cart_panel.dart`](project_pos/lib/features/pos/widgets/cart_panel.dart)

## Related

- [[concepts/multi-tenant-routing]]
- [[issues/accounts-pagination-missing]] (artık B0, hot-fix limit 50'ye çıkardı)
- [[syntheses/accounts-bugfix-investigation-2026-04-26]] §Bug A
