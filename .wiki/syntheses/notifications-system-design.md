---
title: Notifications System Design (SMS/Email/WhatsApp Adaptation)
tags: [synthesis, notifications, sms, email, whatsapp, twilio, sendgrid, rabbitmq, sprint-25, sprint-26, sprint-27, sprint-28]
source: project_pos + pos-product-manager + QUICK_START_NOTIFICATIONS.md
date: 2026-05-01
status: draft
---

# Notifications System Design

`QUICK_START_NOTIFICATIONS.md` rehberinin SEDCORE POS sistemine **kademeli uyarlama** mimarisi. Audit: [[sources/code-refs/2026-05-01-notifications-system-audit]].

## Tasarım İlkeleri

1. **Mevcut altyapıdan başla**: `EmailService` (SMTP) zaten Sprint 5'te yazıldı — sıfırdan yazma, **genişlet**.
2. **Provider abstraction**: SMS sağlayıcılar (Twilio/Netgsm/İletiMerkezi) interface arkasında — Sprint 23'te `sms_settings_screen` zaten 3 provider sunuyor.
3. **Kademeli yatırım** (Sprint 19 kuralı):
   - L1: Entity + endpoint + sync `@Async` (Sprint 25)
   - L2: RabbitMQ + DLQ + retry (Sprint 26)
   - L3: SendGrid alternatif + WhatsApp + rate limit (Sprint 27-28)
4. **Multi-tenant**: `company_code` her notification'da; mevcut backend pattern'iyle uyumlu.
5. **Frontend skeleton'ları gerçeğe çevir**: Sprint 23'te yazılan `email_settings` + `sms_settings` UI hazır; Sprint 27'de backend hookup.

## Mimari Hiyerarşisi (4 Sprint Sonu)

```
┌─────────────────────────────────────────────────────────────┐
│  Frontend (project_pos)                                     │
│  ─────────────────────────────────────────                  │
│  POS sale screen ──┐                                        │
│  Sale detail ──────┤                                        │
│  Account hub ──────┼─→ NotificationService.send(request)    │
│  Reports ──────────┘                                        │
│                       │                                     │
│                       ↓ HTTPS POST                          │
│  ────────────────────────────────────────────────────────── │
│  Backend (pos-product-manager)                              │
│                                                             │
│  /api/v1/notifications/send                                 │
│       ↓                                                     │
│  NotificationController                                     │
│       ↓                                                     │
│  NotificationService.queue(request)                         │
│       ↓ persist (PENDING)                                   │
│  Notifications table                                        │
│       ↓                                                     │
│  ┌────────────────────────────────────────────┐             │
│  │  Sprint 25: @Async @Retryable              │             │
│  │  Sprint 26: RabbitMQ queue + consumer      │             │
│  └────────────────────────────────────────────┘             │
│       ↓                                                     │
│  ChannelRouter.dispatch(notification)                       │
│       ├─→ EmailChannel  → EmailService → SMTP/SendGrid      │
│       ├─→ SmsChannel    → SmsProvider  → Twilio/Netgsm      │
│       └─→ WhatsAppChannel → WhatsAppProvider → Twilio       │
│       ↓ on success → status=SENT, sent_at=now              │
│       ↓ on fail → status=FAILED, error_message=..., retry  │
└─────────────────────────────────────────────────────────────┘
```

## Sprint 25: Backend Foundation (3-4 gün)

### 1. Maven Dependencies (`pom.xml`)

```xml
<!-- Sprint 25: notifications foundation (Twilio + RabbitMQ Sprint 26'da) -->
<!-- Mevcut spring-boot-starter-mail KORUNUR (genişletilecek) -->

<!-- Spring @Async retry için -->
<dependency>
  <groupId>org.springframework.retry</groupId>
  <artifactId>spring-retry</artifactId>
</dependency>
<dependency>
  <groupId>org.springframework</groupId>
  <artifactId>spring-aspects</artifactId>
</dependency>
```

**Not:** Twilio + RabbitMQ Sprint 26'da. Sprint 25 @Async + @Retryable ile başlar.

### 2. Notification Entity

