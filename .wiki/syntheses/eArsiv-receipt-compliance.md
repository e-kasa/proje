---
title: Fiş E-Arşiv Uyumluluk Mimari Kararları (Sprint 30)
tags: [synthesis, compliance, e-arsiv, maliye, receipt, sprint-30, vat, architecture]
source: ../sources/code-refs/2026-05-06-eArsiv-receipt-compliance-audit.md
date: 2026-05-06
status: decided
related-sprint: 30
---

# Fiş E-Arşiv Uyumluluk Mimari Kararları

[[sources/code-refs/2026-05-06-eArsiv-receipt-compliance-audit]] denetim çıktıları üzerine alınan kararlar. Sprint 30 implementasyonunu yönlendirir.

## Stratejik Çerçeve

SEDCORE POS bir **informal satış makbuzu** üretiyor (ÖKC değil, E-Arşiv mükellefi değil). Sertifikasyon yolu (sektör + ciroya bağlı yasal karar) ayrı bir iş kararı. Bu sprint **mevcut kategoride en iyi pratiği** hedefler:

- ✅ Müşteriye verilen kağıt **firma kimliğini açıkça gösterir** (satış sonrası iletişim/iade için)
- ✅ Müşteri **resmi belge ile karıştırmasın** diye disclaimer var
- ✅ KDV bilgisi **vergi danışmanına aktarılabilir** (fişin fotoğrafı yeter)
- ❌ E-Arşiv XML üretimi yok (sertifikasyon ön-koşulu yapılmadan boş efor)
- ❌ ÖKC entegrasyonu yok (donanım sertifikasyonu kapsam dışı)

## Kararlar

### K1 — CompanyInfo, PrintSettings'ten ayrı bir kavramdır

**Karar:** `CompanyInfo` (firma kimlik) ile `PrintSettings` (yazıcı yapılandırması) **iki farklı provider** olur.

**Neden:**
- Şuanki `headerText` free-form yarı-çözüm; "SEDCORE POS" diye yazılan tek satır firma adı + slogan + her şeyi karıştırıyor
- Firma bilgisi backend'de mevcut, server-side authoritative kaynak
- Yazıcı ayarı device-specific (VID/PID/paper width) — multi-device deploy'da **firma tek**, **yazıcı çok**

**Alternatifler değerlendirildi:**

| Seçenek | Verdict | Sebep |
|---|---|---|
| A) PrintSettings'e `companyName/taxNumber/...` ekle | ❌ | Mix concerns; yazıcı ile firma kimliği farklı yaşam döngüsü |
| B) Her receipt print'inde `getCompanySettings()` çağır | ❌ | Network latency, offline kırılgan, satış akışını yavaşlatır |
| **C) Ayrı CompanyInfo provider + SharedPreferences cache** | ✅ | Offline-first, firma tek noktadan akar, refresh kontrolü explicit |

### K2 — Cache invalidation explicit, refresh implicit

**Karar:** `CompanyInfo` provider:
- App boot'ta SharedPreferences'tan **anında** yüklenir (UI bloklamaz)
- Background'da `getCompanySettings()` ile **silent refresh**
- `CompanySettingsScreen` save → cache invalidate + reload

