import 'package:flutter/material.dart';
import '../you/my_tickets_screen.dart';
import 'circles_screen.dart';
import 'plans_hub_screen.dart';
import '../../config/app_config.dart';
import '../../config/env.dart';
import '../../data/mock_data.dart';
import '../../models/member.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/match_expiry_chip.dart';
import '../../widgets/spark_button.dart';
import '../../widgets/state_kit.dart';
import '../chats/conversation_screen.dart';
import '../discover/profile_detail_screen.dart';
import '../you/paywall_screen.dart';
import '../chats/games_screen.dart';
import 'incoming_call_screen.dart';
import 'meet_irl_screens.dart';
import 'decompress_screens.dart';
import 'plans_hub_screens.dart';
import 'plan_composer_screen.dart';
import 'plans_list_screen.dart';
import 'spark_session_screen.dart';

/// S-025 Connect Hub — where matches become momentum:
///  - Spark Session entry (mutually-accepted video, S-026)
///  - Your matches, WITH the REA expiry/archive states (see
///    MatchExpiryChip + MatchConnection): expiring unmessaged matches show
///    their real clock; archived matches sit in their own quiet section
///  - Plan suggestions (S-039) and games (S-030) one tap away
class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final matches = MockData.matches;
    final archived = MockData.archivedMatches;
    return GlassScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          Text('Plans', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const _YourPlansCard(),
          const SizedBox(height: 12),
          GlassContainer(
            child: Column(children: [
              for (final (icon, title, sub, page) in [
                (Icons.groups_2_outlined, 'Group plans, Tables & tickets', 'Dinners with verified strangers, club nights, open plans', const PlansHubScreen() as Widget),
                (Icons.diversity_1_outlined, 'Private circles', 'Your people, your plans, your moments', const CirclesScreen() as Widget),
                (Icons.confirmation_number_outlined, 'My tickets', 'Seats and passes you hold', const MyTicketsScreen() as Widget),
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(icon, color: AppColors.sparkCoral),
                  title: Text(title),
                  subtitle: Text(sub),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page)),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          // --- Spark Sessions ---
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.video_camera_front_outlined,
                        color: AppColors.sparkCoral),
                    const SizedBox(width: 8),
                    Text('Spark Sessions',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Short live video intros with people who ALSO chose you. '
                  'Full profiles first, both accept, cameras last. Never random, never anonymous.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                SparkButton(
                  label: 'Enter the Spark lobby',
                  icon: Icons.video_call_outlined,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SparkPreCallScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // S-025: next real Spark window (server schedule via
                // RemoteConfig — a stated window, never a fake countdown).
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 16, color: AppColors.sparkCoral),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Next window: ${Services.remoteConfig.nextSparkWindowLabel}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // S-027 pending invitations live here until they expire.
                // Demo-only preview of the ring; live builds get real invites.
                if (Env.useMockBackend)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.ring_volume_outlined),
                  title: const Text('Preview a Spark call'),
                  subtitle:
                      const Text('See exactly what a Spark ring looks like.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final accepted = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => IncomingCallScreen(
                          member: MockData.memberById('m-sofia'),
                        ),
                      ),
                    );
                    if (!context.mounted) return;
                    if (accepted == false) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Declined — a missed-call note lands in the chat; they\'re never told more than that.'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Decompress: the bookable reset shelf (+ Phone-Down Mode).
          GlassContainer(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const DecompressScreen()),
            ),
            child: Row(
              children: [
                const Icon(Icons.spa_outlined, color: AppColors.sparkCoral, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Decompress', style: Theme.of(context).textTheme.titleMedium),
                      Text('Sunset walks, kayaking, pottery, park yoga, spa hours — book a reset, phone down.',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const NightPlannerCard(),
          const SizedBox(height: 12),
          // --- Meet in real life: events, Spark Nights, group hangouts ---
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meet in real life',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Ready-made reasons to turn a match into a plan.',
                    style: Theme.of(context).textTheme.bodySmall),
                for (final (icon, title, sub, page) in [
                  (
                    Icons.local_activity_outlined,
                    'Events near you',
                    'Gigs, markets, comedy, run clubs',
                    const EventsScreen() as Widget,
                  ),
                  (
                    Icons.nightlife_outlined,
                    'Spark Nights',
                    'Themed evenings of 5-minute video hellos',
                    const SparkNightsScreen() as Widget,
                  ),
                  (
                    Icons.groups_outlined,
                    'Group hangout',
                    'Bring a friend — 2 + 2, lower pressure',
                    const GroupHangoutScreen() as Widget,
                  ),
                  (
                    Icons.nightlight_outlined,
                    'Tonight near me',
                    'Hosted plans, events, open tables',
                    const TonightScreen() as Widget,
                  ),
                  (
                    Icons.campaign_outlined,
                    'Host a plan',
                    'Coffee run, pickup game — earn host reputation',
                    const HostPlanScreen() as Widget,
                  ),
                  (
                    Icons.coffee_outlined,
                    'Coffee chats',
                    'One curated work intro a week + warm intros',
                    const CoffeeChatsScreen() as Widget,
                  ),
                  (
                    Icons.diversity_2_outlined,
                    'Guilds',
                    'Interest communities that turn into plans',
                    const GuildsScreen() as Widget,
                  ),
                ])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(icon, color: AppColors.sparkCoral),
                    title: Text(title),
                    subtitle: Text(sub),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => page),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // --- S-021 Likes You ---
          Text('Hearts for you 💗', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _LikesYou(),
          const SizedBox(height: 18),
          // --- Matches (with expiry state) ---
          Text('Your matches', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const MatchExpiryExplainer(),
          const SizedBox(height: 10),
          for (final match in matches) ...[
            _MatchTile(match: match),
            const SizedBox(height: 10),
          ],
          if (matches.isEmpty)
            const AppEmptyState(
              icon: Icons.favorite_border,
              title: 'No matches yet',
              body:
                  'When it’s mutual, they land here 💞 Say hello while it’s fresh.',
            ),
          const SizedBox(height: 6),
          SparkButton(
            label: 'Your plans',
            icon: Icons.event_outlined,
            secondary: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PlansListScreen(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SparkButton(
            label: 'Suggest a plan',
            icon: Icons.calendar_month_outlined,
            secondary: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlanComposerScreen(
                  member: MockData.memberById('m-aria'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SparkButton(
            label: 'Play a game together',
            icon: Icons.sports_esports_outlined,
            secondary: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    GamesScreen(member: MockData.memberById('m-sofia')),
              ),
            ),
          ),
          // --- Archived matches (REA §5.1): quiet, no shame, no CTA spam ---
          if (archived.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Archived', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Matches that expired with no conversation. They\'re kept here — not deleted, not a strike against anyone.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            for (final match in archived) ...[
              Opacity(opacity: 0.75, child: _MatchTile(match: match)),
              const SizedBox(height: 10),
            ],
          ],
          const SizedBox(height: 8),
          Text(
            'Plans and Spark windows show real times from ${AppConfig.appName} servers — nothing here counts down fake.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match});
  final MatchConnection match;

  @override
  Widget build(BuildContext context) {
    final member = match.member;
    return GlassContainer(
      onTap: () {
        // A match with a conversation opens the chat; otherwise the
        // profile — where a first hello can start (S-032B starters).
        final convs = MockData.conversations()
            .where((c) => c.memberId == member.id)
            .toList();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => convs.isNotEmpty
                ? ConversationScreen(conversation: convs.first)
                : ProfileDetailScreen(member: member, matched: true),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            CircleAvatar(
                radius: 26, backgroundImage: AssetImage(member.photoAsset)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${member.firstName}, ${member.age}',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(width: 6),
                      if (member.verified)
                        const Icon(Icons.verified,
                            size: 15, color: AppColors.sparkCoral),
                    ],
                  ),
                  Text(
                    match.planStatus ??
                        (match.archived
                            ? 'Expired ${match.matchedAtLabel.toLowerCase()} · no conversation'
                            : 'Matched ${match.matchedAtLabel.toLowerCase()} · say hello'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Align(
              alignment: Alignment.centerLeft,
              child: MatchExpiryChip(match: match)),
        ],
      ),
    );
  }
}

/// S-021 Likes You — the honest version of the genre's most-abused screen:
/// the COUNT is real (it comes from the data layer, never inflated), free
/// members see blurred teasers + the count, and Plus reveals the people.
/// Nobody is ever told "someone likes you!" who doesn't.
class _LikesYou extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final likes = MockData.likesYou;
    final isPlus = Services.payments.isPlus;
    if (likes.isEmpty) {
      return GlassContainer(
        child: Text(
          'No hearts yet — they’ll show up here the moment someone falls for you.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<bool>(
              valueListenable: Services.prefs.noCounts,
              builder: (context, hidden, _) => Text(
                  hidden
                      ? 'People with a crush on you'
                      : '${likes.length} ${likes.length == 1 ? 'person has' : 'people have'} a crush on you 💗',
                  style: Theme.of(context).textTheme.titleMedium)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final m in likes)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: isPlus
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ProfileDetailScreen(member: m),
                              ),
                            )
                        : null,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage(m.photoAsset),
                          // Free tier: blurred teaser — the avatar renders
                          // dimmed; production blurs server-side so the
                          // image itself never ships unblurred.
                          foregroundColor: isPlus
                              ? null
                              : AppColors.midnight.withValues(alpha: 0.55),
                          child: isPlus
                              ? null
                              : const Icon(Icons.blur_on,
                                  color: AppColors.warmIvory),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPlus ? m.firstName : '•••',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (!isPlus) ...[
            const SizedBox(height: 8),
            SparkButton(
              label: 'See who with Plus',
              secondary: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


/// The top of Plans: how many you have, make one, and how it works
/// (pick → agree → book → go, with check-ins).
class _YourPlansCard extends StatelessWidget {
  const _YourPlansCard();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final upcoming = MockData.plans.where((p) => p.upcoming).length;
    Widget step(String n, String title, String body) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: 12, backgroundColor: AppColors.emberCrimson, child: Text(n, style: const TextStyle(fontSize: 12, color: AppColors.warmIvory))),
            const SizedBox(width: 10),
            Expanded(child: Text.rich(TextSpan(children: [
              TextSpan(text: '$title  ', style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: body),
            ]))),
          ]),
        );
    return GlassContainer(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Text(upcoming == 0 ? 'No plans yet' : '$upcoming upcoming ${upcoming == 1 ? 'plan' : 'plans'} 💫',
                style: t.titleLarge),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PlansListScreen())),
            child: const Text('See all'),
          ),
        ]),
        step('1', 'Pick', 'a match and an idea — AI suggests ones you’ll both love.'),
        step('2', 'Agree', 'on a time. They confirm, you both see the details.'),
        step('3', 'Book', 'a table, tickets or a stay right from the plan.'),
        step('4', 'Go', 'with check-ins on. Tap “I’m home safe” after.'),
        const SizedBox(height: 12),
        SparkButton(
          label: 'Create a plan',
          icon: Icons.add,
          onPressed: () {
            final matches = MockData.matches;
            if (matches.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Match with someone first — then plan something lovely.')));
              return;
            }
            Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => PlanComposerScreen(member: matches.first.member)));
          },
        ),
      ]),
    );
  }
}
