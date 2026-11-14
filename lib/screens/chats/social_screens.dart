import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/mock_data.dart';
import '../../models/experience.dart';
import '../../models/member.dart';
import '../../models/social.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/safety_actions.dart';
import '../../widgets/spark_button.dart';

/// Social Phase 1: Friends & circles, new groups, and group chats with a
/// Plan button. Friends never mix with Dates: a group chat can only hold
/// people in your Inner circle or Friends.

// ============================================================================
// Friends & circles
// ============================================================================

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _graph = Services.social;

  Future<void> _addFriend() async {
    final username = TextEditingController();
    await showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add a friend', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Friends see what you share to Friends or Inner circle. They never '
            'see your Dates activity.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SparkButton(
            label: 'Copy my invite link',
            icon: Icons.link,
            secondary: true,
            onPressed: () async {
              try {
                await Clipboard.setData(const ClipboardData(
                    text: 'https://carino.app/add/you-demo'));
              } catch (_) {}
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Invite link copied.')));
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: username,
            decoration: const InputDecoration(
              labelText: 'Or add by username',
              prefixText: '@',
            ),
          ),
          const SizedBox(height: 10),
          SparkButton(
            label: 'Send friend request',
            icon: Icons.person_add_alt_1_outlined,
            onPressed: () {
              final u = username.text.trim();
              if (u.isEmpty) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'Request sent to @$u. They\'ll appear here when they accept.')));
            },
          ),
        ],
      ),
    );
  }

  Widget _person(Member p, Circle c) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(backgroundImage: AssetImage(p.photoAsset)),
        title: Text(p.pronouns.isEmpty ? p.name : '${p.name}  ·  ${p.pronouns}'),
        subtitle: Text(p.headline, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: PopupMenuButton<String>(
          tooltip: 'Move or remove ${p.firstName}',
          onSelected: (v) {
            if (v == 'remove') {
              setState(() => _graph.remove(p.id));
            } else if (v == 'report') {
              SafetyActions.showForMember(context, member: p, surface: 'Friends');
            } else {
              setState(() => _graph.place(
                  p.id, v == 'inner' ? Circle.inner : Circle.friends));
            }
          },
          itemBuilder: (_) => [
            if (c != Circle.inner)
              const PopupMenuItem(value: 'inner', child: Text('Move to Inner circle')),
            if (c != Circle.friends)
              const PopupMenuItem(value: 'friends', child: Text('Move to Friends')),
            const PopupMenuItem(value: 'remove', child: Text('Remove friend')),
            const PopupMenuItem(value: 'report', child: Text('Report or block')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Friends & circles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: 'Add a friend',
            onPressed: _addFriend,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Circles decide who sees what. Nobody is told which circle you '
            'put them in.',
            style: text.bodyMedium,
          ),
          for (final c in [Circle.inner, Circle.friends]) ...[
            const SizedBox(height: 16),
            Text('${c.label} · ${_graph.inCircle(c).length}',
                style: text.titleMedium),
            Text(c.hint, style: text.bodySmall),
            const SizedBox(height: 8),
            if (_graph.inCircle(c).isEmpty)
              GlassContainer(
                child: Text('Nobody here yet.', style: text.bodyMedium),
              ),
            for (final id in _graph.inCircle(c)) ...[
              _person(MockData.personById(id), c),
              const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 16),
          Text(
            'Matches live in your Dates circle and are managed in the Dates tab.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// New group
// ============================================================================

/// Pick friends + a name; returns the new group (or null).
Future<GroupChat?> showNewGroupSheet(BuildContext context) {
  final graph = Services.social;
  final friendIds = [...graph.inCircle(Circle.inner), ...graph.inCircle(Circle.friends)];
  final picked = <String>{};
  final name = TextEditingController();
  return showGlassSheet<GroupChat>(
    context,
    child: StatefulBuilder(
      builder: (ctx, setSheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New group', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Groups are for friends. Matches stay in Dates.',
              style: Theme.of(ctx).textTheme.bodySmall),
          const SizedBox(height: 10),
          TextField(
            controller: name,
            maxLength: 40,
            decoration: const InputDecoration(labelText: 'Group name'),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in friendIds)
                FilterChip(
                  avatar: CircleAvatar(
                      backgroundImage:
                          AssetImage(MockData.personById(id).photoAsset)),
                  label: Text(MockData.personById(id).firstName),
                  selected: picked.contains(id),
                  selectedColor: AppColors.emberCrimson,
                  showCheckmark: false,
                  onSelected: (_) => setSheet(() =>
                      picked.contains(id) ? picked.remove(id) : picked.add(id)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SparkButton(
            label: 'Create group',
            icon: Icons.group_add_outlined,
            onPressed: picked.isEmpty
                ? null
                : () => Navigator.of(ctx).pop(GroupChat(
                      id: 'g-${DateTime.now().millisecondsSinceEpoch}',
                      name: name.text.trim().isEmpty
                          ? picked.map((i) => MockData.personById(i).firstName).join(', ')
                          : name.text.trim(),
                      memberIds: picked.toList(),
                      messages: [
                        GroupMessage(
                            senderId: 'me',
                            text: 'You created the group',
                            timeLabel: 'now',
                            isSystem: true),
                      ],
                    )),
          ),
        ],
      ),
    ),
  );
}

// ============================================================================
// Group chat with the Plan button
// ============================================================================

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key, required this.group});
  final GroupChat group;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _composer = TextEditingController();
  final List<Timer> _timers = [];
  bool _shieldDismissed = false;

  GroupChat get _g => widget.group;
  int get _groupSize => _g.memberIds.length + 1; // + me

  @override
  void initState() {
    super.initState();
    _g.unreadCount = 0;
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _composer.dispose();
    super.dispose();
  }

  void _send() {
    final t = _composer.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _g.messages.add(GroupMessage(senderId: 'me', text: t, timeLabel: 'now'));
      _composer.clear();
    });
  }

  Future<void> _startPlan() async {
    final suggested = suggestPlanTimes(_g.messages.map((m) => m.text));
    final picked = <String>{...suggested.take(2)};
    final place = TextEditingController();
    const ideas = ['Bowling', 'Night market', 'Brunch', 'Board-game café', 'Picnic'];
    final poll = await showGlassSheet<PlanPoll>(
      context,
      child: StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Make it a plan', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Times suggested from your chat — pick the ones to vote on.',
                style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in suggested)
                  FilterChip(
                    label: Text(s),
                    selected: picked.contains(s),
                    selectedColor: AppColors.emberCrimson,
                    showCheckmark: false,
                    onSelected: (_) => setSheet(() =>
                        picked.contains(s) ? picked.remove(s) : picked.add(s)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('What?', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final i in ideas)
                  ActionChip(
                    label: Text(i),
                    onPressed: () => setSheet(() => place.text = i),
                  ),
              ],
            ),
            TextField(
              controller: place,
              decoration: const InputDecoration(
                  labelText: 'Public place or activity'),
            ),
            const SizedBox(height: 14),
            SparkButton(
              label: 'Start the vote',
              icon: Icons.how_to_vote_outlined,
              onPressed: () {
                if (picked.isEmpty || place.text.trim().isEmpty) return;
                Navigator.of(ctx).pop(PlanPoll(
                    placeType: place.text.trim(), options: picked.toList()));
              },
            ),
          ],
        ),
      ),
    );
    if (poll == null || !mounted) return;
    setState(() {
      _g.poll = poll;
      _g.messages.add(GroupMessage(
          senderId: 'me',
          text: 'You started a plan vote: ${poll.placeType}',
          timeLabel: 'now',
          isSystem: true));
    });
  }

  void _vote(String option) {
    final poll = _g.poll!;
    setState(() => poll.vote('me', option));
    // Demo: friends' votes arrive after a beat (sample members). In
    // production these are real votes over the realtime channel.
    for (var i = 0; i < _g.memberIds.length; i++) {
      final id = _g.memberIds[i];
      if (poll.myVote(id) != null) continue;
      _timers.add(Timer(Duration(milliseconds: 600 + 500 * i), () {
        if (!mounted || _g.poll != poll) return;
        setState(() {
          // Most friends go with you; the last one picks the first option.
          poll.vote(id, i == _g.memberIds.length - 1 && i > 0
              ? poll.votes.keys.first
              : option);
          _checkWinner();
        });
      }));
    }
    _checkWinner();
  }

  void _checkWinner() {
    final poll = _g.poll;
    if (poll == null) return;
    final w = poll.winner(_groupSize);
    if (w == null) return;
    _g.poll = null;
    _g.messages.add(GroupMessage(
        senderId: 'me',
        text: 'Plan set: ${poll.placeType} · $w — the group voted',
        timeLabel: 'now',
        isSystem: true));
    Services.sound.planConfirmed();
  }

  Widget _pollCard(PlanPoll poll) {
    final text = Theme.of(context).textTheme;
    final mine = poll.myVote('me');
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_vote_outlined,
                  size: 18, color: AppColors.sparkCoral),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('Vote: ${poll.placeType}', style: text.titleSmall)),
              Text('${poll.totalVotes}/$_groupSize', style: text.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          for (final e in poll.votes.entries) ...[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: mine == e.key
                    ? AppColors.emberCrimson.withValues(alpha: 0.25)
                    : null,
              ),
              onPressed: () => _vote(e.key),
              child: Row(
                children: [
                  Expanded(child: Text(e.key)),
                  for (final v in e.value.take(4))
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: CircleAvatar(
                        radius: 9,
                        backgroundImage: AssetImage(v == 'me'
                            ? MockData.currentUser.photoAsset
                            : MockData.personById(v).photoAsset),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text('Locks when most of the group agrees.', style: text.bodySmall),
        ],
      ),
    );
  }

  Set<ScamSignal> get _signals => {
        for (final m in _g.messages)
          if (!m.isSystem) ...scanForScam(m.text),
      };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassScaffold(
      appBar: AppBar(
        title: Text(_g.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_available_outlined),
            tooltip: 'Make it a plan',
            onPressed: _startPlan,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final id in _g.memberIds)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      avatar: CircleAvatar(
                          backgroundImage:
                              AssetImage(MockData.personById(id).photoAsset)),
                      label: Text(MockData.personById(id).firstName),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
          if (_signals.isNotEmpty && !_shieldDismissed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: GlassContainer(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        size: 18, color: AppColors.sparkCoral),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(scamShieldCopy(_signals),
                            style: text.bodySmall)),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'Dismiss',
                      onPressed: () => setState(() => _shieldDismissed = true),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              children: [
                for (final m in _g.messages) _bubble(m),
                if (_g.poll != null) ...[
                  const SizedBox(height: 6),
                  _pollCard(_g.poll!),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.event_available_outlined),
                  tooltip: 'Make it a plan',
                  onPressed: _startPlan,
                ),
                Expanded(
                  child: TextField(
                    controller: _composer,
                    decoration: InputDecoration(
                      hintText: 'Message ${_g.name}…',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.emberCrimson),
                  tooltip: 'Send',
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(GroupMessage m) {
    final text = Theme.of(context).textTheme;
    if (m.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Text(m.text, style: text.bodySmall, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    final mine = m.senderId == 'me';
    final sender = mine ? null : MockData.personById(m.senderId);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: mine
              ? AppColors.emberCrimson
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sender != null)
              Text(sender.firstName,
                  style: const TextStyle(
                      color: AppColors.sparkCoral,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            Text(m.text,
                style: TextStyle(
                    color: mine
                        ? AppColors.warmIvory
                        : Theme.of(context).textTheme.bodyLarge?.color)),
            Text(m.timeLabel,
                style: TextStyle(
                    fontSize: 10,
                    color: (mine ? AppColors.warmIvory : AppColors.softRose)
                        .withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}
