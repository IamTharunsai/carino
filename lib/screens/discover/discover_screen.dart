import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../data/mock_data.dart';
import '../../models/experience.dart';
import '../../models/member.dart';
import '../../services/services.dart';
import '../../services/sound_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/match_celebration.dart';
import '../../widgets/spark_button.dart';
import '../experience/experience_screens.dart';
import '../you/notifications_screen.dart';
import 'filters_screen.dart';
import 'profile_detail_screen.dart';
import 'worldwide_screen.dart';

/// S-015 Discover Feed + S-016 Daily Drop + S-017 Filters (lite).
///
/// Card mechanics per ANIMATION sheet: drag follows the finger; Like shows a
/// coral glow edge, Pass fades/slides; release past threshold commits with a
/// 280ms spring; below threshold springs back. Undo Pass gets a snackbar
/// with a countdown. Match = S-020 celebration overlay (full-screen modal).
///
/// Location honesty: cards show broad distance BANDS, never exact location.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  SoundService get _sound => Services.sound;
  late List<Member> _deck;
  Member? _lastPassed;
  FiltersConfig _filters = const FiltersConfig();
  Intention? get _filter => _filters.intention;
  bool _showDrop = false;
  Offset _drag = Offset.zero;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _deck = List.of(MockData.members);
  }

  List<Member> get _visibleDeck {
    // Reciprocal "I want to meet" applies to the Drop and the deck alike.
    if (_showDrop) return MockData.dailyDrop.where(fitsMe).toList();
    return _deck.where((m) {
      if (!fitsMe(m)) return false;
      if (_filter != null && m.intention != _filter) return false;
      if (m.age < _filters.ageMin || m.age > _filters.ageMax) return false;
      if (_filters.language != null &&
          !m.languages.contains(_filters.language)) {
        return false;
      }
      final miles =
          double.tryParse(RegExp(r'[0-9.]+').firstMatch(m.distanceBand)?.group(0) ?? '');
      if (miles != null && miles > _filters.maxDistanceMi) return false;
      return true;
    }).toList();
  }

  /// S-016: the next drop lands at 18:00 local — computed from the real
  /// clock. Before launch the server owns this schedule; the client never
  /// invents a countdown (blueprint timer rule).
  String get _dropCountdown {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, 18);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    final d = next.difference(now);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? 'Next drop in ${h}h ${m}m' : 'Next drop in ${m}m';
  }

  Future<void> _likeOptions(Member member) async {
    final choice = await showLikeOptions(context, member);
    if (choice == null || !mounted) return;
    if (choice.kind == LikeKind.gift) {
      final gift = await showGlassSheet<String>(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pick a gift for ${member.firstName}',
                style: Theme.of(context).textTheme.titleLarge),
            for (final g in MockData.gifts)
              ListTile(
                leading: Text(g.emoji, style: const TextStyle(fontSize: 26)),
                title: Text(g.name),
                subtitle: Text(g.priceLabel),
                onTap: () => Navigator.of(context).pop(g.name),
              ),
          ],
        ),
      );
      if (gift == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$gift sent with your like (demo — no charge).')));
    }
    _commit(like: true, spark: choice.kind == LikeKind.spark, note: choice.note);
  }

  void _commit({required bool like, bool spark = false, String? note}) {
    final deck = _visibleDeck;
    if (deck.isEmpty) return;
    final member = deck.first;
    _sound.tapHaptic();
    Services.analytics.action(like ? (spark ? 'spark' : (note != null ? 'like_note' : 'like')) : 'pass');
    setState(() {
      _deck.remove(member);
      _drag = Offset.zero;
      _dragging = false;
      _lastPassed = like ? null : member;
    });
    if (like) {
      // Cinematic beat: hearts (or Spark flames) bloom, THEN the match.
      showHeartBurst(context, spark: spark);
      // Scaffold rule: every like on the demo deck celebrates so the flow is
      // visible. PRODUCTION: BackendService returns a match ONLY on a real
      // mutual like — never fake a match (AI honesty rules).
      Future<void>.delayed(const Duration(milliseconds: 750), () {
        if (mounted) _showMatch(member);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passed'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setState(() {
                if (_lastPassed != null) _deck.insert(0, _lastPassed!);
                _lastPassed = null;
              });
            },
          ),
        ),
      );
    }
  }

  void _showMatch(Member member) {
    _sound.matchChime();
    _sound.gentleHaptic();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => MatchCelebrationOverlay(
          member: member,
          onClose: () => Navigator.of(context).pop(),
          onMessage: () => Navigator.of(context).pop(),
          onSuggestPlan: () => Navigator.of(context).pop(),
          onPlayGame: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deck = _visibleDeck;
    return GlassScaffold(
      backgroundAsset: AppConfig.assetBackdropDiscover,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(_showDrop ? 'Daily Drop' : 'Dates',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                IconButton(
                  icon: const Icon(Icons.public),
                  tooltip: 'Worldwide',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const WorldwideScreen()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifications',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const NotificationsScreen()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: 'Filters',
                  onPressed: _openFilters,
                ),
              ],
            ),
          ),
          // Drop vs everyone nearby: its own row so nothing truncates.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  avatar: const Icon(Icons.explore_outlined, size: 16),
                  label: const Text('Nearby'),
                  selected: !_showDrop,
                  selectedColor: AppColors.emberCrimson,
                  onSelected: (_) => setState(() => _showDrop = false),
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.local_fire_department_outlined, size: 16),
                  label: Text('Daily Drop · ${MockData.dailyDrop.where(fitsMe).length}'),
                  selected: _showDrop,
                  selectedColor: AppColors.emberCrimson,
                  onSelected: (_) => setState(() => _showDrop = true),
                ),
              ],
            ),
          ),
          if (_showDrop) ...[
            // A2 Discover backdrop band (imagery set) heads the Drop.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  AppConfig.assetBackdropDiscover,
                  height: 54,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'A small set, chosen for fit — when it\'s gone, it\'s gone. The count is real.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Chip(
                    avatar: const Icon(Icons.schedule, size: 14),
                    label: Text(_dropCountdown),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: deck.isEmpty ? _emptyState(context) : _deckStack(context, deck),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters() async {
    final result = await Navigator.of(context).push<FiltersConfig>(
      MaterialPageRoute<FiltersConfig>(
        builder: (_) => FiltersScreen(initial: _filters),
      ),
    );
    if (result != null && mounted) {
      setState(() => _filters = result);
    }
  }

  Widget _emptyState(BuildContext context) {
    // S-059 state kit: true reason + next action, never a dead end.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_empty_outlined, size: 36),
              const SizedBox(height: 12),
              Text(
                  _showDrop
                      ? 'Drop complete — you\'ve seen today\'s set.'
                      : 'You\'ve seen everyone nearby for now.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(
                _showDrop
                    ? '$_dropCountdown. Regular Discover stays open meanwhile.'
                    : 'New people arrive daily — the Drop lands at 18:00. Widening your filters also helps.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              SparkButton(
                label: 'Reset demo deck',
                secondary: true,
                onPressed: () => setState(() {
                  _deck = List.of(MockData.members);
                  _showDrop = false;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deckStack(BuildContext context, List<Member> deck) {
    final top = deck.first;
    final progress = _drag.dx / 140; // -1 .. 1
    final likeGlow = progress.clamp(0, 1).toDouble();
    final passFade = (-progress).clamp(0, 1).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      child: Stack(
        children: [
          if (deck.length > 1)
            Positioned.fill(
              child: Transform.scale(
                scale: 0.96,
                child: _MemberCard(member: deck[1], interactive: false),
              ),
            ),
          Positioned.fill(
            child: GestureDetector(
              onPanStart: (_) => setState(() => _dragging = true),
              onPanUpdate: (d) => setState(() => _drag += d.delta),
              onPanEnd: (_) {
                if (_drag.dx > 110) {
                  _commit(like: true);
                } else if (_drag.dx < -110) {
                  _commit(like: false);
                } else {
                  setState(() {
                    _drag = Offset.zero;
                    _dragging = false;
                  });
                }
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: _dragging ? 0 : 280),
                curve: Curves.easeOutBack,
                transform: Matrix4.identity()
                  ..translateByDouble(_drag.dx, _drag.dy * 0.4, 0, 1)
                  ..rotateZ(_drag.dx / 900),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _MemberCard(
                      member: top,
                      interactive: true,
                      onReactPrompt: () => _commit(like: true),
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProfileDetailScreen(member: top),
                        ),
                      ),
                      onLike: () => _commit(like: true),
                      onLikeOptions: () => _likeOptions(top),
                      onPass: () => _commit(like: false),
                    ),
                    if (likeGlow > 0.05)
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.sparkCoral.withValues(alpha: likeGlow),
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    if (passFade > 0.05)
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.black.withValues(alpha: passFade * 0.35),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The viewer's own identity: what they set in About You, else the sample
/// profile's defaults (demo).
List<String> get myGender => Services.prefs.gender.isNotEmpty
    ? Services.prefs.gender
    : MockData.currentUser.gender;
List<String> get myWantToMeet => Services.prefs.wantToMeet.isNotEmpty
    ? Services.prefs.wantToMeet
    : MockData.currentUser.wantToMeet;

/// Reciprocal fit: both people want to meet each other.
bool fitsMe(Member m) => mutualFit(
      myWant: myWantToMeet,
      myGender: myGender,
      theirWant: m.wantToMeet,
      theirGender: m.gender,
    );

/// "Why you're seeing them": REAL taste overlaps first, then shared
/// interests. Returns null when there is nothing true to say.
String? whySuggested(Member member) {
  final mine = Services.prefs.tastesOrSample;
  final tastes = sharedTastes(mine, member.tasteAnswers);
  if (tastes.isNotEmpty) return 'You both picked ${tastes.take(2).join(' · ')}';
  final shared = member.interests
      .where(MockData.currentUser.interests.toSet().contains)
      .toList();
  if (shared.isNotEmpty) return 'You both like ${shared.take(2).join(' · ')}';
  return null;
}

/// The big glass Discover card: video-first media, intention chip, prompts.
class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.interactive,
    this.onOpen,
    this.onLike,
    this.onPass,
    this.onReactPrompt,
    this.onLikeOptions,
  });

  final Member member;
  final bool interactive;

  /// Long-press Like: note, gift or Spark.
  final VoidCallback? onLikeOptions;
  final VoidCallback? onOpen;
  final VoidCallback? onLike;
  final VoidCallback? onPass;

  /// S-015: reacting to a specific prompt = a like ANCHORED to that prompt
  /// (BackendService.recordLike anchorType 'prompt'); the conversation
  /// can then open on what you reacted to (S-032B).
  final VoidCallback? onReactPrompt;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(member.photoAsset, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xB3151014)],
                begin: Alignment.center,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Video-intro affordance — tap-to-play, NEVER autoplay with sound.
          if (member.hasVideoIntro)
            const Positioned(
              top: 14,
              right: 14,
              child: GlassContainer(
                radius: 999,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_fill, size: 16, color: AppColors.warmIvory),
                    SizedBox(width: 4),
                    Text('Video intro · 0:24',
                        style: TextStyle(color: AppColors.warmIvory, fontSize: 12)),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: '${member.firstName}, ${member.age}',
                            children: [
                              if (member.pronouns.isNotEmpty &&
                                  member.shows('pronouns', matched: false))
                                TextSpan(
                                  text: '  ${member.pronouns}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.softRose),
                                ),
                            ],
                          ),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.warmIvory,
                              ),
                        ),
                      ),
                      if (member.verified) const VerifiedBadge(),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${member.distanceBand} · ${member.city}',
                    style: const TextStyle(color: AppColors.softRose, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      Chip(
                        label: Text(member.intention.label),
                        backgroundColor: AppColors.emberCrimson,
                        labelStyle: const TextStyle(
                            color: AppColors.warmIvory, fontSize: 12),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                      for (final i in member.interests.take(2))
                        Chip(
                          label: Text(i),
                          labelStyle: const TextStyle(fontSize: 12),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Builder(builder: (context) {
                    // Shared-signal line (S-015): only states REAL overlaps
                    // (taste quiz first, then interests) — never invented.
                    final why = whySuggested(member);
                    if (why == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              size: 13, color: AppColors.sparkCoral),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              why,
                              style: const TextStyle(
                                  color: AppColors.sparkCoral, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '“${member.prompts.first.answer}”',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.warmIvory,
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                      if (interactive)
                        IconButton(
                          icon: const Icon(Icons.favorite_border,
                              size: 18, color: AppColors.sparkCoral),
                          tooltip: 'React to this prompt',
                          visualDensity: VisualDensity.compact,
                          onPressed: onReactPrompt,
                        ),
                    ],
                  ),
                  if (interactive) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GlassIconButton(
                          icon: Icons.close,
                          semanticLabel: 'Pass',
                          onPressed: onPass ?? () {},
                        ),
                        GlassIconButton(
                          icon: Icons.open_in_full,
                          semanticLabel: 'View full profile',
                          onPressed: onOpen ?? () {},
                        ),
                        GlassIconButton(
                          icon: Icons.favorite,
                          semanticLabel: 'Like. Long-press for note, gift or Spark',
                          filled: true,
                          onPressed: onLike ?? () {},
                          onLongPress: onLikeOptions,
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
    );
  }
}
