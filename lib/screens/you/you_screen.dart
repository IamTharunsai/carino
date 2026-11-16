import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/experience.dart';
import '../../services/services.dart';
import '../../services/verification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/safety_actions.dart';
import '../../widgets/spark_button.dart';
import '../onboarding/identity_screen.dart';
import '../onboarding/intentions_screen.dart';
import '../onboarding/taste_quiz_screen.dart';
import '../onboarding/profile_creation_screen.dart';
import 'delete_account_screen.dart';
import 'likes_manager_screen.dart';
import 'notifications_screen.dart';
import 'paywall_screen.dart';
import 'privacy_centre_screen.dart';
import 'settings_screen.dart';
import 'trust_safety_screen.dart';
import 'wingperson_screen.dart';
import '../experience/experience_screens.dart';
import 'facets_screen.dart';
import 'work_facet_screen.dart';
import 'trust_graph_screen.dart';
import 'sync_settings_screen.dart';

/// S-043 My Profile (You tab) — hub to Edit (S-044), Intentions (S-045),
/// Verification Centre (S-046), Privacy Centre (S-047), Trust & Safety
/// Centre (S-052), Plus (S-054), Settings (S-050) and Delete (S-055).
class YouScreen extends StatefulWidget {
  const YouScreen({super.key});

  @override
  State<YouScreen> createState() => _YouScreenState();
}

class _YouScreenState extends State<YouScreen> {

