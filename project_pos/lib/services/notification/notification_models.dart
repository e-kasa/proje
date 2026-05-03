// Sprint 27 — Notification feature için DTO + enum'lar.
//
// Backend karşılığı: `com.sedcore.notification.dto.{NotificationRequestDto,
// NotificationDto}` ve `com.sedcore.notification.entity.{NotificationChannel,
// NotificationStatus}`.

enum NotificationChannel {
  email('EMAIL'),
  sms('SMS'),
  whatsapp('WHATSAPP'),
  push('PUSH');

  final String apiValue;
  const NotificationChannel(this.apiValue);

  static NotificationChannel fromApi(String? raw) {
    if (raw == null) return NotificationChannel.email;
    return NotificationChannel.values.firstWhere(
      (c) => c.apiValue == raw,
      orElse: () => NotificationChannel.email,
    );
  }
}

enum NotificationStatus {
  pending('PENDING'),
  retrying('RETRYING'),
  sent('SENT'),
  failed('FAILED');

  final String apiValue;
  const NotificationStatus(this.apiValue);

  static NotificationStatus fromApi(String? raw) {
    if (raw == null) return NotificationStatus.pending;
    return NotificationStatus.values.firstWhere(
      (s) => s.apiValue == raw,
      orElse: () => NotificationStatus.pending,
    );
  }
}

/// POST /api/v1/notifications/send body.
class NotificationRequest {
  final String eventType;          // SALE_CREATED, PAYMENT_DUE, TEST, ...
  final NotificationChannel channel;
  final String recipient;          // E.164 phone (SMS/WhatsApp) veya email
  final String? subject;           // Email için
  final String body;
  final String? templateCode;

  const NotificationRequest({
    required this.eventType,
    required this.channel,
    required this.recipient,
    required this.body,
    this.subject,
    this.templateCode,
  });

  Map<String, dynamic> toJson() => {
        'eventType': eventType,
        'channel': channel.apiValue,
        'recipient': recipient,
        if (subject != null) 'subject': subject,
        'body': body,
        if (templateCode != null) 'templateCode': templateCode,
      };
}

/// Backend response — POST 202 Accepted veya GET liste item'ı.
class NotificationDto {
  final String id;
  final String eventType;
  final NotificationChannel channel;
  final String recipient;
  final String? subject;
  final String body;
  final NotificationStatus status;
  final String? errorMessage;
  final int retryCount;
  final String? templateCode;
  final DateTime? sentAt;
  final DateTime? createdAt;

  const NotificationDto({
    required this.id,
    required this.eventType,
    required this.channel,
    required this.recipient,
    required this.body,
    required this.status,
    required this.retryCount,
    this.subject,
    this.errorMessage,
    this.templateCode,
    this.sentAt,
    this.createdAt,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['id']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? '',
      channel: NotificationChannel.fromApi(json['channel']?.toString()),
      recipient: json['recipient']?.toString() ?? '',
      subject: json['subject']?.toString(),
      body: json['body']?.toString() ?? '',
      status: NotificationStatus.fromApi(json['status']?.toString()),
      errorMessage: json['errorMessage']?.toString(),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      templateCode: json['templateCode']?.toString(),
      sentAt: _parseDate(json['sentAt']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}

/// `NotificationService` metot dönüş tipi — fire-and-forget kullanımı için
/// success/failure ayrımı sessizce log + UI'a opsiyonel feedback.
class NotificationResult {
  final bool success;
  final NotificationDto? dto;
  final String? error;

  const NotificationResult._(this.success, this.dto, this.error);

  factory NotificationResult.success(NotificationDto dto) =>
      NotificationResult._(true, dto, null);

  factory NotificationResult.failure(String error) =>
      NotificationResult._(false, null, error);
}
