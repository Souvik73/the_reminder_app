part of 'auth_bloc.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String userId;
  final String email;
  final String? displayName;
  final String? photoUrl;

  AuthSuccess({
    required this.userId,
    required this.email,
    this.displayName,
    this.photoUrl,
  });
}

class AuthDeleteFailure extends AuthSuccess {
  final String message;

  AuthDeleteFailure({
    required super.userId,
    required super.email,
    required this.message,
    super.displayName,
    super.photoUrl,
  });
}

class AuthFailure extends AuthState {
  final String message;

  AuthFailure({required this.message});
}
