import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/onboarding/auth_event.dart';
import 'package:the_reminder_app/data/local/auth_session_store.dart';
import 'package:the_reminder_app/data/remote/firebase_user_sync_service.dart';
import 'package:the_reminder_app/data/repositories/planner_repository.dart';
import 'package:the_reminder_app/models/planner_models.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required PlannerRepository plannerRepository,
    required FirebaseUserSyncService userSyncService,
    required AuthSessionStore sessionStore,
  }) : _plannerRepository = plannerRepository,
       _userSyncService = userSyncService,
       _sessionStore = sessionStore,
       super(AuthInitial()) {
    on<RestoreSessionRequested>(_handleRestoreSession);
    on<EmailSignInRequested>(_handleEmailSignIn);
    on<GoogleSignInRequested>(_handleSocialSignIn);
    on<AppleSignInRequested>(_handleSocialSignIn);
    on<SignOutRequested>(_handleSignOut);
    add(RestoreSessionRequested());
  }

  final PlannerRepository _plannerRepository;
  final FirebaseUserSyncService _userSyncService;
  final AuthSessionStore _sessionStore;

  Future<void> _handleEmailSignIn(
    EmailSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    final normalizedEmail = _normalizeEmail(event.email);
    if (normalizedEmail.isEmpty) {
      emit(AuthFailure(message: 'Please enter a valid email address.'));
      return;
    }

    emit(AuthLoading());
    try {
      // Replace with real authentication logic when backend is ready.
      await Future.delayed(const Duration(milliseconds: 800));
      final user = await _plannerRepository.ensureUser(
        userId: _buildUserIdFromEmail(normalizedEmail),
        email: normalizedEmail,
        displayName: _displayNameFromEmail(normalizedEmail),
      );
      await _userSyncService.syncLogin(user: user, loginMethod: 'email');
      await _sessionStore.save(
        AuthSession(
          userId: user.id,
          email: user.email,
          displayName: user.displayName,
        ),
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
        await _userSyncService.syncLogin(user: user, loginMethod: 'google');
        await _sessionStore.save(
          AuthSession(
            userId: user.id,
            email: user.email,
            displayName: user.displayName,
          ),
        );
        emit(AuthSuccess(userId: user.id, email: user.email));
      } else if (event is AppleSignInRequested) {
        final user = await _plannerRepository.ensureUser(
          userId: 'apple-user',
          email: 'apple-user@example.com',
          displayName: 'Apple User',
        );
        await _userSyncService.syncLogin(user: user, loginMethod: 'apple');
        await _sessionStore.save(
          AuthSession(
            userId: user.id,
            email: user.email,
            displayName: user.displayName,
          ),
        );
        emit(AuthSuccess(userId: user.id, email: user.email));
      } else {
        emit(AuthFailure(message: 'Unsupported sign in method.'));
      }
    } catch (error) {
      emit(AuthFailure(message: 'Social sign in failed. Please try again.'));
    }
  }

  Future<void> _handleSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _sessionStore.clear();
    emit(AuthInitial());
  }

  Future<void> _handleRestoreSession(
    RestoreSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final session = await _sessionStore.read();
      if (session == null) {
        return;
      }
      final user = await _plannerRepository.ensureUser(
        userId: session.userId,
        email: session.email,
        displayName: session.displayName,
      );
      emit(AuthSuccess(userId: user.id, email: user.email));
    } catch (_) {
      // Ignore restore failures to avoid blocking app launch.
    }
  }

  String _normalizeEmail(String rawEmail) => rawEmail.trim().toLowerCase();

  String _buildUserIdFromEmail(String normalizedEmail) {
    final safeEncoded =
        base64Url.encode(utf8.encode(normalizedEmail)).replaceAll('=', '');
    return 'email-$safeEncoded';
  }

  String? _displayNameFromEmail(String normalizedEmail) {
    if (!normalizedEmail.contains('@')) {
      return null;
    }
    final localPart = normalizedEmail.split('@').first;
    if (localPart.isEmpty) {
      return null;
    }
    final segments = localPart
        .split(RegExp(r'[.\-_]+'))
        .where((segment) => segment.isNotEmpty)
        .map((segment) =>
            '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}')
        .toList();
    if (segments.isEmpty) {
      return null;
    }
    return segments.join(' ');
  }
}
