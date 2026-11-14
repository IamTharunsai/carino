import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/platform.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/post_to_plan_sheet.dart';
import '../../widgets/spark_button.dart';

/// PLANS engine + PROFESSIONAL wing: AI Night Planner, Tonight Near Me,
/// Micro-Hosts, Coffee Chats, Warm Intros and Guilds.

// ============================================================================
// AI Night Planner (card on the Plans tab)
// ============================================================================

class NightPlannerCard extends StatelessWidget {
  const NightPlannerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final plan = suggestNightPlan(
      friendFreeTonight: MockData.freeTonight,
      myTaste: Services.prefs.tasteAnswers.isEmpty
          ? const {'t2': 'Midnight pancakes'}
          : Services.prefs.tasteAnswers,
      ideas: MockData.nightIdeas,
    );
    if (plan == null) return const SizedBox.shrink();
    final names =
        plan.friendIds.map((i) => MockData.personById(i).firstName).join(' & ');
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_outlined, color: AppColors.sparkCoral),
              SizedBox(width: 8),
              Expanded(child: Text('Night planner · AI suggestion')),
            ],
          ),
          const SizedBox(height: 8),
          Text('${plan.idea} with $names', style: text.titleMedium),
          Text('${plan.timeLabel} · ${plan.reason}', style: text.bodySmall),
          const SizedBox(height: 10),
          SparkButton(
            label: 'Make it a plan',
            icon: Icons.event_available_outlined,
            onPressed: () => showPostToPlanSheet(context, idea: plan.idea),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Tonight Near Me
// ============================================================================

class TonightScreen extends StatefulWidget {
  const TonightScreen({super.key});

  @override
  State<TonightScreen> createState() => _TonightScreenState();
}

class _TonightScreenState extends State<TonightScreen> {
  final Set<String> _joined = {};

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassScaffold(
      appBar: AppBar(title: const Text('Tonight near me')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'What\'s actually happening this evening: hosted plans, events and '
            'open tables. Public places only; no live map of people.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final (kind, title, where, seats) in MockData.tonight) ...[
            GlassContainer(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kind.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 11,
                                letterSpacing: 1,
                                color: AppColors.sparkCoral)),
                        Text(title, style: text.titleMedium),
                        Text(
                          seats > 0 ? '$where · $seats spots' : where,
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => setState(() => _joined.contains(title)
                        ? _joined.remove(title)
                        : _joined.add(title)),
                    child: Text(_joined.contains(title) ? 'Going ✓' : 'Join'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
              'Joining a hosted plan shares your first name and verified badge with the host.',
              style: text.bodySmall),
        ],
      ),
    );
  }
}

// ============================================================================
// Micro-Hosts
// ============================================================================

class HostPlanScreen extends StatefulWidget {
  const HostPlanScreen({super.key});

  @override
  State<HostPlanScreen> createState() => _HostPlanScreenState();
}

class _HostPlanScreenState extends State<HostPlanScreen> {
  final TextEditingController _what = TextEditingController();
  final TextEditingController _price = TextEditingController();
  String _when = 'Sat · 10:00';
  double _spots = 4;

  // Sample host record (production: from private post-plan feedback).
  static const int _hosted = 4, _positive = 4, _reports = 0;

  @override
  void dispose() {
    _what.dispose();
    _price.dispose();
    super.dispose();
  }

  void _publish() {
    final w = _what.text.trim();
    if (w.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Say what the plan is first.')));
      return;
    }
    final price = double.tryParse(_price.text.trim());
    if (_price.text.trim().isNotEmpty &&
        (price == null || price < 0 || price > 500)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ticket price must be between \$0 and \$500.')));
      return;
    }
    Services.prefs.myPlans
        .add('Hosting: $w · $_when · ${_spots.round()} spots');
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Published. It shows in Tonight Near Me and to your circles.')));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tier =
        hostTier(plansHosted: _hosted, positive: _positive, reports: _reports);
    return GlassScaffold(
      appBar: AppBar(title: const Text('Host a plan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your host reputation', style: text.titleMedium),
                const SizedBox(height: 4),
                Text(
                  switch (tier) {
                    HostTier.newHost =>
                      'New host · host 3 plans people enjoy to become Trusted.',
                    HostTier.trusted =>
                      'Trusted host · $_hosted plans, all good. 10 great plans unlock Partner and a 70% share of ticket sales.',
                    HostTier.partner =>
                      'Partner host · you earn 70% of ticket sales.',
                  },
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_hosted / 10).clamp(0, 1).toDouble(),
                  color: AppColors.emberCrimson,
                ),
                const SizedBox(height: 4),
                Text(
                    'Built from private "did it happen / felt comfortable" feedback — never public star ratings.',
                    style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _what,
            decoration: const InputDecoration(
                labelText: 'What (coffee run, pickup game, gallery night…)'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in ['Tonight · 19:00', 'Sat · 10:00', 'Sun · 15:00'])
                ChoiceChip(
                  label: Text(t),
                  selected: _when == t,
                  selectedColor: AppColors.emberCrimson,
                  onSelected: (_) => setState(() => _when = t),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Spots: ${_spots.round()}', style: text.titleSmall),
          Slider(
            value: _spots,
            min: 2,
            max: 8,
            divisions: 6,
            onChanged: (v) => setState(() => _spots = v),
          ),
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Ticket price (optional)',
              prefixText: '\$',
              helperText: tier == HostTier.partner
                  ? 'You keep 70%.'
                  : 'Ticketed plans pay hosts once you reach Partner.',
            ),
          ),
          const SizedBox(height: 16),
          SparkButton(
              label: 'Publish plan',
              icon: Icons.campaign_outlined,
              onPressed: _publish),
          const SizedBox(height: 8),
          Text(
              'Public places only. Every guest is verified. You can remove anyone, anytime.',
              style: text.bodySmall),
        ],
      ),
    );
  }
}

