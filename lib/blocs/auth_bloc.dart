import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jackdsql/models/auth_models.dart';
import 'package:jackdsql/repositories/auth_repository.dart';
import 'package:jackdsql/exceptions.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginEvent extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const AuthRegisterEvent({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}

class AuthGoogleSignInEvent extends AuthEvent {
  final String idToken;

  const AuthGoogleSignInEvent({required this.idToken});

  @override
  List<Object?> get props => [idToken];
}

class AuthCheckEvent extends AuthEvent {
  const AuthCheckEvent();
}

class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}

class AuthGetProfileEvent extends AuthEvent {
  const AuthGetProfileEvent();
}

class AuthSendOtpEvent extends AuthEvent {
  final String email;

  const AuthSendOtpEvent({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthVerifyOtpEvent extends AuthEvent {
  final String otp;
  final String email;
  final String password;

  const AuthVerifyOtpEvent({
    required this.otp,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [otp, email, password];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final String token;
  final UserProfile? profile;

  const AuthAuthenticated({required this.token, this.profile});

  @override
  List<Object?> get props => [token, profile];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthOtpSentSuccess extends AuthState {
  final String email;

  const AuthOtpSentSuccess({required this.email});

  @override
  List<Object?> get props => [email];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthLoginEvent>(_onLoginEvent);
    on<AuthRegisterEvent>(_onRegisterEvent);
    on<AuthGoogleSignInEvent>(_onGoogleSignInEvent);
    on<AuthCheckEvent>(_onCheckEvent);
    on<AuthLogoutEvent>(_onLogoutEvent);
    on<AuthGetProfileEvent>(_onGetProfileEvent);
    on<AuthSendOtpEvent>(_onSendOtpEvent);
    on<AuthVerifyOtpEvent>(_onVerifyOtpEvent);
  }

  Future<void> _onLoginEvent(
    AuthLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final token = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(token: token));
      add(const AuthGetProfileEvent());
    } catch (e) {
      emit(AuthError(
        message: e is AppException ? e.message : 'Login failed',
      ));
    }
  }

  Future<void> _onRegisterEvent(
    AuthRegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final token = await _authRepository.register(
        email: event.email,
        password: event.password,
        name: event.name,
      );
      emit(AuthAuthenticated(token: token));
      add(const AuthGetProfileEvent());
    } catch (e) {
      emit(AuthError(
        message: e is AppException ? e.message : 'Registration failed',
      ));
    }
  }

  Future<void> _onGoogleSignInEvent(
    AuthGoogleSignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final token = await _authRepository.googleAuth(idToken: event.idToken);
      emit(AuthAuthenticated(token: token));
      add(const AuthGetProfileEvent());
    } catch (e) {
      emit(AuthError(
        message: e is AppException ? e.message : 'Google sign-in failed',
      ));
    }
  }

  Future<void> _onCheckEvent(
    AuthCheckEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isAuth = await _authRepository.isAuthenticated();
      if (!isAuth) {
        emit(const AuthUnauthenticated());
        return;
      }

      // Try to silently refresh on startup to get a fresh 30-day token pair.
      // If it fails (no network / server down), proceed with the existing token —
      // it's a 30-day token so it's almost certainly still valid.
      await _authRepository.refreshTokensOnStartup();

      final profile = await _authRepository.getUserProfile();
      emit(AuthAuthenticated(token: 'existing', profile: profile));
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutEvent(
    AuthLogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(
        message: e is AppException ? e.message : 'Logout failed',
      ));
    }
  }

  Future<void> _onGetProfileEvent(
    AuthGetProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final profile = await _authRepository.getUserProfile();
      if (state is AuthAuthenticated) {
        final currentState = state as AuthAuthenticated;
        emit(AuthAuthenticated(token: currentState.token, profile: profile));
      }
    } catch (e) {
      // Silently fail, don't change state
    }
  }

  Future<void> _onSendOtpEvent(
    AuthSendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.sendOtp(email: event.email);
      emit(AuthOtpSentSuccess(email: event.email));
    } catch (e) {
      emit(AuthError(
        message: e is AppException ? e.message : 'Failed to send OTP',
      ));
    }
  }

  Future<void> _onVerifyOtpEvent(
    AuthVerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final token = await _authRepository.verifyOtp(
        otp: event.otp,
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(token: token));
      add(const AuthGetProfileEvent());
    } catch (e) {
      emit(AuthError(
        message: e is AppException ? e.message : 'OTP verification failed',
      ));
    }
  }
}
