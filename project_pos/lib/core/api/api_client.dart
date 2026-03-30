import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth_events.dart';
import '../constants/app_constants.dart';

class ApiClient {
  late final Dio _dio;
  SharedPreferences? _prefs;    // SharedPreferences instance cache — disk I/O sadece ilk seferde

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectionTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
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

    // Logger Interceptor — SADECE debug modunda (yavaşlamayı önler)
    if (kDebugMode) {
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

  Future<bool> _refreshToken() async {
    try {
      final prefs = await _getPrefs();
      final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await _dio.post(
        'security/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final data = (body['payload'] ?? body) as Map<String, dynamic>;
        final newToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (newToken == null) return false;

        await prefs.setString(AppConstants.tokenKey, newToken);
        if (newRefreshToken != null) {
          await prefs.setString(AppConstants.refreshTokenKey, newRefreshToken);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
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

  // HTTP Methods
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
        if (data is Map) {
          final msgs = data['messages'];
          if (msgs is List && msgs.isNotEmpty) {
            message = msgs.first.toString();
          } else {
            message = data['message']?.toString() ?? 'Server error';
          }
        } else {
          message = 'Server error';
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
    }
    return Exception(message);
  }
}
