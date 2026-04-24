---
title: AccountEditForm — Polimorfik Customer/Supplier CRUD
tags: [source, widget, flutter, form, polymorphic]
source: raw/screens/account-edit-form.md
date: 2026-04-24
status: verified
---

# AccountEditForm

## Amaç
Customer VEYA Supplier için **tek bir form widget**'ı. Type toggle ile iki entity arasında geçilir; create + edit modları aynı sınıfta.

## Props Kontratı

| Prop | Tip | Anlam |
|---|---|---|
| `initialType` | `String` (`'CUSTOMER'|'SUPPLIER'`) | Varsayılan tip. Default `'CUSTOMER'` |
| `editingId` | `String?` | null → create, dolu → update |
| `initialData` | `Map<String, dynamic>?` | Edit modunda mevcut değerler (backend'den fetch edilmiş) |
| `onSuccess` | `VoidCallback` | Başarı callback — parent modal'ı kapatır, list'i refresh eder |
| `onCancel` | `VoidCallback` | İptal |

## Controller Alanları

```dart
_name, _phone, _email, _address, _taxNumber, _taxOffice,
_contactName,   // sadece SUPPLIER için görünür
_website,       // sadece SUPPLIER için görünür
_creditLimit,   // default 0
_paymentTerm,   // default 30 gün
_notes
```

## Submit Akışı (tahmini)

```
_submit() →
  validate form →
  _submitting = true →
  if _isEdit:
    customerService.updateCustomer(editingId, data) | supplierService.updateSupplier
  else:
    customerService.createCustomer(data) | supplierService.createSupplier
  success: ref.read(accountsListProvider.notifier).load() → onSuccess()
  error: AppToast.error()
```

## Kullanım Yerleri

- [[entities/statement-detail-panel]] → `_handleEdit` → modal içinde (initialData dolu, edit mode)
- [[entities/accounts-list-panel]] → "Yeni hesap" butonu → modal içinde (initialData null, create mode)
- Her iki kullanım da `showModalBottomSheet(isScrollControlled: true)` ile bottom sheet olarak açılır

## Kararlar
- [[decisions/polymorphic-account-edit-form]]
- [[decisions/edit-via-modal-not-inline]]

## İlgili
- [[entities/account-edit-form]]
- [[entities/statement-detail-panel]] — edit trigger
- [[entities/accounts-list-panel]] — create trigger

## Sources
- `raw/screens/account-edit-form.md`
- `project_pos/lib/features/accounts/widgets/account_edit_form.dart`
- Konuşma bağlamı 2026-04-24 (edit form modal migration)
