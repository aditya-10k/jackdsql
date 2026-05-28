import 'package:dio/dio.dart';
import 'package:jackdsql/services/api_client.dart';
import 'package:jackdsql/constants.dart';
import 'package:jackdsql/exceptions.dart';
import 'package:jackdsql/services/hive_service.dart';
import 'package:jackdsql/models/question_models.dart';

abstract class QuestionRepository {
  Future<List<Question>> getAllQuestions();
  Future<Map<String, List<QuestionListing>>> getGroupedQuestions();
  Future<QuestionDetail> getQuestionDetail(String id);
  Future<PreviewResponse> previewSql({
    required String questionId,
    required String userSql,
  });
  Future<bool> submitSql({
    required String questionId,
    required String userSql,
  });
  Future<bool> bookmarkQuestion(String id);
  Future<List<BookmarkItem>> getBookmarks();
}

class QuestionRepositoryImpl implements QuestionRepository {
  final ApiClient _apiClient;

  QuestionRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<Question>> getAllQuestions() async {
    try {
      // Try to get from cache first
      final cached = await HiveService.getQuestions('all_questions');
      if (cached != null) {
        return List<Question>.from(
          cached.map((e) => Question.fromJson(e as Map<String, dynamic>)),
        );
      }

      // Fetch from API
      final response = await _apiClient.dio.get(
        '${AppConstants.questionsEndpoint}/all-questions',
      );

      final questions = List<Question>.from(
        (response.data as List).map(
          (e) => Question.fromJson(e as Map<String, dynamic>),
        ),
      );

      // Cache the result
      await HiveService.saveQuestions(
        'all_questions',
        questions.map((e) => e.toJson()).toList(),
      );

      return questions;
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<Map<String, List<QuestionListing>>> getGroupedQuestions() async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.questionsEndpoint}/grouped',
      );

      final Map<String, List<QuestionListing>> grouped = {};
      (response.data as Map<String, dynamic>).forEach((key, value) {
        grouped[key] = List<QuestionListing>.from(
          (value as List).map(
            (e) => QuestionListing.fromJson(e as Map<String, dynamic>),
          ),
        );
      });

      // Cache the result
      await HiveService.saveQuestions('grouped_questions', [response.data]);

      return grouped;
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<QuestionDetail> getQuestionDetail(String id) async {
    try {
      final response = await _apiClient.dio.get(
        '${AppConstants.questionsEndpoint}/$id',
      );

      final detail = QuestionDetail.fromJson(response.data);
      
      // Cache individual question
      await HiveService.saveQuestions(
        'question_$id',
        [detail.toJson()],
      );

      return detail;
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<PreviewResponse> previewSql({
    required String questionId,
    required String userSql,
  }) async {
    try {
      final request = PreviewRequest(questionId: questionId, userSql: userSql);
      final response = await _apiClient.dio.post(
        '${AppConstants.questionsEndpoint}/preview',
        data: request.toJson(),
      );

      return PreviewResponse.fromJson(response.data);
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<bool> submitSql({
    required String questionId,
    required String userSql,
  }) async {
    try {
      final request = PreviewRequest(questionId: questionId, userSql: userSql);
      final response = await _apiClient.dio.post(
        '${AppConstants.questionsEndpoint}/submit',
        data: request.toJson(),
      );

      return SubmitResponse.fromJson(response.data).isCorrect;
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<bool> bookmarkQuestion(String id) async {
    try {
      final response = await _apiClient.dio.post(
        '${AppConstants.questionsEndpoint}/$id/bookmark',
      );
      return response.data['is_bookmarked'] as bool? ?? false;
    } catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<List<BookmarkItem>> getBookmarks() async {
    try {
      // Try cache first
      final cached = await HiveService.getBookmarks('bookmarks');
      if (cached != null) {
        return List<BookmarkItem>.from(
          cached.map((e) => BookmarkItem.fromJson(e as Map<String, dynamic>)),
        );
      }

      // Fetch from API
      final response = await _apiClient.dio.get(
        '${AppConstants.questionsEndpoint}/bookmarks',
      );

      final bookmarks = List<BookmarkItem>.from(
        (response.data as List).map(
          (e) => BookmarkItem.fromJson(e as Map<String, dynamic>),
        ),
      );

      // Cache
      await HiveService.saveBookmarks(
        'bookmarks',
        bookmarks.map((e) => e.toJson()).toList(),
      );

      return bookmarks;
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
      return ServerException(
        message: e.message ?? 'Failed to fetch questions',
        originalError: e,
      );
    }
    return AppException(
      message: 'An unexpected error occurred',
      originalError: e,
    );
  }
}
