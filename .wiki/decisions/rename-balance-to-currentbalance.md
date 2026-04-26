---
title: SupplierResponse.balance → currentBalance Rename
type: decision
source: .claude/wiki/decisions/rename-balance-to-currentbalance.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
status: active
---

# SupplierResponse.balance → currentBalance Rename

## Karar
`SupplierResponse.balance` alanı **`currentBalance`** olarak rename edildi. Eş zamanlı `overdueAmount`, `availableCreditLimit`, `isCreditLimitExceeded` alanları eklendi.

## Neden
- Müşteri tarafı (`CustomerControllerImpl.toMap`) `currentBalance` key'i üretiyor
- Aynı Flutter widget'ı (`accounts_list_panel`) hem müşteri hem tedarikçi satırını render ediyor
- Asimetrik key'ler widget'ta `entity['currentBalance'] ?? entity['balance']` fallback'i gerektiriyor → kırılgan
- [[entities/customer-account]] ve [[entities/supplier-account]] entity alanı zaten `currentBalance` — DTO simetrik olmalı

## Backward Compat
**Breaking.** Flutter tarafı aynı PR'de güncellendi:
- `supplier_list_screen.dart:341,347`: `s['balance']` → `s['currentBalance']`

External client varsa (henüz yok) sözleşme kırılmasına dikkat.

## Related
- [[issues/supplier-list-balance-zero]]
- [[entities/supplier]]
- [[concepts/pattern-dto-tomap-pattern]]
