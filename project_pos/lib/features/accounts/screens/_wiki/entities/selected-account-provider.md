---
title: selectedAccountProvider
tags: [entity, provider, riverpod, state-bridge]
source: project_pos/lib/features/accounts/providers/selected_account_provider.dart
date: 2026-04-24
status: draft
---

# selectedAccountProvider

## Amaç
[[entities/accounts-list-panel]] ile [[entities/statement-detail-panel]] arasında **köprü state**. Hangi hesap seçili — nullable `StatementArgs?`.

## Tip
`StateProvider<StatementArgs?>` (basit state, notifier sınıfı yok).

## Değer

- `null` → seçim yok (ekstre panelinde empty state)
- dolu → `StatementArgs(accountType, accountId, accountName)` — hub satır tıkındığında set

## Write Paths

1. **List tap** → [[entities/accounts-hub-screen]] `_selectFromList(args)` → `ref.read(selectedAccountProvider.notifier).state = args`
2. **Navigator.pop (dar ekran)** → `.then((_) → state = null)` — [[issues/dar-ekran-yeniden-secim-bug]] fix
3. **Manuel temizleme** → edit modal'da "iptal"de tutulur (selection korunur), _Header geri butonunda temizlenir

## Read Paths

- [[entities/statement-detail-panel]] watch → empty state kontrolü (selection null mu)
- [[entities/accounts-hub-screen]] `selectedId` highlight → `ref.watch(selectedAccountProvider)?.accountId`
- [[entities/accounts-list-panel]] — highlight için `selectedId` prop parent'tan geçer

## Neden StateProvider (Notifier Değil)

İş mantığı yok (sadece set/get) → `StateProvider` yeterli. Complex load/error akışı [[entities/accounts-notifiers]] `AccountStatementNotifier`'a düşer; bu provider sadece **seçim kimliğini** tutar.

## Tuzaklar

- Null→null veya aynı args→aynı args set edilirse Riverpod listener notify etmez → detay widget rebuild olmaz ([[issues/dar-ekran-yeniden-secim-bug]])
- autoDispose **değil** (muhtemelen) — hub'dan başka ekrana gidip dönüldüğünde seçim korunur
- Seçim değişince `accountStatementProvider.setAccount(...)` ayrıca tetiklenmeli — iki provider otomatik senkron değil (hub `_selectFromList` ikisini birden yazar)

## Sources
- project_pos/lib/features/accounts/providers/selected_account_provider.dart
- project_pos/lib/features/accounts/models/statement_args.dart

## Related
- [[entities/accounts-hub-screen]]
- [[entities/accounts-list-panel]]
- [[entities/statement-detail-panel]]
- [[entities/accounts-notifiers]]
- [[concepts/master-detail-layout]]
- [[issues/dar-ekran-yeniden-secim-bug]]
