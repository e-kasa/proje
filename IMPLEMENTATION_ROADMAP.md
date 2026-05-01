# SMS/Email/WhatsApp — Implementation Roadmap

**Durum**: Planning  
**Başlama**: May 2026  
**Hedef Bitiş**: June 2026  

---

## 📊 Timeline Overview

```
Week 1: Backend Setup + Twilio Integration
├─ Days 1-2: Environment & Dependencies
├─ Days 3-4: Entity & Service Implementation
└─ Days 5: Basic Testing

Week 2: Message Queue & Retry Logic
├─ Days 1-2: RabbitMQ Config
├─ Days 3-4: Retry Mechanism
└─ Days 5: Performance Testing

Week 3: Frontend Integration
├─ Days 1-2: Dart Models & Services
├─ Days 3-4: UI Integration
└─ Days 5: E2E Testing

Week 4: Production Hardening
├─ Days 1-2: Rate Limiting
├─ Days 3: Monitoring & Alerting
├─ Days 4: Security Review
└─ Days 5: Staging Deployment
```

---

## Phase 1: Backend Foundation (Days 1-5)

### Task 1.1: Setup & Configuration ✓
- [ ] Maven dependencies eklendi
- [ ] application.yml konfigüre edildi
- [ ] Environment variables ayarlandı
- [ ] RabbitMQ docker compose UP
- [ ] PostgreSQL/MySQL ready

**Bitiş Kriteri**: `./mvn spring-boot:run` hatasız çalışır

**Referans**: `QUICK_START_NOTIFICATIONS.md` Adım 2

---

### Task 1.2: Database & Entities
- [ ] `notifications` table migrated
- [ ] `notification_templates` table created
- [ ] `Notification.java` entity yazıldı
- [ ] `NotificationRepository` interface yazıldı
- [ ] Indexes optimize edildi

**SQL Script**:
```sql
-- run_migrations.sql
CREATE TABLE notifications (...)  -- see SMS_EMAIL_WHATSAPP_INTEGRATION_GUIDE.md
CREATE TABLE notification_templates (...)
```

**Bitiş Kriteri**: `NotificationRepository` kullanılarak CRUD işlemleri yapılabiliyor

---

### Task 1.3: Twilio Service Implementation
- [ ] `TwilioService.java` yazıldı
- [ ] SMS gönderimi test edildi
- [ ] WhatsApp gönderimi test edildi
- [ ] Error handling eklendi
- [ ] Retry logic basic versiyonu

**Test Commands**:
```bash
curl -X POST http://localhost:8080/test/send-sms \
  -d "phone=+905551234567&message=Test"

# Expected: SMS received in 10-15 seconds
```

**Bitiş Kriteri**: Gerçek SMS ve WhatsApp test edildi

---

### Task 1.4: SendGrid Email Service
- [ ] `SendGridService.java` yazıldı
- [ ] Email gönderimi test edildi
- [ ] HTML templates hazır
- [ ] Error handling eklendi

**Bitiş Kriteri**: Test email alındı

---

### Task 1.5: Basic API Endpoints
- [ ] `NotificationController` yazıldı
- [ ] `POST /api/v1/notifications/send` endpoint
- [ ] Request validation
- [ ] Response handling

```java
@PostMapping("/send")
public ResponseEntity<?> sendNotification(
    @Valid @RequestBody NotificationRequest request) {
    // Implementation
}
```

**Bitiş Kriteri**: Curl ile test edildi, 202 Accepted dönüyor

---

## Phase 2: Message Queue & Reliability (Days 6-10)

### Task 2.1: RabbitMQ Configuration ✓
- [ ] Queue'ler tanımlandı
- [ ] Exchange'ler tanımlandı
- [ ] Bindings kuruldu
- [ ] DLQ (Dead Letter Queue) eklendi

**Configuration**:
```java
@Configuration
public class RabbitMQConfig {
    public static final String NOTIFICATIONS_QUEUE = "notifications.queue";
    public static final String NOTIFICATIONS_DLQ = "notifications.dlq";
    // ... (see SMS_EMAIL_WHATSAPP_INTEGRATION_GUIDE.md)
}
```

