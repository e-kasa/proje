---
title: AccountsSummaryBar
tags: [entity, widget, flutter, summary]
source: project_pos/lib/features/accounts/widgets/accounts_summary_bar.dart
date: 2026-04-24
status: draft
---

# AccountsSummaryBar

## Amaç
[[entities/accounts-hub-screen]]'in ÜST barı. **4 özet kartı** yatay düzende:
1. **Müşteri Alacağı** — `summary['totalCustomerReceivable']`
2. **Tedarikçi Borcu** — `summary['totalSupplierPayable']`
3. **Vadesi Geçen** — `summary['totalOverdueAmount']`
4. **Bugünkü Tahsilat** — client-side filter (`_todayCollection`)

## Tip
`ConsumerWidget` (stateless — provider watch yeterli).

## Watched Providers
- `accountSummaryProvider` → [[entities/accounts-notifiers]] `AccountSummaryNotifier.summary` Map
- `paymentListProvider` → finance payment list (bugünkü tahsilat filter kaynağı)

## Kritik Fonksiyon: `_todayCollection(payments)`

Client-side filter:
```dart
return payments
  .where((p) =>
    p['customerId'] != null &&
    (p['paymentDate']?.toString() ?? '').startsWith(todayKey) &&
    p['isCancelled'] != true)
  .fold<double>(0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0));
```

**Geçmiş bug**: `p['type']` ve `p['date']` alan adları yanlıştı — backend `paymentType` / `paymentDate` bekliyor. Bkz. [[issues/today-collection-always-zero-ref]] + `.claude/wiki/issues/today-collection-always-zero`.

## Responsive Davranış

Tüm kartlar yatay `Row` — genişlik yetmezse `Wrap` fallback olabilir (kod detayı). Hub breakpoint 800px'i bu bar paylaşmaz — her boyutta görünür.

## Tuzaklar

- `summary` null ise (loading) her kart `0 TL` gösterir — loading indicator ayrı olabilir (şu an fade etkisi yok)
- Client filter tip-unsafe — backend alan adı değişirse sessizce 0 ([[concepts/untyped-map-api]])
- Bugünkü tahsilat sadece müşteri tarafı (`customerId != null`) — tedarikçi ödemeleri kapsam dışı (bilinçli, "tahsilat" = gelen)

## Sources
- project_pos/lib/features/accounts/widgets/accounts_summary_bar.dart
- pos-product-manager/src/main/java/com/sedcore/finance/model/PaymentResponse.java (field sözleşmesi)
- [[sources/screens/2026-04-24-accounts-hub-screen]]

## Related
- [[entities/accounts-hub-screen]]
- [[entities/accounts-notifiers]]
- [[flows/today-collection-calc]]
- [[issues/today-collection-always-zero-ref]]
- [[concepts/untyped-map-api]]
