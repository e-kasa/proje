---
title: Accounts Screens Wiki — İndeks (MOC)
type: index
last-verified: 2026-04-24
---

# Accounts Screens Wiki — İndeks

Flutter `features/accounts/` feature'ının kalıcı bilgi arşivi giriş noktası.

> **Önce oku**: [[CLAUDE]] — protokol

## Genel

- [[log]] — event log
- [[lint-report]] — sağlık taraması (2026-04-24)

## Sources (İşlenen 5 Kaynak)

- [[sources/screens/2026-04-24-accounts-hub-screen]]
- [[sources/screens/2026-04-24-accounts-notifiers]]
- [[sources/screens/2026-04-24-statement-detail-panel]]
- [[sources/screens/2026-04-24-account-edit-form]]
- [[sources/screens/2026-04-24-accounts-list-panel]]

## Entities (Ekran / Widget / Provider)

- [[entities/accounts-hub-screen]] — ana hub (ConsumerStatefulWidget)
- [[entities/accounts-notifiers]] — 3 StateNotifier
- [[entities/statement-detail-panel]] — ekstre detay
- [[entities/account-edit-form]] — polimorfik CRUD
- [[entities/accounts-list-panel]] — birleşik liste

## Concepts

- [[concepts/master-detail-layout]] — iki panel responsive pattern
- [[concepts/sentinel-copy-with]] — null-safe copyWith idiom
- [[concepts/untyped-map-api]] — Map<String,dynamic> risk profili

## Decisions

- [[decisions/master-detail-800px-breakpoint]]
- [[decisions/inline-form-to-modal-migration]] (2026-04-24 UX revizyonu)
- [[decisions/polymorphic-account-edit-form]]
- [[decisions/merged-customer-supplier-list]]
- [[decisions/overdue-aware-list-ordering]]

## Issues

- [[issues/today-collection-always-zero-ref]] — tarihsel (çözüldü)
- [[issues/dar-ekran-yeniden-secim-bug]] — Riverpod aynı değer → no notify (çözüldü)
- [[issues/statement-panel-missing-payment-button]] — ödeme butonu yok 🟡 OPEN

## Syntheses

- [[syntheses/accounts-screens-overview]] — bileşen haritası + state katmanı
- [[syntheses/accounts-data-flow]] — uçtan uca veri akışı
- [[syntheses/payment-recording-and-vehicle-tracking]] — ödeme senaryosu + plaka takibi gap

## Üst Wiki (SEDCORE)

Bu wiki scoped — Flutter accounts ekranları. Backend + domain üst wiki'de:
- `.claude/wiki/syntheses/accounts-overview.md` — uçtan uca hikaye
- `.claude/wiki/flows/accounts-hub-load.md` — veri çağrı zinciri (backend)
- `.claude/wiki/flows/today-collection-calc.md` — client filter detay
- `.claude/wiki/entities/customer-account.md` — domain model
- `.claude/wiki/entities/supplier-account.md`
- `.claude/wiki/patterns/dto-tomap-pattern.md` — untyped Map kaynağı
- `.claude/wiki/syntheses/accounts-hub-production-readiness.md` — gap analizi + roadmap

## Operasyonlar

- `/wiki-ingest <kaynak>` — üst seviye ingest (proje `.claude/commands/`)
- Eklemek istediğin source: `sources/screens/YYYY-MM-DD-<slug>.md` + ilgili entity güncelle
