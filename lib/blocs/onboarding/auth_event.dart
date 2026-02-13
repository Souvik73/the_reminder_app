abstract class AuthEvent {}

class GoogleSignInRequested extends AuthEvent {}

class AppleSignInRequested extends AuthEvent {}

class EmailSignInRequested extends AuthEvent {
  final String email;
  final String password;

  EmailSignInRequested({required this.email, required this.password});
}

class SignOutRequested extends AuthEvent {}

class RestoreSessionRequested extends AuthEvent {}

class DeleteAccountRequested extends AuthEvent {}
