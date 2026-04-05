import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth_events.dart';
import '../constants/app_constants.dart';
import '../constants/env_config.dart';

/// Merkezi HTTP istemcisi — Dio tabanlı, tüm backend iletişimini yönetir.
///
/// Özellikler:
/// - JWT token tabanlı kimlik doğrulama (Bearer token interceptor)
/// - 401 alındığında otomatik token yenileme (`refreshToken`)
/// - `X-Company-Code` header'ı ile API Gateway domain çözümlemesini bypass eder
/// - Base URL [AppConstants.baseUrl] üzerinden ortama göre belirlenir
/// - Debug modda [PrettyDioLogger] ile HTTP log'lama
class ApiClient {
  late final Dio _dio;
  late final Dio _tokenDio;     // Refresh token için interceptor'süz ayrı Dio instance
  SharedPreferences? _prefs;    // SharedPreferences instance cache — disk I/O sadece ilk seferde
  bool _isRefreshing = false;   // Aynı anda birden fazla refresh isteği önlenir
  Completer<bool>? _refreshCompleter; // Eşzamanlı 401'ler tek bir refresh bekler

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: Duration(milliseconds: AppConstants.connectionTimeout),
        receiveTimeout: Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Refresh token isteği için interceptor'süz temiz Dio instance.
    // Bu sayede refresh isteği 401 alırsa onError interceptor'a GİRMEZ → sonsuz döngü olmaz.
    _tokenDio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: Duration(milliseconds: AppConstants.connectionTimeout),
        receiveTimeout: Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  void _setupInterceptors() {
    // Request Interceptor - Add token to headers
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // SharedPreferences instance cache — getInstance() sadece ilk seferde async
          final prefs = await _getPrefs();

          // JWT token — korunan endpoint'ler için
          final token = prefs.getString(AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // X-Company-Code — API Gateway'in CompanyResolutionFilter'ını bypass eder.
          // Flutter mobil/desktop Origin header göndermez; domain çözümlemesi başarısız olur.
          // Bu header varsa gateway doğrudan kullanır, security servisine sorgulamaz.
          final companyCode = prefs.getString(AppConstants.companyCodeKey);
          if (companyCode != null && companyCode.isNotEmpty) {
            options.headers['X-Company-Code'] = companyCode;
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final retryResponse = await _retry(error.requestOptions);
              return handler.resolve(retryResponse);
            } else {
              await _handleLogout();
            }
          }
          return handler.next(error);
        },
      ),
    );

    // Logger Interceptor — debug modunda VE logging aktifse (prod'da kapalı)
    if (kDebugMode && EnvConfig.enableLogging) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 120,
        ),
      );
    }
  }

  /// Token yenileme — eşzamanlı 401'lerde tek bir refresh isteği yapılır.
  ///
  /// [_tokenDio] kullanılarak interceptor'süz istek atılır,
  /// böylece refresh 401 alırsa sonsuz döngüye girilmez.
  /// Aynı anda birden fazla 401 gelirse hepsi aynı Completer'ı bekler.
  Future<bool> _refreshToken() async {
    // Zaten bir refresh devam ediyorsa, sonucunu bekle (race condition önlenir)
    if (_isRefreshing) {
      return _refreshCompleter?.future ?? Future.value(false);
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final prefs = await _getPrefs();
      final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
      if (refreshToken == null) {
        _refreshCompleter!.complete(false);
        return false;
      }

      // _tokenDio kullan — interceptor yok, 401 alırsa döngüye girmez
      final response = await _tokenDio.post(
        'security/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final data = (body['payload'] ?? body) as Map<String, dynamic>;
        final newToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (newToken == null) {
          _refreshCompleter!.complete(false);
          return false;
        }

        await prefs.setString(AppConstants.tokenKey, newToken);
        if (newRefreshToken != null) {
          await prefs.setString(AppConstants.refreshTokenKey, newRefreshToken);
        }
        _refreshCompleter!.complete(true);
        return true;
      }
      _refreshCompleter!.complete(false);
      return false;
    } catch (e) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  /// Başarısız olan isteği yeni token ile tekrar dener.
  ///
  /// Eski Authorization header'ı temizlenir — interceptor yeni token'ı ekler.
  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    // Eski Authorization header'ını kaldır — interceptor güncel token'ı ekleyecek
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    headers.remove('Authorization');

    final options = Options(
      method: requestOptions.method,
      headers: headers,
    );

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<void> _handleLogout() async {
    final prefs = await _getPrefs();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userKey);
    await prefs.remove('session_id');
    AuthEvents.notifyUnauthorized();
  }

  /// HTTP GET isteği gönderir.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// HTTP POST isteği gönderir.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// HTTP PUT isteği gönderir.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// HTTP DELETE isteği gönderir.
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// HTTP PATCH isteği gönderir.
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Multipart file upload
  ///
  /// [path] - API endpoint (e.g. 'product/api/v1/supplier-upload/file')
  /// [filePath] - Absolute path to the local file
  /// [fieldName] - Form field name for the file (e.g. 'file')
  /// [data] - Optional additional form fields
  Future<Response> upload(
    String path, {
    required String filePath,
    String fieldName = 'file',
    Map<String, dynamic>? data,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        if (data != null) ...data,
      });
      final response = await _dio.post(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DioException'ı anlamlı hata mesajına dönüştürür.
  ///
  /// error.type'a göre switch ile uygun mesaj üretir.
  /// badResponse durumunda response body'den mesaj çıkarılmaya çalışılır.
  Exception _handleError(DioException error) {
    String message;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout';
        break;
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        if (data is Map<String, dynamic>) {
          // Backend'den gelen hata mesajlarını çıkar
          final messages = data['messages'];
          if (messages is List && messages.isNotEmpty) {
            message = messages.join(', ');
          } else {
            message = data['message']?.toString() ??
                data['error']?.toString() ??
                'Bad response: ${error.response?.statusCode}';
          }
        } else {
          message = 'Bad response: ${error.response?.statusCode}';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled';
        break;
      case DioExceptionType.connectionError:
        message = 'Connection error';
        break;
      default:
        message = 'Something went wrong';
        break;
    }
    return Exception(message);
  }
}