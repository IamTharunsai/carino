// Wave 4 · The agent layer (MASTER-BUILD-PLAN A1–A4).
//
// Three objects, one rule each:
// - [ConciergeProposal] / [ConciergeBooking]: the Concierge proposes
//   from REAL store data and books through the REAL store actions —
//   a proposal is a pointer at a real night/plan/ticket, never a
//   rendered promise of one.
// - [PreScreenSummary]: the vetting card is COMPUTED from real member
//   fields (verification, intention, interests, city, pace, blocks) —
//   every line can be re-derived from the two profiles.
// - [OutcomeRecord] / [OutcomePrompt]: the outcome graph. A record is
//   written once, by the member, about a real past subject; standing
//   and dashboard numbers are computed FROM the records, never typed.

/// What the member can book through a Concierge proposal.
enum ConciergeProposalKind {
  /// A Cariño Tables night (book a seat).
  table,

  /// An open plan (join / request to join).
  plan,

  /// A club night (claim free / buy premium tickets).
  ticket,

  /// No existing option fits — the Concierge drafts a new plan the
  /// member hosts (prefilled from their own words).
  newPlan,
}

/// One Concierge proposal: a real option, its price stated up front,
/// and a WHY line derived from real fields (see state/concierge.dart).
class ConciergeProposal {
  const ConciergeProposal({
    required this.kind,
    required this.title,
    required this.detailLabel,
    required this.whyLine,
    required this.actionLabel,
    this.refId,
    this.priceLabel,
    this.seats = 1,
    this.premium = false,
    this.newPlanTitle,
    this.newPlanPlace,
    this.newPlanTimeLabel,
    this.newPlanTonight = false,
    this.newPlanGroupSize = 4,
    this.newPlanDecompress = false,
  });

  final ConciergeProposalKind kind;

  /// Id of the real subject (TableNight / OpenPlan / ClubNight id).
  /// Null for [ConciergeProposalKind.newPlan] — nothing exists yet.
  final String? refId;

  final String title;

  /// When/where line ('Thu · Nov 19 · Short North').
  final String detailLabel;

  /// One honest line: why this option, from real fields only.
  final String whyLine;

  /// '$24 total' / 'Free' — null only when there is no money at all
  /// AND nothing to claim (a plan join). Money is always stated
  /// BEFORE the confirm tap, never after (the plan's money rule).
  final String? priceLabel;

  /// The confirm button's verb ('Book seat', 'Join plan', …).
  final String actionLabel;

  /// Seats/tickets the booking takes (from the member's own words —
  /// "4 of us" — capped by the real remaining capacity).
  final int seats;

  /// Ticket proposals only: true = the premium tier, false = the
  /// free claim. The tier is chosen at proposal time from the night's
  /// real offers + the member's words ("free" beats premium).
  final bool premium;

  // --- newPlan draft (kind == newPlan only) ---
  final String? newPlanTitle;
  final String? newPlanPlace;
  final String? newPlanTimeLabel;
  final bool newPlanTonight;
  final int newPlanGroupSize;
  final bool newPlanDecompress;
}

/// A completed Concierge booking, recorded by the store so the
/// confirmation (and the Plans hub card) render real state, not a
/// toast that evaporates.
class ConciergeBooking {
  const ConciergeBooking({
    required this.title,
    required this.actionSummary,
    required this.reminderLabel,
    this.priceLabel,
  });

  /// What was booked ('Cariño Tables — Thu · Nov 19').
  final String title;

  /// What the booking DID ('Seat confirmed · table of 6').
  final String actionSummary;

  /// The price the member saw before confirming; null when free.
  final String? priceLabel;

  /// Reminder state, honestly labelled (demo: scheduled locally).
  final String reminderLabel;
}

/// The four answers to "Did it happen?" (MASTER-BUILD-PLAN A3).
enum OutcomeRating {
  great('Great'),
  fine('Fine'),
  didntHappen("Didn't happen"),
  noShow("Someone didn't show");

  const OutcomeRating(this.label);
  final String label;

  /// The subject took place (from my side of the table). A no-show
  /// report is NOT a "happened" — the plan may have run, but the
  /// outcome graph records what the member attests, and the member
  /// attests someone wasn't there.
  bool get happened => this == OutcomeRating.great || this == OutcomeRating.fine;
}

/// What an outcome is about.
enum OutcomeSubjectKind {
  plan('Plan'),
  table('Tables night'),
  ticket('Club night');

  const OutcomeSubjectKind(this.label);
  final String label;
}

/// One outcome check-in, written by the signed-in member about one
/// real past subject. At most one record per subject from me — the
/// store refuses a second (see AppStore.recordOutcome).
class OutcomeRecord {
  const OutcomeRecord({
    required this.id,
    required this.subjectKind,
    required this.subjectId,
    required this.subjectTitle,
    required this.subjectDetail,
    required this.rating,
    required this.dateLabel,
    this.hostId,
  });

  final String id;
  final OutcomeSubjectKind subjectKind;

  /// OpenPlan id / TableNight id / ClubNight id of the subject.
  final String subjectId;

  final String subjectTitle;

  /// 'Hosted by Dev · Last Sat · 19:00' — display provenance.
  final String subjectDetail;

  /// The plan's host (member id, 'me' for my own plans) — the key
  /// host standing aggregates on. Null for Tables (Cariño hosts) and
  /// club nights (the venue hosts).
  final String? hostId;

  final OutcomeRating rating;

  /// When the check-in was written ('Today' in-session; a real
  /// timestamp server-side in production).
  final String dateLabel;
}

/// A past subject still awaiting my check-in — the prompt the Plans
/// hub and the You tab render. Derived by the store from real past
/// subjects minus the records already written; never seeded as UI.
class OutcomePrompt {
  const OutcomePrompt({
    required this.subjectKind,
    required this.subjectId,
    required this.title,
    required this.detailLabel,
    this.hostId,
  });

  final OutcomeSubjectKind subjectKind;
  final String subjectId;
  final String title;
  final String detailLabel;

  /// See [OutcomeRecord.hostId].
  final String? hostId;
}

/// Safety outcome of an Agent Pre-Screen (A2).
enum PreScreenSafety {
  /// Nothing on file between the two members.
  clear,

  /// I have blocked this member. A blocked member can never be in
  /// [AppStore.matches] (blocking removes them), so this state is
  /// defensive: if it ever renders, the chat stays closed.
  blocked,
}

/// The Agent Pre-Screen card's data (A2): computed from the two real
/// profiles + the store's block list — see state/pre_screen.dart.
/// The agent FILTERS and EXPLAINS; the human commits. Nothing here
/// sends, or can send, a message.
class PreScreenSummary {
  const PreScreenSummary({
    required this.memberId,
    required this.verified,
    required this.intentionAligned,
    required this.intentionLine,
    required this.sharedSignals,
    required this.safety,
    required this.safetyLine,
  });

  final String memberId;

  /// The other member's real verification state.
  final bool verified;

  /// Same stated intention on both profiles.
  final bool intentionAligned;

  /// The intention line, stated plainly either way ('Both here for
  /// Casual Dating' / 'You're here for X — they're here for Y').
  final String intentionLine;

  /// Real shared signals, best first (shared interests, profile
  /// mentions, same city, same pace, Real Capture, online now).
  /// Empty is a possible, honest answer.
  final List<String> sharedSignals;

  final PreScreenSafety safety;
  final String safetyLine;

  /// Chat may open only when the screen is clear — a blocked match
  /// renders the card WITHOUT a start button.
  bool get canChat => safety == PreScreenSafety.clear;
}
