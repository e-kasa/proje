import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../constants/env_config.dart';

/// Uygulama genelinde kullanılacak merkezi logger.
///
/// - **Debug modda** `dart:developer` log() kullanır (DevTools'ta görünür).
/// - **Release/Profile modda** sessizdir (`kDebugMode` koruması).
/// - Production ortamında loglama tamamen kapalıdır (`EnvConfig.enableLogging`).
///
/// Kullanım:
/// ```dart
/// AppLogger.info('Veriler yüklendi');
/// AppLogger.warning('Stok düşük', tag: 'StockService');
/// AppLogger.error('API hatası', error: e, stackTrace: st);
/// ```
class AppLogger {
  AppLogger._();

  static const String _defaultTag = 'App';

  /// Bilgi seviyesi log
  static void info(String message, {String? tag}) {
    _log(message, tag: tag ?? _defaultTag, level: 800);
  }

  /// Uyarı seviyesi log
  static void warning(String message, {String? tag, Object? error}) {
    _log(message, tag: tag ?? _defaultTag, level: 900, error: error);
  }

  /// Hata seviyesi log
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      message,
      tag: tag ?? _defaultTag,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Debug seviyesi log — yalnızca development ortamında
  static void debug(String message, {String? tag}) {
    if (!EnvConfig.isDev) return;
    _log(message, tag: tag ?? _defaultTag, level: 500);
  }

  static void _log(
    String message, {
    required String tag,
    required int level,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode || !EnvConfig.enableLogging) return;

    developer.log(
      message,
      name: tag,
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
