---
title: ReconcileAuditLog (detailed merge from .claude/wiki/)
type: entity
source: .claude/wiki/entities/reconcile-audit-log.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
note: "MERGE_NEEDED — .wiki/entities/reconcile-audit-log.md is brief; this verified version has full field details + write behavior + SQL example."
---

# ReconcileAuditLog

## Amaç
[[syntheses/flow-drift-reconciliation]] çağrılarının denetim kaydı. Her reconcile (drift olsun olmasın) bir satır üretir — "kim, ne zaman kontrol etti, sapma neydi" sorusu için audit trail.

## Kritik Alanlar

| Alan | Tip | Anlam |
|---|---|---|
| scope | enum | SINGLE (tek hesap) \| ALL (sweep özeti) |
| entityType | enum | CUSTOMER \| SUPPLIER |
| accountId | String(36) | SINGLE için müşteri/tedarikçi ID; ALL için null |
| balanceBefore | BigDecimal(15,2) | Reconcile öncesi denormalize bakiye |
| balanceAfter | BigDecimal(15,2) | Reconcile sonrası (değişmediyse balanceBefore ile aynı) |
| driftAmount | BigDecimal(15,2) | previous − ledger (0 ise no-op) |
| debtBefore/After | BigDecimal(15,2) | totalDebt snapshot |
| creditBefore/After | BigDecimal(15,2) | totalCredit snapshot |
| correctionCount | Integer | SINGLE: 0 (drift yok) veya 1; ALL: toplam düzeltilen hesap sayısı |

Base class alanları (`TOpenSimpleCompanyEntity`):
- `createUser` — reconcile'ı tetikleyen kullanıcı
- `createTime` — ne zaman
- `companyCode` — otomatik tenant filtresi

## Yazım Davranışı

- **Her reconcile çağrısı** (`reconcile(id)`) → 1 SINGLE satır. Drift yoksa `correctionCount=0, driftAmount=0`, before=after.
- **Her reconcileAll çağrısı** → N SINGLE satır (her iterasyon) + 1 ALL sweep özet satırı.
- `ReconcileAuditServiceImpl` **`@Transactional(propagation = REQUIRES_NEW)`** — asıl reconcile rollback olsa bile audit log korunur.

## Tuzaklar

- `@Version` YOK — audit log append-only semantiği; iki-paralel yazım çakışmaz (farklı PK)
- `correctionCount` field adı iki anlam taşır: SINGLE için düzeltildi mi (0/1), ALL için toplam. Kafa karışıklığı için `scope` kontrolü gerekir
- ALL sweep özet kayıtta `accountId=null` — sorgu yazanların dikkat etmesi gerek (IS NULL filtresi)

## Kullanım Örneği (sorgu)

```sql
-- Son 7 gün, drift tespit edilmiş müşteri reconcile'ları
SELECT account_id, drift_amount, create_user, create_time
FROM reconcile_audit_logs
WHERE scope = 'SINGLE'
  AND entity_type = 'CUSTOMER'
  AND drift_amount <> 0
  AND create_time > NOW() - INTERVAL '7 days'
ORDER BY create_time DESC;
```

## Sources

- pos-product-manager/src/main/java/com/sedcore/finance/entity/ReconcileAuditLog.java
- pos-product-manager/src/main/java/com/sedcore/finance/service/ReconcileAuditService.java
- pos-product-manager/src/main/java/com/sedcore/finance/service/impl/ReconcileAuditServiceImpl.java
- [[decisions/trust-reconcile-no-ledger-version]]

## Related

- [[syntheses/flow-drift-reconciliation]]
- [[entities/customer-account]]
- [[entities/supplier-account]]
- [[entities/account-transaction]]
- [[concepts/drift]]
- [[concepts/pattern-denormalization-with-reconcile]]
