import 'member.dart';

/// Pure logic + display models for the experience bundle (Bundle v1):
/// taste quiz, events, Spark Nights, chemistry streaks, reciprocal
/// "I want to meet" matching and Scam Shield. No Flutter imports, so
/// every rule here is unit-tested in test/experience_test.dart.

// --- Identity options (S-008A) ----------------------------------------------

const List<String> genderOptions = [
  'Woman', 'Man', 'Non-binary', 'Trans woman', 'Trans man', 'Genderqueer',
  'Genderfluid', 'Agender', 'Two-Spirit',
];
const List<String> pronounOptions = [
  'she/her', 'he/him', 'they/them', 'she/they', 'he/they', 'any pronouns',
];
const List<String> orientationOptions = [
  'Straight', 'Gay', 'Lesbian', 'Bisexual', 'Pansexual', 'Queer', 'Asexual',
  'Demisexual', 'Questioning',
];

/// Who you want to meet. Broad buckets so trans and non-binary people are
/// included by default rather than as an afterthought.
const List<String> wantToMeetOptions = ['Women', 'Men', 'Non-binary people'];

/// Reciprocal "I want to meet" check. Empty [want] = open to everyone.
/// Trans women count as women and trans men as men; every other identity
/// outside Woman/Man maps to the non-binary bucket.
bool wantsToMeet(List<String> want, List<String> theirGender) {
  if (want.isEmpty || theirGender.isEmpty) return true;
  for (final g in theirGender) {
    final bucket = switch (g) {
      'Woman' || 'Trans woman' => 'Women',
      'Man' || 'Trans man' => 'Men',
      _ => 'Non-binary people',
    };
    if (want.contains(bucket)) return true;
  }
  return false;
}

/// Both people must want to meet each other (Discover never shows one-way).
bool mutualFit({
  required List<String> myWant,
  required List<String> myGender,
  required List<String> theirWant,
  required List<String> theirGender,
}) =>
    wantsToMeet(myWant, theirGender) && wantsToMeet(theirWant, myGender);

// --- Taste Quiz ---------------------------------------------------------------

class TasteQuestion {
  const TasteQuestion(this.id, this.prompt, this.a, this.b);
  final String id;
  final String prompt;
  final String a;
  final String b;
}

const List<TasteQuestion> tasteQuiz = [
  TasteQuestion('t1', 'Perfect Saturday?', 'Sunrise hike', 'Slow brunch'),
  TasteQuestion('t2', 'Late night?', 'Midnight pancakes', 'In bed by 11'),
  TasteQuestion('t3', 'First date energy?', 'Coffee and a walk', 'Something active'),
  TasteQuestion('t4', 'Music at a party?', 'Aux cord, always', 'Whatever\'s on'),
  TasteQuestion('t5', 'Travel style?', 'Planned to the minute', 'Book the flight, figure it out'),
  TasteQuestion('t6', 'Texting?', 'Voice notes', 'Short texts'),
  TasteQuestion('t7', 'Sunday reset?', 'Farmers market', 'Couch + a series'),
  TasteQuestion('t8', 'Group or one-on-one?', 'Big group energy', 'Just us'),
];

/// Real overlaps only: the "Why you're seeing them" line never invents one.
List<String> sharedTastes(Map<String, String> mine, Map<String, String> theirs) {
  return [
    for (final q in tasteQuiz)
      if (mine[q.id] != null && mine[q.id] == theirs[q.id]) mine[q.id]!,
  ];
}

// --- Events Near You ------------------------------------------------------------

class LocalEvent {
  const LocalEvent({
    required this.id,
    required this.title,
    required this.venueType,
    required this.timeLabel,
    required this.category,
    this.stepFree = false,
    this.goingMatchIds = const [],
  });

  final String id;
  final String title;

  /// Public venue TYPE (never a private address).
  final String venueType;
  final String timeLabel;
  final String category;
  final bool stepFree;

  /// Matches who said "I'm going" — visible to matches only, never strangers.
  final List<String> goingMatchIds;
}

// --- Spark Nights --------------------------------------------------------------

class SparkNight {
  const SparkNight({
    required this.id,
    required this.theme,
    required this.timeLabel,
    required this.blurb,
    this.ageBand,
  });

  final String id;
  final String theme;
  final String timeLabel;
  final String blurb;
  final String? ageBand;
}

// --- Chemistry Streak (forgiving by design) -------------------------------------

