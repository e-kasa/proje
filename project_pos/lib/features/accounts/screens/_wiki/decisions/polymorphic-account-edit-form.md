---
title: Polimorfik AccountEditForm (Customer + Supplier Tek Widget)
tags: [decision, widget, polymorphism]
date: 2026-04-24
status: active
---

# Polimorfik AccountEditForm

## Karar
Customer ve Supplier CRUD formu **tek widget** — `AccountEditForm`. `initialType` prop ile toggle; supplier-only alanlar (contactName, website) conditional render.

## Alternatif (Red)
İki ayrı widget: `CustomerEditForm`, `SupplierEditForm`. Form alanlarının %80'i ortak — duplicate maintenance.

## Neden Polimorfik
- %80 ortak alan (name, phone, email, address, tax, creditLimit, paymentTerm, notes)
- Hub UI hem müşteri hem tedarikçi açılabiliyor — tek giriş noktası tutarlı
- `StatementArgs.accountType` zaten var → type enumu gibi davranır
- Submit path şartlı ama linear

## Red Edilen Tasarım
`extends` hiyerarşi (CustomerEditForm extends AccountEditFormBase) — Flutter widget composition tercih; inheritance overkill.

## Tuzak
Type toggle kullanıcı CUSTOMER → SUPPLIER geçtiyse eski contactName/website değerleri kaybolmaz (controller reset yok). Submit type'a göre dict'e eklendiği için veri kirliliği olmaz ama UX confusing — belki tip değişince dialog "bilgiler sıfırlanacak, devam?" sormalı (future work).

## Related
- [[entities/account-edit-form]]
