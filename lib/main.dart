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
import 'package:the_reminder_app/data/local/auth_session_store.dart';
import 'package:the_reminder_app/data/repositories/planner_repository.dart';
import 'package:the_reminder_app/blocs/subscription/subscription_cubit.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:the_reminder_app/services/alarm_service.dart';
import 'package:the_reminder_app/services/notification_service.dart';
import 'package:the_reminder_app/services/purchase_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await injection.init();
  final existingSession = await injection.locator<AuthSessionStore>().read();
  final initialUserId = existingSession?.userId ?? 'local-user';
  runApp(MyApp(initialUserId: initialUserId));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.initialUserId});

  final String initialUserId;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    FlutterNativeSplash.remove();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final defaultUserId = widget.initialUserId;
    final plannerRepository = injection.locator<PlannerRepository>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => injection.locator<AuthBloc>()),
        BlocProvider(
          create: (context) => ReminderBloc(
            repository: plannerRepository,
            notificationService: injection.locator<NotificationService>(),
            initialUserId: defaultUserId,
          ),
        ),
        BlocProvider(
          create: (context) => AlarmCubit(
            repository: plannerRepository,
            alarmService: injection.locator<AlarmService>(),
            initialUserId: defaultUserId,
          ),
        ),
        BlocProvider(
          create: (context) => HydrationCubit(
            repository: plannerRepository,
            initialUserId: defaultUserId,
          ),
        ),
        BlocProvider(
          create: (context) => SubscriptionCubit(
            purchaseService: injection.locator<PurchaseService>(),
          )..bootstrap(),
        ),
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
