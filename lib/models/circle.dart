// Wave 2 crowd models (CROWD-FEATURES #5 Private Circles, #6 PrivateCircle-only
// Moments, #7 Smart Chat, #8 Wingperson).
//
// A PrivateCircle is a small PERSISTENT group — the thing a one-off plan becomes
// when the people in it decide to stay. Circles are private: only members
// see the circle, its Moments and its chat. Kept separate from the 1:1
// models (member.dart / message.dart): a circle is a group object with
// its own message kinds (polls, "Ask me" openers, introductions).

/// A private, persistent small group (CROWD-FEATURES #5).
///
/// Born from a plan ("Keep this group as a PrivateCircle") and owned by the
/// AppStore like plans and conversations — a circle created from the
/// Plans hub must still exist when the member opens Connect.
class PrivateCircle {
  PrivateCircle({
    required this.id,
    required this.name,
    required List<String> memberIds,
    required this.formedFromLabel,
    this.upcomingPlanId,
    this.sourcePlanId,
  }) : memberIds = List<String>.of(memberIds);

  final String id;
  final String name;

  /// Member ids, 'me' included for the signed-in member. Host/first
  /// member first, mirroring OpenPlan.attendeeIds.
  final List<String> memberIds;

  /// Honest provenance for the header: 'From the plan "Arcade night +
  /// milkshakes"' — a circle never pretends it fell from the sky.
  final String formedFromLabel;

  /// The circle's next plan (an OpenPlan id), when one is on the board.
  final String? upcomingPlanId;

  /// The OpenPlan this circle was converted from, when it was born via
  /// "Keep this group as a PrivateCircle" — the store uses it to refuse a
  /// second conversion of the same plan.
  final String? sourcePlanId;

  int get memberCount => memberIds.length;
  bool get includesMe => memberIds.contains('me');
}

/// The kinds of message a PrivateCircle chat carries (Smart Chat, #7).
enum CircleMsgKind {
  /// A plain group text message.
  text,

  /// A poll sticker: a question with tappable options and real votes.
  poll,

  /// An "Ask me" opener sticker: a member offers a topic; others ask.
  askMe,

  /// A Wingperson introduction card (see [WingIntro]).
  intro,

  /// A centred system line (e.g. how the circle formed).
  system,
}

/// One option in a PrivateCircle poll, with the member ids who picked it.
/// Votes are state, not decoration: one vote per member, movable.
class CirclePollOption {
  CirclePollOption(this.label, [List<String>? voterIds])
      : voterIds = List<String>.of(voterIds ?? const []);

  final String label;
  final List<String> voterIds;

  int get votes => voterIds.length;
}

/// One message in a PrivateCircle chat. Poll votes and Ask-me question counts
/// are mutable session state on the message itself, like ChatMessage's
/// reaction/unsent flags.
class CircleMessage {
  CircleMessage({
    required this.id,
    required this.circleId,
    required this.authorId,
    required this.kind,
    required this.timeLabel,
    this.text = '',
    this.pollOptions = const [],
    this.askMeTopic,
    this.introId,
    this.questionsAsked = 0,
  });

  final String id;
  final String circleId;

  /// Member id of the author; 'me' for the signed-in member.
  final String authorId;

  final CircleMsgKind kind;
  final String timeLabel;

  /// The body for [CircleMsgKind.text] and system lines; the QUESTION
  /// for [CircleMsgKind.poll]. Empty for askMe/intro cards, which carry
  /// their content in [askMeTopic] / [introId].
  final String text;

  /// Poll options (kind == poll only).
  final List<CirclePollOption> pollOptions;

  /// The offered topic (kind == askMe only): "Ask me about …".
  final String? askMeTopic;

  /// The [WingIntro] this card renders (kind == intro only). The intro
  /// object lives in the store; the message is just its place in chat.
  final String? introId;

  /// How many questions this Ask-me sticker has drawn so far.
  int questionsAsked;

  int get pollTotalVotes =>
      pollOptions.fold(0, (sum, o) => sum + o.votes);

  /// The option index 'me' currently backs, or null when I haven't voted.
  int? get myPollVote {
    for (var i = 0; i < pollOptions.length; i++) {
      if (pollOptions[i].voterIds.contains('me')) return i;
    }
    return null;
  }
}

/// A Wingperson introduction (CROWD-FEATURES #8): a circle member (the
/// wingperson, [byId]) introduces two other members ([aId], [bId]) with
/// a short note. BOTH recipients must accept before anything opens —
/// accepting is per-person state, and a completed intro opens a normal
/// 1:1 conversation through the store's existing conversationFor path.
/// Nobody is auto-matched by an intro, and declining is quiet and final.
class WingIntro {
  WingIntro({
    required this.id,
    required this.circleId,
    required this.byId,
    required this.aId,
    required this.bId,
    required this.note,
    Set<String>? acceptedIds,
    this.declined = false,
  }) : acceptedIds = Set<String>.of(acceptedIds ?? const {});

  final String id;
  final String circleId;

  /// The wingperson who made the introduction.
  final String byId;
  final String aId;
  final String bId;
  final String note;

  /// Recipients who have accepted so far (subset of {aId, bId}).
  final Set<String> acceptedIds;

  /// Either recipient may decline; a decline ends the intro for both.
  bool declined;

  bool get isConnected =>
      !declined && acceptedIds.contains(aId) && acceptedIds.contains(bId);

  IntroStatus get status => declined
      ? IntroStatus.declined
      : isConnected
          ? IntroStatus.connected
          : IntroStatus.pending;

  /// True when the signed-in member is one of the two recipients (the
  /// wingperson is never their own recipient in this build).
  bool get involvesMe => aId == 'me' || bId == 'me';

  /// The other recipient, from the signed-in member's side.
  String get otherPartyForMe => aId == 'me' ? bId : aId;

  bool get acceptedByMe => acceptedIds.contains('me');
}

enum IntroStatus {
  pending('Waiting'),
  connected('Connected'),
  declined('Declined');

  const IntroStatus(this.label);
  final String label;
}
