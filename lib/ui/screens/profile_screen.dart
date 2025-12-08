import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/hydration/hydration_cubit.dart';
import 'package:the_reminder_app/blocs/onboarding/auth_bloc.dart';
import 'package:the_reminder_app/blocs/reminder/reminder_bloc.dart';
import 'package:the_reminder_app/blocs/subscription/subscription_cubit.dart';
import 'package:the_reminder_app/blocs/subscription/subscription_state.dart';
import 'package:the_reminder_app/models/planner_models.dart';
import 'package:the_reminder_app/ui/theme/app_colors.dart';
import 'package:the_reminder_app/ui/theme/app_gradients.dart';
import 'package:the_reminder_app/ui/widgets/ad_banner.dart';
import 'package:the_reminder_app/ui/widgets/gradient_page_shell.dart';
import 'package:the_reminder_app/ui/widgets/subscription_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.onOpenMenu});

  final VoidCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final subscriptionState = context.watch<SubscriptionCubit>().state;
    final hydrationState = context.watch<HydrationCubit>().state;
    final reminderState = context.watch<ReminderBloc>().state;
    final reminders = reminderState.reminders;
    final hydrationGoal = hydrationState.dailyGoal;
    final hydrationLogged = hydrationState.totalIntake;
    final hydrationHistory = hydrationState.logs;

    final theme = Theme.of(context);
    final progress = hydrationGoal == 0
        ? 0.0
        : (hydrationLogged / hydrationGoal).clamp(0.0, 1.0);
    final localizations = MaterialLocalizations.of(context);

    final recentHydration = hydrationHistory.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final isPremium = subscriptionState.isPremium;

    return GradientPageShell(
      icon: Icons.person_outline,
      title: 'Profile',
      subtitle: isPremium
          ? 'Premium subscriber insights'
          : 'Track your productivity and hydration',
      leading: onOpenMenu != null
          ? GradientHeaderButton(
              icon: Icons.menu_rounded,
              onPressed: onOpenMenu!,
            )
          : null,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.pageBackground),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
          children: [
            _ProfileHeaderCard(
              isPremium: isPremium,
              subscriptionState: subscriptionState,
              reminders: reminders.length,
              userName: _friendlyFirstName(authState),
            ),
            const SizedBox(height: 16),
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
                  child: _MetricCard(
                    icon: Icons.notifications_active_outlined,
                    value: '${reminders.length}',
                    label: 'Upcoming reminders',
                    iconColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _HydrationMetricCard(
                    progress: progress,
                    hydrationGoal: hydrationGoal,
                    hydrationLogged: hydrationLogged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Recent hydration',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (recentHydration.isEmpty)
              const _EmptyHydrationState()
            else
              _HydrationHistoryList(
                logs: recentHydration,
                localizations: localizations,
              ),
            const SizedBox(height: 16),
            _QuickActionsCard(isPremium: isPremium),
            const SizedBox(height: 16),
            if (!isPremium) ...[
              AdBanner(onUpgrade: () => _showUpgradePrompt(context)),
              const SizedBox(height: 16),
            ],
            Card(
              color: AppColors.cardBackground,
              shadowColor: AppColors.cardShadow,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Sign out'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _friendlyFirstName(AuthState state) {
    if (state is AuthSuccess) {
      final fromName = _firstName(state.displayName);
      if (fromName != null) return fromName;
      final fromEmail = _firstName(state.email);
      if (fromEmail != null) return fromEmail;
    }
    return 'there';
  }

  String? _firstName(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed
        .split(RegExp('[\\s._-]+'))
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    final lower = parts.first.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  void _showUpgradePrompt(BuildContext context) {
    SubscriptionSheet.show(context);
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.isPremium,
    required this.subscriptionState,
    required this.reminders,
    required this.userName,
  });

  final bool isPremium;
  final SubscriptionState subscriptionState;
  final int reminders;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: AppColors.cardBackground,
      shadowColor: AppColors.cardShadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: const Icon(
                Icons.person_outline,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hey $userName!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPremium ? 'Premium subscriber' : 'Free plan user',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoPill(
                        icon: Icons.notifications_active_outlined,
                        label: '$reminders reminders',
                        color: AppColors.primary,
                      ),
                      if (isPremium)
                        _InfoPill(
                          icon: Icons.workspace_premium,
                          label: 'Premium active',
                          color: AppColors.secondary,
                        ),
                    ],
                  ),
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
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            Icon(icon, color: iconColor),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HydrationMetricCard extends StatelessWidget {
  const _HydrationMetricCard({
    required this.progress,
    required this.hydrationGoal,
    required this.hydrationLogged,
  });

  final double progress;
  final int hydrationGoal;
  final int hydrationLogged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGoalMet = hydrationGoal > 0 && hydrationLogged >= hydrationGoal;
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
            const Icon(Icons.local_drink_outlined, color: AppColors.secondary),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    '$hydrationLogged / $hydrationGoal ml',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isGoalMet) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.chipBackground,
              color: AppColors.secondary,
              minHeight: 6,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 8),
            Text(
              isGoalMet ? 'Goal completed for today' : 'Hydration progress',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isGoalMet
                    ? AppColors.success
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: isGoalMet ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHydrationState extends StatelessWidget {
  const _EmptyHydrationState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.subtle,
        borderRadius: BorderRadius.circular(18),
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
          const Icon(Icons.water_drop_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hydration entries yet. Log your water intake to see history here.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HydrationHistoryList extends StatelessWidget {
  const _HydrationHistoryList({
    required this.logs,
    required this.localizations,
  });

  final List<HydrationLog> logs;
  final MaterialLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    final visibleLogs = logs.length > 6 ? logs.take(6).toList() : logs;

    return Card(
      color: AppColors.cardBackground,
      shadowColor: AppColors.cardShadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: visibleLogs.length,
        separatorBuilder: (context, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final log = visibleLogs[index];
          final timeLabel = localizations.formatTimeOfDay(
            TimeOfDay.fromDateTime(log.timestamp),
          );
          final dateLabel = localizations.formatMediumDate(log.timestamp);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: const Icon(Icons.local_drink, color: AppColors.primary),
            ),
            title: Text('$timeLabel • ${log.amount} ml'),
            subtitle: Text(dateLabel),
          );
        },
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.star_rounded, color: AppColors.secondary),
                SizedBox(width: 12),
                Text(
                  'Quick actions',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickChip(
                  icon: Icons.notifications_active_outlined,
                  label: 'Create reminder',
                  onTap: () {},
                ),
                _QuickChip(
                  icon: Icons.alarm_add_outlined,
                  label: 'Schedule alarm',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.chipBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showSubscriptionSheet(
  BuildContext context,
  SubscriptionState subscriptionState,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subscriptionState.isPremium
                  ? 'Manage your premium plan'
                  : 'Upgrade to Premium',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Enjoy location-based reminders, focus tools, and an ad-free experience.',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
