import 'package:flutter/material.dart';

enum ReminderPriority { high, medium, low }

extension ReminderPriorityLabel on ReminderPriority {
  String get label {
    switch (this) {
      case ReminderPriority.high:
        return 'High';
      case ReminderPriority.medium:
        return 'Medium';
      case ReminderPriority.low:
        return 'Low';
    }
  }

  Color get color {
    switch (this) {
      case ReminderPriority.high:
        return Colors.redAccent;
      case ReminderPriority.medium:
        return Colors.orangeAccent;
      case ReminderPriority.low:
        return Colors.teal;
    }
  }
}

class Reminder {
  final String id;
  final String title;
  final String description;
  final DateTime scheduledAt;
  final ReminderPriority priority;
  final bool isVoiceCreated;
  final bool isGeofenced;
  final String? locationName;

  const Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledAt,
    required this.priority,
    this.isVoiceCreated = false,
    this.isGeofenced = false,
    this.locationName,
  });

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? scheduledAt,
    ReminderPriority? priority,
    bool? isVoiceCreated,
    bool? isGeofenced,
    String? locationName,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      priority: priority ?? this.priority,
      isVoiceCreated: isVoiceCreated ?? this.isVoiceCreated,
      isGeofenced: isGeofenced ?? this.isGeofenced,
      locationName: locationName ?? this.locationName,
    );
  }
}

class AlarmEntry {
  final String id;
  final TimeOfDay time;
  final String recurrence;
  final String label;

  const AlarmEntry({
    required this.id,
    required this.time,
    required this.recurrence,
    required this.label,
  });

  AlarmEntry copyWith({
    String? id,
    TimeOfDay? time,
    String? recurrence,
    String? label,
  }) {
    return AlarmEntry(
      id: id ?? this.id,
      time: time ?? this.time,
      recurrence: recurrence ?? this.recurrence,
      label: label ?? this.label,
    );
  }
}

class HydrationLog {
  final String id;
  final int amount;
  final DateTime timestamp;

  const HydrationLog({
    required this.id,
    required this.amount,
    required this.timestamp,
  });
}
