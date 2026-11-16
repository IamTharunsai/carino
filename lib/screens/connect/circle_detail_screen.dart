import 'package:flutter/material.dart';
import '../../widgets/copy_text.dart';
import '../../models/host_tools.dart';

import '../../data/mock_data.dart';
import '../../models/circle.dart';
import '../../models/member.dart';
import '../../models/plan.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/intro_card.dart';
import '../../widgets/plan_card.dart';
import '../../widgets/spark_button.dart';
import '../moments/moment_viewer_screen.dart';
import 'circle_chat_screen.dart';

/// Wave 2 · circle detail (CROWD-FEATURES #5/#6/#8).
///
/// One circle, whole: its members, its next plan, its Highlights (the
/// pinned standout Moments, max 3), its circle-only Moments (visible to
/// members only — they never enter the connections feed), its
/// Wingperson introductions, and the door into the circle chat.
class CircleDetailScreen extends StatelessWidget {
  const CircleDetailScreen({super.key, required this.circleId});

  final String circleId;

  void _toggleJoin(BuildContext context, OpenPlan plan) {
    final store = Services.store;
    final messenger = ScaffoldMessenger.of(context);
    if (plan.myState == PlanJoinState.none) {
      if (!store.requestJoinPlan(plan.id)) {
        messenger.showSnackBar(const SnackBar(
          content: Text('That plan just filled up — pick another one.'),
        ));
        return;
      }
      messenger.showSnackBar(SnackBar(
        content: Text(plan.instantJoin
            ? 'You\'re in — "${plan.title}".'
            : 'Request sent for "${plan.title}" — the host confirms joins.'),
      ));
    } else {
      store.leavePlan(plan.id);
      messenger.showSnackBar(SnackBar(
        content: Text('Left "${plan.title}" — your spot is released.'),
      ));
    }
  }

