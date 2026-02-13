import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _plannerRepository = plannerRepository,
       _userSyncService = userSyncService,
       _sessionStore = sessionStore,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       super(AuthInitial()) {
    on<RestoreSessionRequested>(_handleRestoreSession);
    on<EmailSignInRequested>(_handleEmailSignIn);
    on<GoogleSignInRequested>(_handleSocialSignIn);
    on<AppleSignInRequested>(_handleSocialSignIn);
    on<SignOutRequested>(_handleSignOut);
    on<DeleteAccountRequested>(_handleDeleteAccount);
    add(RestoreSessionRequested());
  }

  final PlannerRepository _plannerRepository;
  final FirebaseUserSyncService _userSyncService;
  final AuthSessionStore _sessionStore;
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  Future<void> _handleEmailSignIn(
    EmailSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    final normalizedEmail = _normalizeEmail(event.email);
    final displayName = _displayNameFromEmail(normalizedEmail);
    if (normalizedEmail.isEmpty) {
      emit(AuthFailure(message: 'Please enter a valid email address.'));
      return;
    }
    if (event.password.trim().isEmpty) {
      emit(AuthFailure(message: 'Please enter your password.'));
      return;
    }

    emit(AuthLoading());
    try {
      UserCredential userCredential;
      try {
        userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: event.password,
        );
      } on FirebaseAuthException catch (error) {
        if (error.code == 'user-not-found') {
          userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
            email: normalizedEmail,
            password: event.password,
          );
        } else {
          emit(AuthFailure(message: _messageForEmailAuthError(error)));
          return;
        }
      }
      final firebaseUser = userCredential.user;
      if (firebaseUser == null || firebaseUser.email == null) {
        emit(AuthFailure(message: 'Unable to read account details.'));
        return;
      }
      final user = await _plannerRepository.ensureUser(
        userId: firebaseUser.uid,
        email: firebaseUser.email!,
        displayName: firebaseUser.displayName ?? displayName,
      );
      final resolvedDisplayName =
          user.displayName ?? firebaseUser.displayName ?? displayName;
      await _syncLoginWithFallback(user: user, loginMethod: 'email');
      await _sessionStore.save(
        AuthSession(
          userId: user.id,
          email: user.email,
          displayName: resolvedDisplayName,
          photoUrl: null,
        ),
      );
      emit(
        AuthSuccess(
          userId: user.id,
          email: user.email,
          displayName: resolvedDisplayName,
        ),
      );
    } on FirebaseAuthException catch (error) {
      emit(AuthFailure(message: _messageForEmailAuthError(error)));
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
      if (event is GoogleSignInRequested) {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          emit(AuthInitial());
          return;
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final userCredential = await _firebaseAuth.signInWithCredential(
          credential,
        );
        final firebaseUser = userCredential.user;
        if (firebaseUser == null || firebaseUser.email == null) {
          throw FirebaseAuthException(
            code: 'missing-user',
            message: 'Unable to read Google account details',
          );
        }
        final displayName = firebaseUser.displayName ?? googleUser.displayName;
        final photoUrl = firebaseUser.photoURL ?? googleUser.photoUrl;
        final user = await _plannerRepository.ensureUser(
          userId: firebaseUser.uid,
          email: firebaseUser.email!,
          displayName: displayName,
        );
        final resolvedDisplayName = user.displayName ?? displayName;
        await _syncLoginWithFallback(user: user, loginMethod: 'google');
        await _sessionStore.save(
          AuthSession(
            userId: user.id,
            email: user.email,
            displayName: resolvedDisplayName,
            photoUrl: photoUrl,
          ),
        );
        emit(
          AuthSuccess(
            userId: user.id,
            email: user.email,
            displayName: resolvedDisplayName,
            photoUrl: photoUrl,
          ),
        );
      } else if (event is AppleSignInRequested) {
        const displayName = 'Apple User';
        final user = await _plannerRepository.ensureUser(
          userId: 'apple-user',
          email: 'apple-user@example.com',
          displayName: displayName,
        );
        await _syncLoginWithFallback(user: user, loginMethod: 'apple');
        await _sessionStore.save(
          AuthSession(
            userId: user.id,
            email: user.email,
            displayName: user.displayName ?? displayName,
            photoUrl: null,
          ),
        );
        emit(
          AuthSuccess(
            userId: user.id,
            email: user.email,
            displayName: user.displayName ?? displayName,
          ),
        );
      } else {
        emit(AuthFailure(message: 'Unsupported sign in method.'));
      }
    } catch (error) {
      debugPrint("Social sign in error: $error");
      emit(AuthFailure(message: 'Social sign in failed. Please try again.'));
    }
  }

  Future<void> _handleSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
      _sessionStore.clear(),
    ], eagerError: false);
    emit(AuthInitial());
  }

  Future<void> _handleDeleteAccount(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthSuccess) {
      emit(AuthFailure(message: 'No signed-in account to delete.'));
      return;
    }

    emit(AuthLoading());
    try {
      try {
        await _userSyncService.deleteUserData(currentState.userId);
      } catch (error) {
        debugPrint('Cloud user-data deletion skipped: $error');
      }

      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null && firebaseUser.uid == currentState.userId) {
        await firebaseUser.delete();
      }

      await _plannerRepository.deleteUserData(currentState.userId);

      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
        _sessionStore.clear(),
      ], eagerError: false);
      emit(AuthInitial());
    } on FirebaseAuthException catch (error) {
      if (error.code == 'requires-recent-login') {
        emit(
          AuthDeleteFailure(
            userId: currentState.userId,
            email: currentState.email,
            displayName: currentState.displayName,
            photoUrl: currentState.photoUrl,
            message: 'Please sign in again, then retry account deletion.',
          ),
        );
        return;
      }
      emit(
        AuthDeleteFailure(
          userId: currentState.userId,
          email: currentState.email,
          displayName: currentState.displayName,
          photoUrl: currentState.photoUrl,
          message: 'Failed to delete account. Please try again.',
        ),
      );
    } catch (error) {
      emit(
        AuthDeleteFailure(
          userId: currentState.userId,
          email: currentState.email,
          displayName: currentState.displayName,
          photoUrl: currentState.photoUrl,
          message: 'Failed to delete account. Please try again.',
        ),
      );
    }
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
      emit(
        AuthSuccess(
          userId: user.id,
          email: user.email,
          displayName: user.displayName ?? session.displayName,
          photoUrl: session.photoUrl,
        ),
      );
    } catch (_) {
      // Ignore restore failures to avoid blocking app launch.
    }
  }

  String _normalizeEmail(String rawEmail) => rawEmail.trim().toLowerCase();

  Future<void> _syncLoginWithFallback({
    required AppUser user,
    required String loginMethod,
  }) async {
    try {
      await _userSyncService.syncLogin(user: user, loginMethod: loginMethod);
    } on FirebaseException catch (error) {
      debugPrint(
        'Cloud sync skipped for $loginMethod login (code: ${error.code}).',
      );
    } catch (error) {
      debugPrint('Cloud sync skipped for $loginMethod login: $error');
    }
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
        .map(
          (segment) =>
              '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}',
        )
        .toList();
    if (segments.isEmpty) {
      return null;
    }
    return segments.join(' ');
  }

  String _messageForEmailAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'This email is already in use. Try signing in.';
      default:
        return 'Unable to sign in. Please try again.';
    }
  }
}
