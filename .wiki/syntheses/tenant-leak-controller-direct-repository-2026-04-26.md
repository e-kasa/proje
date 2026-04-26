---
title: 🚨 Multi-Tenant Leak — Controller'dan Direkt Repository Erişimi (2026-04-26) [DEPRECATED]
type: synthesis
date: 2026-04-26
status: deprecated
severity: archived
sprint: 8 hot-fix v3 (REVERTED)
superseded-by: concepts/multi-company-per-user-architecture
purpose: bu sayfa yanlış yoruma dayalı — gerçekte sistem multi-firma per-user, "tenant leak" değil intentional design
---

> ⚠️ **DEPRECATED** — Bu sayfanın yorumu YANLIŞ. Kullanıcı 2026-04-26'da düzeltti: "sistemimizde firma bazlı arama yapılır" — yani SEDCORE+SEDCORE1 karışık dönmesi tenant leak değil, intentional design.
>
> **Doğru bağlam:** [[concepts/multi-company-per-user-architecture]]
>
> Hot-fix v3 (`CustomerService.search` + `CustomerControllerImpl` service yönlendirmesi) `git checkout HEAD --` ile **revert edildi**.

# 🚨 Multi-Tenant Leak — Controller→Repository Direkt Erişim [YANLIŞ YORUM]

## Kritik Bulgu (Production Risk)

`GET /product/api/v1/customers?isActive=true` endpoint'i **2 farklı tenant'tan** kayıt döndürüyor (kullanıcı paylaşımı 2026-04-26 16:24):

```json
"data": [
  {"name": "Usta Oto Servis Ltd.", "companyCode": "SEDCORE",  ...},
  {"name": "Moda Butik A.S.",      "companyCode": "SEDCORE1", ...},   ← LEAK
  {"name": "Adem Caliskan",        "companyCode": "SEDCORE",  ...},
  {"name": "Zeynep Yilmaz",        "companyCode": "SEDCORE1", ...}    ← LEAK
]
```

Karşılaştırma — `GET /product/api/v1/accounts/list` aynı oturumda **sadece SEDCORE** kayıtları döndürdü (4 SEDCORE only). İki endpoint **aynı `customerRepository.search(null, true)`** kullanıyor. Fark: çağrının tetikleme yolu.

## Kök Neden — AOP Pointcut Bypass

[[concepts/hibernate-filter-runtime]] §Critical Bulgular #4 ("NPE yok ama sessiz tenant leak") gerçekleşti:

> `CompanyHibernateFilterActivator` `@Around` advice pointcut: `com.sedcore..service..*` — **sadece service layer**'da bean method invocation'ında tetiklenir. CompanyContext set edilir + Hibernate session'a `enableFilter("filterByCompanyCode", ...)` aktif edilir. Repository çağrısı bu session'da filter ile çalışır.
>
> Controller'dan **doğrudan repository** erişimi → service bean method invocation yok → AOP advice tetiklenmez → filter aktif edilmez → query tüm tenant'lara açık.

### İki Çağrı Yolu

```
✅ AccountsHub akışı:
   Controller → AccountsListService.list() [@Service, AOP pointcut match]
              → CompanyHibernateFilterActivator @Around aktive
              → session.enableFilter("filterByCompanyCode", cpCode=SEDCORE)
              → customerRepository.search(null, true)  [filter aktif]
              → SEDCORE kayıtları (4 satır) ✅

❌ POS Cart Panel akışı:
   Controller → customerRepository.search(null, true)  [DIRECT, AOP pointcut match YOK]
              → filter aktif değil
              → tüm tenant kayıtları (4 satır SEDCORE+SEDCORE1) ❌ LEAK
```

## Uygulanan Düzeltme (Hot-Fix v3) — Yalnız `list` Endpoint

### F1 — `CustomerService.search()` Method Eklendi
[`CustomerService.java`](pos-product-manager/src/main/java/com/sedcore/customer/service/CustomerService.java):
```java
List<Customer> search(String q, Boolean isActive);
```

[`CustomerServiceImpl.java`](pos-product-manager/src/main/java/com/sedcore/customer/service/impl/CustomerServiceImpl.java):
```java
@Override @Transactional(readOnly = true)
public List<Customer> search(String q, Boolean isActive) {
    return dao.search(q, isActive);  // service-layer call → AOP filter aktif
}
```

