---
title: Müşteri Liste Bakiyesi Hep 0 (RESOLVED)
tags: [issue, resolved, accounts, silent-null]
date: 2026-04-25
status: resolved
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\issues\customer-list-balance-zero.md
---

# Customer List Balance Zero

**Kök neden**: `CustomerControllerImpl.toMap` `currentBalance` eklemeyi atlamıştı → client `p['currentBalance']` null → 0.0.

**Fix**: toMap güncellendi + @EntityGraph ile account fetch.

## Sources

- `.claude/wiki/issues/customer-list-balance-zero.md`

## Related

- [[concepts/silent-null-bug]]
- [[decisions/dto-tomap-deprecated-candidate]]
