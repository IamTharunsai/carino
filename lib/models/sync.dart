// Conversation Sync — helping two people fit each other's way of talking.
// Pure Dart, tested in test/sync_test.dart.
//
// Honesty: every chip is a REAL overlap, every rule is the member's own
// choice and visible to both, reflections never leave the member, and the
// AI only ever drafts (the member edits and sends).
import 'experience.dart' show sharedTastes;
import 'wellbeing.dart' show Experience;

// ============================================================================
// 1. "How I text"
// ============================================================================

enum ReplyPace {
  quick('I reply fast', 'usually replies within the hour'),
  evenings('Evenings only', 'usually replies in the evening'),
  slow('Slow but I mean it', 'takes their time — slow, not uninterested');

  const ReplyPace(this.label, this.note);
  final String label;
  final String note;
}

enum MsgLength {
  short('Short and snappy'),
  long('Long messages');

  const MsgLength(this.label);
  final String label;
}

enum VoiceNotes {
  love('Love voice notes'),
  sometimes('Voice notes sometimes'),
  textOnly('Text only, please');

  const VoiceNotes(this.label);
  final String label;
}

enum Humour {
  dry('Dry humour'),
  playful('Playful'),
  wholesome('Wholesome');

  const Humour(this.label);
  final String label;
}

/// Null fields = not answered; nothing is shown for them (never guessed).
class TextingStyle {
  const TextingStyle({
    this.pace,
    this.length,
    this.voice,
    this.humour,
    this.loves = const [],
    this.avoid = const [],
  });

  final ReplyPace? pace;
  final MsgLength? length;
  final VoiceNotes? voice;
  final Humour? humour;

  /// "Topics I love" / "Please don't ask about" — short member-written tags.
  final List<String> loves;
  final List<String> avoid;

  bool get isEmpty =>
      pace == null && length == null && voice == null && humour == null &&
      loves.isEmpty && avoid.isEmpty;

  List<String> get labels => [
        if (pace != null) pace!.label,
        if (length != null) length!.label,
        if (voice != null) voice!.label,
        if (humour != null) humour!.label,
      ];
}

String? paceNote(String firstName, TextingStyle s) =>
    s.pace == null ? null : '$firstName ${s.pace!.note}';

/// Gentle heads-ups where two styles really differ. Empty when they don't.
List<String> styleHints({
  required TextingStyle mine,
  required TextingStyle theirs,
  required String name,
}) {
  final out = <String>[];
  if (mine.pace != null && theirs.pace != null && mine.pace != theirs.pace) {
    out.add(theirs.pace == ReplyPace.quick
        ? '$name replies fast — no pressure to match it.'
        : '$name ${theirs.pace!.note}. A slow reply isn\'t a no.');
  }
  if (theirs.voice == VoiceNotes.love && mine.voice == VoiceNotes.textOnly) {
    out.add('$name loves voice notes; you prefer text. Saying so is fine.');
  } else if (theirs.voice == VoiceNotes.textOnly && mine.voice == VoiceNotes.love) {
    out.add('$name prefers text to voice notes.');
  }
  return out;
}

// ============================================================================
// 2. "You both" — common ground, grounded openers, chat → plan bridge
// ============================================================================

/// Real overlaps only: shared taste answers first, then shared interests
/// (in my order). Anything touching their "please don't ask" list is dropped.
List<String> commonGround({
  required List<String> myInterests,
  required List<String> theirInterests,
  required Map<String, String> myTastes,
  required Map<String, String> theirTastes,
  List<String> theirAvoid = const [],
}) {
  final theirs = {for (final i in theirInterests) i.toLowerCase()};
  final all = [
    ...sharedTastes(myTastes, theirTastes),
    for (final i in myInterests)
      if (theirs.contains(i.toLowerCase())) i,
  ];
  bool avoided(String chip) => theirAvoid.any((a) {
        final x = a.trim().toLowerCase();
        final c = chip.toLowerCase();
        return x.isNotEmpty && (c.contains(x) || x.contains(c));
      });
  return [for (final c in all) if (!avoided(c)) c];
}

