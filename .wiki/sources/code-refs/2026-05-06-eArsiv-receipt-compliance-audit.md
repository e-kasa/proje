---
title: Fiş E-Arşiv / Maliye Uyumluluk Denetimi (Sprint 30)
tags: [audit, compliance, e-arsiv, maliye, receipt, sprint-30, vat]
source: project_pos/lib/services/print/receipt_template.dart, lib/features/settings/screens/company_settings_screen.dart
date: 2026-05-06
status: gap-analysis
related-sprint: 30
---

# Fiş E-Arşiv / Maliye Uyumluluk Denetimi

Sprint 29-fix-7'de [`receipt_template.dart`](project_pos/lib/services/print/receipt_template.dart) Türkiye fiş standardına yaklaştı (KDV oranı + KDV TABLOSU). Bu denetim, mevcut formatın **resmi Türkiye Maliye fiş standardı + E-Arşiv standardı** ile karşılaştırmalı gap analizidir. Sprint 30 backlog kalemi.

## Temel Ayrım: ÖKC vs E-Arşiv vs Informal Makbuz

Türkiye'de "fiş" kelimesi 3 farklı belgeye işaret edebilir:

| Belge Tipi | Sertifikasyon | Format | Yasal Geçerlilik |
|---|---|---|---|
| **ÖKC fişi** (Ödeme Kaydedici Cihaz) | TSE + GİB onaylı donanım/firmware | Termal kağıt + Z raporu | ✅ Resmi vergi belgesi |
| **E-Arşiv fatura** | GİB mükellef + sertifika | UBL-TR XML, GİB imzalı, opsiyonel kağıt | ✅ Resmi e-fatura B2C |
| **Satış makbuzu** (informal) | — | Serbest format termal/PDF | ❌ Resmi belge değil; sadece müşteri kaydı/iade takibi |

**SEDCORE POS mevcut durumu:** Üçüncü kategori (informal satış makbuzu). Sertifikasyon yok, GİB E-Arşiv mükellefiyeti yok, ÖKC entegrasyonu yok. Bu denetim, mevcut çıktının **bu kategoride bile en iyi pratiği yansıtıp yansıtmadığını** ölçer.

## Mevcut Format ([`receipt_template.dart`](project_pos/lib/services/print/receipt_template.dart))

```
SEDCORE POS                          ← settings.headerText (free-form)
                                     (büyük punto, bold, ortalı)
Fis No:                       #-   ← saleNumber veya id
Tarih:               06.05.2026 09:30
Musteri:                  John Doe   ← varsa
--------------------
Fren Balata
  1 x TL 320.00      TL 377.60 *20  ← *<oran> KDV göstergesi (Sprint 29-fix-7)
--------------------
Ara Toplam:                TL 320.00
KDV %20:                    TL 57.60  ← oran bazlı (Sprint 29-fix-7)
====================
TOPLAM                     TL 377.60
====================
Odeme:                       Nakit

KDV TABLOSU                          ← Sprint 29-fix-7 footer matrisi
--------------------
Oran  Matrah     KDV
%20   TL 320.00  TL 57.60
--------------------

[QR kod — sale.id]
#<saleId>

Tesekkurler! Iyi gunler...           ← settings.footerText (free-form)
```

## Türkiye Fiş Standardı — Zorunlu Alanlar

Maliye Bakanlığı Genel Tebliği (Seri No: 459) ve Vergi Usul Kanunu uyarınca, **bir satış belgesi** üzerinde aşağıdaki alanlar bulunmalıdır:

| # | Alan | Kaynak | Mevcut? | Gap |
|---|---|---|---|---|
| 1 | **Firma ticari unvanı** | Ticaret sicili | ⚠️ Free-form `headerText` ("SEDCORE POS") | Yapılandırılmış alan değil; CompanySettings'teki `companyName` aktarılmıyor |
| 2 | **Vergi Kimlik Numarası (VKN)** | 10 hane | ❌ Yok | CompanySettings'te `taxNumber` var, fiş'e akmıyor |
| 3 | **Vergi Dairesi** | Şehir + daire adı | ❌ Yok | CompanySettings'te `taxOffice` var, fiş'e akmıyor |
| 4 | **Mağaza adresi** | Cadde/sokak/şehir | ❌ Yok | CompanySettings'te `address` var, fiş'e akmıyor |
| 5 | **Telefon** (opsiyonel) | İletişim | ❌ Yok | CompanySettings'te `phone` var, fiş'e akmıyor |
| 6 | **Fiş seri ve sıra no** | Sürekli artan | ⚠️ `saleNumber` veya `id` (UUID) — sürekli artış garantisi yok | Maliye sıralı seri ister; UUID kullanılırsa "informal" kalır |
| 7 | **Tarih + saat** | dd.MM.yyyy HH:mm | ✅ Var | — |
| 8 | **Mal/hizmet adı** | Açıklayıcı | ✅ Var | — |
| 9 | **Miktar + birim fiyat** | — | ✅ Var | — |
| 10 | **Satır toplamı** | — | ✅ Var | — |
| 11 | **KDV oranı (her satırda)** | `*<oran>` standardı | ✅ Sprint 29-fix-7 | — |
| 12 | **KDV oran bazlı toplam tablosu** | Matrah/KDV/Toplam | ✅ Sprint 29-fix-7 KDV TABLOSU | KDV-dahil toplam sütunu eklenebilir |
| 13 | **Genel toplam** | Bold/büyük | ✅ Var | — |
| 14 | **Ödeme şekli** | Nakit/Kredi/EFT/Karma | ✅ Var | — |
| 15 | **ÖKC seri no + Z raporu no** | TSE onaylı donanımdan | ❌ N/A | SEDCORE ÖKC değil — bu zorunluluk düşer; informal makbuz için yer almaz |
| 16 | **"Bu fiş resmi belge değildir" notu** | Informal makbuz için zorunlu | ❌ Yok | Footer'a eklenebilir; yasal sorumluluk ayrımı için kritik |

