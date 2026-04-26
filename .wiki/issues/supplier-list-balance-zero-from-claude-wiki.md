---
title: Tedarikçi Liste Bakiyesi Her Zaman 0 TL (detailed merge from .claude/wiki/)
type: issue
source: .claude/wiki/issues/supplier-list-balance-zero.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
status: resolved
note: "MERGE_NEEDED — overlap; this resolved version has 2-step fix detail + backward incompat note."
---

# Tedarikçi Liste Bakiyesi Her Zaman 0 TL

## Belirti
AccountsHub tedarikçi liste panelinde her satır 0 TL, gerçek değer DB'de olsa bile.

## Kök Neden
İki sorun birden:

1. **Field adı uyumsuzluğu**: `SupplierResponse.balance` (eski) vs Flutter `s['currentBalance']`. Client yanlış key'i okuyordu → null → 0.

2. **Populate edilmiyordu**: `SupplierServiceImpl.listSuppliers` `SupplierResponse.balance` alanını set etmiyordu bile — DTO'da olsa bile response'ta null geliyordu.

## Fix (iki adımlı)

1. `SupplierResponse.balance` → `currentBalance` **rename**. Eş zamanlı `overdueAmount`, `availableCreditLimit`, `isCreditLimitExceeded` alanları da eklendi (müşteri tarafıyla simetri).
2. `SupplierServiceImpl.mapToResponse()`'ta `SupplierAccount`'tan 4 alanı set etme:
```java
SupplierAccount acct = supplier.getAccount();
if (acct != null) {
    dto.setCurrentBalance(acct.getCurrentBalance());
    dto.setOverdueAmount(acct.getOverdueAmount());
    dto.setAvailableCreditLimit(acct.getAvailableCreditLimit());
    dto.setIsCreditLimitExceeded(acct.getIsCreditLimitExceeded());
    dto.setTotalDebt(acct.getTotalDebt());
    dto.setTotalPaid(acct.getTotalCredit());
} else { /* ZERO fallback */ }
```
3. `SupplierRepository`'ye `@EntityGraph(attributePaths = "account")` — N+1 önleme.

## Backward Incompatibility
`balance` → `currentBalance` **breaking** değişim. Eski Flutter kodu `s['balance']` okuyorsa sessizce 0 alır. Flutter tarafı da aynı PR'de güncellendi (`supplier_list_screen.dart:341,347`).

## İlgili Dosyalar
- pos-product-manager/src/main/java/com/sedcore/supplier/model/SupplierResponse.java
- pos-product-manager/src/main/java/com/sedcore/supplier/service/impl/SupplierServiceImpl.java
- pos-product-manager/src/main/java/com/sedcore/supplier/repository/SupplierRepository.java
- project_pos/lib/features/suppliers/screens/supplier_list_screen.dart

## Öğrenilen
Müşteri ve tedarikçi DTO'ları simetrik adlandırmalı — cross-ekran widget'lar (`accounts_list_panel`) ikisi için de aynı key'i okumak ister. Asimetri silent bug'a yol açar.

## Related
- [[entities/supplier]]
- [[entities/supplier-account]]
- [[decisions/rename-balance-to-currentbalance]]
- [[issues/customer-list-balance-zero]]
- [[sources/code-refs/2026-04-22-accounts-hub-perf]]