/// Opener drafts built from what you really share. Drafts only — the member
/// edits and sends them.
List<String> groundedOpeners(List<String> chips, String name) {
  const templates = [
    'We both like {c} — what\'s the best one you\'ve had lately?',
    'Okay, fellow {c} person: what\'s your go-to spot in town?',
    'Settle this for me, {n}: is {c} better solo or with company?',
  ];
  return [
    for (var i = 0; i < chips.length && i < templates.length; i++)
      templates[i]
          .replaceAll('{c}', chips[i].toLowerCase())
          .replaceAll('{n}', name),
  ];
}

/// Keyword → Decompress shelf category. ponytail: a keyword table, swap for
/// server-side tagging when partner inventory grows past a few categories.
const Map<String, String> _bridge = {
  'walk': 'Walk',
  'farmers market': 'Walk',
  'gallery': 'Walk',
  'coffee': 'Café',
  'café': 'Café',
  'cafe': 'Café',
  'brunch': 'Café',
  'hik': 'Move',
  'trail': 'Move',
  'running': 'Move',
  'ceramic': 'Make',
  'pottery': 'Make',
  'yoga': 'Calm',
  'kayak': 'Water',
  'paddl': 'Water',
  'boulder': 'Sports',
  'volleyball': 'Sports',
  'something active': 'Sports',
  'massage': 'Spa',
  'sauna': 'Spa',
};

String? categoryForPlace(String placeType) {
  final p = placeType.toLowerCase();
  for (final e in _bridge.entries) {
    if (p.contains(e.key)) return e.value;
  }
  return null;
}

class Bridge {
  const Bridge(this.chip, this.experience);
  final String chip;
  final Experience experience;
}

/// When a shared chip comes up in the conversation, find a bookable plan
/// for it. Null when nothing real matches (no invented suggestion).
Bridge? findBridge({
  required List<String> chips,
  required Iterable<String> texts,
  required List<Experience> experiences,
}) {
  final lowered = [for (final t in texts) t.toLowerCase()];
  for (final chip in chips) {
    final c = chip.toLowerCase();
    final cats = {for (final e in _bridge.entries) if (c.contains(e.key)) e.value};
    for (final t in lowered) {
      for (final e in _bridge.entries) {
        if (!cats.contains(e.value) || !t.contains(e.key)) continue;
        for (final x in experiences) {
          if (x.category == e.value && x.spotsLeft > 0) return Bridge(chip, x);
        }
      }
    }
  }
  return null;
}

// ============================================================================
// 3. Comfort rules — the member's own, enforced by the app, shown to both
// ============================================================================

class ComfortRules {
  const ComfortRules({
    this.noCallsBeforeMeet = false,
    this.photosAfterDays = 0,
    this.daytimeFirstMeet = false,
    this.opensFirst = false,
  });

  final bool noCallsBeforeMeet;

  /// Photos only after this many days of chatting (0 = any time).
  final int photosAfterDays;

  /// First meet between 08:00 and 18:00 only.
  final bool daytimeFirstMeet;

  /// "I'll message first": matches can't write until this member does.
  final bool opensFirst;
}

/// Held until they've written, when they chose to open the chat.
String? firstMessageHold({
  required ComfortRules theirs,
  required bool theyHaveWritten,
  required String theirName,
}) =>
    theirs.opensFirst && !theyHaveWritten
        ? "$theirName prefers to send the first message. You'll get a notification the moment they write."
        : null;

List<String> comfortSummary(ComfortRules r) => [
      if (r.noCallsBeforeMeet) 'No calls before we\'ve met',
      if (r.photosAfterDays > 0) 'Photos after ${r.photosAfterDays} days of chatting',
      if (r.daytimeFirstMeet) 'First meet in the daytime',
      if (r.opensFirst) 'Sends the first message',
    ];

