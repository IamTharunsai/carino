import 'package:flutter/material.dart';
import '../../models/member.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/safety_actions.dart';
import '../../widgets/spark_button.dart';
import '../chats/games_screen.dart';
import '../connect/spark_session_screen.dart';

/// S-019 Profile Detail — the full person: media, video/voice intro,
/// prompts, interests, languages, boundaries. Report is reachable HERE
/// (overflow menu) — safety is never more than one tap from a person.
class ProfileDetailScreen extends StatelessWidget {
  const ProfileDetailScreen({super.key, required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      backgroundAsset: member.photoAsset,
      appBar: AppBar(
        title: Text(member.firstName),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            tooltip: 'Report or block',
            onPressed: () => SafetyActions.showForMember(
              context,
              member: member,
              surface: 'Profile',
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          // S-019 media carousel: the full gallery, swipeable, with the
          // video intro pinned first when present.
          SizedBox(
            height: 300,
            child: PageView(
              children: [
                for (final asset in member.gallery)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(asset, fit: BoxFit.cover),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('${member.name}, ${member.age}',
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    if (member.verified) const VerifiedBadge(size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${member.distanceBand} · ${member.city} · ${member.intention.label}',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 10),
                Text(member.headline, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 12),
                // S-019: the full S-008 dimensions + boundaries, printed.
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Chip(label: Text('Structure · ${member.structure}')),
                    Chip(label: Text('Pace · ${member.pace}')),
                    Chip(label: Text('Free · ${member.availability}')),
                  ],
                ),
                if (member.boundaries.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.handshake_outlined,
                          size: 16, color: AppColors.sparkCoral),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Boundaries: ${member.boundaries}',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                if (member.hasVideoIntro)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_circle_outline,
                        color: AppColors.sparkCoral),
                    title: const Text('Video intro (0:24)'),
                    subtitle: const Text('Tap to play · sound off until you tap'),
                    onTap: () {
                      // INTEGRATION POINT: media player over the member's
                      // intro URL from BackendService storage.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Video intro player (stub)')),
                      );
                    },
                  ),
                if (member.hasVoiceIntro)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.graphic_eq, color: AppColors.sparkCoral),
                    title: const Text('Voice intro (0:18)'),
                    subtitle: const Text('Tap to play · never autoplays'),
                    onTap: () {},
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final prompt in member.prompts) ...[
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(prompt.question,
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                      // S-019: react to THIS prompt — the like carries the
                      // anchor into chat (S-032B opens on it).
                      IconButton(
                        icon: const Icon(Icons.favorite_border,
                            size: 18, color: AppColors.sparkCoral),
                        tooltip: 'React to this prompt',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Liked ${member.firstName} — anchored to this prompt. If it\'s mutual, your chat opens right here.'),
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(prompt.answer, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Interests', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final i in member.interests) Chip(label: Text(i)),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Languages: ${member.languages.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassContainer(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.sports_esports_outlined,
                      color: AppColors.sparkCoral),
                  title: const Text('Invite to a game'),
                  subtitle: const Text('This or That, Question Cards…'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GamesScreen(member: member),
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.videocam_outlined,
                      color: AppColors.sparkCoral),
                  title: const Text('Invite to Spark'),
                  subtitle: const Text('Mutual-accept video — they choose too.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SparkPreCallScreen(),
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.visibility_off_outlined),
                  title: const Text('Hide this profile'),
                  subtitle: const Text('No report — you just won\'t see them again.'),
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('${member.firstName} hidden.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SparkButton(
                  label: 'Pass',
                  secondary: true,
                  icon: Icons.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SparkButton(
                  label: 'Like ${member.firstName}',
                  icon: Icons.favorite,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
