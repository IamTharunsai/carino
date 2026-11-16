// Wave 1 crowd models (CROWD-FEATURES #9 Post→Plan, #10 Tonight Near
// Me, #11 Cariño Tables).
//
// Kept separate from the 1:1 PlanSuggestion/MockPlan flow (S-039/S-041):
// those are private suggestions between two matched people. The models
// here are OPEN group plans and the Tables dinner — social objects with
// hosts, attendees and join state, owned by the AppStore.

/// The signed-in member's relationship to an [OpenPlan].
enum PlanJoinState {
  /// Not involved yet — the card offers Join / Request to join.
  none,

  /// Asked the host; waiting on their confirm (host-approval plans).
  requested,

  /// Attending (RSVP'd on an instant-join plan, approved by a host, or
  /// the host themselves).
  going,
}

/// An open, group plan a verified member is hosting — created from a
/// chat, a Moment, or the Plans hub (Post→Plan, CROWD-FEATURES #9).
///
/// PLACES are public place names/types only — never a private address
/// (same rule as S-039). Times are display labels in this build; the
/// live backend stores real timestamps and derives [tonight] server-side.
class OpenPlan {
  OpenPlan({
    required this.id,
    required this.title,
    required this.place,
    required this.timeLabel,
    required this.tonight,
    required this.groupSize,
    required this.hostId,
    required List<String> attendeeIds,
    this.instantJoin = false,
    this.sourceLabel,
    this.note = '',
    this.decompress = false,
    this.durationMinutes = 120,
    this.past = false,
    this.myState = PlanJoinState.none,
  }) : attendeeIds = List<String>.of(attendeeIds);

  final String id;
  final String title;

  /// Public place (name or type) — e.g. 'North Market', 'Arcade bar ·
  /// Short North'. Never a home address.
  final String place;
  final String timeLabel;

  /// True when the plan starts this evening (drives Tonight Near Me).
  final bool tonight;

  /// Total spots INCLUDING the host.
  final int groupSize;

  /// Member id of the host; 'me' for the signed-in member's own plans.
  final String hostId;

  /// Member ids attending (host first). Mutable: the store adds/removes
  /// 'me' as join state changes — session state, like conversations.
  final List<String> attendeeIds;

  /// True when the host lets any verified member RSVP directly; false
  /// means joining is a request the host approves.
  final bool instantJoin;

  /// Honest provenance for the card: 'From your chat with Aria',
  /// 'From Sofia's Moment' — null for plans born in the hub.
  final String? sourceLabel;

  final String note;

  /// Wave 3 · Decompress shelf (CROWD-FEATURES #12): true for calm,
  /// low-key, bookable offline plans (park walks, garden mornings,
  /// lakeside sits, outdoor yoga). The Plans hub shelves these apart
  /// from the loud board; joining uses the same state machine.
  final bool decompress;

  /// How long the plan runs, in minutes. The Presence Score's coverage
  /// term reads this (state/presence.dart) — a real input, seeded per
  /// plan, set by the host's pick in the live composer.
  final int durationMinutes;

  /// Wave 4 · Outcome Graph (MASTER-BUILD-PLAN A3): true when the plan
  /// already happened. Past plans leave the joinable board (the hub and
  /// People Search filter them out) and become outcome subjects — the
  /// store asks "did it happen?" about exactly these. Times in this
  /// build are labels, so pastness is stated, never derived from a
  /// device clock; the live backend derives it from real timestamps.
  final bool past;

  /// The signed-in member's join state (store-mutated).
  PlanJoinState myState;

  int get spotsLeft => groupSize - attendeeIds.length;
  bool get isFull => spotsLeft <= 0;
  bool get hostedByMe => hostId == 'me';
}

/// One weekly Cariño Tables night (CROWD-FEATURES #11): a verified-only
/// group dinner — tables of [TableNight.tableSize], venue and tablemates
/// revealed only on the day (the late-reveal mechanic).
class TableNight {
  const TableNight({
    required this.id,
    required this.dayLabel,
    required this.dateLabel,
    required this.revealLabel,
    required this.areaLabel,
    required this.vibeLabel,
    required this.seatPrice,
    required this.capacity,
    required this.bookedSeats,
  });

  final String id;

  /// 'Thursday'
  final String dayLabel;

  /// 'Thu · Nov 19'
  final String dateLabel;

  /// When the venue + tablemates unlock: 'Thu at 17:00'.
  final String revealLabel;

  /// Neighbourhood only — the venue itself stays hidden until reveal.
  final String areaLabel;

  /// The table mix this night is curated for ('Foodies & first-timers').
  final String vibeLabel;

  /// Per-seat price in USD. Tables seats are priced $17–35 (the range
  /// the category charges per seat); the meal itself is paid at the
  /// restaurant and is never bundled into the seat price.
  final int seatPrice;

  /// Total seats across all tables that night.
  final int capacity;

  /// Seats already booked (seed). The store tracks further bookings on
  /// top of this — see AppStore.tableSeatsLeft.
  final int bookedSeats;

  /// Cariño Tables seat people at tables of six — the group size the
  /// category's evidence supports (small enough to talk, big enough to
  /// survive one quiet person).
  static const int tableSize = 6;
}

/// Booking lifecycle for a Tables seat (demo checkout in this build).
enum TableBookingStatus {
  /// Seat held while the (demo) checkout completes.
  held,

  /// Paid (demo) and locked in. The reveal stays pending until the day.
  confirmed,
}

/// The signed-in member's Tables booking. At most ONE active booking at
/// a time in this build — one dinner a week is the product's rhythm.
class TableBooking {
  TableBooking({
    required this.id,
    required this.nightId,
    required this.seats,
    required this.totalPrice,
    this.status = TableBookingStatus.held,
  });

  final String id;
  final String nightId;
  final int seats;
  final int totalPrice;
  TableBookingStatus status;
}

/// The member's standing with Cariño Tables, driven by the no-show
/// policy: one no-show = a warning; a second = banned from Tables.
/// Attendance is recorded by the host check-in in production; in this
/// build the state exists so the policy is real, visible and testable.
enum TablesStanding {
  good('Good standing'),
  warned('Warning on file'),
  banned('Banned from Tables');

  const TablesStanding(this.label);
  final String label;
}
