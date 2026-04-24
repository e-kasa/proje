---
type: raw-pointer
immutable: true
kind: flutter-widget
date: 2026-04-24
---

# Raw Pointer — AccountEditForm

**Dokunulmaz.**

## Dosya
`project_pos/lib/features/accounts/widgets/account_edit_form.dart` (2026-04-24 03:31'de oluşturulmuş)

## Tip
`ConsumerStatefulWidget` — polimorfik CUSTOMER / SUPPLIER CRUD formu.

## Props
- `initialType: String` — `'CUSTOMER'` veya `'SUPPLIER'` (default CUSTOMER)
- `editingId: String?` — null ise create, dolu ise update modu
- `initialData: Map<String, dynamic>?` — edit için mevcut alan değerleri
- `onSuccess: VoidCallback`, `onCancel: VoidCallback`

## Alanlar (controller'lar)
name, phone, email, address, taxNumber, taxOffice, contactName (supplier), website (supplier), creditLimit, paymentTerm, notes

## Bağımlılıklar
- `accountsListProvider` — başarılı kayıt sonrası refresh
- Backend: customer/supplier CRUD endpoint'leri
