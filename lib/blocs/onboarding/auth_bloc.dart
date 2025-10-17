import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/onboarding/auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<EmailSignInRequested>(_handleEmailSignIn);
    on<GoogleSignInRequested>(_handleSocialSignIn);
    on<AppleSignInRequested>(_handleSocialSignIn);
    on<SignOutRequested>(_handleSignOut);
  }

  Future<void> _handleEmailSignIn(
    EmailSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Replace with real authentication logic when backend is ready.
      await Future.delayed(const Duration(milliseconds: 800));
      emit(AuthSuccess(userId: 'mock-user', email: event.email));
    } catch (error) {
      emit(AuthFailure(message: 'Unable to sign in. Please try again.'));
    }
  }

  Future<void> _handleSocialSignIn(
    AuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 600));

      if (event is GoogleSignInRequested) {
        emit(AuthSuccess(userId: 'google-user', email: 'google-user@example.com'));
      } else if (event is AppleSignInRequested) {
        emit(AuthSuccess(userId: 'apple-user', email: 'apple-user@example.com'));
      } else {
        emit(AuthFailure(message: 'Unsupported sign in method.'));
      }
    } catch (error) {
      emit(AuthFailure(message: 'Social sign in failed. Please try again.'));
    }
  }

  void _handleSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthInitial());
  }
}
