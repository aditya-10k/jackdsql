import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jackdsql/models/user_models.dart';
import 'package:jackdsql/repositories/user_repository.dart';
import 'package:jackdsql/exceptions.dart';

// --- Events ---
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class UserFetchOverviewEvent extends UserEvent {
  const UserFetchOverviewEvent();
}

// --- States ---
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserOverviewLoaded extends UserState {
  final UserOverview overview;
  const UserOverviewLoaded(this.overview);

  @override
  List<Object?> get props => [overview];
}

class UserOverviewError extends UserState {
  final String message;
  const UserOverviewError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- BLoC ---
class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _userRepository;

  UserBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(UserInitial()) {
    on<UserFetchOverviewEvent>(_onFetchOverview);
  }

  Future<void> _onFetchOverview(
    UserFetchOverviewEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      final overview = await _userRepository.getUserOverview();
      emit(UserOverviewLoaded(overview));
    } catch (e) {
      emit(UserOverviewError(e is AppException ? e.message : e.toString()));
    }
  }
}
