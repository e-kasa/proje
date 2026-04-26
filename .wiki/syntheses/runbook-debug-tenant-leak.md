---
title: Runbook — Tenant Sızıntısı Debug
type: synthesis
source: .claude/runbooks/debug-tenant-leak.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# Runbook — Tenant Sızıntısı Debug

Semptom: Başka firmanın kayıtları görünüyor, ya da sorgu tüm firmalardan veri döndürüyor.

---

## Hızlı Kontroller

### 1. Servis Paketi Doğru mu?

AOP pointcut `com.sedcore..service..*` — servis buraya düşmüyorsa filter aktive olmaz.

```bash
# Doğru:
com.sedcore.inventory.service.impl.StoreServiceImpl
com.sedcore.product.service.impl.ProductServiceImpl

# YANLIŞ — paket yok:
com.sedcore.service.impl.*
```

### 2. Entity `TOpenSimpleCompanyEntity` Extend Ediyor mu?

```java
// ✅
public class Store extends TOpenSimpleCompanyEntity { ... }

// ❌ — filter miras alınmaz
public class Store extends TOpenDbEntity { ... }
```

### 3. Entity'de Tekrar @Filter Var mı?

```java
// ❌ YASAK — superclass'taki ile çakışır
@FilterDef(...)
@Filter(...)
@Entity
public class Store extends TOpenSimpleCompanyEntity { ... }
```

### 4. CompanyContext Dolu mu?

Request başında `CompanyContextFilter` ThreadLocal'e yazar.

```java
// Service içinde log:
log.info("CompanyContext: {}", CompanyContext.get());
// null → header gelmemiş / filter çalışmamış
```

### 5. JWT'de `selectedCompanyCode` Var mı?

```bash
# Token'ı decode et
echo $JWT_PAYLOAD | base64 -d | jq '.sessionInstance | fromjson | .userInformation.selectedCompanyCode'
```

### 6. Unique Constraint Compound mu?

`ON CONFLICT DO NOTHING` ile seed atlanıyorsa → unique tek kolon olabilir.

```sql
-- PostgreSQL
\d+ role_def
-- "name_key" UNIQUE ... → YANLIŞ (tek kolon)
-- "(company_code, name)" → DOĞRU
```

---

## Log'larda Aranacaklar

```
CompanyHibernateFilterActivator: filter enabled cpCode=X
  → yoksa AOP pointcut yanlış

Hibernate: ... WHERE company_code in (?)
  → yoksa filter aktif değil, entity extends yanlış

CompanyIsolationViolationException
  → double-safety tetiklendi, controller yanlış companyCode kullanıyor
```

---

## Sık Sebepler

| Sebep | Çözüm |
|-------|-------|
| Servis `com.sedcore.service.*` paketinde | Modül altına taşı: `com.sedcore.{modul}.service.impl` |
| Entity `@Filter` tekrar ekli | Sadece superclass'ta kalsın, entity'den sil |
| Parametre adı `companyCode` | Doğrusu `cpCode` — `CompanyFilterStatics.FILTER_COMPANY` |
| Yazma öncesi `setCompanyCode()` unutulmuş | `entity.setCompanyCode(CompanyContext.get())` |
| `findFirstByUserDef(...)` kullanımı | `findByUserDefAndCompanyCode(...)` |
| Public endpoint tanımlı ama filter aktif | 4 filter listesinin hepsine ekle (bkz. url-routing.md) |

---

## Reproduction Testi

```java
@Test
void testTenantIsolation() {
    // Firma A'da Store ekle
    CompanyContext.set("FIRMAA");
    storeService.create(new StoreRequest("Merkez"));

    // Firma B'den bakmaya çalış
    CompanyContext.set("FIRMAB");
    List<Store> stores = storeService.getAll();
    assertThat(stores).isEmpty();   // ← sızıntı varsa burada failure
}
```

---

## İleri Düzey — PostgreSQL RLS (Sprint 3)

Uygulama katmanı filter'ı atlatılırsa DB seviyesinde double-safety:

```sql
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_policy ON products
  USING (company_code = current_setting('app.current_company_code'));
```
