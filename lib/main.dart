import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:the_reminder_app/blocs/onboarding/auth_bloc.dart';
import 'package:the_reminder_app/config/routes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_reminder_app/injector.dart' as injection;

final GetIt injector = GetIt.instance;

Future<void> setupInjector() async {
  // register your AuthBloc factory
  injector.registerFactory<AuthBloc>(
    () => AuthBloc(),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupInjector();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => injection.locator<AuthBloc>()),
      ],
      child: ScreenUtilInit(
        minTextAdapt: true,
        child: MaterialApp.router(
          title: 'The Reminder App',
          debugShowCheckedModeBanner: false,
          routeInformationParser: AppRouter.router.routeInformationParser,
          routerDelegate: AppRouter.router.routerDelegate,
          routeInformationProvider: AppRouter.router.routeInformationProvider,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          builder: (context, child) {
            return child!;
          },
        ),
      ),
    );
  }
}
