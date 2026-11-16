import '../models/presence.dart';

/// Wave 3 · Presence Score math + check-in message (CROWD-FEATURES #13,
/// #15). Pure logic, no Flutter imports — the score is a formula over
/// real inputs, unit-testable, and identical everywhere it is used
/// (session end, seed records, the Wave 4 dashboard later).

/// Computes a Presence Score, 0–100.
///
/// Two real terms, nothing else:
/// - **Coverage (85 pts):** the share of the plan the phone stayed down,
///   phoneDownMinutes / planMinutes, clamped to 1 — staying down LONGER
///   than the plan never earns more than full coverage.
/// - **Company (15 pts):** presence is presence WITH people. A group of
///   6+ earns the full term; a solo plan-down earns none of it (the
///   coverage term still pays out in full).
///
/// Worked examples (pinned by tests):
/// - 90 of 90 min, group of 6 → 100
/// - 74 of 90 min, group of 2 → 73
/// - 0 min, group of 6 → 15 (you showed up; the phone didn't go down)
/// - 0 min, solo → 0
int presenceScore({
  required int phoneDownMinutes,
  required int planMinutes,
  required int groupSize,
}) {
  if (planMinutes <= 0) return 0;
  final down = phoneDownMinutes < 0 ? 0 : phoneDownMinutes;
  final coverage = (down / planMinutes).clamp(0.0, 1.0);
  final company = ((groupSize - 1) / 5).clamp(0.0, 1.0);
  return (coverage * 85 + company * 15).round();
}

/// The exact text of the trusted-contact check-in message (CROWD-
/// FEATURES #15). DEMO RAIL: in the live app this sends by push/SMS to
/// the member's trusted contact; in this build it is previewed in the
/// check-in sheet and stored on the record — nothing leaves the phone,
/// and every surface that shows it says so.
String checkInMessageText({
  required String contactName,
  required String planTitle,
  required String place,
  required PlanCheckInState state,
}) {
  final who = contactName.trim().isEmpty ? 'there' : contactName.trim();
  return switch (state) {
    PlanCheckInState.checkedIn =>
      'Hi $who — I\'ve checked in at $place for "$planTitle". '
          'All good. — Cariño check-in',
    PlanCheckInState.runningLate =>
      'Hi $who — I\'m running late for "$planTitle" at $place, '
          'but I\'m on my way. — Cariño check-in',
    PlanCheckInState.none => '',
  };
}
