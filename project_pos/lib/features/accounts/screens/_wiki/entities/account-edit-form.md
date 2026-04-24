---
title: AccountEditForm
tags: [entity, widget, flutter, form]
source: project_pos/lib/features/accounts/widgets/account_edit_form.dart
date: 2026-04-24
status: verified
---

# AccountEditForm

## Amaç
Customer VEYA Supplier için tek **polimorfik CRUD form**. Type toggle + create/edit modları aynı widget'ta.

## Tip
`ConsumerStatefulWidget` → `_AccountEditFormState`.

## Props
```dart
AccountEditForm({
  String initialType = 'CUSTOMER',
  String? editingId,              // null → create, dolu → edit
  Map<String, dynamic>? initialData,
  required VoidCallback onSuccess,
  required VoidCallback onCancel,
});
```

## Alanlar

Ortak (müşteri + tedarikçi):
- name, phone, email, address
- taxNumber, taxOffice
- creditLimit (default 0)
- paymentTerm (paymentTermDays, default 30)
- notes

Sadece SUPPLIER:
- contactName, website

Type toggle (UI) ile CUSTOMER ↔ SUPPLIER geçişi; supplier alanları conditional render.

## Submit

```
_submit() {
  if !validate → return
  _submitting = true
  
  type = CUSTOMER:
    if editingId: customerService.update(editingId, data)
    else: customerService.create(data)
  type = SUPPLIER:
    (aynı paten)
  
  success: accountsListProvider.load() → onSuccess()
  error: AppToast.error()
  _submitting = false
}
```

## Kullanım Yerleri

1. **Create**: [[entities/accounts-list-panel]] "Yeni hesap" butonu → `showModalBottomSheet` → `AccountEditForm(initialType, onSuccess, onCancel)`
2. **Edit**: [[entities/statement-detail-panel]] `_handleEdit` → `showModalBottomSheet` → `AccountEditForm(initialType, editingId, initialData, onSuccess, onCancel)`

Her iki durumda da **modal bottom sheet** — 2026-04-24 UX kararı (bkz. [[decisions/inline-form-to-modal-migration]]).

## Tuzaklar

- `_type` state değişirse controller'lardaki supplier-only alanlar "atılmaz" — kullanıcı customer → supplier geçtiyse eski contactName kalır. Submit sırasında type'a göre dict'e eklendiğinden sorun değil ama UX'te confusing olabilir
- `creditLimit` controller TextEditingController — numeric parse submit anında
- `initialData` null olmalı create'te — aksi halde edit mode tetiklenir

## Sources
- [[sources/screens/2026-04-24-account-edit-form]]
- `project_pos/lib/features/accounts/widgets/account_edit_form.dart`

## Related
- [[entities/accounts-list-panel]] — create trigger
- [[entities/statement-detail-panel]] — edit trigger
- [[decisions/polymorphic-account-edit-form]]
- [[decisions/inline-form-to-modal-migration]]
