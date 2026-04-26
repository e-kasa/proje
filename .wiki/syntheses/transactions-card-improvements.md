---
title: Cari Geçmişi (İşlemler Kartı) — İyileştirme Planı
type: synthesis
source: .claude/wiki/syntheses/transactions-card-improvements.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Cari Geçmişi (İşlemler Kartı) — İyileştirme Planı

`statement_detail_panel.dart` içinde seçili cariye ait işlemleri listeleyen `_TxRow` kartının geliştirilmesi. Backend zaten zengin veri dönüyor — Flutter tarafı bunun **yarısından azını** kullanıyor.

## Mevcut Durum

### UI (`_TxRow` render edilen alanlar)

- Sol renkli bar (borç kırmızı / alacak yeşil)
- Açıklama (`description`) + tarih (`transactionDate`)
- Tutar (`+creditAmount` / `-debitAmount`) + çalışan bakiye (`runningBalance`)

### Backend (`AccountStatementEntry.TransactionLine`)

`AccountStatementEntry.java` zaten tüm bu alanları dönüyor:

| Alan | Flutter'da Kullanılıyor? |
|------|--------------------------|
| `id` | Yok — satıra tıklama için gerekli |
| `transactionDate` | Var |
| `transactionType` (enum) | Yok — **13 farklı tip** var, hiçbiri ayırt edilmiyor |
| `description` | Var |
| `referenceNumber` | Yok — fiş/referans kaybı |
| `debitAmount` / `creditAmount` | Var |
| `runningBalance` | Var |

### TransactionType Enum (13 değer)

| Tip | Yön | Yaygın? |
|-----|-----|---------|
| SALE | Borç | Müşteri |
| PURCHASE | Borç | Tedarikçi |
| PAYMENT | Alacak | Müşteri tahsilatı |
| SUPPLIER_PAYMENT | Alacak | Tedarikçiye ödeme |
| COLLECTION | Alacak | Tahsilat |
| RETURN / SUPPLIER_RETURN | Alacak | İade |
| CANCEL | Alacak | İptal |
| DISCOUNT | Alacak | Sonradan indirim |
| LATE_FEE | Borç | Vade gecikme |
| ADJUSTMENT_DEBIT/CREDIT | Manuel | Düzeltme |
| REFUND | Alacak | İade |

## İyileştirme Roadmap'i

### P0 — Yüksek Değer / Düşük Maliyet

#### P0.1 — `transactionType` → İkon + Chip
Backend zaten enum dönüyor, Flutter'da **hiç kullanılmıyor**. Her satıra tip-spesifik ikon + küçük chip:

| Tip | İkon | Chip Rengi |
|-----|------|------------|
| SALE / PURCHASE | `Icons.point_of_sale` | primary |
| PAYMENT / COLLECTION | `Icons.payments_outlined` | success |
| SUPPLIER_PAYMENT | `Icons.outgoing_mail` | success |
| RETURN / SUPPLIER_RETURN | `Icons.undo` | warning |
| CANCEL | `Icons.cancel_outlined` | danger |
| DISCOUNT | `Icons.discount_outlined` | info |
| LATE_FEE | `Icons.warning_amber_rounded` | danger |
| ADJUSTMENT_* | `Icons.tune` | muted |
| REFUND | `Icons.keyboard_return` | warning |

**Faydası:** Kullanıcı "bu satır ödeme mi, iade mi, düzeltme mi" diye açıklama metnini okumak zorunda kalmaz.

#### P0.2 — `referenceNumber` Satır Altında
Fiş/referans numarasını `description` altında küçük gri etiket olarak göster.

#### P0.3 — Tahsilat/Ödeme Kaydet Butonu Bağla
`_Header` içinde edit + PDF butonlarının yanına `Icons.payments_outlined` (tahsilat) veya `Icons.outgoing_mail` (ödeme) ekle; `PaymentRecordModal.show(context, isCustomer: ...)` çağır.

### P1 — UX Olgunluk

#### P1.1 — İşlem Tipi Filtresi
Yatay scrollable chip bar: "Tümü" / "Satışlar" / "Ödemeler" / "İadeler" / "Düzeltmeler"

#### P1.2 — Tarihe Göre Gruplama
"Bugün", "Dün", "Bu Hafta", ayrı ayrı aylar header'ları.

#### P1.3 — `ListView.builder` (Performance)
`CustomScrollView` + `SliverList.builder` — 500+ tx olan müşteride yavaşlamayı önler.

### P2 — Gelişmiş Özellikler

#### P2.1 — Satıra Tıkla → Referans Detayı
`referenceType=SALE` + `referenceId` dolu işlemde fiş modal'ı (sale receipt).

#### P2.2 — Tablo Görünümü + Alt Toplam
Geniş ekranda (≥800px) kolon başlıklı tablo. Toggle: "Card" / "Table" view.

#### P2.3 — CSV / Excel Export
Mevcut `StatementPdfService` var. CSV için Flutter `csv` paketi + share_plus.

### P3 — İleri

- Server-side pagination
- Filter'ın backend tarafına taşınması (URL query param)
- İşlem üzerinde audit trail

## Sistem Uyumluluğu (CLAUDE.md Kuralları)

- **Riverpod + StateNotifier autoDispose** — filter state mevcut `accountStatementProvider` içinde `filter` alanı (+setFilter action)
- **AppColors / AppCard / AppEmptyState** — mevcut örnek `_TxRow` zaten kullanıyor
- **i18n zorunlu** — yeni label'lar `ac.` prefix (accounts) + `data.sql` `bnd-acXXNN-0000-0000-NNN` ID formatı
- **Null safety** — backend typed DTO (`AccountStatementEntry`) döner — `dto-tomap-pattern`'den FARKLI

## Kapsam Dışı

- Backend TransactionLine alanı ekleme/çıkarma (mevcut alan seti yeterli)
- Drift reconcile mantığına müdahale ([[syntheses/flow-drift-reconciliation]] ayrı)
- Sale/Payment entity schema değişikliği

## Sources

- [[entities/account-transaction]] (ledger semantiği)
- [[entities/payment]] (tahsilat/ödeme)
- [[syntheses/flow-accounts-hub-load]] (load chain)
- [[syntheses/accounts-overview]] (genel bakış)
- [[syntheses/accounts-hub-production-readiness]] (P1.3, P2.3, P2.6 ile çakışıyor)
- Kullanıcı talebi 2026-04-24 — "cari geçmişi kartı geliştirme planlama"

## Related

- [[syntheses/account-edit-form-ux]] (aynı panel, edit akışı)
- [[concepts/pattern-dto-tomap-pattern]] (contrast: bu endpoint typed, güvenli)
