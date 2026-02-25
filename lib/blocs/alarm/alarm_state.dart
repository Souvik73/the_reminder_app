import 'package:equatable/equatable.dart';
import 'package:the_reminder_app/models/planner_models.dart';

class AlarmState extends Equatable {
  final List<AlarmEntry> alarms;
  final String activeUserId;
  final bool isLoading;

  const AlarmState({
    required this.alarms,
    required this.activeUserId,
    required this.isLoading,
  });

  factory AlarmState.initial({required String userId}) {
    return AlarmState(alarms: const [], activeUserId: userId, isLoading: true);
  }

  AlarmState copyWith({
    List<AlarmEntry>? alarms,
    String? activeUserId,
    bool? isLoading,
  }) {
    return AlarmState(
      alarms: alarms ?? this.alarms,
      activeUserId: activeUserId ?? this.activeUserId,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [alarms, activeUserId, isLoading];
}
