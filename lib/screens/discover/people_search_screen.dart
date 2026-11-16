import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/plan.dart';
import '../../services/services.dart';
import '../../state/people_search.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/plan_card.dart';
import '../../widgets/spark_button.dart';
import 'profile_detail_screen.dart';

/// Wave 2 · People Search (CROWD-FEATURES #21).
///
/// Search by intention, vibe and plan — "people who hike on Sundays" —
/// the way Gen Z already finds everything. The query matches REAL
/// profile and plan fields only (state/people_search.dart); a result
/// exists because a keyword hit real text, and the empty state says so
/// instead of padding with filler people. Blocked members never appear.
class PeopleSearchScreen extends StatefulWidget {
  const PeopleSearchScreen({super.key});

  @override
  State<PeopleSearchScreen> createState() => _PeopleSearchScreenState();
}

class _PeopleSearchScreenState extends State<PeopleSearchScreen> {
  final TextEditingController _query = TextEditingController();
  String _text = '';

  static const _suggestions = [
    'hiking',
    'vinyl',
    'long-term',
    'arcade',
    'tonight',
    'board games',
    'people who hike on Sundays',
  ];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _toggleJoin(OpenPlan plan) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Services.store,
      builder: (context, _) {
        final store = Services.store;
        final pool = MockData.members
            .where((m) => !store.blockedIds.contains(m.id))
            .toList();
        final people = searchMembers(_text, pool);
        final plans = searchPlans(
          _text,
          // Wave 4: past plans aren't findable/joinable — they live
          // in the outcome check-in, not in search.
          store.openPlans.where((p) => !p.past).toList(),
          (id) => id == 'me' ? 'You' : MockData.memberById(id).firstName,
        );
        final searching = _text.trim().isNotEmpty;
        return GlassScaffold(
          appBar: AppBar(title: const Text('Search people & plans')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              TextField(
                controller: _query,
                autofocus: true,
                onChanged: (v) => setState(() => _text = v),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Try "people who hike on Sundays"',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Clear search',
                          onPressed: () {
                            _query.clear();
                            setState(() => _text = '');
                          },
                        ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              if (!searching) ...[
                Text(
                  'Search reads real signals only — intentions, interests, '
                  'prompts, plans. Nothing here is a paid placement.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _suggestions)
                      ActionChip(
                        label: Text(s),
                        onPressed: () {
                          _query.text = s;
                          setState(() => _text = s);
                        },
                      ),
                  ],
                ),
              ] else if (people.isEmpty && plans.isEmpty) ...[
                GlassContainer(
                  child: Column(
                    children: [
                      const Icon(Icons.search_off_outlined, size: 32),
                      const SizedBox(height: 10),
                      Text('Nothing matches "${_text.trim()}"',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Text(
                        'No verified member or open plan mentions those '
                        'words right now. Try an interest, an intention '
                        '(like "long-term"), or a plan word (like "arcade").',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                if (people.isNotEmpty) ...[
                  Text('People', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  for (final m in people) ...[
                    GlassContainer(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProfileDetailScreen(member: m),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: AssetImage(m.photoAsset),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('${m.firstName}, ${m.age}',
                                        style: theme.textTheme.titleMedium),
                                    const SizedBox(width: 6),
                                    if (m.verified)
                                      const Icon(Icons.verified,
                                          size: 15,
                                          color: AppColors.sparkCoral),
                                  ],
                                ),
                                Text(
                                  '${m.intention.label} · ${m.distanceBand} · ${m.city}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(m.headline,
                                    style: theme.textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 5),
                                Wrap(
                                  spacing: 5,
                                  runSpacing: 4,
                                  children: [
                                    for (final i in m.interests.take(3))
                                      Chip(
                                        label: Text(i),
                                        visualDensity:
                                            VisualDensity.compact,
                                        labelStyle:
                                            const TextStyle(fontSize: 11),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 19),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
                if (plans.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Open plans', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  for (final p in plans) ...[
                    PlanCard(plan: p, onJoinToggle: () => _toggleJoin(p)),
                    const SizedBox(height: 10),
                  ],
                ],
                Text(
                  'Results rank by how many of your words hit real profile '
                  'or plan text — best matches first.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 14),
              SparkButton(
                label: 'Browse plans instead',
                icon: Icons.event_outlined,
                secondary: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
}
