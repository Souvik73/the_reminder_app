import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/hydration/hydration_cubit.dart';
import 'package:the_reminder_app/blocs/hydration/hydration_state.dart';
import 'package:the_reminder_app/blocs/subscription/subscription_cubit.dart';
import 'package:the_reminder_app/blocs/subscription/subscription_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _voiceShortcutsEnabled = true;
  bool _adsPersonalized = true;
  late double _goal;

  @override
  void initState() {
    super.initState();
    _goal = context.read<HydrationCubit>().state.dailyGoal.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscriptionState = context.watch<SubscriptionCubit>().state;

    return BlocListener<HydrationCubit, HydrationState>(
      listenWhen: (previous, current) => previous.dailyGoal != current.dailyGoal,
      listener: (context, state) {
        setState(() => _goal = state.dailyGoal.toDouble());
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
        children: [
          Text(
            'General',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
            title: const Text('Enable smart notifications'),
            subtitle: const Text('Get alerted based on urgency and location.'),
          ),
          SwitchListTile(
            value: _voiceShortcutsEnabled,
            onChanged: (value) => setState(() => _voiceShortcutsEnabled = value),
            title: const Text('Voice shortcuts'),
            subtitle: const Text('Allow voice commands for quick reminders.'),
          ),
          SwitchListTile(
            value: _adsPersonalized,
            onChanged: (value) => setState(() => _adsPersonalized = value),
            title: const Text('Personalized ads'),
            subtitle: const Text('Tailor ads based on your preferences.'),
          ),
          const SizedBox(height: 24),
          Text(
            'Hydration goal',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily target: ${_goal.round()} ml',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: _goal,
                    min: 1500,
                    max: 4000,
                    divisions: 50,
                    label: '${_goal.round()} ml',
                    onChanged: (value) => setState(() => _goal = value),
                    onChangeEnd: (value) {
                      context.read<HydrationCubit>().setDailyGoal(value.round());
                    },
                  ),
                  Text(
                    'Adjust to match your lifestyle and activity level.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Premium',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: subscriptionState.isPremium
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withOpacity(0.12),
                        child: Icon(
                          subscriptionState.isPremium ? Icons.verified : Icons.workspace_premium_outlined,
                          color: subscriptionState.isPremium ? Colors.white : theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subscriptionState.isPremium ? 'Premium unlocked' : 'Upgrade to Premium',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subscriptionState.isPremium
                                  ? 'Enjoy geofenced reminders and an ad-free experience.'
                                  : 'Unlock geofenced reminders, priority support, and an ad-free experience.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: subscriptionState.isPremium
                              ? null
                              : () {
                                  context.read<SubscriptionCubit>().upgrade();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Premium activated. Enjoy the upgrade!')),
                                  );
                                },
                          child: const Text('Purchase Premium'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: subscriptionState.isPremium
                              ? () {
                                  context.read<SubscriptionCubit>().downgrade();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Premium disabled.')),
                                  );
                                }
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Attempting to restore purchases...')),
                                  );
                                },
                          child: Text(subscriptionState.isPremium ? 'Downgrade' : 'Restore purchases'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Support',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.headset_mic_outlined),
                  title: const Text('Help & FAQs'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Privacy policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: const Text('Terms of service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
