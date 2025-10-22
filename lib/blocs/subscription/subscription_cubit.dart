import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/subscription/subscription_state.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit() : super(SubscriptionState.initial());

  void upgrade() {
    emit(state.copyWith(isPremium: true));
  }

  void downgrade() {
    emit(state.copyWith(isPremium: false));
  }
}
