# Hızlı Başlangıç — SMS/Email/WhatsApp Entegrasyonu

_İlk 30 dakikada temel kurulum_

---

## 🎯 Hedef

Bu belgede, SEDCORE POS'un SMS/Email/WhatsApp özelliğini **minimum 30 dakika**da devreye almayı gösterecek.

---

## 📋 Ön Koşullar

- [ ] Spring Boot 3.x projesi (SEDCORE POS backend)
- [ ] PostgreSQL/MySQL database
- [ ] RabbitMQ (Docker'da da olabilir)
- [ ] Twilio hesabı (free trial + $15 credit)
- [ ] Flutter/Dart projesi (frontend)

---

## 🚀 Adım 1: Twilio Kurulumu (5 dakika)

### 1.1 Hesap Oluştur

1. [https://www.twilio.com/console](https://www.twilio.com/console)'a git
2. **Sign up** → Email, şifre
3. Telefon doğrula
4. Dashboard'da **Account SID** ve **Auth Token** kopyala

### 1.2 Telefon Numaraları Ayarla

1. **Phone Numbers** → **Buy a Number**
2. Country: Turkey (+90 seç)
3. Capabilities: SMS + WhatsApp
4. Satın al (~$1/ay)
5. Numarayı kopyala (örn: `+905551234567`)

### 1.3 WhatsApp Sandbox Etkinleştir

1. **Messaging** → **Try it out** → **Send a WhatsApp message**
2. Kendi telefonuna test mesaj gönder
3. Sandbox'u etkinleştir

---

## 🛠️ Adım 2: Backend Setup (15 dakika)

### 2.1 Dependencies Ekle (pom.xml)

```xml
<!-- pom.xml'e ekle -->
<dependency>
    <groupId>com.twilio.sdk</groupId>
    <artifactId>twilio</artifactId>
    <version>9.0.0</version>
</dependency>

<dependency>
    <groupId>com.sendgrid</groupId>
    <artifactId>sendgrid-java</artifactId>
    <version>4.8.3</version>
</dependency>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-amqp</artifactId>
</dependency>
```

Sonra: `mvn clean install`

### 2.2 Environment Variables Ayarla

```bash
# .env or system environment
export TWILIO_ACCOUNT_SID=ACxxxxxxxxxx
export TWILIO_AUTH_TOKEN=your_auth_token
export TWILIO_PHONE_NUMBER=+905551234567
export SENDGRID_API_KEY=SG.xxx...
export RABBITMQ_HOST=localhost
export RABBITMQ_PORT=5672
```

### 2.3 application.yml Güncelle

```yaml
spring:
  rabbitmq:
    host: ${RABBITMQ_HOST:localhost}
    port: ${RABBITMQ_PORT:5672}
    
notification:
  twilio:
    accountSid: ${TWILIO_ACCOUNT_SID}
    authToken: ${TWILIO_AUTH_TOKEN}
    fromPhone: ${TWILIO_PHONE_NUMBER}
  sendgrid:
    apiKey: ${SENDGRID_API_KEY}
    fromEmail: no-reply@sedcore.com
```

### 2.4 Entity & Repository Ekle

**Notification.java** (copy from integration guide):
```java
@Entity @Table(name = "notifications")
public class Notification {
    @Id @GeneratedValue private Long id;
    private String eventType;
    private String channel;    // SMS, EMAIL, WHATSAPP
    private String recipient;
    private String body;
    @Enumerated private NotificationStatus status = NotificationStatus.PENDING;
    // ... (bakınız full guide)
}
```

**NotificationRepository.java**:
```java
@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {
    List<Notification> findByStatus(NotificationStatus status);
}
```

### 2.5 Service Ekle

**TwilioService.java** + **SendGridService.java** (copy from integration guide)

### 2.6 Test Et

```bash
curl -X POST http://localhost:8080/api/v1/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "eventType": "TEST",
    "channel": "SMS",
    "recipient": "+905551234567",
    "body": "Test SMS from SEDCORE"
  }'
```

---

## 📱 Adım 3: Frontend Setup (10 dakika)

### 3.1 Notification Model Ekle

```dart
// lib/models/notification.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

@freezed
class NotificationRequest with _$NotificationRequest {
  factory NotificationRequest({
    required String eventType,
    required String channel,     // SMS, EMAIL, WHATSAPP
    required String recipient,
    required String body,
  }) = _NotificationRequest;

  factory NotificationRequest.fromJson(Map<String, dynamic> json) =>
      _$NotificationRequestFromJson(json);
}
```

### 3.2 Service Ekle

```dart
// lib/services/notification_service.dart
import 'package:dio/dio.dart';

class NotificationService {
  final Dio dio;
  
  NotificationService(this.dio);
  
  Future<void> sendNotification(NotificationRequest request) async {
    try {
      await dio.post(
        '/api/v1/notifications/send',
        data: request.toJson(),
      );
    } catch (e) {
      print('Notification send failed: $e');
    }
  }
}
```

### 3.3 Screen'de Kullan

```dart
// Satış tamamlandığında
void _completeSale() async {
  await saveSale(sale);
  
  // SMS gönder (async, UI'ı engellemiyor)
  notificationService.sendNotification(
    NotificationRequest(
      eventType: 'SALE_CREATED',
      channel: 'SMS',
      recipient: customer.phone,
      body: 'Satış tamamlandı. Toplam: ${sale.total} TL',
    ),
  ).ignore();
}
```

---

## ✅ Kontrol Listesi

- [ ] Twilio hesabı oluşturuldu
- [ ] Telefon numarası satın alındı
- [ ] Credentials environment'a eklendi
- [ ] pom.xml güncellendi
- [ ] Notification entity oluşturuldu
- [ ] TwilioService & SendGridService eklendi
- [ ] API endpoint test edildi
- [ ] Dart model oluşturuldu
- [ ] Frontend service eklendi
- [ ] Ilk test SMS/Email gönderildi ✓

---

## 🧪 Test SMS Gönder

```bash
# Backend test
curl -X POST http://localhost:8080/api/v1/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "eventType": "TEST",
    "channel": "SMS",
    "recipient": "+905551234567",
    "body": "SEDCORE Test SMS"
  }'

# Response:
# { "message": "Notification queued for sending" }
```

**Beklenen sonuç**: 10-15 saniye içinde telefonunuza SMS gelir.

---

## 🐛 Troubleshooting

### SMS gelmedi
- [ ] Twilio balance kontrol et (free trial'ı tüketti mi?)
- [ ] Telefon numarasının format'ı doğru mu? (`+905551234567`)
- [ ] RabbitMQ'nun bağlı olduğunu kontrol et: `http://localhost:15672`
- [ ] Logs kontrol et: `tail -f logs/app.log`

### Email gelmedi
- [ ] SendGrid API key doğru mu?
- [ ] From email, SendGrid'de verified mi?

### WhatsApp gelmedi
- [ ] Sandbox'u activate ettiyler mi?
- [ ] Twilio'dan kendi telefonuna test mesaj gönderdiyler mi?

---

## 📚 Sonraki Adımlar

1. **Templates Ekle**: Email templates DB'ye koy
2. **Rate Limiting**: Spamı önle
3. **Monitoring**: Prometheus metrics
4. **Testing**: Unit + Integration tests
5. **Production**: Credentials rotate, HA kurumu

---

## 📞 Destek

- Twilio Docs: https://www.twilio.com/docs
- SEDCORE Integration Guide: `SMS_EMAIL_WHATSAPP_INTEGRATION_GUIDE.md`

---

**Başarı!** 🎉  
30 dakikanın sonunda, SEDCORE POS'unuz SMS/Email/WhatsApp gönderebilir olacak.
