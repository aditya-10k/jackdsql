import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jackdsql/blocs/auth_bloc.dart';
import 'package:jackdsql/repositories/auth_repository.dart';
import 'package:jackdsql/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool? _isSystemOnline;

  GoogleSignIn? _googleSignIn;
  String? _googleClientId;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _checkSystemHealth();
    _initGoogleSignIn();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkSystemHealth() async {
    if (!mounted) return;
    try {
      final isOnline = await context.read<AuthRepository>().checkHealth();
      if (mounted) {
        setState(() {
          _isSystemOnline = isOnline;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSystemOnline = false;
        });
      }
    }
  }

  Future<void> _initGoogleSignIn() async {
    const envId = String.fromEnvironment('GOOGLE_CLIENT_ID');
    if (envId.isNotEmpty) {
      _googleClientId = envId;
    } else {
      try {
        final clientId = await context.read<AuthRepository>().getGoogleClientId();
        if (clientId.isNotEmpty) {
          _googleClientId = clientId;
        }
      } catch (e) {
        debugPrint('Failed to load Google Client ID: $e');
      }
    }

    if (_googleClientId != null && mounted) {
      setState(() {
        _googleSignIn = GoogleSignIn(
          clientId: _googleClientId,
          scopes: ['email', 'profile'],
        );
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_googleSignIn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Google Sign-In is not initialized. Please try again.',
            style: TextStyle(fontFamily: 'JetBrainsMono'),
          ),
          backgroundColor: AppTheme.hardColor.withOpacity(0.8),
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      try {
        await _googleSignIn!.signOut();
      } catch (_) {}
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Google ID token is null');
      }

      if (mounted) {
        context.read<AuthBloc>().add(AuthGoogleSignInEvent(idToken: idToken));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Google Sign-In failed: $e',
              style: const TextStyle(fontFamily: 'JetBrains Mono'),
            ),
            backgroundColor: AppTheme.hardColor.withOpacity(0.8),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRegisterBottomSheet() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isRegisterLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF13171e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'INITIALIZE ACCOUNT',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'JetBrains Mono',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 16),
                      const Text(
                        'DISPLAY NAME',
                        style: TextStyle(
                          color: Colors.white54,
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'JetBrains Mono',
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'John Doe',
                          hintStyle: const TextStyle(
                            color: Colors.white24,
                            fontFamily: 'JetBrains Mono',
                            fontSize: 14,
                          ),
                          fillColor: const Color(0xFF090c10),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Name required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'EMAIL ADDRESS',
                        style: TextStyle(
                          color: Colors.white54,
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: emailController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'JetBrains Mono',
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'user@example.com',
                          hintStyle: const TextStyle(
                            color: Colors.white24,
                            fontFamily: 'JetBrains Mono',
                            fontSize: 14,
                          ),
                          fillColor: const Color(0xFF090c10),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Email required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'PASSWORD',
                        style: TextStyle(
                          color: Colors.white54,
                          fontFamily: 'JetBrains Mono',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'JetBrains Mono',
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: const TextStyle(
                            color: Colors.white24,
                            fontFamily: 'JetBrains Mono',
                            fontSize: 14,
                          ),
                          fillColor: const Color(0xFF090c10),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) => value == null || value.length < 6
                            ? 'Password must be >= 6 chars'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isRegisterLoading
                              ? null
                              : () async {
                                  if (formKey.currentState!.validate()) {
                                    setSheetState(
                                      () => isRegisterLoading = true,
                                    );
                                    try {
                                      Navigator.pop(context);
                                      this.context.read<AuthBloc>().add(
                                        AuthRegisterEvent(
                                          name: nameController.text,
                                          email: emailController.text,
                                          password: passwordController.text,
                                        ),
                                      );
                                    } catch (e) {
                                      setSheetState(
                                        () => isRegisterLoading = false,
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isRegisterLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'REGISTER ACCOUNT',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showResetPasswordBottomSheet() {
    final emailController = TextEditingController();
    final otpController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isOtpSent = false;
    bool isSheetLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF13171e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isOtpSent
                                ? 'VERIFY OTP & RESET'
                                : 'RESET SECURITY KEY',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'JetBrains Mono',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 16),
                      if (!isOtpSent) ...[
                        const Text(
                          'REGISTERED EMAIL ADDRESS',
                          style: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: emailController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'JetBrains Mono',
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'user@example.com',
                            hintStyle: const TextStyle(
                              color: Colors.white24,
                              fontFamily: 'JetBrains Mono',
                              fontSize: 14,
                            ),
                            fillColor: const Color(0xFF090c10),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Email required'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isSheetLoading
                                ? null
                                : () async {
                                    if (formKey.currentState!.validate()) {
                                      setSheetState(
                                        () => isSheetLoading = true,
                                      );
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      final authRepository = context
                                          .read<AuthRepository>();
                                      try {
                                        await authRepository.sendOtp(
                                          email: emailController.text,
                                        );
                                        setSheetState(() {
                                          isOtpSent = true;
                                          isSheetLoading = false;
                                        });
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'OTP sent to your email.',
                                              style: TextStyle(
                                                fontFamily: 'JetBrains Mono',
                                              ),
                                            ),
                                            backgroundColor:
                                                AppTheme.surfaceContainer,
                                          ),
                                        );
                                      } catch (e) {
                                        setSheetState(
                                          () => isSheetLoading = false,
                                        );
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to send OTP: $e',
                                              style: const TextStyle(
                                                fontFamily: 'JetBrains Mono',
                                              ),
                                            ),
                                            backgroundColor: AppTheme.hardColor
                                                .withOpacity(0.8),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isSheetLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'SEND SECURITY OTP',
                                    style: TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'OTP sent to ${emailController.text}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '6-DIGIT OTP KEY',
                          style: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: otpController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'JetBrains Mono',
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: '123456',
                            hintStyle: const TextStyle(
                              color: Colors.white24,
                              fontFamily: 'JetBrains Mono',
                              fontSize: 14,
                            ),
                            fillColor: const Color(0xFF090c10),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              value == null || value.length < 4
                              ? 'Invalid OTP'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'NEW SECURE PASSWORD',
                          style: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'JetBrains Mono',
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: const TextStyle(
                              color: Colors.white24,
                              fontFamily: 'JetBrains Mono',
                              fontSize: 14,
                            ),
                            fillColor: const Color(0xFF090c10),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.length < 6
                              ? 'Password must be >= 6 chars'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isSheetLoading
                                ? null
                                : () async {
                                    if (formKey.currentState!.validate()) {
                                      setSheetState(
                                        () => isSheetLoading = true,
                                      );
                                      try {
                                        Navigator.pop(context);
                                        this.context.read<AuthBloc>().add(
                                          AuthVerifyOtpEvent(
                                            otp: otpController.text,
                                            email: emailController.text,
                                            password: passwordController.text,
                                          ),
                                        );
                                      } catch (e) {
                                        setSheetState(
                                          () => isSheetLoading = false,
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isSheetLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'VERIFY & EXECUTE RESET',
                                    style: TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleLogin() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in both email and password.',
            style: TextStyle(fontFamily: 'JetBrains Mono'),
          ),
          backgroundColor: AppTheme.surfaceContainer,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      AuthLoginEvent(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(fontFamily: 'JetBrains Mono'),
                ),
                backgroundColor: AppTheme.hardColor.withOpacity(0.8),
              ),
            );
          }
          setState(() => _isLoading = state is AuthLoading);
        },
        child: Stack(
          children: [
            // Matrix Grid overlay
            Positioned.fill(
              child: CustomPaint(painter: GridBackgroundPainter()),
            ),
            // Login Form Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 36,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Terminal icon logo with glow
                      SizedBox(height: 20),
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: const Color(0xFF13171e),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.12),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Image.asset(
                          "assets/database (1).png",
                          width: 72,
                          height: 72,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'jackdsql',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Welcome Back. Initialize session.',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 48),
                      // Core Box Form
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13171e),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.04),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email label
                            const Text(
                              'EMAIL ADDRESS',
                              style: TextStyle(
                                color: Colors.white54,
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Email field
                            TextField(
                              controller: _emailController,
                              enabled: !_isLoading,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'JetBrains Mono',
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFF090c10),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                hintText: 'admin@system.local',
                                hintStyle: const TextStyle(
                                  color: Colors.white24,
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 24),
                            // Password label + Reset key Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'PASSWORD',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _isLoading
                                      ? null
                                      : _showResetPasswordBottomSheet,
                                  child: const Text(
                                    'Reset key',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Password field
                            TextField(
                              controller: _passwordController,
                              enabled: !_isLoading,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'JetBrains Mono',
                                fontSize: 14,
                              ),
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFF090c10),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _isPasswordVisible =
                                        !_isPasswordVisible,
                                  ),
                                ),
                                hintText: '••••••••',
                                hintStyle: const TextStyle(
                                  color: Colors.white24,
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Action Button Execute Login
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(
                                        0.35,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.black,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'EXECUTE LOGIN',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontFamily: 'JetBrains Mono',
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward,
                                              color: Colors.black,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            // Divider OR
                            const Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white10)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: Colors.white24,
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white10)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Google Auth button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _handleGoogleSignIn,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color(0xFF090c10),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Custom G Icon
                                    Image.asset(
                                      'assets/google.png',
                                      width: 18,
                                      height: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Authenticate with Google',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Register account prompt
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No active instance? ',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: _isLoading ? null : _showRegisterBottomSheet,
                            child: const Text(
                              'Initialize account',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      // Bottom status indicator
                      // Bottom status indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isSystemOnline == null
                                  ? Colors.yellow
                                  : (_isSystemOnline!
                                        ? AppTheme.primaryColor
                                        : AppTheme.hardColor),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (_isSystemOnline == null
                                              ? Colors.yellow
                                              : (_isSystemOnline!
                                                    ? AppTheme.primaryColor
                                                    : AppTheme.hardColor))
                                          .withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isSystemOnline == null
                                ? 'Checking System...'
                                : (_isSystemOnline!
                                      ? 'System Online'
                                      : 'System Offline'),
                            style: TextStyle(
                              color: _isSystemOnline == null
                                  ? Colors.yellow.withOpacity(0.7)
                                  : (_isSystemOnline!
                                        ? Colors.white54
                                        : AppTheme.hardColor.withOpacity(0.8)),
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