// ============================================================================
// Coffee Chats + Warm Intros (Professional wing)
// ============================================================================

class CoffeeChatsScreen extends StatefulWidget {
  const CoffeeChatsScreen({super.key});

  @override
  State<CoffeeChatsScreen> createState() => _CoffeeChatsScreenState();
}

class _CoffeeChatsScreenState extends State<CoffeeChatsScreen> {
  final Set<String> _passed = {};
  bool _accepted = false;

  WorkFacet get _me => WorkFacet(
        personId: 'me',
        role: Services.prefs.workRole,
        building: Services.prefs.workBuilding,
        skills: MockData.myWork.skills,
        openTo: Services.prefs.workOpenTo,
      );

  void _requestIntro(String targetId, String introducerId) {
    final note = TextEditingController(
        text:
            'Hi! Would you introduce me to ${MockData.personById(targetId).firstName}? '
            'I\'d love a quick coffee about what they\'re building.');
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
              'Ask ${MockData.personById(introducerId).firstName} for an intro',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
              'They\'ve met you both in person. They decide whether to pass it on.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          TextField(controller: note, maxLines: 3, maxLength: 280),
          SparkButton(
            label: 'Send request',
            icon: Icons.send_outlined,
            onPressed: () {
              if (note.text.trim().isEmpty) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'Request sent to ${MockData.personById(introducerId).firstName}.')));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final match = weeklyCoffeeMatch(_me, MockData.workFacets, _passed);
    final intros = [
      for (final t in ['p-lee', 'm-rowan', 'm-elena'])
        (t, Services.trust.introducersFor(t)),
    ].where((e) => e.$2.isNotEmpty).toList();
    return GlassScaffold(
      appBar: AppBar(title: const Text('Coffee chats')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'One curated 15-minute intro a week, based on your Work facet. '
            'No cold DMs, no spam.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (match == null)
            GlassContainer(
              child: Text('No match this week — check back Monday.',
                  style: text.bodyMedium),
            )
          else
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage(
                              MockData.personById(match.personId).photoAsset)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(MockData.personById(match.personId).firstName,
                                style: text.titleMedium),
                            Text(match.role, style: text.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Building: ${match.building}', style: text.bodyMedium),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in match.skills) Chip(label: Text(s)),
                      for (final o in match.openTo)
                        Chip(label: Text('Open to $o')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_accepted)
                    Text(
                        'Accepted — you\'ll both get a 15-minute slot to pick.',
                        style: text.bodyMedium
                            ?.copyWith(color: AppColors.sparkCoral))
                  else
                    Row(
                      children: [
                        Expanded(
                          child: SparkButton(
                            label: 'Pass',
                            secondary: true,
                            icon: Icons.close,
                            onPressed: () =>
                                setState(() => _passed.add(match.personId)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SparkButton(
                            label: 'Coffee chat',
                            icon: Icons.coffee_outlined,
                            onPressed: () => setState(() => _accepted = true),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Text('Warm intros', style: text.titleMedium),
          Text('Through someone who has met you both in person.',
              style: text.bodySmall),
          const SizedBox(height: 8),
          for (final (target, via) in intros) ...[
            GlassContainer(
              child: Row(
                children: [
                  CircleAvatar(
                      backgroundImage:
                          AssetImage(MockData.personById(target).photoAsset)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(MockData.personById(target).firstName,
                            style: text.titleMedium),
                        Text(
                            'Via ${via.map((v) => MockData.personById(v).firstName).join(', ')}',
                            style: text.bodySmall),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _requestIntro(target, via.first),
                    child: const Text('Ask for intro'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// Guilds
// ============================================================================

class GuildsScreen extends StatefulWidget {
  const GuildsScreen({super.key});

  @override
  State<GuildsScreen> createState() => _GuildsScreenState();
}

class _GuildsScreenState extends State<GuildsScreen> {
  final _joined = Services.prefs.guildDating;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hideCounts = Services.prefs.noCounts.value;
    return GlassScaffold(
      appBar: AppBar(title: const Text('Guilds')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Interest communities. Rooms turn into plans and coffee chats — '
            'and, only if you opt in, dating.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final g in MockData.guilds) ...[
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(g.name, style: text.titleMedium)),
                      FilledButton.tonal(
                        onPressed: () => setState(() =>
                            _joined.containsKey(g.id)
                                ? _joined.remove(g.id)
                                : _joined[g.id] = false),
                        child: Text(
                            _joined.containsKey(g.id) ? 'Joined ✓' : 'Join'),
                      ),
                    ],
                  ),
                  Text(
                    hideCounts
                        ? g.blurb
                        : '${g.blurb} · ${g.memberCount} members',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final r in g.rooms)
                        ActionChip(
                          label: Text('# $r'),
                          onPressed: () => showPostToPlanSheet(context,
                              idea: '${g.name}: $r meetup'),
                        ),
                    ],
                  ),
                  if (_joined.containsKey(g.id) && g.datingOptIn)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Open to dating here'),
                      subtitle: const Text(
                          'Other opted-in, 21+ verified members may appear in your Dates tab.'),
                      value: _joined[g.id]!,
                      onChanged: (v) => setState(() => _joined[g.id] = v),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text('Tap a room to start a plan from it.', style: text.bodySmall),
        ],
      ),
    );
  }
}
