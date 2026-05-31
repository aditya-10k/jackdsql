import 'dart:io';
import 'package:flutter/foundation.dart';

// Constants
class AppConstants {
  // API
  // static final String baseUrl = kIsWeb
  //     ? 'http://localhost:8080'
  //     : (Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080');
  static final String baseUrl = "https://adityx10-jackdsql-api.hf.space";
  static const String apiPrefix = '/api';
  
  // Endpoints
  static const String healthEndpoint = '/api/health';
  static const String registerEndpoint = '/api/auth/register';
  static const String loginEndpoint = '/api/auth/login';
  static const String googleAuthEndpoint = '/api/auth/googleauth';
  static const String sendOtpEndpoint = '/api/auth/sendotp';
  static const String verifyOtpEndpoint = '/api/auth/verifyOtp';
  static const String refreshEndpoint = '/api/auth/refresh';
  static const String questionsEndpoint = '/api/questions';
  static const String foundationsEndpoint = '/api/foundations';
  static const String userEndpoint = '/api/user';
  static const String playgroundEndpoint = '/api/playground';
  static const String aiEndpoint = '/api/ai';
  
  // Hive
  static const String hiveBoxAuth = 'auth_box';
  static const String hiveBoxQuestions = 'questions_box';
  static const String hiveBoxFoundations = 'foundations_box';
  static const String hiveBoxUser = 'user_box';
  static const String hiveBoxBookmarks = 'bookmarks_box';
  
  // JWT
  static const String tokenKey = 'token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user';
  
  // Timeout
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Pagination
  static const int pageSize = 20;
}
