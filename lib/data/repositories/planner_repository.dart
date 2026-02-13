import 'package:hive_ce/hive.dart';
import 'package:the_reminder_app/models/planner_models.dart';

class PlannerRepository {
  static const _usersBox = 'users';

  Future<void> warmUp() async {
    await _openBox<AppUser>(_usersBox);
  }

  Future<AppUser> ensureUser({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    final box = await _openBox<AppUser>(_usersBox);
    final existing = box.get(userId);
    if (existing != null) {
      if (email != existing.email || displayName != existing.displayName) {
        final updated = existing.copyWith(
          email: email,
          displayName: displayName,
        );
        await box.put(userId, updated);
        return updated;
      }
      return existing;
    }

    final user = AppUser(
      id: userId,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );
    await box.put(userId, user);
    return user;
  }

  Future<AppUser?> getUser(String userId) async {
    final box = await _openBox<AppUser>(_usersBox);
    return box.get(userId);
  }

  Future<List<Reminder>> loadReminders(String userId) async {
    final box = await _openReminderBox(userId);
    final reminders = box.values.toList();
    reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return reminders;
  }

  Future<void> saveReminder(Reminder reminder) async {
    final box = await _openReminderBox(reminder.userId);
    await box.put(reminder.id, reminder);
  }

  Future<void> deleteReminder(String userId, String reminderId) async {
    final box = await _openReminderBox(userId);
    await box.delete(reminderId);
  }

  Future<List<AlarmEntry>> loadAlarms(String userId) async {
    final box = await _openAlarmBox(userId);
    final alarms = box.values.toList();
    alarms.sort((a, b) {
      final aMinutes = a.time.hour * 60 + a.time.minute;
      final bMinutes = b.time.hour * 60 + b.time.minute;
      return aMinutes.compareTo(bMinutes);
    });
    return alarms;
  }

  Future<void> saveAlarm(AlarmEntry alarm) async {
    final box = await _openAlarmBox(alarm.userId);
    await box.put(alarm.id, alarm);
  }

  Future<void> deleteAlarm(String userId, String alarmId) async {
    final box = await _openAlarmBox(userId);
    await box.delete(alarmId);
  }

  Future<List<HydrationLog>> loadHydrationLogs(String userId) async {
    final box = await _openHydrationLogBox(userId);
    final logs = box.values.toList();
    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return logs;
  }

  Future<void> addHydrationLog(HydrationLog log) async {
    final box = await _openHydrationLogBox(log.userId);
    await box.put(log.id, log);
  }

  Future<void> removeHydrationLog(String userId, String logId) async {
    final box = await _openHydrationLogBox(userId);
    await box.delete(logId);
  }

  Future<int> getHydrationGoal(String userId) async {
    final box = await _openHydrationSettingsBox(userId);
    return box.get('dailyGoal', defaultValue: 2500) ?? 2500;
  }

  Future<void> setHydrationGoal(String userId, int goal) async {
    final box = await _openHydrationSettingsBox(userId);
    await box.put('dailyGoal', goal);
  }

  Future<void> deleteUserData(String userId) async {
    await _deleteBox('reminders_$userId');
    await _deleteBox('alarms_$userId');
    await _deleteBox('hydration_logs_$userId');
    await _deleteBox('hydration_settings_$userId');
    final users = await _openBox<AppUser>(_usersBox);
    await users.delete(userId);
  }

  Future<Box<Reminder>> _openReminderBox(String userId) {
    return _openBox<Reminder>('reminders_$userId');
  }

  Future<Box<AlarmEntry>> _openAlarmBox(String userId) {
    return _openBox<AlarmEntry>('alarms_$userId');
  }

  Future<Box<HydrationLog>> _openHydrationLogBox(String userId) {
    return _openBox<HydrationLog>('hydration_logs_$userId');
  }

  Future<Box<int>> _openHydrationSettingsBox(String userId) {
    return _openBox<int>('hydration_settings_$userId');
  }

  Future<Box<T>> _openBox<T>(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<T>(name);
    }
    return Hive.openBox<T>(name);
  }

  Future<void> _deleteBox(String name) async {
    if (Hive.isBoxOpen(name)) {
      await Hive.box(name).clear();
      await Hive.box(name).close();
    }
    await Hive.deleteBoxFromDisk(name);
  }
}
