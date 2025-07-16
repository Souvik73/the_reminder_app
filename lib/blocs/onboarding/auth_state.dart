part of 'auth_bloc.dart';



// lib/features/authentication/presentation/bloc/auth_state.dart

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String userId;
  final String email;

  AuthSuccess({required this.userId, required this.email});
}

class AuthFailure extends AuthState {
  final String message;

  AuthFailure({required this.message});
}