// Wave 3.5 · Club & Event Tickets (MASTER-BUILD-PLAN T1).
//
// Kept separate from the Tables models (plan.dart): a Tables seat is a
// curated dinner with a late reveal; a club ticket is a simpler object —
// a night, a tier, a quantity, a door state — sold either by Cariño
// (our events, our ticketing, a transparent service fee) or by a
// partner venue through an affiliate rail ("via partner", no fee line,
// never venue ops in-house — the research verdict in the plan).

/// The two tiers a night can offer.
enum TicketTier {
  free('Free ticket'),
  premium('Premium ticket');

  const TicketTier(this.label);
  final String label;
}

/// Who sells the night — decides the money presentation, honestly:
/// our own events carry our service fee in the open; partner events
/// are affiliate listings and carry NO Cariño fee line.
enum TicketSeller {
  carino('Hosted by Cariño'),
  partner('Via partner');

  const TicketSeller(this.label);
  final String label;
}

/// Lifecycle of one of my tickets. [held] exists only for premium —
/// the seat is reserved while the (demo) checkout completes, exactly
/// like a Tables hold. Free claims skip it: claim → confirmed.
enum EventTicketStatus {
  held,
  confirmed,
  checkedIn,
  cancelled,
}

/// One club/event night on the Tickets board (MASTER-BUILD-PLAN T1):
/// social clubs, nightlife clubs, live music, comedy, members clubs,
/// supper clubs — every kind of club night verified members go to.
///
/// VENUES are named here on purpose (unlike Tables' late reveal, a
/// club night is browsed by venue). Capacity is ONE pool per night:
/// free and premium tickets draw from the same room.
class ClubNight {
  const ClubNight({
    required this.id,
    required this.title,
    required this.categoryLabel,
    required this.venueName,
    required this.areaLabel,
    required this.dateLabel,
    required this.timeLabel,
    required this.vibeLabel,
    required this.capacity,
    required this.claimedSeats,
    required this.seller,
    this.offersFree = true,
    this.premiumPrice,
    this.premiumPerks = const [],
    this.serviceFeePerTicket = 0,
  });

  final String id;

  /// The night's name ('Velvet Room Saturdays').
  final String title;

  /// 'Social club social' / 'Nightlife club night' / 'Live music' /
  /// 'Comedy night' / 'Members club evening' / 'Supper club'.
  final String categoryLabel;

  /// The venue's public name — browsed, never hidden.
  final String venueName;

  /// Neighbourhood ('Short North').
  final String areaLabel;

  /// 'Fri · Nov 20'
  final String dateLabel;

  /// '19:00' — doors/first set, as the venue states it.
  final String timeLabel;

  /// The crowd the night is for ('House & disco edits').
  final String vibeLabel;

  /// Total room capacity across BOTH tiers.
  final int capacity;

  /// Tickets already taken at seed time (other members). The store
  /// tracks the signed-in member's tickets on top — see
  /// AppStore.eventSeatsLeft.
  final int claimedSeats;

  /// Who sells this night (drives the fee presentation).
  final TicketSeller seller;

  /// Free (RSVP) tickets offered. A supper club can be premium-only.
  final bool offersFree;

  /// Premium per-ticket price in USD; null = no premium tier (a
  /// free-only night).
  final int? premiumPrice;

  /// What premium buys, as the venue defines it ('Priority entry',
  /// 'Hosted table', 'Welcome drink credit'). Data, not promises the
  /// app invents.
  final List<String> premiumPerks;

  /// Cariño's transparent service fee per premium ticket, in USD —
  /// OUR events only. Partner nights are 0 and render no fee line at
  /// all (affiliate model: the partner pays us, the member doesn't).
  final int serviceFeePerTicket;

  bool get offersPremium => premiumPrice != null;
}

/// The price of an order, broken down BEFORE anyone confirms — the
/// money is never a surprise after the tap (the plan's money rule).
class TicketQuote {
  const TicketQuote({
    required this.unitPrice,
    required this.serviceFeePerTicket,
    required this.quantity,
    required this.seller,
  });

  /// Per-ticket price (0 for the free tier).
  final int unitPrice;

  /// Per-ticket service fee actually charged (0 for free tier AND for
  /// partner nights — the fee exists only on our own premium sales).
  final int serviceFeePerTicket;

  final int quantity;
  final TicketSeller seller;

  int get subtotal => unitPrice * quantity;
  int get feeTotal => serviceFeePerTicket * quantity;
  int get total => subtotal + feeTotal;

  /// True when a fee line belongs in the breakdown at all.
  bool get hasFeeLine => feeTotal > 0;
}

/// One of the signed-in member's tickets — free claim, premium order,
/// or the held state in between. Session state owned by the AppStore,
/// like TableBooking.
class EventTicket {
  EventTicket({
    required this.id,
    required this.nightId,
    required this.tier,
    required this.quantity,
    required this.totalPrice,
    required this.status,
  });

  final String id;
  final String nightId;
  final TicketTier tier;
  final int quantity;

  /// What the member pays in total (premium: price + fee, computed by
  /// the store's quote at order time; free: always 0).
  final int totalPrice;

  EventTicketStatus status;

  /// Seats this ticket still holds against the night's capacity.
  /// Cancelled tickets hold nothing; every other state does (a
  /// checked-in guest was in the room).
  bool get consumesCapacity => status != EventTicketStatus.cancelled;

  bool get isActive =>
      status == EventTicketStatus.held ||
      status == EventTicketStatus.confirmed ||
      status == EventTicketStatus.checkedIn;
}
