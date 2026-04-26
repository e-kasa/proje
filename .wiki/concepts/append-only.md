---
title: Append-Only Semantiği
tags: [concept, pattern, ledger, audit]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\entities\account-transaction.md
date: 2026-04-25
status: stub
---

# Append-Only

Kayıtların insert edildikten sonra **değiştirilmediği** tablo semantiği. İptal için ayrı kayıt veya flag (soft cancel) kullanılır; fiziksel UPDATE yok.

SEDCORE'da:
- [[entities/account-transaction]] — `isCancelled=true` soft cancel
- [[entities/stock-movement]] — ters kayıt (SALE_CANCEL_IN) insert

"Logical append-only" — küçük mutate alanlar kabul edilebilir (isCancelled, `cancel(user)`); [[concepts/optimistic-lock-version]] bu UPDATE'leri korur.

## Sources

- [[raw/code-refs/2026-04-25-ledger-version-adr]]
- `.claude/wiki/entities/account-transaction.md`

## Related

- [[entities/account-transaction]]
- [[entities/stock-movement]]
- [[concepts/ledger-vs-denormalize]]
