import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/state_kit.dart';
import 'plan_detail_screen.dart';
import 'post_plan_feedback_screen.dart';

/// S-041 Plans List (P1) — upcoming and past plans in one honest list.
/// Past plans with feedback pending route to S-042. No streaks, no
/// "you stood them up" shaming — plans are logistics, not a score.
class PlansListScreen extends StatelessWidget {
  const PlansListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final upcoming = MockData.plans.where((p) => p.upcoming).toList();
    final past = MockData.plans.where((p) => !p.upcoming).toList();
    return GlassScaffold(
      appBar: AppBar(title: const Text('Your plans')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Upcoming', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (upcoming.isEmpty)
            const AppEmptyState(
              icon: Icons.event_outlined,
              title: 'No upcoming plans',
              body: 'When you and a match agree a plan, it lands here.',
            ),
          for (final plan in upcoming) ...[
            Builder(builder: (context) {
              final member = MockData.memberById(plan.memberId);
              return GlassContainer(
                onTap: () => openMockPlan(context, plan),
                child: Row(
                  children: [
                    CircleAvatar(
                        backgroundImage: AssetImage(member.photoAsset)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${plan.placeType} · ${member.firstName}',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text('${plan.timeLabel} · ${plan.state}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          Text('Past', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final plan in past) ...[
            Builder(builder: (context) {
              final member = MockData.memberById(plan.memberId);
              return GlassContainer(
                onTap: () => plan.feedbackPending
                    ? Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PostPlanFeedbackScreen(
                            member: member,
                            placeType: plan.placeType,
                          ),
                        ),
                      )
                    : openMockPlan(context, plan),
                child: Row(
                  children: [
                    CircleAvatar(
                        backgroundImage: AssetImage(member.photoAsset)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${plan.placeType} · ${member.firstName}',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(
                            plan.feedbackPending
                                ? '${plan.timeLabel} · How did it go?'
                                : '${plan.timeLabel} · ${plan.state}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (plan.feedbackPending)
                      const Chip(
                        label: Text('Feedback'),
                        visualDensity: VisualDensity.compact,
                      )
                    else
                      const Icon(Icons.chevron_right),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
