import 'package:flutter/material.dart';
import '../../config/env.dart';
import '../../data/mock_data.dart';
import '../../models/platform.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/post_to_plan_sheet.dart';
import '../../widgets/spark_button.dart';
import '../moments/moments_screen.dart';

/// STAGE — watch and create. Two rooms: a FINITE short-video Feed you
/// steer in plain words, and 24h Moments. The feed ends ("You're caught
/// up"), can go chronological, and the Human-Made filter shows only
/// verified-human posts. AI media is always labelled, never disguised.
class StageScreen extends StatefulWidget {
  const StageScreen({super.key});

  @override
  State<StageScreen> createState() => _StageScreenState();
}

class _StageScreenState extends State<StageScreen> {
  String _room = 'Feed';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: _room == 'Feed' ? 0 : 1,
            children: [
              _FeedView(
                header: _roomSwitch(),
              ),
              MomentsScreen(header: _roomSwitch()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roomSwitch() => SegmentedButton<String>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: 'Feed', label: Text('Feed')),
          ButtonSegment(value: 'Moments', label: Text('Moments')),
        ],
        selected: {_room},
        onSelectionChanged: (v) => setState(() => _room = v.first),
      );
}

class _FeedView extends StatefulWidget {
  const _FeedView({required this.header});
  final Widget header;

