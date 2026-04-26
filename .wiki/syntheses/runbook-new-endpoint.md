---
title: Runbook — Yeni Backend Endpoint Eklemek
type: synthesis
source: .claude/runbooks/new-endpoint.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# Runbook — Yeni Backend Endpoint Eklemek

Önce oku: `reference/url-routing.md`, `reference/api-response.md`, `reference/multi-tenant.md`.

---

## 1. Controller

```java
@RestController
@RequestMapping("/api/v1/my-resource")   // Flutter: product/api/v1/my-resource
@RequiredArgsConstructor
public class MyControllerImpl implements MyController {

    private final MyService myService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<MyResponseDto>>> getAll() {
        try {
            return ResponseEntity.ok(ApiResponse.success(myService.getAll()));
        } catch (TOpenException e) {
            throw ExceptionMapper.map(e);
        }
    }

    @PostMapping
    public ResponseEntity<ApiResponse<MyResponseDto>> create(
            @RequestBody @Valid MyRequestDto request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(myService.create(request)));
    }
}
```

**Kural:** `@RequestHeader("X-Company-Code")` **YAZMA** — token'da zaten var, `CompanyContext.get()` ile alınır.

---

## 2. Service

```java
@Service
@Transactional
public class MyServiceImpl extends BaseDbServiceImp<MyRepository, MyEntity>
        implements MyService {

    public MyResponseDto create(MyRequestDto request) {
        MyEntity entity = new MyEntity();
        entity.setCompanyCode(CompanyContext.get());   // ✅ context'ten
        entity.setName(request.getName());
        return toDTO(repository.save(entity));
    }

    @Override
    protected MyResponseDto toDTO(MyEntity e) {
        return MyResponseDto.builder()
            .id(e.getId()).name(e.getName()).build();
    }
}
```

**Paket:** `com.sedcore.{modul}.service.impl` — AOP pointcut yakalaması için zorunlu.

---

## 3. DTO

```java
// Request — validasyon zorunlu
public class MyRequestDto {
    @NotBlank private String name;
    @NotNull @Positive private Double price;
}

// Response — DtoBaseModel extend (id, createdAt)
public class MyResponseDto extends DtoBaseModel {
    private String name;
    private Double price;
    // ❌ companyCode frontend'e dönme
}
```

---

## 4. Public Endpoint ise — 4 Yer Güncelle

Eğer endpoint JWT olmadan erişilecekse:

1. `api-manager/JwtAuthFilter.PUBLIC_PATHS`
2. `api-manager/CompanyResolutionFilter.isPublicPath()`
3. `security/SecurityConfiguration.requestMatchers().permitAll()` (security servisinde ise)
4. `core/JwtXUserInfoFilter.PUBLIC_PATHS` (path `/api/**` ile başlıyorsa)

---

## 5. i18n Mesaj Anahtarları

`security/src/main/resources/data.sql`'e ekle:

```sql
('bnd-XX000-0000-0000-NNNNNNNNNNNN', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
 'prefix.key', 'Türkçe Metin', 'English Text'),
```

Modül prefix: `bt`=batch, `wz`=wizard, `pd`=product, `st`=stock, `sl`=sale, `pu`=purchase, `cu`=customer, `su`=supplier, `rp`=report, `fn`=finance, `se`=settings, `au`=auth, `cm`=common, `db`=dashboard.

---

## 6. Client Çağrısı

```dart
// Flutter
final res = await _apiClient.get('product/api/v1/my-resource');
final items = List<Map<String,dynamic>>.from(res.data['data'] ?? []);
```

```typescript
// React — endpointBuilder'a ekle
export const ENDPOINTS = {
  ...
  myResource: '/product/api/v1/my-resource',
};
const res = await axiosInstance.get(ENDPOINTS.myResource);
```

---

## 7. Test Checklist

- [ ] Sadece login kullanıcının firmasındaki kayıtlar dönüyor mu?
- [ ] Başka firmada aynı ID → CompanyIsolationViolationException fırlıyor mu?
- [ ] Validasyon hatası → HTTP 400 + net mesaj
- [ ] Kayıt bulunamadı → HTTP 404
- [ ] Flutter `res.data['data']` okuyor mu?
- [ ] Public endpoint ise 4 filter listesi güncel mi?
