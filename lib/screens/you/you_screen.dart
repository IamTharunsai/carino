import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../data/mock_data.dart';
import '../../services/services.dart';
import '../../services/verification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/safety_actions.dart';
import '../onboarding/intentions_screen.dart';
import '../onboarding/profile_creation_screen.dart';
import 'delete_account_screen.dart';
import 'likes_manager_screen.dart';
import 'notifications_screen.dart';
import 'paywall_screen.dart';
import 'privacy_centre_screen.dart';
import 'settings_screen.dart';
import 'trust_safety_screen.dart';

/// S-043 My Profile (You tab) — hub to Edit (S-044), Intentions (S-045),
/// Verification Centre (S-046), Privacy Centre (S-047), Trust & Safety
/// Centre (S-052), Plus (S-054), Settings (S-050) and Delete (S-055).
class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const me = MockData.currentUser;
    return GlassScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          Text('You', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GlassContainer(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProfileCreationScreen(
                  onPublished: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 32, backgroundImage: AssetImage(me.photoAsset)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(me.name, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified,
                              size: 17, color: AppColors.sparkCoral),
                        ],
                      ),
                      Text(me.headline,
                          style: Theme.of(context).textTheme.bodySmall),
                      Text('Here for: ${me.intention.label}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // S-043 completion meter — computed from the REAL profile
          // fields (video, photos, prompts, headline, boundaries), so
          // the percentage is a measurement, not a nag.
          Builder(builder: (context) {
            var score = 0;
            if (me.hasVideoIntro) score += 25;
            if (me.gallery.length >= 3) score += 25;
            if (me.prompts.length >= 3) score += 20;
            if (me.headline.isNotEmpty) score += 15;
            if (me.boundaries.isNotEmpty) score += 15;
            return GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Profile completion · $score%',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      Text(score >= 100 ? 'Complete' : 'In progress',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: score / 100,
                    color: AppColors.emberCrimson,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Complete profiles get real conversations. What\'s missing is listed in Edit Profile — no mystery.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          _row(
            context,
            icon: Icons.edit_outlined,
            title: 'Edit profile & media',
            subtitle: 'Photos, video intro, prompts — AI Coach lives here too',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProfileCreationScreen(
                  onPublished: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
          _row(
            context,
            icon: Icons.flag_outlined,
            title: 'Intentions & availability',
            subtitle: 'What you\'re here for, and when you\'re around',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => IntentionsScreen(
                  initial: me.intention,
                  onDone: (_) => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
          _row(
            context,
            icon: Icons.verified_user_outlined,
            title: 'Verification Centre',
            subtitle: 'All 3 layers passed · badge active',
            onTap: () => _verificationCentre(context),
          ),
          _row(
            context,
            icon: Icons.lock_outline,
            title: 'Privacy Centre',
            subtitle: 'Visibility, blocked people, AI consent, your data',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PrivacyCentreScreen(),
              ),
            ),
          ),
          _row(
            context,
            icon: Icons.favorite_outline,
            title: 'Likes & introductions',
            subtitle: 'Pause discovery, set a daily limit, close kindly',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LikesManagerScreen(),
              ),
            ),
          ),
          _row(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Matches, messages, plans — real events only',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsScreen(),
              ),
            ),
          ),
          _row(
            context,
            icon: Icons.shield_outlined,
            title: 'Trust & Safety Centre',
            subtitle: 'Report, appeal a decision, your cases, safety guides',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TrustSafetyScreen(),
              ),
            ),
          ),
          _row(
            context,
            icon: Icons.workspace_premium_outlined,
            title: AppConfig.plusName,
            subtitle: Services.payments.isPlus
                ? 'Active — manage subscription'
                : 'See who likes you, read receipts, spark sooner',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Services.payments.isPlus
                    ? const SubscriptionScreen()
                    : const PaywallScreen(),
              ),
            ),
          ),
          _row(
            context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Notifications, calls, sessions, passkey, app lock',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DeleteAccountScreen(),
              ),
            ),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete account'),
            style: TextButton.styleFrom(foregroundColor: AppColors.emberCrimson),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.sparkCoral),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  /// S-046: the three layers, stated plainly, with vendor references.
  void _verificationCentre(BuildContext context) {
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Verification Centre',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          for (final layer in VerificationLayer.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline,
                  color: AppColors.sparkCoral),
              title: Text(layer.label),
              subtitle: Text('${layer.tagline} · Ref VN-DEMO'),
            ),
          const SizedBox(height: 8),
          Text(
            'We store results + references only — never your ID images. '
            'If a check ever fails, you get the reason and a human appeal path.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Appeals'),
            subtitle: const Text('None open. Outcomes land here + Notifications.'),
            onTap: () {
              Navigator.of(context).pop();
              SafetyActions.showAppealsEntry(context);
            },
          ),
        ],
      ),
    );
  }

}