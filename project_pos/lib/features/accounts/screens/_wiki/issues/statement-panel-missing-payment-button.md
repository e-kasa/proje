---
title: StatementDetailPanel — Ödeme Al/Yap Butonu Yok
tags: [issue, resolved, ux-gap]
date: 2026-04-24
status: resolved
resolved-date: 2026-04-24
resolved-by: "transactions-card P0 (commit history: payment button bind) — Sprint 6a kapsamında sayılır"
priority: medium
---

# StatementDetailPanel'da Ödeme Butonu Yok — RESOLVED 2026-04-24

**Çözüm**: `statement_detail_panel.dart:_handlePayment` implement edildi (transactions card P0.3 scope'unda). Akış:

```dart
// statement_detail_panel.dart:178-215
PaymentRecordModal.show(context, isCustomer, accountName)
  → payload oluştur (customerId | supplierId + amount + paymentType + bankName + ref + desc)
  → paymentServiceProvider.createPayment(payload)
  → AppToast.success('ac.payment_saved')
  → Future.wait([
      accountStatementProvider.load(),
      accountSummaryProvider.load(),
      accountsListProvider.load(),
      paymentListProvider.load()
    ])
  → try/catch → AppToast.error('common.error: ...')
```

4 provider refresh → hub + list + detay + payment sayfaları senkron.

Akış: [[flows/payment-recording-from-statement]]

## (Orijinal Analiz) Belirti
Kullanıcı seçili bir cari hesabın ekstresini açıp doğrudan ödeme alamıyor / yapamıyor. Statement panel header'ında sadece **edit** + **PDF** butonları var. Tahsilat/ödeme için ayrı bir ekran/akış gerek.

## Mevcut
- [[entities/statement-detail-panel]] `_Header` → 4 buton: geri (mobile), tarih picker, edit, PDF
- `project_pos/lib/features/accounts/screens/payment_record_modal.dart` → **hazır form modal**, kimse çağırmıyor (ingest edilen kaynaklarda referans yok)

## Etki
- Müşteriden tahsilat almak için: ekstre → list'e dön → başka ekrana git → tahsilat kaydı → geri dön → ekstre refresh. Ergonomik olarak zayıf.
- Kullanıcı senaryosu [[syntheses/payment-recording-and-vehicle-tracking]]'te detaylandırıldı — vadeli satış + ödeme akışı için ekstre en doğal yer.

## Önerilen Fix
`_Header` action row'una 5. buton (icon + tooltip):

```dart
IconButton(
  icon: Icon(Icons.payments_outlined, color: AppColors.success),
  tooltip: isCustomer ? t('accounts.collect_payment') : t('accounts.record_payment'),
  onPressed: () => _handlePayment(context, ref, selected),
)
```

`_handlePayment` akışı:
1. `PaymentRecordModal.show(context, isCustomer, accountName)`
2. Null değilse → `paymentService.createPayment(customerId|supplierId, result[...])`
3. Success → `accountStatementProvider.load()` + `accountsListProvider.load()`
4. AppToast.success + optimistic UI

## Tahmini Efor
1-2 saat (client tarafı). Backend endpoint zaten mevcut (`PaymentService.createPayment`).

## İlgili Kararlar Gerekebilir
- Buton yeri — edit'ten önce mi sonra mı?
- Icon seçimi — `payments_outlined` yeterli mi?
- Supplier için "ödeme yap" semantiği — tedarikçiye giden para

## Related
- [[entities/statement-detail-panel]]
- [[syntheses/payment-recording-and-vehicle-tracking]]
- `project_pos/lib/features/accounts/screens/payment_record_modal.dart`
