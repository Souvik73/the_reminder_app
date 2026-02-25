import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_reminder_app/blocs/hydration/hydration_cubit.dart';
import 'package:the_reminder_app/blocs/hydration/hydration_state.dart';
import 'package:the_reminder_app/config/legal_links.dart';
import 'package:the_reminder_app/ui/theme/app_colors.dart';
import 'package:the_reminder_app/ui/widgets/ad_banner.dart';
import 'package:the_reminder_app/ui/widgets/gradient_page_shell.dart';
import 'package:the_reminder_app/utils/external_link_launcher.dart';

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
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const AdBanner(),
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
                      leading: const Icon(Icons.delete_outline),
                      title: const Text('Account deletion guide'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        openExternalLink(
                          context,
                          url: LegalLinks.accountDeletion,
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Privacy policy'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        openExternalLink(
                          context,
                          url: LegalLinks.privacyPolicy,
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.article_outlined),
                      title: const Text('Terms of service'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        openExternalLink(
                          context,
                          url: LegalLinks.termsAndConditions,
                        );
                      },
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
        activeThumbColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18),
      ),
    );
  }
}
