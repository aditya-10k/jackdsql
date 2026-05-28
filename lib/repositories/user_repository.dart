import 'package:dio/dio.dart';
import 'package:jackdsql/services/api_client.dart';
import 'package:jackdsql/models/user_models.dart';
import 'package:jackdsql/models/question_models.dart'; // For PreviewResponse
import 'package:jackdsql/exceptions.dart';

abstract class UserRepository {
  Future<UserOverview> getUserOverview();
  Future<List<AiKeyInfo>> getAiKeys();
  Future<void> addAiKey(String provider, String apiKey);
  Future<void> deleteAiKey(String provider);
  Future<PreviewResponse> runPlayground(String sql);
  Future<HintResponse> requestAiHint(String questionId, String provider, String sqlCode);
}

class UserRepositoryImpl implements UserRepository {
  final ApiClient _apiClient;

  UserRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<UserOverview> getUserOverview() async {
    try {
      final response = await _apiClient.dio.get('/api/user/overview');
      return UserOverview.fromJson(response.data);
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<List<AiKeyInfo>> getAiKeys() async {
    try {
      final response = await _apiClient.dio.get('/api/user/keys');
      return (response.data as List)
          .map((json) => AiKeyInfo.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<void> addAiKey(String provider, String apiKey) async {
    try {
      final request = AiKeyRequest(provider: provider, apiKey: apiKey);
      await _apiClient.dio.post(
        '/api/user/keys/add',
        data: request.toJson(),
      );
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<void> deleteAiKey(String provider) async {
    try {
      await _apiClient.dio.delete('/api/user/keys/delete/$provider');
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<PreviewResponse> runPlayground(String sql) async {
    try {
      final request = PlaygroundRequest(userSql: sql);
      final response = await _apiClient.dio.post(
        '/api/playground',
        data: request.toJson(),
      );
      return PreviewResponse.fromJson(response.data);
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<HintResponse> requestAiHint(
    String questionId,
    String provider,
    String sqlCode,
  ) async {
    try {
      final request = HintRequest(sqlCode: sqlCode);
      final response = await _apiClient.dio.post(
        '/api/ai/hint/$questionId',
        queryParameters: {'provider': provider},
        data: request.toJson(),
      );
      return HintResponse.fromJson(response.data);
    } catch (e) {
      throw _handleException(e);
    }
  }

  AppException _handleException(dynamic e) {
    if (e is AppException) return e;
    if (e is DioException) {
      if (e.error is AppException) return e.error as AppException;
      String msg = 'Request failed';
      if (e.response?.data != null) {
        if (e.response?.data is Map && e.response?.data['error'] != null) {
          msg = e.response?.data['error'].toString() ?? msg;
        } else if (e.response?.data is Map && e.response?.data['message'] != null) {
          msg = e.response?.data['message'].toString() ?? msg;
        }
      }
      return NetworkException(
        message: msg,
        originalError: e,
      );
    }
    return AppException(message: 'An unexpected error occurred', originalError: e);
  }
}