/// A streak is a reward, not a hook: one free freeze per week, a missed day
/// spends the freeze silently, and there is never a "your streak is dying"
/// message. A confirmed date ends the streak happily ([completedByDate]).
class ChemistryStreak {
  const ChemistryStreak({
    required this.days,
    this.freezeAvailable = true,
    this.completedByDate = false,
  });

  final int days;
  final bool freezeAvailable;
  final bool completedByDate;

  /// Advance one calendar day. [active] = either of you played, sent a voice
  /// note, or made a plan that day.
  ChemistryStreak nextDay({required bool active}) {
    if (completedByDate) return this;
    if (active) {
      return ChemistryStreak(days: days + 1, freezeAvailable: freezeAvailable);
    }
    if (freezeAvailable) {
      return ChemistryStreak(days: days, freezeAvailable: false);
    }
    return const ChemistryStreak(days: 0);
  }

  /// Called on the weekly reset: the freeze comes back.
  ChemistryStreak weeklyReset() => ChemistryStreak(
      days: days, freezeAvailable: true, completedByDate: completedByDate);

  ChemistryStreak markDate() =>
      ChemistryStreak(days: days, freezeAvailable: freezeAvailable, completedByDate: true);
}

// --- Profile Aura ----------------------------------------------------------------

/// Effort, never attractiveness: each item is something the member did.
List<(String, bool)> auraChecklist(Member me) => [
      ('Verified', me.verified),
      ('Video intro', me.hasVideoIntro),
      ('3+ photos', me.gallery.length >= 3),
      ('3 prompts', me.prompts.length >= 3),
      ('Voice intro', me.hasVoiceIntro),
      ('Boundaries stated', me.boundaries.isNotEmpty),
    ];

double auraStrength(Member me) {
  final items = auraChecklist(me);
  return items.where((i) => i.$2).length / items.length;
}

// --- Scam Shield ----------------------------------------------------------------

/// Signals (AI-04 spirit), never a verdict: a match is a reason to show a
/// calm safety card to BOTH people — not an accusation, not a ban.
/// ponytail: keyword heuristic on-device; the server-side AI-04 model
/// replaces it for scoring, this stays as the instant offline fallback.
enum ScamSignal { money, crypto, giftCards, offApp }

const Map<ScamSignal, List<String>> _scamPatterns = {
  ScamSignal.money: [
    r'\bwire\b', r'\bwestern union\b', r'\bvenmo\b', r'\bcash ?app\b',
    r'\bzelle\b', r'\bpaypal\b', r'\bsend (me )?(some )?money\b',
    r'\blend me\b', r'\bloan\b', r'\bbank (account|details)\b',
    r'\bmedical (bill|emergency)\b',
  ],
  ScamSignal.crypto: [
    r'\bcrypto\b', r'\bbitcoin\b', r'\busdt\b', r'\bethereum\b',
    r'\btrading platform\b', r'\binvest(ment|ing)? (opportunity|platform)\b',
  ],
  ScamSignal.giftCards: [r'\bgift ?cards?\b', r'\bitunes card\b', r'\bsteam card\b'],
  ScamSignal.offApp: [
    r'\bwhats ?app\b', r'\btelegram\b', r'\bsignal me\b',
    r'\bmove (this|to) (chat )?off\b', r'\bmy (instagram|snap|onlyfans)\b',
  ],
};

Set<ScamSignal> scanForScam(String text) {
  final t = text.toLowerCase();
  return {
    for (final e in _scamPatterns.entries)
      if (e.value.any((p) => RegExp(p).hasMatch(t))) e.key,
  };
}

String scamShieldCopy(Set<ScamSignal> signals) {
  if (signals.contains(ScamSignal.money) ||
      signals.contains(ScamSignal.giftCards) ||
      signals.contains(ScamSignal.crypto)) {
    return 'Money came up. Cariño will never ask you for money, and a match '
        'shouldn\'t either: no transfers, gift cards or crypto "opportunities".';
  }
  return 'Moving to another app this fast is a common scam pattern. Your '
      'report and block tools only work here. Take your time.';
}

// --- Close the Loop ----------------------------------------------------------------

/// Kind, one-tap closes offered after [quietDaysThreshold] quiet days.
const int quietDaysThreshold = 5;
const List<String> closeTheLoopTemplates = [
  'I\'ve enjoyed chatting, but I don\'t feel a spark. Wishing you the best!',
  'Life got busy and I don\'t want to leave you hanging. Take care!',
  'I don\'t think we\'re a match, but thanks for the good conversation.',
];
