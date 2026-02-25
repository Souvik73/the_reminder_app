import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

part 'planner_models.g.dart';

@HiveType(typeId: 0)
enum ReminderPriority {
  @HiveField(0)
  high,
  @HiveField(1)
  medium,
  @HiveField(2)
  low,
}

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

@HiveType(typeId: 1)
class Reminder {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final String title;
  @HiveField(3)
  final String description;
  @HiveField(4)
  final DateTime scheduledAt;
  @HiveField(5)
  final ReminderPriority priority;
  @HiveField(6)
  final bool isVoiceCreated;
  @HiveField(7)
  final bool isGeofenced;
  @HiveField(8)
  final String? locationName;

  const Reminder({
    required this.id,
    required this.userId,
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
    String? userId,
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
      userId: userId ?? this.userId,
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

@HiveType(typeId: 2)
class AlarmEntry {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final TimeOfDay time;
  @HiveField(3)
  final String recurrence;
  @HiveField(4)
  final String label;

  const AlarmEntry({
    required this.id,
    required this.userId,
    required this.time,
    required this.recurrence,
    required this.label,
  });

  AlarmEntry copyWith({
    String? id,
    String? userId,
    TimeOfDay? time,
    String? recurrence,
    String? label,
  }) {
    return AlarmEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      time: time ?? this.time,
      recurrence: recurrence ?? this.recurrence,
      label: label ?? this.label,
    );
  }
}

@HiveType(typeId: 3)
class HydrationLog {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final int amount;
  @HiveField(3)
  final DateTime timestamp;

  const HydrationLog({
    required this.id,
    required this.userId,
    required this.amount,
    required this.timestamp,
  });
}

@HiveType(typeId: 4)
class AppUser {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String email;
  @HiveField(2)
  final String? displayName;
  @HiveField(3)
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    required this.createdAt,
  });

  AppUser copyWith({String? email, String? displayName}) {
    return AppUser(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt,
    );
  }
}
