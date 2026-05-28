import 'dart:convert';
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jackdsql/models/user_models.dart';
import 'package:jackdsql/repositories/user_repository.dart';
import 'package:jackdsql/constants.dart';
import 'package:jackdsql/exceptions.dart';
import 'package:jackdsql/utils/http_client_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Events ---
abstract class AiHintEvent extends Equatable {
  const AiHintEvent();

  @override
  List<Object?> get props => [];
}

class AiHintFetchKeysEvent extends AiHintEvent {
  const AiHintFetchKeysEvent();
}

class AiHintAddKeyEvent extends AiHintEvent {
  final String provider;
  final String apiKey;
  const AiHintAddKeyEvent({required this.provider, required this.apiKey});

  @override
  List<Object?> get props => [provider, apiKey];
}

class AiHintDeleteKeyEvent extends AiHintEvent {
  final String provider;
  const AiHintDeleteKeyEvent(this.provider);

  @override
  List<Object?> get props => [provider];
}

class AiHintRequestEvent extends AiHintEvent {
  final String questionId;
  final String provider;
  final String sqlCode;
  const AiHintRequestEvent({
    required this.questionId,
    required this.provider,
    required this.sqlCode,
  });

  @override
  List<Object?> get props => [questionId, provider, sqlCode];
}

class AiHintConnectSseEvent extends AiHintEvent {
  final String token;
  const AiHintConnectSseEvent(this.token);

  @override
  List<Object?> get props => [token];
}

class AiHintDisconnectSseEvent extends AiHintEvent {
  const AiHintDisconnectSseEvent();
}

class AiHintSseMessageEvent extends AiHintEvent {
  final String requestId;
  final String questionId;
  final String hint;
  const AiHintSseMessageEvent({
    required this.requestId,
    required this.questionId,
    required this.hint,
  });

  @override
  List<Object?> get props => [requestId, questionId, hint];
}

class AiHintSseErrorEvent extends AiHintEvent {
  final String error;
  const AiHintSseErrorEvent(this.error);

  @override
  List<Object?> get props => [error];
}

// --- State ---
class AiHintState extends Equatable {
  final List<AiKeyInfo> keys;
  final bool isLoading;
  final String? error;
  final Map<String, String> activeHints; // requestId -> hint text
  final String? lastRequestId;
  final String? streamingError;
  final bool isStreaming;

  const AiHintState({
    this.keys = const [],
    this.isLoading = false,
    this.error,
    this.activeHints = const {},
    this.lastRequestId,
    this.streamingError,
    this.isStreaming = false,
  });

  AiHintState copyWith({
    List<AiKeyInfo>? keys,
    bool? isLoading,
    String? error,
    Map<String, String>? activeHints,
    String? lastRequestId,
    String? streamingError,
    bool? isStreaming,
  }) {
    return AiHintState(
      keys: keys ?? this.keys,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeHints: activeHints ?? this.activeHints,
      lastRequestId: lastRequestId ?? this.lastRequestId,
      streamingError: streamingError ?? this.streamingError,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  List<Object?> get props => [
        keys,
        isLoading,
        error,
        activeHints,
        lastRequestId,
        streamingError,
        isStreaming,
      ];
}

// --- BLoC ---
class AiHintBloc extends Bloc<AiHintEvent, AiHintState> {
  final UserRepository _userRepository;
  StreamSubscription? _sseSubscription;
  String? _connectedToken;

  AiHintBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(const AiHintState()) {
    on<AiHintFetchKeysEvent>(_onFetchKeys);
    on<AiHintAddKeyEvent>(_onAddKey);
    on<AiHintDeleteKeyEvent>(_onDeleteKey);
    on<AiHintRequestEvent>(_onRequestHint);
    on<AiHintConnectSseEvent>(_onConnectSse);
    on<AiHintDisconnectSseEvent>(_onDisconnectSse);
    on<AiHintSseMessageEvent>(_onSseMessage);
    on<AiHintSseErrorEvent>(_onSseError);
  }

  Future<void> _onFetchKeys(
    AiHintFetchKeysEvent event,
    Emitter<AiHintState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final keys = await _userRepository.getAiKeys();
      emit(state.copyWith(keys: keys, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e is AppException ? e.message : e.toString(),
      ));
    }
  }

  Future<void> _onAddKey(
    AiHintAddKeyEvent event,
    Emitter<AiHintState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _userRepository.addAiKey(event.provider, event.apiKey);
      final keys = await _userRepository.getAiKeys();
      emit(state.copyWith(keys: keys, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e is AppException ? e.message : e.toString(),
      ));
    }
  }