  @override
  Widget build(BuildContext context) {
    final me = Services.prefs.me;
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
                CircleAvatar(
                    radius: 32, backgroundImage: AssetImage(me.photoAsset)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(me.name,
                              style: Theme.of(context).textTheme.titleLarge),
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
          // Profile Aura: a glow that grows with EFFORT (verified, video,
          // photos, prompts, voice, boundaries) — never looks, never
          // popularity, and only you see the meter.
          Builder(builder: (context) {
            final items = auraChecklist(me);
            final strength = auraStrength(me);
            return GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.sparkCoral
                                  .withValues(alpha: 0.25 + 0.6 * strength),
                              blurRadius: 8 + 18 * strength,
                              spreadRadius: 1 + 3 * strength,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                            backgroundImage: AssetImage(me.photoAsset)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Profile aura · ${(strength * 100).round()}%',
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(
                                'Glows brighter as your profile gets more real.',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final (label, done) in items)
                        Chip(
                          avatar: Icon(
                              done
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline,
                              size: 16,
                              color: done ? AppColors.sparkCoral : null),
                          label: Text(label),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                      'Measures effort only — never looks. Only you see this.',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          _row(context,
              icon: Icons.chat_bubble_outline,
              title: 'How I text & comfort',
              subtitle: 'Your texting style + rules Cariño keeps for you',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const SyncSettingsScreen()))),
          _row(context,
              icon: Icons.layers_outlined,
              title: 'Facets',
              subtitle: 'Choose an audience for each field',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const FacetsScreen()))),
          _row(context,
              icon: Icons.work_outline,
              title: 'Work facet',
              subtitle: 'Your role, projects and coffee chat interests',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const WorkFacetScreen()))),
          _row(context,
              icon: Icons.handshake_outlined,
              title: 'Trust Graph',
              subtitle: 'People you have met and personal vouches',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const TrustGraphScreen()))),
          Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: ValueListenableBuilder<bool>(
                      valueListenable: Services.prefs.noCounts,
                      builder: (context, hidden, _) => SwitchListTile(
                          title: const Text('No-Counts'),
                          subtitle: const Text(
                              'Hide public popularity totals and the Likes You count.'),
                          value: hidden,
                          onChanged: (v) =>
                              Services.prefs.noCounts.value = v)))),
          _row(
            context,
            icon: Icons.edit_outlined,
            title: 'Edit profile & media',
            subtitle:
                'Photos, video intro, prompts — AI Coach lives here too',
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
                  onDone: (_) {
                    Navigator.of(context).pop();
                    setState(() {}); // show the new intention right away
                  },
                ),
              ),
            ),
          ),
          _row(
            context,
            icon: Icons.diversity_3_outlined,
            title: 'About you',
            subtitle: 'Gender, pronouns, orientation, who you want to meet',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    IdentityScreen(onDone: () => Navigator.of(context).pop()),
              ),
            ),
          ),
          _row(
            context,
            icon: Icons.quiz_outlined,
            title: 'Taste quiz',
            subtitle: 'Tune your Daily Drop — answers stay editable',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    TasteQuizScreen(onDone: () => Navigator.of(context).pop()),
              ),
            ),
          ),
          _row(
            context,
            icon: Icons.music_note_outlined,
            title: 'Profile soundtrack',
            subtitle: 'Show your anthem and top artists',
            onTap: () => _soundtrack(context),
          ),
          _row(
            context,
            icon: Icons.push_pin_outlined,
            title: 'Highlights',
            subtitle: 'Moments pinned to your profile (up to 3)',
            onTap: () => _highlights(context),
          ),
          _row(
            context,
            icon: Icons.handshake_outlined,
            title: 'Wingperson',
            subtitle: 'Let a friend suggest people from your Drop',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const WingpersonScreen(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: ValueListenableBuilder<bool>(
                valueListenable: Services.prefs.calmMode,
                builder: (context, calm, _) => SwitchListTile(
                  secondary: const Icon(Icons.spa_outlined),
                  title: const Text('Calm mode'),
                  subtitle: const Text(
                      'Fewer animations, no celebration motion. Easier on the senses.'),
                  value: calm,
                  onChanged: (v) => Services.prefs.calmMode.value = v,
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
                : 'See who liked you, unlimited likes, rewind, travel',
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
            icon: Icons.favorite_outline,
            title: 'Relationship & couples',
            subtitle: 'Honest Status, Couples mode, date-night bookings',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CoupleScreen()),
            ),
          ),
          _row(
            context,
            icon: Icons.card_giftcard_outlined,
            title: 'Invite & offers',
            subtitle: 'Give a week of Plus, get a week · promo codes',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ReferralScreen()),
            ),
          ),
          _row(
            context,
            icon: Icons.insights_outlined,
            title: 'Your activity',
            subtitle: 'What you use most — on this phone only',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const InsightsScreen()),
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
            style:
                TextButton.styleFrom(foregroundColor: AppColors.emberCrimson),
          ),
        ],
      ),
    );
  }

  void _soundtrack(BuildContext context) {
    showGlassSheet<void>(
      context,
      child: StatefulBuilder(
        builder: (ctx, setSheet) {
          final connected = Services.prefs.musicConnected;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Profile soundtrack',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                connected
                    ? 'Connected (demo). Your top artists show on your profile; '
                        'shared artists become conversation starters.'
                    : 'Connect Spotify or Apple Music to show your top artists '
                        'and an anthem. We read artist names only — never your '
                        'listening history.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              SparkButton(
                label: connected ? 'Disconnect' : 'Connect music (demo)',
                icon: Icons.music_note_outlined,
                secondary: connected,
                onPressed: () =>
                    setSheet(() => Services.prefs.musicConnected = !connected),
              ),
            ],
          );
        },
      ),
    );
  }

  void _highlights(BuildContext context) {
    showGlassSheet<void>(
      context,
      child: StatefulBuilder(
        builder: (ctx, setSheet) {
          final pins = Services.prefs.highlights;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Highlights', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 6),
              if (pins.isEmpty)
                Text(
                  'Nothing pinned yet. Open one of your Moments and tap '
                  '"Pin to profile" to keep it past 24 hours.',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
              for (final h in List.of(pins))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.push_pin),
                  title: Text(h),
                  trailing: TextButton(
                    onPressed: () => setSheet(() => pins.remove(h)),
                    child: const Text('Unpin'),
                  ),
                ),
            ],
          );
        },
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
            subtitle:
                const Text('None open. Outcomes land here + Notifications.'),
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
