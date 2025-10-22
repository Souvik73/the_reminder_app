import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:the_reminder_app/models/planner_models.dart';

class AlarmState extends Equatable {
  final List<AlarmEntry> alarms;

  const AlarmState({
    required this.alarms,
  });

  factory AlarmState.initial() {
    return const AlarmState(
      alarms: [
        AlarmEntry(
          id: 'a1',
          time: TimeOfDay(hour: 7, minute: 0),
          recurrence: 'Daily',
          label: 'Morning routine',
        ),
        AlarmEntry(
          id: 'a2',
          time: TimeOfDay(hour: 21, minute: 30),
          recurrence: 'Every 2 days',
          label: 'Medication check',
        ),
      ],
    );
  }

  AlarmState copyWith({
    List<AlarmEntry>? alarms,
  }) {
    return AlarmState(
      alarms: alarms ?? this.alarms,
    );
  }

  @override
  List<Object?> get props => [alarms];
}
