import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/api/api_client.dart';
import 'package:project_pos/core/utils/app_logger.dart';

/// Sprint 29 — Email config DTO (backend `EmailConfigDto` karşılığı).
///
/// Backend GET response'unda {@code password} maskeli ("****") veya null döner.
/// PUT request'inde {@code password} null/boş bırakılırsa mevcut değer korunur
/// (kısmi update).
class EmailConfigDto {
  final String? host;
  final int? port;
  final bool? useTls;
  final String? username;
  final String? password;       // GET'te "****" mask, PUT'ta dolu = güncelle
  final String? from;
  final bool? enabled;

  const EmailConfigDto({
    this.host,
    this.port,
    this.useTls,
    this.username,
    this.password,
    this.from,
    this.enabled,
  });

  factory EmailConfigDto.fromJson(Map<String, dynamic> json) {
    return EmailConfigDto(
      host: json['host']?.toString(),
      port: (json['port'] as num?)?.toInt(),
      useTls: json['useTls'] as bool?,
      username: json['username']?.toString(),
      password: json['password']?.toString(),
      from: json['from']?.toString(),
      enabled: json['enabled'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'channel': 'EMAIL',
        if (host != null) 'host': host,
        if (port != null) 'port': port,
        if (useTls != null) 'useTls': useTls,
        if (username != null) 'username': username,
        if (password != null && password!.isNotEmpty) 'password': password,
        if (from != null) 'from': from,
        if (enabled != null) 'enabled': enabled,
      };

  /// UI'a "şifre maskeli mi?" göstergesi.
  bool get isPasswordMasked => password == '****';
}

/// Sprint 29 — Notification config (SMTP/Twilio) save+load API tüketicisi.
///
/// Backend: `pos-product-manager` /api/v1/notification-settings/email
/// (PUT/GET). Sprint 30'da SMS endpoint'i eklenecek (aynı pattern).
class NotificationConfigService {
  final ApiClient _apiClient;
  NotificationConfigService(this._apiClient);

  Future<EmailConfigDto?> loadEmail() async {
    try {
      final res = await _apiClient.get('product/api/v1/notification-settings/email');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return EmailConfigDto.fromJson(data);
      }
      return null;
    } on DioException catch (e) {
      AppLogger.warning('Email config yüklenemedi: ${e.message}');
      return null;
    }
  }

  Future<EmailConfigDto?> saveEmail(EmailConfigDto config) async {
    try {
      final res = await _apiClient.put(
        'product/api/v1/notification-settings/email',
        data: config.toJson(),
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return EmailConfigDto.fromJson(data);
      }
      return null;
    } on DioException catch (e) {
      AppLogger.warning('Email config kaydedilemedi: ${e.message}');
      rethrow;
    }
  }
}

final notificationConfigServiceProvider =
    Provider<NotificationConfigService>((ref) {
  return NotificationConfigService(ref.read(apiClientProvider));
});
