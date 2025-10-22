import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/hydration/hydration_state.dart';
import 'package:the_reminder_app/data/repositories/planner_repository.dart';
import 'package:the_reminder_app/models/planner_models.dart';

class HydrationCubit extends Cubit<HydrationState> {
  HydrationCubit({
    required PlannerRepository repository,
    required String initialUserId,
  }) : _repository = repository,
       super(HydrationState.initial(userId: initialUserId)) {
    _loadForUser(initialUserId);
  }

  final PlannerRepository _repository;

  Future<void> setActiveUser(String userId) async {
    if (userId == state.activeUserId && !state.isLoading) {
      return;
    }
    await _loadForUser(userId);
  }

  Future<void> setDailyGoal(int goal) async {
    if (goal <= 0) return;
    await _repository.setHydrationGoal(state.activeUserId, goal);
    emit(state.copyWith(dailyGoal: goal));
  }

  Future<void> logIntake(int amount) async {
    if (amount <= 0) return;
    final log = HydrationLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      userId: state.activeUserId,
      amount: amount,
      timestamp: DateTime.now(),
    );
    final updatedLogs = List<HydrationLog>.from(state.logs)..add(log);
    updatedLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    emit(state.copyWith(logs: updatedLogs));
    await _repository.addHydrationLog(log);
  }

  Future<void> removeLog(String logId) async {
    final updated = state.logs.where((log) => log.id != logId).toList();
    emit(state.copyWith(logs: updated));
    await _repository.removeHydrationLog(state.activeUserId, logId);
  }

  Future<void> _loadForUser(String userId) async {
    emit(state.copyWith(activeUserId: userId, isLoading: true));
    final goal = await _repository.getHydrationGoal(userId);
    final logs = await _repository.loadHydrationLogs(userId);
    emit(state.copyWith(dailyGoal: goal, logs: logs, isLoading: false));
  }
}
