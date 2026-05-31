import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jackdsql/constants.dart';
import 'package:jackdsql/exceptions.dart';
import 'package:logger/logger.dart';
import 'package:jackdsql/services/hive_service.dart';

class ApiClient {
  late final Dio _dio;
  final SharedPreferences _prefs;
  final Logger _logger = Logger();

  static const String _tokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';

  ApiClient({required SharedPreferences sharedPreferences})
      : _prefs = sharedPreferences {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(_TokenInterceptor(_prefs));
    _dio.interceptors.add(_LoggingInterceptor(_logger));
    _dio.interceptors.add(_ErrorInterceptor(_logger));
  }

  Dio get dio => _dio;

  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    return _prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _prefs.setString(_refreshTokenKey, token);
  }

  Future<String?> getRefreshToken() async {
    return _prefs.getString(_refreshTokenKey);
  }

  Future<void> clearRefreshToken() async {
    await _prefs.remove(_refreshTokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Called once on app startup. Uses the stored refresh token to get a fresh
  /// access+refresh pair. Returns true if successful, false otherwise.
  Future<bool> refreshOnStartup() async {
    final refreshToken = _prefs.getString(_refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      _logger.i('Startup token refresh...');
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          contentType: 'application/json',
          responseType: ResponseType.json,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await refreshDio.get(
        AppConstants.refreshEndpoint,
        options: Options(
          headers: {'Authorization': 'Bearer $refreshToken'},
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final newAccess = data['access_token'] as String? ?? '';
        final newRefresh = data['refresh_token'] as String? ?? '';

        if (newAccess.isNotEmpty) {
          await saveToken(newAccess);
          await saveRefreshToken(newRefresh);
          await HiveService.saveToken(newAccess);
          await HiveService.saveRefreshToken(newRefresh);
          _logger.i('Startup refresh succeeded.');
          return true;
        }
      }
      _logger.w('Startup refresh returned ${response.statusCode}. Keeping existing token.');
      return false;
    } catch (e) {
      // Network error / server down — keep the existing (30-day) token as-is
      _logger.w('Startup refresh failed (network). Keeping existing token: $e');
      return false;
    }
  }
}

class _TokenInterceptor extends Interceptor {
  final SharedPreferences _prefs;

  _TokenInterceptor(this._prefs);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final path = options.path;
    final isPublicRoute = path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/googleauth') ||
        path.contains('/auth/verifyOtp') ||
        path.contains('/auth/sendotp') ||
        path.contains('/auth/google/client-id') ||
        path.contains('/health');

    if (!isPublicRoute) {
      final token = _prefs.getString('jwt_token');
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    return handler.next(options);
  }
}

class _LoggingInterceptor extends Interceptor {
  final Logger _logger;

  _LoggingInterceptor(this._logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.i('--> ${options.method} ${options.uri}');
    if (options.data != null) {
      _logger.i('Body: ${options.data}');
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.i('<-- ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}');
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.requestOptions.path.contains('/health')) {
      _logger.d('<-- ERROR (Health Check) ${err.message}');
    } else {
      _logger.e('<-- ERROR ${err.message} ${err.requestOptions.uri}');
    }
    return handler.next(err);
  }
}

/// Maps HTTP error codes to typed [AppException]s.
/// No automatic token refresh — 30-day access tokens + startup refresh handle that.
class _ErrorInterceptor extends Interceptor {
  final Logger _logger;

  _ErrorInterceptor(this._logger);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!err.requestOptions.path.contains('/health')) {
      _logger.e('API Error: ${err.message}', error: err.error);
    }

    AppException? appException;

    if (err.response?.statusCode == 401) {
      appException = AuthException(
        message: 'Session expired. Please login again.',
        code: '401',
        originalError: err,
      );
    } else if (err.response?.statusCode == 403) {
      appException = AuthException(
        message: 'Access denied. You do not have permission.',
        code: '403',
        originalError: err,
      );
    } else if (err.response?.statusCode == 400) {
      final errorMessage =
          err.response?.data['error'] as String? ?? 'Invalid request';
      appException = ValidationException(
        message: errorMessage,
        code: '400',
        originalError: err,
      );
    } else if (err.response?.statusCode == 500) {
      appException = ServerException(
        message: 'Server error. Please try again later.',
        code: '500',
        originalError: err,
      );
    } else if (err.response != null) {
      final dynamic data = err.response?.data;
      String errorMessage = 'Request failed with status ${err.response?.statusCode}';
      if (data is Map) {
        errorMessage = data['error'] as String? ?? data['message'] as String? ?? errorMessage;
      }
      appException = ServerException(
        message: errorMessage,
        code: err.response?.statusCode?.toString(),
        originalError: err,
      );
    } else if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      appException = NetworkException(
        message: 'Connection timeout. Please check your internet.',
        code: 'TIMEOUT',
        originalError: err,
      );
    } else {
      appException = NetworkException(
        message: err.message ?? 'An unexpected network error occurred.',
        code: 'NETWORK_ERROR',
        originalError: err,
      );
    }

    return handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: appException,
        message: appException.message,
      ),
    );
  }
}
