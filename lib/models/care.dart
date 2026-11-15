// Emotional care + games made for each pair. Pure Dart, tested in
// test/care_games_test.dart and test/personas_test.dart.
import 'experience.dart' show tasteQuiz;
import 'member.dart';
import 'message.dart' show GameQuestion;
import 'wellbeing.dart' show Experience;

// ============================================================================
// "How are you, really?" — a feeling first, then a small step, then a plan
// ============================================================================

enum Mood {
  overwhelmed('Overwhelmed', '🌊'),
  lonely('Lonely', '🫂'),
  restless('Restless', '⚡'),
  low('Low', '🌧️'),
  okay('Okay — just curious', '🌤️');

  const Mood(this.label, this.emoji);
  final String label;
  final String emoji;
}

class Care {
  const Care(this.line, this.oneMinute, this.categories, {this.showCrisisLine = false});

  /// A human acknowledgement — never clinical, never a diagnosis.
  final String line;

  /// Something they can do right now, in about a minute.
  final String oneMinute;

  /// Decompress categories that fit this feeling, best first.
  final List<String> categories;
  final bool showCrisisLine;
}

Care careFor(Mood m) => switch (m) {
      Mood.overwhelmed => const Care(
          "That's a lot to carry. Let's make the next hour smaller.",
          'Breathe with the circle for one minute.',
          ['Calm', 'Walk', 'Spa']),
      Mood.lonely => const Care(
          'Wanting people around is human, not needy.',
          'Send one person in your inner circle a "thinking of you".',
          ['Café', 'Sports', 'Walk', 'Move']),
      Mood.restless => const Care(
          'Your body wants to move. Let it.',
          'Stand up and shake out your hands for 30 seconds.',
          ['Move', 'Sports', 'Water']),
      Mood.low => const Care(
          "Thanks for saying it. You don't have to fix it right now.",
          'Step outside for one minute of daylight.',
          ['Walk', 'Calm', 'Café'],
          showCrisisLine: true),
      Mood.okay => const Care(
          'Love that. Something fun, then?',
          'Pick one thing below that makes you smile.',
          ['Make', 'Water', 'Sports', 'Café']),
    };

/// Plans that fit the feeling, in the care's category order. Lonely leads
/// with plans where verified people are already going.
List<Experience> moodPicks(Mood m, List<Experience> all) {
  final cats = careFor(m).categories;
  final picks = [
    for (final c in cats)
      for (final e in all)
        if (e.category == c && e.spotsLeft > 0) e,
  ];
  if (m == Mood.lonely) {
    picks.sort((a, b) => b.groupGoing.compareTo(a.groupGoing));
  }
  return picks;
}

// ============================================================================
// Games made for the two of you
// ============================================================================

/// A This-or-That deck built from BOTH profiles: their interests and
/// "topics I love", the tastes you disagree on (the fun ones), and a few
/// classics as filler. Never touches their "please don't ask" topics.
List<GameQuestion> personalDeck({
  required List<String> myInterests,
  required Map<String, String> myTastes,
  required Member them,
}) {
  final avoid = [for (final a in them.textingStyle.avoid) a.toLowerCase()];
  bool ok(String s) => !avoid.any((a) => a.isNotEmpty && s.toLowerCase().contains(a));
  final deck = <GameQuestion>[];
  void add(String prompt, String a, String b) {
    if (ok(prompt) && !deck.any((q) => q.prompt == prompt)) {
      deck.add(GameQuestion(prompt: prompt, options: [a, b]));
    }
  }

  for (final t in them.textingStyle.loves) {
    add('${them.firstName}, your $t: best story or best tip?', 'Story', 'Tip');
  }
  for (final q in tasteQuiz) {
    final mine = myTastes[q.id], theirs = them.tasteAnswers[q.id];
    if (mine != null && theirs != null && mine != theirs) {
      add('Settle it: ${q.a} or ${q.b}?', q.a, q.b);
    }
  }
  final shared = {for (final i in myInterests) i.toLowerCase()};
  for (final i in them.interests) {
    shared.contains(i.toLowerCase())
        ? add('$i: solo or together?', 'Solo', 'Together')
        : add("You're into $i. Teach me or show me?", 'Teach me', 'Show me');
  }
  // ponytail: classics only pad short decks; the model (AI-08) replaces
  // this whole function once the live key is set.
  const classics = [
    ('Big night out or cozy night in?', 'Night out', 'Night in'),
    ('Text first or call first?', 'Text', 'Call'),
    ('Window seat or aisle seat?', 'Window', 'Aisle'),
  ];
  for (final c in classics) {
    if (deck.length >= 8) break;
    add(c.$1, c.$2, c.$3);
  }
  return deck;
}
