---
title: Açık İş Kalemleri Durum Raporu (2026-04-26)
type: synthesis
date: 2026-04-26
status: actionable
purpose: tüm planlar + sentezler + hot-fix sonrası kalan işlerin konsolide listesi + öncelik
based-on: lint-action-plan, accounts-dev-analysis-v2, sprint-7-plan, sprint-8-plan, accounts-bugfix-investigation
---

# Açık İş Kalemleri — Durum Raporu

Tüm aktif planlar, sentezler ve hot-fix sonrası bekleyen işler. Öncelik: **P0 (acil) → P1 (yüksek) → P2 (orta) → P3 (düşük)**.

## P0 — Acil / Bu Hafta (Manuel Test + Görüntüleme)

### P0.1 — Smoke Test (sen runtime'da)
Sprint 7 ve Sprint 8 hot-fix değişiklikleri runtime doğrulaması beklenmiyor:
- **Sprint 7 Sale-Payment allocation**: vadeli müşteri tahsilat → açık satış picker → `payment_allocations` tablosunda kayıt
- **Sprint 8 hot-fix Bug A**: POS Cart Panel + AccountsHub liste boyutu uyumlu (limit 50)
- **Sprint 8 hot-fix Bug B**: ödeme sonrası AccountsHub bakiye **anında** değişmeli (hot reload gereksiz)
- **D3 backend doğrulama**: `curl GET /account-statements?...` → response'ta `"currentBalance"` field

**Kaynak:** [[syntheses/accounts-bugfix-investigation-2026-04-26]] §Verification

### P0.2 — D3 Frontend Render (1-2 saat)
Backend `currentBalance` döndürüyor ama frontend ekstre header'ında render etmiyor.

**Dosya:** [`statement_detail_panel.dart`](project_pos/lib/features/accounts/widgets/statement_detail_panel.dart)
- Statement response model'ine `currentBalance` parse eklenmeli
- Header'da `closingBalance` yanına `currentBalance` (eğer farklı ise drift göstergesi badge)

**Kaynak:** [[syntheses/accounts-bugfix-investigation-2026-04-26]] §Sprint 9 Hold-overs

## P1 — Yüksek Öncelik (Sprint 9 Başı)

### P1.1 — WP2 ErrorBoundary Kalan 2 Panel (1.5 saat)
Sprint 8'de AccountsListPanel için yapıldı (1/3). Kalan:
- `StatementDetailPanel` — `accountStatementProvider` error → `AccountsErrorView`
- `AccountsSummaryBar` — `accountSummaryProvider` error → `AccountsErrorView`

**Kaynak:** [[syntheses/sprint-8-implementation-plan-2026-04-26]] §WP2 + [[issues/accounts-error-boundary-missing]]

### P1.2 — WP3 T2-T4 Service-Level Testler (1.6 gün)
Sprint 7'de WP2 minimum yapıldı (`PaymentAllocationRepositoryTest`, 3 test). Eksikler `@SpringBootTest`:
- **T1 full** `PaymentCreationIntegrationTest` — happy path (single/multi/generic allocation), idempotent, sum mismatch validation
- **T2** `ReconcileDriftDetectionTest` — denormalize bozulması + idempotent + allocation sum match
- **T3** `CreditLimitGuardTest` — boundary cases + override role
- **T4** `SalePaymentFkIntegrityTest` — cancel + partial payment + multi-payment sum

Test infrastructure (H2 + application-test.properties) Sprint 7'de hazırlandı.

**Kaynak:** [[syntheses/sprint-7-implementation-plan-2026-04-25]] §WP2 + [[issues/test-coverage-unknown]] (P1)

### P1.3 — B0 Phase 2: POS Cart Panel Paginated (1 gün)
Sprint 8 hot-fix D2 geçici düzeltmedi (limit 50). Kalıcı:
- [`cart_panel.dart`](project_pos/lib/features/pos/widgets/cart_panel.dart) `_CustomerPickerSheet` → AccountsListController kullan veya kendi paginated endpoint
- Sayfa-kaydır + arama + filter (tutarlılık AccountsHub ile)

