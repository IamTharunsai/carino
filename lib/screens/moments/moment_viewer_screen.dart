import 'package:flutter/material.dart';
import '../../models/member.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/safety_actions.dart';

/// S-024 Moment Viewer — full-screen, tap zones for prev/next, the
/// poster's controls over their own Moment (viewers list + delete), and
/// Report one tap away on everyone else's. Expiry is shown honestly.
class MomentViewerScreen extends StatefulWidget {
  const MomentViewerScreen({
    super.key,
    required this.moments,
    required this.initialIndex,
    this.isOwn = false,
  });

  final List<Moment> moments;
  final int initialIndex;

  /// True when viewing your OWN moment: shows who viewed + Delete.
  final bool isOwn;

  @override
  State<MomentViewerScreen> createState() => _MomentViewerScreenState();
}

class _MomentViewerScreenState extends State<MomentViewerScreen> {
  late int _index = widget.initialIndex;
  bool _reacted = false;

  /// Sticker answer sent for the current Moment (private, to the poster).
  String? _answered;
  final TextEditingController _askMe = TextEditingController();

  @override
  void dispose() {
    _askMe.dispose();
    super.dispose();
  }

  void _answer(String answer) {
    setState(() => _answered = answer);
    _askMe.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Sent to ${_moment.member.firstName} privately — it opens a chat, never a public comment.'),
      ),
    );
  }

  Widget _sticker(MomentSticker s) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.question,
              style: const TextStyle(
                  color: AppColors.warmIvory, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (widget.isOwn)
            Text(
              s.kind == StickerKind.askMe
                  ? 'Answers arrive in your chats, privately.'
                  : 'Votes arrive in your chats as openers — no public tally.',
              style: const TextStyle(color: AppColors.softRose, fontSize: 12),
            )
          else if (_answered != null)
            Text('You answered: $_answered',
                style: const TextStyle(color: AppColors.sparkCoral))
          else if (s.kind == StickerKind.askMe)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _askMe,
                    style: const TextStyle(color: AppColors.warmIvory),
                    decoration: const InputDecoration(
                      hintText: 'Your answer…',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.sparkCoral),
                  tooltip: 'Send privately',
                  onPressed: () {
                    final t = _askMe.text.trim();
                    if (t.isNotEmpty) _answer(t);
                  },
                ),
              ],
            )
          else
            Row(
              children: [
                for (final o in s.options) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _answer(o),
                      child: Text(o, textAlign: TextAlign.center),
                    ),
                  ),
                  if (o != s.options.last) const SizedBox(width: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Moment get _moment => widget.moments[_index];

  void _next() {
    if (_index < widget.moments.length - 1) {
      setState(() {
        _index++;
        _reacted = false;
        _answered = null;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prev() {
    if (_index > 0) {
      setState(() {
        _index--;
        _reacted = false;
        _answered = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _moment;
    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(m.imageAsset, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x99151014), Colors.transparent, Color(0xB3151014)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Tap zones: left = previous, right = next.
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _prev,
                  behavior: HitTestBehavior.translucent,
                ),
              ),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _next,
                  behavior: HitTestBehavior.translucent,
                ),
              ),
            ],
          ),
          SafeArea(
            child: Column(
              children: [
                // Segment bar — one per moment in this set.
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      for (var i = 0; i < widget.moments.length; i++) ...[
                        Expanded(
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: i <= _index
                                  ? AppColors.warmIvory
                                  : AppColors.warmIvory.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 6, 0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: AssetImage(m.member.photoAsset),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                        widget.isOwn ? 'Your Moment' : m.member.firstName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.warmIvory,
                            fontWeight: FontWeight.w600),
                      ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Chip(
                          avatar: const Icon(Icons.schedule, size: 12),
                          label: Text('Gone in ${m.expiresInLabel}',
                              overflow: TextOverflow.ellipsis),
                          visualDensity: VisualDensity.compact,
                          labelStyle: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const Spacer(),
                      if (!widget.isOwn)
                        IconButton(
                          icon: const Icon(Icons.more_horiz,
                              color: AppColors.warmIvory),
                          tooltip: 'Report or block',
                          onPressed: () => SafetyActions.showForMember(
                            context,
                            member: m.member,
                            surface: 'Moment',
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.warmIvory),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(m.caption,
                          style: const TextStyle(
                              color: AppColors.warmIvory, fontSize: 16)),
                      const SizedBox(height: 12),
                      if (m.sticker != null) ...[
                        _sticker(m.sticker!),
                        const SizedBox(height: 12),
                      ],
                      if (widget.isOwn)
                        GlassContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Viewed by',
                                  style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 4),
                              // Sample viewer data (scaffold) — production
                              // reads the moment_views table (own rows only).
                              const Text('Aria · Sofia · Marcus',
                                  style: TextStyle(color: AppColors.warmIvory)),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () {
                                  final pins = Services.prefs.highlights;
                                  final msg = pins.contains(m.caption)
                                      ? 'Already pinned to your profile.'
                                      : pins.length >= 3
                                          ? 'Highlights hold 3 — unpin one in Edit profile first.'
                                          : 'Pinned to your profile as a Highlight. It\'s re-checked before it shows.';
                                  if (!pins.contains(m.caption) &&
                                      pins.length < 3) {
                                    pins.add(m.caption);
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(msg)));
                                },
                                icon: const Icon(Icons.push_pin_outlined,
                                    size: 18),
                                label: const Text('Pin to profile'),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Moment deleted — it\'s removed for everyone.')),
                                  );
                                },
                                icon: const Icon(Icons.delete_outline, size: 18),
                                label: const Text('Delete this Moment'),
                              ),
                            ],
                          ),
                        )
                      else
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _reacted
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: AppColors.sparkCoral,
                              ),
                              tooltip: 'React',
                              onPressed: () =>
                                  setState(() => _reacted = !_reacted),
                            ),
                            Expanded(
                              child: Text(
                                'Reply… (poster controls replies)',
                                style: TextStyle(
                                    color: AppColors.warmIvory
                                        .withValues(alpha: 0.8)),
                              ),
                            ),
                            const Icon(Icons.send_outlined,
                                color: AppColors.warmIvory),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
