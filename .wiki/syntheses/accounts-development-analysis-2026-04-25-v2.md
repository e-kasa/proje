---
title: Cari Hesaplar Modülü — Geliştirme Analizi v2 (Review-Revize)
type: synthesis
date: 2026-04-25
status: revised
supersedes: syntheses/accounts-development-analysis-2026-04-25.md
review-source: kullanıcı critique 2026-04-25 (5 ciddi kritik + 3 yapısal öneri)
purpose: v1 analizinin zayıf yönlerini düzeltmek — test stratejisi, B1↔B3 mimari sırası, efor gerçekçiliği, issue/backlog ayrımı, riskler+done+metrikler
---

# Cari Hesaplar Modülü — Geliştirme Analizi v2

**v1 ([[syntheses/accounts-development-analysis-2026-04-25]]) eleştirildi** — bu sayfa 5 zayıflığı düzelten revize. v1 içerik (mimari özet, sprint tarihçesi, kaynak listesi) hâlâ geçerli; **buradaki bölümler v1'in üzerine yazılır**.

## 1. Kabul Edilen Eleştiriler

| # | Eleştiri | Durum |
|---|---|---|
| C1 | **Test coverage P3 yanlış sinyal** — finansal modülde testsiz B1 girmek reconcile drift fark etmeyi haftalara çıkarır | ✅ kabul, **P1'e çekildi** |
| C2 | **Issue vs Backlog ayrımı bulanık** — I1 pagination feature gap, B5 backlog ama I3 issue | ✅ kabul, **netleştirildi** (alt §3) |
| C3 | **Efor tahminleri optimist** — B1 3-4 saat → 1-2 gün, I1 2-3 gün → 4-5 gün gerçekçi | ✅ kabul, **1.5x çarpıldı** |
| C4 | **B1↔B3 mimari bağımlılık** — PaymentAllocation many-to-many sonradan migration acısı, baştan tasarla | ✅ kabul, **B1 yeniden tasarlandı** (alt §4) |
| C5 | **Sprint 7 dolu** — B1+I2+I1+(B5) 1 haftaya sığmaz | ✅ kabul, **I1 Sprint 8'e** |

Yapısal öneri 3 (Riskler+Done+Metrikler) → §6, §7, §8 bölümlerinde eklendi.

## 2. Test Stratejisi (C1 düzeltme — yeni P1)

Finansal kritik path için **Sprint 7 ile birlikte** minimum test güvenlik ağı:

| Test | Kapsam | Tahmini Efor |
|---|---|---|
| **T1** Payment creation integration test | `POST /payments` happy path + saleId picker (B1) + idempotent (aynı request 2x) | 0.5 gün |
| **T2** Reconcile drift detection test | Manuel drift senaryosu (denormalize bozulması) → reconcile çalışır → drift = 0 | 0.5 gün |
| **T3** Credit limit guard test | `checkCreditLimit()` boundary cases (limit = 0, eşit, üzeri, override role'ü) | 0.3 gün |
| **T4** Sale-Payment FK integrity | B1 sonrası: silinen sale'a Payment yazılamaz, kısmi ödeme `remainingAmount` doğru | 0.3 gün |

**Toplam: 1.6 gün** → Sprint 7'ye dahil. CI'da koşmalı, drift fark etmek artık dakikalar.

> **Kural değişikliği:** Bundan sonra finance/accounts modülünde **PR test olmadan merge edilmez** (issue [[issues/test-coverage-unknown]] güncellensin).

[[issues/test-coverage-unknown]] artık **P1**, açıklama: "kritik path testleri (T1-T4) Sprint 7 zorunlu, geniş kapsam P3'te kalabilir".

## 3. Issue vs Backlog Netleştirme (C2 düzeltme)

**Tanım:**
- **Issue** = bug, teknik borç, mevcut kod kusurlu/yanlış (var olan şey çalışmıyor)
- **Backlog** = yeni özellik / feature gap (henüz olmayan şey)

### Yeniden Sınıflandırma

| Eski etiket | Yeni etiket | Sebep |
|---|---|---|
| I1 Pagination | **B0** Pagination | Yok olan UX → feature gap, kod kusurlu değil |
| I2 Error boundary | **I2** Error boundary | Provider hatası ekranı patlatıyor → mevcut kodun davranışı yanlış (issue ✓) |
| I3 Overdue notification | **B8** Overdue notification | Yeni özellik (backlog ✓) |
| I4 Activity history | **B9** Activity history | Yeni özellik (backlog ✓) |
| I5 Test coverage | **I5** Test coverage | Teknik borç (issue ✓), ama P1'e çekildi |
| B1-B7 | aynen kalır | zaten doğru |

Wiki'deki `issues/` altındaki dosyalar **etiket** olarak güncellenmeli (sadece issue listesinde kalmamalı, backlog'a da link verilmeli). Bu lint Pass 3'te kontrol edilebilir.

## 4. B1 Yeniden Tasarımı — PaymentAllocation Baştan (C4 düzeltme)

