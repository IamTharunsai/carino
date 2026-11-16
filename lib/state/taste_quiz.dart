import 'drop_tuning.dart';

/// Wave 3 · Taste Quiz (CROWD-FEATURES #20). Pure logic, no Flutter
/// imports.
///
/// A short quiz that tunes the Drop to actual TASTE, not watch-time:
/// every answer maps to real tune terms, and the result is an ordinary
/// [TuneParse] — it flows through the exact same matcher as a typed
/// Tune My Drop (drop_tuning.dart), persists via UserPrefs, and can be
/// cleared or overridden by a manual tune at any time. Terms were
/// checked against the seed profiles' real fields, same rule as the
/// Drop rituals: an answer that matches nobody is a broken promise.

/// One quiz answer: what the member taps, and the tune terms it means.
class TasteOption {
  const TasteOption({required this.label, this.boost = const [], this.drop = const []});

  final String label;

  /// Boost terms this answer contributes.
  final List<String> boost;

  /// Drop terms this answer contributes (the "less of" question).
  final List<String> drop;
}

/// One quiz question with its options.
class TasteQuestion {
  const TasteQuestion({required this.question, required this.options});

  final String question;
  final List<TasteOption> options;
}

/// The quiz: six questions, four answers each. Five shape the boost;
/// the last is the honest "less of" — a quiz that only asks what you
/// love is a horoscope, not a tuner.
const List<TasteQuestion> tasteQuizQuestions = [
  TasteQuestion(
    question: 'Your ideal Saturday starts with…',
    options: [
      TasteOption(label: 'A trail or a run', boost: ['trail', 'hiking', 'running']),
      TasteOption(label: 'Markets and good food', boost: ['farmers markets', 'cooking', 'street-food']),
      TasteOption(label: 'Games — always games', boost: ['board games', 'karaoke', 'chess']),
      TasteOption(label: 'Slow mornings, books, gardens', boost: ['gardens', 'book', 'classical music']),
    ],
  ),
  TasteQuestion(
    question: 'Pick a soundtrack',
    options: [
      TasteOption(label: 'Vinyl crackle', boost: ['vinyl']),
      TasteOption(label: 'Live jazz', boost: ['jazz']),
      TasteOption(label: 'Classical, for focus', boost: ['classical music']),
      TasteOption(label: 'Whatever\'s loud at the arcade', boost: ['arcade']),
    ],
  ),
  TasteQuestion(
    question: 'First-plan energy',
    options: [
      TasteOption(label: 'Coffee and a long walk', boost: ['coffee', 'walk']),
      TasteOption(label: 'Dinner and deep talk', boost: ['ramen', 'cooking']),
      TasteOption(label: 'Play first, talk later', boost: ['board games', 'bouldering']),
      TasteOption(label: 'Gallery, then gardens', boost: ['gallery', 'gardens', 'photography']),
    ],
  ),
  TasteQuestion(
    question: 'Your group chat knows you as…',
    options: [
      TasteOption(label: 'The foodie', boost: ['tacos', 'ramen', 'street-food']),
      TasteOption(label: 'The competitor', boost: ['trivia', 'chess', 'board games']),
      TasteOption(label: 'The plant person', boost: ['gardening', 'gardens']),
      TasteOption(label: 'The photographer', boost: ['photography']),
    ],
  ),
  TasteQuestion(
    question: 'Pick a night in',
    options: [
      TasteOption(label: 'Cooking something new', boost: ['cooking', 'sourdough']),
      TasteOption(label: 'A film I can\'t stop thinking about', boost: ['indie films', 'films']),
      TasteOption(label: 'Vinyl and nowhere to be', boost: ['vinyl']),
      TasteOption(label: 'Book-club energy', boost: ['book', 'book clubs']),
    ],
  ),
  TasteQuestion(
    question: 'And what should your Drop do LESS of?',
    options: [
      TasteOption(label: 'Less competitive stuff', drop: ['chess', 'board games', 'trivia']),
      TasteOption(label: 'Less food-centric profiles', drop: ['cooking', 'tacos', 'ramen']),
      TasteOption(label: 'Less nightlife', drop: ['jazz', 'karaoke']),
      TasteOption(label: 'Nothing — keep it mixed'),
    ],
  ),
];

/// Builds the tune from quiz answers: [answers] maps question index →
/// chosen option index. Unanswered questions contribute nothing;
/// out-of-range indices are ignored rather than crashing. Terms are
/// deduped (order preserved), and a term that is both boosted and
/// dropped is dropped — the explicit "less" wins, same rule as the
/// typed tune parser.
TuneParse tuneFromQuizAnswers(Map<int, int> answers) {
  final boost = <String>[];
  final drop = <String>[];
  for (var q = 0; q < tasteQuizQuestions.length; q++) {
    final pick = answers[q];
    if (pick == null) continue;
    final options = tasteQuizQuestions[q].options;
    if (pick < 0 || pick >= options.length) continue;
    for (final t in options[pick].boost) {
      if (!boost.contains(t)) boost.add(t);
    }
    for (final t in options[pick].drop) {
      if (!drop.contains(t)) drop.add(t);
    }
  }
  boost.removeWhere(drop.contains);
  return TuneParse(boost: boost, drop: drop);
}
