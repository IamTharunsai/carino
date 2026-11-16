import '../models/member.dart';

/// Wave 1 · Tune My Drop (CROWD-FEATURES #17) + Why You're Seeing Them
/// (#18). Pure logic, no Flutter imports — the deck ordering, the parser
/// and the reason line are all unit-testable, and every output is derived
/// ONLY from real member fields (interests, headline, prompts, intention,
/// city, distance, online state). Nothing here invents a signal.

/// A parsed tune: terms to boost and terms to drop, in the member's own
/// words (lowercased, deduped, order preserved).
class TuneParse {
  const TuneParse({this.boost = const [], this.drop = const []});

  final List<String> boost;
  final List<String> drop;

  static const TuneParse empty = TuneParse();

  bool get isEmpty => boost.isEmpty && drop.isEmpty;

  @override
  String toString() => 'TuneParse(boost: $boost, drop: $drop)';
}

/// Words that carry no matching signal on their own.
const Set<String> _stopwords = {
  'people', 'person', 'profiles', 'profile', 'someone', 'anyone',
  'stuff', 'things', 'thing', 'vibes', 'vibe', 'ones', 'them', 'who',
  'with', 'that', 'this', 'from', 'into', 'just', 'really', 'very',
  'much', 'many', 'more', 'less', 'fewer', 'show', 'showing', 'see',
  'seeing', 'want', 'wants', 'like', 'likes', 'love', 'please', 'give',
  'get', 'find', 'meet', 'near', 'me', 'my', 'i', 'a', 'an', 'the',
  'of', 'to', 'and', 'or', 'in', 'on', 'for',
};

/// Filler words people naturally lead with ('show me more …') that are
/// stripped from the FRONT of a term, word by word.
const Set<String> _leadIns = {
  'show', 'me', 'more', 'less', 'fewer', 'please', 'give', 'find',
  'want', 'see', 'i', 'to', 'only',
};

/// Splits one segment ('hiking and live music, vinyl') into clean terms.
List<String> _termsFrom(String segment) {
  final out = <String>[];
  for (final raw in segment.split(RegExp(r'[,;&]|\band\b'))) {
    var words = raw.trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    while (words.isNotEmpty && _leadIns.contains(words.first)) {
      words.removeAt(0);
    }
    final term = words.join(' ');
    if (term.isEmpty) continue;
    // A term made only of stopwords ('people stuff') carries no signal.
    if (words.every(_stopwords.contains)) continue;
    if (term.length < 2) continue;
    if (!out.contains(term)) out.add(term);
  }
  return out;
}

/// Parses free text like "more hiking and live music, less clubbing"
/// into a [TuneParse]. Everything before the first less/fewer marker is
/// the boost segment; everything after it is the drop segment. A leading
/// "less …" with nothing before it yields boost = [].
TuneParse parseTuneText(String input) {
  final text = input.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.isEmpty) return TuneParse.empty;
  final marker = RegExp(r'\b(less|fewer|no more)\b').firstMatch(text);
  final String boostSegment;
  final String dropSegment;
  if (marker == null) {
    boostSegment = text;
    dropSegment = '';
  } else {
    boostSegment = text.substring(0, marker.start);
    dropSegment = text.substring(marker.end);
  }
  final boost = _termsFrom(boostSegment);
  // A term can't be both boosted and dropped — the explicit "less" wins.
  final drop = _termsFrom(dropSegment);
  boost.removeWhere(drop.contains);
  return TuneParse(boost: boost, drop: drop);
}

/// Everything about a member the tune is allowed to match against —
/// real fields only.
String _searchText(Member m) {
  final parts = <String>[
    m.name,
    m.city,
    m.intention.label,
    m.headline,
    m.structure,
    m.availability,
    ...m.interests,
    for (final p in m.prompts) '${p.question} ${p.answer}',
  ];
  return parts.join(' ').toLowerCase();
}

/// True when [term] matches the member's real profile text. Substring
/// match, with a light singular/plural tolerance ('trails' ~ 'trail').
bool tuneTermMatches(Member m, String term) {
  final text = _searchText(m);
  final t = term.trim().toLowerCase();
  if (t.isEmpty) return false;
  if (text.contains(t)) return true;
  if (t.length > 3 && t.endsWith('s') && text.contains(t.substring(0, t.length - 1))) {
    return true;
  }
  // Multi-word terms: every MEANINGFUL (non-stopword) word present
  // somewhere in the profile also counts ('people who hike' -> 'hike').
  final words = t
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 2 && !_stopwords.contains(w))
      .toList();
  if (words.isNotEmpty && words.every(text.contains)) return true;
  return false;
}

/// Number of boost terms the member matches (the ranking signal).
int tuneBoostScore(Member m, TuneParse tune) =>
    tune.boost.where((t) => tuneTermMatches(m, t)).length;

/// Applies a tune to a deck: members matching ANY drop term are removed
/// (an explicit "less" is an instruction, not a suggestion), and the
/// rest are stably re-ordered by boost score, best matches first.
/// An empty tune returns the deck untouched.
List<Member> applyTuneToDeck(List<Member> deck, TuneParse tune) {
  if (tune.isEmpty) return deck;
  final kept = deck
      .where((m) => !tune.drop.any((t) => tuneTermMatches(m, t)))
      .toList();
  final scored = <(int, int, Member)>[
    for (var i = 0; i < kept.length; i++)
      (i, tuneBoostScore(kept[i], tune), kept[i]),
  ];
  scored.sort((a, b) {
    final byScore = b.$2.compareTo(a.$2);
    return byScore != 0 ? byScore : a.$1.compareTo(b.$1); // stable
  });
  return [for (final e in scored) e.$3];
}

/// The one-line "Why you're seeing them" reason (CROWD-FEATURES #18).
/// Priority: the member's own tune > a shared interest > the same
/// intention > live availability > plain proximity. Every branch states
/// a REAL signal from the two profiles — never a fabricated affinity.
String whySeeingReason(
  Member m, {
  required Member me,
  TuneParse tune = TuneParse.empty,
}) {
  for (final term in tune.boost) {
    if (tuneTermMatches(m, term)) return 'Because you tuned for $term';
  }
  final mine = me.interests.toSet();
  final shared = m.interests.where(mine.contains).toList();
  if (shared.isNotEmpty) return 'You both like ${shared.first}';
  if (m.intention == me.intention) {
    return 'Also here for ${m.intention.label}';
  }
  if (m.onlineNow) return 'Online now · ${m.distanceBand} in ${m.city}';
  return '${m.distanceBand} · ${m.city} · verified';
}
