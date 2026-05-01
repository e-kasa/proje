# SMS/Email/WhatsApp — Troubleshooting Guide

Sık karşılaşılan sorunlar ve çözümleri.

---

## 🔴 SMS Gönderilmiyor

### Semptom
- API endpoint 202 Accepted dönüyor
- Ama telefona SMS gelmiyor
- Logs'ta error yok

### Olası Nedenleri

**1. Twilio Balance Yok**
```bash
# Check balance at https://www.twilio.com/console/account/billing
# Free trial: $15 credit
# Numbers require renewal
```

**Çözüm**: Credit ekle veya trial'ı renew et

---

**2. Telefon Numarası Format'ı Yanlış**
```javascript
// ❌ YANLIŞ
"+9051234567"    // 10 digit (eksik 90)
"05551234567"    // Country code yok
"+905551234567"  // Doğru, fakat tekrar kontrol et

// ✅ DOĞRU
"+905551234567"  // International format
```

**Çözüm**: `+ 90` ile başlayıp 12 digit olmalı

---

**3. Twilio Number Doğru Değil**
```java
// application.yml
notification.twilio.fromPhone: ${TWILIO_PHONE_NUMBER}
```

**Kontrol**:
```bash
echo $TWILIO_PHONE_NUMBER
# Should print: +905551234567
```

**Çözüm**: 
1. https://www.twilio.com/console/phone-numbers/incoming
2. Sahibi olduğun numarayı kopyala
3. `.env` veya environment'a ekle

---

**4. RabbitMQ Queue'ye Gelmedi**
```bash
# RabbitMQ Management UI
http://localhost:15672
# user: guest, password: guest
# Queues tab → notifications.queue kontrol et
```

**Kontrol**:
```bash
# Docker'da çalışıyor mu?
docker ps | grep rabbitmq
# Çıktı boşsa:
docker run -d --hostname my-rabbit --name some-rabbit rabbitmq:latest
```

**Çözüm**: RabbitMQ start et

---

**5. Twilio Credentials Yanlış**
```bash
# Test et
curl -X GET https://api.twilio.com/2010-04-01/Accounts/ACxxxxxxxxx \
  -u "ACxxxxxxxxx:auth_token_here"

# 401 Unauthorized = credentials yanlış
```

**Çözüm**:
1. https://www.twilio.com/console/ → Account SID + Token
2. `$TWILIO_ACCOUNT_SID` ve `$TWILIO_AUTH_TOKEN` kontrol et

---

### Debugging Steps

```bash
# 1. Check Spring Boot logs
tail -f logs/app.log | grep -i "notification\|twilio"

# 2. Check RabbitMQ queue size
# http://localhost:15672 → Queues → notifications.queue

# 3. Check Twilio API directly
curl -X POST https://api.twilio.com/2010-04-01/Accounts/ACxxxxx/Messages.json \
  -u "ACxxxxx:auth_token" \
  -d "From=+905551234567" \
  -d "To=+905559876543" \
  -d "Body=Test"

# 4. Check database
SELECT * FROM notifications ORDER BY created_at DESC LIMIT 5;
# status = ? (PENDING, SENT, FAILED)
# error_message = ? (if FAILED)
```

---

## 🔴 Email Gönderilmiyor

### Semptom
- API 202 dönüyor
- Email inbox'ta değil (spam da değil)
- Logs'ta SendGrid error yok

### Olası Nedenleri

**1. SendGrid API Key Yanlış**
```bash
# Test et
curl -X POST "https://api.sendgrid.com/v3/mail/send" \
  -H "Authorization: Bearer SG.xxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{"personalizations":[{"to":[{"email":"test@test.com"}]}]}'

# 401 = key yanlış
```

**Çözüm**:
1. https://app.sendgrid.com/settings/api_keys
2. Yeni API key oluştur
3. `.env`'ye ekle

---

**2. From Email Verified Değil**
```bash
# https://app.sendgrid.com/settings/sender_auth/senders
# "Sender Identity" listesinde from email var mı?
```

