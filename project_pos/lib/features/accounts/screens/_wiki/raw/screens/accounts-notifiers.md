---
type: raw-pointer
immutable: true
kind: riverpod-providers
date: 2026-04-24
---

# Raw Pointer — accounts_notifiers.dart

**Dokunulmaz.**

## Dosya
`project_pos/lib/features/accounts/providers/accounts_notifiers.dart` (263 satır)

## İçerik
Üç `StateNotifier` + state sınıfları:
1. `AccountSummaryNotifier` + `AccountSummaryState` — özet + overdue list
2. `OverdueTrackingNotifier` + `OverdueTrackingState` — customer + supplier overdue
3. `AccountStatementNotifier` + `AccountStatementState` — ekstre detay

`const _sentinel = Object()` — copyWith null-safe reset için idiom.

## Bağımlılıklar
- `AccountService`
- `flutter_riverpod` 2.x
