// Decompress (bookable stress-relief plans) + Phone-Down Mode.
// Pure Dart — tested in test/wellbeing_test.dart.

// ============================================================================
// Decompress shelf
// ============================================================================

/// How you're going: alone to reset, with your circle, as a date, or by
/// joining a small verified group already going at that time.
enum BookMode {
  solo('Solo reset'),
  circle('With my circle'),
  date('As a date'),
  group('Join a group');

  const BookMode(this.label);
  final String label;
}

class Experience {
  const Experience({
    required this.id,
    required this.title,
    required this.category,
    required this.venueType,
    required this.partner,
    required this.timeLabel,
    required this.durationMin,
    required this.priceCents,
    required this.spotsLeft,
    this.maxPeople = 8,
    this.groupGoing = 0,
    this.stepFree = false,
    this.phoneFree = false,
  });

  final String id;
  final String title;

  /// Walk · Water · Make · Move · Calm · Café · Sports · Spa
  final String category;

  /// Public venue TYPE (never a private address).
  final String venueType;

  /// The local partner that runs it and takes the booking.
  final String partner;
  final String timeLabel;
  final int durationMin;

  /// 0 = free.
  final int priceCents;
  final int spotsLeft;

  /// Most people one booking can include.
  final int maxPeople;

  /// Verified members already in the small group going at this time.
  final int groupGoing;
  final bool stepFree;

  /// Venue asks guests to keep phones away (pairs with Phone-Down Mode).
  final bool phoneFree;
}

List<Experience> filterExperiences(
  List<Experience> all, {
  String? category,
  BookMode? mode,
}) =>
    all.where((e) {
      if (category != null && e.category != category) return false;
      if (mode == BookMode.group && (e.groupGoing == 0 || e.spotsLeft == 0)) return false;
      if ((mode == BookMode.date || mode == BookMode.circle) && e.maxPeople < 2) return false;
      return true;
    }).toList();

bool canBook(Experience e, {required int people}) =>
    people >= 1 && people <= e.spotsLeft && people <= e.maxPeople;

/// Booking economics. The member pays the venue's listed price — no
/// Cariño markup; Cariño's commission comes out of the venue's side.
class BookingQuote {
  const BookingQuote(this.memberPaysCents, this.carinoEarnsCents, this.venueReceivesCents);
  final int memberPaysCents;
  final int carinoEarnsCents;
  final int venueReceivesCents;
}

BookingQuote quoteBooking({
  required int priceCents,
  required int people,
  required double commissionRate,
}) {
  if (people < 1) throw ArgumentError.value(people, 'people', 'must be ≥ 1');
  if (priceCents < 0) throw ArgumentError.value(priceCents, 'priceCents');
  final total = priceCents * people;
  final commission = (total * commissionRate).round();
  return BookingQuote(total, commission, total - commission);
}

// ============================================================================
// Phone-Down Mode — Presence
// ============================================================================

/// One person's Phone-Down session during a plan.
///
/// Honest measurement: time with the SCREEN LOCKED counts as present (the
/// phone is down). Leaving Cariño with the screen on (opening another app)
/// counts as a check-in, and that time as distracted. Apps can't lock other
/// apps without Screen Time / device-admin permissions, so this measures
/// rather than enforces.
class PresenceSession {
  PresenceSession({required this.startedAt});

  final DateTime startedAt;
  DateTime? _awayAt;
  bool _awayScreenOff = false;
  Duration _distracted = Duration.zero;
  int _checkIns = 0;

  bool get isAway => _awayAt != null;

  /// The app stopped being visible. [screenOff] = phone locked / screen off.
  void away(DateTime at, {required bool screenOff}) {
    if (_awayAt != null) return;
    _awayAt = at;
    _awayScreenOff = screenOff;
    if (!screenOff) _checkIns++;
  }

  void back(DateTime at) {
    final since = _awayAt;
    if (since == null) return;
    if (!_awayScreenOff) _distracted += at.difference(since);
    _awayAt = null;
  }

  PresenceResult end(DateTime at) {
    back(at);
    final total = at.difference(startedAt);
    return PresenceResult(total: total, distracted: _distracted, checkIns: _checkIns);
  }
}

class PresenceResult {
  const PresenceResult({
    required this.total,
    required this.distracted,
    required this.checkIns,
  });

  final Duration total;
  final Duration distracted;
  final int checkIns;

  Duration get present => total - distracted;

  /// 0–100: share of the plan spent phone-down.
  int get score => total.inSeconds == 0
      ? 100
      : (present.inSeconds * 100 / total.inSeconds).round();

  String get label {
    final h = present.inHours;
    final m = present.inMinutes % 60;
    final time = h > 0 ? '${h}h ${m}m' : '${m}m';
    final tail = checkIns == 0
        ? 'fully present'
        : '$checkIns check-in${checkIns == 1 ? '' : 's'}';
    return 'Phone down $time · $tail';
  }
}