### Kritik Bulgular

1. **Bulgu A — Firma kimlik blok yok:** Tüm zorunlu firma bilgileri (`companyName`, `taxNumber`, `taxOffice`, `address`, `phone`) `CompanySettingsScreen` üzerinden backend'e kaydediliyor (`product/api/v1/company/settings`) ama [`receipt_template.dart`](project_pos/lib/services/print/receipt_template.dart) **bu veriyi okumuyor**. Yalnızca `PrintSettings.headerText` free-form satırı kullanılıyor.

2. **Bulgu B — "Resmi belge değildir" disclaimer yok:** Sertifikasız sistem informal makbuz üretiyor; müşteri/denetçi yanılgıya düşmesin diye footer'da açık ifade gerekir.

3. **Bulgu C — Fiş seri no Maliye standardına uygun değil:** UUID veya `POS-YYYYMMDD-XXXXXX` formatı sıralı seri tabanlı değil. Resmi sertifikasyona giderse fiş numaralandırma sıfırdan tasarlanmalı (POS-{seri}-{sıra}).

4. **Bulgu D — KDV TABLOSU "Toplam" sütunu eksik:** Mevcut `Oran/Matrah/KDV` 3 sütun. Maliye standartlarında 4. sütun olarak `Toplam (KDV-dahil)` da görülür — opsiyonel ama netlik sağlar.

5. **Bulgu E — Test sayfasında kimlik blok yok:** [`buildTestPage()`](project_pos/lib/services/print/receipt_template.dart#L284) sadece `headerText` basıyor; firma bilgisi olmadan kullanıcı yazıcı çıktısının resmi formatına yakın olup olmadığını test edemez.

## E-Arşiv Standardı — Scope Dışı

Tam E-Arşiv uyumu için yapılması gerekenler (sertifikasyon yolu açılırsa Sprint 32+ gibi büyük scope):

1. GİB E-Arşiv mükellef kaydı + sertifika
2. UBL-TR 2.1 XML üretimi (XSD validation)
3. GİB özel entegratör veya doğrudan portal API
4. XML imzalama (XAdES-BES, XML-DSig)
5. PDF/A-3 türevi (gömülü XML)
6. 8 yıl saklama yükümlülüğü
7. Gönderme/iptal yönetimi
8. UTF-8 + e-imza zinciri

**Tahmini efor:** 6+ hafta + yasal danışmanlık.

**Bu denetimin scope'u dışında**: SEDCORE'un E-Arşiv mükellefi olup olmayacağı iş kararıdır; mükellef olunmadan teknik geliştirme yapmak boş efor olur.

## Sprint 30 İçin Önerilen Eylemler

### Önerilen (kritik gap'ler — informal makbuz iyileştirmesi)

1. ⭐ **CompanyInfo cache provider** — `lib/services/company/company_info.dart`:
   - `CompanyInfo` model: `companyName`, `taxNumber`, `taxOffice`, `address`, `phone`, `mersisNo`
   - SharedPreferences cache (offline çalışsın); `loaded` flag (PrintSettings paterni)
   - App boot'ta `getCompanySettings()` ile lazy fetch + cache
   - `CompanySettingsScreen` save → cache invalidate

2. ⭐ **ReceiptTemplate.buildSaleReceipt** firma kimlik bloğu ekle:
   - Header'a 4 satır: unvan (büyük) + adres (küçük) + `VKN: X | V.D.: Y` + `Tel: Z`
   - `headerText` deprecate yerine `companyName` öncelikli, fallback olarak `headerText`
   - "Bu fis resmi belge degildir; satis takibi icindir" disclaimer footer'a

3. ⭐ **buildTestPage()** firma kimlik bloğu ekle (kullanıcı format önizlemesi).

4. ⚠️ **KDV TABLOSU 4. sütun**: `Toplam` sütunu opsiyonel ekle (rate × matrah).

### Yapılmayacak (scope dışı)

- ❌ ÖKC sertifikasyon — TSE/GİB donanım onayı, dış bağımlı
- ❌ E-Arşiv XML üretimi — büyük scope, sertifikasyon ön gerekli
- ❌ Fiş seri/sıra no Maliye formatına uydurma — sertifikasyon olmadan anlamsız
- ❌ Z raporu — ÖKC'ye bağlı
- ❌ E-imza entegrasyonu

## Sources

- [`receipt_template.dart`](project_pos/lib/services/print/receipt_template.dart) — mevcut format
- [`print_settings.dart`](project_pos/lib/services/print/print_settings.dart) — `headerText` free-form
- [`company_settings_screen.dart`](project_pos/lib/features/settings/screens/company_settings_screen.dart):22-33 — VKN/VD/adres alanları
- [`user_service.dart`](project_pos/lib/features/settings/services/user_service.dart):148-167 — `getCompanySettings()` + `updateCompanySettings()` API
- Maliye Bakanlığı Vergi Usul Kanunu Genel Tebliği (Seri 459) — fiş zorunlu alanları (yasal referans)
- GİB E-Arşiv tebliği (485 sıra no'lu) — E-Arşiv tanım/zorunluluk

## İlgili

- Sprint 29-fix-7 log: KDV oranı + KDV TABLOSU footer eklendi (mevcut bulguların temeli)
- [[syntheses/integrations-hub-architecture]] — yapılandırma yönetimi paterni
- Sprint 30 sentez: [[syntheses/eArsiv-receipt-compliance]] (yazılacak)
