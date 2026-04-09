# POS System - Error Handling & Exception Standardization Guide

## Overview
Bu dokuman POS microservices architecture'inda TOpenException standardizasyonunun nasıl uygulandığını ve her hatanın kendi spesifik kodunun nasıl atandığını açıklar.

## Hata Kodu Kategorileri

### Validation Errors (1001-1099)
| Kod | Enum | Türkçe | English |
|-----|------|--------|---------|
| 1001 | FIELD_IS_REQUIRED_1001 | Gerekli alan boş | Required field is empty |
| 1002 | BETWEEN_MIN_AND_MAX_1002 | Min-Max arası olmalı | Value between min-max |
| 1003 | CAN_NOT_BE_LARGER_THAN_1003 | Maksimumdan büyük | Larger than maximum |
| 1004 | ALREADY_EXISTS_1004 | Zaten sistemde var | Already exists |
| 1006 | NOT_EXISTS_IN_THE_RECORDS_1006 | Kayıtta bulunamadı | Record not found |
| 1032 | VALIDATION_MIN_SIZE_1032 | Minimum boyut hatası | Minimum size failed |
| 1033 | VALIDATION_MAX_SIZE_1033 | Maksimum boyut hatası | Maximum size failed |
| 1046 | ENTERED_DATA_IS_NOT_IN_FORMAT_1046 | Format uygun değil | Format invalid |

### Authorization & Access (1012, 2000+)
| Kod | Enum | Türkçe | English |
|-----|------|--------|---------|
| 1012 | NOT_AUTHORIZED_1012 | Yetki yok | Not authorized |
| 1200 | FIELD_CANNOT_BE_CHANGED_1200 | Alan değiştiremez | Field cannot change |
| 2000+ | AUTHORIZATION_* | Yetkilendirme hataları | Authorization errors |

### System Errors (9000+)
| Kod | Enum | Türkçe | English |
|-----|------|--------|---------|
| 9998 | NO_RESULT_FOUND_9998 | Sonuç bulunamadı | No results found |
| 9999 | UNEXPECTED_ERROR_9999 | Beklenmeyen hata | Unexpected error |

## ExceptionMapper Utility

### Amaç
Sistem'deki tüm exception'ları kontekstine göre uygun TMessageType'a otomatik olarak harita etmek.

### Kullanım

```java
// 1. Manual mapping - specific error
throw ExceptionMapper.notFound("Purchase[123]");  // → 1006
throw ExceptionMapper.duplicateEntry("Customer[456]");  // → 1004

// 2. Automatic mapping - intelligent detection
try {
    purchaseService.create(request);
} catch (TOpenException e) {
    throw e;
} catch (Exception e) {
    // Otomatik olarak 1006 (not found), 1004 (duplicate), etc. algılar
    throw ExceptionMapper.mapAndLog(e, "createPurchase");
}

// 3. Generic mapping
throw ExceptionMapper.map(e);  // Message'a göre otomatik
```

### Mapping Logic
```
Exception Message Pattern → TMessageType Code
┌─────────────────────────────────────────────────┐
│ "bulunamadı" / "not found"         → 1006      │
│ "already exists" / "zaten var"     → 1004      │
│ "required" / "gerekli"             → 1001      │
│ "between" / "arasında"             → 1002      │
│ "insufficient" / "yetersiz"        → 1300+     │
│ "unauthorized" / "yetki"           → 1012      │
│ "format" / "invalid"               → 1046      │
│ Diğer durumlar                     → 9999      │
└─────────────────────────────────────────────────┘
```

## Controller'larda İmplementasyon Örneği

