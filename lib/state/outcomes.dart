import '../models/agent.dart';
import '../models/circle.dart';
import '../models/plan.dart';
import '../models/presence.dart';

/// Wave 4 · Outcome Graph aggregation (MASTER-BUILD-PLAN A3/A4).
/// Pure logic, no Flutter imports — the Presence dashboard and the
/// host standing line are computed FROM the records, so the math is
/// unit-testable and a number on screen can always be re-derived.

/// The host standing line (A3): total hosted plans from the real plan
/// list, happened-count from outcome records ONLY. Before any guest
/// has checked in, the line says so — a host is never credited with
/// outcomes nobody recorded.
String hostOutcomeLineText({
  required int hosted,
  required int recorded,
  required int happened,
}) {
  if (hosted <= 0) return 'No plans hosted yet';
  if (recorded <= 0) {
    return '$hosted plan${hosted == 1 ? '' : 's'} hosted · no check-ins yet';
  }
  return '$hosted plan${hosted == 1 ? '' : 's'} hosted · '
      '$happened happened';
}

/// Everything the Presence dashboard (A4) renders, computed from real
/// store records. All zeros + [hasAnyRecords] false is the honest
/// empty state — the UI renders an explainer, never invented stats.
class PresenceDashboardStats {
  const PresenceDashboardStats({
    required this.phoneDownMinutes,
    required this.offlineMinutes,
    required this.plansAttended,
    required this.tablesAttended,
    required this.eventsAttended,
    required this.presenceScoresChronological,
    required this.circleNames,
  });

  /// Minutes the phone stayed down (PresenceRecords).
  final int phoneDownMinutes;

  /// The north-star number: time spent with people, not on the app.
  /// = phone-down minutes + the full duration of attended plans that
  /// have NO phone-down record (a plan WITH a record contributes its
  /// phone-down minutes only — never counted twice).
  final int offlineMinutes;

  /// Plans I checked in as happened (great/fine).
  final int plansAttended;

  /// Tables nights I checked in as happened.
  final int tablesAttended;

  /// Club nights I checked in as happened.
  final int eventsAttended;

  /// Presence Scores oldest → newest (records are stored newest
  /// first; the trend reads forward in time).
  final List<int> presenceScoresChronological;

  /// Names of the Circles I'm a member of.
  final List<String> circleNames;

  int get latestPresenceScore =>
      presenceScoresChronological.isEmpty
          ? 0
          : presenceScoresChronological.last;

  int get averagePresenceScore => presenceScoresChronological.isEmpty
      ? 0
      : (presenceScoresChronological.fold(0, (a, b) => a + b) /
              presenceScoresChronological.length)
          .round();

  int get circlesCount => circleNames.length;

  /// True when there is anything real to show (a phone-down record
  /// or an outcome record). Drives the honest empty state.
  bool get hasAnyRecords =>
      presenceScoresChronological.isNotEmpty ||
      plansAttended > 0 ||
      tablesAttended > 0 ||
      eventsAttended > 0;
}

/// Aggregates the dashboard from the store's real lists.
PresenceDashboardStats computeDashboardStats({
  required List<PresenceRecord> presenceRecords,
  required List<OutcomeRecord> outcomeRecords,
  required List<OpenPlan> plans,
  required List<PrivateCircle> myCircles,
}) {
  final phoneDown = presenceRecords.fold(
      0, (sum, r) => sum + r.phoneDownMinutes);
  final plansWithPresence = presenceRecords.map((r) => r.planId).toSet();

  var plansAttended = 0;
  var attendedMinutes = 0;
  var tablesAttended = 0;
  var eventsAttended = 0;
  for (final record in outcomeRecords) {
    if (!record.rating.happened) continue;
    switch (record.subjectKind) {
      case OutcomeSubjectKind.plan:
        plansAttended++;
        if (!plansWithPresence.contains(record.subjectId)) {
          for (final p in plans) {
            if (p.id == record.subjectId) {
              attendedMinutes += p.durationMinutes;
            }
          }
        }
      case OutcomeSubjectKind.table:
        tablesAttended++;
      case OutcomeSubjectKind.ticket:
        eventsAttended++;
    }
  }

  return PresenceDashboardStats(
    phoneDownMinutes: phoneDown,
    offlineMinutes: phoneDown + attendedMinutes,
    plansAttended: plansAttended,
    tablesAttended: tablesAttended,
    eventsAttended: eventsAttended,
    presenceScoresChronological:
        presenceRecords.reversed.map((r) => r.score).toList(),
    circleNames: myCircles.map((c) => c.name).toList(),
  );
}

/// '2h 35m' / '45m' — the dashboard's offline-time format.
String formatOfflineMinutes(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}
