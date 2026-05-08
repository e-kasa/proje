---
title: Customer/Supplier Activity Log Yok (RESOLVED)
tags: [issue, resolved, audit]
date: 2026-04-25
resolved: 2026-05-06
status: resolved
priority: low
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\syntheses\accounts-hub-production-readiness.md
---

# Activity History Missing (P2.6) — RESOLVED

Customer/Supplier düzenlemelerinin tarihsel kaydı yok. "creditLimit'i geçen hafta kim değiştirdi?" cevabı yok.

## Çözüm — Sprint 30 (Custom AuditLog)

Hibernate Envers yerine **hafif custom tablo** seçildi: tüm `_AUD` tabloları yerine tek `account_audit_logs` + entity tipi diskriminatörü. Trade-off: transparent rollback yok; gainz: tek migration, sade okuma, "X kullanıcısı creditLimit'i 5000→10000 yaptı" sorgusu kolay.

| Bileşen | Konum |
|---|---|
| `AccountAuditLog` entity | [`finance/entity/AccountAuditLog.java`](pos-product-manager/src/main/java/com/sedcore/finance/entity/AccountAuditLog.java) |
| `AccountAuditAction` enum | CREATE / UPDATE / DELETE / RESTORE |
| `AccountAuditEntityType` enum | CUSTOMER / SUPPLIER |
| `AccountAuditLogRepository` | findByEntityTypeAndEntityIdOrderByCreateTimeDesc |
| `AccountAuditService` | recordFieldChange / recordFieldChanges / recordCreate / recordDelete |
| `AccountAuditControllerImpl` | `GET /api/v1/audit/customer/{id}` + `/supplier/{id}` |
| Hook (örnek) | `CustomerServiceImpl.updateCreditLimit` |

**Tasarım kararları**:
- Bir update operasyonu N alan değiştiriyorsa N satır yazılır (tek satır = tek field değişikliği)
- Eski/yeni eşitse no-op (log spam'i önler)
- 1024 karakteri aşan değer kısaltılır
- `companyCode` + `createUser` + `createTime` `BaseDbServiceImp` dışında kaldığı için `persist()` helper'da elle setleniyor (CompanyContext + SecurityContextHolder)

## Test Coverage

[`AccountAuditServiceTest`](pos-product-manager/src/test/java/com/sedcore/finance/service/AccountAuditServiceTest.java) — 9 test:
- Tek alan değişikliği persist
- Eşit değer no-op
- Çoklu alan toplu yazım + eşit olanları atla
- CREATE / DELETE özet kaydı
- Sıralama (createTime DESC)
- 1024 karakter kısaltma
- Farklı entity tiplerinin segregation
- Null entityId/fieldName için no-op

## Kullanım

```bash
curl -H "X-Company-Code: SEDCORE" \
     http://localhost:8001/product/api/v1/audit/customer/abc-123
# → {"items":[
#     {"createTime":"2026-05-06...", "createUser":"admin",
#      "action":"UPDATE", "fieldName":"creditLimit",
#      "oldValue":"5000", "newValue":"10000"},
#     ...
#   ]}
```

## Sonraki Adımlar (Sprint 31+)

- Frontend AccountEditForm'a "Geçmiş" sekmesi (read-only timeline)
- Diğer hassas alanlar için hook ekle: `riskStatus`, `paymentTermDays`, `name`, `taxNumber`
- Supplier tarafına paralel hook (`SupplierServiceImpl.updateCreditLimit` zaten benzer pattern)
- DELETE/RESTORE hook'ları (soft delete kullanılırsa)

## Sources

- [[raw/code-refs/2026-04-25-accounts-hub-production-readiness]]

## Related

- [[entities/customer]]
- [[entities/supplier]]
- [[entities/reconcile-audit-log]] — paralel patern (drift)
