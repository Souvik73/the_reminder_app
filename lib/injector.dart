import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:the_reminder_app/blocs/onboarding/auth_bloc.dart';
import 'package:the_reminder_app/config/routes.dart';
import 'package:the_reminder_app/data/local/auth_session_store.dart';
import 'package:the_reminder_app/data/local/hive_initializer.dart';
import 'package:the_reminder_app/data/remote/firebase_user_sync_service.dart';
import 'package:the_reminder_app/data/repositories/planner_repository.dart';
import 'package:the_reminder_app/services/notification_service.dart';

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
  await notificationService.init();

  locator.registerLazySingleton<PlannerRepository>(() => plannerRepository);
  locator.registerLazySingleton<AuthSessionStore>(() => sessionStore);
  locator.registerLazySingleton<FirebaseUserSyncService>(() => userSyncService);
  locator.registerSingleton<NotificationService>(notificationService);
  locator.registerLazySingleton(() => AppRouter.router);
  locator.registerFactory<AuthBloc>(
    () => AuthBloc(
      plannerRepository: locator(),
      userSyncService: locator(),
      sessionStore: locator(),
    ),
  );
}
