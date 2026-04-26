---
title: Satın Alma Oluşturma Akışı
tags: [source, purchase, claim, shortage, ledger]
source: C:\Users\Win11\Documents\GitHub\proje\.claude\wiki\flows\purchase-checkout.md
raw: "[[raw/code-refs/2026-04-25-purchase-checkout-flow]]"
date: 2026-04-25
status: draft
---

# Purchase Checkout İngest Özeti

## Amaç

Tedarikçiden alınan malı kaydetmek — stok artışı (fiili gelen mal), cari hesap borç (fiili gelen tutar), ledger kaydı, eksik teslimat varsa otomatik claim.

## Ne Yapıldı

6 adımlı `createPurchase`: (1) supplier doğrula, (2) invoiceAmount vs totalAmount vs shortageAmount hesapla, (3) PURCHASE_IN stok hareketi (sadece receivedQty), (4) SupplierAccount debit (totalAmount), (5) AccountTransaction.PURCHASE, (6) shortage > 0 ise SupplierClaim auto-open.

## Değişenler / Kapsam

- **Entity**: [[entities/purchase]], [[entities/supplier]], [[entities/supplier-account]], [[entities/supplier-claim]], [[entities/stock-movement]], [[entities/account-transaction]]
- **Service**: [[entities/purchase-service-impl]] (createPurchase + cancelPurchase + createPurchaseReturn + applyDiscount)
- **Shortage semantiği**: invoiceAmount = fatura brüt; totalAmount = fiili giren mal; shortageAmount = açık eksik; discountAmount = iskonto ile kapatılan (cari etkisi yok)

## Alınan Kararlar

- [[decisions/debit-only-received-amount]] — cari borç sadece fiili gelen mal; eksik için baştan debit yok
- [[decisions/supplier-claim-auto-open]] — shortage > 0 otomatik claim, manuel oluşturma yok
- [[decisions/discount-no-account-effect]] — iskonto ile kapanış SupplierAccount etkisiz (audit trail için DISCOUNT tx)

## Karşılaşılan Sorunlar

Yok (resolved olanlar source'un orijinalinde işlenmiş).

## Açık Konular

- Batch entry cart'ından gelen create path'te `locationId` zorunlu kuralının prod-ready enforcement'ı (bkz. [[concepts/prod-ready-guards]])
- Claim lifecycle (OPEN → DELIVERY vs DISCOUNT vs CANCELLED) tam dokümantasyon

## Sources

- `.claude/wiki/flows/purchase-checkout.md`
- `pos-product-manager/src/main/java/com/sedcore/purchase/service/impl/PurchaseServiceImpl.java`
- [[raw/code-refs/2026-04-25-purchase-checkout-flow]]

## Related

- [[syntheses/accounts-module-overview]]
- [[concepts/invoice-vs-total-shortage]]
- [[concepts/drift]]
