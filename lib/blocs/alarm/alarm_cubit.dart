import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/alarm/alarm_state.dart';
import 'package:the_reminder_app/models/planner_models.dart';

class AlarmCubit extends Cubit<AlarmState> {
  AlarmCubit() : super(AlarmState.initial());

  void upsertAlarm(AlarmEntry alarm) {
    final updated = List<AlarmEntry>.from(state.alarms);
    final index = updated.indexWhere((element) => element.id == alarm.id);
    if (index >= 0) {
      updated[index] = alarm;
    } else {
      updated.add(alarm);
    }
    emit(state.copyWith(alarms: updated));
  }

  void deleteAlarm(String alarmId) {
    final updated = state.alarms.where((alarm) => alarm.id != alarmId).toList();
    emit(state.copyWith(alarms: updated));
  }
}
