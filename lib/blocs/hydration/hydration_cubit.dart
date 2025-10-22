import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/hydration/hydration_state.dart';
import 'package:the_reminder_app/models/planner_models.dart';

class HydrationCubit extends Cubit<HydrationState> {
  HydrationCubit() : super(HydrationState.initial());

  void setDailyGoal(int goal) {
    if (goal <= 0) return;
    emit(state.copyWith(dailyGoal: goal));
  }

  void logIntake(int amount) {
    if (amount <= 0) return;
    final updatedLogs = List<HydrationLog>.from(state.logs)
      ..add(
        HydrationLog(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          amount: amount,
          timestamp: DateTime.now(),
        ),
      );
    emit(state.copyWith(logs: updatedLogs));
  }
}
