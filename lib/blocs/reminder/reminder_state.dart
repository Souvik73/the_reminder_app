import 'package:equatable/equatable.dart';
import 'package:the_reminder_app/models/planner_models.dart';

class ReminderState extends Equatable {
  final List<Reminder> reminders;

  const ReminderState({
    required this.reminders,
  });

  factory ReminderState.initial() {
    final now = DateTime.now();
    final samples = <Reminder>[
      Reminder(
        id: 'r1',
        title: 'Team sync',
        description: 'Daily stand-up with product team at 10:30 AM.',
        scheduledAt: now.add(const Duration(hours: 3)),
        priority: ReminderPriority.high,
      ),
      Reminder(
        id: 'r2',
        title: 'Pick up groceries',
        description: 'Include fresh veggies for dinner tonight.',
        scheduledAt: now.add(const Duration(hours: 6)),
        priority: ReminderPriority.medium,
      ),
      Reminder(
        id: 'r3',
        title: 'Read and unwind',
        description: 'Finish one chapter of the current book.',
        scheduledAt: now.add(const Duration(hours: 13)),
        priority: ReminderPriority.low,
        isVoiceCreated: true,
      ),
    ];
    samples.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return ReminderState(reminders: samples);
  }

  ReminderState copyWith({
    List<Reminder>? reminders,
  }) {
    return ReminderState(
      reminders: reminders ?? this.reminders,
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
  List<Object?> get props => [reminders];
}
