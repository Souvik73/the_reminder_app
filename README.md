# The Reminder App

A Flutter productivity app that combines reminders, recurring alarms, hydration tracking, and Pomodoro focus sessions in one place.

The app is built with a local-first approach using Hive for core planner data, plus Firebase for authentication and lightweight user engagement/sync signals.

## Features

- Email/password sign in (auto-creates account if user does not exist)
- Google sign in
- Session restore across app launches
- Create, edit, delete, complete, and undo reminders
- Priority-based reminders (`High`, `Medium`, `Low`)
- Local notification scheduling for reminders with timezone support
- Recurring alarms (daily, weekdays, weekends, weekly, custom interval text)
- Hydration goal setting and intake logging
- Pomodoro presets (`25/5`, `15/5`, `50/10`, and custom)
- Calendar and profile views for planning and progress snapshots
- AdMob banner integration in major screens
- Account deletion flow (local + Firestore cleanup)

## Architecture

The app follows a layered Flutter architecture with BLoC/Cubit state management and service/repository abstractions:

```text
UI Screens/Widgets
    |
    v
BLoC/Cubit Layer
    - AuthBloc
    - ReminderBloc
    - AlarmCubit
    - HydrationCubit
    - PomodoroCubit
    |
    v
Domain/Data Layer
    - PlannerRepository (Hive-backed persistence)
    - AuthSessionStore (Hive session)
    - FirebaseUserSyncService (Firestore user/login sync)
    |
    v
Platform Services
    - NotificationService (flutter_local_notifications + timezone)
    - AlarmService (alarm package)
    - FirebaseEngagementService (FCM init/token)
    - AdService (Google Mobile Ads init/IDs)
```

### App flow at startup

1. `main()` initializes Flutter bindings and splash.
2. Firebase is initialized via `firebase_options.dart`.
3. DI container (`get_it`) initializes Hive, repositories, and services.
4. Session is restored from local store.
5. `MultiBlocProvider` wires app-level state objects.
6. Routing starts at `/login_page` (GoRouter).

### State modules

| Module | Responsibility | Primary file |
|---|---|---|
| `AuthBloc` | Sign-in, sign-out, restore session, delete account | `lib/blocs/onboarding/auth_bloc.dart` |
| `ReminderBloc` | Reminder CRUD, completion, notification scheduling/sync | `lib/blocs/reminder/reminder_bloc.dart` |
| `AlarmCubit` | Alarm CRUD and alarm plugin scheduling/sync | `lib/blocs/alarm/alarm_cubit.dart` |
| `HydrationCubit` | Goal management and hydration logs | `lib/blocs/hydration/hydration_cubit.dart` |
| `PomodoroCubit` | Preset and custom work/rest durations | `lib/blocs/pomodoro/pomodoro_cubit.dart` |

### Persistence model

Hive boxes are user-scoped for planner data:

- `users`
- `reminders_<userId>`
- `alarms_<userId>`
- `hydration_logs_<userId>`
- `hydration_settings_<userId>`
- `auth_session`

Core models:

- `Reminder`
- `AlarmEntry`
- `HydrationLog`
- `AppUser`

## Packages Used

Direct dependencies from `pubspec.yaml`:

