import 'package:dio/dio.dart';
import 'package:jackdsql/services/api_client.dart';
import 'package:jackdsql/constants.dart';
import 'package:jackdsql/exceptions.dart';
import 'package:jackdsql/models/foundation_models.dart';
import 'package:jackdsql/services/hive_service.dart';
import 'package:jackdsql/models/question_models.dart';

abstract class FoundationRepository {
  Future<List<Foundation>> getAllFoundations();
  Future<List<FoundationCatalogue>> getFoundationCatalogue();
  Future<Foundation> getFoundationDetail(String id);
  Future<PreviewResponse> previewSql({
    required String topicId,
    required String userSql,
  });
  Future<bool> submitSql({
    required String topicId,
    required String userSql,
  });
}

class FoundationRepositoryImpl implements FoundationRepository {
  final ApiClient _apiClient;

  FoundationRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<Foundation>> getAllFoundations() async {
    try {
      final cached = await HiveService.getFoundations('all_foundations');
      if (cached != null) {
        return List<Foundation>.from(
          cached.map((e) => Foundation.fromJson(e as Map<String, dynamic>)),
        );
      }

      final response = await _apiClient.dio.get(
        '${AppConstants.foundationsEndpoint}/all',
      );

      final foundations = List<Foundation>.from(
        (response.data as List).map(
          (e) => Foundation.fromJson(e as Map<String, dynamic>),
        ),
      );

      await HiveService.saveFoundations(
        'all_foundations',
        foundations.map((e) => e.toJson()).toList(),
      );

      return foundations;
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<List<FoundationCatalogue>> getFoundationCatalogue() async {
    try {
      // Always fetch fresh catalogue since completion status changes per-session.
      final response = await _apiClient.dio.get(
        '${AppConstants.foundationsEndpoint}/catalogue',
      );

      final catalogue = List<FoundationCatalogue>.from(
        (response.data as List).map(
          (e) => FoundationCatalogue.fromJson(e as Map<String, dynamic>),
        ),
      );

      await HiveService.saveFoundations(
        'foundation_catalogue',
        catalogue.map((e) => e.toJson()).toList(),
      );

      return catalogue;
    } catch (e) {
      // Fall back to cache on network errors
      try {
        final cached = await HiveService.getFoundations('foundation_catalogue');
        if (cached != null) {
          return List<FoundationCatalogue>.from(
            cached.map((e) => FoundationCatalogue.fromJson(e as Map<String, dynamic>)),
          );
        }
      } catch (_) {}
      throw _handleException(e);
    }
  }

  @override
  Future<Foundation> getFoundationDetail(String id) async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.foundationsEndpoint}/$id',
      );

      final foundation = Foundation.fromJson(response.data);

      await HiveService.saveFoundations(
        'foundation_$id',
        [foundation.toJson()],
      );

      return foundation;
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<PreviewResponse> previewSql({
    required String topicId,
    required String userSql,
  }) async {
    try {
      final request = FoundationPreviewRequest(topicId: topicId, userSql: userSql);
      final response = await _apiClient.dio.post(
        '${AppConstants.foundationsEndpoint}/preview',
        data: request.toJson(),
      );

      return PreviewResponse.fromJson(response.data);
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<bool> submitSql({
    required String topicId,
    required String userSql,
  }) async {
    try {
      final request = FoundationSubmitRequest(topicId: topicId, userSql: userSql);
      final response = await _apiClient.dio.post(
        '${AppConstants.foundationsEndpoint}/submit',
        data: request.toJson(),
      );

      return SubmitResponse.fromJson(response.data).isCorrect;
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
      // Extract message from response body if available
      final responseData = e.response?.data;
      String? serverMessage;
      if (responseData is Map) {
        serverMessage = responseData['message'] as String? ?? responseData['error'] as String?;
      }
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        return AuthException(
          message: serverMessage ?? 'Session expired. Please log in again.',
          code: e.response?.statusCode?.toString(),
          originalError: e,
        );
      }
      return ServerException(
        message: serverMessage ?? e.message ?? 'Failed to fetch foundations',
        originalError: e,
      );
    }
    return AppException(
      message: 'An unexpected error occurred. Please check your connection.',
      originalError: e,
    );
  }
}

// Duplicate PreviewResponse and SubmitResponse definitions removed, imported from question_models.dart instead.
