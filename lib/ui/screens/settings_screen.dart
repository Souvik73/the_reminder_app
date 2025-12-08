import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/hydration/hydration_cubit.dart';
import 'package:the_reminder_app/blocs/hydration/hydration_state.dart';
import 'package:the_reminder_app/blocs/subscription/subscription_cubit.dart';
import 'package:the_reminder_app/blocs/subscription/subscription_state.dart';
import 'package:the_reminder_app/ui/theme/app_colors.dart';
import 'package:the_reminder_app/ui/widgets/ad_banner.dart';
import 'package:the_reminder_app/ui/widgets/gradient_page_shell.dart';
import 'package:the_reminder_app/ui/widgets/subscription_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onOpenMenu});

  final VoidCallback? onOpenMenu;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
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
      listenWhen: (previous, current) =>
          previous.dailyGoal != current.dailyGoal,
      listener: (context, state) {
        setState(() => _goal = state.dailyGoal.toDouble());
      },
      child: GradientPageShell(
        icon: Icons.tune_outlined,
        title: 'Settings',
        subtitle: 'Customize notifications and hydration goals',
        leading: widget.onOpenMenu != null
            ? GradientHeaderButton(
                icon: Icons.menu_rounded,
                onPressed: widget.onOpenMenu!,
              )
            : null,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.pageBackground),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
            children: [
              Text(
                'General',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _styledSwitch(
                title: 'Enable smart notifications',
                subtitle: 'Get alerted based on urgency and schedule.',
                value: _notificationsEnabled,
                onChanged: (value) =>
                    setState(() => _notificationsEnabled = value),
              ),
              _styledSwitch(
                title: 'Personalized ads',
                subtitle: 'Tailor ads based on your preferences.',
                value: _adsPersonalized,
                onChanged: (value) => setState(() => _adsPersonalized = value),
              ),
              const SizedBox(height: 16),
              Text(
                'Hydration goal',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Card(
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
                      Text(
                        'Daily target: ${_goal.round()} ml',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Slider(
                        value: _goal,
                        min: 1500,
                        max: 4000,
                        divisions: 50,
                        label: '${_goal.round()} ml',
                        onChanged: (value) => setState(() => _goal = value),
                        onChangeEnd: (value) {
                          context.read<HydrationCubit>().setDailyGoal(
                            value.round(),
                          );
                        },
                      ),
                      Text(
                        'Adjust to match your lifestyle and activity level.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Premium',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _premiumCard(subscriptionState),
              if (!subscriptionState.isPremium) ...[
                const SizedBox(height: 16),
                AdBanner(onUpgrade: _openSubscriptionSheet),
              ],
              const SizedBox(height: 16),
              Text(
                'Support',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: AppColors.cardBackground,
                shadowColor: AppColors.cardShadow,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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
        ),
      ),
    );
  }

  Widget _styledSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      color: AppColors.cardBackground,
      shadowColor: AppColors.cardShadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title),
        subtitle: Text(subtitle),
        activeColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18),
      ),
    );
  }

  Widget _premiumCard(SubscriptionState subscriptionState) {
    final helperText = !subscriptionState.isSupportedPlatform
        ? 'In-app purchases are not supported on this platform.'
        : !subscriptionState.hasApiKey
            ? 'Add your RevenueCat public SDK key in lib/config/subscription_keys.dart.'
            : null;
    final isBusy =
        subscriptionState.isProcessing || subscriptionState.isLoading;

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
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: subscriptionState.isPremium
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.12),
                  child: Icon(
                    subscriptionState.isPremium
                        ? Icons.verified
                        : Icons.workspace_premium_outlined,
                    color: subscriptionState.isPremium
                        ? Colors.white
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscriptionState.isPremium
                            ? 'Premium unlocked'
                            : 'Upgrade to Premium',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subscriptionState.isPremium
                            ? 'Enjoy priority support and an ad-free experience.'
                            : 'Unlock advanced productivity tools, priority support, and an ad-free experience.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (helperText != null) ...[
              Text(
                helperText,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (subscriptionState.errorMessage != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subscriptionState.errorMessage!,
                        style: TextStyle(
                          color: Colors.red[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isBusy ? null : _openSubscriptionSheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isBusy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            subscriptionState.isPremium
                                ? 'Manage subscription'
                                : 'Purchase Premium',
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isBusy
                        ? null
                        : () => context.read<SubscriptionCubit>().restore(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isBusy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Restore purchases'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openSubscriptionSheet() {
    SubscriptionSheet.show(context);
  }
}
