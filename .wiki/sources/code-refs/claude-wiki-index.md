---
title: Wiki Index (MOC) — claude-wiki
type: source
source: .claude/wiki/index.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# SEDCORE POS — Wiki İndeksi (claude-wiki)

Kümülatif bilgi arşivi giriş noktası. Yeni sayfa eklendikçe burası güncellenir.

> **Önce oku**: [[CLAUDE]] — proje context / [[README]] — ajan protokolü

## Genel

- [[glossary]] — terim sözlüğü
- [[contradictions]] — çelişen bilgi kayıtları
- [[log]] — append-only event log
- [[lint-report]] — sağlık taraması (2026-04-24)

## Operasyonlar

- `/wiki-ingest <kaynak>` — yeni kaynak entegrasyonu
- `/wiki-query <soru>` — wiki sorgusu (sentezler geri-dosyalanır)
- `/wiki-lint [gün]` — sağlık kontrolü

## Sources (İşlenen Kaynaklar)

- [[sources/code-refs/2026-04-24-drift-reconcile]] — drift reconcile backend
- [[sources/code-refs/2026-04-22-accounts-hub-perf]] — AccountsHub DB aggregates + @EntityGraph
- [[sources/code-refs/2026-04-21-accounts-hub-screens]] — Flutter accounts ekranları
- [[sources/code-refs/2026-04-23-batch-entry-4area]] — batch-entry UX
- [[sources/code-refs/2026-04-17-units-employee-modern]] — Flutter modernizasyon

## Entities (Domain Modelleri)

- [[entities/customer-account]] — müşteri denormalize bakiye
- [[entities/supplier-account]] — tedarikçi denormalize bakiye
- [[entities/account-transaction]] — ledger (source of truth)
- [[entities/customer]] — müşteri master
- [[entities/supplier]] — tedarikçi master
- [[entities/payment]] — tahsilat/ödeme
- [[entities/reconcile-audit-log]] — reconcile denetim kaydı
- [[entities/stock-level]] — variant × location anlık stok (W2)
- [[entities/stock-movement]] — stok hareket log (W2)
- [[entities/sale]] — satış kaydı (W2 Sales)
- [[entities/sale-item]] — satış satır kalemi (W2 Sales)
- [[entities/vehicle]] — araç kataloğu (autoparts)
- [[entities/store]] — mağaza lokasyon master (W2 Inventory)
- [[entities/warehouse]] — depo lokasyon master (W2 Inventory)
- [[entities/stock-transfer]] — lokasyonlar arası transfer (W2 Inventory)
- [[entities/purchase]] — satın alma kaydı (W2 Purchase)
- [[entities/supplier-claim]] — eksik teslimat talebi (W2 Purchase)
- Açılacak: `product`, `product-variant`

## Concepts (Soyut Kavramlar)

- [[concepts/ledger-vs-denormalize]] — iki katman ayrımı
- [[concepts/drift]] — denormalizasyon sapması
- [[concepts/write-through-cache]] — yazım anında güncelleme pattern'i

## Flows (Uçtan Uca Akışlar)

- [[flows/drift-reconciliation]] — denormalize ↔ ledger senkron
- [[flows/accounts-hub-load]] — AccountsHub açılış zinciri
- [[flows/today-collection-calc]] — bugünkü tahsilat filter
- [[flows/batch-entry]] — toplu ürün girişi (UI → purchase-checkout)
- [[flows/sale-checkout]] — satış oluşturma (ledger input #1, W2 Sales)
- [[flows/stock-transfer]] — lokasyonlar arası stok transferi (W2 Inventory)
- [[flows/purchase-checkout]] — satın alma akışı (ledger input #2, W2 Purchase)
- [[flows/pdf-statement-export]] — server-side PDF ekstre (Sprint 5, P2.3)

## Patterns (Mimari Desenler)

- [[patterns/denormalization-with-reconcile]] — cache + periyodik audit
- [[patterns/entity-graph-n-plus-one]] — LAZY fetch optimizasyonu
- [[patterns/dto-tomap-pattern]] — controller inline Map çıktısı (deprecated-candidate, Sprint 4)
- [[patterns/scoped-feature-wiki]] — iki-katmanlı wiki hiyerarşisi (meta)
- [[patterns/optimistic-lock-version]] — @Version concurrency
- [[patterns/base-entity-list-screen]] — Flutter list ekranı
- [[patterns/openapi-codegen-flutter]] — typed client codegen (Sprint 4)
- Açılacak: `multi-tenant-filter`, `soft-delete-with-unique`

## Integrations (Dış Servisler)

- [[integrations/prometheus-micrometer]] — metrics export (Sprint 3)
- [[integrations/slack-webhook]] — alert notification (Sprint 3)
- Açılacak: `postgresql-multitenant`, `hibernate-filter`, `pdfbox`, `tesseract-ocr`

## Decisions (Taktik Kararlar — Wiki Seviyesi)

- [[decisions/ledger-as-source-of-truth]]
- [[decisions/idempotent-reconcile-no-op-guard]]
- [[decisions/manual-reconcile-before-scheduled]]
- [[decisions/db-side-aggregate-over-java-loop]]
- [[decisions/rename-balance-to-currentbalance]]
- [[decisions/use-entity-graph-for-customer-account-fetch]]
- [[decisions/trust-reconcile-no-ledger-version]]
- [[decisions/credit-limit-override-role-based]] (Sprint 5)

> Stratejik ADR'lar için `.claude/decisions/` (ayrı katman).

## Issues (Düzeltilen Sorunlar + Açıklar)

Çözüldü:
- [[issues/today-collection-always-zero]]
- [[issues/customer-list-balance-zero]]
- [[issues/supplier-list-balance-zero]]
- [[issues/batch-entry-provider-truncated]]
- [[issues/n-plus-one-customer-account-fetch]]

Açık:
- [[issues/admin-endpoint-no-preauthorize]]
- [[issues/overdue-amount-not-reconciled]]

## Syntheses (Üst Düzey Özet)

- [[syntheses/accounts-overview]] — Cari Hesaplar ekosistemi
- [[syntheses/denormalization-strategy]] — proje geneli denormalize strateji

## Archive

Eskimiş sayfalar. Mevcut içerik yok — taşıma kuralı için `archive/README.md`.
