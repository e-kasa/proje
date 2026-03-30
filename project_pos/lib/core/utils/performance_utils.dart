import 'dart:async';
import 'package:flutter/foundation.dart';

/// Debounce - Hızlı aramalar için performans optimizasyonu
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Throttle - Scroll gibi sürekli olaylar için
class Throttler {
  final Duration delay;
  Timer? _timer;
  bool _isReady = true;

  Throttler({this.delay = const Duration(milliseconds: 300)});

  void call(VoidCallback action) {
    if (_isReady) {
      _isReady = false;
      action();
      _timer = Timer(delay, () => _isReady = true);
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Memoization - Pahalı hesaplamaları cache'le
class Memoizer<T> {
  final Map<String, T> _cache = {};

  T call(String key, T Function() computation) {
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }
    final result = computation();
    _cache[key] = result;
    return result;
  }

  void clear() => _cache.clear();

  void remove(String key) => _cache.remove(key);
}

/// Performance Monitor - Debug modda performans ölçümü
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};

  static void start(String name) {
    if (!kDebugMode) return;
    _timers[name] = Stopwatch()..start();
  }

  static void end(String name) {
    if (!kDebugMode) return;
    final timer = _timers[name];
    if (timer != null) {
      timer.stop();
      debugPrint('⚡ $name took ${timer.elapsedMilliseconds}ms');
      _timers.remove(name);
    }
  }

  static T measure<T>(String name, T Function() function) {
    start(name);
    final result = function();
    end(name);
    return result;
  }

  static Future<T> measureAsync<T>(String name, Future<T> Function() function) async {
    start(name);
    final result = await function();
    end(name);
    return result;
  }
}

/// Async Helper - Kolay async operasyonlar
class AsyncHelper {
  /// Delay ile async işlem
  static Future<T> delayed<T>(
    Future<T> Function() function, {
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    await Future.delayed(delay);
    return await function();
  }

  /// Timeout ile async işlem
  static Future<T?> withTimeout<T>(
    Future<T> Function() function, {
    Duration timeout = const Duration(seconds: 10),
    T? defaultValue,
  }) async {
    try {
      return await function().timeout(timeout);
    } catch (e) {
      debugPrint('⚠️ Timeout: $e');
      return defaultValue;
    }
  }

  /// Retry logic
  static Future<T?> retry<T>(
    Future<T> Function() function, {
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        return await function();
      } catch (e) {
        if (i == maxAttempts - 1) rethrow;
        await Future.delayed(delay);
      }
    }
    return null;
  }
}
