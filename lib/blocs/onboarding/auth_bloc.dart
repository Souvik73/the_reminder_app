import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/onboarding/auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  bool isFirstPage = true;
  AuthBloc() : super(AuthInitial());
  
}