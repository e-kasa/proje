---
title: Pattern — Optimistic Lock @Version (detailed merge from .claude/wiki/)
type: concept
source: .claude/wiki/patterns/optimistic-lock-version.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
note: "MERGE_NEEDED — overlap with .wiki/concepts/optimistic-lock-version.md (similar topic). This version has SEDCORE entity table + retry strategy code."
---

# Optimistic Lock @Version Pattern

## Problem
Aynı entity satırı iki paralel transaction tarafından güncellenirse son yazan önceki yazımı sessizce ezer (lost update). Örnek: Satış + Ödeme aynı anda müşteri bakiyesini değiştirir → bakiye tutarsız kalır.

## Çözüm
Entity'ye `@Version` alanı eklenir. Hibernate her `UPDATE` SQL'ine `WHERE version = ?` ekler; eşleşmezse `OptimisticLockException` fırlatır.

```java
@Version
@Column(name = "version")
private Long version;
```

## SEDCORE'da Kullanım Yerleri

| Entity | Neden | Notlar |
|---|---|---|
| [[entities/customer-account]] | Concurrent sale + payment | Denormalize bakiye koruması |
| [[entities/supplier-account]] | Simetrik | |
| [[entities/stock-level]] | Concurrent sale + transfer (aynı variant × location) | Kritik — stok tutarsızlığı olmasın; primary lock pessimistic |
| [[entities/account-transaction]] | Defense-in-depth (2026-04-24 ADR revize) | Append-only + soft cancel UPDATE'lerde aktif |
| [[entities/stock-movement]] | Aynı — append-only, @Version import edilmiş | Tartışmalı |

## Ne Zaman Kullanılır

- Mutable entity (update sık) + concurrent yazım beklenen: `CustomerAccount`, `StockLevel`
- Denormalize özet alanlar (lost update kritik): balance, quantity
- **Append-only tablolar**: SEDCORE'da yine de eklenmiş — defense-in-depth (soft cancel UPDATE'lerini koruyor)

## Retry Stratejisi

OptimisticLockException yakalandığında üst katman retry etmeli:

```java
int maxRetry = 3;
while (true) {
  try {
    return operation(); // fresh fetch + update
  } catch (OptimisticLockException e) {
    if (--maxRetry == 0) throw e;
  }
}
```

SEDCORE'da retry merkezi utility **yok** — her callsite kendi sorumluluğu (iyileştirme aday).

## İzleme

Drift oluşursa optimistic lock yerine [[syntheses/flow-drift-reconciliation]] düzeltir. Lock sadece **anlık** koruma, drift = cumulative sapma — ikisi farklı soruna cevap.

## Trade-off

- Lost update önlenir
- Pessimistic lock'tan hızlı (DB lock yok)
- Retry karmaşıklığı client/service katmanında
- Hot entity (çok yazılan) high contention → throughput düşüşü — pessimistic'e geçiş gerekebilir

## Related

- [[entities/customer-account]]
- [[entities/supplier-account]]
- [[entities/stock-level]]
- [[concepts/write-through-cache]]
- [[decisions/trust-reconcile-no-ledger-version]]
- [[concepts/pattern-denormalization-with-reconcile]]
