---
title: StateNotifier vs AsyncNotifier — Riverpod migration özeti
type: concept
source: project_pos/lib/features/inventory/screens/batch_entry/providers/batch_entry_provider.dart
ingested: 2026-04-25
last-verified: 2026-04-25
status: stub
---

# StateNotifier vs AsyncNotifier

## Tanım

Riverpod 2.x state yönetimi — proje şu an **`StateNotifier`** (legacy) kullanıyor; ADR `AsyncNotifier`'a geçiş hedefi koyuyor (sprint 3 kararı, henüz kod migrasyonu yok).

## Mevcut Durum (2026-04-25 tarama)

| Pattern | Occurrence |
|---|---|
| `extends StateNotifier<T>` | 18 dosyada 29 kullanım |
| `extends AsyncNotifier<T>` | **0** |

**Geçiş henüz başlamadı.**

## Örnek Mevcut Kullanım

```dart
// project_pos/lib/features/inventory/screens/batch_entry/providers/batch_entry_provider.dart:29
class BatchEntryNotifier extends StateNotifier<BatchEntryState> {
  final Ref ref;
  BatchEntryNotifier(this.ref) : super(BatchEntryState.initial());
  ...
}
```

Diğer örnekler: `pos_provider.dart`, `auth_provider.dart`, `accounts_notifiers.dart`.

## Karar Referansı

Root `CLAUDE.md` §8: 
> "State management: Riverpod 2.x `StateNotifier` → `AsyncNotifier` (sprint 3)"

`.wiki/decisions/` altında özel ADR yok — bu sayfa kararın özetidir.

## AsyncNotifier'ın Avantajı

- Loading/error/data state'ini doğal modeller (`AsyncValue<T>`)
- Manuel `try/catch` + `isSubmitting` flag'leri azalır
- `.future` ile auto-refresh + cache eviction kolaylaşır

## Migration Riskleri

- `autoDispose` semantiği farklı (subscription-based)
- `family` parametre passing değişir (`AsyncNotifierProviderFamily`)
- Her notifier ayrı migration sprint'i ister — büyük PR yerine modül bazlı geçiş öneriyor

## Sıralı Geçiş Önerisi

1. **Kolay olanlar**: read-only providers (örn. `accountSummaryProvider`).
2. **Orta**: tek action'lı notifier'lar (`paymentService` çağıran).
3. **Zor**: kompleks state machine (`BatchEntryNotifier` — 10+ method, alt state'ler).

## Related

- [[concepts/batch-entry-state]]
- [[entities/project-pos]]
- [[concepts/batch-row-status]]
