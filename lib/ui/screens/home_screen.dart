import 'dart:async';

import 'package:flutter/material.dart';
import 'package:the_reminder_app/models/planner_models.dart';
import 'package:the_reminder_app/ui/screens/calendar_screen.dart';
import 'package:the_reminder_app/ui/screens/pomodoro_session_screen.dart';
import 'package:the_reminder_app/ui/screens/profile_screen.dart';
import 'package:the_reminder_app/ui/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  bool _isPremiumUser = false;

  final TextEditingController _quickReminderController = TextEditingController();
  final List<Reminder> _reminders = <Reminder>[];
  final Set<String> _completedReminderIds = <String>{};
  final List<AlarmEntry> _alarms = <AlarmEntry>[];
  final List<HydrationLog> _hydrationHistory = <HydrationLog>[];

  int _hydrationGoal = 2500;
  int _hydrationLogged = 0;

  String _selectedPomodoroPreset = '25/5 min';
  Duration? _customWorkDuration;
  Duration? _customRestDuration;

  List<String> get _pomodoroPresets => const ['25/5 min', '15/5 min', '50/10 min', 'Custom'];

  @override
  void initState() {
    super.initState();
    _seedInitialData();
  }

  @override
  void dispose() {
    _quickReminderController.dispose();
    super.dispose();
  }

  void _seedInitialData() {
    if (_reminders.isEmpty) {
      final now = DateTime.now();
      _reminders.addAll([
        Reminder(
          id: 'r1',
          title: 'Team sync',
          description: 'Daily stand-up with product team at 10:30 AM.',
          scheduledAt: now.add(const Duration(hours: 3)),
          priority: ReminderPriority.high,
        ),
        Reminder(
          id: 'r2',
          title: 'Pick up groceries',
          description: 'Include fresh veggies for dinner tonight.',
          scheduledAt: now.add(const Duration(hours: 6)),
          priority: ReminderPriority.medium,
        ),
        Reminder(
          id: 'r3',
          title: 'Read and unwind',
          description: 'Finish one chapter of the current book.',
          scheduledAt: now.add(const Duration(hours: 13)),
          priority: ReminderPriority.low,
          isVoiceCreated: true,
        ),
      ]);
      _reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    }

    if (_hydrationHistory.isEmpty) {
      final now = DateTime.now();
      _hydrationHistory.addAll([
        HydrationLog(id: 'h1', amount: 400, timestamp: now.subtract(const Duration(hours: 2))),
        HydrationLog(id: 'h2', amount: 250, timestamp: now.subtract(const Duration(hours: 5))),
        HydrationLog(id: 'h3', amount: 300, timestamp: now.subtract(const Duration(hours: 9))),
      ]);
      _hydrationLogged = _hydrationHistory.fold(0, (total, log) => total + log.amount);
    }

    if (_alarms.isEmpty) {
      _alarms.addAll([
        const AlarmEntry(
          id: 'a1',
          time: TimeOfDay(hour: 7, minute: 0),
          recurrence: 'Daily',
          label: 'Morning routine',
        ),
        const AlarmEntry(
          id: 'a2',
          time: TimeOfDay(hour: 21, minute: 30),
          recurrence: 'Every 2 days',
          label: 'Medication check',
        ),
      ]);
    }
  }

  List<Reminder> get _activeReminders =>
      _reminders.where((reminder) => !_completedReminderIds.contains(reminder.id)).toList();

  Map<ReminderPriority, List<Reminder>> _groupRemindersByPriority() {
    final grouped = <ReminderPriority, List<Reminder>>{
      ReminderPriority.high: [],
      ReminderPriority.medium: [],
      ReminderPriority.low: [],
    };

    for (final reminder in _activeReminders) {
      grouped[reminder.priority]?.add(reminder);
    }

    for (final list in grouped.values) {
      list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Home', 'Calendar', 'Settings', 'Profile'];
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(theme),
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        centerTitle: true,
        actions: _buildAppBarActions(),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(theme),
          CalendarScreen(reminders: _activeReminders, alarms: _alarms),
          SettingsScreen(
            isPremium: _isPremiumUser,
            hydrationGoal: _hydrationGoal,
            onPremiumChanged: _togglePremium,
            onHydrationGoalChanged: _updateHydrationGoal,
            onPurchaseTap: _handlePurchasePremium,
            onRestorePurchases: _handleRestorePurchases,
          ),
          ProfileScreen(
            isPremium: _isPremiumUser,
            hydrationGoal: _hydrationGoal,
            hydrationLogged: _hydrationLogged,
            hydrationHistory: _hydrationHistory,
            reminders: _activeReminders,
            onSubscriptionTap: _handleSubscriptionTap,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFab(),
    );
  }

  List<Widget> _buildAppBarActions() {
    switch (_currentIndex) {
      case 0:
        return [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _handleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.mic_none_outlined),
            onPressed: _handleVoiceCapture,
          ),
        ];
      case 1:
        return [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calendar filters coming soon.')),
              );
            },
          ),
        ];
      case 3:
        return [
          IconButton(
            icon: const Icon(Icons.manage_accounts_outlined),
            onPressed: _handleSubscriptionTap,
          ),
        ];
      default:
        return const [];
    }
  }

  Drawer _buildDrawer(ThemeData theme) {
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
              accountName: Text(_isPremiumUser ? 'Premium member' : 'Guest'),
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
              onTap: () => _setIndex(0),
            ),
            _DrawerTile(
              icon: Icons.calendar_month_outlined,
              label: 'Calendar',
              onTap: () => _setIndex(1),
            ),
            _DrawerTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => _setIndex(2),
            ),
            _DrawerTile(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () => _setIndex(3),
            ),
            const Divider(),
          ]
            ..add(
              _DrawerTile(
                icon: Icons.workspace_premium_outlined,
                label: _isPremiumUser ? 'Manage subscription' : 'Upgrade to Premium',
                onTap: _handleSubscriptionTap,
              ),
            )
            ..add(
              _DrawerTile(
                icon: Icons.help_outline,
                label: 'Help & support',
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Support center coming soon.')),
                  );
                },
              ),
            )
            ..add(const Spacer())
            ..add(
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Swipe reminders up to mark them complete. Use undo if you change your mind.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ),
      ),
    );
  }

  void _setIndex(int index) {
    Navigator.of(context).pop();
    setState(() => _currentIndex = index);
  }

  Widget _buildHomeTab(ThemeData theme) {
    final localizations = MaterialLocalizations.of(context);
    final grouped = _groupRemindersByPriority();

    return RefreshIndicator(
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
        children: [
          _buildQuickEntryCard(theme),
          const SizedBox(height: 24),
          if (_activeReminders.isEmpty) _buildEmptyRemindersState(theme),
          if (grouped[ReminderPriority.high]!.isNotEmpty)
            _buildReminderSection(
              title: 'High priority',
              accent: ReminderPriority.high.color,
              reminders: grouped[ReminderPriority.high]!,
              theme: theme,
              localizations: localizations,
            ),
          if (grouped[ReminderPriority.medium]!.isNotEmpty)
            _buildReminderSection(
              title: 'Medium priority',
              accent: ReminderPriority.medium.color,
              reminders: grouped[ReminderPriority.medium]!,
              theme: theme,
              localizations: localizations,
            ),
          if (grouped[ReminderPriority.low]!.isNotEmpty)
            _buildReminderSection(
              title: 'Low priority',
              accent: ReminderPriority.low.color,
              reminders: grouped[ReminderPriority.low]!,
              theme: theme,
              localizations: localizations,
            ),
          const SizedBox(height: 24),
          _buildAlarmCard(theme, localizations),
          const SizedBox(height: 24),
          _buildHydrationCard(theme),
          const SizedBox(height: 16),
          _buildWaterHistoryCard(theme, localizations),
          const SizedBox(height: 16),
          _buildPomodoroCard(theme),
          const SizedBox(height: 16),
          _buildGeofenceCard(theme),
          if (!_isPremiumUser) ...[
            const SizedBox(height: 16),
            _buildAdBanner(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickEntryCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _quickReminderController,
              decoration: InputDecoration(
                labelText: 'Quick reminder',
                hintText: 'e.g. Call the dentist tomorrow at 9am',
                prefixIcon: const Icon(Icons.edit_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: _createReminderFromText,
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _createReminderFromText(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.mic_none_outlined),
                    label: const Text('Capture voice'),
                    onPressed: _handleVoiceCapture,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.alarm_add_outlined),
                    label: const Text('Create alarm'),
                    onPressed: () => _openAlarmComposer(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSection({
    required String title,
    required Color accent,
    required List<Reminder> reminders,
    required ThemeData theme,
    required MaterialLocalizations localizations,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                  onEdit: () => _openReminderComposer(reminder: reminder),
                  onDelete: () => _deleteReminder(reminder),
                  onCompleted: () => _markReminderComplete(reminder),
                  localizations: localizations,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRemindersState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_none_rounded, size: 36, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'No upcoming reminders. Create one with text or voice to stay organized.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmCard(ThemeData theme, MaterialLocalizations localizations) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                child: Icon(Icons.alarm_outlined, color: theme.colorScheme.primary),
              ),
              title: const Text('Recurring alarms'),
              subtitle: const Text('Stay consistent with your routines.'),
              trailing: IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () => _openAlarmComposer(),
              ),
            ),
            if (_alarms.isEmpty)
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
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._alarms.map((alarm) {
                final timeLabel = localizations.formatTimeOfDay(alarm.time);
                return ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text(alarm.label),
                  subtitle: Text('${alarm.recurrence} • $timeLabel'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openAlarmComposer(existing: alarm);
                      } else if (value == 'delete') {
                        _deleteAlarm(alarm);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildHydrationCard(ThemeData theme) {
    final progress = _hydrationGoal == 0 ? 0.0 : (_hydrationLogged / _hydrationGoal).clamp(0.0, 1.0);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                  child: Icon(Icons.local_drink_outlined, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Hydration goal',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: _openHydrationGoalDialog,
                  child: const Text('Set goal'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$_hydrationLogged / $_hydrationGoal ml',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () => _addHydrationEntry(200),
                  child: const Text('+200 ml'),
                ),
                FilledButton.tonal(
                  onPressed: () => _addHydrationEntry(400),
                  child: const Text('+400 ml'),
                ),
                OutlinedButton(
                  onPressed: _openHydrationLogSheet,
                  child: const Text('Custom amount'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterHistoryCard(ThemeData theme, MaterialLocalizations localizations) {
    final history = _hydrationHistory.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                    const SnackBar(content: Text('Detailed hydration analytics coming soon.')),
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
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              )
            else
              ...history.take(5).map((log) {
                final timeLabel = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(log.timestamp));
                final dateLabel = localizations.formatMediumDate(log.timestamp);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(Icons.water_drop_outlined, color: theme.colorScheme.primary),
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

  Widget _buildPomodoroCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                  child: Icon(Icons.hourglass_bottom_outlined, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Pomodoro focus',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: _pomodoroPresets.map((preset) {
                String label = preset;
                if (preset == 'Custom' && _customWorkDuration != null && _customRestDuration != null) {
                  label = 'Custom ${_customWorkDuration!.inMinutes}/${_customRestDuration!.inMinutes} min';
                }
                return ChoiceChip(
                  label: Text(label),
                  selected: _selectedPomodoroPreset == preset,
                  onSelected: (selected) async {
                    if (!selected) return;
                    if (preset == 'Custom') {
                      final config = await _selectCustomIntervals();
                      if (config != null) {
                        setState(() {
                          _selectedPomodoroPreset = preset;
                          _customWorkDuration = config.work;
                          _customRestDuration = config.rest;
                        });
                      }
                    } else {
                      setState(() {
                        _selectedPomodoroPreset = preset;
                        _customWorkDuration = null;
                        _customRestDuration = null;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _startSelectedPomodoro();
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Pomodoro'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeofenceCard(ThemeData theme) {
    final geofencedReminders = _activeReminders.where((reminder) => reminder.isGeofenced).toList();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                  child: Icon(Icons.location_on_outlined, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Location-based reminders',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _isPremiumUser
                  ? 'Trigger reminders when you arrive at a selected place.'
                  : 'Upgrade to Premium to unlock geofenced reminders.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_location_alt_outlined),
                label: Text(_isPremiumUser ? 'Create geofenced reminder' : 'See premium benefits'),
                onPressed: _isPremiumUser
                    ? () => _openReminderComposer(initialTitle: 'Reminder when I arrive at...', isVoiceCreated: false)
                    : _handleSubscriptionTap,
              ),
            ),
            if (geofencedReminders.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: geofencedReminders.map((reminder) {
                  final location = reminder.locationName ?? 'Location';
                  return Chip(
                    avatar: const Icon(Icons.location_pin, size: 16),
                    label: Text(location),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondaryContainer,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.campaign_outlined, size: 32, color: theme.colorScheme.onSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Ad — Upgrade to Premium to enjoy an ad-free experience.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _handlePurchasePremium,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.onSecondary,
              foregroundColor: theme.colorScheme.secondary,
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  NavigationBar _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
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
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  FloatingActionButton _buildFab() {
    return FloatingActionButton.extended(
      onPressed: _showCreationSheet,
      icon: const Icon(Icons.add_rounded),
      label: const Text('New'),
    );
  }

  Future<void> _showCreationSheet() async {
    await showModalBottomSheet<void>(
      context: context,
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
                leading: const Icon(Icons.mic_none_outlined),
                title: const Text('New reminder (voice)'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleVoiceCapture();
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
                  _startSelectedPomodoro();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _createReminderFromText() {
    final text = _quickReminderController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a reminder description first.')),
      );
      return;
    }
    final reminder = Reminder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: text,
      description: '',
      scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      priority: ReminderPriority.medium,
    );
    _quickReminderController.clear();
    _saveReminder(reminder);
  }

  void _saveReminder(Reminder reminder) {
    setState(() {
      final index = _reminders.indexWhere((element) => element.id == reminder.id);
      if (index >= 0) {
        _reminders[index] = reminder;
      } else {
        _reminders.add(reminder);
      }
      _reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      _completedReminderIds.remove(reminder.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder "${reminder.title}" saved.')),
    );
  }

  void _deleteReminder(Reminder reminder) {
    setState(() {
      _reminders.removeWhere((element) => element.id == reminder.id);
      _completedReminderIds.remove(reminder.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder "${reminder.title}" deleted.')),
    );
  }

  void _markReminderComplete(Reminder reminder) {
    final index = _reminders.indexWhere((element) => element.id == reminder.id);
    setState(() {
      _completedReminderIds.add(reminder.id);
      if (index >= 0) {
        _reminders.removeAt(index);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked "${reminder.title}" as complete.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _completedReminderIds.remove(reminder.id);
              if (index >= 0) {
                _reminders.insert(index, reminder);
              } else {
                _reminders.add(reminder);
                _reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
              }
            });
          },
        ),
      ),
    );
  }

  Future<void> _openReminderComposer({
    Reminder? reminder,
    bool isVoiceCreated = false,
    String? initialTitle,
    String? initialDescription,
  }) async {
    final rootContext = context;
    final titleController = TextEditingController(text: initialTitle ?? reminder?.title ?? '');
    final detailsController = TextEditingController(text: initialDescription ?? reminder?.description ?? '');
    DateTime scheduledAt = reminder?.scheduledAt ?? DateTime.now().add(const Duration(hours: 1));
    ReminderPriority priority = reminder?.priority ?? ReminderPriority.medium;
    bool voiceCreated = reminder?.isVoiceCreated ?? isVoiceCreated;
    bool geofenced = reminder?.isGeofenced ?? false;
    String? locationName = reminder?.locationName;

    final updatedReminder = await showModalBottomSheet<Reminder>(
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
                      reminder == null ? 'Create reminder' : 'Edit reminder',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
                      controller: detailsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Add extra details or context (optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event_outlined),
                            label: Text(MaterialLocalizations.of(context).formatMediumDate(scheduledAt)),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: scheduledAt,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (pickedDate != null) {
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(scheduledAt),
                                );
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
                            decoration: const InputDecoration(labelText: 'Priority'),
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
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: voiceCreated,
                      onChanged: (value) => setModalState(() => voiceCreated = value),
                      title: const Text('Captured via voice'),
                      subtitle: const Text('Keep track of reminders created with voice input.'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isPremiumUser && geofenced,
                      onChanged: (value) async {
                        if (!_isPremiumUser) {
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            const SnackBar(content: Text('Upgrade to Premium to enable geofenced reminders.')),
                          );
                          return;
                        }
                        if (value) {
                          final selected = await _pickLocation();
                          if (selected != null) {
                            setModalState(() {
                              geofenced = true;
                              locationName = selected;
                            });
                          }
                        } else {
                          setModalState(() {
                            geofenced = false;
                            locationName = null;
                          });
                        }
                      },
                      title: const Text('Trigger on arrival'),
                      subtitle: Text(
                        !_isPremiumUser
                            ? 'Premium feature'
                            : locationName == null
                                ? 'Select a location to trigger this reminder.'
                                : 'Location: $locationName',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(rootContext).showSnackBar(
                              const SnackBar(content: Text('Please add a title to your reminder.')),
                            );
                            return;
                          }
                          final id = reminder?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
                          Navigator.of(context).pop(
                            Reminder(
                              id: id,
                              title: titleController.text.trim(),
                              description: detailsController.text.trim(),
                              scheduledAt: scheduledAt,
                              priority: priority,
                              isVoiceCreated: voiceCreated,
                              isGeofenced: _isPremiumUser && geofenced && locationName != null,
                              locationName: _isPremiumUser ? locationName : null,
                            ),
                          );
                        },
                        child: Text(reminder == null ? 'Create' : 'Save changes'),
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

    // titleController.dispose();
    // detailsController.dispose();

    if (updatedReminder != null) {
      _saveReminder(updatedReminder);
    }
  }

  Future<String?> _pickLocation() async {
    if (!mounted) return null;
    const options = ['Home', 'Work', 'Gym', 'Supermarket', 'Pharmacy'];
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select a location'),
        children: [
          for (final option in options)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(option),
              child: Text(option),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAlarmComposer({AlarmEntry? existing}) async {
    final labelController = TextEditingController(text: existing?.label ?? '');
    TimeOfDay selectedTime = existing?.time ?? TimeOfDay.now();
    const recurrenceOptions = ['Daily', 'Weekdays', 'Weekends', 'Weekly', 'Custom'];
    String recurrence = existing?.recurrence ?? 'Daily';
    String customRecurrence = existing != null && !recurrenceOptions.contains(existing.recurrence)
        ? existing.recurrence
        : 'Every 3 days';
    bool isCustom = recurrence == 'Custom' || (!recurrenceOptions.contains(recurrence));

    final newAlarm = await showModalBottomSheet<AlarmEntry>(
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
                  children: [
                    Text(
                      existing == null ? 'Create alarm' : 'Edit alarm',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
                      label: Text(MaterialLocalizations.of(context).formatTimeOfDay(selectedTime)),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
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
                        final selected = isCustom ? option == 'Custom' : recurrence == option;
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
                          final recurrenceLabel =
                              isCustom ? customRecurrence.trim() : recurrence;
                          Navigator.of(context).pop(
                            AlarmEntry(
                              id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                              time: selectedTime,
                              recurrence: recurrenceLabel.isEmpty ? 'Custom interval' : recurrenceLabel,
                              label: label,
                            ),
                          );
                        },
                        child: Text(existing == null ? 'Create alarm' : 'Save changes'),
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

    labelController.dispose();

    if (newAlarm != null) {
      _saveAlarm(newAlarm);
    }
  }

  void _saveAlarm(AlarmEntry alarm) {
    setState(() {
      final index = _alarms.indexWhere((element) => element.id == alarm.id);
      if (index >= 0) {
        _alarms[index] = alarm;
      } else {
        _alarms.add(alarm);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Alarm "${alarm.label}" saved.')),
    );
  }

  void _deleteAlarm(AlarmEntry alarm) {
    setState(() {
      _alarms.removeWhere((element) => element.id == alarm.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Alarm "${alarm.label}" removed.')),
    );
  }

  Future<void> _openHydrationLogSheet() async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _addHydrationEntry(200);
                    },
                    child: const Text('+200 ml'),
                  ),
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _addHydrationEntry(400);
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
                        const SnackBar(content: Text('Enter a positive amount.')),
                      );
                      return;
                    }
                    Navigator.of(context).pop();
                    _addHydrationEntry(value);
                  },
                  child: const Text('Log hydration'),
                ),
              ),
            ],
          ),
        );
      },
      isScrollControlled: true,
    );
    controller.dispose();
  }

  void _addHydrationEntry(int amount) {
    setState(() {
      final log = HydrationLog(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        amount: amount,
        timestamp: DateTime.now(),
      );
      _hydrationHistory.add(log);
      _hydrationLogged += amount;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged $amount ml of water.')),
    );
  }

  void _updateHydrationGoal(int newGoal) {
    setState(() {
      _hydrationGoal = newGoal;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hydration goal set to $newGoal ml.')),
    );
  }

  Future<void> _openHydrationGoalDialog() async {
    final controller = TextEditingController(text: _hydrationGoal.toString());
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
                  const SnackBar(content: Text('Enter at least 1000 ml.')),
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
    controller.dispose();
    if (newGoal != null) {
      _updateHydrationGoal(newGoal);
    }
  }

  Future<void> _handleVoiceCapture() async {
    final recognized = await _simulateVoiceCapture();
    if (recognized != null && recognized.isNotEmpty) {
      _openReminderComposer(
        isVoiceCreated: true,
        initialTitle: recognized,
      );
    }
  }

  Future<String?> _simulateVoiceCapture() async {
    if (!mounted) return null;
    const suggestions = [
      'Call Dr. Singh tomorrow at 9am',
      'Buy birthday gift when near the mall',
      'Start Pomodoro at 3pm for coding session',
    ];
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Simulated voice input'),
        children: [
          for (final suggestion in suggestions)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(suggestion),
              child: Text(suggestion),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Future<_PomodoroConfig?> _selectCustomIntervals() async {
    final workController =
        TextEditingController(text: (_customWorkDuration ?? const Duration(minutes: 25)).inMinutes.toString());
    final restController =
        TextEditingController(text: (_customRestDuration ?? const Duration(minutes: 5)).inMinutes.toString());
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
                  const SnackBar(content: Text('Use positive numbers for custom intervals.')),
                );
                return;
              }
              Navigator.of(context).pop(
                _PomodoroConfig(Duration(minutes: work), Duration(minutes: rest)),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    workController.dispose();
    restController.dispose();
    return config;
  }

  Future<void> _startSelectedPomodoro() async {
    Duration work;
    Duration rest;

    switch (_selectedPomodoroPreset) {
      case '15/5 min':
        work = const Duration(minutes: 15);
        rest = const Duration(minutes: 5);
        break;
      case '50/10 min':
        work = const Duration(minutes: 50);
        rest = const Duration(minutes: 10);
        break;
      case 'Custom':
        if (_customWorkDuration == null || _customRestDuration == null) {
          final config = await _selectCustomIntervals();
          if (config == null) return;
          setState(() {
            _customWorkDuration = config.work;
            _customRestDuration = config.rest;
          });
        }
        work = _customWorkDuration ?? const Duration(minutes: 25);
        rest = _customRestDuration ?? const Duration(minutes: 5);
        break;
      case '25/5 min':
      default:
        work = const Duration(minutes: 25);
        rest = const Duration(minutes: 5);
        break;
    }

    _startPomodoroSession(work, rest);
  }

  void _startPomodoroSession(Duration work, Duration rest) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PomodoroSessionScreen(
          workDuration: work,
          restDuration: rest,
        ),
      ),
    );
  }

  void _handleSearch() {
    final reminders = _activeReminders;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
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
                            subtitle: Text(reminder.description.isEmpty
                                ? reminder.priority.label
                                : reminder.description),
                            onTap: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(content: Text('Open reminder "${reminder.title}"')),
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

  void _togglePremium(bool value) {
    setState(() => _isPremiumUser = value);
  }

  void _handlePurchasePremium() {
    setState(() => _isPremiumUser = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Premium activated. Enjoy geofenced reminders and no ads!')),
    );
  }

  void _handleRestorePurchases() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attempting to restore purchases...')),
    );
  }

  void _handleSubscriptionTap() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                _isPremiumUser ? 'Manage your Premium plan' : 'Upgrade to Premium',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _isPremiumUser
                    ? 'Adjust your subscription, manage billing, or contact support.'
                    : 'Unlock geofenced reminders, advanced Pomodoro analytics, and an ad-free experience.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (_isPremiumUser) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Subscription portal coming soon.')),
                      );
                    } else {
                      _handlePurchasePremium();
                    }
                  },
                  child: Text(_isPremiumUser ? 'Manage subscription' : 'Upgrade now'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
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

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
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
    final timeLabel = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(reminder.scheduledAt));
    final dueLabel = _formatDue(reminder.scheduledAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey(reminder.id),
        direction: DismissDirection.up,
        confirmDismiss: (direction) async => direction == DismissDirection.up,
        onDismissed: (_) => onCompleted(),
        background: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 36),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
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
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.15),
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
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                        if (reminder.isVoiceCreated)
                          const Chip(
                            avatar: Icon(Icons.mic_none_outlined, size: 16),
                            label: Text('Voice'),
                          ),
                        if (reminder.isGeofenced && reminder.locationName != null)
                          Chip(
                            avatar: const Icon(Icons.location_on_outlined, size: 16),
                            label: Text(reminder.locationName!),
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
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
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
