import 'package:go_router/go_router.dart';
import 'package:the_reminder_app/ui/screens/home_screen.dart';
import 'package:the_reminder_app/ui/screens/login_screen.dart';
import 'package:the_reminder_app/ui/screens/register_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: "/login_page",
    debugLogDiagnostics: true,
    routes: <RouteBase>[
      GoRoute(
        name: "home",
        path: "/",
        builder: (context, state) {
          return HomeScreen();
        },
      ),
      GoRoute(
        name: "login_page",
        path: "/login_page",
        builder: (context, state) {
          return LoginPage();
        },
      ),
      GoRoute(
        name: "register_page",
        path: "/register_page",
        builder: (context, state) {
          return RegisterPage();
        },
      ),
    ],
  );
}
