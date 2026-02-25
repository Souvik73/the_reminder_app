import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:the_reminder_app/models/planner_models.dart';

/// Wraps the `alarm` plugin so alarms vibrate and display the full-screen UI.
class AlarmService {
  AlarmService({DateTime Function()? nowProvider})
    : _nowProvider = nowProvider ?? DateTime.now;

  final DateTime Function() _nowProvider;
  bool _initialized = false;

  // Use the plugin's bundled tone so we don't need to ship our own audio file.
  static const String _defaultAlarmAsset = 'packages/alarm/assets/not_blank.mp3';

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    await Alarm.init();
    await Alarm.setWarningNotificationOnKill(
      'Keep alarms running',
      'Re-open the app if your alarms stop ringing.',
    );

    _initialized = true;
  }

  Future<bool> scheduleAlarm(AlarmEntry entry) async {
    if (kIsWeb) return false;
    await init();
    if (!_initialized) return false;

    final DateTime? triggerAt = _nextTriggerTime(entry);
    if (triggerAt == null) return false;

    final settings = AlarmSettings(
      id: _alarmId(entry.id),
      dateTime: triggerAt,
      assetAudioPath: _defaultAlarmAsset,
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      warningNotificationOnKill: true,
      payload: entry.id,
      notificationSettings: NotificationSettings(
        title: entry.label,
        body: _notificationBody(entry),
        stopButton: 'Stop alarm',
      ),
      volumeSettings: VolumeSettings.fade(
        fadeDuration: Duration(seconds: 4),
        volume: 0.8,
        volumeEnforced: true,
      ),
    );

    try {
      return await Alarm.set(alarmSettings: settings);
    } catch (error, stackTrace) {
      debugPrint('Failed to schedule alarm ${entry.id}: $error');
      debugPrint('$stackTrace');
      return false;
    }
  }

  Future<void> cancelAlarm(String alarmId) async {
    if (kIsWeb) return;
    await init();
    if (!_initialized) return;
    await Alarm.stop(_alarmId(alarmId));
  }

  Future<void> syncAlarms(List<AlarmEntry> alarms) async {
    if (kIsWeb) return;
    await init();
    if (!_initialized) return;

    final desiredIds = alarms.map((alarm) => _alarmId(alarm.id)).toSet();
    final scheduled = await Alarm.getAlarms();
    for (final alarm in scheduled) {
      if (!desiredIds.contains(alarm.id)) {
        await Alarm.stop(alarm.id);
      }
    }

    for (final alarm in alarms) {
      await scheduleAlarm(alarm);
    }
  }

  DateTime? _nextTriggerTime(AlarmEntry entry) {
    final now = _nowProvider();
    final normalizedRecurrence = entry.recurrence.trim().toLowerCase();

    int intervalDays = 1;
    if (normalizedRecurrence == 'weekly') {
      intervalDays = 7;
    } else {
      final customInterval = _parseCustomIntervalDays(normalizedRecurrence);
      intervalDays = customInterval > 0 ? customInterval : 1;
    }

    DateTime candidate = DateTime(
      now.year,
      now.month,
      now.day,
      entry.time.hour,
      entry.time.minute,
    );

    while (!candidate.isAfter(now)) {
      candidate = candidate.add(Duration(days: intervalDays));
    }

    if (normalizedRecurrence == 'weekdays') {
      while (candidate.weekday == DateTime.saturday ||
          candidate.weekday == DateTime.sunday) {
        candidate = candidate.add(const Duration(days: 1));
      }
    } else if (normalizedRecurrence == 'weekends') {
      while (candidate.weekday != DateTime.saturday &&
          candidate.weekday != DateTime.sunday) {
        candidate = candidate.add(const Duration(days: 1));
      }
    }

    return candidate;
  }

  int _parseCustomIntervalDays(String recurrence) {
    final match = RegExp(r'every\s+(\d+)\s+day', caseSensitive: false)
        .firstMatch(recurrence);
    if (match != null) {
      final parsed = int.tryParse(match.group(1) ?? '');
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
    return 1;
  }

  int _alarmId(String id) {
    final numeric = int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), ''));
    final hashed = (numeric ?? id.hashCode) & 0x7fffffff;
    return hashed == 0 ? 1 : hashed;
  }

  String _notificationBody(AlarmEntry entry) {
    final timeLabel = _formatTime(entry.time);
    final recurrence = entry.recurrence.trim().isEmpty
        ? 'One-time'
        : entry.recurrence;
    return '$recurrence • $timeLabel';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }
}
