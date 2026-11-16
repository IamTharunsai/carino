import '../models/member.dart';
import '../models/plan.dart';

/// Wave 2 · People Search (CROWD-FEATURES #21). Pure logic, no Flutter
/// imports — social-as-search: a plain-words query ("people who hike on
/// Sundays", "long-term", "arcade") matched against REAL fields of real
/// members and open plans, the same honesty rule as Tune My Drop
/// (drop_tuning.dart): a result appears only because a real signal in
/// the profile/plan text matched a keyword the member typed.
///
/// Matching semantics: the query is tokenised into keywords (filler
/// dropped); a member/plan scores one point per keyword that hits its
/// searchable text; score ≥ 1 lists it, best score first, stable order
/// within a score. An empty or all-filler query matches nothing — the
/// screen shows suggestion chips instead of inventing results.

/// Words that carry no search signal on their own.
const Set<String> _stopwords = {
  'people', 'person', 'who', 'whom', 'that', 'this', 'with', 'near',
  'me', 'my', 'i', 'a', 'an', 'the', 'of', 'to', 'and', 'or', 'in',
  'on', 'for', 'find', 'finding', 'looking', 'look', 'search',
  'searching', 'show', 'someone', 'anyone', 'some', 'any', 'into',
  'want', 'wants', 'like', 'likes', 'get', 'meet',
};

/// Splits a free-text query into matchable keywords: lowercase,
/// punctuation stripped, filler dropped, deduped, order preserved.
List<String> searchKeywords(String query) {
  final words = query
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.length >= 2 && !_stopwords.contains(w));
  final out = <String>[];
  for (final w in words) {
    if (!out.contains(w)) out.add(w);
  }
  return out;
}

/// True when [keyword] hits [text]: substring match plus two light
/// stemming variants — trailing 's' dropped ('sundays' ~ 'sunday') and
/// trailing 'e' dropped ('hike' ~ 'hiking', where the plain substring
/// FAILS: h-i-k-e is not inside h-i-k-i-n-g). Deliberately small: this
/// is forgiving demo matching, not a search engine.
bool _keywordHits(String text, String keyword) {
  if (text.contains(keyword)) return true;
  if (keyword.length <= 3) return false;
  final variants = <String>[
    if (keyword.endsWith('s')) keyword.substring(0, keyword.length - 1),
    if (keyword.endsWith('e')) keyword.substring(0, keyword.length - 1),
  ];
  return variants.any(text.contains);
}

/// Everything about a member search is allowed to read — real fields
/// only (same field set Tune My Drop matches, plus languages).
String memberSearchText(Member m) {
  final parts = <String>[
    m.name,
    m.city,
    m.intention.label,
    m.intention.tagline,
    m.headline,
    m.structure,
    m.pace,
    m.availability,
    ...m.interests,
    ...m.languages,
    for (final p in m.prompts) '${p.question} ${p.answer}',
  ];
  return parts.join(' ').toLowerCase();
}

/// Everything about an open plan search is allowed to read — the plan's
/// own text plus its host's name (people search plans by host too:
/// "Sofia's arcade night").
String planSearchText(OpenPlan p, String hostName) {
  final parts = <String>[
    p.title,
    p.place,
    p.note,
    p.timeLabel,
    hostName,
    if (p.tonight) 'tonight',
    if (p.sourceLabel != null) p.sourceLabel!,
  ];
  return parts.join(' ').toLowerCase();
}

/// How many of [keywords] hit [text] (the ranking signal).
int _score(String text, List<String> keywords) =>
    keywords.where((k) => _keywordHits(text, k)).length;

/// Members matching the query, best score first (stable within a
/// score). Empty query / no hits → empty list, honestly.
List<Member> searchMembers(String query, List<Member> people) {
  final keywords = searchKeywords(query);
  if (keywords.isEmpty) return const [];
  final scored = <(int, int, Member)>[];
  for (var i = 0; i < people.length; i++) {
    final s = _score(memberSearchText(people[i]), keywords);
    if (s > 0) scored.add((i, s, people[i]));
  }
  scored.sort((a, b) {
    final byScore = b.$2.compareTo(a.$2);
    return byScore != 0 ? byScore : a.$1.compareTo(b.$1); // stable
  });
  return [for (final e in scored) e.$3];
}

/// Open plans matching the query, best score first (stable within a
/// score). [hostNameOf] resolves a plan's host id to a display name.
List<OpenPlan> searchPlans(
  String query,
  List<OpenPlan> plans,
  String Function(String memberId) hostNameOf,
) {
  final keywords = searchKeywords(query);
  if (keywords.isEmpty) return const [];
  final scored = <(int, int, OpenPlan)>[];
  for (var i = 0; i < plans.length; i++) {
    final text = planSearchText(plans[i], hostNameOf(plans[i].hostId));
    final s = _score(text, keywords);
    if (s > 0) scored.add((i, s, plans[i]));
  }
  scored.sort((a, b) {
    final byScore = b.$2.compareTo(a.$2);
    return byScore != 0 ? byScore : a.$1.compareTo(b.$1); // stable
  });
  return [for (final e in scored) e.$3];
}
