import 'package:equatable/equatable.dart';
import 'package:the_reminder_app/models/planner_models.dart';

class ReminderState extends Equatable {
  final List<Reminder> reminders;
  final String activeUserId;
  final bool isLoading;

  const ReminderState({
    required this.reminders,
    required this.activeUserId,
    required this.isLoading,
  });

  factory ReminderState.initial(String userId) {
    return ReminderState(
      reminders: const [],
      activeUserId: userId,
      isLoading: true,
    );
  }

  ReminderState copyWith({
    List<Reminder>? reminders,
    String? activeUserId,
    bool? isLoading,
  }) {
    return ReminderState(
      reminders: reminders ?? this.reminders,
      activeUserId: activeUserId ?? this.activeUserId,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<Reminder> get activeReminders => reminders;

  Map<ReminderPriority, List<Reminder>> get remindersByPriority {
    final grouped = <ReminderPriority, List<Reminder>>{
      ReminderPriority.high: [],
      ReminderPriority.medium: [],
      ReminderPriority.low: [],
    };
    for (final reminder in reminders) {
      grouped[reminder.priority]?.add(reminder);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    }
    return grouped;
  }

  @override
  List<Object?> get props => [reminders, activeUserId, isLoading];
}