| Package | Version | Purpose |
|---|---|---|
| `flutter` | SDK | Core framework |
| `cupertino_icons` | `^1.0.8` | iOS style icon set |
| `go_router` | `^16.0.0` | Declarative routing |
| `hive_ce` | `^2.11.3` | Local key-value persistence |
| `hive_ce_flutter` | `^2.3.1` | Flutter bindings for Hive |
| `flutter_bloc` | `^9.1.1` | State management (BLoC/Cubit) |
| `equatable` | `^2.0.7` | Value equality for state/events |
| `firebase_core` | `^3.15.1` | Firebase initialization |
| `firebase_auth` | `^5.6.2` | Authentication |
| `cloud_firestore` | `^5.6.11` | Cloud sync for user metadata/events |
| `firebase_messaging` | `^15.2.9` | Messaging/engagement setup |
| `flutter_local_notifications` | `^19.3.0` | Reminder notifications |
| `table_calendar` | `^3.2.0` | Calendar UI dependency (currently not imported) |
| `uuid` | `^4.5.1` | ID utility dependency (currently not imported) |
| `intl` | `^0.20.2` | Date/time formatting dependency (currently not imported) |
| `get_it` | `^8.0.3` | Dependency injection/service locator |
| `timezone` | `^0.10.1` | Timezone-aware scheduling |
| `flutter_timezone` | `^5.0.1` | Device timezone lookup |
| `path_provider` | `^2.1.4` | Local file paths (notification assets) |
| `google_sign_in` | `^6.2.1` | Google authentication flow |
| `url_launcher` | `^6.3.1` | Open legal/help external links |
| `flutter_native_splash` | `^2.4.6` | Native splash screen |
| `flutter_screenutil` | `^5.9.3` | Adaptive sizing utilities |
| `alarm` | `^5.1.5` | Full-screen alarm scheduling/ringing |
| `google_mobile_ads` | `^6.0.0` | Banner ad integration |

Dev dependencies:

- `flutter_test`
- `flutter_lints`
- `build_runner`
- `hive_ce_generator`
- `flutter_launcher_icons`

## Project Structure

```text
lib/
  blocs/
    alarm/
    hydration/
    onboarding/
    pomodoro/
    reminder/
  config/
    legal_links.dart
    routes.dart
  data/
    local/
    remote/
    repositories/
  models/
    planner_models.dart
  services/
    ad_service.dart
    alarm_service.dart
    firebase_engagement_service.dart
    notification_service.dart
  ui/
    screens/
    theme/
    widgets/
  injector.dart
  main.dart
```

## Getting Started

### Prerequisites

- Flutter SDK compatible with Dart `^3.8.1`
- Android Studio + Android SDK (for Android builds)
- Xcode + CocoaPods (for iOS/macOS builds)
- Firebase project (Auth + Firestore + Messaging)

### Install dependencies

```bash
flutter pub get
```

### Firebase configuration

This repo already includes:

- `lib/firebase_options.dart`
- `android/app/google-services.json`

For your own project setup, reconfigure Firebase values and platform files:

```bash
flutterfire configure
```

Recommended checks:

- Enable Firebase Auth providers you use (`Email/Password`, `Google`)
- Ensure Firestore is created in your Firebase project
- For iOS, verify bundle IDs and required Firebase/APNs setup

### Google Sign-In

`lib/injector.dart` uses a configured `serverClientId` for `GoogleSignIn`. Replace it with your own OAuth client ID if needed.

### AdMob

Ad IDs are configured in:

- `android/app/src/main/AndroidManifest.xml` (`com.google.android.gms.ads.APPLICATION_ID`)
- `ios/Runner/Info.plist` (`GADApplicationIdentifier`)
- `lib/services/ad_service.dart` (`bannerAdUnitId`)

Use your own test/live IDs per environment before release.

## Run

```bash
flutter run
```

Examples:

```bash
flutter run -d android
flutter run -d ios
flutter run -d chrome
```

## Test

```bash
flutter test
```

Current tests include a notification scheduling unit test. The default `widget_test.dart` is still the Flutter starter smoke test and should be replaced with app-specific widget coverage.

## Platform Notes

- Notifications and exact alarm behavior are strongest on Android, where permission fallbacks are handled at runtime.
- Alarm behavior uses the `alarm` plugin and includes native hooks for screen-off stop and volume-down snooze on Android (`MainActivity.kt`).
- Several modules guard behavior with `kIsWeb`, so web builds run with limited notification/alarm capabilities.

## Known Gaps / Roadmap Signals

- Apple sign-in path is currently a placeholder flow (not full Sign in with Apple).
- Settings toggles for "smart notifications" and "personalized ads" are currently UI-only.
- Fields like `isVoiceCreated` and `isGeofenced` exist in `Reminder` but are not fully implemented in UI/services yet.
- Some dependencies are declared for planned features (`table_calendar`, `uuid`, `intl`) but are not currently imported in `lib/`.

## Build

```bash
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
flutter build web --release
```
