---
title: Bugünkü Tahsilat Hep 0 Gösteriyordu (RESOLVED)
tags: [issue, resolved, accounts, silent-null]
date: 2026-04-25
status: resolved
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\issues\today-collection-always-zero.md
---

# Today Collection Always Zero

**Kök neden**: Backend response `transactionDate` alanı, Flutter client `paymentDate` okuyordu — silent null ([[concepts/silent-null-bug]]).

**Fix**: Client tarafı düzeltildi; motivasyon kaynağı [[decisions/openapi-incremental-migration]] (typed client ile sınıf olarak çözülecek).

## Sources

- `.claude/wiki/issues/today-collection-always-zero.md`

## Related

- [[concepts/silent-null-bug]]
- [[concepts/typed-api-contract]]
