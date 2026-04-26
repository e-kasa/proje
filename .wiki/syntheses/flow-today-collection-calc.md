---
title: Flow — Today Collection Calculation
type: synthesis
source: .claude/wiki/flows/today-collection-calc.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Today Collection Calculation

## Amaç
AccountsHub 4. özet kartı: "Bugünkü Tahsilat". Bugün alınan müşteri ödemelerinin toplamı.

## Algoritma (Client-Side Filter)

```dart
// accounts_summary_bar.dart — düzeltilmiş hâli
return payments
  .where((p) =>
      p['customerId'] != null &&                       // tahsilat yönü
      (p['paymentDate']?.toString() ?? '').startsWith(todayKey) &&
      p['isCancelled'] != true)
  .fold<double>(0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0));
```

## Neden Server-Side Değil

- Endpoint `/payments` zaten günlük payment listesi dönüyor
- Ekstra endpoint açmak yerine client tarafında filter ucuz
- Müşteri/tedarikçi ayrımı + iptal filtresi client-side basit

## Tuzaklar (Geçmişte)

- `p['type'] == 'income'` → BACKEND'DE YOK. `paymentType` (CASH/CREDIT_CARD/...) var, income/expense yok
- `p['date']` → BACKEND'DE YOK. `paymentDate` var
- `isCancelled` filtresi olmadan iptal edilen ödemeler sayılıyordu

Bkz. [[issues/today-collection-always-zero]]

## Yön Tespiti

```
customerId != null → müşteriden gelen (tahsilat, income)
supplierId != null → tedarikçiye giden (ödeme, expense)
```

`PaymentResponse`'da `type: income|expense` alanı **yoktur** — yön bu FK'larla anlaşılır.

## Sources

- [[sources/code-refs/2026-04-21-accounts-hub-screens]]
- project_pos/lib/features/accounts/widgets/accounts_summary_bar.dart
- pos-product-manager/src/main/java/com/sedcore/finance/model/PaymentResponse.java

## Related

- [[entities/payment]]
- [[syntheses/flow-accounts-hub-load]]
- [[issues/today-collection-always-zero]]
