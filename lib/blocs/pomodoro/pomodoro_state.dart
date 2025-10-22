import 'package:equatable/equatable.dart';

class PomodoroState extends Equatable {
  final String selectedPreset;
  final Duration workDuration;
  final Duration restDuration;
  final Duration? customWorkDuration;
  final Duration? customRestDuration;

  static const presets = ['25/5 min', '15/5 min', '50/10 min', 'Custom'];

  const PomodoroState({
    required this.selectedPreset,
    required this.workDuration,
    required this.restDuration,
    this.customWorkDuration,
    this.customRestDuration,
  });

  factory PomodoroState.initial() => const PomodoroState(
    selectedPreset: '25/5 min',
    workDuration: Duration(minutes: 25),
    restDuration: Duration(minutes: 5),
  );

  PomodoroState copyWith({
    String? selectedPreset,
    Duration? workDuration,
    Duration? restDuration,
    Duration? customWorkDuration,
    Duration? customRestDuration,
  }) {
    return PomodoroState(
      selectedPreset: selectedPreset ?? this.selectedPreset,
      workDuration: workDuration ?? this.workDuration,
      restDuration: restDuration ?? this.restDuration,
      customWorkDuration: customWorkDuration ?? this.customWorkDuration,
      customRestDuration: customRestDuration ?? this.customRestDuration,
    );
  }

  @override
  List<Object?> get props => [
    selectedPreset,
    workDuration,
    restDuration,
    customWorkDuration,
    customRestDuration,
  ];
}
