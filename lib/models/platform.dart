// Platform layer (Stage, Trust Graph, Plans engine, Professional wing,
// Money). Pure Dart — rules are tested in test/platform_test.dart.

// ============================================================================
// STAGE — finite, controllable, human-first feed
// ============================================================================

class FeedItem {
  const FeedItem({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.caption,
    required this.topic,
    required this.minutesAgo,
    required this.imageAsset,
    this.durationSec = 15,
    this.aiGenerated = false,
    this.verifiedHuman = true,
    this.fromCircle = false,
    this.viral = false,
    this.planIdea,
  });

  final String id;
  final String creatorId;
  final String creatorName;
  final String caption;
  final String topic; // e.g. 'Food', 'Music', 'Fitness', 'Diet'
  final int minutesAgo;
  final String imageAsset;
  final int durationSec;

  /// AI-generated media is LABELLED, never hidden (unless the viewer turns
  /// on the Human-Made filter).
  final bool aiGenerated;
  final bool verifiedHuman;

  /// Posted by someone in your circles (vs. discovery).
  final bool fromCircle;
  final bool viral;

  /// If set, "Make it a plan" pre-fills this place/activity.
  final String? planIdea;
}

/// What the member asked for, in plain words.
class FeedControls {
  const FeedControls({
    this.moreFriends = false,
    this.lessViral = false,
    this.mutedTopics = const {},
    this.boostedTopics = const {},
    this.minutesBudget,
  });

  final bool moreFriends;
  final bool lessViral;
  final Set<String> mutedTopics;
  final Set<String> boostedTopics;
  final int? minutesBudget;

  bool get isDefault =>
      !moreFriends &&
      !lessViral &&
      mutedTopics.isEmpty &&
      boostedTopics.isEmpty &&
      minutesBudget == null;

  /// Human-readable echo so the member sees exactly what was understood.
  List<String> describe() => [
        if (moreFriends) 'More from your circles',
        if (lessViral) 'Less viral',
        for (final t in boostedTopics) 'More $t',
        for (final t in mutedTopics) 'No $t',
        if (minutesBudget != null) '$minutesBudget min a day',
      ];
}

