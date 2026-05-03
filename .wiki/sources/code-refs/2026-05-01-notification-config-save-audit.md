---
title: Sprint 29 — Notification Config Save Audit (Email SMTP)
tags: [audit, notifications, email, smtp, config, runtime-refresh, security, sprint-29]
source: pos-product-manager EmailService + Sprint 25 NotificationService + Sprint 27 frontend skeleton
date: 2026-05-01
status: verified
---

# Sprint 29 — Notification Config Save Audit (Email SMTP)

Sprint 27'de `email_settings_screen` "Kaydet" butonu skeleton'da bırakıldı (toast: *"Yapılandırma kaydı Sprint 24+ ile aktif olacak"*). Sprint 29 = bu butonu gerçek API'ye bağla. **EMAIL kanalı odaklı**; SMS/Twilio config save Sprint 30'a (aynı pattern).

## Tetikleyici

Kullanıcı, 2026-05-01: Sprint 28 sonu *"1"* — Sprint 29+ kuyruğundan **"SMTP/Twilio config save endpoint"** seçimi.

## Mevcut Durum (Backend)

### `EmailService` (Sprint 5 mini, 2026-04-24)

[`com.sedcore.common.notification.EmailService`](pos-product-manager/src/main/java/com/sedcore/common/notification/EmailService.java):

```java
public EmailService(
    @Nullable JavaMailSender mailSender,                  // @Bean autoconfigure
    @Value("${mail.enabled:false}") boolean enabled,      // @Value compile-time
    @Value("${mail.from:noreply@sedcore.com}") String fromAddress) {
    ...
}
```

**Kısıtlamalar:**
- `JavaMailSender` Spring `JavaMailSenderAutoConfiguration` ile `application.properties`'tan oluşturulur (`spring.mail.host`, `spring.mail.port`, `spring.mail.username`, `spring.mail.password`)
- `@Value` static — runtime değişmez. Bean ilk yaratılınca config sabittir.
- `mail.enabled=false` no-op (log warn)
- HTML body yok, attachment optional

### Sprint 25 NotificationService

[`com.sedcore.notification.service.NotificationService`](pos-product-manager/src/main/java/com/sedcore/notification/service/NotificationService.java):
- `EmailChannel` → `EmailService.sendWithAttachment(...)` thin wrap
- `EmailService` ne dönerse o davranır; config refresh yetkisi yok

### `application.properties`

```properties
mail.enabled=false
mail.from=noreply@sedcore.com
# spring.mail.host=smtp.example.com
# spring.mail.port=587
# spring.mail.username=apikey
# spring.mail.password=${SPRING_MAIL_PASSWORD:}
# spring.mail.properties.mail.smtp.auth=true
# spring.mail.properties.mail.smtp.starttls.enable=true
```

Şu an config **deployment-time** (env var + properties dosyası). UI'dan değiştirilemez.

## Mevcut Durum (Frontend)

[`email_settings_screen.dart`](project_pos/lib/features/settings/integrations/screens/email_settings_screen.dart):
- 5 input controller: `_hostCtl`, `_portCtl`, `_usernameCtl`, `_passwordCtl`, `_fromCtl`
- 1 toggle: `_useTls`
- 3 placeholder switch (kullanım alanları)
- "Kaydet" buton → `AppToast.info(t('email_settings.save_coming_soon'))` ❌ skeleton
- "Test E-postası Gönder" → Sprint 27 real (mevcut `EmailService` SMTP üzerinden)

**Eksik**: 
- Init'te DB'den config yükleme yok
- Save butonu gerçek API çağırmıyor
- Test SMS/Email config doldurulmadan değil — env var SMTP'yi test ediyor

## Sprint 29 Tasarım Sorunları & Kararlar

### Sorun 1: SMTP Credentials DB'de Plain Text mi?

SMTP password DB'ye düz metin yazmak güvenlik riski (DB backup leak, log leak). Çözümler:

| Yaklaşım | Karmaşıklık | MVP uygun? |
|---|---|---|
| Plain text + warning | Düşük | Sadece dev/staging |
| Jasypt application-level | Orta | ✅ MVP için iyi |
| PostgreSQL pgcrypto column | Orta | DB-side, key yönetimi gerek |
| HashiCorp Vault | Yüksek | Üretim için ideal |

**Sprint 29 Karar**: **Plain text + WARN log** + property `notification.config.security.warn=true`. Production geçişinde Vault Sprint 30+. Dev/staging için yeterli, scope korumacı.

### Sorun 2: Runtime Refresh — Spring `@Value` Static

`EmailService` ilk yaratıldığında `JavaMailSender` bean'ı sabittir. Config DB'de değişince:

- **Yaklaşım A**: Service her çağrılığında DB'den oku → `JavaMailSenderImpl` her seferinde yeniden inşa et (slow + GC pressure)
- **Yaklaşım B**: `NotificationConfigService` cache + DB değişince `cache.evict()` + `EmailService` cache.get() (ORTA)
- **Yaklaşım C**: Spring Cloud Config + `@RefreshScope` (kompleks, deployment overhead)

