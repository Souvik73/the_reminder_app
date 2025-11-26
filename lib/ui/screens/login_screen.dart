import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:the_reminder_app/blocs/onboarding/auth_bloc.dart';
import 'package:the_reminder_app/blocs/onboarding/auth_event.dart';
import 'package:the_reminder_app/ui/widgets/auth_form_widget.dart';
import 'dart:io' show Platform;

import 'package:the_reminder_app/ui/widgets/social_login_widget.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _redirectIfAuthenticated(context.read<AuthBloc>().state);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          _redirectIfAuthenticated(state);
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFF6B73FF)],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Header Section
                    _buildHeader(),

                    // Login Form Section
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: _buildLoginForm(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _redirectIfAuthenticated(AuthState state) {
    if (state is AuthSuccess) {
      context.go("/");
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          // App Logo/Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(
              'assets/images/logo_trimmed.png',
              width: 68,
              height: 68,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 12),

          // App Name
          const Text(
            'Reminder App',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          // App Tagline
          Text(
            'Never miss what matters most',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withAlpha((0.8 * 255).toInt()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Welcome Text
              const Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Sign in to continue to your account',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Social Login Buttons
              SocialLoginWidget(
                onGooglePressed: () {
                  context.read<AuthBloc>().add(GoogleSignInRequested());
                },
                onApplePressed: Platform.isIOS
                    ? () {
                        context.read<AuthBloc>().add(AppleSignInRequested());
                      }
                    : null,
                isLoading: state is AuthLoading,
              ),

              const SizedBox(height: 30),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.grey[400], thickness: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Or continue with',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.grey[400], thickness: 1),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Email Login Form
              AuthFormWidget(
                isLoading: state is AuthLoading,
                onEmailLogin: (email, password) {
                  context.read<AuthBloc>().add(
                    EmailSignInRequested(email: email, password: password),
                  );
                },
                onCreateAccount: () {
                  context.push("/register_page");
                },
              ),

              const SizedBox(height: 30),

              // Terms and Privacy
              _buildTermsAndPrivacy(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTermsAndPrivacy() {
    return Column(
      children: [
        Text(
          'By signing in, you agree to our',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                // Navigate to terms
              },
              child: const Text(
                'Terms of Service',
                style: TextStyle(
                  color: Color(0xFF667eea),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              ' and ',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to privacy policy
              },
              child: const Text(
                'Privacy Policy',
                style: TextStyle(
                  color: Color(0xFF667eea),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
