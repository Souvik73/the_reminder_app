import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/alarm/alarm_cubit.dart';
import 'package:the_reminder_app/blocs/alarm/alarm_state.dart';
import 'package:the_reminder_app/blocs/hydration/hydration_cubit.dart';
import 'package:the_reminder_app/blocs/hydration/hydration_state.dart';
import 'package:the_reminder_app/blocs/pomodoro/pomodoro_cubit.dart';
import 'package:the_reminder_app/blocs/pomodoro/pomodoro_state.dart';
import 'package:the_reminder_app/blocs/onboarding/auth_bloc.dart';
import 'package:the_reminder_app/blocs/reminder/reminder_bloc.dart';
import 'package:the_reminder_app/blocs/reminder/reminder_event.dart';
import 'package:the_reminder_app/blocs/reminder/reminder_state.dart';
import 'package:the_reminder_app/blocs/subscription/subscription_cubit.dart';
import 'package:the_reminder_app/blocs/subscription/subscription_state.dart';
import 'package:the_reminder_app/injector.dart' as injection;
import 'package:the_reminder_app/models/planner_models.dart';
import 'package:the_reminder_app/services/notification_service.dart';
import 'package:the_reminder_app/ui/screens/calendar_screen.dart';
import 'package:the_reminder_app/ui/screens/pomodoro_session_screen.dart';
import 'package:the_reminder_app/ui/screens/profile_screen.dart';
import 'package:the_reminder_app/ui/screens/settings_screen.dart';
import 'package:the_reminder_app/ui/theme/app_colors.dart';
import 'package:the_reminder_app/ui/theme/app_gradients.dart';
import 'package:the_reminder_app/ui/widgets/gradient_page_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _quickReminderController =
      TextEditingController();
  int _currentIndex = 0;
  static const String _fallbackUserId = 'local-user';
  String? _activeUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncUserScope(_resolveUserId());
    });
  }

  @override
  void dispose() {
    _quickReminderController.dispose();
    super.dispose();
  }

  String _resolveUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      return authState.userId;
    }
    return _fallbackUserId;
  }

  void _syncUserScope(String userId) {
    if (_activeUserId == userId) return;
    _activeUserId = userId;
    context.read<ReminderBloc>().setActiveUser(userId);
    context.read<AlarmCubit>().setActiveUser(userId);
    context.read<HydrationCubit>().setActiveUser(userId);
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _showExactAlarmPermissionWarning() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Enable “Exact alarms” in system settings so reminders arrive on time.',
        ),
        action: SnackBarAction(
          label: 'Open settings',
          onPressed: () {
            injection
                .locator<NotificationService>()
                .openExactAlarmPermissionSettings();
          },
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  String _userIdFromState(AuthState state) {
    if (state is AuthSuccess) {
      return state.userId;
    }
    return _fallbackUserId;
  }

  @override
  Widget build(BuildContext context) {
    final reminderState = context.watch<ReminderBloc>().state;
    final alarmState = context.watch<AlarmCubit>().state;
    final hydrationState = context.watch<HydrationCubit>().state;
    final subscriptionState = context.watch<SubscriptionCubit>().state;
    final pomodoroState = context.watch<PomodoroCubit>().state;

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              _userIdFromState(previous) != _userIdFromState(current),
          listener: (context, state) {
            _syncUserScope(_userIdFromState(state));
          },
        ),
        BlocListener<ReminderBloc, ReminderState>(
          listenWhen: (previous, current) =>
              previous.permissionWarningCounter !=
              current.permissionWarningCounter,
          listener: (context, state) {
            _showExactAlarmPermissionWarning();
          },
        ),
      ],
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _HomeDrawer(
          currentIndex: _currentIndex,
          onDestinationSelected: _setIndex,
          isPremium: subscriptionState.isPremium,
          onSubscriptionTap: _showSubscriptionSheet,
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeTab(
              reminderState,
              alarmState,
              hydrationState,
              subscriptionState,
              pomodoroState,
            ),
            CalendarScreen(onOpenMenu: _openDrawer),
            SettingsScreen(onOpenMenu: _openDrawer),
            ProfileScreen(onOpenMenu: _openDrawer),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF667EEA).withValues(alpha: 0.18),
          surfaceTintColor: Colors.transparent,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Calendar',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreationSheet,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New'),
          backgroundColor: const Color(0xFF667EEA),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHomeTab(
    ReminderState reminderState,
    AlarmState alarmState,
    HydrationState hydrationState,
    SubscriptionState subscriptionState,
    PomodoroState pomodoroState,
  ) {
    final grouped = reminderState.remindersByPriority;
    final theme = Theme.of(context);

    final actions = [
      GradientHeaderButton(
        icon: Icons.search_rounded,
        onPressed: _showReminderSearch,
      ),
    ];

    Widget bodyContent;
    if (reminderState.isLoading && reminderState.activeReminders.isEmpty) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else {
      bodyContent = RefreshIndicator(
        onRefresh: () async =>
            Future<void>.delayed(const Duration(milliseconds: 600)),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
          children: [
            _QuickEntryCard(
              controller: _quickReminderController,
              onTextSubmitted: _createReminderFromText,
              onAlarmPressed: () => _openAlarmComposer(),
            ),
            const SizedBox(height: 24),
            if (reminderState.activeReminders.isEmpty)
              _buildEmptyRemindersState(theme)
            else ...[
              if (grouped[ReminderPriority.high]!.isNotEmpty)
                _ReminderSection(
                  title: 'High priority',
                  accent: ReminderPriority.high.color,
                  reminders: grouped[ReminderPriority.high]!,
                  onEdit: (reminder) =>
                      _openReminderComposer(reminder: reminder),
                  onDelete: _deleteReminder,
                  onComplete: _completeReminder,
                ),
              if (grouped[ReminderPriority.medium]!.isNotEmpty)
                _ReminderSection(
                  title: 'Medium priority',
                  accent: ReminderPriority.medium.color,
                  reminders: grouped[ReminderPriority.medium]!,
                  onEdit: (reminder) =>
                      _openReminderComposer(reminder: reminder),
                  onDelete: _deleteReminder,
                  onComplete: _completeReminder,
                ),
              if (grouped[ReminderPriority.low]!.isNotEmpty)
                _ReminderSection(
                  title: 'Low priority',
                  accent: ReminderPriority.low.color,
                  reminders: grouped[ReminderPriority.low]!,
                  onEdit: (reminder) =>
                      _openReminderComposer(reminder: reminder),
                  onDelete: _deleteReminder,
                  onComplete: _completeReminder,
                ),
            ],
            const SizedBox(height: 24),
            _AlarmCard(
              alarmState: alarmState,
              onCreate: _openAlarmComposer,
              onEdit: _openAlarmComposer,
              onDelete: _deleteAlarm,
            ),
            const SizedBox(height: 24),
            _HydrationGoalCard(
              hydrationState: hydrationState,
              onQuickLog: _logHydration,
              onCustomLog: _openHydrationLogSheet,
              onSetGoal: _openHydrationGoalDialog,
            ),
            const SizedBox(height: 16),
            _HydrationHistoryCard(hydrationState: hydrationState),
            const SizedBox(height: 16),
            _PomodoroCard(
              pomodoroState: pomodoroState,
              onPresetSelected: _selectPomodoroPreset,
              onCustomRequested: _selectCustomIntervals,
              onStartSession: _startPomodoroSession,
            ),
            const SizedBox(height: 16),
            if (!subscriptionState.isPremium) ...[
              const SizedBox(height: 16),
              _AdBanner(onUpgrade: _showSubscriptionSheet),
            ],
          ],
        ),
      );
    }

    return GradientPageShell(
      icon: Icons.dashboard_customize_rounded,
      title: "Today's Plan",
      subtitle: 'Capture, prioritize, and stay on track',
      leading: GradientHeaderButton(
        icon: Icons.menu_rounded,
        onPressed: _openDrawer,
      ),
      actions: actions,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.pageBackground),
        child: bodyContent,
      ),
    );
  }

  Widget _buildEmptyRemindersState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppGradients.subtle,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 36,
            color: AppColors.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'No upcoming reminders. Create one to stay organized.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.accent.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setIndex(int index) {
    Navigator.of(context).pop();
    setState(() => _currentIndex = index);
  }

  void _createReminderFromText() {
    final text = _quickReminderController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a reminder description first.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    context.read<ReminderBloc>().add(ReminderCreatedFromText(text));
    _quickReminderController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder created.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _openReminderComposer({
    Reminder? reminder,
    String? initialTitle,
  }) async {
    final titleController = TextEditingController(
      text: initialTitle ?? reminder?.title ?? '',
    );
    final notesController = TextEditingController(
      text: reminder?.description ?? '',
    );
    DateTime scheduledAt =
        reminder?.scheduledAt ?? DateTime.now().add(const Duration(hours: 1));
    ReminderPriority priority = reminder?.priority ?? ReminderPriority.medium;

    final updated = await showModalBottomSheet<Reminder>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      // enableDrag: false,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder == null ? 'Create reminder' : 'Edit reminder',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'What should we remind you about?',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Add details or context (optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event_outlined),
                            label: Text(
                              MaterialLocalizations.of(
                                context,
                              ).formatMediumDate(scheduledAt),
                            ),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: scheduledAt,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (pickedDate != null) {
                                if (!context.mounted) return;
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(
                                    scheduledAt,
                                  ),
                                );
                                if (!context.mounted) return;
                                setModalState(() {
                                  scheduledAt = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    pickedTime?.hour ?? scheduledAt.hour,
                                    pickedTime?.minute ?? scheduledAt.minute,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<ReminderPriority>(
                            value: priority,
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                            ),
                            items: ReminderPriority.values
                                .map(
                                  (priority) => DropdownMenuItem(
                                    value: priority,
                                    child: Text(priority.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(() => priority = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          final title = titleController.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please add a title to your reminder.',
                                ),
                                duration: Duration(seconds: 3),
                              ),
                            );
                            return;
                          }
                          final id =
                              reminder?.id ??
                              DateTime.now().microsecondsSinceEpoch.toString();
                          Navigator.of(context).pop(
                            Reminder(
                              id: id,
                              userId: context
                                  .read<ReminderBloc>()
                                  .state
                                  .activeUserId,
                              title: title,
                              description: notesController.text.trim(),
                              scheduledAt: scheduledAt,
                              priority: priority,
                            ),
                          );
                        },
                        child: Text(
                          reminder == null ? 'Create' : 'Save changes',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      titleController.dispose();
      notesController.dispose();
    });

    if (!mounted) return;

    if (updated != null) {
      context.read<ReminderBloc>().add(ReminderUpserted(reminder: updated));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder "${updated.title}" saved.'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _deleteReminder(Reminder reminder) {
    context.read<ReminderBloc>().add(ReminderDeleted(reminderId: reminder.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder "${reminder.title}" deleted.'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _completeReminder(Reminder reminder) {
    context.read<ReminderBloc>().add(ReminderCompleted(reminder: reminder));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked "${reminder.title}" as complete.'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            context.read<ReminderBloc>().add(
              ReminderCompletionUndone(reminder: reminder),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openAlarmComposer({AlarmEntry? existing}) async {
    final labelController = TextEditingController(text: existing?.label ?? '');
    TimeOfDay selectedTime = existing?.time ?? TimeOfDay.now();
    const recurrenceOptions = [
      'Daily',
      'Weekdays',
      'Weekends',
      'Weekly',
      'Custom',
    ];
    String recurrence = existing?.recurrence ?? 'Daily';
    String customRecurrence =
        existing != null && !recurrenceOptions.contains(existing.recurrence)
        ? existing.recurrence
        : 'Every 3 days';
    bool isCustom =
        recurrence == 'Custom' || (!recurrenceOptions.contains(recurrence));

    final result = await showModalBottomSheet<AlarmEntry>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null ? 'Create alarm' : 'Edit alarm',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Alarm label',
                        hintText: 'e.g. Morning workout',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        MaterialLocalizations.of(
                          context,
                        ).formatTimeOfDay(selectedTime),
                      ),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (!context.mounted) return;
                        if (picked != null) {
                          setModalState(() => selectedTime = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: recurrenceOptions.map((option) {
                        final selected = isCustom
                            ? option == 'Custom'
                            : recurrence == option;
                        return ChoiceChip(
                          label: Text(option),
                          selected: selected,
                          onSelected: (value) {
                            if (!value) return;
                            setModalState(() {
                              if (option == 'Custom') {
                                isCustom = true;
                                recurrence = 'Custom';
                              } else {
                                isCustom = false;
                                recurrence = option;
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (isCustom) ...[
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Custom interval',
                          hintText: 'e.g. Every 3 days',
                        ),
                        onChanged: (value) => customRecurrence = value,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final label = labelController.text.trim().isEmpty
                              ? 'Alarm'
                              : labelController.text.trim();
                          final recurrenceLabel = isCustom
                              ? customRecurrence.trim()
                              : recurrence;
                          Navigator.of(context).pop(
                            AlarmEntry(
                              id:
                                  existing?.id ??
                                  DateTime.now().microsecondsSinceEpoch
                                      .toString(),
                              userId: context
                                  .read<AlarmCubit>()
                                  .state
                                  .activeUserId,
                              time: selectedTime,
                              recurrence: recurrenceLabel.isEmpty
                                  ? 'Custom interval'
                                  : recurrenceLabel,
                              label: label,
                            ),
                          );
                        },
                        child: Text(
                          existing == null ? 'Create alarm' : 'Save changes',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      labelController.dispose();
    });

    if (!mounted) return;

    if (result != null) {
      context.read<AlarmCubit>().upsertAlarm(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alarm "${result.label}" saved.'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _deleteAlarm(AlarmEntry alarm) {
    context.read<AlarmCubit>().deleteAlarm(alarm.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alarm "${alarm.label}" removed.'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _logHydration(int amount) {
    context.read<HydrationCubit>().logIntake(amount);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged $amount ml of water.'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _openHydrationLogSheet() async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Log water intake',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _logHydration(200);
                    },
                    child: const Text('+200 ml'),
                  ),
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _logHydration(400);
                    },
                    child: const Text('+400 ml'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Custom amount (ml)',
                  hintText: 'Enter amount in milliliters',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final value = int.tryParse(controller.text.trim());
                    if (value == null || value <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enter a positive amount.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pop();
                    _logHydration(value);
                  },
                  child: const Text('Log hydration'),
                ),
              ),
            ],
          ),
        );
      },
    );
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      controller.dispose();
    });
  }

  Future<void> _openHydrationGoalDialog() async {
    final hydrationState = context.read<HydrationCubit>().state;
    final controller = TextEditingController(
      text: hydrationState.dailyGoal.toString(),
    );
    final newGoal = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set hydration goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Daily goal in ml'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value < 1000) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter at least 1000 ml.'),
                    duration: Duration(seconds: 3),
                  ),
                );
                return;
              }
              Navigator.of(context).pop(value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      controller.dispose();
    });
    if (!mounted) return;
    if (newGoal != null) {
      context.read<HydrationCubit>().setDailyGoal(newGoal);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hydration goal set to $newGoal ml.'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<_PomodoroConfig?> _selectCustomIntervals() async {
    final pomodoroState = context.read<PomodoroCubit>().state;
    final workController = TextEditingController(
      text: (pomodoroState.customWorkDuration ?? pomodoroState.workDuration)
          .inMinutes
          .toString(),
    );
    final restController = TextEditingController(
      text: (pomodoroState.customRestDuration ?? pomodoroState.restDuration)
          .inMinutes
          .toString(),
    );
    final config = await showDialog<_PomodoroConfig>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Pomodoro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: workController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Focus minutes'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: restController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Rest minutes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final work = int.tryParse(workController.text.trim());
              final rest = int.tryParse(restController.text.trim());
              if (work == null || work <= 0 || rest == null || rest < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Use positive numbers for custom intervals.'),
                    duration: Duration(seconds: 3),
                  ),
                );
                return;
              }
              Navigator.of(context).pop(
                _PomodoroConfig(
                  Duration(minutes: work),
                  Duration(minutes: rest),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      workController.dispose();
      restController.dispose();
    });

    if (!mounted) return config;

    if (config != null) {
      context.read<PomodoroCubit>().setCustomDurations(
        config.work,
        config.rest,
      );
    }
    return config;
  }

  void _selectPomodoroPreset(String preset) {
    final pomodoroCubit = context.read<PomodoroCubit>();
    pomodoroCubit.selectPreset(preset);
    if (preset == 'Custom' && pomodoroCubit.state.customWorkDuration == null) {
      _selectCustomIntervals();
    }
  }

  void _startPomodoroSession() {
    final state = context.read<PomodoroCubit>().state;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PomodoroSessionScreen(
          workDuration: state.workDuration,
          restDuration: state.restDuration,
        ),
      ),
    );
  }

  void _showReminderSearch() {
    final reminders = context.read<ReminderBloc>().state.reminders;
    final rootContext = context;
    showModalBottomSheet<void>(
      context: rootContext,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: reminders.isEmpty
                ? const Text('No reminders to search through yet.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: reminders
                        .map(
                          (reminder) => ListTile(
                            leading: const Icon(Icons.search),
                            title: Text(reminder.title),
                            subtitle: Text(
                              reminder.description.isEmpty
                                  ? reminder.priority.label
                                  : reminder.description,
                            ),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              ScaffoldMessenger.of(rootContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Open reminder "${reminder.title}"',
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            },
                          ),
                        )
                        .toList(),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _showCreationSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_note_outlined),
                title: const Text('New reminder (text)'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openReminderComposer();
                },
              ),
              ListTile(
                leading: const Icon(Icons.alarm_add_outlined),
                title: const Text('Create alarm'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openAlarmComposer();
                },
              ),
              ListTile(
                leading: const Icon(Icons.water_drop_outlined),
                title: const Text('Log hydration'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openHydrationLogSheet();
                },
              ),
              ListTile(
                leading: const Icon(Icons.hourglass_bottom_outlined),
                title: const Text('Start Pomodoro session'),
                onTap: () {
                  Navigator.of(context).pop();
                  _startPomodoroSession();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSubscriptionSheet() {
    final rootContext = context;
    final subscriptionState = rootContext.read<SubscriptionCubit>().state;
    showModalBottomSheet<void>(
      context: rootContext,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                size: 48,
                color: Theme.of(rootContext).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                subscriptionState.isPremium
                    ? 'Manage your Premium plan'
                    : 'Upgrade to Premium',
                style: Theme.of(
                  rootContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                subscriptionState.isPremium
                    ? 'Adjust your subscription, manage billing, or contact support.'
                    : 'Unlock advanced Pomodoro analytics and an ad-free experience.',
                textAlign: TextAlign.center,
                style: Theme.of(rootContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    rootContext,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final cubit = rootContext.read<SubscriptionCubit>();
                    if (subscriptionState.isPremium) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(
                          content: Text('Subscription portal coming soon.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    } else {
                      cubit.upgrade();
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Premium activated. Enjoy the upgrade!',
                          ),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                    Navigator.of(sheetContext).pop();
                  },
                  child: Text(
                    subscriptionState.isPremium
                        ? 'Manage subscription'
                        : 'Upgrade now',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PomodoroConfig {
  final Duration work;
  final Duration rest;

  const _PomodoroConfig(this.work, this.rest);
}

class _HomeDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isPremium;
  final VoidCallback onSubscriptionTap;

  const _HomeDrawer({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.isPremium,
    required this.onSubscriptionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primaryContainer,
                  ],
                ),
              ),
              accountName: Text(isPremium ? 'Premium member' : 'Guest'),
              accountEmail: const Text('Stay on top of your day'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person_outline,
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            _DrawerTile(
              icon: Icons.home_outlined,
              label: 'Home',
              selected: currentIndex == 0,
              onTap: () => onDestinationSelected(0),
            ),
            _DrawerTile(
              icon: Icons.calendar_month_outlined,
              label: 'Calendar',
              selected: currentIndex == 1,
              onTap: () => onDestinationSelected(1),
            ),
            _DrawerTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              selected: currentIndex == 2,
              onTap: () => onDestinationSelected(2),
            ),
            _DrawerTile(
              icon: Icons.person_outline,
              label: 'Profile',
              selected: currentIndex == 3,
              onTap: () => onDestinationSelected(3),
            ),
            const Divider(),
            _DrawerTile(
              icon: Icons.workspace_premium_outlined,
              label: isPremium ? 'Manage subscription' : 'Upgrade to Premium',
              onTap: onSubscriptionTap,
            ),
            _DrawerTile(
              icon: Icons.help_outline,
              label: 'Help & support',
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Support center coming soon.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Swipe reminders up to mark them complete. Use undo if you change your mind.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(label),
      selected: selected,
      onTap: onTap,
    );
  }
}

class _QuickEntryCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTextSubmitted;
  final VoidCallback onAlarmPressed;

  const _QuickEntryCard({
    required this.controller,
    required this.onTextSubmitted,
    required this.onAlarmPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.subtle,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Quick reminder',
              hintText: 'e.g. Call the dentist tomorrow at 9am',
              prefixIcon: const Icon(Icons.edit_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send_rounded),
                color: AppColors.primary,
                onPressed: onTextSubmitted,
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onTextSubmitted(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.alarm_add_outlined),
              label: const Text('Create alarm'),
              onPressed: onAlarmPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.secondary, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderSection extends StatelessWidget {
  final String title;
  final Color accent;
  final List<Reminder> reminders;
  final ValueChanged<Reminder> onEdit;
  final ValueChanged<Reminder> onDelete;
  final ValueChanged<Reminder> onComplete;

  const _ReminderSection({
    required this.title,
    required this.accent,
    required this.reminders,
    required this.onEdit,
    required this.onDelete,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: AppColors.cardBackground,
        shadowColor: accent.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: AppGradients.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${reminders.length} upcoming',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...reminders.map(
                (reminder) => _ReminderTile(
                  reminder: reminder,
                  accent: accent,
                  localizations: localizations,
                  onEdit: () => onEdit(reminder),
                  onDelete: () => onDelete(reminder),
                  onCompleted: () => onComplete(reminder),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final Reminder reminder;
  final Color accent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCompleted;
  final MaterialLocalizations localizations;

  const _ReminderTile({
    required this.reminder,
    required this.accent,
    required this.onEdit,
    required this.onDelete,
    required this.onCompleted,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(reminder.scheduledAt),
    );
    final dueLabel = _formatDue(reminder.scheduledAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey(reminder.id),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async =>
            direction == DismissDirection.startToEnd ||
            direction == DismissDirection.endToStart,
        onDismissed: (_) => onCompleted(),
        background: _DismissibleActionBackground(
          alignment: Alignment.centerLeft,
          theme: theme,
        ),
        secondaryBackground: _DismissibleActionBackground(
          alignment: Alignment.centerRight,
          theme: theme,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 56,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reminder.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            timeLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (reminder.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        reminder.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.timer_outlined, size: 16),
                          label: Text(dueLabel),
                        ),
                        Chip(
                          avatar: const Icon(Icons.flag_outlined, size: 16),
                          label: Text(reminder.priority.label),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDue(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    if (difference.isNegative) {
      return 'Overdue';
    }
    final days = difference.inDays;
    if (days > 0) {
      return 'in ${days}d';
    }
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    if (hours > 0) {
      return minutes > 0 ? 'in ${hours}h ${minutes}m' : 'in ${hours}h';
    }
    if (minutes > 0) {
      return 'in ${minutes}m';
    }
    return 'Soon';
  }
}

class _AlarmCard extends StatelessWidget {
  final AlarmState alarmState;
  final Future<void> Function({AlarmEntry? existing}) onCreate;
  final Future<void> Function({AlarmEntry? existing}) onEdit;
  final ValueChanged<AlarmEntry> onDelete;

  const _AlarmCard({
    required this.alarmState,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    return Card(
      color: AppColors.cardBackground,
      shadowColor: AppColors.cardShadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Icon(Icons.alarm_outlined, color: AppColors.primary),
              ),
              title: const Text('Recurring alarms'),
              subtitle: const Text('Stay consistent with your routines.'),
              trailing: IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () {
                  onCreate();
                },
              ),
            ),
            if (alarmState.alarms.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No alarms yet. Create one to get repeating alerts.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...alarmState.alarms.map((alarm) {
                final timeLabel = localizations.formatTimeOfDay(alarm.time);
                return ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text(alarm.label),
                  subtitle: Text('${alarm.recurrence} • $timeLabel'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit(existing: alarm);
                      } else if (value == 'delete') {
                        onDelete(alarm);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

}

class _DismissibleActionBackground extends StatelessWidget {
  const _DismissibleActionBackground({
    required this.alignment,
    required this.theme,
  });

  final Alignment alignment;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: const Icon(
        Icons.check_circle_outline,
        color: Colors.white,
        size: 32,
      ),
    );
  }
}

class _HydrationGoalCard extends StatelessWidget {
  final HydrationState hydrationState;
  final ValueChanged<int> onQuickLog;
  final VoidCallback onCustomLog;
  final VoidCallback onSetGoal;

  const _HydrationGoalCard({
    required this.hydrationState,
    required this.onQuickLog,
    required this.onCustomLog,
    required this.onSetGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = hydrationState.dailyGoal == 0
        ? 0.0
        : (hydrationState.totalIntake / hydrationState.dailyGoal).clamp(
            0.0,
            1.0,
          );
    final bool isGoalMet = hydrationState.dailyGoal > 0 && progress >= 1.0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: isGoalMet
          ? _HydrationSuccessCard(
              key: const ValueKey('hydration-success'),
              hydrationState: hydrationState,
              onCustomLog: onCustomLog,
              onSetGoal: onSetGoal,
            )
          : _HydrationGoalProgressCard(
              key: const ValueKey('hydration-progress'),
              hydrationState: hydrationState,
              progress: progress,
              theme: theme,
              onQuickLog: onQuickLog,
              onCustomLog: onCustomLog,
              onSetGoal: onSetGoal,
            ),
    );
  }
}

class _HydrationGoalProgressCard extends StatelessWidget {
  const _HydrationGoalProgressCard({
    super.key,
    required this.hydrationState,
    required this.progress,
    required this.theme,
    required this.onQuickLog,
    required this.onCustomLog,
    required this.onSetGoal,
  });

  final HydrationState hydrationState;
  final double progress;
  final ThemeData theme;
  final ValueChanged<int> onQuickLog;
  final VoidCallback onCustomLog;
  final VoidCallback onSetGoal;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      shadowColor: AppColors.cardShadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.local_drink_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Hydration goal',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(onPressed: onSetGoal, child: const Text('Set goal')),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${hydrationState.totalIntake} / ${hydrationState.dailyGoal} ml',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.chipBackground,
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () => onQuickLog(200),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('+200 ml'),
                ),
                FilledButton.tonal(
                  onPressed: () => onQuickLog(400),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                    foregroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('+400 ml'),
                ),
                OutlinedButton(
                  onPressed: onCustomLog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Custom amount'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HydrationSuccessCard extends StatelessWidget {
  const _HydrationSuccessCard({
    super.key,
    required this.hydrationState,
    required this.onCustomLog,
    required this.onSetGoal,
  });

  final HydrationState hydrationState;
  final VoidCallback onCustomLog;
  final VoidCallback onSetGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: AppColors.success,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppColors.success.withValues(alpha: 0.95),
              AppColors.success.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 88,
              width: 88,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Goal completed!',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${hydrationState.totalIntake} ml logged today.\nStay hydrated and keep it up!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(
                  onPressed: onCustomLog,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Log extra water'),
                ),
                TextButton(
                  onPressed: onSetGoal,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Adjust goal'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HydrationHistoryCard extends StatelessWidget {
  final HydrationState hydrationState;

  const _HydrationHistoryCard({required this.hydrationState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final history = hydrationState.logs.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Card(
      color: AppColors.cardBackground,
      shadowColor: AppColors.cardShadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hydration history'),
              subtitle: const Text('Track how consistent you are each day.'),
              trailing: IconButton(
                icon: const Icon(Icons.history),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Detailed hydration analytics coming soon.',
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              ),
            ),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No history yet. Log your water to see it here.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              )
            else
              ...history.take(5).map((log) {
                final timeLabel = localizations.formatTimeOfDay(
                  TimeOfDay.fromDateTime(log.timestamp),
                );
                final dateLabel = localizations.formatMediumDate(log.timestamp);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    child: Icon(
                      Icons.water_drop_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text('${log.amount} ml added'),
                  subtitle: Text('$dateLabel • $timeLabel'),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _PomodoroCard extends StatelessWidget {
  final PomodoroState pomodoroState;
  final ValueChanged<String> onPresetSelected;
  final Future<_PomodoroConfig?> Function() onCustomRequested;
  final VoidCallback onStartSession;

  const _PomodoroCard({
    required this.pomodoroState,
    required this.onPresetSelected,
    required this.onCustomRequested,
    required this.onStartSession,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: AppColors.cardBackground,
      shadowColor: AppColors.cardShadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.hourglass_bottom_outlined,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Pomodoro focus',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: PomodoroState.presets.map((preset) {
                String label = preset;
                if (preset == 'Custom' &&
                    pomodoroState.customWorkDuration != null &&
                    pomodoroState.customRestDuration != null) {
                  label =
                      'Custom ${pomodoroState.customWorkDuration!.inMinutes}/${pomodoroState.customRestDuration!.inMinutes} min';
                }
                final isSelected = pomodoroState.selectedPreset == preset;
                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  selectedColor: AppColors.secondary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: AppColors.chipBackground,
                  onSelected: (value) async {
                    if (!value) return;
                    onPresetSelected(preset);
                    if (preset == 'Custom' &&
                        pomodoroState.customWorkDuration == null &&
                        pomodoroState.customRestDuration == null) {
                      await onCustomRequested();
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStartSession,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Pomodoro'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdBanner extends StatelessWidget {
  final VoidCallback onUpgrade;

  const _AdBanner({required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppGradients.accent,
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.campaign_outlined, size: 32, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Ad — Upgrade to Premium to enjoy an ad-free experience.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onUpgrade,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}