### Eski tasarım (v1) — sorunlu
```
Payment.saleId (tek FK) → tek satışa bağlanır
B3 (toplu ödeme) sonradan → schema migration: saleId NULL + PaymentAllocation many-to-many tablo
Migration acısı: mevcut Payment kayıtları + repository sorguları + Flutter UI hepsi etkilenir
```

### Yeni tasarım (v2) — many-to-many baştan
```
Payment (no saleId)
PaymentAllocation entity:
  - id
  - payment_id FK → Payment
  - sale_id FK → Sale (nullable, "genel ödeme" için NULL)
  - amount BigDecimal (allocation amount, sum = Payment.amount)
  - allocated_at timestamp
```

**B1'in yapacakları (revize):**
1. Backend: `PaymentAllocation` entity + repository + service'te `createAllocations(paymentId, List<{saleId, amount}>)`
2. Backend: `Payment` insert sonrası tek satış seçildiyse 1 allocation kaydı oluştur (`amount = payment.amount`)
3. Backend: "Genel ödeme" için 1 allocation kaydı `sale_id = NULL` (nadir, ama tutarlı)
4. Frontend: Modal'da tek satış seç + allocation otomatik (B1)
5. Frontend gelecek: B3'te aynı modal'a "+ satış ekle" butonu → multi allocation (UI değişimi minimum, schema sıfır değişim)

### Faydalar
- B3'e geçiş **sıfır migration** — sadece UI'a "+" butonu eklemek
- Reporting tutarlı: her zaman PaymentAllocation üzerinden sorgu (Sale.paidAmount = SUM allocations)
- Audit zinciri net: her allocation timestamp'li, kim ne zaman dağıttı izlenebilir

### Eklenen efor
- v1 B1: 3-4 saat (yanıltıcı)
- v2 B1: **2 gün** (PaymentAllocation entity + repo + service test + frontend) — C3 ile uyumlu

## 5. Revize Önceliklendirme Matrisi

