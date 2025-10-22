import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/pomodoro/pomodoro_state.dart';

class PomodoroCubit extends Cubit<PomodoroState> {
  PomodoroCubit() : super(PomodoroState.initial());

  void selectPreset(String preset) {
    if (!PomodoroState.presets.contains(preset)) return;
    switch (preset) {
      case '15/5 min':
        emit(state.copyWith(
          selectedPreset: preset,
          workDuration: const Duration(minutes: 15),
          restDuration: const Duration(minutes: 5),
        ));
        break;
      case '50/10 min':
        emit(state.copyWith(
          selectedPreset: preset,
          workDuration: const Duration(minutes: 50),
          restDuration: const Duration(minutes: 10),
        ));
        break;
      case 'Custom':
        final customWork = state.customWorkDuration ?? const Duration(minutes: 25);
        final customRest = state.customRestDuration ?? const Duration(minutes: 5);
        emit(state.copyWith(
          selectedPreset: preset,
          workDuration: customWork,
          restDuration: customRest,
        ));
        break;
      case '25/5 min':
      default:
        emit(state.copyWith(
          selectedPreset: '25/5 min',
          workDuration: const Duration(minutes: 25),
          restDuration: const Duration(minutes: 5),
        ));
    }
  }

  void setCustomDurations(Duration work, Duration rest) {
    emit(state.copyWith(
      customWorkDuration: work,
      customRestDuration: rest,
      selectedPreset: 'Custom',
      workDuration: work,
      restDuration: rest,
    ));
  }
}
