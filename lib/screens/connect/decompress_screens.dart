import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/env.dart';
import '../../data/mock_data.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/care.dart';
import '../../models/sync.dart' show rankForMe;
import '../../models/wellbeing.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/copy_text.dart';
import '../../widgets/spark_button.dart';

/// Decompress: a bookable shelf of offline stress-relief experiences, and
/// Phone-Down Mode: the presence ritual for the plan itself.
/// Book the relief → show up → phone down → feel it.

const _commissionRate = 0.12; // proposal: paid by the venue, never the member

IconData _categoryIcon(String c) => switch (c) {
      'Walk' => Icons.directions_walk,
      'Water' => Icons.kayaking,
      'Make' => Icons.palette_outlined,
      'Calm' => Icons.self_improvement,
      'Move' => Icons.hiking,
      'Spa' => Icons.spa_outlined,
      'Café' => Icons.local_cafe_outlined,
      'Sports' => Icons.sports_volleyball_outlined,
      _ => Icons.park_outlined,
    };

String _price(int cents) =>
    cents == 0 ? 'Free' : '\$${(cents / 100).toStringAsFixed(cents % 100 == 0 ? 0 : 2)}';

// ============================================================================
// Decompress shelf
// ============================================================================

/// Opens the booking sheet (also used from chat's "You both" bridge).
Future<void> bookExperience(BuildContext context, Experience e, BookMode mode) async {
  final booked = await showGlassSheet<bool>(
    context,
    child: _BookingSheet(experience: e, initialMode: mode),
  );
  if (booked != true || !context.mounted) return;
  Services.analytics.action('decompress_booked');
  await showGlassSheet<void>(
    context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 44, color: AppColors.sparkCoral),
        const SizedBox(height: 10),
        Text('You\'re booked', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          '${e.title} · ${e.timeLabel}. When you arrive, put your phone down — '
          'Cariño keeps time and you get your Presence Score after.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        SparkButton(
          label: 'Start Phone-Down now',
          icon: Icons.phonelink_lock_outlined,
          onPressed: () {
            Navigator.of(context).pop();
            openPhoneDown(context, planTitle: e.title, durationMin: e.durationMin);
          },
        ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Later')),
      ],
    ),
  );
}

class DecompressScreen extends StatefulWidget {
  const DecompressScreen({super.key});

  @override
  State<DecompressScreen> createState() => _DecompressScreenState();
}

class _DecompressScreenState extends State<DecompressScreen> {
  BookMode _mode = BookMode.solo;
  String? _category;

  /// "How are you, really?" — feeling first; it narrows the shelf gently.
  Mood? _mood;

