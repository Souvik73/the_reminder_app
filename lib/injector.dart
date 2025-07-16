import 'package:get_it/get_it.dart';
import 'package:the_reminder_app/blocs/onboarding/auth_bloc.dart';
import 'package:the_reminder_app/config/routes.dart';

final locator = GetIt.instance;

Future<void> init() async {
  // Register your services, repositories, and other dependencies here
  // Example:
  // locator.registerLazySingleton<SomeService>(() => SomeServiceImpl());
  
  // You can also register factories or singletons as needed
  // locator.registerFactory<AnotherService>(() => AnotherServiceImpl());
  
  // If you have any initial setup or configuration, do it here
  locator.registerLazySingleton(() => AppRouter.router);
  locator.registerLazySingleton(() => AuthBloc());
}