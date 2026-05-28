import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jackdsql/models/foundation_models.dart';
import 'package:jackdsql/models/question_models.dart'; // For PreviewResponse and SubmitResponse
import 'package:jackdsql/repositories/foundation_repository.dart';
import 'package:jackdsql/exceptions.dart';

// --- Events ---
abstract class FoundationEvent extends Equatable {
  const FoundationEvent();

  @override
  List<Object?> get props => [];
}

class FoundationFetchCatalogueEvent extends FoundationEvent {
  const FoundationFetchCatalogueEvent();
}

class FoundationFetchDetailEvent extends FoundationEvent {
  final String id;
  const FoundationFetchDetailEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class FoundationPreviewSqlEvent extends FoundationEvent {
  final String topicId;
  final String userSql;
  const FoundationPreviewSqlEvent({required this.topicId, required this.userSql});

  @override
  List<Object?> get props => [topicId, userSql];
}

class FoundationSubmitSqlEvent extends FoundationEvent {
  final String topicId;
  final String userSql;
  const FoundationSubmitSqlEvent({required this.topicId, required this.userSql});

  @override
  List<Object?> get props => [topicId, userSql];
}

// --- States ---
abstract class FoundationState extends Equatable {
  const FoundationState();

  @override
  List<Object?> get props => [];
}

class FoundationInitial extends FoundationState {}

class FoundationLoading extends FoundationState {}

class FoundationCatalogueLoading extends FoundationLoading {}
class FoundationDetailLoading extends FoundationLoading {}
class FoundationPreviewLoading extends FoundationLoading {}
class FoundationSubmitLoading extends FoundationLoading {}

class FoundationCatalogueLoaded extends FoundationState {
  final List<FoundationCatalogue> catalogue;
  const FoundationCatalogueLoaded(this.catalogue);

  @override
  List<Object?> get props => [catalogue];
}

class FoundationDetailLoaded extends FoundationState {
  final Foundation foundation;
  const FoundationDetailLoaded(this.foundation);

  @override
  List<Object?> get props => [foundation];
}

class FoundationPreviewSuccess extends FoundationState {
  final PreviewResponse preview;
  const FoundationPreviewSuccess(this.preview);

  @override
  List<Object?> get props => [preview];
}

class FoundationSubmitSuccess extends FoundationState {
  final SubmitResponse submit;
  const FoundationSubmitSuccess(this.submit);

  @override
  List<Object?> get props => [submit];
}

class FoundationError extends FoundationState {
  final String message;
  const FoundationError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- BLoC ---
class FoundationBloc extends Bloc<FoundationEvent, FoundationState> {
  final FoundationRepository _foundationRepository;

  FoundationBloc({required FoundationRepository foundationRepository})
      : _foundationRepository = foundationRepository,
        super(FoundationInitial()) {
    on<FoundationFetchCatalogueEvent>(_onFetchCatalogue);
    on<FoundationFetchDetailEvent>(_onFetchDetail);
    on<FoundationPreviewSqlEvent>(_onPreviewSql);
    on<FoundationSubmitSqlEvent>(_onSubmitSql);
  }

  Future<void> _onFetchCatalogue(
    FoundationFetchCatalogueEvent event,
    Emitter<FoundationState> emit,
  ) async {
    emit(FoundationCatalogueLoading());
    try {
      final catalogue = await _foundationRepository.getFoundationCatalogue();
      emit(FoundationCatalogueLoaded(catalogue));
    } catch (e) {
      emit(FoundationError(e is AppException ? e.message : e.toString()));
    }
  }

  Future<void> _onFetchDetail(
    FoundationFetchDetailEvent event,
    Emitter<FoundationState> emit,
  ) async {
    emit(FoundationDetailLoading());
    try {
      final detail = await _foundationRepository.getFoundationDetail(event.id);
      emit(FoundationDetailLoaded(detail));
    } catch (e) {
      emit(FoundationError(e is AppException ? e.message : e.toString()));
    }
  }

  Future<void> _onPreviewSql(
    FoundationPreviewSqlEvent event,
    Emitter<FoundationState> emit,
  ) async {
    emit(FoundationPreviewLoading());
    try {
      final preview = await _foundationRepository.previewSql(
        topicId: event.topicId,
        userSql: event.userSql,
      );
      emit(FoundationPreviewSuccess(preview));
    } catch (e) {
      emit(FoundationError(e is AppException ? e.message : e.toString()));
    }
  }

  Future<void> _onSubmitSql(
    FoundationSubmitSqlEvent event,
    Emitter<FoundationState> emit,
  ) async {
    emit(FoundationSubmitLoading());
    try {
      final isCorrect = await _foundationRepository.submitSql(
        topicId: event.topicId,
        userSql: event.userSql,
      );
      emit(FoundationSubmitSuccess(SubmitResponse(isCorrect: isCorrect)));
    } catch (e) {
      emit(FoundationError(e is AppException ? e.message : e.toString()));
    }
  }
}
