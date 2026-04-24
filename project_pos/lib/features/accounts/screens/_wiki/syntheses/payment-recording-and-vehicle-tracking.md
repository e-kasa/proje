---
title: Ödeme Kayıt + Plaka Bazlı Takip — Senaryo Analizi
tags: [synthesis, payment, vehicle, resolved]
date: 2026-04-24
status: verified
resolved-date: 2026-04-24
covers:
  - "[[entities/statement-detail-panel]]"
  - "[[entities/accounts-hub-screen]]"
  - "[[entities/accounts-notifiers]]"
  - "[[flows/payment-recording-from-statement]]"
related:
  - "[[issues/statement-panel-missing-payment-button]]"
---

# Ödeme Kayıt + Plaka Bazlı Takip — RESOLVED

## Çözüm Özeti (Sprint 6a + Sprint 6b-A, 2026-04-24)

| Bölüm | Karar | Dosya |
|---|---|---|
| Ödeme alma (S6.1) | ✅ `_handlePayment` bağlandı — 4 provider refresh | `statement_detail_panel.dart:178` |
| Plaka takibi (S6.2) | ✅ Seçenek **A** (pragmatik) — modal'a opsiyonel plaka alanı + description prepend | `payment_record_modal.dart:_submit` |

ADR: `C:\Users\Win11\.claude\plans\agile-noodling-crown-s6b-adr.md`.

Plan'ın orijinal C seçeneği (Sale→SaleItem→Vehicle zinciri) W2 Sales ingest'te çürüdü — FK yok, Vehicle kataloğunda plate yok. B/C için yeni schema gerekir, şimdilik A yeterli.

**Kısıtlar (A kabul edildi)**: plaka arama/filter yok, rapor yok. Veri birikince B/C değerlendirilir.

## Senaryo
Yedek parça POS'unda:
1. **X müşterisi** (bir usta/parçacı) dükkandan **Y plakası** aracına ait parçalar satın alır
2. Ödemeyi **vadeli** seçer → `CustomerAccount.currentBalance` artar (cari açılır veya bakiye yükselir)
3. Daha sonra müşteri gelip ödeme yapar → "Y plakasına ait satışın ödemesi" olarak gelir

Soru: **Statement panelinden nasıl ödeme alırım? Plakayı nasıl takip ederim?**

## Cevap (Wiki'ye Göre)

### 1. Ödeme Alma — ŞU AN StatementDetailPanel'den YapılAMAZ

