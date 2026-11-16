import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../config/env.dart';
import '../../data/mock_data.dart';
import '../../models/experience.dart';
import '../../models/member.dart';
import '../../models/plans.dart';
import '../../services/services.dart';
import '../../services/sound_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/match_celebration.dart';
import '../../widgets/plus_nudge.dart';
import '../../widgets/spark_button.dart';
import '../chats/conversation_screen.dart';
import '../chats/games_screen.dart';
import '../connect/plan_composer_screen.dart';
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

  /// Blocked or hidden: never shown in any deck.
  bool _gone(Member m) =>
      Services.prefs.blocked.contains(m.id) || Services.prefs.hiddenPeople.contains(m.id);

  /// Everyone I've liked or passed this session — gone from BOTH decks.
  final Set<String> _swiped = {};
  Offset _drag = Offset.zero;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _deck = List.of(MockData.members);
  }

  List<Member> get _visibleDeck {
    // Reciprocal "I want to meet" applies to the Drop and the deck alike.
    if (_showDrop) {
      return MockData.dailyDrop.where((m) => fitsMe(m) && !_swiped.contains(m.id) && !_gone(m)).toList();
    }
    return _deck.where((m) {
      if (_gone(m)) return false;
      if (!fitsMe(m)) return false;
      if (_filter != null && m.intention != _filter) return false;
      if (m.age < _filters.ageMin || m.age > _filters.ageMax) return false;
      if (_filters.language != null &&
          !m.languages.contains(_filters.language)) {
        return false;
      }
      final miles =
          double.tryParse(RegExp(r'[0-9.]+').firstMatch(m.distanceBand)?.group(0) ?? '');
      final city = _filters.city?.toLowerCase();
      if (city != null) return m.city.toLowerCase().contains(city);
      if (!_filters.worldwideDistance && miles != null && miles > _filters.maxDistanceMi) return false;
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

  bool _leaving = false;

  Future<void> _commit({required bool like, bool spark = false, String? note}) async {
    final deck = _visibleDeck;
    if (deck.isEmpty || _leaving) return;
    if (like && !_allowed(spark)) return;
    final member = deck.first;
    _sound.tapHaptic();
    Services.analytics.action(like ? (spark ? 'spark' : (note != null ? 'like_note' : 'like')) : 'pass');
    // The card flies off the side it was sent to (still under reduced motion,
    // just without the travel).
    final calm = MediaQuery.of(context).disableAnimations;
    setState(() {
      _leaving = true;
      _dragging = false;
      _drag = Offset(like ? 520 : -520, _drag.dy);
    });
    if (!calm) await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    setState(() {
      _deck.remove(member);
      _swiped.add(member.id);
      _drag = Offset.zero;
      _leaving = false;
      _lastPassed = like ? null : member;
    });
    if (like) {
      Services.prefs.liked
        ..remove(member.id)
        ..insert(0, member.id);
      Services.prefs.save();
      showHeartBurst(context, spark: spark);
      // A match ONLY when they already liked you (Likes You). Live: the
      // server decides on a real mutual like — never a fake match.
      final mutual = MockData.likesYou.any((m) => m.id == member.id);
      if (mutual) {
        Future<void>.delayed(const Duration(milliseconds: 750), () {
          if (mounted) _showMatch(member);
        });
      }
      // No pop-up for a plain like: the heart burst says it.
    }
  }

  /// Rewind the last pass (Plus) — a button in the top bar, not a pop-up.
  void _rewind() {
    if (!Services.payments.isPlus) {
      showPlusNudge(context,
          title: 'Rewind with Plus',
          body: 'Passed too fast? Plus brings them back to the top of your deck.');
      return;
    }
    setState(() {
      if (_lastPassed != null) {
        _deck.insert(0, _lastPassed!);
        _swiped.remove(_lastPassed!.id);
      }
      _lastPassed = null;
    });
  }

  /// Swipe up = Super Like (a "Spark"): 1 a day free, 5 with Plus.
  void _superLike(Member m) => _commit(like: true, spark: true);

  /// Free/Plus allowances (models/plans.dart), checked where every like
  /// goes through. Out of likes = the honest moment to mention Plus.
  bool _allowed(bool spark) {
    final now = DateTime.now();
    final plus = Services.payments.isPlus;
    final ok = spark
        ? Services.prefs.useSpark(now, isPlus: plus)
        : Services.prefs.useLike(now, isPlus: plus);
    if (ok) return true;
    setState(() {
      _drag = Offset.zero;
      _dragging = false;
    });
    if (spark) {
      showPlusNudge(context,
          title: 'No Super Likes left today',
          body: 'You get a new one at midnight. Plus gives you $plusSparksPerDay a day, '
              'or get a pack of $superLikePackSize that never expires.',
          extra: SparkButton(
            label: 'Get $superLikePackSize Super Likes · $superLikePackPrice',
            secondary: true,
            onPressed: _buySparkPack,
          ));
    } else {
      showPlusNudge(context,
          title: "That's your $freeLikesPerDay likes for today",
          body: 'New likes at midnight — give the ones you sent a chance. '
              'Or go unlimited with Plus.');
    }
    return false;
  }

  void _buySparkPack() {
    Navigator.of(context).pop(); // the sheet
    final demo = Env.useMockBackend;
    if (demo) Services.prefs.addSparkPack();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(demo
            ? '$superLikePackSize Super Likes added (demo — no charge).'
            : 'Super Like packs are bought through the App Store or Google Play. '
                "They aren't on sale in this build yet — nothing was charged.")));
  }

  /// Full profile; its Pass / Like act on this card.
  Future<void> _openProfile(Member m) async {
    final like = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => ProfileDetailScreen(member: m)),
    );
    if (like != null && mounted) _commit(like: like);
  }

  /// A new match always gets a chat; then go where they tapped.
  void _afterMatch(Widget next) {
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => next));
  }

  void _showMatch(Member member) {
    MockData.chatWith(member);
    _sound.matchChime();
    _sound.gentleHaptic();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => MatchCelebrationOverlay(
          member: member,
          onClose: () => Navigator.of(context).pop(),
          onMessage: () => _afterMatch(ConversationScreen(conversation: MockData.chatWith(member))),
          onSuggestPlan: () => _afterMatch(PlanComposerScreen(member: member)),
          onPlayGame: () => _afterMatch(GamesScreen(member: member)),
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
                if (_lastPassed != null)
                  IconButton(
                    icon: const Icon(Icons.replay),
                    tooltip: 'Rewind last pass',
                    onPressed: _rewind,
                  ),
                IconButton(
                  icon: const Icon(Icons.public),
                  tooltip: 'Worldwide',
                  onPressed: () => Services.payments.isPlus
                      ? Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => const WorldwideScreen()))
                      : showPlusNudge(context,
                          title: 'Travel mode',
                          body: 'Meet verified people in a city before you land. '
                              'Part of Plus.'),
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
                  label: Text('Daily Drop · ${MockData.dailyDrop.where((m) => fitsMe(m) && !_swiped.contains(m.id)).length}'),
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
    final progress = _drag.dx / 110; // -1 .. 1 at the commit threshold
    final likeGlow = progress.clamp(0, 1).toDouble();
    final passFade = (-progress).clamp(0, 1).toDouble();
    final superGlow = (-_drag.dy / 110).clamp(0, 1).toDouble() * (1 - likeGlow - passFade).clamp(0, 1);
    // The card behind grows into place as the top one leaves.
    final lift = (_drag.distance / 110).clamp(0, 1).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      child: Stack(
        children: [
          if (deck.length > 1)
            Positioned.fill(
              child: Transform.scale(
                scale: 0.96 + 0.04 * lift,
                child: _MemberCard(member: deck[1], interactive: false),
              ),
            ),
          Positioned.fill(
            child: GestureDetector(
              onDoubleTap: () => _commit(like: true), // double-tap = like
              onTap: () => _openProfile(top),
              onPanStart: (_) => setState(() => _dragging = true),
              onPanUpdate: (d) => setState(() => _drag += d.delta),
              onPanEnd: (d) {
                // Distance OR a quick flick commits; swipe up = Super Like.
                final v = d.velocity.pixelsPerSecond;
                if (_drag.dx > 110 || (v.dx > 750 && _drag.dx > 30)) {
                  _commit(like: true);
                } else if (_drag.dx < -110 || (v.dx < -750 && _drag.dx < -30)) {
                  _commit(like: false);
                } else if (_drag.dy < -110 || (v.dy < -750 && _drag.dy < -30)) {
                  _superLike(top);
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
                transformAlignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012) // perspective for the 3D tilt
                  ..translateByDouble(_drag.dx, _drag.dy * 0.55, 0, 1)
                  ..rotateZ(_drag.dx * 0.00085)
                  ..rotateY(_drag.dx * 0.00045),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _MemberCard(
                      member: top,
                      interactive: true,
                      onReactPrompt: () => _commit(like: true),
                      onOpen: () => _openProfile(top),
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
                    // LIKE / PASS / SUPER LIKE stamps fade + grow in with the drag.
                    if (likeGlow > 0.05)
                      Positioned(
                        top: 36,
                        left: 24,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: likeGlow,
                            child: Transform.rotate(
                              angle: -0.25,
                              child: Transform.scale(
                                scale: 0.8 + 0.2 * likeGlow,
                                child: const _Stamp(label: 'LIKE', color: AppColors.sparkCoral),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (passFade > 0.05)
                      Positioned(
                        top: 36,
                        right: 24,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: passFade,
                            child: Transform.rotate(
                              angle: 0.25,
                              child: Transform.scale(
                                scale: 0.8 + 0.2 * passFade,
                                child: const _Stamp(label: 'PASS', color: AppColors.warmIvory),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (superGlow > 0.05)
                      Positioned(
                        bottom: 160,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Center(
                            child: Opacity(
                              opacity: superGlow,
                              child: Transform.scale(
                                scale: 0.8 + 0.2 * superGlow,
                                child: const _SuperStamp(),
                              ),
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
      .where(Services.prefs.me.interests.toSet().contains)
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

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        border: Border.all(color: color, width: 3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

/// The Super Like stamp: gradient pill + star + glow — visibly a
/// different, rarer action than a plain LIKE.
class _SuperStamp extends StatelessWidget {
  const _SuperStamp();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.emberCrimson, AppColors.sparkCoral],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.sparkCoral.withValues(alpha: 0.65),
            blurRadius: 22,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 18, color: AppColors.warmIvory),
          SizedBox(width: 6),
          Text(
            'SUPER LIKE',
            style: TextStyle(
              color: AppColors.warmIvory,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
