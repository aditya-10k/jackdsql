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

    // Add interceptors
    _dio.interceptors.add(_TokenInterceptor(_prefs));
    _dio.interceptors.add(_LoggingInterceptor(_logger));
    _dio.interceptors.add(_ErrorInterceptor(this, _logger));
  }

  Dio get dio => _dio;

  // Store token securely
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  // Retrieve token
  Future<String?> getToken() async {
    return _prefs.getString(_tokenKey);
  }

  // Clear token
  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }

  // Store refresh token
  Future<void> saveRefreshToken(String token) async {
    await _prefs.setString(_refreshTokenKey, token);
  }

  // Retrieve refresh token
  Future<String?> getRefreshToken() async {
    return _prefs.getString(_refreshTokenKey);
  }

  // Clear refresh token
  Future<void> clearRefreshToken() async {
    await _prefs.remove(_refreshTokenKey);
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
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
    _logger.i('Headers: ${options.headers}');
    if (options.data != null) {
      _logger.i('Body: ${options.data}');
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.i('<-- ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}');
    _logger.i('Response Data: ${response.data}');
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.requestOptions.path.contains('/health')) {
      _logger.d('<-- ERROR (Health Check) ${err.message} ${err.requestOptions.method} ${err.requestOptions.uri}');
    } else {
      _logger.e('<-- ERROR ${err.message} ${err.requestOptions.method} ${err.requestOptions.uri}');
      if (err.response != null) {
        _logger.e('Response Status: ${err.response?.statusCode}');
        _logger.e('Response Body: ${err.response?.data}');
      }
    }
    return handler.next(err);
  }
}

class _ErrorInterceptor extends Interceptor {
  final ApiClient _apiClient;
  final Logger _logger;
  Future<String?>? _tokenRefreshFuture;

  _ErrorInterceptor(this._apiClient, this._logger);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.requestOptions.path.contains('/health')) {
      _logger.d('API Health Check failed: ${err.message}');
    } else {
      _logger.e('API Error: ${err.message}', error: err.error, stackTrace: err.stackTrace);
    }

    final path = err.requestOptions.path;
    final isAuthRoute = path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/googleauth') ||
        path.contains('/auth/verifyOtp') ||
        path.contains('/auth/sendotp');

    if (err.response?.statusCode == 401 && !isAuthRoute) {
      try {
        String? newAccessToken;
        if (_tokenRefreshFuture != null) {
          _logger.i('Token refresh already in progress, waiting...');
          newAccessToken = await _tokenRefreshFuture;
        } else {
          _tokenRefreshFuture = _performTokenRefresh();
          newAccessToken = await _tokenRefreshFuture;
          _tokenRefreshFuture = null;
        }

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';

          final responseRetry = await _apiClient.dio.fetch(options);
          return handler.resolve(responseRetry);
        }
      } catch (refreshErr) {
        _tokenRefreshFuture = null;

        // Only fully logout if the refresh endpoint itself rejected the token (401/403).
        // Network errors (server restarting, timeout) must NOT wipe the session.
        final isHardAuthFailure = refreshErr is DioException &&
            (refreshErr.response?.statusCode == 401 ||
                refreshErr.response?.statusCode == 403);

        if (isHardAuthFailure) {
          _logger.e('Refresh token rejected by server. Logging out...', error: refreshErr);
          await _apiClient.clearToken();
          await _apiClient.clearRefreshToken();
          await HiveService.clearAllCache();

          return handler.next(
            DioException(
              requestOptions: err.requestOptions,
              error: AuthException(
                message: 'Session expired. Please login again.',
                code: '401',
                originalError: refreshErr,
              ),
            ),
          );
        } else {
          // Transient error (network, timeout, server restart) — keep the session alive.
          _logger.w('Token refresh failed due to transient error (${refreshErr.runtimeType}). Keeping session.');
        }
      }
    }

    AppException? appException;
    if (err.response?.statusCode == 401) {
      appException = AuthException(
        message: 'Unauthorized. Please login again.',
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

  Future<String?> _performTokenRefresh() async {
    final refreshToken = await _apiClient.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    _logger.i('Attempting to refresh token...');
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    final response = await refreshDio.get(
      AppConstants.refreshEndpoint,
      options: Options(
        headers: {'Authorization': 'Bearer $refreshToken'},
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final newAccessToken = data['access_token'] as String;
      final newRefreshToken = data['refresh_token'] as String;

      _logger.i('Token refreshed successfully!');
      await _apiClient.saveToken(newAccessToken);
      await _apiClient.saveRefreshToken(newRefreshToken);
      await HiveService.saveToken(newAccessToken);
      await HiveService.saveRefreshToken(newRefreshToken);

      return newAccessToken;
    }
    return null;
  }
}