```java
package com.sedcore.notification.entity;

@Entity
@Table(name = "notifications", indexes = {
  @Index(name = "idx_notifications_status_created", columnList = "status, createdAt"),
  @Index(name = "idx_notifications_company_recipient", columnList = "companyCode, recipient")
})
public class NotificationEntity extends BaseEntity {  // BaseEntity = audit fields
    @Id @GeneratedValue(strategy = IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String eventType;       // SALE_CREATED, PAYMENT_DUE, ...

    @Enumerated(STRING) @Column(nullable = false, length = 16)
    private NotificationChannel channel;  // SMS, EMAIL, WHATSAPP

    @Column(nullable = false, length = 256)
    private String recipient;

    @Column(length = 256)
    private String subject;          // email için (null SMS/WhatsApp)

    @Column(nullable = false, columnDefinition = "TEXT")
    private String body;

    @Enumerated(STRING) @Column(nullable = false, length = 16)
    private NotificationStatus status = PENDING;

    @Column(columnDefinition = "TEXT")
    private String errorMessage;

    private int retryCount = 0;

    @Column(length = 64)
    private String templateCode;     // DB template referansı (Sprint 26+)

    @Column(nullable = false, length = 64)
    private String companyCode;      // multi-tenant

    private Instant sentAt;

    @Type(JsonType.class) @Column(columnDefinition = "jsonb")
    private Map<String, Object> metadata;
}

public enum NotificationChannel { SMS, EMAIL, WHATSAPP, PUSH }
public enum NotificationStatus { PENDING, RETRYING, SENT, FAILED }
```

### 3. Repository

```java
public interface NotificationRepository extends JpaRepository<NotificationEntity, Long> {
    List<NotificationEntity> findByStatusAndRetryCountLessThan(NotificationStatus status, int max);
    Page<NotificationEntity> findByCompanyCodeAndStatusOrderByCreatedAtDesc(
        String companyCode, NotificationStatus status, Pageable pageable);
}
```

### 4. NotificationService

```java
@Service
@Slf4j
@RequiredArgsConstructor
public class NotificationService {
    private final NotificationRepository repo;
    private final ChannelRouter channelRouter;
    private final SecurityContext security;  // mevcut multi-tenant helper

    /**
     * Public API — frontend'den çağrılır.
     * Persist (PENDING) + @Async dispatch.
     */
    @Transactional
    public NotificationDto queue(NotificationRequestDto req) {
        var entity = NotificationEntity.builder()
            .eventType(req.eventType())
            .channel(req.channel())
            .recipient(req.recipient())
            .subject(req.subject())
            .body(req.body())
            .status(PENDING)
            .companyCode(security.currentCompanyCode())
            .build();
        var saved = repo.save(entity);
        // Sprint 25: @Async direct dispatch
        // Sprint 26: RabbitMQ producer
        channelRouter.dispatchAsync(saved.getId());
        return NotificationDto.fromEntity(saved);
    }

    /** Sprint 25: in-memory async with @Retryable. */
    @Async
    @Retryable(
        retryFor = TransientNotificationException.class,
        maxAttempts = 3,
        backoff = @Backoff(delay = 5000, multiplier = 2)
    )
    public void deliver(Long notificationId) {
        var n = repo.findById(notificationId).orElseThrow();
        n.setStatus(RETRYING);
        repo.save(n);
        try {
            channelRouter.send(n);  // throws on transient/permanent fail
            n.setStatus(SENT);
            n.setSentAt(Instant.now());
        } catch (PermanentNotificationException e) {
            n.setStatus(FAILED);
            n.setErrorMessage(e.getMessage());
        } finally {
            n.setRetryCount(n.getRetryCount() + 1);
            repo.save(n);
        }
    }
}
```

### 5. ChannelRouter

```java
@Component
@RequiredArgsConstructor
public class ChannelRouter {
    private final EmailChannel emailChannel;
    // Sprint 26+: private final SmsChannel smsChannel;

    public void send(NotificationEntity n) {
        switch (n.getChannel()) {
            case EMAIL -> emailChannel.send(n);
            case SMS -> throw new UnsupportedChannelException("SMS Sprint 26+");
            case WHATSAPP -> throw new UnsupportedChannelException("WhatsApp Sprint 27+");
            case PUSH -> throw new UnsupportedChannelException("Push Sprint 28+");
        }
    }
}
```

### 6. EmailChannel — Mevcut `EmailService`'i Wrap Eder

```java
@Component
@RequiredArgsConstructor
public class EmailChannel {
    private final EmailService emailService;  // mevcut Sprint 5 service

    public void send(NotificationEntity n) {
        boolean ok = emailService.sendWithAttachment(
            n.getRecipient(),
            n.getSubject() != null ? n.getSubject() : "(no subject)",
            n.getBody(),
            null, null  // Sprint 25: attachment yok
        );
        if (!ok) throw new TransientNotificationException("SMTP send returned false");
    }
}
```

**Mevcut EmailService genişletilmedi** — ileride HTML body + template support eklenecek (Sprint 27+).

### 7. NotificationController

```java
@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
public class NotificationController {
    private final NotificationService service;

    @PostMapping("/send")
    public ResponseEntity<NotificationDto> send(@RequestBody @Valid NotificationRequestDto req) {
        return ResponseEntity.accepted().body(service.queue(req));
    }

    @GetMapping
    public Page<NotificationDto> list(
        @RequestParam(required = false) NotificationStatus status,
        Pageable pageable
    ) {
        return service.list(status, pageable);
    }
}
```