/// Parses "more friends, less viral, no diet content, more music, 20 min".
/// A transparent rule parser: what it understands is echoed back as chips,
/// so nothing about the feed is a mystery.
FeedControls parseFeedControls(String input, Set<String> knownTopics) {
  final parts = input
      .toLowerCase()
      .split(RegExp(r'[,;.]|\band\b'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty);
  var moreFriends = false, lessViral = false;
  final muted = <String>{}, boosted = <String>{};
  int? minutes;
  String? topicIn(String s) {
    for (final t in knownTopics) {
      if (s.contains(t.toLowerCase())) return t;
    }
    return null;
  }

  for (final p in parts) {
    final m = RegExp(r'(\d+)\s*(min|minutes|m\b)').firstMatch(p);
    if (m != null) {
      minutes = int.parse(m.group(1)!);
      continue;
    }
    if (RegExp(r'friend|circle|people i know').hasMatch(p) &&
        p.contains('more')) {
      moreFriends = true;
      continue;
    }
    if (RegExp(r'viral|trending|popular').hasMatch(p) &&
        RegExp(r'less|no|fewer').hasMatch(p)) {
      lessViral = true;
      continue;
    }
    final t = topicIn(p);
    if (t == null) continue;
    if (RegExp(r'\b(no|less|fewer|hide|without|mute)\b').hasMatch(p)) {
      muted.add(t);
    } else if (RegExp(r'\b(more|lots of|love|show)\b').hasMatch(p)) {
      boosted.add(t);
    }
  }
  return FeedControls(
    moreFriends: moreFriends,
    lessViral: lessViral,
    mutedTopics: muted,
    boostedTopics: boosted,
    minutesBudget: minutes,
  );
}

/// Builds the FINITE feed: filtered, ordered, and capped. The feed ends —
/// either at today's set or when the time budget is spent.
List<FeedItem> buildFeed(
  List<FeedItem> items, {
  required FeedControls controls,
  bool humanOnly = false,
  bool chronological = false,
  int dailyCap = 12,
}) {
  final kept = items.where((i) {
    if (humanOnly && (i.aiGenerated || !i.verifiedHuman)) return false;
    if (controls.mutedTopics.contains(i.topic)) return false;
    return true;
  }).toList();

  double score(FeedItem i) {
    var s = 100 - i.minutesAgo / 60; // fresher first by default
    if (i.fromCircle) s += controls.moreFriends ? 60 : 20;
    if (i.viral) s += controls.lessViral ? -80 : 15;
    if (controls.boostedTopics.contains(i.topic)) s += 40;
    return s;
  }

  if (chronological) {
    kept.sort((a, b) => a.minutesAgo.compareTo(b.minutesAgo));
  } else {
    kept.sort((a, b) => score(b).compareTo(score(a)));
  }

  var cap = dailyCap;
  final budget = controls.minutesBudget;
  if (budget != null) {
    // Budget in seconds of watch time.
    var used = 0, n = 0;
    for (final i in kept) {
      if (used + i.durationSec > budget * 60) break;
      used += i.durationSec;
      n++;
    }
    cap = cap < n ? cap : n;
  }
  return kept.take(cap).toList();
}

/// "Why am I seeing this?" — always a true, specific reason.
String whyThisPost(FeedItem i, FeedControls c) {
  if (i.fromCircle) return 'Someone in your circles posted this';
  if (c.boostedTopics.contains(i.topic)) return 'You asked for more ${i.topic}';
  if (i.viral) return 'Popular in Columbus today';
  return 'Matches your taste: ${i.topic}';
}

// ============================================================================
// TRUST GRAPH — who you've actually met, who vouches for you
// ============================================================================

class TrustGraph {
  TrustGraph({Set<String>? met, Map<String, Set<String>>? metBy})
      : _met = {...?met},
        _metBy = {
          for (final e in (metBy ?? {}).entries) e.key: {...e.value}
        };

  /// People *I* have met in person (both confirmed).
  final Set<String> _met;

  /// For other people: who they have met (used for warm intros). Private
  /// server-side; the client only ever sees "you share a mutual who met
  /// both of you".
  final Map<String, Set<String>> _metBy;

  final Map<String, String> vouches = {}; // voucherId -> short note

  bool hasMet(String id) => _met.contains(id);
  Set<String> get met => Set.unmodifiable(_met);

  /// Met-IRL: both phones confirm the same one-time code.
  bool confirmMeeting(String id,
      {required String myCode, required String theirCode}) {
    if (myCode.isEmpty || myCode != theirCode) return false;
    _met.add(id);
    return true;
  }

  /// Mutuals who have met BOTH me and [target] — the only people who can
  /// make a warm intro.
  List<String> introducersFor(String target) => [
        for (final m in _met)
          if (_metBy[m]?.contains(target) ?? false) m,
      ];

  /// Vouches only count from people you've actually met.
  bool addVouch(String fromId, String note) {
    if (!_met.contains(fromId) || note.trim().isEmpty) return false;
    vouches[fromId] = note.trim();
    return true;
  }
}

// ============================================================================
// PLANS ENGINE — micro-hosts, night planner, splits
// ============================================================================

enum HostTier { newHost, trusted, partner }

/// Good hosts earn reputation, then a revenue share. Reputation comes from
/// private post-plan feedback ("did it happen / comfortable / worthwhile"),
/// never from public star ratings of people.
HostTier hostTier(
    {required int plansHosted, required int positive, required int reports}) {
  if (reports > 0) return HostTier.newHost; // any upheld report resets trust
  final rate = plansHosted == 0 ? 0 : positive / plansHosted;
  if (plansHosted >= 10 && rate >= 0.9) return HostTier.partner;
  if (plansHosted >= 3 && rate >= 0.8) return HostTier.trusted;
  return HostTier.newHost;
}

/// Revenue share for ticketed plans: only Partner hosts, platform keeps the
/// rest. ponytail: flat 70/30; tier it later if hosts ask.
int hostShareCents(int ticketCents, HostTier tier) =>
    tier == HostTier.partner ? (ticketCents * 70) ~/ 100 : 0;

/// Split a cost exactly: amounts sum to [totalCents]; the remainder cents go
/// to the first people so nobody is short-changed by rounding.
List<int> splitCents(int totalCents, int people) {
  if (people <= 0) throw ArgumentError.value(people, 'people', 'must be > 0');
  if (totalCents < 0) throw ArgumentError.value(totalCents, 'totalCents');
  final base = totalCents ~/ people, rem = totalCents % people;
  return [for (var i = 0; i < people; i++) base + (i < rem ? 1 : 0)];
}

String formatCents(int c) =>
    '\$${(c ~/ 100)}.${(c % 100).toString().padLeft(2, '0')}';

/// Session ledger only. A paid mark records the member's own statement;
/// it is never evidence of a transfer or another participant's payment.
class PlanSplit {
  PlanSplit({required this.totalCents, required List<String> participants})
      : participants = List.unmodifiable(participants),
        amounts =
            List.unmodifiable(splitCents(totalCents, participants.length)) {
    if (participants.toSet().length != participants.length) {
      throw ArgumentError('Participants must be unique');
    }
  }
  final int totalCents;
  final List<String> participants;
  final List<int> amounts;
  bool mySharePaid = false;
}

/// Parse dollars without floating-point rounding or silently rounding input.
int? parseCostCents(String input) {
  final value = input.trim();
  if (!RegExp(r'^\d{1,7}(\.\d{1,2})?$').hasMatch(value)) return null;
  final parts = value.split('.');
  return int.parse(parts.first) * 100 +
      (parts.length == 1 ? 0 : int.parse(parts.last.padRight(2, '0')));
}

/// AI Night Planner: suggests a plan when 2+ circle members are free and an
/// idea matches your taste. Returns null if nothing honest to suggest.
class NightPlan {
  const NightPlan(this.friendIds, this.idea, this.timeLabel, this.reason);
  final List<String> friendIds;
  final String idea;
  final String timeLabel;
  final String reason;
}

NightPlan? suggestNightPlan({
  required Map<String, bool> friendFreeTonight,
  required Map<String, String> myTaste,
  required List<(String idea, String tasteKey, String tastePick)> ideas,
}) {
  final free = [
    for (final e in friendFreeTonight.entries)
      if (e.value) e.key
  ];
  if (free.length < 2) return null;
  for (final (idea, key, pick) in ideas) {
    if (myTaste[key] == pick) {
      return NightPlan(free, idea, 'Tonight · 20:00',
          '${free.length} of your circle are free, and you picked "$pick"');
    }
  }
  return NightPlan(free, ideas.first.$1, 'Tonight · 20:00',
      '${free.length} of your circle are free tonight');
}

// ============================================================================
// PROFESSIONAL WING — coffee chats, guilds
// ============================================================================

class WorkFacet {
  const WorkFacet({
    required this.personId,
    required this.role,
    required this.building,
    required this.skills,
    required this.openTo,
  });

  final String personId;
  final String role;
  final String building;
  final List<String> skills;

  /// collabs | mentoring | hiring | coffee
  final Set<String> openTo;
}

/// One curated coffee chat a week: the person whose "open to" and skills
/// overlap yours most (ties -> first). Never someone you've already been
/// matched with this cycle.
WorkFacet? weeklyCoffeeMatch(
    WorkFacet me, List<WorkFacet> pool, Set<String> alreadyMatched) {
  WorkFacet? best;
  var bestScore = 0;
  for (final p in pool) {
    if (p.personId == me.personId || alreadyMatched.contains(p.personId)) {
      continue;
    }
    if (!p.openTo.contains('coffee')) continue;
    final score = p.openTo.intersection(me.openTo).length * 2 +
        p.skills.toSet().intersection(me.skills.toSet()).length;
    if (score > bestScore) {
      best = p;
      bestScore = score;
    }
  }
  return best;
}

class Guild {
  const Guild({
    required this.id,
    required this.name,
    required this.blurb,
    required this.memberCount,
    required this.rooms,
    this.datingOptIn = false,
  });

  final String id;
  final String name;
  final String blurb;
  final int memberCount;
  final List<String> rooms;

  /// Members may opt in to being discoverable for dating via this guild.
  final bool datingOptIn;
}

// ============================================================================
// SMART CHAT — AI catch-up (heuristic fallback)
// ============================================================================

/// "What did I miss?" — a short, factual digest of a busy chat. Fallback
/// for when the AI proxy isn't connected: picks out who spoke, plans and
/// questions. Labelled as a summary; links back to the full thread.
List<String> catchUpSummary(List<(String sender, String text)> messages) {
  if (messages.isEmpty) return const ['Nothing new.'];
  final speakers = <String>{for (final m in messages) m.$1};
  final points = <String>[
    '${messages.length} new messages from ${speakers.join(', ')}.'
  ];
  for (final (s, t) in messages) {
    final l = t.toLowerCase();
    if (RegExp(
            r'\b(mon|tues|wednes|thurs|fri|satur|sun)day\b|tonight|tomorrow|weekend')
        .hasMatch(l)) {
      points.add('$s talked timing: “$t”');
    } else if (t.trim().endsWith('?')) {
      points.add('$s asked: “$t”');
    }
  }
  return points.take(4).toList();
}

// ============================================================================
// MONEY — gifts
// ============================================================================

class Gift {
  const Gift(this.id, this.emoji, this.name, this.priceLabel);
  final String id;
  final String emoji;
  final String name;

  /// Price comes from the store in production — never hard-coded in the UI.
  final String priceLabel;
}
