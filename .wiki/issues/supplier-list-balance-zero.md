---
title: Tedarikçi Liste Bakiyesi Hep 0 (RESOLVED)
tags: [issue, resolved, accounts, silent-null]
date: 2026-04-25
status: resolved
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\issues\supplier-list-balance-zero.md
---

# Supplier List Balance Zero

**Kök neden**: Backend DTO alan adı `balance` → `currentBalance` rename edildi; client `p['balance']` okumaya devam etti → null → 0.0.

**Fix**: Client güncellendi.

## Sources

- `.claude/wiki/issues/supplier-list-balance-zero.md`

## Related

- [[concepts/silent-null-bug]]
- [[issues/customer-list-balance-zero]]