### 8. application.properties Genişletme

```properties
# Sprint 25 — Notifications
notification.email.enabled=true       # mevcut mail.enabled paralel
notification.async.thread-pool.size=5
notification.retry.max-attempts=3
notification.retry.initial-delay-ms=5000
notification.retry.multiplier=2.0
```

### 9. `@EnableAsync` + `@EnableRetry`

```java
@SpringBootApplication
@EnableAsync
@EnableRetry
public class PosProductManagerApplication { ... }
```

### Sprint 25 Çıktıları

- 1 entity + repo + service + controller + 2 component
- 1 mevcut service wrap (EmailService → EmailChannel)
- 1 yeni endpoint (`POST /api/v1/notifications/send`)
- 4 enum + 3 DTO + 2 exception
- @Async retry pattern (in-memory)
- Test: integration test `NotificationServiceIntegrationTest` (H2 mevcut)

## Sprint 26: RabbitMQ + SMS Provider (3-4 gün)

### 1. Dependencies

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-amqp</artifactId>
</dependency>
<dependency>
  <groupId>com.twilio.sdk</groupId>
  <artifactId>twilio</artifactId>
  <version>9.x</version>
</dependency>
```

### 2. RabbitMQ Topology

```
Exchange: notifications (topic)
  ├─ Queue: notifications.email   (routing key: email.*)
  ├─ Queue: notifications.sms     (routing key: sms.*)
  ├─ Queue: notifications.whatsapp(routing key: whatsapp.*)
  └─ DLQ: notifications.dlq       (retry tükenince)
```

### 3. Producer (Sprint 25 `@Async` → RabbitMQ producer'a refactor)

```java
public NotificationDto queue(NotificationRequestDto req) {
    var saved = repo.save(...);  // PENDING
    rabbitTemplate.convertAndSend(
        "notifications",
        saved.getChannel().name().toLowerCase() + ".send",
        saved.getId()
    );
    return NotificationDto.fromEntity(saved);
}
```

### 4. Consumer

```java
@RabbitListener(queues = "notifications.email")
public void onEmail(Long notificationId) {
    deliver(notificationId);  // mevcut Sprint 25 deliver() metodu
}
```

### 5. SmsChannel + Provider Abstraction

```java
public interface SmsProvider {
    void sendSms(String to, String body) throws NotificationException;
}

@Component @ConditionalOnProperty(name = "notification.sms.provider", havingValue = "twilio")
public class TwilioSmsProvider implements SmsProvider { ... }

@Component @ConditionalOnProperty(name = "notification.sms.provider", havingValue = "netgsm")
public class NetgsmSmsProvider implements SmsProvider { ... }   // Sprint 27+
```

`sms_settings_screen` (Sprint 23) zaten provider seçimi sunuyor — Sprint 26 backend hookup.

### 6. DLQ + Retry

```java
@RabbitListener(queues = "notifications.dlq")
public void onDeadLetter(Long notificationId) {
    // Slack notify (mevcut SlackNotifier reuse) + alert
}
```

## Sprint 27: Frontend Hookup (2-3 gün)

### 1. `lib/services/notification_service.dart`

```dart
class NotificationService {
  final Dio dio;
  NotificationService(this.dio);