/// A call needs both people, so either person's rule applies.
String? callBlockedReason({
  required ComfortRules mine,
  required ComfortRules theirs,
  required bool met,
  required String theirName,
}) {
  if (met) return null;
  if (theirs.noCallsBeforeMeet) {
    return '$theirName asked for no calls before you\'ve met.';
  }
  if (mine.noCallsBeforeMeet) {
    return 'You set "no calls before we\'ve met". Change it in How I text & comfort.';
  }
  return null;
}

/// Photos follow the RECIPIENT's rule.
String? photoBlockedReason({
  required ComfortRules theirs,
  required int daysChatting,
  required bool met,
  required String theirName,
}) {
  if (met || daysChatting >= theirs.photosAfterDays) return null;
  final left = theirs.photosAfterDays - daysChatting;
  return '$theirName prefers photos after ${theirs.photosAfterDays} days of '
      'chatting — $left more day${left == 1 ? '' : 's'} to go.';
}

/// Time labels look like "Sat · 11:00". Unknown times are allowed.
bool firstMeetAllowed(
  String timeLabel, {
  required ComfortRules mine,
  required ComfortRules theirs,
  required bool met,
}) {
  if (met || !(mine.daytimeFirstMeet || theirs.daytimeFirstMeet)) return true;
  final m = RegExp(r'(\d{1,2}):\d{2}').firstMatch(timeLabel);
  if (m == null) return true;
  final h = int.parse(m.group(1)!);
  return h >= 8 && h < 18;
}

/// Optional tone tags — help neurodivergent members and second-language
/// chats read intent. Shown as a small pill under the message.
enum ToneTag {
  joking('joking'),
  serious('serious'),
  gentle('being gentle'),
  excited('excited');

  const ToneTag(this.label);
  final String label;
}

// ============================================================================
// 4. Private reflections — only the member ever sees them
// ============================================================================

enum ReflectTag {
  place('The place'),
  talk('The conversation'),
  pace('The pace'),
  timeOfDay('Time of day'),
  quiet('A quiet setting'),
  busy('A busy setting');

  const ReflectTag(this.label);
  final String label;
}

class Reflection {
  const Reflection({
    required this.category,
    required this.good,
    this.liked = const {},
    this.disliked = const {},
  });

  /// Decompress category of the plan, or null when it didn't map to one.
  final String? category;
  final bool good;
  final Set<ReflectTag> liked;
  final Set<ReflectTag> disliked;
}

class Ranked {
  const Ranked(this.experience, this.reason);
  final Experience experience;

  /// Why it's higher, in plain words — null when nothing moved it.
  final String? reason;
}

/// Reorders the shelf from the member's own private check-ins. Stable: with
/// no reflections the order is unchanged and no reasons are invented.
List<Ranked> rankForMe(List<Experience> all, List<Reflection> mine) {
  final scored = <(int, int, Ranked)>[];
  for (var i = 0; i < all.length; i++) {
    final e = all[i];
    var score = 0;
    String? reason;
    for (final r in mine) {
      if (r.category == e.category) {
        score += r.good ? 2 : -2;
        if (r.good) reason ??= 'You enjoyed a ${e.category.toLowerCase()} plan';
      }
      if (e.phoneFree && r.liked.contains(ReflectTag.quiet)) {
        score += 1;
        reason ??= 'You liked quiet settings';
      }
      if (e.groupGoing > 0) {
        if (r.liked.contains(ReflectTag.busy)) {
          score += 1;
          reason ??= 'You liked a lively crowd';
        }
        if (r.disliked.contains(ReflectTag.busy)) score -= 1;
      }
    }
    scored.add((score, i, Ranked(e, score > 0 ? reason : null)));
  }
  scored.sort((a, b) => a.$1 != b.$1 ? b.$1 - a.$1 : a.$2 - b.$2);
  return [for (final s in scored) s.$3];
}

// ============================================================================
// Extras from other apps' reviews: "pause, don't ghost"
// ============================================================================

enum PauseLength {
  tomorrow('tomorrow'),
  fewDays('in a few days'),
  nextWeek('next week');

  const PauseLength(this.label);
  final String label;
}

String pauseNotice(PauseLength l, {required String name}) =>
    '$name paused this chat — back ${l.label}. Not ghosting, just busy.';
