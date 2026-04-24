---
title: Overdue-Aware List Ordering
tags: [decision, ux, data-flow]
date: 2026-04-24
status: active
---

# Overdue-Aware List Ordering

## Karar
[[entities/accounts-list-panel]] liste yüklenmeden önce [[entities/accounts-notifiers]] `AccountSummaryNotifier` tamamlanmış olmalı. Sebep: summary'den `overdueIds` set gelir, list "vadesi geçen" filter + badge için bu set'e bakar.

## Uygulama

[[entities/accounts-hub-screen]] `initState`:

```dart
WidgetsBinding.instance.addPostFrameCallback((_) async {
  await ref.read(accountSummaryProvider.notifier).load();  // ← await
  ref.read(paymentListProvider.notifier).load();            // fire-and-forget
  ref.read(accountsListProvider.notifier).load();           // summary sonrası
});
```

`summary.load()` **await** — list ondan sonra. `paymentListProvider` ayrı akışta (bugünkü tahsilat için), liste onu beklemez.

## Alternatif (Red)
Liste summary'den bağımsız yüklensin → overdue filter tıklandığında empty veya eksik sonuç. UX kötü.

## Related
- [[entities/accounts-hub-screen]]
- [[entities/accounts-list-panel]]
- [[entities/accounts-notifiers]]
