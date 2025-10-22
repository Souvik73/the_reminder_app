import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/alarm/alarm_cubit.dart';
import 'package:the_reminder_app/blocs/hydration/hydration_cubit.dart';
import 'package:the_reminder_app/blocs/onboarding/auth_bloc.dart';
import 'package:the_reminder_app/blocs/pomodoro/pomodoro_cubit.dart';
import 'package:the_reminder_app/blocs/reminder/reminder_bloc.dart';
import 'package:the_reminder_app/config/routes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_reminder_app/injector.dart' as injection;
import 'package:the_reminder_app/data/repositories/planner_repository.dart';
import 'package:the_reminder_app/blocs/subscription/subscription_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await injection.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const defaultUserId = 'local-user';
    final plannerRepository = injection.locator<PlannerRepository>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => injection.locator<AuthBloc>()),
        BlocProvider(
          create: (context) => ReminderBloc(
            repository: plannerRepository,
            initialUserId: defaultUserId,
          ),
        ),
        BlocProvider(
          create: (context) => AlarmCubit(
            repository: plannerRepository,
            initialUserId: defaultUserId,
          ),
        ),
        BlocProvider(
          create: (context) => HydrationCubit(
            repository: plannerRepository,
            initialUserId: defaultUserId,
          ),
        ),
        BlocProvider(create: (context) => SubscriptionCubit()),
        BlocProvider(create: (context) => PomodoroCubit()),
      ],
      child: ScreenUtilInit(
        minTextAdapt: true,
        child: MaterialApp.router(
          title: 'The Reminder App',
          debugShowCheckedModeBanner: false,
          routerConfig: AppRouter.router,
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
