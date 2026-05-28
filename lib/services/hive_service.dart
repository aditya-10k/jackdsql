import 'package:hive_flutter/hive_flutter.dart';
import 'package:jackdsql/constants.dart';

class HiveService {
  static Future<void> initializeHive() async {
    await Hive.initFlutter();
    await _openBoxes();
  }

  static Future<void> _openBoxes() async {
    await Hive.openBox<String>(AppConstants.hiveBoxAuth);
    await Hive.openBox<dynamic>(AppConstants.hiveBoxQuestions);
    await Hive.openBox<dynamic>(AppConstants.hiveBoxFoundations);
    await Hive.openBox<dynamic>(AppConstants.hiveBoxUser);
    await Hive.openBox<dynamic>(AppConstants.hiveBoxBookmarks);
  }

  // Auth Box Operations
  static Box<String> getAuthBox() => Hive.box<String>(AppConstants.hiveBoxAuth);

  static Future<void> saveToken(String token) async {
    await getAuthBox().put(AppConstants.tokenKey, token);
  }

  static Future<String?> getToken() async {
    return getAuthBox().get(AppConstants.tokenKey);
  }

  static Future<void> clearToken() async {
    await getAuthBox().delete(AppConstants.tokenKey);
  }

  static Future<void> saveRefreshToken(String token) async {
    await getAuthBox().put(AppConstants.refreshTokenKey, token);
  }

  static Future<String?> getRefreshToken() async {
    return getAuthBox().get(AppConstants.refreshTokenKey);
  }

  static Future<void> clearRefreshToken() async {
    await getAuthBox().delete(AppConstants.refreshTokenKey);
  }

  // Questions Cache Operations
  static Box<dynamic> getQuestionsBox() =>
      Hive.box<dynamic>(AppConstants.hiveBoxQuestions);

  static Future<void> saveQuestions(String key, List<dynamic> questions) async {
    await getQuestionsBox().put(key, questions);
  }

  static Future<List<dynamic>?> getQuestions(String key) async {
    return getQuestionsBox().get(key) as List<dynamic>?;
  }

  static Future<void> clearQuestionsCache() async {
    await getQuestionsBox().clear();
  }

  // Foundations Cache Operations
  static Box<dynamic> getFoundationsBox() =>
      Hive.box<dynamic>(AppConstants.hiveBoxFoundations);

  static Future<void> saveFoundations(
    String key,
    List<dynamic> foundations,
  ) async {
    await getFoundationsBox().put(key, foundations);
  }

  static Future<List<dynamic>?> getFoundations(String key) async {
    return getFoundationsBox().get(key) as List<dynamic>?;
  }

  static Future<void> clearFoundationsCache() async {
    await getFoundationsBox().clear();
  }

  // User Cache Operations
  static Box<dynamic> getUserBox() => Hive.box<dynamic>(AppConstants.hiveBoxUser);

  static Future<void> saveUserProfile(String key, dynamic profile) async {
    await getUserBox().put(key, profile);
  }

  static Future<dynamic> getUserProfile(String key) async {
    return getUserBox().get(key);
  }

  static Future<void> clearUserCache() async {
    await getUserBox().clear();
  }

  // Bookmarks Cache Operations
  static Box<dynamic> getBookmarksBox() =>
      Hive.box<dynamic>(AppConstants.hiveBoxBookmarks);

  static Future<void> saveBookmarks(String key, List<dynamic> bookmarks) async {
    await getBookmarksBox().put(key, bookmarks);
  }

  static Future<List<dynamic>?> getBookmarks(String key) async {
    return getBookmarksBox().get(key) as List<dynamic>?;
  }

  static Future<void> clearBookmarksCache() async {
    await getBookmarksBox().clear();
  }

  // Global clear (logout)
  static Future<void> clearAllCache() async {
    await clearToken();
    await clearRefreshToken();
    await clearQuestionsCache();
    await clearFoundationsCache();
    await clearUserCache();
    await clearBookmarksCache();
  }
}
