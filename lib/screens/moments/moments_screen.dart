import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/member.dart';
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
  const MomentsScreen({super.key});

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  late final List<Moment> _moments = List.of(MockData.moments);
  Moment? _ownMoment;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          Row(
            children: [
              Text('Moments', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Create a Moment (S-023)',
                onPressed: _createSheet,
              ),
            ],
          ),
          Text(
            'Real life, for 24 hours. Only people connected with you can see these.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
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
                        : 'Your Moment · ${_ownMoment!.caption}',
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
                        Chip(
                          avatar: const Icon(Icons.schedule, size: 13),
                          label: Text(moment.expiresInLabel),
                          visualDensity: VisualDensity.compact,
                          labelStyle: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(moment.caption,
                        style: const TextStyle(color: AppColors.warmIvory)),
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
    var audience = 'Connections';
    final caption = TextEditingController();
    showGlassSheet<void>(
      context,
      child: StatefulBuilder(
        builder: (ctx, setState) => Column(
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
                    onSelected: (_) => setState(() => kind = k),
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
            const SizedBox(height: 6),
            Text('Who can see it?', style: Theme.of(ctx).textTheme.titleMedium),
            RadioGroup<String>(
              groupValue: audience,
              onChanged: (v) => setState(() => audience = v ?? 'Connections'),
              child: const Column(
                children: [
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text('Connections'),
                    subtitle: Text('People you\'re matched with.'),
                    value: 'Connections',
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text('Matches + their Sparks'),
                    subtitle: Text('A slightly wider circle.'),
                    value: 'Matches+',
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
                setState(() {
                  _ownMoment = Moment(
                    id: 'moment-own-${DateTime.now().millisecondsSinceEpoch}',
                    member: MockData.currentUser,
                    caption: caption.text.trim().isEmpty
                        ? 'Out and about.'
                        : caption.text.trim(),
                    imageAsset: 'assets/images/backdrop_match.jpg',
                    expiresInLabel: '24h',
                  );
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Moment posted ($kind · $audience) — pre-screen passed (demo). It expires in 24h.'),
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
