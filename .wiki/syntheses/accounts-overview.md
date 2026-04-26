---
title: Cari Hesaplar (Accounts) — Genel Bakış
type: synthesis
source: .claude/wiki/syntheses/accounts-overview.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Cari Hesaplar (Accounts) — Genel Bakış

SEDCORE POS'ta müşteri ve tedarikçi cari hesap ekosisteminin uçtan uca haritası. 4 katman, 3 temel flow, 1 drift risk yönetimi.

## Katmanlar

### 1. Ledger Katmanı (Source of Truth)
- [[entities/account-transaction]] — append-only, is_cancelled flag, customer/supplier FK
- Her ekonomik hareket burada: satış → debit, ödeme → credit, iade → ters kayıt

### 2. Denormalize Katmanı (Cache)
- [[entities/customer-account]] — currentBalance, totalDebt, totalCredit, overdueAmount, @Version
- [[entities/supplier-account]] — simetrik, işaret konvansiyonu ters

### 3. Master Data
- [[entities/customer]] — name, creditLimit, 1:1 CustomerAccount LAZY
- [[entities/supplier]] — aynı yapı
- [[entities/payment]] — tahsilat/ödeme, customerId XOR supplierId

### 4. UI Katmanı (Flutter)
- `AccountsHubScreen` — 3 panel: summary bar + list + detail
- [[syntheses/flow-accounts-hub-load]] — data çağrısı zinciri
- [[syntheses/flow-today-collection-calc]] — client-side filter

## Temel Flow'lar

1. **[[syntheses/flow-accounts-hub-load]]** — ekran açılışı, liste + özet + detay
2. **[[syntheses/flow-today-collection-calc]]** — bugünkü tahsilat kartı
3. **[[syntheses/flow-drift-reconciliation]]** — denormalize ↔ ledger senkronizasyon

## Mimari Pattern'lar

- **[[concepts/pattern-denormalization-with-reconcile]]** — tüm hikayenin özü
- **[[concepts/pattern-entity-graph-n-plus-one]]** — LAZY account fetch optimizasyonu
- **[[concepts/pattern-dto-tomap-pattern]]** — controller inline Map çıktısı

## Kritik Kararlar

- [[decisions/ledger-as-source-of-truth]] — ledger doğru, denormalize düzeltilir
- [[decisions/idempotent-reconcile-no-op-guard]] — drift yoksa save yok
- [[decisions/manual-reconcile-before-scheduled]] — scheduled'dan önce operator gözlem
- [[decisions/db-side-aggregate-over-java-loop]] — SUM DB tarafında
- [[decisions/rename-balance-to-currentbalance]] — supplier DTO simetrisi
- [[decisions/use-entity-graph-for-customer-account-fetch]] — LAZY fetch stratejisi

## Geçmiş Buglar (hepsi çözüldü)

- [[issues/today-collection-always-zero]] — Flutter alan adı uyumsuzluğu
- [[issues/customer-list-balance-zero]] — toMap eksik alan
- [[issues/supplier-list-balance-zero]] — DTO field adı yanlış
- [[issues/n-plus-one-customer-account-fetch]] — @EntityGraph eksikti

## Açık Konular

- [[issues/admin-endpoint-no-preauthorize]] — reconcile endpoint'i rol koruması yok (prod öncesi zorunlu)
- [[issues/overdue-amount-not-reconciled]] — reconcile kapsamında overdueAmount yok
- Scheduled reconcile job (henüz yok)
- Prometheus drift metric (gelecek sprint)

## Kaynak Oturumlar

- [[sources/code-refs/2026-04-24-drift-reconcile]] — backend impl
- [[sources/code-refs/2026-04-22-accounts-hub-perf]] — toMap + @EntityGraph
- [[sources/code-refs/2026-04-21-accounts-hub-screens]] — Flutter ekranlar

## Related

- [[syntheses/denormalization-strategy]]
