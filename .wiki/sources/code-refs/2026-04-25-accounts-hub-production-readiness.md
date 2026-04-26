---
title: Cari Hesap Hub Üretim Hazırlık Gap Analizi
tags: [source, accounts, production, gap-analysis, roadmap]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\syntheses\accounts-hub-production-readiness.md
raw: "[[raw/code-refs/2026-04-25-accounts-hub-production-readiness]]"
date: 2026-04-25
status: draft
---

# Cari Hesap Hub Üretim Hazırlık İngest Özeti

## Amaç

Cari Hesaplar (AccountsHub) modülünün production'a çıkış öncesi hazır olmadığı konuları 3 öncelik katmanında tespit etmek; her maddeyi takip edilebilir aksiyonla kapatmak.

## Ne Yapıldı

P0-P1-P2 matrisi ile ~15 madde listelendi. 2026-04-24 ile 2026-04-25 arasında P0'ların hepsi ve P1/P2'lerin çoğu kapatıldı.

## Değişenler / Kapsam

- **P0 (Prod Gate)** ✅ Hepsi RESOLVED:
  - @PreAuthorize admin endpoint koruması
  - [[entities/reconcile-audit-log]] + REQUIRES_NEW propagation
  - [[decisions/ledger-concurrency-defense-in-depth]] (A+D)
  - `overdueAmount` reconcile 5-aggregate
- **P1 (Operasyonel)** — P1.1, P1.2, P1.4 RESOLVED; P1.3 (pagination) ve P1.5 (error boundary) açık
- **P2 (Disiplin + UX)** — P2.3 (PDF+email), P2.5 (credit limit) RESOLVED; P2.4 (notification), P2.6 (activity), P2.7 (test coverage) açık

## Alınan Kararlar

- [[decisions/ledger-concurrency-defense-in-depth]]
- [[decisions/credit-limit-override-role-based]]
- [[decisions/pdf-backend-over-client]]
- [[decisions/openapi-incremental-migration]]

## Karşılaşılan Sorunlar

- [[issues/admin-endpoint-no-preauthorize]] → resolved
- [[issues/overdue-amount-not-reconciled]] → resolved

## Açık Konular

- [[issues/accounts-pagination-missing]] (P1.3)
- [[issues/accounts-error-boundary-missing]] (P1.5)
- [[issues/overdue-notification-missing]] (P2.4)
- [[issues/activity-history-missing]] (P2.6)
- [[issues/test-coverage-unknown]] (P2.7)

## Sources

- `.claude/wiki/syntheses/accounts-hub-production-readiness.md`
- [[raw/code-refs/2026-04-25-accounts-hub-production-readiness]]

## Related

- [[syntheses/accounts-module-overview]]
- [[concepts/drift]]
- [[concepts/denormalization-with-reconcile]]
