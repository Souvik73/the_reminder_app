import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:the_reminder_app/data/local/adapters/time_of_day_adapter.dart';
import 'package:the_reminder_app/models/planner_models.dart';

class HiveInitializer {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _registerAdapters();
    _initialized = true;
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(TimeOfDayAdapter());
    }
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ReminderPriorityAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ReminderAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AlarmEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(HydrationLogAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(AppUserAdapter());
    }
  }
}
