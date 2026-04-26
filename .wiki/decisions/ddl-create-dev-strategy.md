---
title: Karar — DDL=create (Dev), Update Prod'a Ertelendi
tags: [decision, database, ddl]
date: 2026-04-25
status: accepted
source: C:\Users\Win11\Documents\GitHub\proje\CLAUDE.md
---

# DDL=create Dev Stratejisi

## Karar

`spring.jpa.hibernate.ddl-auto=create` geliştirme ortamında. Her başlatmada schema drop + recreate; data.sql seed her zaman çalışır.

## Gerekçe

- Entity değişiklikleri otomatik yansır (manuel migration yok)
- Seed yenilenir → bilinen state
- Prod'a çıkışta `update` veya Flyway/Liquibase migration'a geçiş planlı

## Trade-off

- ✅ Hızlı iterasyon
- ❌ Local data kaybı her restart
- ❌ Prod'da kullanılamaz

## Sources

- [[raw/code-refs/2026-04-25-project-root-claude]]

## Related

- [[entities/pos-product-manager]]
