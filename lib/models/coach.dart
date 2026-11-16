/// AI profile coach: a short chat that fills the profile for you.
/// Live: the ai-proxy `coach` feature writes the draft. Offline/demo: the
/// plain rules below, so the flow always works. Nothing saves until you tap
/// "Use this".
library;

enum CoachField { work, weekend, firstDate, interests, bio }

typedef CoachQuestion = ({CoachField field, String ask});

const _questions = <CoachField, String>{
  CoachField.work: 'Let’s make you irresistible 😌 What do you do — or love doing — most days?',
  CoachField.weekend: 'Perfect weekend, no rules. What are you doing?',
  CoachField.firstDate: 'Dream first date with someone cute. Go.',
  CoachField.interests: 'What could you talk about for hours? Hobbies, obsessions, guilty pleasures.',
};

/// Only asks about what's still empty.
List<CoachQuestion> coachQuestions({
  required bool hasBio,
  required int interestCount,
  required int promptCount,
}) =>
    [
      if (!hasBio) ...[
        (field: CoachField.work, ask: _questions[CoachField.work]!),
        (field: CoachField.weekend, ask: _questions[CoachField.weekend]!),
      ],
      if (promptCount < 1) (field: CoachField.firstDate, ask: _questions[CoachField.firstDate]!),
      if (interestCount < 3) (field: CoachField.interests, ask: _questions[CoachField.interests]!),
    ];

class CoachDraft {
  CoachDraft({this.bio, this.interests = const [], this.promptAnswers = const {}});
  final String? bio;
  final List<String> interests;
  final Map<String, String> promptAnswers;
}

const knownInterests = [
  'Coffee', 'Live music', 'Hiking', 'Ceramics', 'Yoga', 'Kayaking', 'Board games',
  'Cooking', 'Photography', 'Farmers markets', 'Bouldering', 'Jazz', 'Comedy shows',
  'Trail running', 'Book clubs', 'Travel', 'Dancing', 'Wine', 'Gaming', 'Movies',
  'Art galleries', 'Football', 'Cricket', 'Gym', 'Cycling', 'Swimming', 'Dogs', 'Cats',
  'Anime', 'Fashion', 'Tech', 'Startups', 'Meditation', 'Baking', 'Karaoke', 'Concerts',
];

String? cleanInterest(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  return t[0].toUpperCase() + t.substring(1);
}

/// Offline draft: pulls interests out of what you said and writes a short bio.
CoachDraft draftFromAnswers(Map<CoachField, String> a) {
  final all = a.values.join(' ').toLowerCase();
  final interests = [for (final i in knownInterests) if (all.contains(i.toLowerCase())) i];
  final work = a[CoachField.work]?.trim();
  final weekend = a[CoachField.weekend]?.trim();
  final bio = [
    if (work != null && work.isNotEmpty) work.endsWith('.') ? work : '$work.',
    if (weekend != null && weekend.isNotEmpty) 'Weekends? $weekend.',
  ].join(' ');
  final date = a[CoachField.firstDate]?.trim();
  return CoachDraft(
    bio: bio.isEmpty ? null : bio,
    interests: interests,
    promptAnswers: {if (date != null && date.isNotEmpty) 'My ideal first plan is…': date},
  );
}