  Widget _moodCard(TextTheme text) {
    final care = _mood == null ? null : careFor(_mood!);
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How are you, really?', style: text.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in Mood.values)
                ChoiceChip(
                  label: Text('${m.emoji} ${m.label}'),
                  selected: _mood == m,
                  onSelected: (on) => setState(() => _mood = on ? m : null),
                ),
            ],
          ),
          if (care != null) ...[
            const SizedBox(height: 10),
            Text(care.line, style: text.bodyLarge),
            const SizedBox(height: 4),
            Text('One minute for you: ${care.oneMinute}', style: text.bodySmall),
            const SizedBox(height: 8),
            SparkButton(
              label: 'Start my minute',
              icon: Icons.self_improvement,
              secondary: true,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => OneMinuteScreen(step: care.oneMinute))),
            ),
            if (care.showCrisisLine) ...[
              const SizedBox(height: 8),
              Text(
                "If you're thinking about hurting yourself, you're not alone. "
                'Call or text 988 (US) — free, 24/7.',
                style: text.bodySmall,
              ),
              TextButton(
                onPressed: () => launchUrl(Uri.parse('tel:988')),
                child: const Text('Call 988'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _book(Experience e) => bookExperience(context, e, _mode);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final categories = {for (final e in MockData.decompress) e.category}.toList();
    // Private check-ins (never shared) gently reorder the shelf, with a reason.
    final source = _mood == null ? MockData.decompress : moodPicks(_mood!, MockData.decompress);
    final items = rankForMe(
        filterExperiences(source, category: _category, mode: _mode),
        Services.prefs.reflections);
    return GlassScaffold(
      appBar: AppBar(title: const Text('Decompress')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text('Book a reset. Offline, near you.', style: text.headlineSmall),
          const SizedBox(height: 4),
          Text('Go solo, with your circle, as a date — or join a small verified group already going.',
              style: text.bodyMedium),
          const SizedBox(height: 12),
          _moodCard(text),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in BookMode.values)
                ChoiceChip(
                  label: Text(m.label),
                  selected: _mode == m,
                  selectedColor: AppColors.blush,
                  onSelected: (_) => setState(() => _mode = m),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                ),
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(_categoryIcon(c), size: 16),
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = _category == c ? null : c),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            GlassContainer(
              child: Text(
                _mode == BookMode.group
                    ? 'No verified groups going for this filter yet. Try Solo, or start one with Host a plan.'
                    : 'Nothing here right now — try another category.',
                style: text.bodyMedium,
              ),
            ),
          for (final (:e, :why) in [for (final r in items) (e: r.experience, why: r.reason)]) ...[
            GlassContainer(
              onTap: () => _book(e),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.emberCrimson.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_categoryIcon(e.category), color: AppColors.sparkCoral),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (why != null)
                          Text('Picked for you · $why', style: text.labelSmall?.copyWith(color: AppColors.sparkCoral)),
                        Text(e.title, style: text.titleMedium),
                        Text('${e.partner} · ${e.venueType}', style: text.bodySmall),
                        Text('${e.timeLabel} · ${e.durationMin} min', style: text.bodySmall),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _tag(context, _price(e.priceCents), Icons.sell_outlined),
                            if (e.groupGoing > 0)
                              _tag(context, '${e.groupGoing} verified going', Icons.groups_outlined),
                            if (e.phoneFree) _tag(context, 'Phone-free', Icons.phonelink_erase),
                            if (e.stepFree) _tag(context, 'Step-free', Icons.accessible_forward),
                            if (e.spotsLeft <= 3) _tag(context, '${e.spotsLeft} spots left', Icons.event_seat_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            'Prices are set by the venue — you pay the same price as booking direct. '
            'Cariño earns a commission from the venue.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _tag(BuildContext context, String label, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.glassBorder(Theme.of(context).brightness)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.sparkCoral),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
}

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({required this.experience, required this.initialMode});
  final Experience experience;
  final BookMode initialMode;

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  late BookMode _mode = widget.initialMode;
  late int _people = _defaultPeople(widget.initialMode);

  int _defaultPeople(BookMode m) => switch (m) {
        BookMode.date => 2,
        BookMode.circle => min(3, widget.experience.maxPeople),
        _ => 1,
      };

  @override
  Widget build(BuildContext context) {
    final e = widget.experience;
    final text = Theme.of(context).textTheme;
    final ok = canBook(e, people: _people);
    final q = quoteBooking(priceCents: e.priceCents, people: max(1, _people), commissionRate: _commissionRate);
    final maxP = min(e.maxPeople, e.spotsLeft);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(e.title, style: text.headlineSmall),
        Text('${e.timeLabel} · ${e.durationMin} min · ${e.partner}', style: text.bodySmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in BookMode.values)
              ChoiceChip(
                label: Text(m.label),
                selected: _mode == m,
                selectedColor: AppColors.blush,
                onSelected: (m == BookMode.group && e.groupGoing == 0) || (m != BookMode.solo && m != BookMode.group && e.maxPeople < 2)
                    ? null
                    : (_) => setState(() {
                          _mode = m;
                          _people = min(_defaultPeople(m), maxP);
                        }),
              ),
          ],
        ),
        if (_mode == BookMode.group)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('You\'ll join ${e.groupGoing} verified members going at ${e.timeLabel}. '
                'Group chat opens 2 hours before.', style: text.bodySmall),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: Text('People', style: text.titleMedium)),
            IconButton(
              tooltip: 'Fewer people',
              onPressed: _people > 1 && _mode != BookMode.date ? () => setState(() => _people--) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$_people', style: text.titleMedium),
            IconButton(
              tooltip: 'More people',
              onPressed: _people < maxP && _mode != BookMode.date && _mode != BookMode.solo && _mode != BookMode.group
                  ? () => setState(() => _people++)
                  : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const Divider(),
        Row(
          children: [
            Expanded(child: Text('You pay', style: text.titleMedium)),
            Text(_price(q.memberPaysCents), style: text.titleLarge),
          ],
        ),
        Text('The venue\'s own price — no Cariño fee added.', style: text.bodySmall),
        const SizedBox(height: 14),
        SparkButton(
          label: ok ? (e.priceCents == 0 ? 'Reserve my spot' : 'Book for ${_price(q.memberPaysCents)}') : 'Not enough spots',
          icon: Icons.event_available_outlined,
          onPressed: ok
              ? () {
                  Services.prefs.bookings.add('${e.title} · ${e.timeLabel} · ${_mode.label} · $_people');
                  Services.prefs.myPlans.add('${e.title} · ${e.timeLabel} · ${_mode.label}');
                  Navigator.of(context).pop(true);
                }
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          Env.useMockBackend
              ? 'Demo: reserved without payment. In the live app you pay ${e.partner} directly'
              : 'You pay ${e.partner} directly, securely',
          style: text.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ============================================================================
// Phone-Down Mode
// ============================================================================

/// Asks the OS whether the screen is on (Android PowerManager). On iOS the
/// channel isn't implemented, so leaving the app counts as screen-off — the
/// session says so honestly.
class _PresenceChannel {
  static const _ch = MethodChannel('carino/presence');
  static Future<bool?> isInteractive() async {
    try {
      return await _ch.invokeMethod<bool>('isInteractive');
    } catch (_) {
      return null;
    }
  }
}

void openPhoneDown(BuildContext context, {required String planTitle, int durationMin = 90}) {
  Services.analytics.action('phone_down_started');
  Navigator.of(context).push(MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => PhoneDownScreen(planTitle: planTitle, plannedMinutes: durationMin),
  ));
}

class PhoneDownScreen extends StatefulWidget {
  const PhoneDownScreen({super.key, required this.planTitle, this.plannedMinutes = 90});
  final String planTitle;
  final int plannedMinutes;

  @override
  State<PhoneDownScreen> createState() => _PhoneDownScreenState();
}

class _PhoneDownScreenState extends State<PhoneDownScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final PresenceSession _session = PresenceSession(startedAt: DateTime.now());
  late final AnimationController _breath =
      AnimationController(vsync: this, duration: const Duration(seconds: 6));
  Timer? _tick;
  PresenceResult? _result;
  bool? _distinguishes; // null until known: can this phone tell lock vs app switch?

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _result == null) setState(() {});
    });
    _PresenceChannel.isInteractive().then((v) {
      if (mounted) setState(() => _distinguishes = v != null);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    _breath.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_result != null) return;
    final now = DateTime.now();
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (_session.isAway) return;
      _PresenceChannel.isInteractive().then((interactive) {
        // Screen still on after we left = another app was opened.
        _session.away(now, screenOff: interactive != true);
      });
    } else if (state == AppLifecycleState.resumed) {
      _session.back(now);
    }
  }

  void _end() {
    setState(() => _result = _session.end(DateTime.now()));
    _tick?.cancel();
    _breath.stop();
    Services.analytics.action('phone_down_finished');
  }

  Future<bool> _confirmEnd() async {
    final end = await showGlassSheet<bool>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('End Phone-Down?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('You\'ll see your Presence Score for this plan.'),
          const SizedBox(height: 12),
          SparkButton(label: 'End and see my score', onPressed: () => Navigator.of(context).pop(true)),
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep going')),
        ],
      ),
    );
    return end == true;
  }

  String _clock(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}' : '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return PopScope(
      canPop: r != null,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmEnd()) _end();
      },
      child: Scaffold(
        backgroundColor: AppColors.midnight,
        body: SafeArea(child: r == null ? _running(context) : _summary(context, r)),
      ),
    );
  }

  Widget _running(BuildContext context) {
    final elapsed = DateTime.now().difference(_session.startedAt);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Phone-Down', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.softRose)),
          Text(widget.planTitle, textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.warmIvory)),
          const Spacer(),
          Center(
            child: AnimatedBuilder(
              animation: _breath,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(_breath.value);
                return Container(
                  width: 200 + 30 * t,
                  height: 200 + 30 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.emberCrimson.withValues(alpha: 0.55 + 0.25 * t),
                      AppColors.midnight,
                    ]),
                  ),
                  alignment: Alignment.center,
                  child: Text(_clock(elapsed),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.warmIvory, fontFeatures: const [FontFeature.tabularFigures()])),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text('Put your phone face-down. Breathe in as the circle grows.',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.softRose)),
          const Spacer(),
          Text(
            _distinguishes == false
                ? 'On this phone, any time away from Cariño counts as phone-down.'
                : 'Locking your screen counts as present. Opening another app counts as a check-in.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.softRose, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SparkButton(
            label: 'End Phone-Down',
            icon: Icons.stop_circle_outlined,
            secondary: true,
            onPressed: () async {
              if (await _confirmEnd()) _end();
            },
          ),
        ],
      ),
    );
  }

  Widget _summary(BuildContext context, PresenceResult r) {
    final shareText = '${r.label} — ${widget.planTitle}. #Cariño';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          // The screenshot card people post.
          GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: r.score / 100,
                          strokeWidth: 10,
                          color: AppColors.sparkCoral,
                          backgroundColor: AppColors.plumCharcoal,
                        ),
                      ),
                      Text('${r.score}%', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.warmIvory)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(r.label, textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.warmIvory)),
                const SizedBox(height: 4),
                Text(widget.planTitle, style: const TextStyle(color: AppColors.softRose)),
                const SizedBox(height: 8),
                const Text('Presence Score · Cariño', style: TextStyle(color: AppColors.softRose, fontSize: 12)),
              ],
            ),
          ),
          const Spacer(),
          SparkButton(
            label: 'Copy to share',
            icon: Icons.ios_share,
            onPressed: () async {
              if (!await copyText(context, shareText)) return;
              Services.analytics.action('presence_shared');
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied — or screenshot the card.')));
            },
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
        ],
      ),
    );
  }
}