**Mevcut durum**:
- [[entities/statement-detail-panel]] `_Header` 4 aksiyon butonu barındırıyor:
  - Geri (mobile push'ta)
  - Tarih aralığı picker
  - **Edit** → `AccountEditForm` modal ([[decisions/inline-form-to-modal-migration]])
  - **PDF** → `StatementPdfService.show(...)` ([[decisions/pdf-client-side-for-now]])
- **"Tahsilat al / Ödeme yap" butonu YOK.**

**Ama hazır bir modal var** — ingest edilmemiş:
- `project_pos/lib/features/accounts/screens/payment_record_modal.dart`
- `PaymentRecordModal.show(context, isCustomer, accountName)` statik API
- Döner: `Map<String, dynamic>?` — `amount`, `paymentType`, `bankName`, `referenceNo`, `description`
- Form alanları: tutar + ödeme tipi (CASH/CREDIT_CARD/BANK_TRANSFER/CHECK) + banka + ref no + açıklama

Bu modal **bağlanmamış durumda** — hiçbir widget onu çağırmıyor (en azından ingest edilen 5 kaynakta referans yok).

### 2. Plaka Takibi — ŞU AN YAPI YOK

Ingest edilen wiki sayfalarında (bu `_wiki/` + üst `.claude/wiki/`):
- [[entities/accounts-notifiers]] `AccountStatementState` → `statement` Map içinde `transactions[]` var ama her transaction'da plaka alanı doğrulanmamış
- [[entities/statement-detail-panel]] `_TxRow` çıkardığı alanlar: `transactionDate`, `description`, `debitAmount`, `creditAmount`, `runningBalance` — **plaka yok**
- `.claude/wiki/entities/payment.md` — `customerId`, `supplierId`, `saleId`, `purchaseId`, `paymentType`, `amount`, `referenceNumber` — **plaka yok**
- `.claude/wiki/entities/account-transaction.md` — ledger append-only, plaka kolonu yok

**Plaka backend'de nerede var?** → **HİÇBİR YERDE** (W2 Sales ingest tespit, 2026-04-24)
- [[entities/vehicle]] = katalog (make/model/year) — `plate` alanı yok
- [[entities/sale]] — `vehicleId` FK yok, `vehiclePlate` alanı yok
- [[entities/sale-item]] — `vehicleId` FK yok
- `VehicleCompatibility` = parça-araç modeli eşleştirmesi (satışa konu değil)
- `.claude/wiki/entities/payment.md` — plaka alanı yok
- **Sonuç**: Plaka bilgisi şu an hiçbir entity'de yapısal olarak tutulmuyor. Eklenirse yeni kolon veya yeni entity şart

## Çözüm Yolları

### A — Minimum değişiklik (pragmatik, bugün)

1. **StatementDetailPanel'e "Tahsilat Al" butonu ekle** — `_Header` action row'una:
   ```dart
   IconButton(icon: Icon(Icons.payments_outlined),
     onPressed: () async {
       final result = await PaymentRecordModal.show(
         context, isCustomer: selected.accountType == 'CUSTOMER',
         accountName: selected.accountName);
       if (result != null) {
         await ref.read(paymentServiceProvider).createPayment(
           customerId: selected.accountId,  // veya supplierId
           amount: result['amount'],
           paymentType: result['paymentType'],
           referenceNumber: result['referenceNo'],
           description: result['description'],
         );
         ref.read(accountStatementProvider.notifier).load();
         ref.read(accountsListProvider.notifier).load();
       }
     })
   ```
2. **Plaka için `description` alanına manuel** — kullanıcı "Y plakası — balata seti" yazar. Ekstrede görünür çünkü `_TxRow` `description` alanını render eder ([[entities/statement-detail-panel]]).

**Kısıtlar**: Plaka arama yapılamaz, raporlanamaz, tutarsız yazım (34ABC123 vs 34 ABC 123 vs 34-abc-123).

### B — Yarı-yapısal (sprint ölçek)

1. `PaymentRecordModal`'a **plaka alanı** ekle (opsiyonel `plate` field).
2. Backend `Payment` entity'e `vehicle_plate VARCHAR(20)` alanı + repository filtre.
3. `StatementDetailPanel._TxRow` plaka chip göster.
4. Filter: tarih aralığı + plaka.

**Kısıtlar**: Plaka ile Sale/SaleItem bağı hâlâ gevşek (manuel alan).

### C — Tam yapısal (önerilen orta vade)

> **2026-04-24 GÜNCELLEME (W2 Sales ingest sonrası)** — Üst wiki [[entities/sale]], [[entities/sale-item]], [[entities/vehicle]] ingest edildi. Sonuç:
> - `SaleItem.vehicleId` FK **YOK**
> - `Sale.vehicleId` FK **YOK**
> - `Vehicle` entity = **katalog** (make/model/year); `plate` alanı **YOK**
> - `VehicleCompatibility` = parça↔araç modeli eşleştirmesi (satışa konu araç değil)
>
> Yani orijinal "zincir varsa hazır" varsayımı çürüdü. C seçeneği şema ekleme gerektirir:

1. Yeni `CustomerVehicle` entity: `customer_id` FK + `plate VARCHAR(20) UNIQUE per customer` + optional `vehicle_id` FK (katalog referansı, marka/model otomatik çekmek için)
2. `Sale.customer_vehicle_id` FK (nullable — peşin satışta yok)
3. POS `cart_panel.dart` → satıştan önce müşteri seçildiğinde plaka dropdown (mevcut araçlar) veya "yeni plaka ekle"
4. `AccountStatementControllerImpl` response'a `vehicle_plate` zenginleştirmesi (tx.sale.customerVehicle.plate)
5. `statement_detail_panel._TxRow` plaka chip render
6. Yeni endpoint: `GET /account-statements/{id}/by-vehicle/{plate}` — plaka bazlı filtre

**Fayda**: Plaka raporlaması otomatik, veri tutarlı, Sale-Payment zinciri mantıksal.

**Efor (güncel)**: 3-5 gün yerine **5-7 gün** (schema + migration + cart UI + statement enrichment + test).

## Wiki'de Eksik — Ingest Önerisi

Bu senaryoyu tam yanıtlamak için **şu kaynakları ingest etmek gerekir**:

| Kaynak | Neden |
|---|---|
| `project_pos/lib/features/accounts/screens/payment_record_modal.dart` | Mevcut ödeme modalı — form alanları, döndürülen Map şeması |
| `project_pos/lib/features/accounts/services/payment_service.dart` | Flutter client → backend payment endpoint çağrısı |
| `project_pos/lib/features/accounts/services/account_service.dart` | getAccountStatement çağrısı — response'ta plaka var mı |
| `pos-product-manager` `SaleItem.java` | Vehicle FK var mı, plaka nereden gelir |
| `pos-product-manager` `AccountStatementControllerImpl.java` | Ekstre response'unda transaction zenginleştirme |
| Üst wiki: `.claude/wiki/entities/sale-item` (yok — oluşturulmalı) | Sale × Vehicle × Parça ilişkisi |

## ÇELİŞKİ

Yok — wiki'de plaka alanı hiç kayıtlı değil, beyan çakışması oluşmuyor. Sadece **kaynak boşluğu** (ingest eksiği).

## Önerilen Sıra

1. `/wiki-ingest payment_record_modal.dart` → bu synthesis'i güncelle
2. Çözüm **A** uygula (1-2 saatlik iş) → en azından "ödeme alma" flow'u çalışsın
3. Plaka için backend araştırma: `SaleItem.vehicleId` FK kontrolü + `AccountStatementController` response şeması
4. Çözüm B veya C karar → üst wiki `syntheses/accounts-hub-production-readiness`'e P2 madde olarak ekle

## Sources
- [[entities/statement-detail-panel]]
- [[entities/accounts-hub-screen]]
- [[entities/accounts-notifiers]]
- `project_pos/lib/features/accounts/screens/payment_record_modal.dart` (henüz ingest edilmedi, inline okuma)
- `.claude/wiki/entities/payment.md`
- `.claude/wiki/entities/account-transaction.md`
- `.claude/wiki/syntheses/accounts-hub-production-readiness.md`

## Related
- [[syntheses/accounts-screens-overview]]
- [[syntheses/accounts-data-flow]]
- [[issues/statement-panel-missing-payment-button]] (yeni — aşağıda)
