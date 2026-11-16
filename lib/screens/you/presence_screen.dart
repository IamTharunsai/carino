import 'package:flutter/material.dart';

import '../../services/services.dart';
import '../../state/outcomes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';

/// Wave 3 · Phone-Down Mode (#13) records, Wave 4 · Presence
/// Dashboard (MASTER-BUILD-PLAN A4).
///
/// Everything on this screen is computed from real store records —
/// PresenceRecords from phone-down sessions and OutcomeRecords from
/// my own check-ins — by the pure aggregation in state/outcomes.dart
/// (store.dashboardStats). Nothing here is estimated, modelled or
/// invented: with no records, the screen says so and shows the empty
/// state instead of numbers.
///
/// Score formula (honest, shown on screen): coverage (phone-down
/// minutes ÷ plan minutes, clamped) × 85 + company ((group − 1) ÷ 5,
/// clamped) × 15 — presence is mostly about the phone staying down,
/// with a gentle bonus for bigger company.
class PresenceScreen extends StatelessWidget {
  const PresenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Services.store,
      builder: (context, _) {
        final store = Services.store;
        final stats = store.dashboardStats;
        final records = store.presenceRecords;
        return GlassScaffold(
          appBar: AppBar(title: const Text('Presence')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              Text(
                'Time with people, not on the app. Every number here '
                'comes from your own records — phone-down sessions and '
                'plan check-ins — never from estimates.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (!stats.hasAnyRecords)
                GlassContainer(
                  child: Column(
                    children: [
                      const Icon(Icons.spa_outlined, size: 34),
                      const SizedBox(height: 10),
                      Text('Nothing recorded yet',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        'Join a plan and run Phone-Down Mode there, '
                        'then check in on how it went — your offline '
                        'time, scores and circles will build from '
                        'those records. This dashboard shows nothing '
                        'until something real happened.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else ...[
                // --- Offline time: the north-star number ---
                GlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Offline time so far',
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        formatOfflineMinutes(stats.offlineMinutes),
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(color: AppColors.sparkCoral),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phone-down minutes, plus the full length of '
                        'plans you checked in as happened — a plan '
                        'with a phone-down record counts its '
                        'phone-down minutes only, never twice.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _stat(context,
                          label: 'Phone down',
                          value: formatOfflineMinutes(
                              stats.phoneDownMinutes)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _stat(context,
                          label: 'Plans attended',
                          value: '${stats.plansAttended}'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _stat(context,
                          label: 'Tables attended',
                          value: '${stats.tablesAttended}'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _stat(context,
                          label: 'Club nights attended',
                          value: '${stats.eventsAttended}'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _stat(context,
                          label: 'Latest Presence Score',
                          value: stats.presenceScoresChronological.isEmpty
                              ? '—'
                              : '${stats.latestPresenceScore}'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _stat(context,
                          label: 'Average score',
                          value: stats.presenceScoresChronological.isEmpty
                              ? '—'
                              : '${stats.averagePresenceScore}'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // --- Score trend, oldest → newest ---
                if (stats.presenceScoresChronological.isNotEmpty) ...[
                  Text('Score trend', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Oldest to newest — each bar is one phone-down '
                    'session\'s score.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  GlassContainer(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final score
                            in stats.presenceScoresChronological)
                          Expanded(
                            child: Column(
                              children: [
                                Text('$score',
                                    style: theme.textTheme.bodySmall),
                                const SizedBox(height: 4),
                                Container(
                                  height: 8 + score * 0.9,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.emberCrimson,
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                // --- Circles I'm in ---
                Text('Your circles', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                GlassContainer(
                  child: stats.circleNames.isEmpty
                      ? Text(
                          'No circles yet — keep a plan\'s group '
                          'together from the plan page and it lands here.',
                          style: theme.textTheme.bodyMedium,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final name in stats.circleNames)
                              Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.groups_outlined,
                                        size: 17,
                                        color: AppColors.sparkCoral),
                                    const SizedBox(width: 8),
                                    Text(name,
                                        style:
                                            theme.textTheme.bodyMedium),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 18),
                // --- The sessions behind the scores ---
                if (records.isNotEmpty) ...[
                  Text('Phone-down sessions',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  for (final record in records) ...[
                    GlassContainer(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(record.planTitle,
                                    style: theme.textTheme.titleMedium),
                                Text(
                                  '${record.dateLabel} · phone down '
                                  '${record.phoneDownMinutes} of '
                                  '${record.planMinutes} min · group '
                                  'of ${record.groupSize}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            children: [
                              Text('${record.score}',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                          color: AppColors.sparkCoral)),
                              Text('score',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
                const SizedBox(height: 6),
                Text(
                  'Score = coverage (phone-down ÷ plan minutes) × 85 '
                  '+ company ((group − 1) ÷ 5) × 15, each clamped. '
                  'Presence is a nudge, not a grade — there is no '
                  'leaderboard and nobody else sees your score.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _stat(BuildContext context,
      {required String label, required String value}) {
    final theme = Theme.of(context);
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: AppColors.sparkCoral)),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
