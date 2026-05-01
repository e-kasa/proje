---
title: Sprint 26 Notifications — A/B Bölünme Kararı (2026-05-01)
tags: [audit, decision, notifications, sms, twilio, rabbitmq, sprint-26]
source: Sprint 25 NotificationService + QUICK_START_NOTIFICATIONS.md + audit
date: 2026-05-01
status: verified
---

# Sprint 26 Notifications — A/B Bölünme Kararı

Sprint 25 backend foundation tamamlandı (10 Java dosya, EMAIL real). Sprint 26 sentezde tek blok olarak planlandı (RabbitMQ + Twilio). **Kullanıcı henüz Twilio credentials sağlamadı + RabbitMQ Docker kurulu değil.** Sprint 26 iki alt-sprint'e bölündü.

## Tetikleyici

Kullanıcı, 2026-05-01: *"DEVAM"* — Sprint 25 sonu, Sprint 26 başlatma.

Sprint 25 sonu sorduğum hazırlık girdileri (cevapsız):
1. Twilio hesabı ($15 trial) — Account SID + Auth Token + Phone Number?
2. RabbitMQ Docker compose dev ortam?
3. Türkiye SMS provider seçimi (Twilio/Netgsm/İletiMerkezi)?

## Karar: Sprint 26'yı 2 alt-sprint'e böl

### Sprint 26-A — Provider Abstraction + Twilio Hazırlık (bu sprint)

Credentials-bağımsız, config-driven. Twilio creds gelince **bir property toggle** ile aktive olur.

**Kapsam:**
- `pom.xml`: Twilio SDK eklenir
- `SmsProvider` interface (`com.sedcore.notification.service.channel.sms`)
- `TwilioSmsProvider` impl (`@ConditionalOnProperty(name = "notification.sms.provider", havingValue = "twilio")`)
- `NoopSmsProvider` impl (`@ConditionalOnProperty(...having = "noop", matchIfMissing = true)` — default)
- `SmsChannel` extends `NotificationChannelGateway` — `SmsProvider` kullanır
- `ChannelRouter`: SMS case → `smsChannel.send(n)` (UnsupportedException kaldırılır)
- `application.properties`: `notification.sms.provider=noop` (default), Twilio config placeholder

**Avantajlar:**
- Credentials beklerken iş ilerler
- `NoopSmsProvider` test/dev'de SMS request'lerini kaydeder ama göndermez (status=SENT, `metadata={"noop":true}`)
- Provider switch tek `application.properties` satırı (`=twilio`)
- Sprint 27'de Netgsm eklenirken sadece yeni provider class + bir conditional case

**Sprint 25 mimarisi korunur**: `@Async` deliver loop aynı; sadece `ChannelRouter` SMS'i artık dispatch ediyor.

### Sprint 26-B — RabbitMQ Refactor (sonraki sprint, kullanıcı RabbitMQ Docker'ı kurduğunda)

- `pom.xml`: `spring-boot-starter-amqp`
- RabbitMQ topology (exchange + 4 queue + DLQ)
- `NotificationService.queue()`: `@Async` direct call → `rabbitTemplate.convertAndSend(...)`
- `@RabbitListener` consumer, mevcut `deliverAsync` metodunu reuse eder
- DLQ + `SlackNotifier` alert
- Integration test (testcontainers RabbitMQ)

**Tetik koşulu:** Kullanıcı `docker-compose up rabbitmq` kurar + onay verir. O ana kadar Sprint 26-A in-memory @Async ile production-ready (tek instance senaryo için).

## Sprint 26-A Mimari Detay

### SmsProvider Interface

```java
public interface SmsProvider {
    /** Throws TransientNotificationException (5xx, network) veya
     *  PermanentNotificationException (4xx, invalid recipient).
     *  Returns provider message ID (Twilio messageSid, vb. — metadata için). */
    String sendSms(String to, String body);
}
```

### TwilioSmsProvider

```java
@Component
@ConditionalOnProperty(name = "notification.sms.provider", havingValue = "twilio")
public class TwilioSmsProvider implements SmsProvider {
    @Value("${notification.twilio.account-sid:}") private String accountSid;
    @Value("${notification.twilio.auth-token:}") private String authToken;
    @Value("${notification.twilio.from-phone:}") private String fromPhone;

    @PostConstruct
    void init() {
        if (accountSid.isBlank() || authToken.isBlank()) {
            throw new IllegalStateException(
                "notification.sms.provider=twilio ama credentials eksik");
        }
        Twilio.init(accountSid, authToken);
    }

    @Override
    public String sendSms(String to, String body) {
        try {
            Message msg = Message.creator(
                new PhoneNumber(to), new PhoneNumber(fromPhone), body
            ).create();
            return msg.getSid();
        } catch (ApiException e) {
            if (e.getStatusCode() / 100 == 4) {
                throw new PermanentNotificationException("Twilio 4xx: " + e.getMessage(), e);
            }
            throw new TransientNotificationException("Twilio 5xx/network: " + e.getMessage(), e);
        }
    }
}
```

### NoopSmsProvider (default — credentials yokken)

```java
@Component
@ConditionalOnProperty(name = "notification.sms.provider", havingValue = "noop", matchIfMissing = true)
public class NoopSmsProvider implements SmsProvider {
    private static final Logger log = LoggerFactory.getLogger(NoopSmsProvider.class);

    @Override
    public String sendSms(String to, String body) {
        log.info("[NOOP-SMS] to={}, body={}", to, body);
        return "noop-" + UUID.randomUUID();
    }
}
```

**Davranış:** Sprint 26-A başladığında SMS request'leri 202 Accepted dönecek, status=SENT, log'da görünür ama hiçbir gerçek SMS gönderilmez. UI test edilebilir, frontend hookup mümkün.

### SmsChannel

```java
@Component
@RequiredArgsConstructor
public class SmsChannel implements NotificationChannelGateway {
    private final SmsProvider smsProvider;

    @Override
    public void send(NotificationEntity n) {
        String providerMsgId = smsProvider.sendSms(n.getRecipient(), n.getBody());
        n.setMetadata("{\"providerMessageId\":\"" + providerMsgId + "\"}");
    }
}
```

### ChannelRouter Güncellemesi

```java
case SMS -> smsChannel.send(n);  // Sprint 26-A: artık unsupported değil
```

## Sources

- [[sources/code-refs/2026-05-01-notifications-system-audit]] — Sprint 25 audit
- [[syntheses/notifications-system-design]] — 4 sprint mimari sentez (Sprint 26 bölümü güncellenir)
- `pos-product-manager/src/main/java/com/sedcore/notification/` — Sprint 25 modülü

## Related

- [[log]] — Sprint 26-A entry
- Sprint 26-B kararı: RabbitMQ kurulumu sonrası ayrı audit + sentez güncellemesi
