import 'package:flutter/material.dart';

import '../../models/plan.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/intro_card.dart';
import '../../widgets/state_kit.dart';
import 'circle_detail_screen.dart';

/// Wave 2 · Your Circles (CROWD-FEATURES #5).
///
/// The list of the member's private Circles — the small groups that
/// formed from plans and stayed — plus the conversion shelf: plans the
/// member is part of that haven't become a circle yet, each with its
/// "Keep this group as a circle" action. Everything reads the shared
/// store, so a conversion made here (or in the Plans hub) shows up in
/// both places at once.
class CirclesScreen extends StatelessWidget {
  const CirclesScreen({super.key});

  void _convert(BuildContext context, OpenPlan plan) {
    final circle = Services.store.convertPlanToCircle(plan.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(circle == null
            ? 'That plan already became a circle.'
            : 'Circle created: "${circle.name}" — the group chat is open '
                'and the plan stays pinned inside.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Services.store,
      builder: (context, _) {
        final store = Services.store;
        final convertible =
            store.openPlans.where(store.canConvertPlanToCircle).toList();
        return GlassScaffold(
          appBar: AppBar(title: const Text('Your Circles')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              Text(
                'Small groups that stuck. A circle is private — only its '
                'members see the chat, the Moments and the plans.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              if (store.circles.isEmpty)
                const AppEmptyState(
                  icon: Icons.groups_outlined,
                  title: 'No Circles yet',
                  body: 'Join a plan, meet the group — then keep it as a '
                      'Circle and it stays yours.',
                ),
              for (final circle in store.circles) ...[
                GlassContainer(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          CircleDetailScreen(circleId: circle.id),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(circle.name,
                                style: theme.textTheme.titleMedium),
                          ),
                          const Icon(Icons.chevron_right, size: 19),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(circle.formedFromLabel,
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          SizedBox(
                            height: 30,
                            width: 30 +
                                (circle.memberIds.length.clamp(1, 5) - 1) *
                                    22.0,
                            child: Stack(
                              children: [
                                for (var i = 0;
                                    i < circle.memberIds.length && i < 5;
                                    i++)
                                  Positioned(
                                    left: i * 22.0,
                                    child: CircleAvatar(
                                      radius: 15,
                                      backgroundColor:
                                          AppColors.plumCharcoal,
                                      backgroundImage: AssetImage(
                                          circleMemberPhoto(
                                              circle.memberIds[i])),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${circle.memberCount} members · '
                              '${circle.memberIds.map(circleMemberName).join(', ')}',
                              style: theme.textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (circle.upcomingPlanId != null &&
                          store.planById(circle.upcomingPlanId!) !=
                              null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.event_outlined,
                                size: 15, color: AppColors.sparkCoral),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Next: ${store.planById(circle.upcomingPlanId!)!.title} · '
                                '${store.planById(circle.upcomingPlanId!)!.timeLabel}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (convertible.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Keep a group as a circle',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Plans you\'re part of can become permanent Circles — '
                  'the group, its chat and its Moments carry over.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                for (final plan in convertible) ...[
                  GlassContainer(
                    child: Row(
                      children: [
                        const Icon(Icons.event_outlined,
                            color: AppColors.sparkCoral),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(plan.title,
                                  style: theme.textTheme.titleSmall),
                              Text(
                                '${plan.timeLabel} · '
                                '${plan.attendeeIds.length} people in',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.groups_outlined,
                              size: 17, color: AppColors.sparkCoral),
                          label: const Text('Keep as circle',
                              style: TextStyle(
                                  color: AppColors.sparkCoral,
                                  fontSize: 13)),
                          onPressed: () => _convert(context, plan),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
              const SizedBox(height: 6),
              Text(
                'Circles never appear in Discover and can\'t be searched — '
                'membership is the only door in.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}
