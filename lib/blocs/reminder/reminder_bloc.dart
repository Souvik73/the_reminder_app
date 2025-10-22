import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/reminder/reminder_event.dart';
import 'package:the_reminder_app/blocs/reminder/reminder_state.dart';
import 'package:the_reminder_app/models/planner_models.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  ReminderBloc() : super(ReminderState.initial()) {
    on<ReminderUpserted>(_onReminderUpserted);
    on<ReminderDeleted>(_onReminderDeleted);
    on<ReminderCompleted>(_onReminderCompleted);
    on<ReminderCompletionUndone>(_onReminderCompletionUndone);
    on<ReminderCreatedFromText>(_onReminderCreatedFromText);
  }

  void _onReminderUpserted(ReminderUpserted event, Emitter<ReminderState> emit) {
    final updated = List<Reminder>.from(state.reminders);
    final index = updated.indexWhere((element) => element.id == event.reminder.id);
    if (index >= 0) {
      updated[index] = event.reminder;
    } else {
      updated.add(event.reminder);
    }
    updated.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    emit(state.copyWith(reminders: updated));
  }

  void _onReminderDeleted(ReminderDeleted event, Emitter<ReminderState> emit) {
    final updated = state.reminders.where((reminder) => reminder.id != event.reminderId).toList();
    emit(state.copyWith(reminders: updated));
  }

  void _onReminderCompleted(ReminderCompleted event, Emitter<ReminderState> emit) {
    final updated = state.reminders.where((reminder) => reminder.id != event.reminder.id).toList();
    emit(state.copyWith(reminders: updated));
  }

  void _onReminderCompletionUndone(
    ReminderCompletionUndone event,
    Emitter<ReminderState> emit,
  ) {
    final updated = List<Reminder>.from(state.reminders)..add(event.reminder);
    updated.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    emit(state.copyWith(reminders: updated));
  }

  void _onReminderCreatedFromText(
    ReminderCreatedFromText event,
    Emitter<ReminderState> emit,
  ) {
    final description = event.description.trim();
    if (description.isEmpty) {
      return;
    }
    final reminder = Reminder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: description,
      description: '',
      scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      priority: ReminderPriority.medium,
    );
    final updated = List<Reminder>.from(state.reminders)..add(reminder);
    updated.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    emit(state.copyWith(reminders: updated));
  }
}
