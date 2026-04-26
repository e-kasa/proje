---
title: Today Collection Always Zero (detailed merge from .claude/wiki/)
type: issue
source: .claude/wiki/issues/today-collection-always-zero.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
status: resolved
note: "MERGE_NEEDED — overlap; this version has full Flutter code snippet + lessons learned."
---

# Bugünkü Tahsilat Her Zaman 0 TL

## Belirti
AccountsHub 4. özet kartı "Bugünkü Tahsilat" her zaman 0 TL gösteriyordu, gerçek tahsilat olsa bile.

## Kök Neden
Client-side filter yanlış alan adlarını okuyordu:
```dart
p['type'] == 'income'     // ← 'type' alanı YOK
p['date'] == todayKey     // ← 'date' alanı YOK
```

`PaymentResponse` gerçekte:
- `paymentType` (enum: CASH/CREDIT_CARD/...) — `type` değil
- `paymentDate` (LocalDateTime) — `date` değil
- Income/expense yok; yön `customerId != null` ile tespit edilir

Filter hiçbir zaman eşleşmiyordu → daima 0.

## Fix
```dart
payments.where((p) =>
    p['customerId'] != null &&
    (p['paymentDate']?.toString() ?? '').startsWith(todayKey) &&
    p['isCancelled'] != true)
```

## İlgili Dosyalar
- project_pos/lib/features/accounts/widgets/accounts_summary_bar.dart
- pos-product-manager/src/main/java/com/sedcore/finance/model/PaymentResponse.java

## Öğrenilen
Client-backend field adı dokümante edilmiyorsa sessizce çakışır. OpenAPI şeması Flutter'a import edilseydi erken yakalanırdı. Bkz. [[concepts/pattern-dto-tomap-pattern]] — tipsiz Map çıktısı bu riski artırır.

## Related
- [[entities/payment]]
- [[syntheses/flow-today-collection-calc]]
- [[sources/code-refs/2026-04-21-accounts-hub-screens]]
