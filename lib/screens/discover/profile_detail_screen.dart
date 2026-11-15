import 'package:flutter/material.dart';
import '../../models/member.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/safety_actions.dart';
import '../../widgets/spark_button.dart';
import '../../widgets/video_reply_sheet.dart';
import '../../widgets/sync_widgets.dart';
import '../../models/sync.dart' show comfortSummary;
import 'discover_screen.dart' show whySuggested;
import '../chats/games_screen.dart';
import '../connect/spark_session_screen.dart';

/// S-019 Profile Detail — the full person: media, video/voice intro,
/// prompts, interests, languages, boundaries. Report is reachable HERE
/// (overflow menu) — safety is never more than one tap from a person.
class ProfileDetailScreen extends StatelessWidget {
  const ProfileDetailScreen({
    super.key,
    required this.member,
    this.matched = false,
  });

  final Member member;

  /// Matches may see fields the member set to "Matches" visibility.
  final bool matched;

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
                      child: Text.rich(
                        TextSpan(
                          text: '${member.name}, ${member.age}',
                          children: [
                            if (member.pronouns.isNotEmpty &&
                                member.shows('pronouns', matched: matched))
                              TextSpan(
                                text: '  ${member.pronouns}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                          ],
                        ),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (member.verified) const VerifiedBadge(size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${member.distanceBand} · ${member.city} · ${member.intention.label}',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 10),
                Text(member.headline, style: Theme.of(context).textTheme.bodyLarge),
                if (whySuggested(member) case final why?) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 14, color: AppColors.sparkCoral),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Why you\'re seeing them: $why',
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // S-019: the full S-008 dimensions + boundaries, printed.
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Chip(label: Text('Structure · ${member.structure}')),
                    Chip(label: Text('Pace · ${member.pace}')),
                    Chip(label: Text('Free · ${member.availability}')),
                    if (member.gender.isNotEmpty &&
                        member.shows('gender', matched: matched))
                      Chip(label: Text(member.gender.join(' · '))),
                    if (member.orientation.isNotEmpty &&
                        member.shows('orientation', matched: matched))
                      Chip(label: Text(member.orientation)),
                  ],
                ),
                if (member.accessNote.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.accessible_forward,
                          size: 16, color: AppColors.sparkCoral),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Access: ${member.accessNote}',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ],
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
                if (!member.textingStyle.isEmpty ||
                    comfortSummary(member.comfort).isNotEmpty) ...[
                  const SizedBox(height: 14),
                  TextingCard(
                    title: 'How ${member.firstName} texts',
                    style: member.textingStyle,
                    comfort: member.comfort,
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
          if (member.highlights.isNotEmpty) ...[
            _Highlights(member: member),
            const SizedBox(height: 12),
          ],
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
                        icon: const Icon(Icons.videocam_outlined,
                            size: 18, color: AppColors.sparkCoral),
                        tooltip: 'Reply with video',
                        visualDensity: VisualDensity.compact,
                        onPressed: () async {
                          final sent = await showVideoReplySheet(context,
                              member: member, prompt: prompt);
                          if (sent != true || !context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Video reply sent to ${member.firstName} privately — your like, with a hello.'),
                            ),
                          );
                        },
                      ),
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
          if (member.anthem != null || member.topArtists.isNotEmpty) ...[
            const SizedBox(height: 12),
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.music_note_outlined,
                          color: AppColors.sparkCoral),
                      const SizedBox(width: 8),
                      Text('Soundtrack',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  if (member.anthem != null) ...[
                    const SizedBox(height: 8),
                    Text('Anthem · ${member.anthem}',
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                  if (member.topArtists.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final a in member.topArtists) Chip(label: Text(a)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text('Linked from their music app.',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
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

/// Highlights: up to 3 Moments the member chose to keep on their profile.
class _Highlights extends StatelessWidget {
  const _Highlights({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Highlights', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: member.highlights.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => SizedBox(
                width: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(member.gallery[i % member.gallery.length],
                          fit: BoxFit.cover),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0xCC151014)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            member.highlights[i],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.warmIvory, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