**Çözüm**:
1. SendGrid dashboard → Sender Verification
2. Email ekle ve verify et (link'i tıkla)
3. application.yml'de kullan

---

**3. Email Template HTML Kötü**
```html
<!-- ❌ Sorunlu -->
<h2>Title</h2>
<img src="/relative/path">  <!-- broken image -->

<!-- ✅ Düzgün -->
<h2 style="color: #333;">Title</h2>
<img src="https://cdn.example.com/image.png">
```

**Kontrol**: HTML validator → https://validator.w3.org/

---

**4. Sandbox Mode Açık**
```bash
# https://app.sendgrid.com/settings/sender_auth/domain/settings
# "Sandbox Mode" toggle
# ✓ OFF olmalı production'da
```

---

## 🔴 WhatsApp Gönderilmiyor

### Semptom
- `whatsapp:+9055512345` format'ı kullanıyor
- Twilio 400 Bad Request dönüyor

### Olası Nedenleri

**1. Sandbox Aktive Değil**
```bash
# Twilio Console → Messaging → WhatsApp Sandbox
# "Click here to activate" linki var mı?
# İlk kez SMS gönder:
# "join <keyword>"
```

**Çözüm**: Kendi telefonundan Twilio WhatsApp number'a (sandbox) message gönder

---

**2. Phone Number Format'ı Yanlış**
```java
// ❌ YANLIŞ
"5551234567"         // country code yok
"+1905551234567"     // +1 (US)

// ✅ DOĞRU
"+905551234567"      // Turkey
"whatsapp:+905551234567"  // Explicit format
```

---

**3. Receiver Telefon WhatsApp Yüklü Değil**
```bash
# WhatsApp test et:
# https://www.whatsapp.com/
# Telefon aktif ve WhatsApp yüklü mü kontrol et
```

---

## 🟡 Yavaş Gönderim

### Semptom
- SMS gelme süresi 30+ saniye
- Timeout hatası (rare)

### Olası Nedenleri

**1. Twilio API Yavaş**
```bash
# https://www.twilio.com/console/sms/logs
# Response times kontrol et
# Genelde network latency sebebi
```

**Çözüm**: Timeout'u artır (uygulama bazında, ama önemli değil — async zaten)

---

**2. Database Bottleneck**
```sql
-- Slow query log kontrol et
SHOW VARIABLES LIKE 'slow_query_log';

-- Index kontrol et
EXPLAIN SELECT * FROM notifications 
WHERE status = 'PENDING' AND retry_count < 3;
-- "Using index" görüntüsü olmalı
```

**Çözüm**: Index ekle (guide'da zaten var)

---

**3. RabbitMQ Queue Dolu**
```bash
# http://localhost:15672 → Queues
# Ready messages sayısı kontrol et
# Listener'ın işlediği hız

# Çözüm: Consumer'ı scale et
docker-compose scale notification-consumer=3
```

---

## 🟡 Yüksek SMS Maliyeti

### Semptom
- Fatura bekleneninden yüksek
- Spam SMS'ler gönderilmiş

### Olası Nedenleri

**1. Rate Limiting Kurulu Değil**
```java
// ❌ Hiç rate limiting yok
notificationService.sendNotification(request);

// ✅ Rate limiting var
if (rateLimiter.isAllowed(request.getRecipient())) {
    notificationService.sendNotification(request);
} else {
    return ResponseEntity.status(429).body("Rate limited");
}
```

**Çözüm**: Rate limiting implement et (guide'da var)

---

**2. Duplicate Messages**
```sql
-- Kontrol et
SELECT recipient, COUNT(*) as count 
FROM notifications 
WHERE created_at > DATE(NOW())
GROUP BY recipient 
HAVING count > 10;
```

**Çözüm**: Idempotency key implement et

---

**3. Test'ten Produksyon'a Geçiş**
```bash
# ❌ Test account credentials ile production'da test
TWILIO_ACCOUNT_SID=ACtest...  # Test account
TWILIO_PHONE_NUMBER=+1234567  # Test number

# ✅ Production account
TWILIO_ACCOUNT_SID=AClive...
TWILIO_PHONE_NUMBER=+905551234567
```

**Çözüm**: Production account ve number kontrol et

---

## 🟡 Failed Messages Artıyor

### Semptom
```sql
SELECT COUNT(*) FROM notifications WHERE status = 'FAILED';
-- 1000+ row çıkıyor
```

### Olası Nedenleri

**1. Retry Job Çalışmıyor**
```java
// ❌ @Scheduled method exception throw ediyor
@Scheduled(fixedDelay = 60000)
public void retryFailed() {
    // Exception → job stops
}

// ✅ Exception handle ediliyor
@Scheduled(fixedDelay = 60000)
public void retryFailed() {
    try {
        // retry logic
    } catch (Exception e) {
        log.error("Retry job failed", e);
        // continues next time
    }
}
```

**Kontrol**:
```bash
# Logs'ta "retryFailed" görüyor musun?
grep -i "retry" logs/app.log | tail -20
```

**Çözüm**: Retry job'ı debug et

---

**2. Max Retries Çok Düşük**
```yaml
# ❌ Sadece 1 retry
notification:
  retry:
    maxAttempts: 1

# ✅ 3 retry
notification:
  retry:
    maxAttempts: 3
```

**Çözüm**: Config'i kontrol et

---

**3. Provider API Outage**
```bash
# Twilio status:
https://status.twilio.com/

# SendGrid status:
https://www.sendgridstatus.com/
```

**Çözüm**: Outage bitene kadar bekle (auto-retry zamanında tekrar deneyecek)

---

## 🔵 Database Size Büyüyor

### Semptom
```bash
SELECT COUNT(*) FROM notifications;
-- 10 million+ rows
```

### Çözüm

**1. Eski Mesajları Sil**
```sql
-- 90 gün öncesini sil
DELETE FROM notifications 
WHERE created_at < DATE_SUB(NOW(), INTERVAL 90 DAY);

-- Vacuum table
VACUUM ANALYZE notifications;
```

**2. Archive Job Ekle**
```java
@Scheduled(cron = "0 0 2 * * *")  // 2 AM daily
public void archiveOldNotifications() {
    LocalDateTime ninetyDaysAgo = LocalDateTime.now().minusDays(90);
    List<Notification> old = notificationRepository
        .findByCreatedAtBefore(ninetyDaysAgo);
    
    // Move to archive table or S3
    archiveService.archive(old);
    notificationRepository.deleteAll(old);
}
```

---

## 🔵 Logs Çok Büyük

### Semptom
```bash
ls -lh logs/
# app.log: 5GB
```

### Çözüm

```yaml
# application.yml
logging:
  file:
    name: logs/app.log
    max-size: 100MB
    max-history: 30  # Keep 30 days
  pattern:
    file: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"
```

---

## 📊 Monitoring Checklist

Hergün kontrol et:

```bash
# 1. Failure rate
SELECT 
  COUNT(*) as failed_24h,
  ROUND(COUNT(*) / (SELECT COUNT(*) FROM notifications WHERE created_at > NOW() - INTERVAL 24 HOUR) * 100, 2) as failure_rate
FROM notifications 
WHERE status = 'FAILED' AND created_at > NOW() - INTERVAL 24 HOUR;

# 2. Average latency
SELECT 
  AVG(UNIX_TIMESTAMP(sent_at) - UNIX_TIMESTAMP(created_at)) as avg_latency_seconds
FROM notifications
WHERE status = 'SENT' AND sent_at IS NOT NULL;

# 3. Queue size
# http://localhost:15672 → Queues

# 4. API errors
grep "ERROR\|Exception" logs/app.log | tail -20
```

---

## 🆘 Emergency Contacts

- **Twilio Support**: https://www.twilio.com/help
- **SendGrid Support**: https://support.sendgrid.com/
- **RabbitMQ**: https://www.rabbitmq.com/support

---

## 📞 Internal Support

- **Backend Dev Lead**: [Name] - backend-issues@sedcore.com
- **DevOps**: [Name] - devops@sedcore.com
- **Product**: [Name] - product@sedcore.com

---

**Last Updated**: May 2026  
**Version**: 1.0
