---
title: Sentinel Object for Null-Safe copyWith
tags: [concept, dart, pattern]
date: 2026-04-24
status: verified
---

# Sentinel Object for Null-Safe copyWith

## Problem
Dart immutable class'larda `copyWith` yazarken `null` iki farklı anlama gelir:
- "Bu alanı değiştirme (varsayılan)"
- "Bu alanı `null`'a set et (reset)"

Normal `copyWith` bu ikisini ayırt edemez:
```dart
copyWith({String? error}) {
  error: error ?? this.error;  // null → reset değil, "değiştirme"
}
```

## Çözüm: Sentinel
Global sabit bir obje:
```dart
const _sentinel = Object();

copyWith({Object? error = _sentinel}) {
  error: error == _sentinel ? this.error : error as String?;
}
```

Çağıran:
- `copyWith()` → error korunur (default = `_sentinel`)
- `copyWith(error: null)` → error **gerçekten null'a** set edilir
- `copyWith(error: 'x')` → error 'x'

## SEDCORE Uygulaması
[[entities/accounts-notifiers]] `AccountSummaryState`, `OverdueTrackingState`, `AccountStatementState` hepsi bu pattern'i kullanır:
- `error` field reset edilmek istendiğinde (yeni load başlarken) `copyWith(error: null)`
- Diğer state update'lerde error korunur

## Related
- [[entities/accounts-notifiers]]
- [[decisions/sentinel-object-for-nullable-copy-with]]
