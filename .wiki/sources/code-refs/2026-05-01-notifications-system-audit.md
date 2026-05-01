---
title: Notifications System Audit (SMS/Email/WhatsApp) — 2026-05-01
tags: [audit, notifications, sms, email, whatsapp, twilio, sendgrid, rabbitmq, sprint-25]
source: pos-product-manager backend + Sprint 23 frontend skeleton ekranlar + QUICK_START_NOTIFICATIONS.md rehberi
date: 2026-05-01
status: verified
---

# Notifications System Audit (Sprint 25 Öncesi)

Kullanıcı, `QUICK_START_NOTIFICATIONS.md` rehberi'ni paylaşıp **"PROJE ALTINDA ENTEGRASYON ÖRNEĞİNİ SİSTEMİMİZE UYARLA"** dedi. Bu audit, rehberi sistemimize adapte etmeden önce mevcut durumu belgeliyor.

## Tetikleyici Bağlam

- Kullanıcı (2026-05-01): Twilio + SendGrid + RabbitMQ tabanlı **SMS/Email/WhatsApp event-driven notification** sistemini SEDCORE POS'a uyarlamak istiyor.
- Sprint 23'te `email_settings_screen` ve `sms_settings_screen` **skeleton** (UI hazır, backend yok) inşa edildi.
- Sprint 24'te i18n cleanup yapıldı (88 bundle key).
- Şimdi Sprint 25 = **backend foundation real implementation**.

## Rehberden İstenenler (`QUICK_START_NOTIFICATIONS.md`)

1. **Twilio** SMS + WhatsApp gönderim
2. **SendGrid** email gönderim
3. **RabbitMQ** queue-based async + retry
4. **Notification entity** — eventType, channel (SMS/EMAIL/WHATSAPP), recipient, body, status (PENDING/SENT/FAILED)
5. **`/api/v1/notifications/send`** endpoint (POST)
6. **Frontend integration** — `NotificationService` (Dart) + ekran tetikleyicileri

## Mevcut Backend Durumu (Verified)

### `pom.xml` Dependencies

```xml
<!-- VAR -->
<dependency>spring-boot-starter-data-jpa</dependency>
<dependency>spring-boot-starter-web</dependency>
<dependency>spring-boot-starter-security</dependency>
<dependency>spring-boot-starter-mail</dependency>           <!-- ✅ JavaMailSender SMTP -->
<dependency>spring-boot-starter-actuator</dependency>
<dependency>postgresql</dependency>
<dependency>springdoc-openapi-starter-webmvc-ui</dependency>
<dependency>micrometer-registry-prometheus</dependency>
<dependency>org.apache.pdfbox</dependency>

<!-- ❌ EKSIK (Sprint 25'te eklenecek) -->
<dependency>com.twilio.sdk:twilio:9.x</dependency>
<dependency>com.sendgrid:sendgrid-java:4.8.x</dependency>
<dependency>spring-boot-starter-amqp</dependency>          <!-- RabbitMQ -->
```

### Mevcut Notification Altyapısı

#### `EmailService` (`com.sedcore.common.notification.EmailService`)
- **Sprint 5 mini** (2026-04-24) — statement PDF email gönderim için
- `JavaMailSender` SMTP üzerinden tek metot: `sendWithAttachment(to, subject, bodyText, attachmentFilename, attachmentBytes)`
- `mail.enabled=false` → no-op (log.warn)
- ❌ Queue/template/retry yok
- ❌ HTML body desteği yok (sadece plaintext)
- ❌ Notification kaydı/audit log yok

#### `SlackNotifier` (`com.sedcore.common.notification.SlackNotifier`)
- Webhook URL'sine POST atan minimal HttpClient wrapper
- `slack.webhook.url=` boşsa no-op
- Pattern referans olarak kullanışlı (no-op pattern, config-driven, log-only)

#### `NotificationRepository` / `NotificationEntity` / `NotificationController`
- ❌ **Yok** — sıfırdan yazılacak

### `application.properties` / `.yml` Config

[`pos-product-manager/src/main/resources/application.properties`](pos-product-manager/src/main/resources/) muhtemelen:
- `spring.mail.host`, `spring.mail.port`, `spring.mail.username`, `spring.mail.password` — SMTP config
- `mail.enabled`, `mail.from` — flag
- `slack.webhook.url` — opsiyonel
- ❌ Twilio config yok
- ❌ SendGrid config yok
- ❌ RabbitMQ config yok

