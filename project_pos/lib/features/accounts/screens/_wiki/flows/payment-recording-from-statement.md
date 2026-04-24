---
title: Payment Recording from Statement — Ekstreden 1-Tık Ödeme
tags: [flow, payment, statement, ux]
source: project_pos/lib/features/accounts/widgets/statement_detail_panel.dart (_handlePayment)
date: 2026-04-24
status: verified
---

# Payment Recording from Statement

## Amaç

Seçili cari hesabın ekstresini açmışken kullanıcının tahsilat (müşteri) veya ödeme (tedarikçi) kaydını tek modalda tamamlayabilmesi. Önceden [[issues/statement-panel-missing-payment-button]] → ekran geçişi gerektiriyordu.

## Tetikleyici

[[entities/statement-detail-panel]] `_Header` → `onPayment: () => _handlePayment(context, ref, selected)` callback (action row'unda `Icons.payments_outlined` butonu).

## Akış

```
_Header payment button onTap
  → _handlePayment(context, ref, account)
  ├─ isCustomer = account.accountType == 'CUSTOMER'
  ├─ result = await PaymentRecordModal.show(context, isCustomer, accountName)
  ├─ if (result == null || !context.mounted) return      ← kullanıcı iptal
  │
  ├─ payload = {
  │     amount, paymentType,
  │     customerId or supplierId,
  │     bankName?, referenceNumber?, description?
  │   }
  │
  ├─ try:
  │    await paymentServiceProvider.createPayment(payload)   ← POST /product/api/v1/payments
  │    AppToast.success(t('ac.payment_saved'))
  │    await Future.wait([
  │      accountStatementProvider.load(),   ← ekstre satırları refresh
  │      accountSummaryProvider.load(),     ← hub üst kart (bakiye özet)
  │      accountsListProvider.load(),       ← liste (bakiye güncelle)
  │      paymentListProvider.load()         ← ödeme tab'ı / rapor
  │    ])
  │
  └─ catch (e):
       AppToast.error(t('common.error') + e)
```

## Side Effects

| Provider / Backend | Etki |
|---|---|
| `paymentServiceProvider.createPayment` | Payment entity insert |
| Backend — AccountTransaction | Type=COLLECTION (customer) veya PAYMENT (supplier) |
| Backend — CustomerAccount/SupplierAccount | currentBalance ↓, totalCredit ↑ (customer tahsilat) / ↑ totalCredit (supplier ödeme) |
| `accountStatementProvider` | Yeni satır görünür (refresh) |
| `accountSummaryProvider` | Hub özet kart bakiye güncellenir |
| `accountsListProvider` | Liste rowunun bakiye bilgisi güncellenir |
| `paymentListProvider` | Ödeme tab'ında yeni kayıt |

## Hata Yolları

| Durum | UX |
|---|---|
| Kullanıcı modal'ı iptal eder | Sessiz return, state değişmez |
| Network / backend 4xx/5xx | `AppToast.error` kırmızı banner + hata mesajı |
| `context.mounted == false` await sonrası | Sessiz return (widget ağaçtan söküldü) |

## UX Kararları

- **Buton yeri**: header action row'da edit + PDF'in yanında 5. buton. Tooltip `isCustomer` göre değişir: "Tahsilat Al" vs "Ödeme Yap"
- **Icon**: `Icons.payments_outlined` + `AppColors.success` (yeşil) — para girişi sinyali
- **Modal**: `PaymentRecordModal` mevcut form; tutar + ödeme tipi (CASH/CREDIT_CARD/BANK_TRANSFER/CHECK) + banka + ref + açıklama
- **Toast**: success 2sn, error infinite (kullanıcı dismiss eder)
- **Optimistic**: yok — gerçek backend yanıtı beklenir, başarısızsa hata gösterilir

## Plaka Alanı (Sektör Notu)

Yedek parça sektöründe "X plakasına ait satışın ödemesi" ihtiyacı — bu modal'da şu an **plaka alanı yok**. [[syntheses/payment-recording-and-vehicle-tracking]] Sprint 6b'de A/B/C kararına göre:

- **A (pragmatik)**: modal'a opsiyonel `plate` text field, `description` içine "plaka:XX" append
- **B/C**: modal'a plaka alanı + backend Payment.vehiclePlate / CustomerVehicle.id zenginleştirmesi

## Sources

- `project_pos/lib/features/accounts/widgets/statement_detail_panel.dart:178-215` (_handlePayment)
- `project_pos/lib/features/accounts/screens/payment_record_modal.dart` (modal form)
- `project_pos/lib/features/accounts/services/payment_service.dart` (createPayment)
- `.claude/wiki/entities/payment.md` (backend entity)

## Related

- [[entities/statement-detail-panel]]
- [[entities/account-service]]
- [[flows/statement-load-flow]] (reload sonrası akış)
- [[issues/statement-panel-missing-payment-button]] (resolved by this flow)
- [[syntheses/payment-recording-and-vehicle-tracking]] (Sprint 6b devam)
