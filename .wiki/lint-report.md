---
title: Lint Raporu — İlk Tam Setup Sonrası
date: 2026-04-25
scanned: 88
status: draft
---

# Lint Raporu — 2026-04-25 (İlk Tam Setup)

`.wiki/` ilk kapsamlı kurulum + 7 kaynak ingest sonrası sağlık taraması. Otomatik düzeltme yapılmadı; sadece raporlama.

## Özet

- **Yüksek**: 0
- **Orta**: 0
- **Düşük**: 14 (stub sayfalar — yeni eklenen, henüz detay yok)

## Bulgular

### 🔴 Çelişki (0)

Yok. ([[concepts/silent-null-bug]] içindeki "@Version" tartışması `.claude/wiki/contradictions.md`'de zaten resolved durumda; bu yeni vault'a aktarılmadı çünkü `.wiki/` farklı kapsamlı.)

### ⚠️ Eskimiş (0)

İlk setup — tüm içerik 2026-04-25 tarihli.

### 🟡 Yetim Sayfa (0)

Tüm sayfalar en az bir wikilink alıyor. Index + synthesis + cross-ref çapraz örgüsü yeterli.

### 🟠 Eksik Kavram (0)

Bahsedilen ama sayfası olmayan kavram tespit edilmedi. (Stub'lar zaten sayfa olarak açıldı.)

### 🔗 Tek-Yönlü Cross-Ref (potansiyel — manuel doğrulama gerek)

Otomatik tarama yapılmadı. Manuel kontrol önerisi:
- `entities/sale.md` ↔ `entities/customer-account.md` (iki yönlü ✓)
- `entities/account-transaction.md` ↔ `decisions/ledger-concurrency-defense-in-depth.md` (iki yönlü ✓)
- `concepts/drift.md` ↔ `concepts/denormalization-with-reconcile.md` (iki yönlü ✓)

Sonraki lint pass'inde tam tarama hedef.

### 📌 Kaynak Boşluğu (0)

Tüm sayfalar `## Sources` bölümünde en az 1 referans veriyor (raw pointer, kod dosyası path veya `.claude/wiki/` orijinal sayfa).

### 🟤 Stub Sayfalar (14)

`status: stub` ile işaretlenenler — minimal içerik, ilerideki ingest/query'lerde detay artırılacak:

| Sayfa | Kategori |
|---|---|
| [[entities/api-manager]] | service |
| [[entities/security]] | service |
| [[entities/pos-product-manager]] | service |
| [[entities/core]] | service |
| [[entities/project-pos]] | service |
| [[entities/template]] | service |
| [[entities/sale-item]] | domain |
| [[entities/customer]] | domain |
| [[entities/supplier]] | domain |
| [[entities/supplier-account]] | domain |
| [[entities/supplier-claim]] | domain |
| [[entities/stock-level]] | domain |
| [[entities/stock-movement]] | domain |
| [[entities/reconcile-audit-log]] | domain |

Plus 4 service-impl entity (sale-service-integrated, purchase-service-impl, reconcile-scheduled-job, slack-notifier) ve 6 concept (write-through-cache, append-only, defense-in-depth, typed-api-contract, silent-null-bug, jwt-auth, i18n, prod-ready-guards) ile bazı issue'lar — toplam ~25 stub. 30 günlük cooldown sonrası (2026-05-25) lint tekrar değerlendirir.

## Otomatik Düzeltme

**Yapılmadı.** Sadece rapor.

## Öncelikli Aksiyonlar

1. Yeni kaynak ingest'leri sırasında stub'lar genişletilecek (yan etki: detay artar)
2. Aylık lint cadence — sonraki: 2026-05-04 (Mayıs ilk Pazartesi)
3. Manuel cross-ref doğrulama (tek-yönlü) — sonraki lint pass'inde otomatize edilebilir