**Neden:** Sprint 22 `PrintSettings.loaded` paterni (UI ilk frame'de cached değer gösterir, network gelince güncellenir) — kullanıcı her açılışta yazıcıyı yeniden seçmek zorunda kalmaz; aynı UX firma bilgisi için.

### K3 — ReceiptTemplate API stable kalır, opsiyonel parametre

**Karar:** [`buildSaleReceipt(sale)`](project_pos/lib/services/print/receipt_template.dart) imzası değişmez. CompanyInfo, constructor'a opsiyonel parametre olarak eklenir:

```dart
class ReceiptTemplate {
  final PrintSettings settings;
  final CompanyInfo? company; // ← Sprint 30 eklenir; null güvenli

  ReceiptTemplate(this.settings, {this.company});

  Future<List<int>> buildSaleReceipt(Map<String, dynamic> sale) async {
    // ...
    if (company != null && company!.isComplete) {
      _addCompanyHeaderBlock(bytes, gen);
    } else {
      // Backward compat: eski tek-satır headerText
      bytes.addAll(gen.text(settings.headerText, ...));
    }
    // ...
  }
}
```

**Neden:**
- Backward compat: Sprint 22 davranışı (sadece `headerText`) test edilmiş çalışıyor; null'da regresyon yok
- Provider DI net: `ReceiptTemplate(settings, company: ref.watch(companyInfoProvider))`
- Test edilebilir: company null veya partial veri ile unit test kolay

### K4 — Disclaimer footer KOŞULLU + i18n

**Karar:** "Bu fis resmi belge degildir; satis takibi icindir." satırı **default açık**, `companyInfoProvider` `isOfficialReceipt` flag'i (false default) ile gizlenebilir.

**Neden:**
- Mevcut sertifikasız durumda yasal sorumluluk azaltır; tüketici yanılmaz
- İleride ÖKC entegrasyonu yapılırsa flag açılır (resmi olur), kod değişmez
- i18n: `t('receipt.disclaimer.unofficial')` — yeni bundle key (`bnd-rcp-*` prefix)

### K5 — Test sayfasında gerçek format yansıması

**Karar:** [`buildTestPage()`](project_pos/lib/services/print/receipt_template.dart#L284) firma kimlik blok + KDV breakdown örnek + disclaimer içerir (gerçek sale örneğine yakın).

**Neden:** Yazıcı kurulumunu (Sprint 29-fix-5 + `/docs/printer-setup.md`) doğrulamak isteyen kullanıcı, gerçek satışa benzer bir çıktı görmeli — codepage, paper width, font size sorunları test sayfasında ortaya çıkar.

### K6 — Sertifikasyon yolu açıksa Sprint 32+ çatısı

**Karar:** E-Arşiv XML üretimi + ÖKC entegrasyonu **bu sprint'te yapılmaz**, ama mimari **engelleyici tasarım yapılmaz**:
- `CompanyInfo` model: `mersisNo`, `eArsivCertificateAlias` gibi alanlar opsiyonel (gelecek sertifikasyon için)
- ReceiptTemplate'in çıktı formatı XML üretiminin **kaynağı** olabilir (aynı veri)
- Fiş seri no formatı (`POS-YYYYMMDD-XXXXXX`) Maliye standardına çevrilebilir bir adapter ile

**Neden:** Bugünden büyük scope açmadan, gelecek için kapı kapatma.

## Implementation Sırası

```
1. lib/services/company/company_info.dart           ⭐ NEW
   - CompanyInfo model + Notifier + provider + SharedPreferences cache
2. lib/services/company/company_info_service.dart   ⭐ NEW (opsiyonel — UserService.getCompanySettings reuse de OK)
3. lib/services/print/receipt_template.dart         📝 EDIT
   - Constructor: company opsiyonel param
   - buildSaleReceipt: firma blok render (companyName, address, VKN/VD, phone)
   - buildSaleReceipt: disclaimer footer (KOŞULLU)
   - buildTestPage: aynı blok
4. lib/features/sales/.../receipt_print_dialog.dart 📝 EDIT (varsa, ReceiptTemplate consumer'ı)
   - ReceiptTemplate(settings, company: ref.watch(companyInfoProvider))
5. lib/features/settings/screens/company_settings_screen.dart 📝 EDIT
   - Save sonrası companyInfoProvider.notifier.refreshFromBackend() çağır
```

## Risk + Yasaklar

| Risk | Etki | Mitigasyon |
|---|---|---|
| Backend `getCompanySettings()` fail → fiş basılmaz | UX kritik | `loaded=true` ama tüm alanlar boş → eski `headerText` fallback (regresyon yok) |
| Çok satır firma bilgisi kağıt israfı | Termal kağıt maliyeti | `paperWidth=58mm` durumunda compact format (adres tek satır kısaltılır) |
| Multi-tenant: yanlış firma bilgisi cache'lenir | Security/privacy | `companyInfoProvider` user logout'ta invalidate (Sprint 30 to-do) |
| i18n key eklemesi sprint scope'unu büyütür | Yan iş | `bnd-rcp-disclaimer` 1 key — küçük tutulur |

**Yasaklar:**
- ❌ ÖKC sertifikasyon kodu — donanım/yasal kapsam dışı
- ❌ E-Arşiv XML serializer — Sprint 32+ scope
- ❌ Tax rate validation (1/8/10/18/20 sınırlama) — backend zaten zorlamıyor, KOBİ tax rate freedom
- ❌ "Resmi fiş" görüntüsü — disclaimer çıkarılması yasal sorun yaratır

## Sources

- [[sources/code-refs/2026-05-06-eArsiv-receipt-compliance-audit]] — denetim
- [`print_settings.dart`](project_pos/lib/services/print/print_settings.dart) — paterni klonlanacak
- [`receipt_template.dart`](project_pos/lib/services/print/receipt_template.dart) — düzenlenecek
- [`user_service.dart`](project_pos/lib/features/settings/services/user_service.dart):148-167 — `getCompanySettings()` API
- [`feedback_project_code_structure.md`](memory) — Riverpod/SharedPreferences/AppLogger paterni

## İlgili

- Sprint 29-fix-7 log: KDV format temeli
- [[syntheses/integrations-hub-architecture]] — yapılandırma yönetimi paterni (referans)
- Sprint 32+ olası: ÖKC + E-Arşiv sertifikasyon yolu (bu sentezde dışarıda tutuldu)
