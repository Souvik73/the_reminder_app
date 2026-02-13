import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:the_reminder_app/blocs/onboarding/auth_bloc.dart';
import 'package:the_reminder_app/config/routes.dart';
import 'package:the_reminder_app/data/local/auth_session_store.dart';
import 'package:the_reminder_app/data/local/hive_initializer.dart';
import 'package:the_reminder_app/data/remote/firebase_user_sync_service.dart';
import 'package:the_reminder_app/data/repositories/planner_repository.dart';
import 'package:the_reminder_app/services/alarm_service.dart';
import 'package:the_reminder_app/services/ad_service.dart';
import 'package:the_reminder_app/services/firebase_engagement_service.dart';
import 'package:the_reminder_app/services/notification_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

final locator = GetIt.instance;

Future<void> init() async {
  await HiveInitializer.init();

  final plannerRepository = PlannerRepository();
  await plannerRepository.warmUp();
  await plannerRepository.ensureUser(
    userId: 'local-user',
    email: 'local-user@offline.app',
    displayName: 'Local User',
  );
  final sessionStore = AuthSessionStore();

  final firestore = FirebaseFirestore.instance;
  final userSyncService = FirebaseUserSyncService(firestore: firestore);
  final notificationService = NotificationService();
  final alarmService = AlarmService();
  final adService = AdService();
  final engagementService = FirebaseEngagementService();
  await notificationService.init();
  await alarmService.init();
  await adService.init();
  await engagementService.init();

  locator.registerLazySingleton<PlannerRepository>(() => plannerRepository);
  locator.registerLazySingleton<AuthSessionStore>(() => sessionStore);
  locator.registerLazySingleton<FirebaseUserSyncService>(() => userSyncService);
  locator.registerSingleton<NotificationService>(notificationService);
  locator.registerSingleton<AlarmService>(alarmService);
  locator.registerSingleton<AdService>(adService);
  locator.registerLazySingleton(() => AppRouter.router);
  locator.registerFactory<AuthBloc>(
    () => AuthBloc(
      plannerRepository: locator(),
      userSyncService: locator(),
      sessionStore: locator(),
      googleSignIn: GoogleSignIn(
        serverClientId:
            '266329530255-26pkfoit5ueete442nilf4unv29u7vsc.apps.googleusercontent.com',
      ),
    ),
  );
}