  Future<void> _onDeleteKey(
    AiHintDeleteKeyEvent event,
    Emitter<AiHintState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _userRepository.deleteAiKey(event.provider);
      final keys = await _userRepository.getAiKeys();
      emit(state.copyWith(keys: keys, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e is AppException ? e.message : e.toString(),
      ));
    }
  }

  Future<void> _onRequestHint(
    AiHintRequestEvent event,
    Emitter<AiHintState> emit,
  ) async {
    emit(state.copyWith(isStreaming: true, streamingError: null));
    try {
      final hintResponse = await _userRepository.requestAiHint(
        event.questionId,
        event.provider,
        event.sqlCode,
      );

      final updatedHints = Map<String, String>.from(state.activeHints);
      updatedHints[hintResponse.requestId] = '';

      emit(state.copyWith(
        lastRequestId: hintResponse.requestId,
        activeHints: updatedHints,
      ));
    } catch (e) {
      emit(state.copyWith(
        isStreaming: false,
        streamingError: e is AppException ? e.message : e.toString(),
      ));
    }
  }

  void _onConnectSse(
    AiHintConnectSseEvent event,
    Emitter<AiHintState> emit,
  ) {
    // SSE via dart:io HttpClient is NOT supported on Flutter Web.
    // Skip silently — AI hint requests still work via HTTP POST.
    if (kIsWeb) return;
    if (_sseSubscription != null && _connectedToken == event.token) return;
    _connectedToken = event.token;
    _startSseConnection(event.token);
  }

  void _onDisconnectSse(
    AiHintDisconnectSseEvent event,
    Emitter<AiHintState> emit,
  ) {
    _closeSseConnection();
    _connectedToken = null;
  }

  void _onSseMessage(
    AiHintSseMessageEvent event,
    Emitter<AiHintState> emit,
  ) {
    final updatedHints = Map<String, String>.from(state.activeHints);
    updatedHints[event.requestId] = event.hint;

    emit(state.copyWith(
      activeHints: updatedHints,
      isStreaming: false,
    ));
  }

  void _onSseError(
    AiHintSseErrorEvent event,
    Emitter<AiHintState> emit,
  ) {
    emit(state.copyWith(
      isStreaming: false,
      streamingError: event.error,
    ));
  }

  void _startSseConnection(String token) async {
    if (kIsWeb) return; // Safety guard
    _closeSseConnection();

    try {
      final prefs = await SharedPreferences.getInstance();
      final latestToken = prefs.getString('jwt_token') ?? token;
      _connectedToken = latestToken;

      // Use a simple HTTP-based SSE fallback via Dio's stream request.
      // This avoids importing dart:io directly which breaks web compilation.
      final url = Uri.parse('${AppConstants.baseUrl}/api/ai/stream');

      // On native platforms, we connect using a streaming HTTP client.
      // Wrap in try/catch to gracefully handle connection failures.
      await _connectSseNative(url.toString(), latestToken);
    } catch (e) {
      add(AiHintSseErrorEvent('SSE connection failed: $e'));
    }
  }

  Future<void> _connectSseNative(String url, String token) async {
    // This method is conditionally compiled only on native.
    // The kIsWeb guard in _startSseConnection prevents this from running on web.
    try {
      // We use the jsonDecode approach — import dart:io only at method call level.
      // This is safe because kIsWeb already returns before this point on web.
      final lines = await _openNativeStream(url, token);
      if (lines == null) return;

      String? currentEvent;
      _sseSubscription = lines.listen(
        (line) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) return;

          if (trimmed.startsWith('event:')) {
            currentEvent = trimmed.substring(6).trim();
          } else if (trimmed.startsWith('data:')) {
            final dataStr = trimmed.substring(5).trim();
            if (currentEvent == 'AI Hint') {
              try {
                final json = jsonDecode(dataStr) as Map<String, dynamic>;
                final requestId = json['requestId'] as String;
                final questionId = json['questionId'] as String;
                final hint = json['hint'] as String;

                add(AiHintSseMessageEvent(
                  requestId: requestId,
                  questionId: questionId,
                  hint: hint,
                ));
              } catch (_) {}
            }
          }
        },
        onError: (e) {
          final errStr = e.toString();
          // Silently reconnect in 5s on normal connection closed error
          if (errStr.contains('Connection closed') || errStr.contains('HttpException')) {
            Future.delayed(const Duration(seconds: 5), () {
              if (_connectedToken != null && !kIsWeb) {
                _startSseConnection(_connectedToken!);
              }
            });
          } else {
            add(AiHintSseErrorEvent('SSE error: $e'));
          }
        },
        onDone: () {
          if (_connectedToken != null) {
            Future.delayed(const Duration(seconds: 5), () {
              if (_connectedToken != null && !kIsWeb) {
                _startSseConnection(_connectedToken!);
              }
            });
          }
        },
      );
    } catch (e) {
      add(AiHintSseErrorEvent('SSE native connect error: $e'));
    }
  }

  // Returns a stream of SSE lines. Uses dynamic to avoid dart:io at compile time.
  Future<Stream<String>?> _openNativeStream(String url, String token) async {
    // This is only called from _connectSseNative, which is guarded by kIsWeb.
    // We use late binding through dynamic to avoid compilation failures on web.
    try {
      // ignore: avoid_dynamic_calls
      final dynamic ioImport = _getHttpClient();
      if (ioImport == null) return null;

      final dynamic client = ioImport;
      client.connectionTimeout = const Duration(seconds: 15);

      final uri = Uri.parse(url);
      final request = await client.getUrl(uri) as dynamic;
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Accept', 'text/event-stream');
      request.headers.set('Cache-Control', 'no-cache');
      request.headers.set('Connection', 'keep-alive');

      final response = await request.close() as dynamic;
      return (response as dynamic)
          .cast<List<int>>()
          .transform(const Utf8Decoder())
          .transform(const LineSplitter()) as Stream<String>;
    } catch (e) {
      return null;
    }
  }

  dynamic _getHttpClient() {
    return getPlatformHttpClient();
  }

  void _closeSseConnection() {
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _connectedToken = null;
  }

  @override
  Future<void> close() {
    _closeSseConnection();
    return super.close();
  }
}
