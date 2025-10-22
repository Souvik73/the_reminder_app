import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/alarm/alarm_cubit.dart';
import 'package:the_reminder_app/blocs/reminder/reminder_bloc.dart';
import 'package:the_reminder_app/models/planner_models.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final reminderState = context.watch<ReminderBloc>().state;
    final alarmState = context.watch<AlarmCubit>().state;
    final reminders =
        reminderState.reminders
            .where(
              (reminder) => reminder.scheduledAt.isAfter(
                DateTime.now().subtract(const Duration(days: 1)),
              ),
            )
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final alarms = alarmState.alarms;

    final filteredReminders = _selectedDay == null
        ? reminders
        : reminders.where((reminder) {
            final scheduled = reminder.scheduledAt;
            return scheduled.year == _selectedDay!.year &&
                scheduled.month == _selectedDay!.month &&
                scheduled.day == _selectedDay!.day;
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan your schedule',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _selectedDay == null
                    ? 'Tap a day to filter reminders'
                    : 'Showing reminders for ${localizations.formatMediumDate(_selectedDay!)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        CalendarDatePicker(
          currentDate: DateTime.now(),
          firstDate: DateTime(DateTime.now().year - 1),
          lastDate: DateTime(DateTime.now().year + 2),
          initialDate: _focusedDay,
          onDateChanged: (date) {
            setState(() {
              _selectedDay = date;
            });
          },
          onDisplayedMonthChanged: (date) {
            setState(() {
              _focusedDay = date;
            });
          },
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              if (filteredReminders.isEmpty)
                _EmptyStateCard(
                  title: 'No reminders',
                  description: _selectedDay == null
                      ? 'Create a reminder to see it on your calendar.'
                      : 'No reminders are scheduled for this day.',
                  icon: Icons.event_available_outlined,
                ),
              ..._buildReminderSections(
                filteredReminders,
                localizations,
                theme,
              ),
              const SizedBox(height: 24),
              _buildAlarmSection(alarms, theme, localizations),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildReminderSections(
    List<Reminder> reminders,
    MaterialLocalizations localizations,
    ThemeData theme,
  ) {
    final grouped = <DateTime, List<Reminder>>{};
    for (final reminder in reminders) {
      final key = DateTime(
        reminder.scheduledAt.year,
        reminder.scheduledAt.month,
        reminder.scheduledAt.day,
      );
      grouped.putIfAbsent(key, () => []).add(reminder);
    }

    final orderedKeys = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

    return orderedKeys.map((date) {
      final entries = grouped[date]!
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.formatMediumDate(date),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${entries.length} reminder${entries.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...entries.map((reminder) {
                  final timeOfDay = TimeOfDay.fromDateTime(
                    reminder.scheduledAt,
                  );
                  final timeLabel = localizations.formatTimeOfDay(
                    timeOfDay,
                    alwaysUse24HourFormat: false,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: reminder.priority.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            reminder.priority.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: reminder.priority.color,
                              fontWeight: FontWeight.w600,
                            ),
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
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    timeLabel,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                              if (reminder.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  reminder.description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                              if (reminder.isGeofenced &&
                                  reminder.locationName != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      reminder.locationName!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildAlarmSection(
    List<AlarmEntry> alarms,
    ThemeData theme,
    MaterialLocalizations localizations,
  ) {
    if (alarms.isEmpty) {
      return _EmptyStateCard(
        title: 'No alarms yet',
        description: 'Set up recurring alarms to stay on track.',
        icon: Icons.alarm_add_outlined,
      );
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alarms',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${alarms.length} active',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...alarms.map((alarm) {
              final timeLabel = localizations.formatTimeOfDay(alarm.time);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                  child: Icon(Icons.alarm, color: theme.colorScheme.primary),
                ),
                title: Text(
                  alarm.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${alarm.recurrence} • $timeLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _EmptyStateCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: theme.colorScheme.primary.withOpacity(0.8),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
