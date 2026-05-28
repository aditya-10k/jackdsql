import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jackdsql/exceptions.dart';
import 'package:jackdsql/models/question_models.dart';
import 'package:jackdsql/repositories/question_repository.dart';

// Events
abstract class QuestionEvent extends Equatable {
  const QuestionEvent();

  @override
  List<Object?> get props => [];
}

class QuestionFetchAllEvent extends QuestionEvent {
  const QuestionFetchAllEvent();
}

class QuestionFetchGroupedEvent extends QuestionEvent {
  const QuestionFetchGroupedEvent();
}

class QuestionFetchDetailEvent extends QuestionEvent {
  final String questionId;

  const QuestionFetchDetailEvent({required this.questionId});

  @override
  List<Object?> get props => [questionId];
}

class QuestionPreviewEvent extends QuestionEvent {
  final String questionId;
  final String userSql;

  const QuestionPreviewEvent({
    required this.questionId,
    required this.userSql,
  });

  @override
  List<Object?> get props => [questionId, userSql];
}

class QuestionSubmitEvent extends QuestionEvent {
  final String questionId;
  final String userSql;

  const QuestionSubmitEvent({
    required this.questionId,
    required this.userSql,
  });

  @override
  List<Object?> get props => [questionId, userSql];
}

class QuestionBookmarkEvent extends QuestionEvent {
  final String questionId;

  const QuestionBookmarkEvent({required this.questionId});

  @override
  List<Object?> get props => [questionId];
}

class QuestionFetchBookmarksEvent extends QuestionEvent {
  const QuestionFetchBookmarksEvent();
}

// States
abstract class QuestionState extends Equatable {
  const QuestionState();

  @override
  List<Object?> get props => [];
}

class QuestionInitial extends QuestionState {
  const QuestionInitial();
}

class QuestionLoading extends QuestionState {
  const QuestionLoading();
}

class QuestionAllLoading extends QuestionLoading {
  const QuestionAllLoading();
}

class QuestionGroupedLoading extends QuestionLoading {
  const QuestionGroupedLoading();
}

class QuestionDetailLoading extends QuestionLoading {
  const QuestionDetailLoading();
}

class QuestionPreviewLoading extends QuestionLoading {
  const QuestionPreviewLoading();
}

class QuestionSubmitLoading extends QuestionLoading {
  const QuestionSubmitLoading();
}

class QuestionBookmarksLoading extends QuestionLoading {
  const QuestionBookmarksLoading();
}

class QuestionAllLoaded extends QuestionState {
  final List<Question> questions;

  const QuestionAllLoaded({required this.questions});

  @override
  List<Object?> get props => [questions];
}

class QuestionGroupedLoaded extends QuestionState {
  final Map<String, List<QuestionListing>> grouped;

  const QuestionGroupedLoaded({required this.grouped});

  @override
  List<Object?> get props => [grouped];
}

class QuestionDetailLoaded extends QuestionState {
  final QuestionDetail detail;

  const QuestionDetailLoaded({required this.detail});

  @override
  List<Object?> get props => [detail];
}

class QuestionPreviewLoaded extends QuestionState {
  final PreviewResponse preview;

  const QuestionPreviewLoaded({required this.preview});

  @override
  List<Object?> get props => [preview];
}

class QuestionSubmitSuccess extends QuestionState {
  final bool isCorrect;

  const QuestionSubmitSuccess({required this.isCorrect});

  @override
  List<Object?> get props => [isCorrect];
}

class QuestionBookmarkToggled extends QuestionState {
  final bool isBookmarked;

  const QuestionBookmarkToggled({required this.isBookmarked});

  @override
  List<Object?> get props => [isBookmarked];
}

class QuestionBookmarksLoaded extends QuestionState {
  final List<BookmarkItem> bookmarks;

  const QuestionBookmarksLoaded({required this.bookmarks});

  @override
  List<Object?> get props => [bookmarks];
}

class QuestionError extends QuestionState {
  final String message;

