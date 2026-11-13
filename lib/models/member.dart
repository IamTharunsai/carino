/// The four stated intentions (blueprint S-008 / EMBER spec).
/// Intention is always visible on the card — nobody guesses what someone wants.
enum Intention {
  tonight('Tonight', 'Open to meeting soon'),
  casualDating('Casual Dating', 'Dates, no pressure'),
  longTerm('Long-Term', 'Looking for something real'),
  hangoutAndPlay('Hangout & Play', 'Games, laughs, low-key plans'),
  stillExploring('Still exploring', 'Open to seeing what fits');

  const Intention(this.label, this.tagline);
  final String label;
  final String tagline;
}

/// A member of the app. In this scaffold every member is SAMPLE DATA
/// (see data/mock_data.dart) — never a real person.
class Member {
  const Member({
    required this.id,
    required this.name,
    required this.age,
    required this.city,
    required this.distanceBand,
    required this.intention,
    required this.photoAsset,
    required this.headline,
    required this.prompts,
    required this.interests,
    this.verified = true,
    this.hasVideoIntro = true,
    this.hasVoiceIntro = false,
    this.languages = const ['English'],
    this.onlineNow = false,
    // S-008/S-019 dimensions — always text-labelled on the profile.
    this.structure = 'Monogamy',
    this.pace = 'Chat first',
    this.availability = 'This week',
    this.boundaries = '',
    this.photoAssets = const [],
  });

  final String id;
  final String name;
  final int age;
  final String city;

  /// Broad band only — the app NEVER shows an exact location (blueprint S-015).
  final String distanceBand;

  final Intention intention;

  /// In production this is a signed media URL from BackendService storage.
  final String photoAsset;

  /// Full gallery for the S-019 media carousel; falls back to [photoAsset].
  final List<String> photoAssets;
  List<String> get gallery =>
      photoAssets.isEmpty ? [photoAsset] : photoAssets;

  final String headline;

  /// Prompt question -> answer (3 prompts per blueprint S-013).
  final List<PromptAnswer> prompts;

  final List<String> interests;

  /// Verified badge = ID + liveness + photo match passed (S-007).
  final bool verified;
  final bool hasVideoIntro;
  final bool hasVoiceIntro;
  final List<String> languages;
  final bool onlineNow;

  /// Relationship structure (S-008): a separate dimension from intention.
  final String structure;

  /// Preferred pace (S-008): Chat first / Voice first / Video first /
  /// Meet after chatting.
  final String pace;

  /// Availability signal (S-008) — drives plan-led matching.
  final String availability;

  /// Free-text boundaries shown on the profile (S-013). A label never
  /// grants consent — it only informs.
  final String boundaries;

  String get firstName => name.split(' ').first;
}

class PromptAnswer {
  const PromptAnswer(this.question, this.answer);
  final String question;
  final String answer;
}

/// A mutual match (both people liked each other).
///
/// MATCH EXPIRY + ARCHIVE (REA pattern, rea-patterns.md §5.1 — Tinder ships
/// `/v1/match-expiration/archived-matches`): a match with NO conversation
/// expires on a stated, real clock ([expiresInLabel]) and then moves to the
/// ARCHIVE — it is never deleted-and-shamed, and the deadline is honest
/// (server-enforced via RemoteConfig.matchExpiryHours, never a fake timer).
/// Once a conversation or plan exists, expiry no longer applies.
class MatchConnection {
  const MatchConnection({
    required this.id,
    required this.member,
    required this.matchedAtLabel,
    this.planStatus,
    this.expiresInLabel,
    this.archived = false,
  });

  final String id;
  final Member member;
  final String matchedAtLabel;

  /// e.g. "Coffee suggested · awaiting their confirm" — null when no plan yet.
  final String? planStatus;

  /// For unmessaged matches only: the real time left before archival,
  /// rendered by MatchExpiryChip as "Expires in Xh". Server-authoritative
  /// in production — the client only displays what the server states.
  final String? expiresInLabel;

  /// True once the expiry clock ran out with no conversation. Archived
  /// matches render in their own quiet section (Connect tab) and can be
  /// left there without penalty or pressure copy.
  final bool archived;

  /// Expiry pressure only exists while there is nothing real yet.
  bool get isExpiring => !archived && planStatus == null && expiresInLabel != null;
}

/// A 24h Moment (blueprint S-022–S-024). Expiry timers are real and, in
/// production, server-authoritative — never trust the device clock alone.
class Moment {
  const Moment({
    required this.id,
    required this.member,
    required this.caption,
    required this.imageAsset,
    required this.expiresInLabel,
  });

  final String id;
  final Member member;
  final String caption;
  final String imageAsset;
  final String expiresInLabel;
}

/// A suggested real-world plan (blueprint S-039/S-040). Public place TYPES
/// only — never a private address.
class PlanSuggestion {
  const PlanSuggestion({
    required this.id,
    required this.placeType,
    required this.timeLabel,
    required this.note,
  });

  final String id;
  final String placeType; // e.g. "Coffee", "Gallery walk", "Street-food market"
  final String timeLabel; // e.g. "Sat · 11:00"
  final String note;
}