**Kaynak:** [[syntheses/accounts-bugfix-investigation-2026-04-26]] §Sprint 9 + [[issues/accounts-pagination-missing]]

## P2 — Orta Öncelik (Sprint 9-10)

### P2.1 — B3 Toplu Ödeme UI (1.5-2 gün)
**Backend hazır** ([[entities/payment-allocation]] many-to-many). Sadece UI:
- [`payment_record_modal.dart`](project_pos/lib/features/accounts/screens/payment_record_modal.dart) "+ satış ekle" butonu (şu an disabled hint)
- Multi-allocation form: tutar bölme, FIFO öneri, manuel düzenleme

**Kaynak:** [[syntheses/accounts-development-analysis-2026-04-25-v2]] §B3 + [[concepts/payment-allocation-pattern]]

### P2.2 — B8 Overdue Notification (3 gün)
Vadesi geçen alacak için kullanıcı uyarısı (toast/badge).

**Kaynak:** [[syntheses/accounts-development-analysis-2026-04-25-v2]] §B8 + [[issues/overdue-notification-missing]]

### P2.3 — B9 Activity History (1.5-2 gün)
Cari hesap işlem zamanı/güncelleme takibi.

**Kaynak:** [[syntheses/accounts-development-analysis-2026-04-25-v2]] §B9 + [[issues/activity-history-missing]]

### P2.4 — B6 Yaşlandırma Raporu (3-4 gün)
Backend `GET /accounts/aging?asOf=DATE` + frontend chart (0-30/30-60/60-90/90+ gün).

**Kaynak:** [[syntheses/accounts-development-analysis-2026-04-25-v2]] §B6

### P2.5 — Lint Action Plan P1 Cleanup (1 saat — yüksek ROI)
[[syntheses/lint-action-plan-2026-04-25]] hâlâ uygulanmadı:
- P1.1: 16 wikilink ad değişimi (sed batch — script hazır, 10-15 dk)
- P1.2: 6 gerçek eksik wikilink hedefi (30 dk karar + sed)
- P1.3: 8 placeholder kırık link (code-block sar, 10 dk)

**Kaynak:** [[syntheses/lint-action-plan-2026-04-25]] §P1

### P2.6 — I5 Test Coverage Geniş (4-7 gün)
T1-T4 kritik path tamamlandıktan sonra geniş kapsam:
- Diğer service'ler (CustomerService, SaleService, ReconcileScheduledJob)
- Repository custom query'ler
- Controller endpoint'leri

**Kaynak:** [[issues/test-coverage-unknown]]

### P2.7 — MERGE_NEEDED Dosya İncelemesi (2-3 saat)
[[lint-report]] §1 — 18 `-from-claude-wiki` suffix'li dosya. Standart algoritma:
1. Read kanonik + suffix
2. %95 aynı → suffix delete; ek detay var → merge; farklı → cross-link

**Kaynak:** [[syntheses/lint-action-plan-2026-04-25]] §P2.1

## P3 — Düşük Öncelik (Sprint 11+ veya Müşteri Talebine Göre)

### P3.1 — B2 Plaka Opsiyon B/C (5-10 gün)
Sprint 6b'de Opsiyon A (description prepend) kabul edildi. B (Payment.vehicle_plate kolonu) veya C (CustomerVehicle entity) müşteri feedback bekliyor.

**Tetikleyici:** [[decisions/2026-04-24-vehicle-plate-tracking-option-a]] "Yeniden Değerlendirme Kriterleri"

### P3.2 — B4 Taksitli Ödeme (6-7 gün)
Premium feature. `Payment.installmentPlan` (3x, 6x), her vade için ayrı kayıt + due date.

**Kaynak:** [[syntheses/accounts-development-analysis-2026-04-25-v2]] §B4

### P3.3 — B7 SMS/WhatsApp Bildirim (3-6 gün + entegrasyon)
Twilio/SMS gateway entegrasyonu.

### P3.4 — B5 Hızlı Tahsilat Butonu (POS Ana Menü) (0.5-1 gün)
POS ana ekrana shortcut.

### P3.5 — Wiki React (template/) Ingest (1-2 sprint)
525 dosya, sadece CLAUDE.md kopyası kapsanmış.

