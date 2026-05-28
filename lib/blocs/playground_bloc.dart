import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jackdsql/models/question_models.dart'; // For PreviewResponse
import 'package:jackdsql/repositories/user_repository.dart';
import 'package:jackdsql/exceptions.dart';

// --- Events ---
abstract class PlaygroundEvent extends Equatable {
  const PlaygroundEvent();

  @override
  List<Object?> get props => [];
}

class PlaygroundRunSqlEvent extends PlaygroundEvent {
  final String sql;
  const PlaygroundRunSqlEvent(this.sql);

  @override
  List<Object?> get props => [sql];
}

class PlaygroundClearEvent extends PlaygroundEvent {
  const PlaygroundClearEvent();
}

// --- States ---
abstract class PlaygroundState extends Equatable {
  const PlaygroundState();

  @override
  List<Object?> get props => [];
}

class PlaygroundInitial extends PlaygroundState {}

class PlaygroundLoading extends PlaygroundState {}

class PlaygroundSuccess extends PlaygroundState {
  final PreviewResponse result;
  const PlaygroundSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class PlaygroundError extends PlaygroundState {
  final String message;
  const PlaygroundError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- BLoC ---
class PlaygroundBloc extends Bloc<PlaygroundEvent, PlaygroundState> {
  final UserRepository _userRepository;

  PlaygroundBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(PlaygroundInitial()) {
    on<PlaygroundRunSqlEvent>(_onRunSql);
    on<PlaygroundClearEvent>(_onClear);
  }

  Future<void> _onRunSql(
    PlaygroundRunSqlEvent event,
    Emitter<PlaygroundState> emit,
  ) async {
    emit(PlaygroundLoading());
    try {
      final result = await _userRepository.runPlayground(event.sql);
      emit(PlaygroundSuccess(result));
    } catch (e) {
      emit(PlaygroundError(e is AppException ? e.message : e.toString()));
    }
  }

  void _onClear(
    PlaygroundClearEvent event,
    Emitter<PlaygroundState> emit,
  ) {
    emit(PlaygroundInitial());
  }
}
