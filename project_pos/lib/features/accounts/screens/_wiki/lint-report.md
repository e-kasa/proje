---
title: Lint Report — Accounts Screens Wiki (W2 sonrası)
date: 2026-04-24
scanned: 33
status: draft
---

# Lint Report — 2026-04-24 (W2 güncellemesi)

W2 — 5 eksik sayfa kapatıldı. İlk 5 "eksik sayfa" kategorisi **resolved** oldu. Güncel rapor:

## Özet
- **Yüksek**: 0
- **Orta**: 0 (eksik sayfalar kapandı)
- **Düşük**: 4 (aşağıda)

## Bulgular

### ✅ Eksik Sayfa — W2'de Kapatıldı (0 kalan)

Aşağıdaki 5 sayfa W2 acil kapsamında yazıldı:

| Sayfa | Status |
|---|---|
| [[entities/accounts-summary-bar]] | draft ✅ |
| [[entities/accounts-list-provider]] | draft ✅ |
| [[entities/selected-account-provider]] | draft ✅ |
| [[entities/account-service]] | draft ✅ |
| [[flows/statement-load-flow]] | verified ✅ |

### 🟠 Kararlar — Oluşturulmamış (3)

| Karar | Referans veren |
|---|---|
| `decisions/post-frame-parallel-load` | sources/accounts-hub-screen, entities/accounts-hub-screen |
| `decisions/sentinel-object-for-nullable-copy-with` | sources/accounts-notifiers, concepts/sentinel-copy-with |
| `decisions/parallel-summary-overdue-fetch` | sources/accounts-notifiers, entities/accounts-notifiers |
| `decisions/edit-via-modal-not-inline` | sources/statement-detail-panel, entities/account-edit-form |
| `decisions/pdf-client-side-for-now` | sources/statement-detail-panel, entities/statement-detail-panel |

### 🟡 Kaynak Boşluğu (4)

Tek kaynağa dayanan entity sayfaları:
- [[entities/account-edit-form]] — sadece ilk 80 satır okundu, submit logic tahmini
- [[entities/accounts-list-panel]] — dosya okunmadan yazıldı, provider API sözleşmesi varsayıldı
- [[entities/accounts-hub-screen]] — sadece ana .dart dosyası
- [[entities/accounts-notifiers]] — tam okundu ✓

### 🔴 Çelişki (0)
Yok.

### ⚠️ Eskimiş (0)
İlk setup — tümü bugün yazıldı.

### 🟡 Yetim Sayfa (0)
Her sayfa en az bir yerden link alıyor veya kategori index'inden.

## Otomatik Düzeltme
Yapılmadı. Sadece rapor.

## Öncelikli Aksiyon
1. Eksik decisions için küçük atomik sayfalar yaz (her biri 10-20 satır)
2. `account_edit_form.dart` dosyasını tam oku ve entity sayfasını doğrula
3. `accounts_list_panel.dart` provider API'yı doğrula
4. `/wiki-lint 30` sonraki sprint ortasında tekrarla
