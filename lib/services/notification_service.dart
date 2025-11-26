import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:the_reminder_app/models/planner_models.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Result from attempting to schedule a reminder notification.
enum NotificationScheduleResult {
  scheduledExact,
  scheduledWithInexactFallback,
  failed,
}

/// Handles initializing and scheduling reminder notifications with the
/// `flutter_local_notifications` plugin.
class NotificationService {
  NotificationService()
    : _notificationsPlugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  static const MethodChannel _timezoneChannel = MethodChannel(
    'the_reminder_app/timezone',
  );
  static const String _defaultSmallIcon = '@mipmap/launcher_icon';
  bool _initialized = false;
  bool _timeZoneInitialized = false;

  static const String _reminderChannelId = 'the_reminder_app';
  static const String _reminderChannelName = 'Notification';
  static const String _reminderChannelDescription =
      'Notifications that fire when reminders are due.';
  static const String _reminderPayloadPrefix = 'reminder:';
  // static const String _defaultTimeZoneName = 'Asia/Kolkata';

  String? _cachedLargeIconPath;
  String? _cachedBigPicturePath;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    await _ensureTimeZoneData();

    const androidSettings = AndroidInitializationSettings(
      _defaultSmallIcon,
    );
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

    final bigPictureStyleInformation = await _buildBigPictureStyleInformation(
      reminder,
    );

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _reminderChannelId,
        _reminderChannelName,
        channelDescription: _reminderChannelDescription,
        icon: _defaultSmallIcon,
        importance: Importance.high,
        priority: reminder.priority == ReminderPriority.high
            ? Priority.max
            : reminder.priority == ReminderPriority.medium
            ? Priority.defaultPriority
            : Priority.low,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        styleInformation: bigPictureStyleInformation,
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
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      final bool? canScheduleExact = await androidImplementation
          .canScheduleExactNotifications();
      if (canScheduleExact == false) {
        requiresExactAlarmPermission = true;
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      }
    }
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      reminder.scheduledAt,
      tz.local,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = now.add(const Duration(minutes: 1));
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        _notificationId(reminder.id),
        reminder.title,
        reminder.description.isEmpty
            ? 'Reminder due now'
            : reminder.description,
        scheduledDate,
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
            scheduledDate,
            notificationDetails,
            androidScheduleMode: scheduleMode,
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
        debugPrint('Failed to schedule reminder ${reminder.id}: $error');
        debugPrint('$stackTrace');
      }
    } catch (error, stackTrace) {
      debugPrint('Unexpected error scheduling reminder ${reminder.id}: $error');
      debugPrint('$stackTrace');
    }
    return NotificationScheduleResult.failed;
  }

  Future<StyleInformation?> _buildBigPictureStyleInformation(
    Reminder reminder,
  ) async {
    final bigPicturePath =
        _cachedBigPicturePath ??
        await _cacheAssetImage(
          assetPath: 'assets/images/logo.png',
          fileName: 'reminder_big_picture.png',
        );
    if (bigPicturePath != null) {
      _cachedBigPicturePath = bigPicturePath;
    }

    final largeIconPath =
        _cachedLargeIconPath ??
        await _cacheAssetImage(
          assetPath: 'assets/images/logo.png',
          fileName: 'reminder_large_icon.png',
        );
    if (largeIconPath != null) {
      _cachedLargeIconPath = largeIconPath;
    }

    if (bigPicturePath == null || largeIconPath == null) {
      return null;
    }

    return BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath),
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      contentTitle: reminder.title,
      summaryText: reminder.description,
    );
  }

  Future<String?> _cacheAssetImage({
    required String assetPath,
    required String fileName,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      if (await file.exists()) {
        return filePath;
      }
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (error) {
      debugPrint('Failed to cache image $assetPath for notification: $error');
      return null;
    }
  }

  /// Fire an immediate, one-off notification to verify device delivery.
  Future<void> triggerDebugNotification({String? title, String? body}) async {
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
        icon: _defaultSmallIcon,
        importance: Importance.high,
        priority: Priority.max,
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
    // Get Proper timezone for the user notifications.
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (error, stackTrace) {
      debugPrint('Failed to update timezone from platform: $error');
      debugPrint('$stackTrace');
    }
    _timeZoneInitialized = true;
  }

  Future<void> _requestPermissions() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();

    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final macImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    await macImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<bool> _ensureNotificationPermission() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final bool? androidEnabled = await androidImplementation
        ?.areNotificationsEnabled();
    if (androidEnabled == false) {
      await androidImplementation!.requestNotificationsPermission();
      final bool? retried = await androidImplementation
          .areNotificationsEnabled();
      if (retried == false) {
        return false;
      }
    }

    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
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

    final macImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
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
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
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
      final String? localTimeZone = await _timezoneChannel.invokeMethod<String>(
        'getTimeZone',
      );
      if (localTimeZone != null && localTimeZone.isNotEmpty) {
        tz.setLocalLocation(tz.getLocation(localTimeZone));
        return;
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to determine timezone: $error');
      debugPrint('$stackTrace');
    }
    tz.setLocalLocation(tz.getLocation(tz.local.name));
  }

  Future<void> _logStatusDebug(String context) async {
    if (kIsWeb) return;
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final macImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    final bool? androidEnabled = await androidImplementation
        ?.areNotificationsEnabled();
    final bool? canScheduleExact = await androidImplementation
        ?.canScheduleExactNotifications();
    final iosPermissions = await iosImplementation?.checkPermissions();
    final macPermissions = await macImplementation?.checkPermissions();
    final pending = await _notificationsPlugin
        .pendingNotificationRequests()
        .catchError((_) => <PendingNotificationRequest>[]);

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
