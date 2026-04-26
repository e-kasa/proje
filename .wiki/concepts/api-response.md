---
title: API Response Zarfı — Tek Kaynak
type: concept
source: .claude/reference/api-response.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# API Response Zarfı — Tek Kaynak

Tüm backend endpoint'leri **aynı zarfı** döner. Client her zaman `data` key'inden okur.

---

## Başarı

```json
// Tekil
{ "success": true, "data": { ... }, "message": null }

// Liste
{ "success": true, "data": [ ... ], "message": null }
```

## Hata

```json
{
  "success": false,
  "data": null,
  "message": "Hata mesajı",
  "errorCode": "XXXX"
}
```

---

## Client Tarafı

### Flutter
```dart
final items = List<Map<String,dynamic>>.from(response.data['data'] ?? []);
// ❌ response.data['items']   — YANLIŞ
// ✅ response.data['data']    — HER ZAMAN
```

### React / TypeScript
```typescript
const items = (res.data.data ?? []) as MyType[];
// axios interceptor res.data.data'yı otomatik unwrap edebilir — axiosClient'e bak
```

---

## Backend Tarafı

```java
// Controller
return ResponseEntity.ok(ApiResponse.success(service.getAll()));

// Exception → AppExceptionHandler @ControllerAdvice yakalar
// → ApiErrorResponse { success: false, message, errorCode }
```

---

## Exception → HTTP Status Eşleme

| Exception | HTTP | Kullanım |
|-----------|------|---------|
| `NotFoundException` | 404 | Kayıt bulunamadı |
| `BusinessException` | 400 | İş kuralı ihlali, yetersiz stok |
| `ConflictException` | 409 | Duplicate kayıt, SKU çakışması |
| `DataConflictException` | 409 | Veri bütünlüğü ihlali |
| `OperationNotAllowedException` | 403 | İzinsiz işlem |
| `CompanyIsolationViolationException` | 403 | Tenant sızıntısı — KRİTİK |

### Kullanım Kuralı

```java
// ✅ DOĞRU — log'da net mesaj
throw new NotFoundException("Ürün bulunamadı: " + id);
throw new BusinessException("Stok yetersiz: mevcut=" + c + ", istenen=" + r);
throw new ConflictException("Bu SKU zaten kayıtlı: " + sku);

// ❌ YANLIŞ — TOpenMessage.toString() object reference döner → log okunmaz
throw new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006));
// Log: "TOpenException: [com.towpen.base.restservice.model.TOpenMessage@5bd0d0d5]"
```

`TOpenException` sadece core kütüphanesi (`BaseDbServiceImp.findAndCheckById()` vb.) içinden re-throw ediliyorsa kabul edilebilir. Servis/controller kodunda `new TOpenException(...)` **yazma**.

---

## Sık Yapılan Hatalar

| Hata | Çözüm |
|------|-------|
| `res.data.items` okumak | `res.data.data` |
| Direkt `res.data` kullanmak | `res.data.data` — wrapper var |
| TOpenException fırlatmak | Proje exception'larını kullan |
| `message: null` başarıda | Normal — frontend kontrol etmeli |
