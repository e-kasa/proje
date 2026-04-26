---
title: Sektör (SectorType) String Standardı — Tek Kaynak
type: concept
source: .claude/reference/sector-strings.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# Sektör (SectorType) String Standardı — Tek Kaynak

Firma sektörü **kurulumda** `CompanySetting.sectorType` alanına yazılır — sonradan değiştirilemez.  
Her firma 1 sektöre aittir. Ürün sektörü otomatik firmadan alınır.

---

## Geçerli Değerler

| SectorType (enum) | apiValue | Özel Alanlar |
|-------------------|----------|-------------|
| `autoParts` | `AUTO_PARTS` | OEM, çapraz ref, raf kodu, araç uyumu |
| `general` | `GENERAL` | Depo konumu |
| `technology` | `TECHNOLOGY` | IMEI, seri no (metadata), garanti |
| `footwear` | `FOOTWEAR` | Renk, beden/numara (multi-variant) |

---

## Client — `apiValue` Kullanımı

```dart
// ✅ DOĞRU — SectorType enum'ından apiValue
'sector': cfg.type.apiValue   // 'AUTO_PARTS' | 'GENERAL' | 'TECHNOLOGY' | 'FOOTWEAR'

// ❌ YANLIŞ — eski Türkçe legacy değerler, DB'de yanlış depolanır
'sector': 'parcaci'   // NO
'sector': 'giyim'     // NO
'sector': 'genel'     // NO
```

Hem wizard hem batch entry `sectorType.apiValue` kullanır — düzeltildi.

---

## Backend — Sektör Override

```java
// ProductServiceImpl.createProduct() — sector HER ZAMAN firmadan alınır
String companySector = companySettingRepository
    .findFirstByCompanyCodeOrderByCreateTimeDesc(CompanyContext.get())
    .map(CompanySetting::getSectorType)
    .orElse(dto.getProduct().getSector());   // fallback: request'teki değer

product.setSector(companySector);   // request'teki sector override edilir
// → Cross-sector contamination önlenir
```

---

## JWT'de Sektör

```
sessionInstance.userInformation.dynamicLoginParameters.sectorType
```

```dart
// Flutter'da
final sectorType = userInfo['dynamicLoginParameters']?['sectorType'] as String?;
// → "AUTO_PARTS" | "GENERAL" | "TECHNOLOGY" | "FOOTWEAR"
```

---

## Birim (unit) Default

```
Varsayılan: 'adet'  (hem wizard hem batch tutarlı kullanır)
```

Backend `Unit` tablosunda karşılığı olan kod gönderilmelidir.

---

## Değiştirilemezlik Kuralı

```java
// CompanySettingServiceImpl.updateSettings()
// → sectorType GÜNCELLEMEZ, sessiz ignore eder
// Değiştirmek isteyen firma → yeniden kayıt
```

---

## Sık Yapılan Hatalar

| Hata | Çözüm |
|------|-------|
| `'sector': 'genel'` | `'sector': 'GENERAL'` veya `SectorType.general.apiValue` |
| Request'te sector override etmeye çalışmak | Backend zaten firmadan alıyor |
| `sectorType` settings'ten güncellemek | Güncellenmez — firma yeniden kaydet |
