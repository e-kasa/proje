---
title: Untyped Map<String, dynamic> API Pattern
tags: [concept, api, dart, risk]
date: 2026-04-24
status: verified
---

# Untyped Map<String, dynamic> API

## Tanım
Client (Flutter) backend'den gelen response'u typed DTO yerine `Map<String, dynamic>` olarak kullanır. Alan erişimi `map['key']` üzerinden.

## SEDCORE'da Neden
Backend `toMap()` pattern'i çoğu liste endpoint'inde `Map<String, Object>` döner (bkz. `.claude/wiki/patterns/dto-tomap-pattern`). OpenAPI codegen henüz yok — client typed model generate etmiyor.

## Örnek Kullanım
```dart
// statement_detail_panel.dart
final opening = (s['openingBalance'] ?? 0).toDouble();
final transactions = List<Map<String, dynamic>>.from(s['transactions'] ?? []);
```

## Riskler

1. **Silent field rename** — backend `balance` → `currentBalance` yaptığında client `m['balance']` sessizce null okur, 0 gösterir (bkz. `.claude/wiki/issues/supplier-list-balance-zero`)
2. **Wrong field name** — client `p['type']` yazdığında backend `paymentType` → filter hiç eşleşmez (bkz. `.claude/wiki/issues/today-collection-always-zero`)
3. **Tip hatası runtime'da yakalanır** — `as num?` cast compile-time check yok
4. **IDE refactoring zayıf** — alan adı değişince Find Usages çalışmaz

## Azaltma
- Kod review'da backend DTO adı ↔ client key manual eşleştirme
- Sprint 3 planlı: OpenAPI codegen → typed Dart model (`.claude/wiki/syntheses/accounts-hub-production-readiness` P1.2)

## Related
- [[entities/statement-detail-panel]]
- [[entities/accounts-notifiers]]
- `.claude/wiki/patterns/dto-tomap-pattern`
- `.claude/wiki/issues/today-collection-always-zero`
- `.claude/wiki/issues/supplier-list-balance-zero`
