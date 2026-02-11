import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:the_reminder_app/ui/theme/app_colors.dart';
import 'package:the_reminder_app/ui/widgets/gradient_page_shell.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const String _effectiveDate = 'February 6, 2026';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientPageShell(
      icon: Icons.description_outlined,
      title: 'Terms & Conditions',
      subtitle: 'Please read before using the app',
      leading: GradientHeaderButton(
        icon: Icons.arrow_back_rounded,
        onPressed: () => context.pop(),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.pageBackground),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
          children: [
            _metaCard(theme),
            const SizedBox(height: 16),
            _sectionCard(
              theme,
              '1. Acceptance of Terms',
              [
                'By downloading, installing, or using The Reminder App (the "App"), you agree to these Terms and Conditions. If you do not agree, do not use the App.',
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              theme,
              '2. Using the App',
              [
                'You are responsible for the information you enter, including reminder content, alarm labels, and hydration logs.',
                'Do not use the App for unlawful purposes or to infringe on the rights of others.',
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              theme,
              '3. Accounts and Sign-In',
              [
                'The App may offer multiple sign-in options, such as Google sign-in. Access to your account depends on your device security and the sign-in method you choose.',
                'If you use a shared device, you are responsible for protecting access to your reminders and profile.',
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              theme,
              '4. Reminders, Alarms, and Notifications',
              [
                'The App schedules local notifications and alarms on your device. Delivery can be affected by system permissions, battery optimization, or OS restrictions.',
                'Reminders and alarms are not guaranteed to arrive exactly on time, and the App should not be used for emergencies or critical safety alerts.',
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              theme,
              '5. Hydration and Pomodoro Features',
              [
                'Hydration tracking and Pomodoro timers are for general wellness and productivity. They are not medical advice or professional guidance.',
                'Always use your own judgment and consult a professional if you have health concerns.',
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              theme,
              '6. Data Storage and Sync',
              [
                'Most data is stored locally on your device, including reminders, alarms, and hydration logs.',
                'If you sign in, basic profile data and login events may be stored in Firebase services. At this time, reminders and logs are not synced across devices.',
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              theme,
              '7. Advertising',
              [
                'The App may display ads using Google Mobile Ads. Ad personalization may depend on your settings and platform policies.',
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              theme,
              '8. Third-Party Services',
              [
                'The App uses third-party SDKs and services (for example, Firebase, Google sign-in, and Google Mobile Ads). Your use of those services may be subject to their terms and policies.',
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              theme,
              '9. Changes to the App or Terms',
              [
                'We may update the App or these Terms from time to time. Continued use after changes means you accept the updated Terms.',
              ],
            ),
            const SizedBox(height: 12),
            _sectionCard(
              theme,
              '10. Questions',
              [
                'If you have questions about these Terms, please use the support options provided in the App when available.',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaCard(ThemeData theme) {
    return Card(
      color: AppColors.cardBackground,
      shadowColor: AppColors.cardShadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.event_note_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Effective date',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _effectiveDate,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
    ThemeData theme,
    String title,
    List<String> paragraphs,
  ) {
    return Card(
      color: AppColors.cardBackground,
      shadowColor: AppColors.cardShadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < paragraphs.length; i++) ...[
              Text(
                paragraphs[i],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                  height: 1.4,
                ),
              ),
              if (i != paragraphs.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
