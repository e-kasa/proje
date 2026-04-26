---
title: Lint Report — W2 Full + W3 sonrası (claude-wiki)
type: source
source: .claude/wiki/lint-report.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Lint Report — 2026-04-24 (W2 Full + W3 güncellemesi)

**Güncel kümülatif W2**:
- Acil (4): `entities/stock-level`, `entities/stock-movement`, `patterns/optimistic-lock-version`, `patterns/base-entity-list-screen` ✅
- Sales (4): `entities/sale`, `entities/sale-item`, `entities/vehicle`, `flows/sale-checkout` ✅
- Inventory (4): `entities/store`, `entities/warehouse`, `entities/stock-transfer`, `flows/stock-transfer` ✅
- Purchase (3): `entities/purchase`, `entities/supplier-claim`, `flows/purchase-checkout` ✅
- Düzeltmeler: `account-transaction.md` (@Version notu), `stock-level.md` + `sale-checkout.md` (concurrency mekanizması — pessimistic lock)

**W3 (operasyon hijyeni)**: `commands/wiki-lint.md` + `wiki/README.md` güncel — aylık cadence + ingest tetikleyici + archive kuralı + konuşma-sonrası disiplin belgelendi.

## Özet (güncel)

- **Yüksek**: 0 (Sprint 1'de P0.1 resolved — admin-endpoint kapandı)
- **Orta**: 0 (W2 Sales dolduruldu)
- **Düşük**: 1 (decisions orphan referanslar)

## Bulgular

### Çelişki (0)

- 2026-04-24 — `AccountTransaction.@Version` ADR vs Kod: **RESOLVED** — ADR revize, A+D defense-in-depth kararı.

### Eskimiş (0)
İlk setup — tüm içerik bugün yazıldı.

### Yetim Sayfalar (0)
Tüm sayfalar en az bir başka sayfadan link alıyor veya kategori README'sinden referans alıyor.

### Eksik Sayfa (0)
W2 acil + W2 Sales kapsamında tüm mevcut referanslar karşılandı.

### Tek-Yönlü Cross-Ref (0)
Belirgin tek-yönlü yok.

### Kaynak Boşluğu (3, düşük öncelik)

- [[entities/customer]] — sadece 2 kaynak (`Customer.java` + 1 source doc)
- [[entities/supplier]] — aynı
- [[entities/payment]] — 3 kaynak, yeterli

Doğrulama önerisi: ilgili servis (`CustomerServiceImpl`, `SupplierServiceImpl`) kaynak olarak eklenebilir.

### Stub Sayfalar (0)
Hepsi `draft` veya `verified`.

### Oluşturulmayan Decision Sayfaları (6, opsiyonel)

Source doc'larda referans geçen ama henüz açılmamış:

| Bahsedilen | Referans veren |
|---|---|
| `decisions/batch-entry-4area-split` | sources/code-refs/2026-04-23-batch-entry-4area |
| `decisions/tomap-inline-denorm-fields` | sources/code-refs/2026-04-22-accounts-hub-perf |
| `decisions/three-panel-layout-accounts-hub` | sources/code-refs/2026-04-21-accounts-hub-screens |
| `decisions/merged-customer-supplier-list` | sources/code-refs/2026-04-21-accounts-hub-screens |
| `decisions/category-in-header-state` | sources/code-refs/2026-04-23-batch-entry-4area |
| `decisions/base-entity-list-screen-adoption` | sources/code-refs/2026-04-17-units-employee-modern |

**Öneri**: İlgili sprint konuşmasında ihtiyaç olursa aç; şu an için düşük değer, orphan referans kalabilir.

## Otomatik Düzeltme
**Yapılmadı.** Sadece rapor.

## Öncelikli Aksiyonlar

1. (Opsiyonel) Decision sayfalarını ihtiyaç anında oluştur
2. Sonraki aylık `/wiki-lint 30` (her ayın ilk Pazartesi) — W3 cadence kuralı