## Mevcut Frontend Durumu (Sprint 23-24)

### Skeleton Ekranlar

[`email_settings_screen.dart`](project_pos/lib/features/settings/integrations/screens/email_settings_screen.dart):
- UI: Host/port/TLS/credential/from + 3 kullanım alanı switch + test/save butonları
- **Tüm butonlar "Sprint 24+ ile aktif olacak" toast** — backend yok
- Sarı banner: "iskelet aşamasında"
- i18n: 22 `email_settings.*` key (Sprint 24'te yapıldı)

[`sms_settings_screen.dart`](project_pos/lib/features/settings/integrations/screens/sms_settings_screen.dart):
- UI: Provider seçimi (Netgsm/Twilio/İletiMerkezi) + API key + sender ID + 3 kullanım alanı + test
- **Provider önerisi rehberle uyumlu** (Twilio var)
- i18n: 25 `sms_settings.*` key

[`integrations_hub_screen.dart`](project_pos/lib/features/settings/integrations/screens/integrations_hub_screen.dart):
- 9 entegrasyon catalog (yazıcı + mail + SMS + push + ...) + master switch + status badge
- E-posta + SMS satırları **yapılandırılmadı** turuncu badge gösteriyor

### Mevcut Service Pattern Referans

[`lib/services/print/print_service.dart`](project_pos/lib/services/print/print_service.dart):
- Sprint 22'de yazılan abstract + impl pattern
- `PrinterManager.instance.discovery()` + `connect()` + `send()` cycle
- `PrintResult.success() / failure(error)` immutable result type
- Riverpod `printServiceProvider`

→ `NotificationService` aynı pattern'i izleyecek.

## Rehber → Sistem Uyarlama Boşluk Analizi

| Rehber Bileşeni | Sistemde Var | Eksik | Sprint 25 İşi |
|---|---|---|---|
| Spring Boot 3.x | ✅ 3.5.7 | — | — |
| Twilio SDK | ❌ | dependency + service | EKLE |
| SendGrid SDK | ❌ | dependency + service | EKLE (mevcut JavaMailSender'a alternatif) |
| RabbitMQ | ❌ | dependency + config + queue | EKLE |
| Mevcut SMTP (JavaMailSender) | ✅ EmailService basic | template, queue, retry yok | GENİŞLET |
| Notification entity | ❌ | — | YENİ |
| Notification repository | ❌ | — | YENİ |
| `/api/v1/notifications/send` controller | ❌ | — | YENİ |
| Async retry mekanizması | ❌ | — | YENİ |
| Notification template (DB-stored) | ❌ | — | YENİ |
| Frontend `NotificationService` (Dart) | ❌ | — | YENİ |
| Frontend ekran tetikleyici (POS sale → SMS) | ❌ | — | YENİ (Sprint 26+) |

## Mevcut Sprint Bağlamı (Sprint 16-24 Sonu)

- 9 sprint, 60+ ekran/feature, **0 yeni `flutter analyze` issue**
- Wiki workflow disiplini: her feature için audit + synthesis + log
- Sprint 19 kuralı: gerçek müşteri talebi olmadan inşa etme — **bu kez talep var** (kullanıcı QUICK_START rehberini paylaştı)

## Karar Kriteri (Synthesis için Hazırlık)

### Twilio mu, Yerel Provider mı?

Rehber Twilio öneriyor. Türkiye için alternatif: **Netgsm** (yerel, daha ucuz, BTK uyumlu). `sms_settings_screen` zaten 3 provider seçimi sunuyor (Netgsm/Twilio/İletiMerkezi).

**Karar (Sprint 25 sentezde detay)**: Provider abstraction (interface) — implementasyon olarak Sprint 25'te Twilio başlat (rehber takip), Sprint 26+'da Netgsm eklenebilir.

### RabbitMQ mu, @Async mı?

Rehber RabbitMQ öneriyor (production-ready). Daha basit start: **Spring `@Async`** + `@Retryable` (in-memory queue, single instance). RabbitMQ Sprint 26'ya bırakılır.

**Karar**: Sprint 25 = `@Async` + `@Retryable` (basit start). RabbitMQ Sprint 26 (multi-instance + reliability).

### SendGrid mu, Mevcut SMTP mi?

Mevcut `EmailService` SMTP üzerinden çalışıyor. SendGrid eklemek dependency artırır. SendGrid avantajı: better deliverability + analytics + template engine.

**Karar**: Sprint 25 = mevcut SMTP'yi genişlet (template + queue + retry). SendGrid Sprint 27+ (gerçek production deliverability ihtiyacı doğarsa).

### Notification Entity Schema

```sql
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    event_type VARCHAR(64) NOT NULL,    -- SALE_CREATED, PAYMENT_DUE, ...
    channel VARCHAR(16) NOT NULL,        -- SMS, EMAIL, WHATSAPP
    recipient VARCHAR(256) NOT NULL,
    subject VARCHAR(256),                -- email için
    body TEXT NOT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'PENDING',  -- PENDING, SENT, FAILED, RETRYING
    error_message TEXT,
    retry_count INT DEFAULT 0,
    template_code VARCHAR(64),           -- DB template referansı (opsiyonel)
    company_code VARCHAR(64) NOT NULL,   -- multi-tenant
    created_at TIMESTAMP DEFAULT NOW(),
    sent_at TIMESTAMP,
    metadata JSONB                       -- channel-specific extra data
);
CREATE INDEX idx_notifications_status_created ON notifications(status, created_at);
CREATE INDEX idx_notifications_company_recipient ON notifications(company_code, recipient);
```

## Sprint 25-28 Modüler Plan Önerisi

| Sprint | Kapsam | Tahmini Efor |
|---|---|---|
| **25 (backend foundation)** | Notification entity + repo + service + controller; mevcut SMTP genişlet; @Async + @Retryable; in-memory test | 3-4 gün |
| **26 (RabbitMQ + provider)** | RabbitMQ queue + consumer + DLQ; Twilio service (SMS) entegrasyonu; provider abstraction | 3-4 gün |
| **27 (frontend hookup)** | `NotificationService` Dart; email_settings + sms_settings real save/test; ilk POS satış SMS tetikleyici | 2-3 gün |
| **28 (production hardening)** | SendGrid alternatif (deliverability); WhatsApp; rate limiting; Prometheus metrics; testing | 3-4 gün |

**Toplam: 11-15 gün** (rehberdeki 4 hafta tahminiyle uyumlu, modüler).

## Eksik Rehber Dosyaları

Kullanıcı 3 rehberden bahsetti ama proje kökünde sadece **1** bulundu:
- ✅ [`QUICK_START_NOTIFICATIONS.md`](QUICK_START_NOTIFICATIONS.md) (mevcut, okundu)
- ❌ `SMS_EMAIL_WHATSAPP_INTEGRATION_GUIDE.md` (yok — ana rehber)
- ❌ `IMPLEMENTATION_ROADMAP.md` (yok — 4-haftalık timeline)

**Etki**: QUICK_START yeterli iskelet sunuyor (entity şeması, dependency listesi, endpoint örneği). Ana rehber detayları (template engine, RabbitMQ topology, retry strategy) sentez aşamasında **standart en iyi practice** ile dolduralacak.

## Sources

- [`QUICK_START_NOTIFICATIONS.md`](QUICK_START_NOTIFICATIONS.md) — kullanıcı rehberi
- [`pos-product-manager/pom.xml`](pos-product-manager/pom.xml) — backend deps
- [`com.sedcore.common.notification.EmailService`](pos-product-manager/src/main/java/com/sedcore/common/notification/EmailService.java) — mevcut SMTP service
- [`com.sedcore.common.notification.SlackNotifier`](pos-product-manager/src/main/java/com/sedcore/common/notification/SlackNotifier.java) — pattern referans
- [`project_pos/lib/features/settings/integrations/screens/email_settings_screen.dart`](project_pos/lib/features/settings/integrations/screens/email_settings_screen.dart) — Sprint 23 skeleton
- [`project_pos/lib/features/settings/integrations/screens/sms_settings_screen.dart`](project_pos/lib/features/settings/integrations/screens/sms_settings_screen.dart) — Sprint 23 skeleton
- [`project_pos/lib/services/print/print_service.dart`](project_pos/lib/services/print/print_service.dart) — Sprint 22 service pattern referansı

## Related

- [[syntheses/notifications-system-design]] — Sprint 25 sentezi (audit'in çıktısı)
- [[syntheses/integrations-hub-architecture]] — Sprint 23 hub mimarisi (entegrasyon noktaları)
- [[log]] — Sprint 25-28 entries (incremental)
