---
title: Runbook — Yeni Entity + Tablo Eklemek
type: synthesis
source: .claude/runbooks/new-entity.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# Runbook — Yeni Entity + Tablo Eklemek

Önce oku: `reference/multi-tenant.md`, `core/CLAUDE.md`.

---

## 1. Entity Sınıfı

```java
@Entity
@Table(name = "my_table",
       uniqueConstraints = @UniqueConstraint(
           columnNames = {"company_code", "name"}))   // compound — tek kolon YASAK
public class MyEntity extends TOpenSimpleCompanyEntity {
    //                      ↑ filter/companyCode/id/timestamps miras alınır

    @Column(nullable = false, length = 500)
    private String name;

    @ManyToOne(fetch = FetchType.LAZY)   // HER ZAMAN LAZY
    @JoinColumn(name = "parent_id")
    private ParentEntity parent;

    @OneToMany(mappedBy = "myEntity", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ChildEntity> children = new ArrayList<>();

    @Column(name = "is_deleted")
    private Boolean isDeleted = false;

    @Version
    private Long version;   // Optimistic locking
}
```

**YAPMA:**
- `@FilterDef` / `@Filter` tekrar ekleme — superclass'ta var, miras alınır.
- Tek kolon `unique = true` — multi-tenant kırar.
- `FetchType.EAGER` — N+1 sorun.

---

## 2. Repository

```java
@Repository
public interface MyRepository extends BaseDaoRepository<MyEntity, String> {
    // Filter aktif iken companyCode parametresi gereksiz (otomatik eklenir)
    List<MyEntity> findByIsDeletedFalse();
    Optional<MyEntity> findByIdAndIsDeletedFalse(String id);

    // Double-safety için explicit istenirse:
    List<MyEntity> findByCompanyCodeAndIsDeletedFalse(String companyCode);
}
```

---

## 3. DDL — Otomatik

`spring.jpa.hibernate.ddl-auto=create` → tablo startup'ta oluşur. data.sql'de `ALTER TABLE` **yazma**.

Zorunlu kolonlar (parent class'tan otomatik gelir):

```sql
company_code  VARCHAR(8)  NOT NULL
id            VARCHAR(36) PRIMARY KEY
created_at    TIMESTAMP   NOT NULL
updated_at    TIMESTAMP   NOT NULL
create_user   VARCHAR(255)
update_user   VARCHAR(255)
```

---

## 4. Para Alanı

```java
@Column(precision = 15, scale = 2)
private BigDecimal price;   // ❌ double / float KULLANMA
```

---

## 5. JSONB (PostgreSQL)

```java
@JdbcTypeCode(SqlTypes.JSON)
@Column(columnDefinition = "jsonb")
private Map<String, Object> metadata;
```

---

## 6. Seed Data

- **security servisi** → `company`, `role_def`, `user_def`, `user_def_access`, `user_role`, i18n
- **pos-product-manager** → ürün, mağaza, depo, kategori, vb.

pos-product-manager/data.sql'e **kullanıcı/rol INSERT'i EKLEME** — çift insert çakışır.

---

## 7. Checklist

- [ ] `extends TOpenSimpleCompanyEntity`
- [ ] Servis paketi `com.sedcore.{modul}.service.impl` altında
- [ ] Unique constraint compound `(company_code, X)`
- [ ] İlişkiler LAZY
- [ ] Para alanı `BigDecimal(15,2)`
- [ ] `@Version` optimistic locking
- [ ] Soft delete — `isDeleted=true`, fiziksel silme yasak