### F2 — `CustomerControllerImpl.list()` Service'e Yönlendirildi
[`CustomerControllerImpl.java:49`](pos-product-manager/src/main/java/com/sedcore/customer/controller/impl/CustomerControllerImpl.java#L49):
```diff
- List<Customer> rows = customerRepository.search(search, isActive);
+ List<Customer> rows = customerService.search(search, isActive);
```

### Verification
- Backend Maven compile: **exit 0** ✅
- **Beklenen davranış:** Backend restart sonrası `GET /customers?isActive=true` artık sadece JWT'deki `selectedCompanyCode` tenant'ının kayıtlarını döndürür.

## Kalan Riskler (Sprint 9 — Acil Audit Gerekli)

`grep -rn "Repository\." src/main/java --include="*ControllerImpl.java"` taraması ile **5+ controller** hâlâ direkt repository erişiyor:

| Dosya | Satır | Method | Risk |
|---|---|---|---|
| [`CustomerControllerImpl.java`](pos-product-manager/src/main/java/com/sedcore/customer/controller/impl/CustomerControllerImpl.java) | 71, 114, 145, 165 | `customerRepository.findById(id)` | **Yüksek** — başka tenant ID ile direkt erişim açık |
| `CustomerControllerImpl.java` | 187-189 | `customerRepository.countBy*` | Orta — count tüm tenant toplar |
| [`SupplierControllerImpl.java`](pos-product-manager/src/main/java/com/sedcore/supplier/controller/impl/SupplierControllerImpl.java) | 156-159 | `supplierRepository.countBy*` | Orta |
| [`AccountStatementControllerImpl.java`](pos-product-manager/src/main/java/com/sedcore/finance/controller/impl/AccountStatementControllerImpl.java) | 55-56, 135 | `accountTransactionRepository.findCustomerStatement/findOverdue` | **Yüksek** — başka tenant ekstresi açık |
| [`AccountStatementPdfControllerImpl.java`](pos-product-manager/src/main/java/com/sedcore/finance/controller/impl/AccountStatementPdfControllerImpl.java) | 153-158 | aynı | **Yüksek** |
| [`StockMovementControllerImpl.java`](pos-product-manager/src/main/java/com/sedcore/inventory/controller/impl/StockMovementControllerImpl.java) | 69-71, 101, 122, 155 | `stockMovementRepository.find*`, `variantRepository.findById` | Orta — `findByCompanyCode` parametresi explicit; ama `findById` filter'sız |
| [`StockTransferControllerImpl.java`](pos-product-manager/src/main/java/com/sedcore/inventory/controller/impl/StockTransferControllerImpl.java) | 41 | `stockTransferRepository.findByFromLocationId` | Orta |

## Sistemik Çözüm Seçenekleri (Sprint 9)

### Seçenek A — AOP Pointcut Genişlet (önerilen)
[`CompanyHibernateFilterActivator`](pos-product-manager/src/main/java/com/sedcore/common/aspect/CompanyHibernateFilterActivator.java) pointcut'ına controller layer ekle:
```java
@Around("execution(* com.sedcore..service..*(..)) || execution(* com.sedcore..controller..*(..))")
```
**Avantaj:** Tüm controller'lar otomatik korunur, code change minimum.
**Dezavantaj:** Aspect overhead her controller method'a eklenir (perf etkisi ölçülmeli).

### Seçenek B — Controller'larda Service Layer Zorla
Tüm controller'lar repository'ye direkt erişmek yerine service'e gitsin. Service interface'lere eksik method'lar eklenmeli (search, findById, count*).
**Avantaj:** Mimari temiz (separation of concerns). DDD pattern.
**Dezavantaj:** ~10+ method eklenmeli, refactor 1-2 gün.

### Seçenek C — Manual `CompanyContext.get()` Filter
Her repository metodunda `WHERE company_code = :cc` JPQL parametresi.
**Avantaj:** Fully explicit, AOP riskleri yok.
**Dezavantaj:** Boilerplate her query'de, hata payı yüksek (unutulması ölümcül).

**Öneri:** A + B kombinasyonu — pointcut genişletme acil mitigation, sonra B ile temiz mimari.

## Acil Aksiyonlar

### Hemen (sen, restart sonrası test)
1. `GET /customers?isActive=true` artık tenant izolasyonu doğru mu?
   - Backend restart
   - JWT SEDCORE → response sadece SEDCORE
   - JWT SEDCORE1 → response sadece SEDCORE1 (Zeynep + Moda Butik)

2. **POS satış ekranındaki Zeynep**: SEDCORE1 tenant'ında oluşturuldu, ama POS oturumu SEDCORE'daydı (leak ile gösteriyordu). Hot-fix sonrası:
   - SEDCORE oturumunda → Zeynep **artık görünmeyecek** (doğru davranış)
   - SEDCORE1 oturumunda → Zeynep görünür + AccountsHub'da da görünür

### Sprint 9 (acil)
- Yukarıdaki 7 dosya/13 callsite'ı audit edip Seçenek A veya B uygula
- Penetration test: cross-tenant ID erişimi blok mu?
- `[[issues/tenant-leak-controller-direct-repository.md]]` issue oluştur (P0)

## Sources

- Kullanıcı kanıt: backend response 2026-04-26 16:24 (`/customers?isActive=true` 4 kayıt — 2 SEDCORE + 2 SEDCORE1)
- Karşıt kanıt: `/accounts/list` aynı oturumda 4 SEDCORE only (2026-04-26 16:19)
- [[concepts/hibernate-filter-runtime]] §Critical Bulgular #4 (NPE yok sessiz tenant leak — Sprint 7 Faz 4 ingest araştırması)
- [[concepts/multi-tenant-routing]] — gateway header → CompanyContext akışı
- Kod: [`CustomerControllerImpl`](pos-product-manager/src/main/java/com/sedcore/customer/controller/impl/CustomerControllerImpl.java), [`CustomerService`](pos-product-manager/src/main/java/com/sedcore/customer/service/CustomerService.java), [`AccountsListService`](pos-product-manager/src/main/java/com/sedcore/finance/service/AccountsListService.java)

## Related

- [[syntheses/zeynep-customer-not-in-db-2026-04-26]] (önceki tanı — DB'de yok hipotezi çürüdü; gerçekte DB'de var ama farklı tenant)
- [[concepts/troubleshooting-customer-missing-in-accounts-hub]]
- [[issues/admin-endpoint-no-preauthorize]] (benzer security pattern: defense-in-depth eksikliği)
- [[concepts/defense-in-depth]]