### PurchaseControllerImpl - Best Practice
```java
@PostMapping
public ResponseEntity<ApiResponse<PurchaseResponse>> create(
        @Valid @RequestBody PurchaseRequest request) {
    try {
        PurchaseResponse response = purchaseService.createPurchase(request);
        log.info("Satin alma olusturuldu: fatura={}", response.getInvoiceNumber());
        return ResponseEntity.ok(ApiResponse.success(response));
    } catch (TOpenException e) {
        throw e;  // Already mapped - propagate as-is
    } catch (Exception e) {
        // Automatic context-aware error mapping
        throw ExceptionMapper.mapAndLog(e, "createPurchase");
    }
}

@GetMapping("/{id}")
public ResponseEntity<ApiResponse<PurchaseResponse>> getById(@PathVariable String id) {
    try {
        return ResponseEntity.ok(ApiResponse.success(purchaseService.getPurchase(id)));
    } catch (TOpenException e) {
        throw e;
    } catch (Exception e) {
        // Specific: Not found operations
        throw ExceptionMapper.notFound("Purchase[" + id + "]");
    }
}
```

## Exception Handling Flow

```
┌──────────────────┐
│  REST Request    │
└────────┬─────────┘
         │
    ┌────▼─────────────────┐
    │  @Controller Method   │
    │  try { ... }          │
    └────┬──────────┬───────┘
         │          │
    ┌────▼──┐   ┌───▼─────────────┐
    │ Service│   │ Exception       │
    │ Success│   │ Caught          │
    └────┬──┘   └───┬─────────────┘
         │          │
         │      ┌───▼──────────────────┐
         │      │ ExceptionMapper      │
         │      │ - Detect type        │
         │      │ - Analyze message    │
         │      │ - Log details        │
         │      │ - Return TOpen*      │
         │      └───┬──────────────────┘
         │          │
    ┌────▼──────────▼───┐
    │ TOpenException    │
    │ + TOpenMessage    │
    │ + TMessageType    │
    └────┬──────────────┘
         │
    ┌────▼─────────────────────┐
    │ AppExceptionHandler       │
    │ - Map code to HTTP status │
    │ - Format response         │
    └────┬──────────────────────┘
         │
    ┌────▼──────────────┐
    │ Client Response   │
    │ HTTP 400/404/500  │
    │ + Error Details   │
    └───────────────────┘
```

## Error Message Localization

### error-messages.properties Structure
```properties
# Format: code.key = TR: Turkish | EN: English

1001.message = TR: Gerekli alan boş | EN: Required field is empty
1004.message = TR: Bu kayıt zaten var | EN: Record already exists
1006.message = TR: Aradığınız kayıt bulunamadı | EN: Record not found
...
9999.message = TR: Beklenmeyen hata oluştu | EN: An unexpected error occurred
```

### Runtime Message Retrieval
```java
// Future: Add MessageService for i18n
String turkishMessage = messageService.getMessage("1006", "tr");
String englishMessage = messageService.getMessage("1006", "en");
```

## Commit History

1. **54949bb** - Refactor: Standardize TOpenException in ProductControllerImpl
2. **5a4e5e4** - Fix: Correct syntax errors and standardize exception handling
3. **ea9a6bd** - Feat: Implement context-specific error mapping with ExceptionMapper

## Best Practices Checklist

- ✅ Her exception catch bloğunda TOpenException re-throw
- ✅ Service hataları TOpenException'a dönüştür
- ✅ Operation adını logla (mapAndLog'a parameter olarak)
- ✅ Generic UNEXPECTED_ERROR_9999'dan kaçın
- ✅ Kontekse uygun hata kodu seç:
  - Not found → 1006
  - Duplicate → 1004
  - Validation → 1001-1033
  - Unauthorized → 1012
- ✅ Türkçe ve İngilizce hata mesajları error-messages.properties'de tut

## Future Improvements

1. **MessageService i18n** - Runtime'da Türkçe/İngilizce mesaj döndür
2. **Database Error Table** - Hata kodlarını veritabanında yönet
3. **Custom Error Codes** - 1300-1399 aralığında inventory-specific kodlar
4. **Error Analytics** - Sık yapılan hataları dashboard'da görünür kıl
5. **Graceful Fallback** - Unmapped exception'lar default mesaj ile işlensin
