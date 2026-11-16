// Wave 3 crowd models (CROWD-FEATURES #13 Phone-Down Mode + Presence
// Score, #15 Check-In Safety).
//
// Kept with the plan models' philosophy: these are social-safety objects
// owned by the AppStore, with every number derived from real inputs —
// a Presence Score is COMPUTED from minutes and group size, never
// typed into a seed or hard-coded in a widget.

/// An in-progress Phone-Down session (CROWD-FEATURES #13).
///
/// DEMO STATE, honestly labelled: in the live app, starting a session
/// also engages the OS-level app lock (Screen Time / Digital Wellbeing
/// APIs) so distracting apps are actually blocked. In this build the
/// session is a real timer + record — the lock itself is a hosting-phase
/// integration, and the UI says so wherever the session appears.
class PhoneDownSession {
  PhoneDownSession({
    required this.planId,
    required this.startedAt,
  });

  /// The OpenPlan this session belongs to.
  final String planId;

  /// Wall-clock start. Injected in tests; DateTime.now() in the app.
  final DateTime startedAt;

  /// Whole minutes elapsed at [now] (never negative).
  int elapsedMinutesAt(DateTime now) {
    final m = now.difference(startedAt).inMinutes;
    return m < 0 ? 0 : m;
  }
}

/// The result of a finished Phone-Down session: the Presence Score and
/// the real inputs it was computed from, kept together so the score can
/// always be re-derived and audited (Wave 4's dashboard reads these).
class PresenceRecord {
  const PresenceRecord({
    required this.planId,
    required this.planTitle,
    required this.phoneDownMinutes,
    required this.planMinutes,
    required this.groupSize,
    required this.score,
    required this.dateLabel,
  });

  final String planId;
  final String planTitle;

  /// Minutes the phone actually stayed down.
  final int phoneDownMinutes;

  /// The plan's length in minutes (OpenPlan.durationMinutes).
  final int planMinutes;

  /// People at the plan, host included — presence is presence WITH
  /// people, so the score's group term reads this.
  final int groupSize;

  /// 0–100, from state/presence.dart presenceScore() — the only place
  /// the formula lives.
  final int score;

  /// Display label ('Today', 'Last Fri') — the live backend stores a
  /// real timestamp; labels are this build's convention, like plan times.
  final String dateLabel;
}

/// Whether the signed-in member has checked in to a plan, and how
/// (CROWD-FEATURES #15). One record per plan; updating replaces it.
enum PlanCheckInState {
  /// Not checked in — the plan card offers "Check in".
  none('Not checked in'),

  /// Arrived: "I'm here".
  checkedIn('Checked in'),

  /// On the way but delayed: "Running late".
  runningLate('Running late');

  const PlanCheckInState(this.label);
  final String label;
}

/// A recorded plan check-in. The trusted-contact message is a DEMO RAIL:
/// [messagePreview] is the exact text the live app would send — in this
/// build nothing leaves the phone, and the UI labels it that way.
class PlanCheckIn {
  const PlanCheckIn({
    required this.planId,
    required this.state,
    required this.timeLabel,
    required this.messagePreview,
  });

  final String planId;
  final PlanCheckInState state;

  /// When the check-in was recorded ('now' in-session; a real
  /// timestamp server-side in production).
  final String timeLabel;

  /// The demo message text for the member's trusted contact.
  final String messagePreview;
}
