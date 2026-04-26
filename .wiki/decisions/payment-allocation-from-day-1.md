---
title: ADR — PaymentAllocation Many-to-Many Baştan (B1↔B3 Bağımlılık)
type: decision
date: 2026-04-25
status: accepted
sprint: 7
related-issue: B1 (alışveriş bazlı ödeme), B3 (toplu ödeme)
---

# ADR — PaymentAllocation Many-to-Many Baştan

**Tarih:** 2026-04-25 · Sprint 7 · **Durum:** Kabul edildi

## Karar

Sale-Payment ilişkisini **baştan many-to-many** olarak modelle. Tek satışlı durumda bile her Payment için **bir veya daha fazla `PaymentAllocation` kaydı** oluşturulsun. Mevcut `Payment.sale` tek-FK alanı **deprecated** olarak işaretlensin, geçiş süreci sonunda (Sprint 9) kaldırılsın.

## Bağlam

v1 plan ([[syntheses/accounts-development-analysis-2026-04-25]]) B1'i tek-FK ile basit tutuyordu, B3'te (toplu ödeme) sonradan many-to-many'e migrate önerisi vardı. Review (v2) bu yaklaşımı **migration acısı** sebebiyle eleştirdi:

> "PaymentAllocation entity'si B1'in Payment.saleId tek FK yaklaşımıyla çatışıyor — B1'i tek-FK olarak yapıp sonra B3'te many-to-many'e geçmek migration acısı yaratır. B1'i tasarlarken PaymentAllocation'ı baştan düşünmek (tek satış için bile allocation kaydı tutmak) daha temiz olur."

[[syntheses/accounts-development-analysis-2026-04-25-v2]] §4 kabul: many-to-many Sprint 7'de implemente edilsin.

## Alternatifler

**A) Tek FK (`Payment.sale`) + sonradan PaymentAllocation tablosu**
- Avantaj: Sprint 7'de daha az kod (3-4 saat tahmini, gerçekte de küçük).
- Dezavantaj: B3'te 3 ağrı:
  1. Mevcut Payment kayıtları için backfill migration
  2. `Sale.paidAmount` derivasyonu kod yolunda iki branch (Payment.sale vs PaymentAllocation.sale)
  3. Reporting query'leri rewrite (`SELECT FROM payments WHERE sale_id = X` → JOIN PaymentAllocation)

**B) Many-to-many baştan (PaymentAllocation entity, tek satış için 1 kayıt)** ← SEÇİLDİ
- Avantaj: B3 sıfır migration, sıfır code path bifurcation, reporting tutarlı
- Dezavantaj: Sprint 7 efor +1 gün (toplam 2 gün B1)

## Sebep

1. **B3 (toplu ödeme) backlog'da P2** — yakın gelecekte gelecek, migration acısından kaçınmak istiyoruz.
2. **Audit zinciri** — her allocation `allocated_at` ile kim ne zaman dağıttı izlenebilir; tek-FK'da bu yok.
3. **Reporting tutarlı** — `Sale.paidAmount = SUM(PaymentAllocation.amount)` her zaman geçerli; tek-FK + sonradan eklenen tablo zaten 2 kaynak yaratır.
4. **`Payment.sale` deprecated path açık** — Sprint 9'da temiz kaldırılır, tek satır migration.

## Implementasyon

[[entities/payment-allocation]] sayfasında detay. Özet:
- Yeni entity + repository + request DTO
- `PaymentServiceImpl.createCustomerPayment()` sonunda `createAllocations()` çağrılır
- Default davranış: `request.allocations` boş + `saleId` boş → 1 "genel ödeme" allocation (sale=null)
- Geriye uyum: `request.saleId` dolu → 1 allocation otomatik

## Geçiş Süreci

| Sprint | Aksiyon |
|---|---|
| 7 (mevcut) | PaymentAllocation entity + service entegre, `Payment.sale` paralel set ediliyor |
| 8 | Reconcile job güncellemesi: `Sale.paidAmount = SUM(PaymentAllocation)` |
| 8 | Reporting endpoint'leri PaymentAllocation üzerinden okur |
| 9 | `Payment.sale` field hard delete + `PaymentRequest.saleId` kaldır |

## Riskler

| Risk | Önlem |
|---|---|
| `companyCode` PaymentAllocation'a kopyalanmaz → tenant leak | `createAllocations()` `payment.getCompanyCode()` set eder |
| Reconcile job güncellenmez → drift | Sprint 8'de reconcile + T2 test (yapılmayacak Sprint 7) |
| `request.allocations` SUM mismatch sessiz fail | Service katmanında validation (TOpenException) |
| B3 UI'da bölünmüş ödeme eklemediğimizde "+ satış ekle" disabled gösterilirse confused user | i18n: "yakında" hint (`accounts.add_another_sale`) |

## Sources

- v2 review: [[syntheses/accounts-development-analysis-2026-04-25-v2]] §4
- v1 (superseded): [[syntheses/accounts-development-analysis-2026-04-25]] §4 (B3 önkoşul B1)
- Sprint 7 plan: [[syntheses/sprint-7-implementation-plan-2026-04-25]] WP1
- Implementasyon: [[entities/payment-allocation]]

## Related

- [[entities/payment-allocation]]
- [[entities/payment]] — deprecated `sale` FK
- [[entities/sale]] — `paidAmount` derived
- [[concepts/append-only]] — audit pattern benzerliği
