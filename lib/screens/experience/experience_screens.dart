import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../config/env.dart';
import '../../data/mock_data.dart';
import '../../models/member.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';
import '../../widgets/copy_text.dart';
import '../you/paywall_screen.dart';

/// Experience upgrade (Nov 14): cinematic like burst, like-with-a-note /
/// gift / Spark, Honest Status + Couples mode (calendar, memories,
/// bookings), referrals & promo codes, and "Your activity" insights.

// ============================================================================
// Heart burst — the cinematic like moment
// ============================================================================

/// Hearts bloom from [origin] and float up, ~900ms. With reduced motion /
/// Calm mode on, a single heart fades in and out instead.
void showHeartBurst(BuildContext context, {Offset? origin, bool spark = false}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  final size = MediaQuery.of(context).size;
  final calm = MediaQuery.of(context).disableAnimations;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _HeartBurst(
      origin: origin ?? Offset(size.width / 2, size.height * 0.62),
      spark: spark,
      calm: calm,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
  HapticFeedback.mediumImpact();
}

class _HeartBurst extends StatefulWidget {
  const _HeartBurst({
    required this.origin,
    required this.spark,
    required this.calm,
    required this.onDone,
  });

  final Offset origin;
  final bool spark;
  final bool calm;
  final VoidCallback onDone;

  @override
  State<_HeartBurst> createState() => _HeartBurstState();
}

class _HeartBurstState extends State<_HeartBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.calm ? 500 : 950),
  )..forward().whenComplete(widget.onDone);
  final _rand = Random(7);
  late final List<(double angle, double dist, double size)> _particles = [
    for (var i = 0; i < (widget.calm ? 1 : 16); i++)
      (
        -pi / 2 + (_rand.nextDouble() - 0.5) * pi * 1.1,
        90 + _rand.nextDouble() * 140,
        16 + _rand.nextDouble() * 22,
      ),
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_c.value);
          final fade = 1 - Curves.easeIn.transform(_c.value);
          return Stack(
            children: [
              // Soft coral bloom behind the hearts.
              Positioned(
                left: widget.origin.dx - 120,
                top: widget.origin.dy - 120,
                child: Opacity(
                  opacity: (fade * 0.55).clamp(0, 1).toDouble(),
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        (widget.spark ? AppColors.sparkCoral : AppColors.emberCrimson)
                            .withValues(alpha: 0.7),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),
              for (final (a, d, s) in _particles)
                Positioned(
                  left: widget.origin.dx + cos(a) * d * t - s / 2,
                  top: widget.origin.dy + sin(a) * d * t - s / 2 - 40 * t,
                  child: Opacity(
                    opacity: fade.clamp(0, 1).toDouble(),
                    child: Transform.scale(
                      scale: widget.calm ? 1.6 : 0.6 + 0.6 * t,
                      child: Icon(
                        widget.spark ? Icons.local_fire_department : Icons.favorite,
                        size: s,
                        color: widget.spark ? AppColors.sparkCoral : AppColors.emberCrimson,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// Like options — like with a note, a gift, or a Spark
// ============================================================================

enum LikeKind { plain, note, gift, spark }

class LikeChoice {
  const LikeChoice(this.kind, [this.note]);
  final LikeKind kind;
  final String? note;
}

/// Long-press the heart: say why you liked them (the #1 thing that gets a
/// reply), attach a gift, or send a Spark (Super Like, honest daily count).
Future<LikeChoice?> showLikeOptions(BuildContext context, Member m) {
  final note = TextEditingController();
  final prefs = Services.prefs;
  return showGlassSheet<LikeChoice>(
    context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Heart ${m.firstName} 💗', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('A heart with a sweet note gets far more replies.',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        TextField(
          controller: note,
          maxLength: 140,
          decoration: InputDecoration(
            hintText: m.prompts.isEmpty
                ? 'What made you smile about ${m.firstName}?'
                : 'Your “${m.prompts.first.answer}” made me smile because…',
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16))),
          ),
        ),
        SparkButton(
          label: 'Send heart with note',
          icon: Icons.favorite,
          onPressed: () {
            final t = note.text.trim();
            Navigator.of(context).pop(
                t.isEmpty ? const LikeChoice(LikeKind.plain) : LikeChoice(LikeKind.note, t));
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SparkButton(
                label: 'Add a gift',
                icon: Icons.card_giftcard,
                secondary: true,
                onPressed: () => Navigator.of(context).pop(const LikeChoice(LikeKind.gift)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SparkButton(
                label: prefs.sparksLeft(DateTime.now(), isPlus: Services.payments.isPlus) > 0
                    ? 'Spark (${prefs.sparksLeft(DateTime.now(), isPlus: Services.payments.isPlus)} left)'
                    : 'Spark — Plus',
                icon: Icons.local_fire_department,
                secondary: true,
                onPressed: () {
                  if (!prefs.useSpark(DateTime.now(), isPlus: Services.payments.isPlus)) {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const PaywallScreen()));
                    return;
                  }
                  Navigator.of(context).pop(const LikeChoice(LikeKind.spark));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'A crush puts you at the top of their hearts, with your note. '
          '1 free a day; resets at midnight. No fake "only 2 left!" timers.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// ============================================================================
// Honest Status + Couples mode
// ============================================================================

const relationshipStatuses = [
  'Single',
  'Dating',
  'Open relationship',
  'In a relationship',
  'Married',
  'It\'s complicated',
];

/// Statuses where dating discovery pauses automatically.
bool statusPausesDating(String s) => UserPrefs.pausesDating(s);

class CoupleScreen extends StatefulWidget {
  const CoupleScreen({super.key});

  @override
  State<CoupleScreen> createState() => _CoupleScreenState();
}

class _CoupleScreenState extends State<CoupleScreen> {
  final _prefs = Services.prefs;

  void _setStatus(String s) {
    // Honest Status: taken = not discoverable (and restored when not).
    setState(() => _prefs.setRelationshipStatus(s));
    // Event name only — never the status value (privacy rule).
    Services.analytics.action('status_changed');
    if (statusPausesDating(s)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dates paused — you won\'t appear in anyone\'s Discover. Friends and Plans stay on.')));
    }
  }

  Future<void> _link() async {
    final name = TextEditingController();
    final code = TextEditingController();
    final ok = await showGlassSheet<bool>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Link your partner', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Both of you must agree. Share your code; enter theirs. Either '
            'of you can unlink anytime, and nothing from before is shared.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          SelectableText('Your code: CPL-${_prefs.referralCode.substring(7)}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Partner\'s first name')),
          TextField(controller: code, decoration: const InputDecoration(labelText: 'Their code')),
          const SizedBox(height: 12),
          SparkButton(
            label: 'Link',
            icon: Icons.link,
            onPressed: () {
              if (name.text.trim().isEmpty || code.text.trim().length < 6) return;
              _prefs.partnerName = name.text.trim();
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() {
        if (!statusPausesDating(_prefs.relationshipStatus)) {
          _prefs.setRelationshipStatus('In a relationship');
        }
      });
    }
  }

  Future<void> _addCalendar() async {
    final what = TextEditingController();
    var when = 'Fri · 19:30';
    await showGlassSheet<void>(
      context,
      child: StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Plan time together', style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 10),
            TextField(controller: what, decoration: const InputDecoration(labelText: 'What (date night, trip, call…)')),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in ['Tonight · 20:00', 'Fri · 19:30', 'Sat · 11:00', 'Sun · 18:00'])
                  ChoiceChip(
                    label: Text(t),
                    selected: when == t,
                    selectedColor: AppColors.blush,
                    onSelected: (_) => setSheet(() => when = t),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SparkButton(
              label: 'Add to our calendar',
              icon: Icons.event_available_outlined,
              onPressed: () {
                if (what.text.trim().isEmpty) return;
                _prefs.coupleCalendar.add((when, what.text.trim()));
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _addMemory() async {
    final t = TextEditingController();
    await showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Save a memory', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Private to the two of you. Never on any feed.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          TextField(controller: t, maxLines: 3, maxLength: 280),
          SparkButton(
            label: 'Save',
            icon: Icons.bookmark_add_outlined,
            onPressed: () {
              if (t.text.trim().isEmpty) return;
              _prefs.coupleMemories.insert(0, t.text.trim());
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _book(String kind, Uri url) async {
    Services.analytics.action('booking_${kind.toLowerCase()}');
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication)
        .catchError((_) => false);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t open $kind. Check you have a browser installed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final linked = _prefs.partnerName != null;
    final city = Uri.encodeComponent(MockData.currentUser.city);
    return GlassScaffold(
      appBar: AppBar(title: const Text('Relationship & couples')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your status', style: text.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Honest Status: if you\'re taken, Dates pauses so nobody '
                  'is misled. Friends, Feed and Plans stay on.',
                  style: text.bodySmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in relationshipStatuses)
                      ChoiceChip(
                        label: Text(s),
                        selected: _prefs.relationshipStatus == s,
                        selectedColor: AppColors.blush,
                        onSelected: (_) => _setStatus(s),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Who sees it', style: text.bodySmall),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'everyone', label: Text('Everyone')),
                    ButtonSegment(value: 'matches', label: Text('Friends')),
                    ButtonSegment(value: 'hidden', label: Text('Just me')),
                  ],
                  selected: {_prefs.relationshipVisibility},
                  onSelectionChanged: (v) =>
                      setState(() => _prefs.relationshipVisibility = v.first),
                ),
                if (_prefs.relationshipStatus == 'Open relationship') ...[
                  const SizedBox(height: 8),
                  Text(
                    'Open relationships stay discoverable and are labelled on '
                    'your card so everyone knows up front.',
                    style: text.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!linked)
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.favorite, color: AppColors.sparkCoral, size: 32),
                  const SizedBox(height: 8),
                  Text('Couples mode', style: text.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(
                    'A private space for two: a shared calendar, saved '
                    'memories and one-tap bookings for date night.',
                    style: text.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SparkButton(label: 'Link your partner', icon: Icons.link, onPressed: _link),
                ],
              ),
            )
          else ...[
            GlassContainer(
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: AppColors.sparkCoral),
                  const SizedBox(width: 10),
                  Expanded(child: Text('You & ${_prefs.partnerName}', style: text.titleLarge)),
                  TextButton(
                    onPressed: () => setState(_prefs.unlinkPartner),
                    child: const Text('Unlink'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Our calendar', style: text.titleMedium),
            const SizedBox(height: 6),
            for (final (slot, what) in _prefs.coupleCalendar)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined, color: AppColors.sparkCoral),
                title: Text(what),
                subtitle: Text(slot),
              ),
            SparkButton(
              label: 'Plan time together',
              icon: Icons.add,
              secondary: true,
              onPressed: _addCalendar,
            ),
            const SizedBox(height: 16),
            Text('Book date night', style: text.titleMedium),
            const SizedBox(height: 4),
            Text('Opens our booking partners — you pay them directly.', style: text.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.restaurant, size: 18),
                  label: const Text('Restaurant'),
                  onPressed: () => _book('Restaurant',
                      Uri.parse('https://www.opentable.com/s?term=$city')),
                ),
                ActionChip(
                  avatar: const Icon(Icons.hotel_outlined, size: 18),
                  label: const Text('Hotel'),
                  onPressed: () => _book('Hotel',
                      Uri.parse('https://www.booking.com/searchresults.html?ss=$city')),
                ),
                ActionChip(
                  avatar: const Icon(Icons.local_taxi_outlined, size: 18),
                  label: const Text('Ride'),
                  onPressed: () => _book('Ride', Uri.parse('https://m.uber.com/looking')),
                ),
                ActionChip(
                  avatar: const Icon(Icons.directions_walk, size: 18),
                  label: const Text('Walk'),
                  onPressed: () => _book('Walk',
                      Uri.parse('https://www.google.com/maps/search/parks+near+$city')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text('Memories', style: text.titleMedium)),
                TextButton.icon(
                  onPressed: _addMemory,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Save one'),
                ),
              ],
            ),
            if (_prefs.coupleMemories.isEmpty)
              Text('Your first one is waiting to happen.', style: text.bodySmall),
            for (final m in _prefs.coupleMemories)
              GlassContainer(
                padding: const EdgeInsets.all(12),
                child: Text(m),
              ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// Referrals & promo codes (ethical: real rewards, plain terms)
// ============================================================================

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _promo = TextEditingController();
  String? _promoResult;

  @override
  void dispose() {
    _promo.dispose();
    super.dispose();
  }

  void _redeem() {
    final c = _promo.text.trim().toUpperCase();
    // Demo codes; production validates server-side (one use per account).
    final offers = {'FOUNDING': 'Founding member: first month of Plus at the founding price.',
        'COLUMBUS': 'Columbus launch: 1 week of Plus free.'};
    setState(() {
      if (Services.prefs.redeemedPromo != null) {
        _promoResult = 'You\'ve already redeemed ${Services.prefs.redeemedPromo}.';
      } else if (offers.containsKey(c)) {
        Services.prefs.redeemedPromo = c;
        _promoResult = offers[c];
        Services.analytics.action('promo_redeemed');
      } else {
        _promoResult = 'That code isn\'t valid. Check the spelling, or it may have expired.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final code = Services.prefs.referralCode;
    return GlassScaffold(
      appBar: AppBar(title: const Text('Invite & offers')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.card_giftcard, size: 36, color: AppColors.sparkCoral),
                const SizedBox(height: 8),
                Text('Give a week, get a week', style: text.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(
                  'When a friend joins with your link and passes verification, '
                  'you both get 1 week of ${AppConfig.plusName} free. Up to 10 weeks a year.',
                  style: text.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Chip(
                    label: Text(code, style: text.titleMedium),
                    avatar: const Icon(Icons.qr_code_2),
                  ),
                ),
                const SizedBox(height: 8),
                SparkButton(
                  label: 'Copy invite link',
                  icon: Icons.link,
                  onPressed: () async {
                    if (!await copyText(context, 'https://carino.app/join/$code')) return;
                    Services.analytics.action('referral_copied');
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied — share it anywhere.')));
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  'Rewards only count for real, verified people — never for fake '
                  'sign-ups. Friends you invite are never told who else you invited.',
                  style: text.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Have a promo code?', style: text.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('promo-code'),
                  controller: _promo,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'e.g. FOUNDING',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _redeem, child: const Text('Apply')),
            ],
          ),
          if (_promoResult != null) ...[
            const SizedBox(height: 8),
            Text(_promoResult!, style: text.bodyMedium),
          ],
          const SizedBox(height: 16),
          Text(
            Env.useMockBackend
                ? 'Demo codes: FOUNDING, COLUMBUS. Real offers are validated by the server and the app store.'
                : 'Offers are validated by the server and applied through the app store.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Your activity — the member's own usage, on device
// ============================================================================

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final a = Services.analytics;
    return GlassScaffold(
      appBar: AppBar(title: const Text('Your activity')),
      body: ListenableBuilder(
        listenable: a,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              'What you use most — counted on this phone. We log event names, '
              'never your messages, photos or who you viewed.',
              style: text.bodySmall,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Share anonymous usage to improve the app'),
              value: a.enabled,
              onChanged: a.setEnabled,
            ),
            for (final (title, map) in [('Screens', a.screens), ('Actions', a.actions)]) ...[
              const SizedBox(height: 8),
              Text(title, style: text.titleMedium),
              const SizedBox(height: 6),
              if (map.isEmpty)
                Text('Nothing yet — use the app a little and come back.', style: text.bodySmall),
              for (final e in a.top(map))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(width: 120, child: Text(e.key, overflow: TextOverflow.ellipsis)),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: e.value / (a.top(map).first.value),
                          color: AppColors.emberCrimson,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${e.value}'),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 12),
            TextButton(
                onPressed: () {
                  a.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Your activity on this phone is cleared.')));
                },
                child: const Text('Clear my activity')),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Chat themes & stickers
// ============================================================================

/// Per-chat look: the colour of YOUR bubbles + a soft glow. Brand-derived.
const chatThemes = <(String, Color)>[
  ('Ember', AppColors.emberCrimson),
  ('Coral sunset', Color(0xFFE0554F)),
  ('Midnight plum', Color(0xFF5B2A55)),
  ('Rose gold', Color(0xFFB76E6E)),
  ('Deep teal', Color(0xFF1F5F63)),
  ('Lavender', Color(0xFF7A5FB0)),
  ('Ocean', Color(0xFF2E6FB0)),
  ('Forest', Color(0xFF2F7A4E)),
];

/// Chat wallpapers: soft gradients, or your own photo ('photo').
const chatWallpapers = <String, List<Color>>{
  'Blush': [Color(0xFF3A1C2B), Color(0xFF7A3048)],
  'Sunset': [Color(0xFF41204A), Color(0xFFB3523E)],
  'Night sky': [Color(0xFF0D1330), Color(0xFF2B2F6B)],
  'Lagoon': [Color(0xFF0E3B3F), Color(0xFF1F7A72)],
  'Peach': [Color(0xFFF6D5C4), Color(0xFFE79A8A)],
};

/// Stickers are message CONTENT (big emoji), never UI icons.
const stickerPacks = <String, List<String>>{
  'Flirty': ['😍', '😘', '🥰', '😏', '💋', '🔥', '❤️‍🔥', '💘'],
  'Fun': ['😂', '🤪', '🙈', '🎉', '🍕', '🎲', '🎤', '🕺'],
  'Plans': ['☕', '🍷', '🍜', '🎬', '🌅', '🚲', '🎟️', '🏖️'],
};

/// Returns a bubble colour index (int), a wallpaper name, 'photo' for your
/// own picture, or 'none' — or null if closed.
Future<Object?> showChatThemeSheet(BuildContext context, int current) {
  return showGlassSheet<Object>(
    context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Chat theme', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('Only changes how this chat looks for you.',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < chatThemes.length; i++)
              Semantics(
                button: true,
                selected: i == current,
                label: '${chatThemes[i].$1} theme',
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(i),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: chatThemes[i].$2,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: i == current ? AppColors.warmIvory : Colors.transparent,
                              width: 3),
                        ),
                        child: i == current
                            ? const Icon(Icons.check, color: AppColors.warmIvory)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(chatThemes[i].$1, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Wallpaper', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final e in chatWallpapers.entries)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(e.key),
              child: Column(children: [
                Container(
                  width: 56,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(colors: e.value, begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  ),
                ),
                Text(e.key, style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ActionChip(avatar: const Icon(Icons.photo_outlined), label: const Text('My photo'),
              onPressed: () => Navigator.of(context).pop('photo')),
          ActionChip(label: const Text('None'), onPressed: () => Navigator.of(context).pop('none')),
        ]),
      ],
    ),
  );
}

Future<String?> showStickerTray(BuildContext context) {
  return showGlassSheet<String>(
    context,
    child: DefaultTabController(
      length: stickerPacks.length,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(tabs: [for (final k in stickerPacks.keys) Tab(text: k)]),
          SizedBox(
            height: 180,
            child: TabBarView(
              children: [
                for (final pack in stickerPacks.values)
                  GridView.count(
                    crossAxisCount: 4,
                    padding: const EdgeInsets.only(top: 12),
                    children: [
                      for (final st in pack)
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).pop(st),
                          child: Center(child: Text(st, style: const TextStyle(fontSize: 36))),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
