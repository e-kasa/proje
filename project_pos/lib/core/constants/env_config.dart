/// Ortam konfigürasyonu.
///
/// Derleme zamanında `--dart-define` ile ortam seçilir:
///
/// ```bash
/// # Development (varsayılan)
/// flutter run --dart-define=ENV=dev
///
/// # Staging
/// flutter run --dart-define=ENV=staging
///
/// # Production
/// flutter run --dart-define=ENV=prod
/// ```
///
/// Opsiyonel olarak baseUrl doğrudan override edilebilir:
/// ```bash
/// flutter run --dart-define=BASE_URL=https://custom-api.example.com/
/// ```
library;

/// Uygulama ortam seçenekleri.
enum Environment {
  dev,
  staging,
  prod,
}

/// Ortam konfigürasyon yardımcısı.
///
/// `--dart-define=ENV=dev|staging|prod` ile derleme zamanında ortam seçilir.
/// Base URL, timeout süreleri ve loglama ayarları ortama göre belirlenir.
/// Opsiyonel olarak `--dart-define=BASE_URL=...` ile URL override edilebilir.
class EnvConfig {
  EnvConfig._();

  // --dart-define değerlerini compile-time'da oku
  static const String _envName =
      String.fromEnvironment('ENV', defaultValue: 'dev');

  static const String _baseUrlOverride =
      String.fromEnvironment('BASE_URL');

  /// Aktif ortam
  static Environment get environment {
    switch (_envName) {
      case 'staging':
        return Environment.staging;
      case 'prod':
      case 'production':
        return Environment.prod;
      case 'dev':
      case 'development':
      default:
        return Environment.dev;
    }
  }

  /// API base URL.
  /// Öncelik sırası:
  /// 1. `--dart-define=BASE_URL=...` ile verilen değer
  /// 2. Ortama göre varsayılan URL
  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    switch (environment) {
      case Environment.dev:
        return 'http://localhost:8080/';
      case Environment.staging:
        return 'https://staging-api.ekalem.com/';
      case Environment.prod:
        return 'https://api.ekalem.com/';
    }
  }

  /// Bağlantı zaman aşımı (ms)
  static int get connectionTimeout {
    switch (environment) {
      case Environment.dev:
        return 15000;
      case Environment.staging:
        return 20000;
      case Environment.prod:
        return 10000;
    }
  }

  /// Yanıt alma zaman aşımı (ms)
  /// PDF analizi uzun sürebilir (OCR + eşleşme): dev=60s, staging=45s, prod=30s
  static int get receiveTimeout {
    switch (environment) {
      case Environment.dev:
        return 60000;
      case Environment.staging:
        return 45000;
      case Environment.prod:
        return 30000;
    }
  }

  /// Debug/verbose logging aktif mi
  static bool get enableLogging {
    switch (environment) {
      case Environment.dev:
        return true;
      case Environment.staging:
        return true;
      case Environment.prod:
        return false;
    }
  }

  /// Ortam adı (UI'da göstermek için)
  static String get environmentName {
    switch (environment) {
      case Environment.dev:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.prod:
        return 'Production';
    }
  }

  /// Dev ortamı mı
  static bool get isDev => environment == Environment.dev;

  /// Production ortamı mı
  static bool get isProd => environment == Environment.prod;

  /// Staging ortamı mı
  static bool get isStaging => environment == Environment.staging;
}
