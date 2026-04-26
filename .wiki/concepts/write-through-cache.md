---
title: Write-Through Cache
tags: [concept, pattern, cache, consistency]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\concepts\write-through-cache.md
date: 2026-04-25
status: stub
---

# Write-Through Cache

Her write işleminde hem ledger (ana kayıt) hem denormalize (özet) güncellenir. Tek `@Transactional` içinde commit edildiği için çoğunlukla tutarlılık garantili; sınır vakalarda (paralel write, commit fail) [[concepts/drift]] oluşur.

## Sources

- `.claude/wiki/concepts/write-through-cache.md`
- [[raw/code-refs/2026-04-25-sale-checkout-flow]]

## Related

- [[concepts/ledger-vs-denormalize]]
- [[concepts/drift]]
- [[concepts/denormalization-with-reconcile]]
