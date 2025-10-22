import 'package:equatable/equatable.dart';
import 'package:the_reminder_app/models/planner_models.dart';

abstract class ReminderEvent extends Equatable {
  const ReminderEvent();

  @override
  List<Object?> get props => [];
}

class ReminderUserChanged extends ReminderEvent {
  final String userId;

  const ReminderUserChanged({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class ReminderUpserted extends ReminderEvent {
  final Reminder reminder;

  const ReminderUpserted({required this.reminder});

  @override
  List<Object?> get props => [reminder];
}

class ReminderDeleted extends ReminderEvent {
  final String reminderId;

  const ReminderDeleted({required this.reminderId});

  @override
  List<Object?> get props => [reminderId];
}

class ReminderCompleted extends ReminderEvent {
  final Reminder reminder;

  const ReminderCompleted({required this.reminder});

  @override
  List<Object?> get props => [reminder];
}

class ReminderCompletionUndone extends ReminderEvent {
  final Reminder reminder;

  const ReminderCompletionUndone({required this.reminder});

  @override
  List<Object?> get props => [reminder];
}

class ReminderCreatedFromText extends ReminderEvent {
  final String description;

  const ReminderCreatedFromText(this.description);

  @override
  List<Object?> get props => [description];
}
