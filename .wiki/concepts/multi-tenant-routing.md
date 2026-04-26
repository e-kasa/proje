---
title: Multi-Tenant İzolasyon — Tek Kaynak (Routing & Filter Detayları)
type: concept
source: .claude/reference/multi-tenant.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# Multi-Tenant İzolasyon — Tek Kaynak

Tenant = firma. Her satırda `company_code` kolonu. Hibernate `@Filter` her sorguya `WHERE company_code IN(:cpCode)` otomatik ekler.

---

## Veri Akışı

```
HTTP Request
  ↓
JwtXUserInfoFilter
  → JWT parse → selectedCompanyCode
  → TOpenContextHolder.set(ctx)   (ThreadLocal)
  ↓
CompanyContextFilter (pos-product-manager)
  → X-Company-Code header → CompanyContext.set(code)
  ↓
CompanyHibernateFilterActivator (AOP @Around)
  → session.enableFilter("filterByCompanyCode")
         .setParameter("cpCode", CompanyContext.get())
  ↓
Tüm find* sorguları: WHERE company_code IN('X') otomatik
  ↓
Service metodu biter → session.disableFilter()
  ↓
Request biter → CompanyContext.clear()
```

---

## companyCode Kaynağı — Tek Doğruluk

**JWT token içinde zaten var.** Controller'da `@RequestHeader("X-Company-Code")` **gereksiz**.

```java
// ❌ GEREKSIZ
public ResponseEntity<?> getAll(@RequestHeader("X-Company-Code") String cc) { ... }

// ✅ DOĞRU — context'ten al
public ResponseEntity<?> getAll() {
    return ResponseEntity.ok(service.getAll());
}

// Yazma işlemi:
entity.setCompanyCode(CompanyContext.get());   // ✅
```

---

## Filter Tanımı — core/TOpenSimpleCompanyEntity

```java
@MappedSuperclass
@FilterDef(
    name = "filterByCompanyCode",                       // CompanyFilterStatics.FILTER_COMPANY
    parameters = @ParamDef(name = "cpCode", type = String.class),
    defaultCondition = "company_code in(:cpCode)"
)
@Filter(name = "filterByCompanyCode", condition = "company_code in(:cpCode)")
public class TOpenSimpleCompanyEntity extends TOpenSimpleDbEntity {
    @Column(name = "company_code", nullable = false, updatable = false, length = 8)
    protected String companyCode;
}
```

### Kritik Kurallar

- Filter adı: `"filterByCompanyCode"` (sabit: `CompanyFilterStatics.FILTER_COMPANY`)
- Parametre adı: **`"cpCode"`** — `"companyCode"` değil!
- Extend eden entity'lere **tekrar eklenmez** — miras yeterli.

```java
// ✅ DOĞRU — miras alınır
@Entity
public class Store extends TOpenSimpleCompanyEntity { ... }

// ❌ YANLIŞ — tekrar ekleme → çakışma
@FilterDef(...)
@Filter(...)
@Entity
public class Store extends TOpenSimpleCompanyEntity { ... }
```

---

## AOP Pointcut — KRİTİK

```java
// ✅ DOĞRU — com.sedcore altındaki tüm modül servisleri
@Around("execution(public * com.sedcore..service..*(..))")
// com.sedcore.inventory.service.impl.StoreServiceImpl ✓
// com.sedcore.product.service.impl.ProductServiceImpl ✓

// ❌ YANLIŞ — böyle paket yok → filter hiç çalışmaz → TÜM firmalar görünür!
@Around("execution(public * com.sedcore.service..*(..))")
```

---

## Repository — companyCode Parametresiz Çalışır

Hibernate filter otomatik eklediği için repository metodlarına `companyCode` parametresi eklemeye **gerek yok**:

```java
// Filter aktifse bunlar otomatik izole:
List<Store> findByIsActiveTrue();    // → + AND company_code IN('X')
Optional<Store> findById(String id); // → + AND company_code IN('X')
```

> Ancak mevcut kod `findByIdAndCompanyCode(...)` şeklinde double-safety kullanıyor — uyumluluk için korunabilir.

---

## Unique Constraint — Compound Zorunlu

Tek kolon `unique = true` → **global unique** → farklı firmalar aynı değeri kullanamaz → multi-tenant kırar.

```java
// ❌ YANLIŞ
@Column(name = "name", unique = true)
private String name;

// ✅ DOĞRU
@Table(name = "my_table",
       uniqueConstraints = @UniqueConstraint(columnNames = {"company_code", "name"}))
```

**Gerçek hata (2026-04-13):** `RoleDef.name unique=true` → SEDCORE1 rolleri `ON CONFLICT DO NOTHING` ile atlandı → FK violation. Çözüm: `(company_code, name)` compound.

---

## UserDefAccess — Multi-Tenant Sorgu

```java
// ✅ Login dahil tüm durumlarda — aynı user farklı firmalarda erişime sahip olabilir
userDefAccessRepository.findByUserDefAndCompanyCode(user, user.getCompanyCode());

// ❌ IncorrectResultSizeDataAccessException riski
userDefAccessRepository.findByUserDef(user);
userDefAccessRepository.findFirstByUserDef(user);  // sadece companyCode bilinmediğinde fallback
```

---

## Yeni Entity Eklerken Checklist

```java
// 1. TOpenSimpleCompanyEntity extend et — filter miras alınır
@Entity
public class MyEntity extends TOpenSimpleCompanyEntity { ... }

// 2. Servis paketi com.sedcore.{modul}.service altında olsun
package com.sedcore.mymodule.service.impl;  // ✓ AOP yakalar
package com.sedcore.service.impl;           // ❌ böyle paket yok

// 3. Unique constraint → compound
@Table(uniqueConstraints = @UniqueConstraint(columnNames = {"company_code", "name"}))

// 4. Yazma işlemi → CompanyContext.get()
entity.setCompanyCode(CompanyContext.get());
```

---

## Exception

```java
// Tenant sızıntısı tespit edilirse:
throw new CompanyIsolationViolationException("Yetkisiz erişim");  // → HTTP 403
```

---

## Debug İpuçları

Tenant sızıntısı şüphesi varsa: `runbooks/debug-tenant-leak.md`