**Sprint 29 Karar**: **Yaklaşım B**. `NotificationConfigService` ConcurrentHashMap cache; PUT endpoint cache.invalidate; `EmailService.send()` cache'den config'i çekip `JavaMailSenderImpl` instance'ı oluşturur (per-call, lightweight).

### Sorun 3: Multi-Tenant — Her Şirketin Kendi SMTP'si

`TOpenSimpleCompanyEntity` zaten `companyCode` ekler. `NotificationConfigEntity` extend eder → otomatik filter. Her şirket kendi SMTP credentials'ına sahip olur. Bu **doğru ve istenen** davranış.

### Sorun 4: Mevcut `application.properties` Config'i Korunsun mu?

Eski deployment-time config bozulmasın. Hibrit yaklaşım:
- **DB-stored config öncelikli** (varsa kullan)
- **Yoksa fallback `application.properties`**

Bu sayede Sprint 5 mevcut `mail.from`, `mail.enabled`, `spring.mail.*` korunur; UI'dan kayıt yapılmamış şirketler etkilenmez.

### Sorun 5: Schema — Tek Tablo Key-Value mi, Channel-Specific mi?

| Yaklaşım | Pro | Con |
|---|---|---|
| Tek tablo + JSON column | Esnek | Type-safety yok, query zor |
| Tek tablo + key-value | Migration kolay | Çok satır |
| Channel-specific table | Type-safe | Her yeni channel için migration |

**Sprint 29 Karar**: **Tek tablo + key-value**. Sebep: Sprint 30 SMS/Twilio aynı tabloyu kullanır. Migration tek seferlik.

```sql
CREATE TABLE notification_configs (
    id VARCHAR(36) PRIMARY KEY,
    config_channel VARCHAR(16) NOT NULL,    -- EMAIL, SMS, WHATSAPP
    config_key VARCHAR(64) NOT NULL,         -- host, port, username, password, ...
    config_value TEXT,
    encrypted BOOLEAN DEFAULT FALSE,
    company_code VARCHAR(64) NOT NULL,
    -- audit fields TOpenSimpleCompanyEntity inherited
    UNIQUE (company_code, config_channel, config_key)
);
```

## Sprint 29 Kapsam

### Backend (5 yeni dosya + 1 edit)

1. `entity/NotificationConfigEntity.java` — channel + key + value + encrypted flag
2. `repository/NotificationConfigRepository.java` — `findByConfigChannel()` + `findByConfigChannelAndConfigKey()`
3. `service/NotificationConfigService.java` — get(channel) Map<key,value> + save(channel, Map) + cache + invalidate
4. `controller/NotificationConfigController.java` — `GET /api/v1/notification-settings/email` + `PUT /api/v1/notification-settings/email`
5. `dto/EmailConfigDto.java` — host, port, useTls, username, password (mask), from

**Edit**: `EmailService.java` — `JavaMailSender` constructor'da injecte etmek yerine `NotificationConfigService` kullanarak `JavaMailSenderImpl` per-call oluştur. Backward compat için `application.properties` fallback korunur.

### Frontend (1 edit)

`email_settings_screen.dart`:
- `initState` → `notificationConfigService.loadEmail()` ile mevcut config'i yükle, controller'lara doldur
- "Kaydet" buton → `notificationConfigService.saveEmail(EmailConfigDto)` real API call
- Password mask: backend GET'inde plain dönmesin (`****` gibi); save'de yeni değer girilmemişse mevcudu koruyacak (omit field veya special marker)

### Güvenlik Önlemi

- Backend `application.properties`'e: `notification.config.security.warn=true` flag → SMTP password plain text saklı warning log atar
- Frontend "Kaydet" sonrası toast: *"Kaydedildi. Şifreler dev ortamda plain text saklanır — production için Vault entegrasyonu önerilir."*
- Sprint 30+'da Jasypt encryption ekleneceği `// TODO Sprint 30` ile işaretlenir

## Sprint 30 Hazırlık (Bu Sprint Sonrası)

1. **SMS/Twilio config save** — aynı `notification_configs` tablosu, `configChannel='SMS'`. `TwilioSmsProvider` refactor: DB config first, application.properties fallback
2. **Jasypt encryption** — `encrypted=true` row'lar için decrypt-on-read, encrypt-on-write
3. **Notification config audit log** — kim ne zaman değiştirdi (Sprint 27'de zaten `TOpenSimpleCompanyEntity` audit alanları var)

## Sources

- [`EmailService.java`](pos-product-manager/src/main/java/com/sedcore/common/notification/EmailService.java)
- [`application.properties`](pos-product-manager/src/main/resources/application.properties) `mail.*` block
- [`email_settings_screen.dart`](project_pos/lib/features/settings/integrations/screens/email_settings_screen.dart) skeleton
- [[sources/code-refs/2026-05-01-notifications-system-audit]] — Sprint 25 audit
- [[syntheses/notifications-system-design]] — 4 sprint mimari sentez

## Related

- [[log]] — Sprint 25, 27, 28 (notifications zinciri); Sprint 29 (bu)
- Sprint 30 takip eden audit: SMS config save + Twilio gerçek aktivasyon