  const QuestionError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class QuestionBloc extends Bloc<QuestionEvent, QuestionState> {
  final QuestionRepository _questionRepository;

  QuestionBloc({required QuestionRepository questionRepository})
      : _questionRepository = questionRepository,
        super(const QuestionInitial()) {
    on<QuestionFetchAllEvent>(_onFetchAllEvent);
    on<QuestionFetchGroupedEvent>(_onFetchGroupedEvent);
    on<QuestionFetchDetailEvent>(_onFetchDetailEvent);
    on<QuestionPreviewEvent>(_onPreviewEvent);
    on<QuestionSubmitEvent>(_onSubmitEvent);
    on<QuestionBookmarkEvent>(_onBookmarkEvent);
    on<QuestionFetchBookmarksEvent>(_onFetchBookmarksEvent);
  }

  Future<void> _onFetchAllEvent(
    QuestionFetchAllEvent event,
    Emitter<QuestionState> emit,
  ) async {
    emit(const QuestionAllLoading());
    try {
      final questions = await _questionRepository.getAllQuestions();
      emit(QuestionAllLoaded(questions: questions));
    } catch (e) {
      emit(QuestionError(
        message: e is AppException ? e.message : 'Failed to load questions',
      ));
    }
  }

  Future<void> _onFetchGroupedEvent(
    QuestionFetchGroupedEvent event,
    Emitter<QuestionState> emit,
  ) async {
    emit(const QuestionGroupedLoading());
    try {
      final grouped = await _questionRepository.getGroupedQuestions();
      emit(QuestionGroupedLoaded(grouped: grouped));
    } catch (e) {
      emit(QuestionError(
        message: e is AppException ? e.message : 'Failed to load questions',
      ));
    }
  }

  Future<void> _onFetchDetailEvent(
    QuestionFetchDetailEvent event,
    Emitter<QuestionState> emit,
  ) async {
    emit(const QuestionDetailLoading());
    try {
      final detail = await _questionRepository.getQuestionDetail(event.questionId);
      emit(QuestionDetailLoaded(detail: detail));
    } catch (e) {
      emit(QuestionError(
        message: e is AppException ? e.message : 'Failed to load question',
      ));
    }
  }

  Future<void> _onPreviewEvent(
    QuestionPreviewEvent event,
    Emitter<QuestionState> emit,
  ) async {
    emit(const QuestionPreviewLoading());
    try {
      final preview = await _questionRepository.previewSql(
        questionId: event.questionId,
        userSql: event.userSql,
      );
      emit(QuestionPreviewLoaded(preview: preview));
    } catch (e) {
      emit(QuestionError(
        message: e is AppException ? e.message : 'Preview failed',
      ));
    }
  }

  Future<void> _onSubmitEvent(
    QuestionSubmitEvent event,
    Emitter<QuestionState> emit,
  ) async {
    emit(const QuestionSubmitLoading());
    try {
      final isCorrect = await _questionRepository.submitSql(
        questionId: event.questionId,
        userSql: event.userSql,
      );
      emit(QuestionSubmitSuccess(isCorrect: isCorrect));
    } catch (e) {
      emit(QuestionError(
        message: e is AppException ? e.message : 'Submit failed',
      ));
    }
  }

  Future<void> _onBookmarkEvent(
    QuestionBookmarkEvent event,
    Emitter<QuestionState> emit,
  ) async {
    try {
      final isBookmarked = await _questionRepository.bookmarkQuestion(event.questionId);
      emit(QuestionBookmarkToggled(isBookmarked: isBookmarked));
    } catch (e) {
      emit(QuestionError(
        message: e is AppException ? e.message : 'Bookmark failed',
      ));
    }
  }

  Future<void> _onFetchBookmarksEvent(
    QuestionFetchBookmarksEvent event,
    Emitter<QuestionState> emit,
  ) async {
    emit(const QuestionBookmarksLoading());
    try {
      final bookmarks = await _questionRepository.getBookmarks();
      emit(QuestionBookmarksLoaded(bookmarks: bookmarks));
    } catch (e) {
      emit(QuestionError(
        message: e is AppException ? e.message : 'Failed to load bookmarks',
      ));
    }
  }
}
