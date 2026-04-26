---
title: Ledger Concurrency ADR (A+D Defense-in-Depth)
tags: [source, adr, concurrency, optimistic-lock, ledger]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\decisions\2026-04-24-ledger-no-version-accept-reconcile-guard.md
raw: "[[raw/code-refs/2026-04-25-ledger-version-adr]]"
date: 2026-04-25
status: draft
---

# Ledger Concurrency ADR İngest Özeti

## Amaç

`AccountTransaction` (ledger) için concurrent write koruması stratejisini kararlaştırmak. İlk versiyon "sadece reconcile" (D), revize versiyon "@Version + reconcile" (A+D) defense-in-depth.

## Ne Yapıldı

ADR iki iterasyon geçirdi:
- **İlk**: Sprint 1 yazımı — "@Version eklenmeyecek, reconcile yeterli"
- **Revize**: Sprint 2 tespit — AccountTransaction.java:122-124'te `@Version` zaten vardı; kod gerçeğine göre ADR yeniden yazıldı. Karar **A+D**: @Version runtime lost-update + reconcile kümülatif drift düzeltme.

## Değişenler / Kapsam

- **Entity**: [[entities/account-transaction]] — `@Version` alanı (122-124)
- **Service**: reconcile metodu (customer/supplier) — 5-aggregate + audit
- **Concept**: [[concepts/defense-in-depth]] — iki bağımsız savunma katmanı
- **Contradiction**: önceki çelişki (`contradictions.md` 2026-04-24) → resolved

## Alınan Kararlar

- [[decisions/ledger-concurrency-defense-in-depth]] — A+D birleşik (tek sayfa olarak belgelendi)
- [[concepts/append-only]] — logical append-only (soft cancel UPDATE'leri @Version'ın hedefi)

## Karşılaşılan Sorunlar

- Önceki contradictions.md girdisi (ADR vs kod) → resolved

## Açık Konular

- Prod'da `OptimisticLockException` oranı ölçümü (client retry utility gerekir mi?)
- Drift insidansı > %1 olursa B (pessimistic) gündeme gelir

## Sources

- `.claude/decisions/2026-04-24-ledger-no-version-accept-reconcile-guard.md`
- `pos-product-manager/src/main/java/com/sedcore/finance/entity/AccountTransaction.java` (L122-124)
- [[raw/code-refs/2026-04-25-ledger-version-adr]]

## Related

- [[concepts/optimistic-lock-version]]
- [[concepts/append-only]]
- [[concepts/defense-in-depth]]
- [[concepts/drift]]