  void _toggleHighlight(BuildContext context, Moment moment) {
    final wasHighlighted = Services.store.isMomentHighlighted(moment.id);
    final ok = Services.store.toggleMomentHighlight(moment.id);
    if (!context.mounted) return;
    if (!ok && !wasHighlighted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Highlights hold up to 3 — unpin one first to make room.'),
      ));
    }
  }

  void _shareMomentSheet(BuildContext context, PrivateCircle circle) {
    final caption = TextEditingController();
    showGlassSheet<void>(
      context,
      child: StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Moment for ${circle.name}',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Visible ONLY to this circle\'s ${circle.memberCount} '
              'members, for 24 hours. It never appears in the '
              'connections feed. Demo build: posts with a sample image.',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: caption,
              onChanged: (_) => setSheetState(() {}),
              maxLength: 140,
              decoration: const InputDecoration(
                labelText: 'Caption',
                hintText: 'What\'s happening with the circle?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SparkButton(
              label: 'Post to the circle',
              icon: Icons.send_outlined,
              onPressed: () {
                Services.store.postCircleMoment(
                  circleId: circle.id,
                  caption: caption.text,
                );
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Moment posted — circle members only.')),
                );
              },
            ),
          ],
        ),
      ),
    ).whenComplete(caption.dispose);
  }

  void _introduceSheet(BuildContext context, PrivateCircle circle) {
    // The wingperson introduces two OTHER members — 'me' is never a
    // pick here (introducing yourself isn't a wing move).
    final others =
        circle.memberIds.where((id) => id != 'me').toList();
    if (others.length < 2) return;
    String aId = others[0];
    String bId = others[1];
    final note = TextEditingController();
    showGlassSheet<void>(
      context,
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          final ready = aId != bId && note.text.trim().isNotEmpty;
          Widget picker(String value, ValueChanged<String> onPick) {
            return DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: [
                for (final id in others)
                  DropdownMenuItem(
                    value: id,
                    child: Text(circleMemberName(id)),
                  ),
              ],
              onChanged: (v) {
                if (v != null) onPick(v);
              },
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Introduce two people',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'You\'re the wingperson: pick two members of '
                '${circle.name} and say why they should meet. The intro '
                'lands in the circle chat — it only opens a 1:1 chat '
                'when BOTH of them accept.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: picker(aId, (v) {
                    aId = v;
                    setSheetState(() {});
                  })),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.favorite,
                        size: 16, color: AppColors.sparkCoral),
                  ),
                  Expanded(child: picker(bId, (v) {
                    bId = v;
                    setSheetState(() {});
                  })),
                ],
              ),
              if (aId == bId)
                Text('Pick two different people.',
                    style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                onChanged: (_) => setSheetState(() {}),
                maxLength: 140,
                decoration: const InputDecoration(
                  labelText: 'Why these two?',
                  hintText: 'e.g. You both keep missing the same trail runs',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SparkButton(
                label: 'Post the intro',
                icon: Icons.handshake_outlined,
                onPressed: ready
                    ? () {
                        Services.store.createIntro(
                          circleId: circle.id,
                          aId: aId,
                          bId: bId,
                          note: note.text,
                        );
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Intro posted in the circle chat — it opens only if both accept.'),
                          ),
                        );
                      }
                    : null,
              ),
            ],
          );
        },
      ),
    ).whenComplete(note.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Services.store,
      builder: (context, _) {
        final store = Services.store;
        final circle = store.circleById(circleId);
        if (circle == null) {
          return GlassScaffold(
            appBar: AppBar(title: const Text('Circle')),
            body: const Center(child: Text('This circle no longer exists.')),
          );
        }
        final upcoming = circle.upcomingPlanId == null
            ? null
            : store.planById(circle.upcomingPlanId!);
        final moments = store.circleMomentsFor(circle.id);
        final highlights = store.circleHighlightsFor(circle.id);
        final intros = store.introsForCircle(circle.id);
        return GlassScaffold(
          appBar: AppBar(title: Text(circle.name), actions: [
            IconButton(
              icon: const Icon(Icons.group_add_outlined),
              tooltip: 'Invite your group',
              onPressed: () async {
                final ok = await copyText(context, groupInviteLink(circle.id));
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Invite link copied — paste it in your group chat and everyone joins in one tap.')));
                }
              },
            ),
          ]),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              // --- Header: members + provenance ---
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(circle.formedFromLabel,
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 10),
                    for (final id in circle.memberIds) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage:
                                AssetImage(circleMemberPhoto(id)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              id == 'me'
                                  ? 'You'
                                  : MockData.memberById(id).name,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          if (id != 'me' &&
                              MockData.memberById(id).verified)
                            const Icon(Icons.verified,
                                size: 15, color: AppColors.verifiedGold),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      'Private to these ${circle.memberCount} members — '
                      'chat, Moments and plans stay inside the circle.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SparkButton(
                label: 'Open circle chat',
                icon: Icons.chat_bubble_outline,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CircleChatScreen(circleId: circle.id),
                  ),
                ),
              ),
              // --- Upcoming plan ---
              if (upcoming != null) ...[
                const SizedBox(height: 18),
                Text('Next plan', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                PlanCard(
                  plan: upcoming,
                  onJoinToggle: () => _toggleJoin(context, upcoming),
                ),
              ],
              // --- Highlights ---
              if (highlights.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('Highlights', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'The standout Moments the circle pinned — up to 3.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 190,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final m in highlights) ...[
                        _highlightCard(context, m, moments),
                        const SizedBox(width: 10),
                      ],
                    ],
                  ),
                ),
              ],
              // --- circle Moments ---
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text('Circle Moments',
                        style: theme.textTheme.titleLarge),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add_circle_outline,
                        size: 17, color: AppColors.sparkCoral),
                    label: const Text('Share',
                        style: TextStyle(color: AppColors.sparkCoral)),
                    onPressed: () => _shareMomentSheet(context, circle),
                  ),
                ],
              ),
              Text(
                'Only ${circle.name} members can see these. Pin the '
                'standouts as Highlights.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              if (moments.isEmpty)
                GlassContainer(
                  child: Text(
                    'No Moments in this circle yet — share the first one.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              for (final m in moments) ...[
                _momentRow(context, m, moments),
                const SizedBox(height: 10),
              ],
              // --- Introductions (Wingperson) ---
              const SizedBox(height: 8),
              Text('Introductions', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Wingperson moves: a member introduces two others. Both '
                'have to accept before a chat opens.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              if (intros.isEmpty)
                GlassContainer(
                  child: Text(
                    'No introductions yet in this circle.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              for (final intro in intros) ...[
                IntroCard(intro: intro),
                const SizedBox(height: 10),
              ],
              SparkButton(
                label: 'Introduce two people',
                icon: Icons.handshake_outlined,
                secondary: true,
                onPressed: () => _introduceSheet(context, circle),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _highlightCard(
      BuildContext context, Moment moment, List<Moment> all) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MomentViewerScreen(
            moments: all,
            initialIndex: all.indexOf(moment),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Image.asset(moment.imageAsset,
                width: 140, height: 190, fit: BoxFit.cover),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Color(0xB3151014)],
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 9,
              right: 9,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.push_pin,
                          size: 12, color: AppColors.sparkCoral),
                      const SizedBox(width: 4),
                      Text(
                        moment.member.firstName,
                        style: const TextStyle(
                            color: AppColors.warmIvory,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(
                    moment.caption,
                    style: const TextStyle(
                        color: AppColors.warmIvory, fontSize: 11.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _momentRow(
      BuildContext context, Moment moment, List<Moment> all) {
    final theme = Theme.of(context);
    final highlighted = Services.store.isMomentHighlighted(moment.id);
    return GlassContainer(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MomentViewerScreen(
                  moments: all,
                  initialIndex: all.indexOf(moment),
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(moment.imageAsset,
                  width: 54, height: 54, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${moment.member.firstName} · ${moment.expiresInLabel}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(moment.caption,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              highlighted ? Icons.push_pin : Icons.push_pin_outlined,
              color: highlighted ? AppColors.sparkCoral : null,
            ),
            tooltip: highlighted
                ? 'Unpin from Highlights'
                : 'Pin as a Highlight',
            onPressed: () => _toggleHighlight(context, moment),
          ),
        ],
      ),
    );
  }
}
