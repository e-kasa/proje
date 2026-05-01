# SEDCORE POS — SMS • Email • WhatsApp Integration Guide

**Spring Boot + Dart/Flutter Implementation**  
_v1.0 — May 2026_

---

## İçindekiler

1. [Genel Bakış](#1-genel-bakış)
2. [Sistem Mimarisi](#2-sistem-mimarisi)
3. [Provider Karşılaştırması](#3-provider-karşılaştırması)
4. [Backend Implementation (Spring Boot)](#4-backend-implementation-spring-boot)
5. [Frontend Implementation (Dart/Flutter)](#5-frontend-implementation-dartflutter)
6. [Veritabanı Şeması](#6-veritabanı-şeması)
7. [Security & Best Practices](#7-security--best-practices)

---

## 1. Genel Bakış

SEDCORE POS'ta SMS, Email ve WhatsApp entegrasyonu, müşteri ve yönetim bildirimlerini otomatikleştirmek için kritik öneme sahiptir.

### Kullanım Durumları

- **Satış Onayı**: Müşteriye sipariş tamamlandığında otomatik bildiri
- **Ödeme Bildirimi**: Ödeme alındığında, bakiye özeti
- **Stok Uyarıları**: Stok düşük olduğunda yönetim notifikasyonu
- **Sistem Bildirimleri**: Önemli işlemler, satış raporları
- **Pazaryeri Senkronizasyonu**: Trendyol, Hepsiburada sipariş bildirimleri

### Temel İlkeler

- **Asenkron İşleme**: Bildiri gönderimi ana işlemi engellememelidir
- **Tekrar Denemeleri**: Başarısız gönderimler otomatik olarak yeniden denenmelidir
- **Audit Log**: Tüm gönderilen bildiriler kaydedilmelidir
- **Rate Limiting**: API kotalarını aşmamak için sınırlama
- **Çok-Kanal**: Kullanıcı tercihine göre SMS, Email veya WhatsApp seçimi

---

## 2. Sistem Mimarisi

Tipik bir event-driven mesajlaşma mimarisi:

```
┌─────────────────┐         ┌──────────────────┐         ┌──────────────┐
│  Spring Boot    │────────▶│  Message Queue   │────────▶│  Notification│
│  Event (Sale)   │         │  (RabbitMQ/Kafka)│         │  Service     │
└─────────────────┘         └──────────────────┘         └──────────────┘
                                                                │
                                ┌──────────────────────────────┼──────────────────────────┐
                                ▼                             ▼                         ▼
                        ┌──────────────┐        ┌──────────────┐        ┌──────────────┐
                        │ SMS Provider │        │    Email     │        │   WhatsApp   │
                        │  (Twilio)    │        │  (SendGrid)  │        │   (Twilio)   │
                        └──────────────┘        └──────────────┘        └──────────────┘
```

### Bileşenler

- **Event Publisher**: Spring Events yükseltir (`SaleCreatedEvent`, `PaymentReceivedEvent`, ...)
- **Message Queue**: RabbitMQ/Kafka'ya iletilir (optional ama recommended)
- **Notification Service**: Kanalları koordine eder ve Provider API'lerini çağırır
- **Provider SDKs**: Twilio, SendGrid vb. kütüphaneleri
- **Audit & Retry**: Veritabanında gönderim kayıtları ve otomatik tekrar mekanizması

---

## 3. Provider Karşılaştırması

| Provider | SMS | Email | WhatsApp |
|----------|-----|-------|----------|
| **Twilio** | ✓ | ✓ | ✓ |
| **SendGrid** | ✗ | ✓ | ✗ |
| **AWS SNS** | ✓ | ✗ | ✗ |
| **Mailgun** | ✗ | ✓ | ✗ |
| **Netgsm*** | ✓ | ✗ | ✗ |

*Türkiye'ye özel, daha uygun fiyatlı

### Twilio (Önerilen)

- **Avantajlar**: SMS + Email + WhatsApp tek API; güçlü dokümantasyon; webhook support
- **Fiyatlandırma**: SMS ~$0.0075/mesaj; WhatsApp ~$0.01/mesaj
- **Setup**: 5 dakika

### SendGrid + AWS SNS

- **Avantajlar**: Uygun fiyat; SendGrid ön-tasarlanmış template'ler sunuyor
- **Dezavantajlar**: Üçlü entegrasyon, birden fazla kütüphane

### Hybrid: Netgsm (Türkiye) + SendGrid

- **SMS**: Netgsm (uygun fiyat, yerel destek)
- **Email**: SendGrid

**Önerilen Seçim**: Twilio (başlangıç) → Netgsm + SendGrid (scale)

---

## 4. Backend Implementation (Spring Boot)

### Adım 1: Dependencies (Maven)

```xml
<!-- Twilio SDK -->
<dependency>
    <groupId>com.twilio.sdk</groupId>
    <artifactId>twilio</artifactId>
    <version>9.0.0</version>
</dependency>

<!-- SendGrid Email -->
<dependency>
    <groupId>com.sendgrid</groupId>
    <artifactId>sendgrid-java</artifactId>
    <version>4.8.3</version>
</dependency>

<!-- RabbitMQ (optional but recommended) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-amqp</artifactId>
</dependency>

<!-- Lombok (optional) -->
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <optional>true</optional>
</dependency>
```

### Adım 2: Configuration (application.yml)

```yaml
spring:
  rabbitmq:
    host: ${RABBITMQ_HOST:localhost}
    port: ${RABBITMQ_PORT:5672}
    username: ${RABBITMQ_USER:guest}
    password: ${RABBITMQ_PASSWORD:guest}
    virtual-host: /

notification:
  twilio:
    accountSid: ${TWILIO_ACCOUNT_SID}
    authToken: ${TWILIO_AUTH_TOKEN}
    fromPhone: ${TWILIO_PHONE_NUMBER:+1234567890}
    whatsappFrom: ${TWILIO_WHATSAPP_NUMBER:whatsapp:+1234567890}
  
  sendgrid:
    apiKey: ${SENDGRID_API_KEY}
    fromEmail: ${SENDGRID_FROM_EMAIL:no-reply@sedcore.com}
    fromName: "SEDCORE POS"
  
  netgsm:
    username: ${NETGSM_USERNAME}
    password: ${NETGSM_PASSWORD}
    sender: ${NETGSM_SENDER:SEDCORE}
  
  retry:
    maxAttempts: 3
    initialDelay: 1000  # 1 second
    multiplier: 5.0     # exponential backoff

logging:
  level:
    com.sedcore.notification: DEBUG
```

### Adım 3: Entity & Repository

```java
@Entity
@Table(name = "notifications", indexes = {
    @Index(name = "idx_status_retry_created", columnList = "status, retry_count, created_at"),
    @Index(name = "idx_event_type", columnList = "event_type")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Notification {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false)
    private String eventType;  // SALE_CREATED, PAYMENT_RECEIVED, STOCK_LOW, ...
    
    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private NotificationChannel channel;  // SMS, EMAIL, WHATSAPP
    
    @Column(nullable = false)
    private String recipient;  // phone number or email
    
    private String subject;  // for email
    
    @Column(nullable = false, columnDefinition = "TEXT")
    private String body;
    
    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private NotificationStatus status = NotificationStatus.PENDING;  // PENDING, SENT, FAILED
    
    @Column(name = "retry_count")
    private Integer retryCount = 0;
    
    @Column(name = "external_id")
    private String externalId;  // Twilio/SendGrid message ID
    
    @Column(columnDefinition = "TEXT")
    private String errorMessage;
    
    @CreationTimestamp
    private LocalDateTime createdAt;
    
    @UpdateTimestamp
    private LocalDateTime updatedAt;
    
    private LocalDateTime sentAt;
    
    @Version
    private Long version;  // for optimistic locking
}

public enum NotificationChannel {
    SMS, EMAIL, WHATSAPP
}

public enum NotificationStatus {
    PENDING, SENT, FAILED, BOUNCED
}
```

Repository:

```java
@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {
    
    List<Notification> findByStatusAndRetryCountLessThanAndCreatedAtAfter(
        NotificationStatus status, 
        Integer maxRetries, 
        LocalDateTime createdAfter
    );
    
    List<Notification> findByStatusOrderByCreatedAtAsc(NotificationStatus status);
    
    Long countByChannelAndStatusAndCreatedAtAfter(
        NotificationChannel channel,
        NotificationStatus status,
        LocalDateTime from
    );
}
```

### Adım 4: Services

**NotificationService.java** (Facade):

```java
@Service
@Slf4j
public class NotificationService {
    
    @Autowired
    private NotificationRepository notificationRepository;
    
    @Autowired
    private TwilioService twilioService;
    
    @Autowired
    private SendGridService sendGridService;
    
    @Autowired
    private RabbitTemplate rabbitTemplate;
    
    @Autowired
    @Qualifier("notificationTaskExecutor")
    private TaskExecutor taskExecutor;
    
    /**
     * Asynchronously send notification
     * Does NOT block the caller
     */
    public void sendNotification(NotificationRequest request) {
        Notification notification = new Notification();
        notification.setEventType(request.getEventType());
        notification.setChannel(request.getChannel());
        notification.setRecipient(request.getRecipient());
        notification.setSubject(request.getSubject());
        notification.setBody(request.getBody());
        notification.setStatus(NotificationStatus.PENDING);
        notification.setRetryCount(0);
        
        notificationRepository.save(notification);
        
        // Async send via RabbitMQ
        rabbitTemplate.convertAndSend("notifications.queue", notification);
        
        log.info("Notification queued: id={}, channel={}, recipient={}", 
            notification.getId(), request.getChannel(), request.getRecipient());
    }
    
    /**
     * Retry failed notifications (called by scheduled job)
     */
    @Scheduled(fixedDelay = 30000)  // 30 seconds
    public void retryFailedNotifications() {
        LocalDateTime thirtyMinutesAgo = LocalDateTime.now().minusMinutes(30);
        
        List<Notification> failed = notificationRepository
            .findByStatusAndRetryCountLessThanAndCreatedAtAfter(
                NotificationStatus.FAILED,
                3,
                thirtyMinutesAgo
            );
        
        for (Notification notif : failed) {
            log.info("Retrying notification: id={}", notif.getId());
            rabbitTemplate.convertAndSend("notifications.queue", notif);
        }
    }
    
    /**
     * Get notification delivery stats (for dashboard)
     */
    public NotificationStats getStats() {
        LocalDateTime last24Hours = LocalDateTime.now().minusHours(24);
        
        return NotificationStats.builder()
            .totalSms(notificationRepository.countByChannelAndStatusAndCreatedAtAfter(
                NotificationChannel.SMS, NotificationStatus.SENT, last24Hours))
            .totalEmail(notificationRepository.countByChannelAndStatusAndCreatedAtAfter(
                NotificationChannel.EMAIL, NotificationStatus.SENT, last24Hours))
            .totalWhatsapp(notificationRepository.countByChannelAndStatusAndCreatedAtAfter(
                NotificationChannel.WHATSAPP, NotificationStatus.SENT, last24Hours))
            .failedCount(notificationRepository.countByChannelAndStatusAndCreatedAtAfter(
                null, NotificationStatus.FAILED, last24Hours))
            .build();
    }
}
```

**TwilioService.java**:

```java
@Service
@Slf4j
public class TwilioService {
    
    @Value("${notification.twilio.accountSid}")
    private String accountSid;
    
    @Value("${notification.twilio.authToken}")
    private String authToken;
    
    @Value("${notification.twilio.fromPhone}")
    private String fromPhone;
    
    @Value("${notification.twilio.whatsappFrom}")
    private String whatsappFrom;
    
    @Autowired
    private NotificationRepository notificationRepository;
    
    @PostConstruct
    public void init() {
        Twilio.init(accountSid, authToken);
    }
    
    public void sendSms(Notification notification) {
        try {
            Message message = Message.creator(
                new PhoneNumber(notification.getRecipient()),  // To
                new PhoneNumber(fromPhone),                     // From
                notification.getBody()
            )
            .create();
            
            notification.setExternalId(message.getSid());
            notification.setStatus(NotificationStatus.SENT);
            notification.setSentAt(LocalDateTime.now());
            notificationRepository.save(notification);
            
            log.info("SMS sent: externalId={}, to={}", message.getSid(), notification.getRecipient());
            
        } catch (Exception e) {
            notification.setRetryCount(notification.getRetryCount() + 1);
            notification.setErrorMessage(e.getMessage());
            
            if (notification.getRetryCount() >= 3) {
                notification.setStatus(NotificationStatus.FAILED);
            }
            
            notificationRepository.save(notification);
            log.error("SMS failed: to={}, error={}", notification.getRecipient(), e.getMessage());
        }
    }
    
    public void sendWhatsapp(Notification notification) {
        try {
            Message message = Message.creator(
                new PhoneNumber("whatsapp:" + notification.getRecipient()),  // To
                new PhoneNumber(whatsappFrom),                               // From
                notification.getBody()
            )
            .create();
            
            notification.setExternalId(message.getSid());
            notification.setStatus(NotificationStatus.SENT);
            notification.setSentAt(LocalDateTime.now());
            notificationRepository.save(notification);
            
            log.info("WhatsApp sent: externalId={}, to={}", message.getSid(), notification.getRecipient());
            
        } catch (Exception e) {
            notification.setRetryCount(notification.getRetryCount() + 1);
            notification.setErrorMessage(e.getMessage());
            
            if (notification.getRetryCount() >= 3) {
                notification.setStatus(NotificationStatus.FAILED);
            }
            
            notificationRepository.save(notification);
            log.error("WhatsApp failed: to={}, error={}", notification.getRecipient(), e.getMessage());
        }
    }
}
```

**SendGridService.java**:

```java
@Service
@Slf4j
public class SendGridService {
    
    @Value("${notification.sendgrid.apiKey}")
    private String apiKey;
    
    @Value("${notification.sendgrid.fromEmail}")
    private String fromEmail;
    
    @Value("${notification.sendgrid.fromName}")
    private String fromName;
    
    @Autowired
    private NotificationRepository notificationRepository;
    
    public void sendEmail(Notification notification) {
        try {
            Email from = new Email(fromEmail, fromName);
            Email to = new Email(notification.getRecipient());
            Content content = new Content("text/html", notification.getBody());
            Mail mail = new Mail(from, notification.getSubject(), to, content);
            
            SendGrid sg = new SendGrid(apiKey);
            Request request = new Request();
            request.setMethod(Method.POST);
            request.setEndpoint("mail/send");
            request.setBody(mail.build());
            Response response = sg.api(request);
            
            if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
                notification.setStatus(NotificationStatus.SENT);
                notification.setSentAt(LocalDateTime.now());
                notificationRepository.save(notification);
                
                log.info("Email sent: to={}, subject={}", notification.getRecipient(), notification.getSubject());
            } else {
                throw new Exception("SendGrid API error: " + response.getStatusCode());
            }
            
        } catch (Exception e) {
            notification.setRetryCount(notification.getRetryCount() + 1);
            notification.setErrorMessage(e.getMessage());
            
            if (notification.getRetryCount() >= 3) {
                notification.setStatus(NotificationStatus.FAILED);
            }
            
            notificationRepository.save(notification);
            log.error("Email failed: to={}, error={}", notification.getRecipient(), e.getMessage());
        }
    }
}
```

### Adım 5: Message Queue Listener

```java
@Configuration
public class RabbitMQConfig {
    
    public static final String NOTIFICATIONS_QUEUE = "notifications.queue";
    public static final String NOTIFICATIONS_EXCHANGE = "notifications.exchange";
    public static final String NOTIFICATIONS_ROUTING_KEY = "notification.*";
    
    @Bean
    public Queue notificationsQueue() {
        return new Queue(NOTIFICATIONS_QUEUE, true, false, false,
            Map.of("x-max-length", 100000));  // Keep last 100k messages
    }
    
    @Bean
    public DirectExchange notificationsExchange() {
        return new DirectExchange(NOTIFICATIONS_EXCHANGE, true, false);
    }
    
    @Bean
    public Binding notificationsBinding(Queue queue, DirectExchange exchange) {
        return BindingBuilder.bind(queue)
            .to(exchange)
            .with(NOTIFICATIONS_ROUTING_KEY);
    }
}

@Component
@Slf4j
public class NotificationMessageListener {
    
    @Autowired
    private TwilioService twilioService;
    
    @Autowired
    private SendGridService sendGridService;
    
    @RabbitListener(queues = "notifications.queue")
    public void handleNotification(Notification notification) {
        log.info("Processing notification: id={}, channel={}", notification.getId(), notification.getChannel());
        
        switch (notification.getChannel()) {
            case SMS:
                twilioService.sendSms(notification);
                break;
            case EMAIL:
                sendGridService.sendEmail(notification);
                break;
            case WHATSAPP:
                twilioService.sendWhatsapp(notification);
                break;
            default:
                log.warn("Unknown channel: {}", notification.getChannel());
        }
    }
}
```

### Adım 6: API Endpoint

```java
@RestController
@RequestMapping("/api/v1/notifications")
@Slf4j
public class NotificationController {
    
    @Autowired
    private NotificationService notificationService;
    
    @PostMapping("/send")
    public ResponseEntity<NotificationResponse> sendNotification(
        @Valid @RequestBody NotificationRequest request
    ) {
        notificationService.sendNotification(request);
        
        return ResponseEntity.accepted()
            .body(NotificationResponse.builder()
                .message("Notification queued for sending")
                .build());
    }
    
    @GetMapping("/stats")
    public ResponseEntity<NotificationStats> getStats() {
        return ResponseEntity.ok(notificationService.getStats());
    }
}
```

---

## 5. Frontend Implementation (Dart/Flutter)

### Adım 1: Notification API Contract

```dart
// models/notification.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

@freezed
class NotificationRequest with _$NotificationRequest {
  factory NotificationRequest({
    required String eventType,      // SALE_CREATED, PAYMENT_RECEIVED, ...
    required String channel,        // SMS, EMAIL, WHATSAPP
    required String recipient,      // phone or email
    required String body,
    String? subject,                // for email
  }) = _NotificationRequest;

  factory NotificationRequest.fromJson(Map<String, dynamic> json) =>
      _$NotificationRequestFromJson(json);
}
```

### Adım 2: Notification Service (Riverpod)

```dart
// services/notification_service.dart
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final notificationServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationService(dio);
});

class NotificationService {
  final Dio _dio;
  
  NotificationService(this._dio);
  
  Future<void> sendNotification(NotificationRequest request) async {
    try {
      await _dio.post(
        '/api/v1/notifications/send',
        data: request.toJson(),
      );
    } catch (e) {
      print('Failed to send notification: $e');
      // Don't rethrow - notifications are non-critical
    }
  }
}
```

### Adım 3: Usage in Screens

```dart
// screens/sale_screen.dart
void _completeSale(Sale sale, WidgetRef ref) async {
  // Save sale to database
  await _saveSale(sale);
  
  // Send SMS notification (async, doesn't block UI)
  if (sale.customer.phoneNumber != null) {
    ref.read(notificationServiceProvider).sendNotification(
      NotificationRequest(
        eventType: 'SALE_CREATED',
        channel: 'SMS',
        recipient: sale.customer.phoneNumber!,
        body: 'Satış ${sale.id} tamamlandı. Toplam: ${sale.total} TL',
      ),
    ).ignore();  // Fire and forget
  }
  
  // Show success message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Satış kaydedildi')),
  );
}
```

---

## 6. Veritabanı Şeması

```sql
-- Notifications table
CREATE TABLE notifications (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    event_type VARCHAR(50) NOT NULL,
    channel VARCHAR(20) NOT NULL,
    recipient VARCHAR(255) NOT NULL,
    subject VARCHAR(255),
    body TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    retry_count INT NOT NULL DEFAULT 0,
    external_id VARCHAR(255),
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    sent_at TIMESTAMP NULL,
    version BIGINT DEFAULT 0,
    
    INDEX idx_status_retry_created (status, retry_count, created_at),
    INDEX idx_event_type (event_type),
    INDEX idx_recipient (recipient)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Notification templates for easy customization
CREATE TABLE notification_templates (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    event_type VARCHAR(50) NOT NULL UNIQUE,
    sms_template TEXT,
    email_subject VARCHAR(255),
    email_template TEXT,
    whatsapp_template TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_event_type (event_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Sample templates
INSERT INTO notification_templates (event_type, sms_template, email_subject, email_template) VALUES
('SALE_CREATED', 
 'Satış tamamlandı. Sipariş: {orderId}, Toplam: {total} TL',
 'Satış Onayınız',
 '<h2>Satış Onayı</h2><p>Sipariş #{orderId}</p><p>Toplam: {total} TL</p>'),

('PAYMENT_RECEIVED',
 'Ödeme alındı. Tutar: {amount} TL, Bakiye: {balance} TL',
 'Ödeme Onayı',
 '<h2>Ödeme Alındı</h2><p>Tutar: {amount} TL</p><p>Yeni Bakiye: {balance} TL</p>'),

('STOCK_LOW',
 'Uyarı: {productName} stoğu azalıyor. Mevcut: {quantity}',
 'Stok Uyarısı',
 '<h2>Stok Uyarısı</h2><p>Ürün: {productName}</p><p>Mevcut Stok: {quantity}</p>');
```

---

## 7. Security & Best Practices

### 1. Credentials Management

❌ **Yapma**:
```yaml
twilio:
  accountSid: AC1234567890abcdef
  authToken: very_secret_token
```

✅ **Yap**:
```bash
export TWILIO_ACCOUNT_SID=AC1234567890abcdef
export TWILIO_AUTH_TOKEN=very_secret_token
```

```yaml
notification:
  twilio:
    accountSid: ${TWILIO_ACCOUNT_SID}
    authToken: ${TWILIO_AUTH_TOKEN}
```

**Alternatif: Spring Vault**
```java
@Configuration
public class VaultConfig {
    @Bean
    public VaultTemplate vaultTemplate(VaultOperations vaultOperations) {
        return new VaultTemplate(vaultOperations);
    }
}
```

### 2. Rate Limiting

```java
@Component
public class NotificationRateLimiter {
    
    private final Map<String, LocalDateTime> lastSentMap = new ConcurrentHashMap<>();
    
    public boolean canSend(String recipient, NotificationChannel channel) {
        String key = recipient + ":" + channel;
        LocalDateTime lastSent = lastSentMap.get(key);
        
        if (lastSent == null) {
            lastSentMap.put(key, LocalDateTime.now());
            return true;
        }
        
        if (Duration.between(lastSent, LocalDateTime.now()).getSeconds() < 60) {
            return false;  // Rate limited
        }
        
        lastSentMap.put(key, LocalDateTime.now());
        return true;
    }
}
```

### 3. Retry Logic

```java
@Configuration
public class RetryConfig {
    
    @Bean
    public RetryTemplate retryTemplate() {
        RetryTemplate template = new RetryTemplate();
        
        ExponentialBackOffPolicy backOff = new ExponentialBackOffPolicy();
        backOff.setInitialInterval(1000);        // 1 second
        backOff.setMultiplier(5.0);              // 1s, 5s, 25s
        backOff.setMaxInterval(60000);           // max 60 seconds
        template.setBackOffPolicy(backOff);
        
        SimpleRetryPolicy policy = new SimpleRetryPolicy();
        policy.setMaxAttempts(3);
        template.setRetryPolicy(policy);
        
        return template;
    }
}
```

### 4. Idempotency

Aynı notification iki kez gönderilmemesi için:

```java
@Service
public class NotificationIdempotencyService {
    
    @Autowired
    private IdempotencyKeyRepository idempotencyKeyRepository;
    
    public boolean isIdempotent(String key) {
        if (idempotencyKeyRepository.existsById(key)) {
            return false;  // Already processed
        }
        
        idempotencyKeyRepository.save(new IdempotencyKey(key));
        return true;  // First time
    }
}
```

### 5. Monitoring & Alerting

```java
@Component
@Slf4j
public class NotificationMetrics {
    
    private final MeterRegistry meterRegistry;
    
    @Autowired
    public NotificationMetrics(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
    }
    
    public void recordSent(NotificationChannel channel) {
        meterRegistry.counter("notification.sent", "channel", channel.toString()).increment();
    }
    
    public void recordFailed(NotificationChannel channel) {
        meterRegistry.counter("notification.failed", "channel", channel.toString()).increment();
    }
    
    public void recordLatency(long millis, NotificationChannel channel) {
        meterRegistry.timer("notification.latency", "channel", channel.toString())
            .record(Duration.ofMillis(millis));
    }
}
```

Prometheus dashboard'unuzda uyarı kurun:
```
alert: HighNotificationFailureRate
expr: rate(notification_failed_total[5m]) / rate(notification_sent_total[5m]) > 0.1
```

### 6. Testing

**Unit Test**:
```java
@SpringBootTest
public class NotificationServiceTest {
    
    @Autowired
    private NotificationService notificationService;
    
    @MockBean
    private TwilioService twilioService;
    
    @Test
    public void testSendSmsNotification() {
        NotificationRequest request = NotificationRequest.builder()
            .eventType("SALE_CREATED")
            .channel(NotificationChannel.SMS)
            .recipient("+905551234567")
            .body("Test message")
            .build();
        
        notificationService.sendNotification(request);
        
        // Verify async processing
        Thread.sleep(1000);
    }
}
```

**Integration Test (with Testcontainers)**:
```java
@SpringBootTest
@Testcontainers
public class NotificationIntegrationTest {
    
    @Container
    static RabbitMQContainer rabbitmq = new RabbitMQContainer("rabbitmq:3.11");
    
    @Test
    public void testNotificationFlow() {
        // Send notification
        // Assert it was processed
    }
}
```

---

## Deployment Checklist

- [ ] Environment variables set in production
- [ ] RabbitMQ cluster configured with HA
- [ ] Database backups enabled
- [ ] Monitoring & alerting configured
- [ ] Rate limiting active
- [ ] Retry logic tested
- [ ] Notification logs retained for 90 days
- [ ] API keys rotated every 3 months
- [ ] Staging environment test completed

---

## Resources

- [Twilio Docs](https://www.twilio.com/docs)
- [SendGrid Docs](https://docs.sendgrid.com)
- [Spring Boot RabbitMQ](https://spring.io/guides/gs/messaging-rabbitmq)
- [Dart Freezed](https://pub.dev/packages/freezed)
- [Riverpod Documentation](https://riverpod.dev)

---

**Oluşturan**: SEDCORE Dev Team  
**Son Güncelleme**: May 2026  
**Versiyon**: 1.0
