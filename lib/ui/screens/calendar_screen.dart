import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/alarm/alarm_cubit.dart';
import 'package:the_reminder_app/blocs/reminder/reminder_bloc.dart';
import 'package:the_reminder_app/models/planner_models.dart';
import 'package:the_reminder_app/ui/theme/app_colors.dart';
import 'package:the_reminder_app/ui/theme/app_gradients.dart';
import 'package:the_reminder_app/ui/widgets/gradient_page_shell.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.onOpenMenu});

  final VoidCallback? onOpenMenu;

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

    final subtitle = _selectedDay == null
        ? 'Tap a day to filter reminders'
        : 'Showing reminders for ${localizations.formatMediumDate(_selectedDay!)}';

    return GradientPageShell(
      icon: Icons.calendar_month_outlined,
      title: 'Calendar',
      subtitle: subtitle,
      leading: widget.onOpenMenu != null
          ? GradientHeaderButton(
              icon: Icons.menu_rounded,
              onPressed: widget.onOpenMenu!,
            )
          : null,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.pageBackground),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: CalendarDatePicker(
                currentDate: DateTime.now(),
                firstDate: DateTime(DateTime.now().year - 1),
                lastDate: DateTime(DateTime.now().year + 2),
                initialDate: _focusedDay,
                onDateChanged: (date) {
                  setState(() => _selectedDay = date);
                },
                onDisplayedMonthChanged: (date) {
                  setState(() => _focusedDay = date);
                },
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
                children: [
                  if (filteredReminders.isEmpty)
                    _EmptyStateCard(
                      title: 'No reminders',
                      description: _selectedDay == null
                          ? 'Create a reminder to see it on your calendar.'
                          : 'No reminders are scheduled for this day.',
                      icon: Icons.event_available_outlined,
                    )
                  else
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
        ),
      ),
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
          color: AppColors.cardBackground,
          shadowColor: AppColors.cardShadow,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                        color: AppColors.primary,
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
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    timeLabel,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (reminder.description.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  reminder.description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
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
      return const SizedBox.shrink();
    }

    return Card(
      color: AppColors.cardBackground,
      shadowColor: AppColors.cardShadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.alarm_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Scheduled alarms',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...alarms.map((alarm) {
              final timeLabel = localizations.formatTimeOfDay(alarm.time);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        alarm.recurrence,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alarm.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                          ),
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
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
