import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/api/api_client.dart';
import 'package:project_pos/core/utils/app_logger.dart';

import 'notification_models.dart';

/// Sprint 27 — Notification backend tüketicisi.
///
/// Backend: `pos-product-manager` /api/v1/notifications/* endpoint'leri.
/// Sprint 25 EMAIL real, Sprint 26-A SMS NOOP default (Twilio config-driven).
///
/// Tüketici çağrı paterni:
/// ```dart
/// // POS sale tamamlandı → fire-and-forget SMS
/// ref.read(notificationServiceProvider).send(
///   NotificationRequest(
///     eventType: 'SALE_CREATED',
///     channel: NotificationChannel.sms,
///     recipient: customer.phone!,
///     body: 'Satışınız tamamlandı: ₺${total}',
///   ),
/// ).ignore();  // UI engellenmesin; hata log'a düşer
/// ```
class NotificationService {
  final ApiClient _apiClient;

  NotificationService(this._apiClient);

  /// POST /api/v1/notifications/send — backend 202 Accepted + DTO döner.
  ///
  /// HTTP / network hataları yakalanır — `NotificationResult.failure(error)`
  /// olarak döner. Çağıran istemese bile `Future` `ignore()` edilebilir
  /// (fire-and-forget); hata log'a düşer.
  Future<NotificationResult> send(NotificationRequest req) async {
    try {
      final res = await _apiClient.post(
        'product/api/v1/notifications/send',
        data: req.toJson(),
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        return NotificationResult.failure('Geçersiz response: $data');
      }
      return NotificationResult.success(NotificationDto.fromJson(data));
    } on DioException catch (e) {
      final msg = _extractError(e);
      AppLogger.warning('Notification send başarısız: $msg');
      return NotificationResult.failure(msg);
    } catch (e) {
      AppLogger.error('Notification send beklenmeyen hata', error: e);
      return NotificationResult.failure(e.toString());
    }
  }

  /// Sprint 30 — Vadesi geçen müşterilere bildirim taraması manuel tetikle.
  ///
  /// Backend: `POST /api/v1/admin/notifications/overdue/scan` (ROLE_ADMIN).
  /// Sadece çağıranın aktif tenant'ı taranır (`X-Company-Code` header).
  /// Multi-tenant batch için backend scheduled job otomatik tetiklenir
  /// (`overdue.notification.enabled=true` + cron).
  Future<({int queued, int skipped, String? error})>
      triggerOverdueScan() async {
    try {
      final res = await _apiClient.post(
        'product/api/v1/admin/notifications/overdue/scan',
      );
      final body = res.data;
      Map<String, dynamic>? data;
      if (body is Map<String, dynamic>) {
        final inner = body['data'];
        if (inner is Map<String, dynamic>) {
          data = inner;
        } else {
          data = body;
        }
      }
      final queued = (data?['queued'] as num?)?.toInt() ?? 0;
      final skipped = (data?['skipped'] as num?)?.toInt() ?? 0;
      return (queued: queued, skipped: skipped, error: null);
    } on DioException catch (e) {
      final msg = _extractError(e);
      AppLogger.warning('Overdue scan başarısız: $msg');
      return (queued: 0, skipped: 0, error: msg);
    } catch (e) {
      AppLogger.error('Overdue scan beklenmeyen hata', error: e);
      return (queued: 0, skipped: 0, error: e.toString());
    }
  }

  /// GET /api/v1/notifications?status=...&page=...&size=...
  Future<List<NotificationDto>> list({
    NotificationStatus? status,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final res = await _apiClient.get(
        'product/api/v1/notifications',
        queryParameters: {
          if (status != null) 'status': status.apiValue,
          'page': page,
          'size': size,
        },
      );
      final data = res.data;
      if (data is Map<String, dynamic> && data['content'] is List) {
        return (data['content'] as List)
            .whereType<Map<String, dynamic>>()
            .map(NotificationDto.fromJson)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      AppLogger.warning('Notification list başarısız: ${_extractError(e)}');
      return const [];
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'] ?? data['error'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return e.message ?? 'Bilinmeyen hata';
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.read(apiClientProvider));
});
