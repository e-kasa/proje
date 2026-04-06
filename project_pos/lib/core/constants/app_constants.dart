import 'env_config.dart';

class AppConstants {
  // API Configuration — ortam bazlı, EnvConfig üzerinden okunur
  static String get baseUrl => EnvConfig.baseUrl;
  static int get connectionTimeout => EnvConfig.connectionTimeout;
  static int get receiveTimeout => EnvConfig.receiveTimeout;

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String companyCodeKey = 'company_code'; // X-Company-Code gateway header'ı için
  static const String themeKey = 'theme_mode';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // App Info
  static const String appName = 'Admin Dashboard';
  static const String appVersion = '1.0.0';

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;

  // UI
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 0.0;

  // Chart Colors
  static const List<String> chartColors = [
    '#6366F1',
    '#8B5CF6',
    '#EC4899',
    '#F97316',
    '#EAB308',
    '#22C55E',
    '#10B981',
    '#14B8A6',
    '#06B6D4',
    '#0EA5E9',
    '#3B82F6',
    '#6366F1',
  ];
}