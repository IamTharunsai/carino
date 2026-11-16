import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/member.dart';
import '../../models/social.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/safety_actions.dart';
import '../../widgets/spark_button.dart';
import '../../widgets/state_kit.dart';
import 'moment_viewer_screen.dart';

/// S-022 Moments Feed + S-023 Create + S-024 Viewer.
/// 24h Moments for your connections; expiry labels are real (server-side
/// timers in production). Report is on every Moment (overflow). Your own
/// Moment pins to the top with its moderation state — uploads are
/// pre-screened BEFORE they appear (AI-05 holds distribution; humans
/// decide), and the feed says so instead of pretending otherwise.
class MomentsScreen extends StatefulWidget {
  /// Optional title replacement (Stage puts its Feed/Moments switch here).
  const MomentsScreen({super.key, this.header});

  final Widget? header;

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  late final List<Moment> _all = [
    ...MockData.friendMoments,
    ...MockData.moments,
  ];
  Moment? _ownMoment;

  /// Feed filter: everything you can see, friends only, or dates only.
  String _filter = 'All';

  /// Only Moments whose circle includes YOU (as the poster placed you —
  /// demo assumes placements are mutual). Unknown people see 'everyone'
  /// posts only.
  List<Moment> get _moments => _all.where((m) {
        final rel = Services.social.circleOf(m.member.id);
        final visible = rel == null
            ? m.circle == Circle.everyone
            : circleCanSee(m.circle, rel);
        if (!visible) return false;
        final isFriend = Services.social.isFriend(m.member.id);
        return switch (_filter) {
          'Friends' => isFriend,
          'Dates' => !isFriend,
          _ => true,
        };
      }).toList();

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          Row(
            children: [
              Expanded(
                child: widget.header ??
                    Text('Moments', style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Create a Moment',
                onPressed: _createSheet,
              ),
            ],
          ),
          Text(
            'Real life, for 24 hours. Every Moment is shared to a circle you pick.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final f in ['All', 'Friends', 'Dates'])
                ChoiceChip(
                  label: Text(f),
                  selected: _filter == f,
                  selectedColor: AppColors.emberCrimson,
                  onSelected: (_) => setState(() => _filter = f),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Your moment ring.
          GlassContainer(
            onTap: () {
              if (_ownMoment != null) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MomentViewerScreen(
                      moments: [_ownMoment!],
                      initialIndex: 0,
                      isOwn: true,
                    ),
                  ),
                );
              } else {
                _createSheet();
              }
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage:
                      AssetImage(MockData.currentUser.photoAsset),
                  child: _ownMoment == null
                      ? const Icon(Icons.add, color: AppColors.warmIvory)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _ownMoment == null
                        ? 'Share a Moment'
                        : 'Your Moment · ${_ownMoment!.circle.label}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (_ownMoment != null)
                  const Chip(
                    label: Text('Live · approved'),
                    visualDensity: VisualDensity.compact,
                    labelStyle: TextStyle(fontSize: 11),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_moments.isEmpty)
            const AppEmptyState(
              icon: Icons.photo_library_outlined,
              title: 'No Moments right now',
              body:
                  'When your connections share something, it shows up here for 24 hours.',
            ),
          for (var i = 0; i < _moments.length; i++) ...[
            _momentCard(context, _moments[i], i),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _momentCard(BuildContext context, Moment moment, int index) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MomentViewerScreen(
            moments: _moments,
            initialIndex: index,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Image.asset(moment.imageAsset,
                height: 300, width: double.infinity, fit: BoxFit.cover),
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
              top: 10,
              right: 6,
              child: IconButton(
                icon: const Icon(Icons.more_horiz, color: AppColors.warmIvory),
                tooltip: 'Report or block',
                onPressed: () => SafetyActions.showForMember(
                  context,
                  member: moment.member,
                  surface: 'Moment',
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: GlassContainer(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage:
                              AssetImage(moment.member.photoAsset),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            moment.member.firstName,
                            style: const TextStyle(
                                color: AppColors.warmIvory,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        // Circle + expiry in one chip that can shrink, so
                        // the header never overflows on small phones.
                        Flexible(
                          child: Chip(
                            avatar: const Icon(Icons.schedule, size: 13),
                            label: Text(
                              moment.circle == Circle.everyone
                                  ? moment.expiresInLabel
                                  : '${moment.circle.label} · ${moment.expiresInLabel}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            visualDensity: VisualDensity.compact,
                            labelStyle: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(moment.caption,
                        style: const TextStyle(color: AppColors.warmIvory)),
                    if (moment.sticker != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.how_to_vote_outlined,
                              size: 14, color: AppColors.sparkCoral),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Tap to answer · ${moment.sticker!.question}',
                              style: const TextStyle(
                                  color: AppColors.sparkCoral, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// S-023 Create — type picker, caption, audience selector, review note,
  /// Post. The post lands in the feed only after the (demo) moderation
  /// pass; the sheet states the real pipeline instead of hiding it.
  void _createSheet() {
    var kind = 'Photo';
    var audience = Circle.friends;
    StickerKind? sticker;
    final caption = TextEditingController();
    final stickerQ = TextEditingController();
    final optA = TextEditingController();
    final optB = TextEditingController();
    showGlassSheet<void>(
      context,
      child: StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New Moment', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final k in ['Photo', 'Video', 'Text'])
                  ChoiceChip(
                    label: Text(k),
                    selected: kind == k,
                    selectedColor: AppColors.emberCrimson,
                    onSelected: (_) => setSheet(() => kind = k),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: caption,
              maxLength: 140,
              decoration: const InputDecoration(
                labelText: 'Caption',
                hintText: 'What\'s happening?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
            Text('Add a sticker', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('None'),
                  selected: sticker == null,
                  selectedColor: AppColors.emberCrimson,
                  onSelected: (_) => setSheet(() => sticker = null),
                ),
                for (final (k, label) in [
                  (StickerKind.poll, 'Poll'),
                  (StickerKind.askMe, 'Ask me'),
                  (StickerKind.thisOrThat, 'This or That'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: sticker == k,
                    selectedColor: AppColors.emberCrimson,
                    onSelected: (_) => setSheet(() => sticker = k),
                  ),
              ],
            ),
            if (sticker != null) ...[
              const SizedBox(height: 8),
              TextField(
                controller: stickerQ,
                maxLength: 60,
                decoration: InputDecoration(
                  labelText: sticker == StickerKind.askMe
                      ? 'Ask me…'
                      : 'Question',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
              if (sticker != StickerKind.askMe)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: optA,
                        decoration: const InputDecoration(labelText: 'Option A'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: optB,
                        decoration: const InputDecoration(labelText: 'Option B'),
                      ),
                    ),
                  ],
                ),
              Text(
                'Answers come to you as private chat openers. No public counts.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 6),
            Text('Who can see it?', style: Theme.of(ctx).textTheme.titleMedium),
            RadioGroup<Circle>(
              groupValue: audience,
              onChanged: (v) => setSheet(() => audience = v ?? Circle.friends),
              child: Column(
                children: [
                  for (final c in Circle.values)
                    RadioListTile<Circle>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(c.label),
                      subtitle: Text(c.hint),
                      value: c,
                    ),
                ],
              ),
            ),
            Text(
              'Every Moment is pre-screened before it appears. In the demo '
              'it posts instantly; in production a hold of a few seconds '
              'is normal — we\'d rather be honest than instant.',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            SparkButton(
              label: 'Post Moment',
              icon: Icons.send_outlined,
              onPressed: () {
                // INTEGRATION POINT: media picker -> storage upload ->
                // moderation hold -> publish (BackendService).
                Navigator.of(ctx).pop();
                final q = stickerQ.text.trim();
                setState(() {
                  _ownMoment = Moment(
                    sticker: sticker == null
                        ? null
                        : MomentSticker(
                            kind: sticker!,
                            question: q.isEmpty
                                ? (sticker == StickerKind.askMe
                                    ? 'Ask me anything'
                                    : 'Which one?')
                                : q,
                            options: sticker == StickerKind.askMe
                                ? const []
                                : [
                                    optA.text.trim().isEmpty ? 'This' : optA.text.trim(),
                                    optB.text.trim().isEmpty ? 'That' : optB.text.trim(),
                                  ],
                          ),
                    id: 'moment-own-${DateTime.now().millisecondsSinceEpoch}',
                    member: MockData.currentUser,
                    caption: caption.text.trim().isEmpty
                        ? 'Out and about.'
                        : caption.text.trim(),
                    imageAsset: 'assets/images/backdrop_match.jpg',
                    expiresInLabel: '24h',
                    circle: audience,
                  );
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Moment shared with ${audience.label} ✨ It disappears in 24h.'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
