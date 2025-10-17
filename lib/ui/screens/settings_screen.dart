import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final bool isPremium;
  final int hydrationGoal;
  final ValueChanged<bool> onPremiumChanged;
  final ValueChanged<int> onHydrationGoalChanged;
  final VoidCallback onPurchaseTap;
  final VoidCallback onRestorePurchases;

  const SettingsScreen({
    super.key,
    required this.isPremium,
    required this.hydrationGoal,
    required this.onPremiumChanged,
    required this.onHydrationGoalChanged,
    required this.onPurchaseTap,
    required this.onRestorePurchases,
  });

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
    _goal = widget.hydrationGoal.toDouble();
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hydrationGoal != widget.hydrationGoal) {
      _goal = widget.hydrationGoal.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
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
                    widget.onHydrationGoalChanged(value.round());
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
                      backgroundColor: widget.isPremium
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withOpacity(0.12),
                      child: Icon(
                        widget.isPremium ? Icons.verified : Icons.workspace_premium_outlined,
                        color: widget.isPremium ? Colors.white : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isPremium ? 'Premium unlocked' : 'Upgrade to Premium',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isPremium
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
                        onPressed: widget.isPremium ? null : widget.onPurchaseTap,
                        child: const Text('Purchase Premium'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.isPremium
                            ? () => widget.onPremiumChanged(false)
                            : widget.onRestorePurchases,
                        child: Text(widget.isPremium ? 'Downgrade' : 'Restore purchases'),
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
    );
  }
}
