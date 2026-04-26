---
title: Multi-Tenant (Çoklu Kiracılı Mimari)
tags: [concept, architecture, isolation]
source: C:\Users\Win11\Documents\GitHub\proje\CLAUDE.md
date: 2026-04-25
status: draft
---

# Multi-Tenant

Tek veritabanında birden fazla firma (tenant) kaydının izole tutulması. SEDCORE'da her tablo `company_code` kolonu taşır ve Hibernate `@Filter` ile runtime'da otomatik filtrelenir.

## Uygulama

- `TOpenSimpleCompanyEntity` base class — tüm entity'ler bunu extend eder, `company_code` miras alınır
- `@FilterDef("filterCompany")` — query'lere otomatik `WHERE company_code = :cc` ekler
- [[entities/api-manager]] gateway'den gelen JWT'den `CompanyContext` (ThreadLocal) set edilir
- Unique constraint'ler **compound**: `(company_code, X)` — tek kolon unique yasak

## Scheduled Thread Uyarısı

Cron job'larda thread-local context boş — [[entities/reconcile-scheduled-job]] native query ile tenant listesini çeker + her biri için `CompanyContext.set`/`clear` ile iterate eder.

## Sources

- [[raw/code-refs/2026-04-25-project-root-claude]]
- [[raw/code-refs/2026-04-25-drift-reconciliation-flow]]

## Related

- [[concepts/jwt-auth]]
- [[syntheses/sector-agnostic-architecture]]