  @override
  State<_FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<_FeedView> {
  final TextEditingController _ask = TextEditingController();
  FeedControls _controls = const FeedControls();
  bool _humanOnly = false;
  bool _chronological = false;
  final List<FeedItem> _mine = [];
  bool _doneForToday = false;

  @override
  void dispose() {
    _ask.dispose();
    super.dispose();
  }

  void _apply() {
    setState(() => _controls = parseFeedControls(_ask.text, MockData.feedTopics));
    if (_controls.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Try: "more friends, less viral, no diet, more music, 20 min"')));
    }
  }

  void _gift(FeedItem item) {
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Send ${item.creatorName} a gift',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Gifts are paid through the App Store or Google Play, at the price '
            'the store shows. Creators receive a share.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final g in MockData.gifts)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(g.emoji, style: const TextStyle(fontSize: 26)),
              title: Text(g.name),
              subtitle: Text(g.priceLabel),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(Env.useMockBackend
                      ? '${g.emoji} ${g.name} sent to ${item.creatorName} (demo — no charge).'
                      : 'Gift purchases open when store products are live.'),
                ));
              },
            ),
        ],
      ),
    );
  }

  void _post() {
    final caption = TextEditingController();
    var topic = MockData.feedTopics.first;
    var usedAi = false;
    var public = true;
    showGlassSheet<void>(
      context,
      child: StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Post a video', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Up to 60s. Captions are added automatically (editable).',
                style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 10),
            TextField(
              controller: caption,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Caption'),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in MockData.feedTopics)
                  ChoiceChip(
                    label: Text(t),
                    selected: topic == t,
                    selectedColor: AppColors.emberCrimson,
                    onSelected: (_) => setSheet(() => topic = t),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Public on Stage'),
              subtitle: Text(public ? 'Anyone can see it' : 'Your circles only'),
              value: public,
              onChanged: (v) => setSheet(() => public = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('I used AI to make this'),
              subtitle: const Text('Required honesty: it gets an "AI-generated" label.'),
              value: usedAi,
              onChanged: (v) => setSheet(() => usedAi = v),
            ),
            const SizedBox(height: 8),
            SparkButton(
              label: 'Post',
              icon: Icons.send_outlined,
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _mine.insert(
                      0,
                      FeedItem(
                        id: 'mine-${DateTime.now().millisecondsSinceEpoch}',
                        creatorId: 'me',
                        creatorName: 'You',
                        caption: caption.text.trim().isEmpty
                            ? 'New post'
                            : caption.text.trim(),
                        topic: topic,
                        minutesAgo: 0,
                        imageAsset: MockData.currentUser.photoAsset,
                        aiGenerated: usedAi,
                        fromCircle: !public,
                      ),
                    ));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'Posted — pre-screened before anyone sees it (demo: instant).')));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final items = buildFeed(
      [..._mine, ...MockData.feed],
      controls: _controls,
      humanOnly: _humanOnly,
      chronological: _chronological,
    );
    return GlassScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          Row(
            children: [
              Expanded(child: widget.header),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Post a video',
                onPressed: _post,
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('feed-ask'),
            controller: _ask,
            onSubmitted: (_) => _apply(),
            decoration: InputDecoration(
              hintText: 'Tell your feed what you want…',
              prefixIcon: const Icon(Icons.tune, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Apply',
                onPressed: _apply,
              ),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              FilterChip(
                avatar: const Icon(Icons.verified_user_outlined, size: 16),
                label: const Text('Human-made only'),
                selected: _humanOnly,
                onSelected: (v) => setState(() => _humanOnly = v),
              ),
              FilterChip(
                avatar: const Icon(Icons.schedule, size: 16),
                label: const Text('Chronological'),
                selected: _chronological,
                onSelected: (v) => setState(() => _chronological = v),
              ),
              for (final d in _controls.describe())
                InputChip(
                  label: Text(d),
                  onDeleted: () => setState(() {
                    _ask.clear();
                    _controls = const FeedControls();
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_doneForToday)
            _endCard(text, done: true)
          else ...[
            for (final item in items) ...[
              _card(item, text),
              const SizedBox(height: 14),
            ],
            _endCard(text),
          ],
        ],
      ),
    );
  }

  Widget _card(FeedItem item, TextTheme text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Image.asset(item.imageAsset,
              height: 340, width: double.infinity, fit: BoxFit.cover),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xCC151014)],
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: Center(
              child: Icon(Icons.play_circle_outline,
                  size: 56, color: AppColors.warmIvory),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Chip(
              avatar: Icon(
                  item.aiGenerated ? Icons.auto_awesome : Icons.verified_user,
                  size: 14),
              label: Text(item.aiGenerated
                  ? 'AI-generated'
                  : (item.verifiedHuman ? 'Verified human' : 'Unverified')),
              visualDensity: VisualDensity.compact,
              labelStyle: const TextStyle(fontSize: 11),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.creatorName,
                    style: const TextStyle(
                        color: AppColors.warmIvory, fontWeight: FontWeight.w600)),
                Text(item.caption,
                    style: const TextStyle(color: AppColors.warmIvory)),
                Text(whyThisPost(item, _controls),
                    style: const TextStyle(color: AppColors.softRose, fontSize: 11)),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          showPostToPlanSheet(context, idea: item.planIdea ?? ''),
                      icon: const Icon(Icons.event_available_outlined,
                          size: 16, color: AppColors.sparkCoral),
                      label: const Text('Make it a plan',
                          style: TextStyle(color: AppColors.warmIvory)),
                    ),
                    const Spacer(),
                    if (item.creatorId != 'me')
                      IconButton(
                        icon: const Icon(Icons.card_giftcard,
                            color: AppColors.warmIvory),
                        tooltip: 'Send a gift',
                        onPressed: () => _gift(item),
                      ),
                    IconButton(
                      icon: const Icon(Icons.flag_outlined,
                          color: AppColors.warmIvory),
                      tooltip: 'Report',
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Reported — a human reviews within 24h.'))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _endCard(TextTheme text, {bool done = false}) {
    return GlassContainer(
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, size: 36, color: AppColors.sparkCoral),
          const SizedBox(height: 8),
          Text(done ? 'Done for today' : 'You\'re caught up',
              style: text.titleMedium),
          const SizedBox(height: 4),
          Text(
            done
                ? 'The feed is resting until tomorrow. Your friends are in Chats.'
                : 'That\'s today\'s feed. No endless scroll — go make a plan.',
            style: text.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SparkButton(
            label: done ? 'Open it again' : 'Done for today',
            secondary: true,
            icon: done ? Icons.refresh : Icons.bedtime_outlined,
            onPressed: () => setState(() => _doneForToday = !done),
          ),
        ],
      ),
    );
  }
}