**Bitiş Kriteri**: RabbitMQ Management (http://localhost:15672) kuyruğu gösteriyor

---

### Task 2.2: Message Listener Implementation
- [ ] `NotificationMessageListener` yazıldı
- [ ] `@RabbitListener` annotation
- [ ] Channel dispatch logic
- [ ] Error handling

```java
@RabbitListener(queues = "notifications.queue")
public void handleNotification(Notification notification) {
    // Route to appropriate service
}
```

**Bitiş Kriteri**: Kuyruğa mesaj gönderince listener işliyor

---

### Task 2.3: Retry Logic & Exponential Backoff
- [ ] Retry entity alanları eklendi (retry_count, status)
- [ ] `@Retryable` annotation ile retry
- [ ] Exponential backoff policy
- [ ] Max retry attempts (3)
- [ ] Failed notification status

**Adımlar**:
1. İlk denemede başarısız → retry_count: 1, status: PENDING
2. 5 saniye sonra tekrar → retry_count: 2
3. 25 saniye sonra tekrar → retry_count: 3
4. Hala başarısız → status: FAILED

**Bitiş Kriteri**: Başarısız gönderim otomatik 3 kez deneniyor

---

### Task 2.4: Scheduled Job for Retry
- [ ] `@Scheduled` method yazıldı
- [ ] Fail eden mesajları bulk retry
- [ ] Old message cleanup job (30 gün)
- [ ] Metrics collection

```java
@Scheduled(fixedDelay = 60000)  // 1 minute
public void retryFailedNotifications() {
    // Find FAILED messages with retry_count < 3
    // Push back to queue
}

@Scheduled(cron = "0 0 2 * * *")  // 2 AM daily
public void cleanupOldNotifications() {
    // Delete notifications older than 90 days
}
```

**Bitiş Kriteri**: Eski mesajlar otomatik siliniyor

---

### Task 2.5: Audit Log & Monitoring
- [ ] Tüm gönderilen mesajlar loglanıyor
- [ ] Status tracking (PENDING → SENT/FAILED)
- [ ] Error messages kaydediliyor
- [ ] External ID (Twilio/SendGrid message ID) kaydediliyor

```sql
SELECT COUNT(*) as sent_today FROM notifications 
WHERE status = 'SENT' AND created_at > DATE(NOW());

SELECT COUNT(*) as failed_today FROM notifications 
WHERE status = 'FAILED' AND created_at > DATE(NOW());
```

**Bitiş Kriteri**: Dashboard mesaj istatistiklerini gösteriyor

---

## Phase 3: Frontend Integration (Days 11-15)

### Task 3.1: Dart Model Generation
- [ ] `NotificationRequest` model yazıldı
- [ ] `freezed` + `json_serializable` setup
- [ ] Model test edildi

```bash
flutter pub run build_runner build
```

**Bitiş Kriteri**: `.freezed.dart` ve `.g.dart` dosyaları generate oldu

---

### Task 3.2: Notification Service (Riverpod)
- [ ] `NotificationService` class'ı yazıldı
- [ ] Dio integration
- [ ] Error handling (non-critical)
- [ ] Timeout ayarları

```dart
final notificationServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationService(dio);
});
```

**Bitiş Kriteri**: Service test edildi, mock Dio ile çalışıyor

---

### Task 3.3: Screen Integration
- [ ] Sales screen: satış tamamlandığında SMS gönder
- [ ] Payments screen: ödeme alındığında email gönder
- [ ] Admin panel: stok uyarıları
- [ ] Settings: notification preferences

**Örnekler**:
```dart
// Sales screen'de
void _completeSale(Sale sale) async {
  await _saveSale(sale);
  
  ref.read(notificationServiceProvider).sendNotification(
    NotificationRequest(
      eventType: 'SALE_CREATED',
      channel: 'SMS',
      recipient: sale.customer.phone,
      body: 'Satış tamamlandı...',
    ),
  ).ignore();  // Non-blocking
}
```

**Bitiş Kriteri**: Gerçek satış yapınca SMS/email gidiyor

---

### Task 3.4: Notification Preferences UI
- [ ] Customer notification preferences ayarları
- [ ] Channel seçimi (SMS, Email, WhatsApp)
- [ ] Frequency settings (immediately, daily digest)
- [ ] Unsubscribe option

**DB Schema**:
```sql
CREATE TABLE customer_notification_preferences (
    id BIGINT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    channel VARCHAR(20),  -- SMS, EMAIL, WHATSAPP
    enabled BOOLEAN DEFAULT TRUE,
    frequency VARCHAR(20),  -- IMMEDIATE, DAILY, WEEKLY
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);
```

**Bitiş Kriteri**: Müşteri tercihlerine göre kanal seçilip gönderiliyor

---

## Phase 4: Production Hardening (Days 16-20)

### Task 4.1: Rate Limiting
- [ ] Per-customer SMS limit (5/day)
- [ ] Per-email limit (10/minute)
- [ ] Global rate limiting
- [ ] Bucket4j integration

```java
@Component
public class NotificationRateLimiter {
    private final Bucket bucket = Bucket4j
        .builder()
        .addLimit(Limit.of(100, Refill.intervally(100, Duration.ofMinutes(1))))
        .build();
    
    public boolean isAllowed() {
        return bucket.tryConsume(1);
    }
}
```

**Bitiş Kriteri**: Test'te rate limit aşıldığında 429 Too Many Requests dönüyor

---

### Task 4.2: Monitoring & Alerting
- [ ] Prometheus metrics eklendi
- [ ] Grafana dashboard kuruldu
- [ ] Alert rules tanımlandı
- [ ] Slack/email notifications

**Metrics**:
```
notification_sent_total{channel="SMS"}
notification_failed_total{channel="SMS"}
notification_latency_seconds{channel="SMS"}
notification_queue_size
```

**Alert Examples**:
```yaml
- alert: HighNotificationFailureRate
  expr: rate(notification_failed_total[5m]) / rate(notification_sent_total[5m]) > 0.1
  annotations:
    summary: "Notification failure rate > 10%"
```

**Bitiş Kriteri**: Dashboard canlı metrikler gösteriyor

---

### Task 4.3: Security Hardening
- [ ] API keys environment'a taşındı (no hardcoding)
- [ ] Spring Vault setup (optional)
- [ ] HTTPS enforced
- [ ] Request validation
- [ ] Sensitive data not logged

**Checklist**:
- [ ] Twilio credentials never in git
- [ ] SendGrid API key in .env
- [ ] Database passwords in vault
- [ ] Logs don't contain phone numbers or emails (masked)

**Bitiş Kriteri**: Security scan (OWASP) geçiyor

---

### Task 4.4: Testing
- [ ] Unit tests (Services, Entities)
- [ ] Integration tests (with Testcontainers)
- [ ] E2E tests (Staging ortamında real SMS/Email)
- [ ] Load testing (1000 concurrent notifications)

```bash
# Run tests
mvn test
mvn verify  # with integration tests

# Load test
curl -X POST http://localhost:8080/api/v1/notifications/send \
  --parallel 100 \
  --repeat 10 \
  [payload]
```

**Bitiş Kriteri**: Tüm testler geçiyor, code coverage > 80%

---

### Task 4.5: Documentation & Knowledge Transfer
- [ ] Runbook hazırlandı (production deployment)
- [ ] Troubleshooting guide yazıldı
- [ ] Team training yapıldı
- [ ] API docs (Swagger) güncellenip

**Dosyalar**:
- [x] `SMS_EMAIL_WHATSAPP_INTEGRATION_GUIDE.md` (technical deep dive)
- [x] `QUICK_START_NOTIFICATIONS.md` (30-min setup)
- [ ] `DEPLOYMENT_RUNBOOK.md` (production steps)
- [ ] `TROUBLESHOOTING.md` (common issues)

**Bitiş Kriteri**: Yeni developer 2 saatte sistemi setup edebiliyor

---

## Phase 5: Go-Live & Post-Launch (Days 21+)

### Task 5.1: Staging Deployment
- [ ] Staging ortamına deploy
- [ ] Real Twilio account with test balance
- [ ] Real SendGrid test

---

### Task 5.2: Production Deployment
- [ ] Production credentials setup
- [ ] Database migration
- [ ] Canary deployment (10% traffic)
- [ ] Monitoring active

---

### Task 5.3: Post-Launch Monitoring (Week 1)
- [ ] Failure rate monitoring
- [ ] Latency checks
- [ ] Customer feedback
- [ ] Bug fixes

---

## 📈 Success Metrics

| Metrik | Target | Current |
|--------|--------|---------|
| SMS Delivery Rate | > 99% | - |
| Email Delivery Rate | > 95% | - |
| Avg Latency | < 30s | - |
| Failed Message Retry Success | > 90% | - |
| System Availability | > 99.9% | - |

---

## 🚨 Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Twilio API outage | Low | High | AWS SNS as fallback |
| Message queue overload | Medium | Medium | Auto-scaling RabbitMQ |
| High SMS costs | Medium | High | Rate limiting + budget alerts |
| Data privacy violation | Low | Critical | Encrypt logs, mask PII |

---

## 📚 References

- **Integration Guide**: `SMS_EMAIL_WHATSAPP_INTEGRATION_GUIDE.md`
- **Quick Start**: `QUICK_START_NOTIFICATIONS.md`
- **Twilio Docs**: https://www.twilio.com/docs
- **RabbitMQ Docs**: https://www.rabbitmq.com/documentation.html

---

**Project Manager**: [Name]  
**Tech Lead**: [Name]  
**Created**: May 2026
