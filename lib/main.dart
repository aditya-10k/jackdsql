import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jackdsql/services/api_client.dart';
import 'package:jackdsql/services/hive_service.dart';
import 'package:jackdsql/theme.dart';

// Repositories
import 'package:jackdsql/repositories/auth_repository.dart';
import 'package:jackdsql/repositories/question_repository.dart';
import 'package:jackdsql/repositories/foundation_repository.dart';
import 'package:jackdsql/repositories/user_repository.dart';

// Blocs
import 'package:jackdsql/blocs/auth_bloc.dart';
import 'package:jackdsql/blocs/question_bloc.dart';
import 'package:jackdsql/blocs/foundation_bloc.dart';
import 'package:jackdsql/blocs/playground_bloc.dart';
import 'package:jackdsql/blocs/ai_hint_bloc.dart';
import 'package:jackdsql/blocs/user_bloc.dart';

// Screens
import 'package:jackdsql/screens/splash_screen.dart';
import 'package:jackdsql/screens/login_screen.dart';
import 'package:jackdsql/screens/dashboard_screen.dart';
import 'package:jackdsql/screens/question_detail_screen.dart';
import 'package:jackdsql/screens/foundation_detail_screen.dart';
import 'package:jackdsql/screens/playground_screen.dart';
import 'package:jackdsql/screens/api_keys_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for caching
  await HiveService.initializeHive();
  
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  
  runApp(MyApp(sharedPreferences: sharedPreferences));
}

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;

  const MyApp({required this.sharedPreferences, super.key});

  @override
  Widget build(BuildContext context) {
    // Setup dependencies
    final apiClient = ApiClient(sharedPreferences: sharedPreferences);
    
    final authRepository = AuthRepositoryImpl(apiClient: apiClient);
    final questionRepository = QuestionRepositoryImpl(apiClient: apiClient);
    final foundationRepository = FoundationRepositoryImpl(apiClient: apiClient);
    final userRepository = UserRepositoryImpl(apiClient: apiClient);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => authRepository),
        RepositoryProvider<QuestionRepository>(create: (_) => questionRepository),
        RepositoryProvider<FoundationRepository>(create: (_) => foundationRepository),
        RepositoryProvider<UserRepository>(create: (_) => userRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            )..add(const AuthCheckEvent()),
          ),
          BlocProvider(
            create: (context) => QuestionBloc(
              questionRepository: context.read<QuestionRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => FoundationBloc(
              foundationRepository: context.read<FoundationRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => PlaygroundBloc(
              userRepository: context.read<UserRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => AiHintBloc(
              userRepository: context.read<UserRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => UserBloc(
              userRepository: context.read<UserRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'JackDSQL',
          theme: AppTheme.darkTheme,
          home: const RouteManager(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/foundation_detail': (context) => const FoundationDetailScreen(),
            '/question_detail': (context) => const QuestionDetailScreen(),
            '/playground': (context) => const PlaygroundScreen(),
            '/api_keys': (context) => const ApiKeysScreen(),
          },
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class RouteManager extends StatelessWidget {
  const RouteManager({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial) {
          return const SplashScreen();
        } else if (state is AuthAuthenticated) {
          return const DashboardScreen();
        } else if (state is AuthUnauthenticated) {
          return const LoginScreen();
        } else if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
