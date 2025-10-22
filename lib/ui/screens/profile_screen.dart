import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/hydration/hydration_cubit.dart';
import 'package:the_reminder_app/blocs/hydration/hydration_state.dart';
import 'package:the_reminder_app/blocs/reminder/reminder_bloc.dart';
import 'package:the_reminder_app/blocs/reminder/reminder_state.dart';
import 'package:the_reminder_app/blocs/subscription/subscription_cubit.dart';
import 'package:the_reminder_app/blocs/subscription/subscription_state.dart';
import 'package:the_reminder_app/models/planner_models.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subscriptionState = context.watch<SubscriptionCubit>().state;
    final hydrationState = context.watch<HydrationCubit>().state;
    final reminderState = context.watch<ReminderBloc>().state;
    final reminders = reminderState.reminders;
    final hydrationGoal = hydrationState.dailyGoal;
    final hydrationLogged = hydrationState.totalIntake;
    final hydrationHistory = hydrationState.logs;
    final isPremium = subscriptionState.isPremium;

    final theme = Theme.of(context);
    final progress = hydrationGoal == 0
        ? 0.0
        : (hydrationLogged / hydrationGoal).clamp(0.0, 1.0);
    final localizations = MaterialLocalizations.of(context);

    final recentHydration = hydrationHistory.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                  child: Icon(
                    Icons.person_outline,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hey there!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPremium ? 'Premium subscriber' : 'Free plan user',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      if (isPremium) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: theme.colorScheme.primary.withOpacity(0.12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.workspace_premium,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Premium active',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.manage_accounts_outlined),
                  onPressed: () =>
                      _showSubscriptionSheet(context, subscriptionState),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Productivity overview',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notifications_active_outlined),
                      const SizedBox(height: 12),
                      Text(
                        '${reminders.length}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upcoming reminders',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.local_drink_outlined),
                      const SizedBox(height: 12),
                      Text(
                        '${hydrationLogged} / $hydrationGoal ml',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: theme.colorScheme.primary.withOpacity(
                          0.12,
                        ),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hydration progress',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Recent hydration',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (recentHydration.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.water_drop_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No hydration entries yet. Log your water intake to see history here.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentHydration.length > 5
                  ? 5
                  : recentHydration.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final log = recentHydration[index];
                final timeLabel = localizations.formatTimeOfDay(
                  TimeOfDay.fromDateTime(log.timestamp),
                );
                final dateLabel = localizations.formatMediumDate(log.timestamp);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(
                      0.12,
                    ),
                    child: Icon(
                      Icons.local_drink,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text('${log.amount} ml logged'),
                  subtitle: Text('$dateLabel • $timeLabel'),
                );
              },
            ),
          ),
        const SizedBox(height: 24),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscription',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isPremium
                      ? 'Thanks for supporting us! Manage or adjust your plan any time.'
                      : 'Upgrade to Premium for geofenced reminders, Pomodoro insights, and an ad-free experience.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        _showSubscriptionSheet(context, subscriptionState),
                    child: Text(
                      isPremium ? 'Manage subscription' : 'Upgrade to Premium',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSubscriptionSheet(
    BuildContext rootContext,
    SubscriptionState state,
  ) {
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
                state.isPremium
                    ? 'Manage your Premium plan'
                    : 'Upgrade to Premium',
                style: Theme.of(
                  rootContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                state.isPremium
                    ? 'Adjust your subscription, manage billing, or contact support.'
                    : 'Unlock geofenced reminders, advanced Pomodoro analytics, and an ad-free experience.',
                textAlign: TextAlign.center,
                style: Theme.of(rootContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    rootContext,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final cubit = rootContext.read<SubscriptionCubit>();
                    if (state.isPremium) {
                      cubit.downgrade();
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(content: Text('Premium disabled.')),
                      );
                    } else {
                      cubit.upgrade();
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Premium activated. Enjoy the upgrade!',
                          ),
                        ),
                      );
                    }
                    Navigator.of(sheetContext).pop();
                  },
                  child: Text(
                    state.isPremium ? 'Downgrade to free' : 'Upgrade now',
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
