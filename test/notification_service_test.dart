import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_reminder_app/models/planner_models.dart';
import 'package:the_reminder_app/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAndroidNotificationsPlugin fakePlugin;
  late NotificationService service;
  FlutterLocalNotificationsPlatform? previousPlatform;
  const MethodChannel timezoneChannel =
      MethodChannel('the_reminder_app/timezone');
  const MethodChannel flutterTimezoneChannel = MethodChannel('flutter_timezone');

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      previousPlatform = FlutterLocalNotificationsPlatform.instance;
    } catch (_) {
      previousPlatform = null;
    }
    fakePlugin = FakeAndroidNotificationsPlugin();
    FlutterLocalNotificationsPlatform.instance = fakePlugin;
    service = NotificationService();
    timezoneChannel.setMockMethodCallHandler((MethodCall call) async {
      if (call.method == 'getTimeZone') {
        return 'Asia/Kolkata';
      }
      return null;
    });
    flutterTimezoneChannel.setMockMethodCallHandler((MethodCall call) async {
      if (call.method == 'getLocalTimezone') {
        return 'Asia/Kolkata';
      }
      return null;
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    timezoneChannel.setMockMethodCallHandler(null);
    flutterTimezoneChannel.setMockMethodCallHandler(null);
    if (previousPlatform != null) {
      FlutterLocalNotificationsPlatform.instance = previousPlatform!;
    }
  });

  test(
    'scheduleReminder schedules soon using the configured local timezone',
    () async {
      final reminder = Reminder(
        id: '42',
        userId: 'user-1',
        title: 'Test reminder',
        description: 'Check scheduling time and timezone',
        scheduledAt: DateTime.utc(2030, 1, 1, 12, 0),
        priority: ReminderPriority.high,
      );

      final result = await service.scheduleReminder(reminder);

      expect(result, NotificationScheduleResult.scheduledExact);

      final tz.TZDateTime? scheduled = fakePlugin.lastScheduledDate;
      expect(scheduled, isNotNull);
      expect(scheduled!.location.name, 'Asia/Kolkata');

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final Duration diff = scheduled.difference(now);
      expect(diff, greaterThan(Duration.zero));
      expect(diff, lessThan(const Duration(minutes: 5)));

      expect(fakePlugin.lastScheduleMode, AndroidScheduleMode.exactAllowWhileIdle);
      expect(fakePlugin.lastPayload, 'reminder:${reminder.id}');
    },
  );
}

class FakeAndroidNotificationsPlugin extends AndroidFlutterLocalNotificationsPlugin {
  tz.TZDateTime? lastScheduledDate;
  AndroidScheduleMode? lastScheduleMode;
  String? lastPayload;

  bool notificationsEnabled = true;
  bool exactAlarmsAllowed = true;

  @override
  Future<bool> initialize(
    AndroidInitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    return true;
  }

  @override
  Future<bool?> requestNotificationsPermission() async => notificationsEnabled;

  @override
  Future<bool?> requestExactAlarmsPermission() async => exactAlarmsAllowed;

  @override
  Future<bool?> areNotificationsEnabled() async => notificationsEnabled;

  @override
  Future<bool?> canScheduleExactNotifications() async => exactAlarmsAllowed;

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    AndroidNotificationDetails? notificationDetails, {
    required AndroidScheduleMode scheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    lastScheduledDate = scheduledDate;
    lastScheduleMode = scheduleMode;
    lastPayload = payload;
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async =>
      <PendingNotificationRequest>[];

  @override
  Future<void> cancel(int id, {String? tag}) async {}
}