// ============================================================================
// One minute for you — a short, kind reset (no score, no streak)
// ============================================================================

class OneMinuteScreen extends StatefulWidget {
  const OneMinuteScreen({super.key, required this.step});
  final String step;

  @override
  State<OneMinuteScreen> createState() => _OneMinuteScreenState();
}

class _OneMinuteScreenState extends State<OneMinuteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath =
      AnimationController(vsync: this, duration: const Duration(seconds: 4));
  Timer? _tick;
  int _left = 60;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        _breath.stop();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: a still circle, same minute.
    if (!MediaQuery.of(context).disableAnimations && _left > 0 && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final done = _left <= 0;
    return GlassScaffold(
      appBar: AppBar(title: const Text('One minute for you')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _breath,
              builder: (_, __) => Container(
                width: 140 + 80 * _breath.value,
                height: 140 + 80 * _breath.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emberCrimson.withValues(alpha: 0.25 + 0.2 * _breath.value),
                ),
                alignment: Alignment.center,
                child: Text(done ? '✓' : '$_left', style: text.headlineMedium),
              ),
            ),
            const SizedBox(height: 24),
            Text(done ? 'That was a minute just for you.' : widget.step,
                style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(done ? 'Come back any time.' : 'Breathe in as the circle grows, out as it shrinks.',
                style: text.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SparkButton(
              label: done ? 'Done' : 'Finish early',
              secondary: !done,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
