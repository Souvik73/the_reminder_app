import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/onboarding/auth_event.dart';
import 'package:the_reminder_app/data/repositories/planner_repository.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required PlannerRepository plannerRepository})
    : _plannerRepository = plannerRepository,
      super(AuthInitial()) {
    on<EmailSignInRequested>(_handleEmailSignIn);
    on<GoogleSignInRequested>(_handleSocialSignIn);
    on<AppleSignInRequested>(_handleSocialSignIn);
    on<SignOutRequested>(_handleSignOut);
  }

  final PlannerRepository _plannerRepository;

  Future<void> _handleEmailSignIn(
    EmailSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Replace with real authentication logic when backend is ready.
      await Future.delayed(const Duration(milliseconds: 800));
      final user = await _plannerRepository.ensureUser(
        userId: 'mock-user',
        email: event.email,
      );
      emit(AuthSuccess(userId: user.id, email: user.email));
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
        final user = await _plannerRepository.ensureUser(
          userId: 'google-user',
          email: 'google-user@example.com',
          displayName: 'Google User',
        );
        emit(AuthSuccess(userId: user.id, email: user.email));
      } else if (event is AppleSignInRequested) {
        final user = await _plannerRepository.ensureUser(
          userId: 'apple-user',
          email: 'apple-user@example.com',
          displayName: 'Apple User',
        );
        emit(AuthSuccess(userId: user.id, email: user.email));
      } else {
        emit(AuthFailure(message: 'Unsupported sign in method.'));
      }
    } catch (error) {
      emit(AuthFailure(message: 'Social sign in failed. Please try again.'));
    }
  }

  void _handleSignOut(SignOutRequested event, Emitter<AuthState> emit) {
    emit(AuthInitial());
  }
}
