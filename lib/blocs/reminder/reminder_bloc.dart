import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/reminder/reminder_event.dart';
import 'package:the_reminder_app/blocs/reminder/reminder_state.dart';
import 'package:the_reminder_app/data/repositories/planner_repository.dart';
import 'package:the_reminder_app/models/planner_models.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  ReminderBloc({
    required PlannerRepository repository,
    required String initialUserId,
  }) : _repository = repository,
       super(ReminderState.initial(initialUserId)) {
    on<ReminderUserChanged>(_onReminderUserChanged);
    on<ReminderUpserted>(_onReminderUpserted);
    on<ReminderDeleted>(_onReminderDeleted);
    on<ReminderCompleted>(_onReminderCompleted);
    on<ReminderCompletionUndone>(_onReminderCompletionUndone);
    on<ReminderCreatedFromText>(_onReminderCreatedFromText);

    add(ReminderUserChanged(userId: initialUserId));
  }

  final PlannerRepository _repository;

  void setActiveUser(String userId) {
    add(ReminderUserChanged(userId: userId));
  }

  Future<void> _onReminderUserChanged(
    ReminderUserChanged event,
    Emitter<ReminderState> emit,
  ) async {
    emit(state.copyWith(activeUserId: event.userId, isLoading: true));
    final reminders = await _repository.loadReminders(event.userId);
    emit(state.copyWith(reminders: reminders, isLoading: false));
  }

  Future<void> _onReminderUpserted(
    ReminderUpserted event,
    Emitter<ReminderState> emit,
  ) async {
    final reminder = _ensureReminderUser(event.reminder);
    final updated = List<Reminder>.from(state.reminders);
    final index = updated.indexWhere((element) => element.id == reminder.id);
    if (index >= 0) {
      updated[index] = reminder;
    } else {
      updated.add(reminder);
    }
    updated.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    emit(state.copyWith(reminders: updated));
    await _repository.saveReminder(reminder);
  }

  Future<void> _onReminderDeleted(
    ReminderDeleted event,
    Emitter<ReminderState> emit,
  ) async {
    final updated = state.reminders
        .where((reminder) => reminder.id != event.reminderId)
        .toList();
    emit(state.copyWith(reminders: updated));
    await _repository.deleteReminder(state.activeUserId, event.reminderId);
  }

  Future<void> _onReminderCompleted(
    ReminderCompleted event,
    Emitter<ReminderState> emit,
  ) async {
    final updated = state.reminders
        .where((reminder) => reminder.id != event.reminder.id)
        .toList();
    emit(state.copyWith(reminders: updated));
    await _repository.deleteReminder(state.activeUserId, event.reminder.id);
  }

  Future<void> _onReminderCompletionUndone(
    ReminderCompletionUndone event,
    Emitter<ReminderState> emit,
  ) async {
    final reminder = _ensureReminderUser(event.reminder);
    final updated = List<Reminder>.from(state.reminders)..add(reminder);
    updated.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    emit(state.copyWith(reminders: updated));
    await _repository.saveReminder(reminder);
  }

  Future<void> _onReminderCreatedFromText(
    ReminderCreatedFromText event,
    Emitter<ReminderState> emit,
  ) async {
    final description = event.description.trim();
    if (description.isEmpty) {
      return;
    }
    final reminder = Reminder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      userId: state.activeUserId,
      title: description,
      description: '',
      scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      priority: ReminderPriority.medium,
    );
    final updated = List<Reminder>.from(state.reminders)..add(reminder);
    updated.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    emit(state.copyWith(reminders: updated));
    await _repository.saveReminder(reminder);
  }

  Reminder _ensureReminderUser(Reminder reminder) {
    if (reminder.userId == state.activeUserId) {
      return reminder;
    }
    return reminder.copyWith(userId: state.activeUserId);
  }
}
