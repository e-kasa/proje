---
title: Cari Hesaplar Modülü — Geliştirme Analizi (2026-04-25)
type: synthesis
date: 2026-04-25
status: superseded
superseded-by: syntheses/accounts-development-analysis-2026-04-25-v2.md
superseded-reason: 5 ciddi review eleştirisi (test stratejisi, B1↔B3 mimari bağımlılık, efor tahmini, issue/backlog ayrımı, sprint 7 yoğunluğu) v2'de düzeltildi
scope: Cari yönetimi (project_pos/lib/features/accounts) + backend finance/sales
purpose: mevcut durum + tamamlanan işler + açık sorunlar + geliştirme backlog'u — önceliklendirme ile
---

> ⚠️ **SUPERSEDED**: Bu sayfa v1'dir. **Güncel versiyon: [[syntheses/accounts-development-analysis-2026-04-25-v2]]**.
> v2'de düzeltilenler: test coverage P1'e çekildi, B1 yeniden tasarlandı (PaymentAllocation many-to-many baştan), efor tahminleri 1.5x, issue/backlog ayrımı netleşti, Sprint 7 gerçekçileştirildi (B0=pagination Sprint 8'e taşındı), Riskler+Done+Metrikler bölümleri eklendi.
> v1'in mimari özet, sprint tarihçesi ve kaynak listesi hâlâ geçerli — sadece önceliklendirme/efor/Sprint 7 yapısı v2'de güncel.

# Cari Hesaplar Modülü — Geliştirme Analizi

`.wiki/` ve scoped wiki (`project_pos/.../accounts/_wiki/`) sayfalarına dayalı **kapsamlı geliştirme analizi**. Mevcut durum + tamamlanan işler + açık sorunlar + yeni özellik tespitleri ile **P1-P3 önceliklendirme** + roadmap önerisi.

## 1. Mevcut Mimari (Özet)

### Backend
- **Entities**: [[entities/customer]], [[entities/customer-account]], [[entities/supplier]], [[entities/supplier-account]], [[entities/account-transaction]] (ledger), [[entities/payment]], [[entities/reconcile-audit-log]], [[entities/sale]] (`saleId` FK Payment'a bağlı), [[entities/supplier-claim]]
- **Concepts**: [[concepts/ledger-vs-denormalize]], [[concepts/denormalization-with-reconcile]], [[concepts/drift]], [[concepts/optimistic-lock-version]], [[concepts/append-only]], [[concepts/write-through-cache]]
- **Decisions**: [[decisions/ledger-as-source-of-truth]], [[decisions/idempotent-reconcile-no-op-guard]], [[decisions/scheduled-reconcile-safe-rollout]], [[decisions/db-side-aggregate-over-java-loop]], [[decisions/use-entity-graph-for-customer-account-fetch]], [[decisions/credit-limit-override-role-based]]

### Frontend (Flutter)
- **Ana ekran**: [[entities/accounts-hub-screen]] — master/detail hub (≥800px split, <800px push) — [[syntheses/flow-accounts-hub-load]]
- **Bileşenler** (scoped wiki'de detaylı):
  - `accounts-summary-bar` — üst özet
  - `accounts-list-panel` — sol/full liste
  - `statement-detail-panel` — sağ/push ekstre
  - `payment-record-modal` — tahsilat/ödeme dialog
  - `account-edit-form` — modal form ([[syntheses/account-edit-form-ux]])
- **Provider'lar**: `accounts-list-provider`, `accounts-notifiers`, `selected-account-provider`, payment/account services
- **Üst-düzey sentez**: [[syntheses/accounts-overview]], [[syntheses/accounts-module-overview]], [[syntheses/accounts-hub-production-readiness]]

## 2. Tamamlanan İyileştirmeler (Sprint Tarihçesi)

| Sprint | Konu | Kaynak |
|---|---|---|
| Sprint 1-3 | Ledger + denormalize + reconcile mimarisi | [[concepts/ledger-vs-denormalize]], [[concepts/denormalization-with-reconcile]] |
| Sprint 4 (`d53b33e`) | Multi-tenant nightly scheduled reconcile | [[entities/reconcile-scheduled-job]], [[decisions/scheduled-reconcile-safe-rollout]] |
| Sprint 5 (`8b6ac05`) | AccountsHub backend optimization (DB-side aggregates + indexes) | [[decisions/db-side-aggregate-over-java-loop]], [[sources/code-refs/2026-04-22-accounts-hub-perf]] |
| Sprint 5 | EntityGraph N+1 fix | [[issues/n-plus-one-customer-account-fetch]], [[decisions/use-entity-graph-for-customer-account-fetch]] |
| Sprint 5 (`9a8c704`) | PDF + email statement export endpoints | [[syntheses/flow-pdf-statement-export]] |
| Sprint 6a (`c57eeaa`) | Statement panelinden tahsilat alma — `_handlePayment` + 4 provider refresh | scoped: `flows/payment-recording-from-statement.md` |
| Sprint 6 (`6c6280b`) | Credit limit override role-based authorization | [[decisions/credit-limit-override-role-based]] |
| Sprint 6b (`5c2b752`) | Plaka takibi Opsiyon A (description prepend) | [[decisions/2026-04-24-vehicle-plate-tracking-option-a]] |
| Geçmiş çözümler | overdue-amount-not-reconciled, customer-list-balance-zero, supplier-list-balance-zero, today-collection-always-zero, credit-limit-not-enforced | `issues/*` (RESOLVED) |

## 3. Açık Sorunlar (Wiki'de İşaretli)

| # | Issue | Kaynak | Öncelik | Tahmini Efor |
|---|---|---|---|---|
| I1 | **Pagination eksik** — accounts list 100+ kayıt yavaş, infinite scroll yok | [[issues/accounts-pagination-missing]] (P1.3) | Y | 2-3 gün |
| I2 | **Error boundary eksik** — provider hatası tüm ekranı patlatıyor | [[issues/accounts-error-boundary-missing]] (P1.5) | Y | 1 gün |
| I3 | **Overdue notification yok** — vadesi geçen alacak için kullanıcı uyarısı | [[issues/overdue-notification-missing]] (P2.4) | O | 2 gün |
| I4 | **Activity history yok** — bir cari hesabın geçmiş işlem zamanı/güncellendi takibi yok | [[issues/activity-history-missing]] (P2.6) | O | 1-2 gün |
| I5 | **Test coverage bilinmiyor** — accounts modülü için unit/widget test yok | [[issues/test-coverage-unknown]] (P2.7) | O-D | 3-5 gün |

Scoped wiki'deki açık issue'lar:
- `dar-ekran-yeniden-secim-bug.md` — mobil push'tan dönüşte selection kayıp olabiliyor
- `statement-panel-missing-payment-button.md` — Sprint 6a'da fix edildi, kapatma teyidi gerek

## 4. Geliştirme Backlog'u (Yeni Tespit)

### B1. **Alışveriş bazlı ödeme** (kullanıcı bu turda istedi)
- **Durum**: Backend hazır (`Payment.saleId` FK + `GET /sales?customerId=X` endpoint), frontend modalda satış picker yok
- **Yapılacak**: `PaymentRecordModal`'a "Açık Alışverişler" radio + liste; seçilen satış için `remainingAmount` otomatik dol
- **Değer**: Yedek parça müşterilerinin "X plakası için balata satışı ödemesi" gibi yapısal bağ — drift azalır, raporlama mümkün
- **Efor**: 3-4 saat
- **Öncelik**: **Y** (kullanıcı talebi + backend altyapı zaten hazır → düşük efor, yüksek değer)

### B2. **Plaka takibi Opsiyon B/C** (Sprint 6b'de ertelendi)
- **Durum**: Mevcut Opsiyon A (description prepend) çalışıyor ama plaka arama/filtre/rapor yok
- **Yapılacak**:
  - Opsiyon B: `Payment.vehicle_plate VARCHAR(20)` kolonu + repository filter (3-5 gün)
  - Opsiyon C: `CustomerVehicle` entity + Sale FK (5-7 gün)
- **Tetikleyici**: Bkz. [[decisions/2026-04-24-vehicle-plate-tracking-option-a]] "Yeniden Değerlendirme Kriterleri"
- **Öncelik**: **D** (müşteri feedback'i bekliyor)

### B3. **Toplu ödeme (multi-fatura)**
- **Durum**: Yapı yok
- **Yapılacak**: 1 ödemenin birden fazla satışa bölünmesi (FIFO veya manuel dağıtım) — `PaymentAllocation` entity gerekir
- **Önkoşul**: B1 tamamlanmış olmalı
- **Efor**: 3-4 gün
- **Öncelik**: O (B1 sonrası ihtiyaç)

### B4. **Taksitli ödeme / vade planı**
- **Durum**: Yapı yok
- **Yapılacak**: `Payment.installmentPlan` (3x, 6x), her vade için ayrı kayıt + due date takibi
- **Efor**: 4-5 gün
- **Öncelik**: D (premium feature)

### B5. **Hızlı tahsilat butonu (POS ana menü)**
- **Durum**: Yok — sadece AccountsHub içinden tahsilat alınabiliyor
- **Yapılacak**: POS ana ekrana shortcut: müşteri ara → tutar → kaydet
- **Efor**: 0.5-1 gün
- **Öncelik**: O

### B6. **Yaşlandırma raporu (aging analysis)**
- **Durum**: Yok — vadesi geçen toplam var ama 0-30/30-60/60-90/90+ gün ayrımı yok
- **Yapılacak**: Backend `GET /accounts/aging?asOf=DATE` + frontend chart
- **Efor**: 2-3 gün
- **Öncelik**: O

### B7. **SMS/WhatsApp tahsilat hatırlatma**
- **Durum**: Yok
- **Yapılacak**: Vadesi yaklaşan/geçmiş alacaklar için bildirim — entegrasyon (Twilio/SMS gateway)
- **Efor**: 2-4 gün + entegrasyon
- **Öncelik**: D

## 5. Önceliklendirme Matrisi

| # | İş | Değer | Efor | Öncelik | Sıra |
|---|---|---|---|---|---|
| B1 | Alışveriş bazlı ödeme | Y (yapısal Sale-Payment bağı) | D (3-4 saat) | **P1** | 1 |
| I2 | Error boundary | Y (UX kalitesi, hata durumunda) | D (1 gün) | **P1** | 2 |
| I1 | Pagination | Y (100+ cari müşteri için zorunlu) | O (2-3 gün) | **P1** | 3 |
| I3 | Overdue notification | O | O (2 gün) | **P2** | 4 |
| B5 | Hızlı tahsilat butonu | O | D (0.5-1 gün) | **P2** | 5 |
| I4 | Activity history | O | D (1-2 gün) | **P2** | 6 |
| B6 | Yaşlandırma raporu | O (yönetici için kritik) | O (2-3 gün) | **P2** | 7 |
| B3 | Toplu ödeme | O (B1 sonrası mantıklı) | O (3-4 gün) | **P3** | 8 |
| I5 | Test coverage | O-D (uzun vadede zorunlu) | O (3-5 gün) | **P3** | 9 |
| B2 | Plaka Opsiyon B/C | O | O (3-7 gün) | **P3** | 10 |
| B4 | Taksitli ödeme | D | O-Y (4-5 gün) | **P3** | 11 |
| B7 | SMS bildirim | D | O (2-4 gün + entegrasyon) | **P3** | 12 |

## 6. Önerilen Roadmap

### Sprint 7 (1 hafta) — "Sale-Payment Yapısal Bağ + UX Sağlamlaştırma"
- B1 (Alışveriş bazlı ödeme) — 3-4 saat
- I2 (Error boundary) — 1 gün
- I1 (Pagination) — 2-3 gün
- B5 (Hızlı tahsilat butonu — opsiyonel, kalan süreyle) — 0.5-1 gün

### Sprint 8 (1 hafta) — "Yönetim Görünürlüğü"
- I3 (Overdue notification)
- I4 (Activity history)
- B6 (Yaşlandırma raporu)

### Sprint 9+ (ileri) — "Premium Tahsilat Özellikleri"
- B3 (Toplu ödeme)
- I5 (Test coverage — sürekli, paralel)
- B2/B4/B7 — müşteri feedback'i ile karar

## 7. Wiki'de Eksik Bilgi

Bu analiz için **ek ingest gerekmiyor** — wiki kapsamlı (50+ accounts sayfası). Yine de aşağıdaki noktalar **gelecek ingest'te zenginleştirilebilir**:

- `entities/payment-record-modal` (mevcut sadece scoped wiki'de geçiyor) — ana wiki entity sayfası açılabilir
- `entities/account-statement-controller` — backend endpoint kataloğu için
- `concepts/payment-allocation` (B3 için) — toplu ödeme dağıtım pattern'i

## 8. Kaynak Referansları

### Wiki Sayfaları (Bu Sentezde Kullanılan)
- **Entity**: [[entities/customer-account]], [[entities/supplier-account]], [[entities/account-transaction]], [[entities/payment]], [[entities/sale]], [[entities/accounts-hub-screen]]
- **Synthesis**: [[syntheses/accounts-overview]], [[syntheses/accounts-module-overview]], [[syntheses/accounts-hub-production-readiness]], [[syntheses/account-edit-form-ux]], [[syntheses/flow-accounts-hub-load]], [[syntheses/flow-pdf-statement-export]], [[syntheses/flow-today-collection-calc]]
- **Decision**: [[decisions/2026-04-24-vehicle-plate-tracking-option-a]], [[decisions/credit-limit-override-role-based]], [[decisions/db-side-aggregate-over-java-loop]], [[decisions/use-entity-graph-for-customer-account-fetch]], [[decisions/scheduled-reconcile-safe-rollout]], [[decisions/ledger-as-source-of-truth]], [[decisions/idempotent-reconcile-no-op-guard]]
- **Concept**: [[concepts/ledger-vs-denormalize]], [[concepts/denormalization-with-reconcile]], [[concepts/drift]], [[concepts/optimistic-lock-version]]
- **Issue**: [[issues/accounts-pagination-missing]], [[issues/accounts-error-boundary-missing]], [[issues/overdue-notification-missing]], [[issues/activity-history-missing]], [[issues/test-coverage-unknown]]

### Scoped Wiki (project_pos/lib/features/accounts/screens/_wiki/)
- `entities/accounts-hub-screen.md`, `entities/statement-detail-panel.md`, `entities/payment-record-modal` (referans), `entities/accounts-notifiers.md`, `entities/account-edit-form.md`
- `flows/payment-recording-from-statement.md`, `flows/statement-load-flow.md`
- `syntheses/payment-recording-and-vehicle-tracking.md` — Sprint 6a/6b detaylı
- `decisions/inline-form-to-modal-migration.md`, `decisions/master-detail-800px-breakpoint.md`, `decisions/merged-customer-supplier-list.md`, `decisions/overdue-aware-list-ordering.md`, `decisions/polymorphic-account-edit-form.md`

### Kod Referansları (Doğrulama)
- Backend: [`SaleControllerImpl.java:48`](pos-product-manager/src/main/java/com/sedcore/sales/controller/impl/SaleControllerImpl.java#L48) — `GET /api/v1/sales?customerId=X` mevcut, `status=pending` filtre
- Backend: [`Payment.java:41`](pos-product-manager/src/main/java/com/sedcore/finance/entity/Payment.java#L41) — `Payment.saleId` FK
- Frontend: [`payment_record_modal.dart`](project_pos/lib/features/accounts/screens/payment_record_modal.dart) — Sprint 6b sonrası, satış picker eksik
- Frontend: [`payment_service.dart`](project_pos/lib/features/accounts/services/payment_service.dart) — generic `Map<String,dynamic>` alıyor (saleId eklenebilir)
- Frontend: [`sales_service.dart`](project_pos/lib/features/sales/services/sales_service.dart) — `getSales(customerId, paymentStatus)` mevcut

### Commit Tarihçesi
- `5c2b752` Sprint 6b vehicle-plate
- `c57eeaa` Sprint 6a payment recording sync
- `6c6280b` Credit limit override
- `9a8c704` PDF/email statement export
- `4c2a0a9` OpenAPI codegen
- `d53b33e` Multi-tenant scheduled reconcile
- `8b6ac05` AccountsHub perf
- `dbf8282` batch-entry 4-area UX

## Related

- [[syntheses/accounts-overview]]
- [[syntheses/accounts-module-overview]]
- [[syntheses/accounts-hub-production-readiness]]
- [[syntheses/lint-action-plan-2026-04-25]] (paralel iş — wiki sağlık)
- [[syntheses/codebase-snapshot-2026-04-25]] (genel proje snapshot)
- [[lint-report]]
