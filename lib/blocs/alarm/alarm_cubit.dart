import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/alarm/alarm_state.dart';
import 'package:the_reminder_app/data/repositories/planner_repository.dart';
import 'package:the_reminder_app/models/planner_models.dart';

class AlarmCubit extends Cubit<AlarmState> {
  AlarmCubit({
    required PlannerRepository repository,
    required String initialUserId,
  }) : _repository = repository,
       super(AlarmState.initial(userId: initialUserId)) {
    _loadForUser(initialUserId);
  }

  final PlannerRepository _repository;

  Future<void> setActiveUser(String userId) async {
    if (userId == state.activeUserId && !state.isLoading) {
      return;
    }
    await _loadForUser(userId);
  }

  Future<void> upsertAlarm(AlarmEntry alarm) async {
    final userAligned = _ensureAlarmUser(alarm);
    final updated = List<AlarmEntry>.from(state.alarms);
    final index = updated.indexWhere((element) => element.id == userAligned.id);
    if (index >= 0) {
      updated[index] = userAligned;
    } else {
      updated.add(userAligned);
    }
    updated.sort((a, b) {
      final aMinutes = a.time.hour * 60 + a.time.minute;
      final bMinutes = b.time.hour * 60 + b.time.minute;
      return aMinutes.compareTo(bMinutes);
    });
    emit(state.copyWith(alarms: updated));
    await _repository.saveAlarm(userAligned);
  }

  Future<void> deleteAlarm(String alarmId) async {
    final updated = state.alarms.where((alarm) => alarm.id != alarmId).toList();
    emit(state.copyWith(alarms: updated));
    await _repository.deleteAlarm(state.activeUserId, alarmId);
  }

  Future<void> _loadForUser(String userId) async {
    emit(state.copyWith(activeUserId: userId, isLoading: true));
    final alarms = await _repository.loadAlarms(userId);
    emit(state.copyWith(alarms: alarms, isLoading: false));
  }

  AlarmEntry _ensureAlarmUser(AlarmEntry alarm) {
    if (alarm.userId == state.activeUserId) {
      return alarm;
    }
    return alarm.copyWith(userId: state.activeUserId);
  }
}
