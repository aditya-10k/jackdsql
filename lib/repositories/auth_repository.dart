import 'package:dio/dio.dart';
import 'package:jackdsql/services/api_client.dart';
import 'package:jackdsql/models/auth_models.dart';
import 'package:jackdsql/constants.dart';
import 'package:jackdsql/exceptions.dart';
import 'package:jackdsql/services/hive_service.dart';

abstract class AuthRepository {
  Future<String> login({required String email, required String password});
  Future<String> register({
    required String email,
    required String password,
    required String name,
  });
  Future<String> googleAuth({required String idToken});
  Future<void> logout();
  Future<bool> isAuthenticated();
  Future<UserProfile?> getUserProfile();
  Future<bool> checkHealth();
  Future<void> sendOtp({required String email});
  Future<String> verifyOtp({
    required String otp,
    required String email,
    required String password,
  });
  Future<String> getGoogleClientId();
}


class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;

  AuthRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _apiClient.dio.post(
        AppConstants.loginEndpoint,
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);
      await _apiClient.saveToken(authResponse.accessToken);
      await _apiClient.saveRefreshToken(authResponse.refreshToken);
      await HiveService.saveToken(authResponse.accessToken);
      await HiveService.saveRefreshToken(authResponse.refreshToken);
      return authResponse.accessToken;
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<String> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final request = RegisterRequest(email: email, password: password, name: name);
      final response = await _apiClient.dio.post(
        AppConstants.registerEndpoint,
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);
      await _apiClient.saveToken(authResponse.accessToken);
      await _apiClient.saveRefreshToken(authResponse.refreshToken);
      await HiveService.saveToken(authResponse.accessToken);
      await HiveService.saveRefreshToken(authResponse.refreshToken);
      return authResponse.accessToken;
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<String> googleAuth({required String idToken}) async {
    try {
      final request = GoogleAuthRequest(idToken: idToken);
      final response = await _apiClient.dio.post(
        AppConstants.googleAuthEndpoint,
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);
      await _apiClient.saveToken(authResponse.accessToken);
      await _apiClient.saveRefreshToken(authResponse.refreshToken);
      await HiveService.saveToken(authResponse.accessToken);
      await HiveService.saveRefreshToken(authResponse.refreshToken);
      return authResponse.accessToken;
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.clearToken();
      await _apiClient.clearRefreshToken();
      await HiveService.clearAllCache();
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await _apiClient.isAuthenticated();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<UserProfile?> getUserProfile() async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.userEndpoint}/profile',
      );
      final profile = UserProfile.fromJson(response.data);
      return profile;
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<bool> checkHealth() async {
    try {
      final response = await _apiClient.dio.get(
        AppConstants.healthEndpoint,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> sendOtp({required String email}) async {
    try {
      await _apiClient.dio.post(
        AppConstants.sendOtpEndpoint,
        data: {'email': email},
      );
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<String> verifyOtp({
    required String otp,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        AppConstants.verifyOtpEndpoint,
        data: {
          'otp': otp,
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);
      await _apiClient.saveToken(authResponse.accessToken);
      await _apiClient.saveRefreshToken(authResponse.refreshToken);
      await HiveService.saveToken(authResponse.accessToken);
      await HiveService.saveRefreshToken(authResponse.refreshToken);
      return authResponse.accessToken;
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<String> getGoogleClientId() async {
    try {
      final response = await _apiClient.dio.get('/api/auth/google/client-id');
      return response.data['clientId'] as String? ?? '';
    } catch (e) {
      throw _handleException(e);
    }
  }

  AppException _handleException(dynamic e) {
    if (e is AppException) {
      return e;
    } else if (e is DioException) {
      if (e.error is AppException) {
        return e.error as AppException;
      }
      return AuthException(
        message: e.message ?? 'Authentication failed',
        originalError: e,
      );
    }
    return AppException(
      message: 'An unexpected error occurred',
      originalError: e,
    );
  }
}