  Future<NotificationResult> send(NotificationRequest req) async {
    try {
      final res = await dio.post('/api/v1/notifications/send', data: req.toJson());
      return NotificationResult.success(NotificationDto.fromJson(res.data));
    } on DioException catch (e) {
      return NotificationResult.failure(e.message ?? 'Network error');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.read(dioProvider));
});
```

### 2. `email_settings_screen` + `sms_settings_screen` Real Save

Skeleton "Sprint 24+ ile aktif olacak" toast'ları → gerçek `POST /api/v1/notification-settings/...` endpoint çağrılarına çevir.

### 3. POS Sale Trigger

```dart
// pos_provider.dart submitSale() sonrası
if (settings.smsEnabled && customer?.phone != null) {
  ref.read(notificationServiceProvider).send(NotificationRequest(
    eventType: 'SALE_CREATED',
    channel: 'SMS',
    recipient: customer!.phone,
    body: t('notifications.sale_sms').replaceAll('{0}', sale.total),
  )).ignore();  // fire-and-forget; UI engellenmesin
}
```

### 4. Notification History Ekranı (opsiyonel)

`/settings/notifications/history` → `ListScreenTemplate<NotificationDto>` (status filtreli).

## Sprint 28: Production Hardening (3-4 gün)

1. **SendGrid** alternatif (deliverability) — `@ConditionalOnProperty` provider seçimi
2. **WhatsApp** — Twilio WhatsApp sandbox (production için meta business approval)
3. **Rate limiting** — `@Bucket4j` veya custom `RedisRateLimiter`
4. **Prometheus metrics** — `notification_sent_total{channel,status}`, `notification_retry_count`, `notification_dlq_total`
5. **Template engine** — DB-backed templates (Mustache veya Thymeleaf) + i18n (mevcut `ext_bundles` reuse)
6. **Testing**:
   - `NotificationServiceIntegrationTest` (H2)
   - `TwilioSmsProviderTest` (mock)
   - `RabbitMqIntegrationTest` (testcontainers)
7. **Credentials rotation** — Spring Cloud Config Server veya AWS Secrets Manager

## Riskler

| Risk | Etki | Mitigation |
|---|---|---|
| Twilio Türkiye SMS pahalı | Maliyet | Netgsm fallback (Sprint 27 provider seçimi) |
| RabbitMQ tek instance fail | Notification kaybı | DLQ + Slack alert + idempotency key |
| Rate limit aşımı | Provider banlar | Bucket4j + queue-level throttling |
| GDPR — kişisel veri (telefon/email) | Yasal | `notifications.body` retention policy (90 gün sonra anonimize) |
| Multi-tenant cross-leak | Ciddi | `companyCode` her query'de zorunlu (mevcut `SecurityContext` pattern) |

## Sprint 19 Kuralı Uygulaması

> *"Gerçek tüketici talebi olmadan template/feature inşa etme."*

| Bileşen | Talep var mı? | Yatırım Seviyesi |
|---|---|---|
| Email gönderim | ✅ (Sprint 5'ten beri) | L3 (real, mevcut) |
| SMS gönderim | ✅ (kullanıcı QUICK_START paylaştı) | L2 → L3 (Sprint 26) |
| WhatsApp | ⚠️ rehberde önerildi, gerçek kullanım belirsiz | L1 (Sprint 28 placeholder) |
| Push (FCM) | ❌ mobile build yok | L0 (eklemiyoruz) |
| Notification history UI | ⚠️ nice-to-have | Sprint 27 opsiyonel |

WhatsApp ve Push **kademeli** — gerçek kullanıcı senaryosu doğmadan tam yatırım yok.

## Verification (Sprint Sonu)

### Sprint 25 Sonu

- ✅ `POST /api/v1/notifications/send` çalışır
- ✅ Email kanalı: mevcut SMTP üzerinden gerçek mail gönderir (test ortam)
- ✅ Notification entity persist + status transition (PENDING → SENT/FAILED)
- ✅ @Async + @Retryable: 3 deneme, exponential backoff
- ✅ `flutter analyze` (0 yeni issue — backend değişiklik)

### Sprint 26 Sonu

- ✅ RabbitMQ kuyruğu çalışır (Docker compose ile)
- ✅ Twilio SMS gönderim test ortam
- ✅ DLQ + Slack alert

### Sprint 27 Sonu

- ✅ `NotificationService` Dart Riverpod provider
- ✅ POS sale → otomatik SMS (kullanıcı toggle ile)
- ✅ `email_settings` + `sms_settings` real save

### Sprint 28 Sonu

- ✅ SendGrid alternatif provider
- ✅ Rate limiting + Prometheus metrics
- ✅ Template engine + DB templates

## Karar Tablosu (Sentez Özeti)

| Soru | Karar |
|---|---|
| Twilio mu Netgsm mi? | Provider abstraction; Sprint 26 Twilio başlat (rehber takip), Sprint 27 Netgsm |
| RabbitMQ mu @Async mı? | Sprint 25 @Async (basit), Sprint 26 RabbitMQ |
| SendGrid mu mevcut SMTP mi? | Mevcut SMTP genişlet (EmailChannel); Sprint 28 SendGrid ekle |
| Yeni entity mi tek tablo mu? | Tek `notifications` tablosu, channel-discriminator (rehber paterni takip) |
| `companyCode` zorunlu mu? | EVET — multi-tenant kural |

## Sources

- [[sources/code-refs/2026-05-01-notifications-system-audit]] — bu sentezin temeli
- [`QUICK_START_NOTIFICATIONS.md`](QUICK_START_NOTIFICATIONS.md) — kullanıcı rehberi
- [[syntheses/integrations-hub-architecture]] — Sprint 23 hub mimarisi
- `pos-product-manager/src/main/java/com/sedcore/common/notification/EmailService.java` — mevcut SMTP

## Related

- [[log]] — Sprint 25-28 entries
- [[sources/code-refs/2026-05-01-printer-integrations-i18n-audit]] — Sprint 24 i18n cleanup (notification metinleri için bundle key zaten hazır)
