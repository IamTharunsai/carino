import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/platform.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/post_to_plan_sheet.dart';
import '../../widgets/spark_button.dart';
import '../moments/moments_screen.dart';
import '../../models/creator.dart';
import '../../widgets/copy_text.dart';
import '../../widgets/gift_sheet.dart';
import '../../services/links.dart';
import '../experience/experience_screens.dart' show showHeartBurst;
import '../../widgets/media.dart';
import '../../widgets/plus_nudge.dart';
import 'creator_profile_screen.dart';

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

/// Reels: one full-screen post at a time, swipe up for the next, never
/// ends. Double-tap to like. Right rail: profile (with online dot), like,
/// comment, gift, share.
class _FeedViewState extends State<_FeedView> {
  final TextEditingController _ask = TextEditingController();
  FeedControls _controls = const FeedControls();
  bool _humanOnly = false;
  final List<FeedItem> _mine = [];
  final Map<String, List<String>> _comments = {};
  final _prefs = Services.prefs;

  @override
  void dispose() {
    _ask.dispose();
    super.dispose();
  }

  void _tune() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (s) => StatefulBuilder(
        builder: (s, set) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(s).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Tune your feed', style: Theme.of(s).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              key: const Key('feed-ask'),
              controller: _ask,
              decoration: const InputDecoration(hintText: 'e.g. more music, less diet, more friends'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Only real people (no AI posts)'),
              value: _humanOnly,
              onChanged: (v) => set(() => _humanOnly = v),
            ),
            SparkButton(
              label: 'Apply',
              onPressed: () {
                setState(() => _controls = parseFeedControls(_ask.text, MockData.feedTopics));
                Navigator.pop(s);
              },
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _post() async {
    final media = await chooseMedia(context);
    if (media == null || !mounted) return;
    setState(() => _mine.insert(
          0,
          FeedItem(
            id: 'mine-${DateTime.now().millisecondsSinceEpoch}',
            creatorId: 'me',
            creatorName: 'You',
            caption: 'New post',
            topic: MockData.feedTopics.first,
            minutesAgo: 0,
            imageAsset: isVideo(media) ? MockData.currentUser.photoAsset : media,
          ),
        ));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Posted ✨ Videos up to ${maxVideoSeconds(isPlus: Services.payments.isPlus) ~/ 60} min.')));
  }

  void _like(FeedItem item) => setState(() {
        _prefs.likedPosts.contains(item.id) ? _prefs.likedPosts.remove(item.id) : _prefs.likedPosts.add(item.id);
        _prefs.save();
      });

  void _openComments(FeedItem item) {
    final can = canComment(isPlus: Services.payments.isPlus, subscribed: _prefs.subscriptions.contains(item.creatorId));
    final input = TextEditingController();
    final list = _comments.putIfAbsent(item.id, () => []);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (s) => StatefulBuilder(
        builder: (s, set) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(s).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(s).size.height * 0.6,
            child: Column(children: [
              Text('Comments', style: Theme.of(s).textTheme.titleMedium),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('No comments yet. Be the first 💬'))
                    : ListView(children: [for (final c in list) ListTile(leading: const Icon(Icons.person), title: Text(c))]),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: can
                    ? TextField(
                        controller: input,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Add a comment…',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send),
                            tooltip: 'Post comment',
                            onPressed: () {
                              if (input.text.trim().isEmpty) return;
                              set(() => list.add(input.text.trim()));
                              input.clear();
                            },
                          ),
                        ),
                      )
                    : SparkButton(
                        label: 'Comment with Plus or by subscribing',
                        secondary: true,
                        onPressed: () {
                          Navigator.pop(s);
                          showPlusNudge(context,
                              title: 'Comments are for Plus & subscribers',
                              body: 'Hearts are free for everyone. Comments are for Plus members and '
                                  '${item.creatorName}\'s subscribers — it keeps comment sections kind and spam-free.');
                        },
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _share(FeedItem item) async {
    final ok = await copyText(context, shareLink(item.creatorId));
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied — it opens their profile 💌')));
    }
  }

  void _openProfile(FeedItem item) {
    if (item.creatorId == 'me') return;
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => CreatorProfileScreen(creatorId: item.creatorId, name: item.creatorName)))
        .then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final items = buildFeed([..._mine, ...MockData.feed], controls: _controls, humanOnly: _humanOnly)
        .where((i) => !i.subscribersOnly || _prefs.subscriptions.contains(i.creatorId))
        .toList();
    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: Stack(children: [
        if (items.isEmpty)
          const Center(child: Text('Nothing matches your tuning — loosen it up?', style: TextStyle(color: AppColors.warmIvory)))
        else
          PageView.builder(
            scrollDirection: Axis.vertical,
            // ponytail: demo loops the sample posts; live pages from the server.
            itemBuilder: (_, i) => _reel(items[i % items.length]),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
            child: Row(children: [
              Expanded(child: widget.header),
              IconButton(icon: const Icon(Icons.tune, color: AppColors.warmIvory), tooltip: 'Tune your feed', onPressed: _tune),
              IconButton(icon: const Icon(Icons.add_circle_outline, color: AppColors.warmIvory), tooltip: 'Post', onPressed: _post),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _railButton(IconData icon, String label, VoidCallback onTap, {Color color = AppColors.warmIvory}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: InkWell(
          onTap: onTap,
          child: Column(children: [
            Icon(icon, color: color, size: 32),
            Text(label, style: const TextStyle(color: AppColors.warmIvory, fontSize: 12)),
          ]),
        ),
      );

  Widget _reel(FeedItem item) {
    final liked = _prefs.likedPosts.contains(item.id);
    final following = _prefs.following.contains(item.creatorId);
    return GestureDetector(
      onDoubleTap: () {
        if (!liked) _like(item);
        showHeartBurst(context);
      },
      child: Stack(fit: StackFit.expand, children: [
        MediaImage(item.imageAsset),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x66151014), Colors.transparent, Colors.transparent, Color(0xDD151014)],
              stops: [0, 0.18, 0.55, 1],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        if (item.aiGenerated)
          const Positioned(
            top: 100,
            left: 12,
            child: Chip(avatar: Icon(Icons.auto_awesome, size: 14), label: Text('AI-made'), visualDensity: VisualDensity.compact),
          ),
        Positioned(
          right: 10,
          bottom: 120,
          child: Column(children: [
            GestureDetector(
              onTap: () => _openProfile(item),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Stack(clipBehavior: Clip.none, children: [
                  CircleAvatar(radius: 24, backgroundImage: AssetImage(MockData.currentUser.photoAsset)),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: MockData.isOnline(item.creatorId) ? const Color(0xFF34C759) : const Color(0xFF8E8E93),
                        border: Border.all(color: AppColors.midnight, width: 2),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            _railButton(liked ? Icons.favorite : Icons.favorite_border, liked ? 'Hearted' : 'Heart', () => _like(item),
                color: liked ? AppColors.emberCrimson : AppColors.warmIvory),
            _railButton(Icons.mode_comment_outlined, '${_comments[item.id]?.length ?? 0}', () => _openComments(item)),
            if (item.creatorId != 'me') _railButton(Icons.card_giftcard, 'Gift', () => showGiftSheet(context, item.creatorName)),
            _railButton(Icons.send_outlined, 'Share', () => _share(item)),
            _railButton(Icons.more_horiz, '', () => _more(item)),
          ]),
        ),
        Positioned(
          left: 14,
          right: 80,
          bottom: 110,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: GestureDetector(
                  onTap: () => _openProfile(item),
                  child: Text(item.creatorName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.warmIvory, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              if (item.verifiedHuman) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified, size: 18, color: Color(0xFFE8B84A)), // gold = ID-verified
              ],
              if (item.creatorId != 'me') ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.warmIvory, visualDensity: VisualDensity.compact),
                  onPressed: () => setState(() {
                    following ? _prefs.following.remove(item.creatorId) : _prefs.following.add(item.creatorId);
                    _prefs.save();
                  }),
                  child: Text(following ? 'Following' : 'Follow'),
                ),
              ],
            ]),
            const SizedBox(height: 4),
            Text(item.caption, style: const TextStyle(color: AppColors.warmIvory)),
          ]),
        ),
      ]),
    );
  }

  void _more(FeedItem item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (s) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (item.planIdea != null)
            ListTile(
              leading: const Icon(Icons.event_available_outlined),
              title: const Text('Make it a plan'),
              onTap: () {
                Navigator.pop(s);
                showPostToPlanSheet(context, idea: item.planIdea!);
              },
            ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Report'),
            onTap: () {
              Navigator.pop(s);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reported. Our team will review it.')));
            },
          ),
        ]),
      ),
    );
  }
}