| # | İş | Değer | Efor (1.5x) | Öncelik | Sprint |
|---|---|---|---|---|---|
| **B1** | Alışveriş bazlı ödeme + PaymentAllocation many-to-many | Y | 2 gün | P1 | **7** |
| **T1-T4** | Kritik path testleri (B1 + reconcile + credit + FK) | Y (drift sigorta) | 1.6 gün | P1 | **7** |
| **I2** | Error boundary | Y | 1.5 gün | P1 | **7** |
| **B5** | Hızlı tahsilat butonu | O | 1 gün | P2 | **7** (opsiyonel) |
| **B0** | Pagination (eski I1) | Y | 4-5 gün | P1 | **8** (Sprint 7'den taşındı) |
| **B8** | Overdue notification (eski I3) | O | 3 gün | P2 | 8 |
| **B9** | Activity history (eski I4) | O | 1.5-2 gün | P2 | 8 |
| **B6** | Yaşlandırma raporu | O (yönetici) | 3-4 gün | P2 | 8 |
| **B3** | Toplu ödeme (PaymentAllocation many-to-many UI) | O | 1.5-2 gün (B1 sonrası kolay) | P2 | 9 |
| **I5** | Test coverage geniş kapsam | O-D | 4-7 gün | P2 | 9 (kritik path zaten Sprint 7'de) |
| **B2** | Plaka Opsiyon B/C | D | 5-10 gün | P3 | feedback bekle |
| **B4** | Taksitli ödeme | D | 6-7 gün | P3 | feedback bekle |
| **B7** | SMS bildirim | D | 3-6 gün + entegrasyon | P3 | feedback bekle |

## 6. Riskler ve Bağımlılıklar (yeni — yapısal öneri)

| Risk | Etki | Önlem |
|---|---|---|
| **R1** B1 → B3 sessiz şema bağımlılığı | B3'te migration acısı | ✅ B1'de baştan PaymentAllocation many-to-many ([§4](#4-b1-yeniden-tasarımı--paymentallocation-baştan-c4-düzeltme)) |
| **R2** Test güvenlik ağı yokken finance değişikliği | Drift fark etmek haftalar sürer | ✅ T1-T4 Sprint 7'de zorunlu ([§2](#2-test-stratejisi-c1-düzeltme--yeni-p1)) |
| **R3** I2 error boundary yokken pagination async race | Kullanıcı boş ekran görür, log eksik | I2 → B0 öncesi (Sprint 7 → Sprint 8 sıra korunur) |
| **R4** B6 (yaşlandırma) → B8 (notification) bağımlılığı | Notification kuralı yaş aralıklarına bağlı | B6 önce, B8 onunla aynı sprint'te |
| **R5** B5 (hızlı tahsilat ana menü) → B1 dependency | Modal call site farklı, B1 tamamlanmamışsa eski API'ye fallback | B5 Sprint 7'ye opsiyonel — B1'in API stabil olduktan sonra |
| **R6** PaymentAllocation entity → reconcile job güncellemesi | `Sale.paidAmount` artık SUM allocations'tan hesaplanır | Reconcile job da güncellenmeli, T2 testi bunu kapsasın |

## 7. "Done" Tanımı (yeni — yapısal öneri)

Her madde için kabul kriteri:

| Kriter | Açıklama |
|---|---|
| 🟢 **Kod** | Implementation tamamlandı, lint geçer, build başarılı |
| 🟢 **Test** | Unit + integration test yazıldı, CI green (B1 için T1-T4 dahil) |
| 🟢 **Wiki** | İlgili entity/concept/issue sayfası güncel, decisions/'a ADR eklendi (mimari değişiklik varsa) |
| 🟢 **Migration** | DB schema değişikliği varsa data.sql + migration script + rollback plan |
| 🟢 **Manuel test** | Kritik flow real DB ile end-to-end test (örn. B1: 3 farklı müşteriye 5 ödeme akışı, reconcile sonrası drift = 0) |
| 🟢 **Metrik baseline** | Performance/davranış değişikliği varsa before/after sayım (§8) |

Bu standart Sprint 7'den itibaren her madde için zorunlu. PR template'e checklist olarak eklenebilir.

## 8. Metrikler — Mevcut Boşluklar ve Hedefler (yeni — yapısal öneri)

### Şu An Ölçülmeyen (boşluk)
- Reconcile drift sayısı (kaç tenant'ta kaç hesapta drift bulundu, ortalama tutar farkı)
- Statement load süresi (p50/p95/p99 — Sprint 5 perf optimizasyon yapıldı ama before/after rakam yok)
- Payment creation latency (modal aç → kayıt → liste güncelle)
- Failed payment rate (kullanıcı modal'ı açıp iptal mi etti, hata mı aldı)
- Test coverage % (henüz ölçülmüyor)

### Hedefler (Sprint 7 sonrası)
| Metrik | Hedef |
|---|---|
| Reconcile drift saptama gecikmesi | < 24 saat (nightly job) |
| Statement load p95 | < 1 saniye (DB-side aggregate fix sonrası ölçülecek) |
| Payment creation roundtrip p95 | < 500 ms |
| Finance modülü test coverage (kritik path) | %80+ (T1-T4 zorunlu) |
| Drift fix MTTR | < 1 gün (manuel reconcile sonrası) |

### Aksiyon
- **Prometheus/Micrometer entegrasyonu** zaten var ([[syntheses/integration-prometheus-micrometer]]) → metrik ekleme kolay
- Sprint 7'de B1 ile birlikte **payment creation timer** eklenmeli
- Sprint 8'de **drift dashboard** (Grafana panel) — yönetici görünürlüğü için B6'nın parçası olabilir

## 9. Revize Sprint 7 (gerçekçi)

| İş | Efor | Açıklama |
|---|---|---|
| B1 (PaymentAllocation many-to-many baştan) | 2 gün | C4 + C3 birleşik |
| T1-T4 (kritik path testleri) | 1.6 gün | C1 düzeltmesi, B1 ile paralel kısmi |
| I2 (Error boundary) | 1.5 gün | UX sağlamlaştırma |
| B5 (Hızlı tahsilat — opsiyonel) | 1 gün | Kalan süreyle, B1 stabil olduktan sonra |

**Net iş: ~5-6 gün** + review/test/buffer = 1 hafta → gerçekçi.

**B0 (pagination) Sprint 8'e taşındı** — C5 düzeltmesi.

## 10. Wiki'de Eksik Bilgi

- `concepts/payment-allocation` — B1'in many-to-many tasarımı için yeni concept sayfası açılmalı (B1 implementasyon sırasında)
- `entities/payment-allocation` — entity sayfası
- `decisions/payment-allocation-from-day-1` — ADR (B1↔B3 bağımlılık kararı)
- `concepts/finance-test-strategy` — T1-T4 + sürekli test kuralı için
- `decisions/test-required-for-finance-merge` — kural ADR

Bu 5 sayfa B1 implementasyon başlarken aynı PR'da yazılmalı (Done kriteri: wiki güncel).

## 11. Kaynak Referansları (v1'e ek olarak)

- v1: [[syntheses/accounts-development-analysis-2026-04-25]] (mimari özet + sprint tarihçesi + kaynak listesi v1'de tam)
- Bu v2'nin tetikleyicisi: kullanıcı critique 2026-04-25
- B1 ↔ B3 bağımlılık argümanı: [[concepts/append-only]] (audit zinciri) + [[concepts/denormalization-with-reconcile]] (Sale.paidAmount derived)
- Test stratejisi tetikleyicisi: [[issues/test-coverage-unknown]] + [[concepts/drift]] (drift fark etme MTTR)
- Metrikler entegrasyon adayı: [[syntheses/integration-prometheus-micrometer]]

## Related

- [[syntheses/accounts-development-analysis-2026-04-25]] (v1 — superseded)
- [[syntheses/accounts-hub-production-readiness]]
- [[syntheses/lint-action-plan-2026-04-25]]
- [[syntheses/codebase-snapshot-2026-04-25]]
- [[issues/test-coverage-unknown]] (artık P1)
