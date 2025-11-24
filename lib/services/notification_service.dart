import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:the_reminder_app/models/planner_models.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Result from attempting to schedule a reminder notification.
enum NotificationScheduleResult {
  scheduledExact,
  scheduledWithInexactFallback,
  failed,
}

/// Handles initializing and scheduling reminder notifications with the
/// `flutter_local_notifications` plugin.
class NotificationService {
  NotificationService() : _notificationsPlugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  static const MethodChannel _timezoneChannel =
      MethodChannel('the_reminder_app/timezone');
  bool _initialized = false;
  bool _timeZoneInitialized = false;

  static const String _reminderChannelId = 'reminders_channel';
  static const String _reminderChannelName = 'Reminders';
  static const String _reminderChannelDescription =
      'Notifications that fire when reminders are due.';
  static const String _reminderPayloadPrefix = 'reminder:';
  static const String _defaultTimeZoneName = 'Asia/Kolkata';

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    await _ensureTimeZoneData();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _notificationsPlugin.initialize(initializationSettings);
    await _requestPermissions();
    await _logStatusDebug('init');
    _initialized = true;
  }

  Future<NotificationScheduleResult> scheduleReminder(Reminder reminder) async {
    if (kIsWeb) {
      return NotificationScheduleResult.failed;
    }
    await init();
    if (!_initialized) {
      return NotificationScheduleResult.failed;
    }
    final hasPermission = await _ensureNotificationPermission();
    if (!hasPermission) {
      debugPrint(
        'Notification permission denied; skipping schedule for reminder '
        '${reminder.id}.',
      );
      return NotificationScheduleResult.failed;
    }

    if (reminder.scheduledAt.isBefore(DateTime.now())) {
      // Reminder already elapsed. Ensure any pending notification is cancelled.
      await cancelReminder(reminder.id);
      return NotificationScheduleResult.scheduledExact;
    }
    
    final tz.Location targetTimeZone = tz.getLocation(_defaultTimeZoneName);
    // Use the configured local timezone (populated from platform; falls back to IST).
    final tz.TZDateTime scheduledTime =
        tz.TZDateTime.from(reminder.scheduledAt, targetTimeZone);

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _reminderChannelId,
        _reminderChannelName,
        channelDescription: _reminderChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        styleInformation: reminder.description.isEmpty
            ? null
            : BigTextStyleInformation(reminder.description),
      ),
      iOS: const DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.timeSensitive,
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    AndroidScheduleMode scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    bool requiresExactAlarmPermission = false;
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      final bool? canScheduleExact =
          await androidImplementation.canScheduleExactNotifications();
      if (canScheduleExact == false) {
        requiresExactAlarmPermission = true;
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      }
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        _notificationId(reminder.id),
        reminder.title,
        reminder.description.isEmpty ? 'Reminder due now' : reminder.description,
        scheduledTime,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        payload: '$_reminderPayloadPrefix${reminder.id}',
      );
      await _logStatusDebug('scheduled:${reminder.id}');
      return requiresExactAlarmPermission
          ? NotificationScheduleResult.scheduledWithInexactFallback
          : NotificationScheduleResult.scheduledExact;
    } on PlatformException catch (error, stackTrace) {
      if (scheduleMode == AndroidScheduleMode.exactAllowWhileIdle &&
          error.code == 'exact_alarms_not_permitted') {
        try {
          await _notificationsPlugin.zonedSchedule(
            _notificationId(reminder.id),
            reminder.title,
            reminder.description.isEmpty
                ? 'Reminder due now'
                : reminder.description,
            scheduledTime,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: '$_reminderPayloadPrefix${reminder.id}',
          );
          await _logStatusDebug('scheduled-fallback:${reminder.id}');
          return NotificationScheduleResult.scheduledWithInexactFallback;
        } catch (fallbackError, fallbackStack) {
          debugPrint(
            'Fallback scheduling failed for reminder ${reminder.id}: $fallbackError',
          );
          debugPrint('$fallbackStack');
        }
      } else {
        debugPrint(
          'Failed to schedule reminder ${reminder.id}: $error',
        );
        debugPrint('$stackTrace');
      }
    } catch (error, stackTrace) {
      debugPrint('Unexpected error scheduling reminder ${reminder.id}: $error');
      debugPrint('$stackTrace');
    }
    return NotificationScheduleResult.failed;
  }

  /// Fire an immediate, one-off notification to verify device delivery.
  Future<void> triggerDebugNotification({
    String? title,
    String? body,
  }) async {
    if (kIsWeb) return;
    await init();
    if (!_initialized) return;
    final hasPermission = await _ensureNotificationPermission();
    if (!hasPermission) {
      debugPrint('Notification permission denied; debug notification skipped.');
      return;
    }

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _reminderChannelId,
        _reminderChannelName,
        channelDescription: _reminderChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      ),
      iOS: const DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.timeSensitive,
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final int id = DateTime.now().millisecondsSinceEpoch % 0x7fffffff;
    await _notificationsPlugin.show(
      id,
      title ?? 'Test notification',
      body ?? 'If you see this, local notifications are working.',
      notificationDetails,
      payload: '${_reminderPayloadPrefix}debug',
    );
    await _logStatusDebug('debug-show:$id');
  }

  Future<void> cancelReminder(String reminderId) async {
    if (kIsWeb) return;
    await init();
    if (!_initialized) return;

    await _notificationsPlugin.cancel(_notificationId(reminderId));
  }

  Future<bool> syncReminderSchedules(List<Reminder> reminders) async {
    if (kIsWeb) return false;
    await init();
    if (!_initialized) return false;

    final desiredIds = reminders.map((reminder) => reminder.id).toSet();
    final pending = await _notificationsPlugin.pendingNotificationRequests();

    for (final request in pending) {
      final payload = request.payload ?? '';
      if (payload.startsWith(_reminderPayloadPrefix)) {
        final reminderId = payload.substring(_reminderPayloadPrefix.length);
        if (!desiredIds.contains(reminderId)) {
          await _notificationsPlugin.cancel(request.id);
        }
      }
    }

    bool warnedAboutExactAlarmPermission = false;
    for (final reminder in reminders) {
      final result = await scheduleReminder(reminder);
      if (result == NotificationScheduleResult.scheduledWithInexactFallback) {
        warnedAboutExactAlarmPermission = true;
      }
    }
    return warnedAboutExactAlarmPermission;
  }

  Future<void> _ensureTimeZoneData() async {
    if (_timeZoneInitialized || kIsWeb) return;

    tz.initializeTimeZones();
    await _configureLocalTimeZone();
    // If for any reason the platform lookup failed and tz.local stayed UTC,
    // fall back to IST to avoid misfiring schedules.
    if (tz.local.name == 'UTC') {
      tz.setLocalLocation(tz.getLocation(_defaultTimeZoneName));
      debugPrint(
        '[NotificationService] tz.local was UTC after configure; '
        'falling back to $_defaultTimeZoneName',
      );
    }
    _timeZoneInitialized = true;
  }

  Future<void> _requestPermissions() async {
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();

    final iosImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final macImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
    await macImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<bool> _ensureNotificationPermission() async {
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final bool? androidEnabled =
        await androidImplementation?.areNotificationsEnabled();
    if (androidEnabled == false) {
      await androidImplementation!.requestNotificationsPermission();
      final bool? retried =
          await androidImplementation.areNotificationsEnabled();
      if (retried == false) {
        return false;
      }
    }

    final iosImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    final iosPermissions = await iosImplementation?.checkPermissions();
    if (iosPermissions != null && iosPermissions.isEnabled == false) {
      final bool? granted = await iosImplementation!.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted == false) {
        return false;
      }
    }

    final macImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
    final macPermissions = await macImplementation?.checkPermissions();
    if (macPermissions != null && macPermissions.isEnabled == false) {
      final bool? granted = await macImplementation!.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted == false) {
        return false;
      }
    }

    return true;
  }

  Future<void> openExactAlarmPermissionSettings() async {
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  int _notificationId(String reminderId) {
    final numeric = int.tryParse(reminderId.replaceAll(RegExp(r'[^0-9]'), ''));
    if (numeric != null) {
      return numeric % 0x7fffffff;
    }
    return reminderId.hashCode & 0x7fffffff;
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final String? localTimeZone =
          await _timezoneChannel.invokeMethod<String>('getTimeZone');
      if (localTimeZone != null && localTimeZone.isNotEmpty) {
        tz.setLocalLocation(tz.getLocation(localTimeZone));
        return;
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to determine timezone: $error');
      debugPrint('$stackTrace');
    }
    tz.setLocalLocation(tz.getLocation(_defaultTimeZoneName));
  }

  Future<void> _logStatusDebug(String context) async {
    if (kIsWeb) return;
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final iosImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    final macImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
    final bool? androidEnabled =
        await androidImplementation?.areNotificationsEnabled();
    final bool? canScheduleExact =
        await androidImplementation?.canScheduleExactNotifications();
    final iosPermissions = await iosImplementation?.checkPermissions();
    final macPermissions = await macImplementation?.checkPermissions();
    final pending =
        await _notificationsPlugin.pendingNotificationRequests().catchError(
              (_) => <PendingNotificationRequest>[],
            );

    debugPrint(
      '[NotificationService:$context] '
      'androidEnabled=$androidEnabled '
      'canScheduleExact=$canScheduleExact '
      'iosEnabled=${iosPermissions?.isEnabled} '
      'macEnabled=${macPermissions?.isEnabled} '
      'tz=${tz.local.name} '
      'pending=${pending.length}',
    );
  }
}
