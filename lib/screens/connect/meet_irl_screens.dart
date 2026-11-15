import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/mock_data.dart';
import '../../models/experience.dart';
import '../../models/member.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';
import 'plan_detail_screen.dart';
import '../../widgets/copy_text.dart';
import 'spark_session_screen.dart';

/// Real-world connection bundle: Events Near You, Speed Spark Nights and
/// Group Hangouts. Plans are the win state; these give people a ready
/// reason to meet. Public venue TYPES only, attendance visible to matches
/// only, everyone involved is verified.

// ============================================================================
// Events Near You
// ============================================================================

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final Set<String> _going = {};
  String? _category;
  late bool _stepFreeOnly = Services.prefs.accessNote.isNotEmpty;

  List<LocalEvent> get _events => MockData.events
      .where((e) => _category == null || e.category == _category)
      .where((e) => !_stepFreeOnly || e.stepFree)
      .toList();

  Future<void> _makePlan(LocalEvent e) async {
    final member = await showGlassSheet<Member>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Who do you want to invite?',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final m in MockData.matches)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                  backgroundImage: AssetImage(m.member.photoAsset)),
              title: Text(m.member.firstName),
              subtitle: Text(m.member.intention.label),
              onTap: () => Navigator.of(context).pop(m.member),
            ),
        ],
      ),
    );
    if (member == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlanDetailScreen(
          member: member,
          placeType: '${e.title} · ${e.venueType}',
          timeLabel: e.timeLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final categories = {for (final e in MockData.events) e.category}.toList();
    final events = _events;
    return GlassScaffold(
      appBar: AppBar(title: const Text('Events near you')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Public things to do in Columbus. Say you\'re going and only your '
            'matches see it — never strangers, never your location.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _category == null,
                selectedColor: AppColors.emberCrimson,
                onSelected: (_) => setState(() => _category = null),
              ),
              for (final c in categories)
                ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  selectedColor: AppColors.emberCrimson,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.accessible_forward),
            title: const Text('Step-free venues only'),
            value: _stepFreeOnly,
            onChanged: (v) => setState(() => _stepFreeOnly = v),
          ),
          if (events.isEmpty)
            GlassContainer(
              child: Text('Nothing matches those filters this week.',
                  style: text.bodyMedium),
            ),
          for (final e in events) ...[
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(e.title, style: text.titleMedium)),
                      if (e.stepFree)
                        const Tooltip(
                          message: 'Step-free venue',
                          child: Icon(Icons.accessible_forward, size: 18),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${e.venueType} · ${e.timeLabel} · ${e.category}',
                      style: text.bodySmall),
                  if (e.goingMatchIds.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${e.goingMatchIds.map((id) => MockData.memberById(id).firstName).join(', ')} '
                      '(your match) is going',
                      style: const TextStyle(
                          color: AppColors.sparkCoral, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SparkButton(
                          label: _going.contains(e.id) ? 'Going ✓' : 'I\'m going',
                          secondary: true,
                          icon: Icons.event_available_outlined,
                          onPressed: () => setState(() => _going.contains(e.id)
                              ? _going.remove(e.id)
                              : _going.add(e.id)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SparkButton(
                          label: 'Make it a plan',
                          icon: Icons.calendar_month_outlined,
                          onPressed: () => _makePlan(e),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            'Sample listings. In production these come from partner venues '
            'and a curated city feed.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Speed Spark Nights
// ============================================================================

class SparkNightsScreen extends StatefulWidget {
  const SparkNightsScreen({super.key});

  @override
  State<SparkNightsScreen> createState() => _SparkNightsScreenState();
}

class _SparkNightsScreenState extends State<SparkNightsScreen> {
  final Set<String> _saved = {};

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassScaffold(
      appBar: AppBar(title: const Text('Spark Nights')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Themed evenings: three 5-minute Spark calls in a row. Same rules '
            'as every Spark — full profiles first, both accept, report and '
            'block on screen the whole time. Never anonymous.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final n in MockData.sparkNights) ...[
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.nightlife_outlined,
                          color: AppColors.sparkCoral),
                      const SizedBox(width: 8),
                      Expanded(child: Text(n.theme, style: text.titleMedium)),
                      if (n.ageBand != null)
                        Chip(
                          label: Text(n.ageBand!),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  Text(n.timeLabel, style: text.bodySmall),
                  const SizedBox(height: 6),
                  Text(n.blurb, style: text.bodyMedium),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SparkButton(
                          label: _saved.contains(n.id) ? 'Spot saved ✓' : 'Save my spot',
                          secondary: true,
                          icon: Icons.bookmark_add_outlined,
                          onPressed: () => setState(() => _saved.contains(n.id)
                              ? _saved.remove(n.id)
                              : _saved.add(n.id)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SparkButton(
                          label: 'Try it now',
                          icon: Icons.video_call_outlined,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SparkPreCallScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            'We\'ll remind you 30 minutes before. Times come from Cariño '
            'servers — no fake countdowns.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Group Hangouts & Double Dates
// ============================================================================

class GroupHangoutScreen extends StatefulWidget {
  const GroupHangoutScreen({super.key});

  @override
  State<GroupHangoutScreen> createState() => _GroupHangoutScreenState();
}

class _GroupHangoutScreenState extends State<GroupHangoutScreen> {
  bool _friendInvited = false;
  Member? _pairWith;
  String _plan = 'Bowling';
  bool _created = false;

  static const _ideas = ['Bowling', 'Trivia night', 'Mini golf', 'Board-game café'];

  Future<void> _inviteFriend() async {
    const link = 'https://carino.app/hangout/invite/demo-7Q2X';
    if (!await copyText(context, link)) return;
    if (!mounted) return;
    setState(() => _friendInvited = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Invite link copied. Your friend joins once they\'re verified too.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final matches = MockData.matches
        .where((m) => m.member.intention == Intention.hangoutAndPlay ||
            m.member.intention == Intention.casualDating)
        .toList();
    if (_created) {
      return GlassScaffold(
        appBar: AppBar(title: const Text('Group hangout')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.groups_outlined,
                  size: 48, color: AppColors.sparkCoral),
              const SizedBox(height: 12),
              Text('$_plan · 2 + 2',
                  style: text.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Proposed to ${_pairWith!.firstName}. When they and their '
                'friend accept, a group chat opens for all four of you.',
                style: text.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SparkButton(
                label: 'Done',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    }
    return GlassScaffold(
      appBar: AppBar(title: const Text('Group hangout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Bring a friend, meet a match and their friend. Lower pressure, '
            'more fun, safer first meetings.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: 14),
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('1 · Bring a friend', style: text.titleMedium),
                const SizedBox(height: 4),
                Text('They get a link and verify before they can join.',
                    style: text.bodySmall),
                const SizedBox(height: 10),
                SparkButton(
                  label: _friendInvited ? 'Invite link copied ✓' : 'Copy invite link',
                  icon: Icons.link,
                  secondary: true,
                  onPressed: _inviteFriend,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('2 · Pick a match to pair with', style: text.titleMedium),
                const SizedBox(height: 4),
                RadioGroup<String>(
                  groupValue: _pairWith?.id,
                  onChanged: (id) => setState(
                      () => _pairWith = id == null ? null : MockData.memberById(id)),
                  child: Column(
                    children: [
                      for (final m in matches)
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: m.member.id,
                          title: Text(m.member.firstName),
                          subtitle: Text(m.member.intention.label),
                          secondary: CircleAvatar(
                              backgroundImage:
                                  AssetImage(m.member.photoAsset)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('3 · What should we do?', style: text.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final i in _ideas)
                      ChoiceChip(
                        label: Text(i),
                        selected: _plan == i,
                        selectedColor: AppColors.emberCrimson,
                        onSelected: (_) => setState(() => _plan = i),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SparkButton(
            label: 'Propose the hangout',
            icon: Icons.groups_outlined,
            onPressed: _friendInvited && _pairWith != null
                ? () => setState(() => _created = true)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            'Everyone is verified. Anyone can leave or block at any time '
            'without exposing the others.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}