**Kaynak:** [[syntheses/codebase-snapshot-2026-04-25]] §Hâlâ Boş Bölgeler

### P3.6 — Pos-Product-Manager Controller Endpoint Kataloğu (~50, 1 sprint)

### P3.7 — Core Kütüphane Derinleşme (3-5 gün)
TOpenDbEntity, BaseDbServiceImp, @FilterDef.

### P3.8 — Lint P2 Tek-Yönlü Xref + Zayıf Kaynak (1-2 saat sample)

### P3.9 — i18n + Hibernate Filter Wiki Ingest (Faz 4 cancel — agent araştırmaları hazır, yazılma atlanmış)
8 critical drift wiki'ye yansıtılmadı. İçerik plan dosyalarında: `agent-a5ea01805e868e74d.md` (i18n), `agent-ad5045150372b9773.md` (Hibernate Filter).

**Sebep:** kullanıcı "mdler silindi plan iptal" dedi. Yeniden başlatılabilir.

## Önerilen Sıra (Pragmatik)

**Bu hafta:**
1. P0.1 smoke test (sen, ~30 dk)
2. P0.2 D3 frontend render (1-2 saat)
3. P1.1 ErrorBoundary kalan 2 panel (1.5 saat)
4. P2.5 lint P1 cleanup (1 saat) — yüksek ROI

→ Total ~5 saat, tüm Sprint 7+8 done sayılır.

**Sprint 9 (1 hafta):**
1. P1.2 WP3 T2-T4 testler (1.6 gün)
2. P1.3 B0 phase 2 paginated POS picker (1 gün)
3. P2.1 B3 toplu ödeme UI (1.5-2 gün)
4. P2.5 lint P1 (artık olmuyorsa)

**Sprint 10 (1 hafta):**
- P2.2-P2.4 (B6, B8, B9 — yönetim görünürlüğü)

**Sprint 11+:**
- P2.6 test coverage geniş kapsam
- P2.7 MERGE_NEEDED inceleme
- P3 backlog'u feedback'e göre

## Önceliklendirme Mantığı

- **P0**: kullanıcı görünür, kor uygulamada bug/eksik (smoke + currentBalance render)
- **P1**: production riski azaltma (test güvenlik ağı + UI sağlamlaştırma + tutarlılık)
- **P2**: yönetim/raporlama özellikleri (B3/B6/B8/B9), wiki sağlık temizliği
- **P3**: müşteri feedback'i bekleyen (B2/B4/B7), büyük scope wiki ingest

## Önemli Not — Frontend `flutter analyze` Hâlâ Koşulmadı

Sprint 7+8 boyunca backend Maven compile her aşamada doğrulandı (exit 0). Frontend için `flutter analyze` sen koşturmadın. Olası sorunlar:
- Sprint 8 `accounts_list_provider.dart` rewrite — geriye uyum `load()` alias var ama call site'lar test edilmedi
- `payment_record_modal.dart` `customerId` yeni param — null safety doğru
- Hot-fix `ref.invalidate(accountsListProvider)` import gerek olmayabilir (zaten ref.invalidate global API)

**Önerim:** P0.1'in parçası olarak `cd project_pos && flutter analyze` koş.

## Sources

- Plan dosyası: `C:\Users\Win11\.claude\plans\polymorphic-gathering-flute.md`
- [[syntheses/lint-action-plan-2026-04-25]]
- [[syntheses/accounts-development-analysis-2026-04-25-v2]]
- [[syntheses/sprint-7-implementation-plan-2026-04-25]]
- [[syntheses/sprint-8-implementation-plan-2026-04-26]]
- [[syntheses/accounts-bugfix-investigation-2026-04-26]]
- [[syntheses/codebase-snapshot-2026-04-25]]
- [[lint-report]]
- [[issues/accounts-pagination-missing]] · [[issues/accounts-error-boundary-missing]] · [[issues/test-coverage-unknown]] · [[issues/overdue-notification-missing]] · [[issues/activity-history-missing]]

## Related

- [[index]] (MOC)
- [[log]] (event log)
- [[syntheses/codebase-snapshot-2026-04-25]] (kod-wiki uyum)
