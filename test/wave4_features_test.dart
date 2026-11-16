// Wave 4 · Agent layer tests (MASTER-BUILD-PLAN A1–A4).
//
// Every number here is pinned against the REAL seed data in
// lib/data/mock_data.dart, read from the files — the Wave 1 lesson
// applies: never trust a secondhand description of the seeds.
//
// Seed facts these tests rely on (verified from mock_data.dart):
// - Table nights in seed order: tn-thu-19 'Thu · Nov 19' Short North,
//   $24/seat, 17/24 booked (seats left at tables: 24-17 = 7 seats
//   across tables of 6); tn-fri-20 SOLD OUT; tn-thu-26 $29, 9/24;
//   tn-sat-28 $19, 3/12.
// - Decompress plans: op-priya-parkwalk (park walk, calm), op-aria-
//   garden, op-dev-lakeside, op-sofia-yoga (tonight). Seed order in
//   openPlans: park walk is FIRST among decompress plans.
// - Past plans (Wave 4): op-dev-boardgames (host m-dev, I'm going,
//   150 min) and op-me-riverwalk (hosted by me, 90 min).
// - Past Table: tn-thu-12 'Thu · Nov 12', $24. Past club night:
//   cn-riverbend-sat 'Riverbend Listening Night'.
// - Seeded PresenceRecord: plan-2, 74 phone-down of 90 min, group 2,
//   score 73.
// - Members: Aria (casualDating like me; interests Photography,
//   Indie films, Farmers markets, Vinyl; prompt mentions Coffee —
//   my interest — and Live music is not in her text), Sofia
//   (hangoutAndPlay; interests Board games, Karaoke, Bouldering,
//   Comedy shows).
// - My circles: circle-arcade 'Arcade Crew', circle-garden
//   'Garden & Chai Club'.

import 'package:carino/models/agent.dart';
import 'package:carino/models/plan.dart';
import 'package:carino/screens/connect/concierge_screen.dart';
import 'package:carino/screens/connect/outcome_checkin_screen.dart';
import 'package:carino/state/app_store.dart';
import 'package:carino/state/concierge.dart';
import 'package:carino/state/outcomes.dart';
import 'package:carino/state/pre_screen.dart';
import 'package:carino/data/mock_data.dart';
import 'package:carino/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('A1 · Concierge intent parsing', () {
    test('dinner + group size + tonight parse from plain words', () {
      final intent = parseConciergeIntent('Dinner Friday, quiet, 4 of us');
      expect(intent.dinner, isTrue);
      expect(intent.groupSize, 4);
    });

    test('calm outdoors parse; "night out" is nightlife, not tonight', () {
      final calm = parseConciergeIntent('Something calm outdoors Sunday');
      expect(calm.calm, isTrue);
      expect(calm.dinner, isFalse);
      final nightOut = parseConciergeIntent('a night out with friends');
      expect(nightOut.nightlife, isTrue);
      expect(nightOut.tonight, isFalse);
    });

    test('free + club words parse', () {
      final intent = parseConciergeIntent('any free club nights?');
      expect(intent.nightlife, isTrue);
      expect(intent.wantsFree, isTrue);
    });
  });

  group('A1 · Concierge proposals', () {
    test('dinner intent leads with a real Table night at a real price',
        () {
      final store = AppStore();
      final proposals =
          conciergeProposals(store, 'Dinner Friday, quiet, 4 of us');
      expect(proposals.length, lessThanOrEqualTo(3));
      final first = proposals.first;
      expect(first.kind, ConciergeProposalKind.table);
      // First night in seed order with room: tn-thu-19, $24/seat × 4.
      expect(first.refId, 'tn-thu-19');
      expect(first.priceLabel, '\$96 total · 4 seats');
      expect(first.whyLine, contains('room for your 4'));
      // Every refId must resolve to a real store object.
      for (final p in proposals) {
        if (p.kind == ConciergeProposalKind.table) {
          expect(store.tableNightById(p.refId!), isNotNull);
        } else if (p.kind == ConciergeProposalKind.plan) {
          expect(store.planById(p.refId!), isNotNull);
        } else if (p.kind == ConciergeProposalKind.ticket) {
          expect(store.clubNightById(p.refId!), isNotNull);
        }
      }
    });

    test('calm intent leads with a real Decompress plan', () {
      final store = AppStore();
      final proposals =
          conciergeProposals(store, 'Something calm outdoors Sunday');
      final first = proposals.first;
      expect(first.kind, ConciergeProposalKind.plan);
      final plan = store.planById(first.refId!)!;
      expect(plan.decompress, isTrue);
      // First decompress plan in seed order.
      expect(plan.id, 'op-priya-parkwalk');
      expect(first.whyLine, contains('Decompress'));
    });

    test('club intent leads with a club night, never a sold-out one',
        () {
      final store = AppStore();
      final proposals = conciergeProposals(store, 'Club night Saturday');
      final ticket = proposals.firstWhere(
          (p) => p.kind == ConciergeProposalKind.ticket);
      expect(ticket.refId, isNot('cn-bluenote-thu')); // sold out
      final night = store.clubNightById(ticket.refId!)!;
      expect(store.eventNightSoldOut(night), isFalse);
    });

    test('a query with no matching words still offers the draft', () {
      final store = AppStore();
      final proposals =
          conciergeProposals(store, 'underwater basket weaving');
      expect(
        proposals.any((p) => p.kind == ConciergeProposalKind.newPlan),
        isTrue,
      );
      // And no arbitrary plan is dressed up as a match.
      expect(
        proposals.where((p) => p.kind == ConciergeProposalKind.plan),
        isEmpty,
      );
    });
  });

  group('A1 · Concierge execution books the real thing', () {
    test('booking a Table proposal creates a real confirmed booking',
        () {
      final store = AppStore();
      final proposals =
          conciergeProposals(store, 'Dinner Friday, quiet, 4 of us');
      final table = proposals.first;
      final result = executeConciergeProposal(store, table);
      expect(result.ok, isTrue);
      expect(store.tableBooking, isNotNull);
      expect(store.tableBooking!.nightId, 'tn-thu-19');
      expect(store.tableBooking!.seats, 4);
      expect(store.tableBooking!.totalPrice, 24 * 4);
      expect(store.tableBooking!.status.name, 'confirmed');
      expect(store.lastConciergeBooking, isNotNull);
      expect(result.priceLabel, '\$96 total');
      expect(result.reminderLabel, contains('Reminder set'));
      // Booking the same Table again refuses honestly (one active
      // booking per member) instead of double-booking.
      final again = executeConciergeProposal(store, table);
      expect(again.ok, isFalse);
      expect(again.headline, contains('already'));
    });

    test('joining a plan proposal moves the real join state', () {
      final store = AppStore();
      final proposals =
          conciergeProposals(store, 'Something calm outdoors Sunday');
      final planProposal = proposals.first;
      expect(store.planById(planProposal.refId!)!.myState,
          PlanJoinState.none);
      final result = executeConciergeProposal(store, planProposal);
      expect(result.ok, isTrue);
      expect(store.planById(planProposal.refId!)!.myState,
          PlanJoinState.going);
    });

    test('a new-plan proposal creates a real plan hosted by me', () {
      final store = AppStore();
      final before = store.openPlans.length;
      final proposals =
          conciergeProposals(store, 'underwater basket weaving');
      final draft = proposals
          .firstWhere((p) => p.kind == ConciergeProposalKind.newPlan);
      final result = executeConciergeProposal(store, draft);
      expect(result.ok, isTrue);
      expect(store.openPlans.length, before + 1);
      final created = store.openPlans.last;
      expect(created.hostedByMe, isTrue);
      expect(created.attendeeIds, contains('me'));
    });

    test('a ticket proposal claims a real ticket into My Tickets', () {
      final store = AppStore();
      final proposals = conciergeProposals(store, 'any free club nights?');
      final ticket = proposals
          .firstWhere((p) => p.kind == ConciergeProposalKind.ticket);
      final result = executeConciergeProposal(store, ticket);
      expect(result.ok, isTrue);
      expect(
        store.myTickets.any((t) => t.nightId == ticket.refId),
        isTrue,
      );
    });
  });

  group('A2 · Agent Pre-Screen', () {
    final me = MockData.currentUser;
    final aria = MockData.memberById('m-aria');
    final sofia = MockData.memberById('m-sofia');

    test('Aria: verified, intentions aligned, real shared signals', () {
      final s = buildPreScreen(me: me, other: aria, blockedIds: {});
      expect(s.verified, isTrue);
      expect(s.intentionAligned, isTrue); // both casualDating
      expect(s.intentionLine, contains('Casual Dating'));
      expect(s.canChat, isTrue);
      // 'Coffee' is MY interest and appears in Aria's prompt answer —
      // a mention signal, labelled as such.
      expect(
        s.sharedSignals.any((line) => line.contains('Coffee')),
        isTrue,
      );
      expect(s.sharedSignals, contains('Both in Columbus'));
      expect(s.safety, PreScreenSafety.clear);
    });

    test('Sofia: different intention is stated plainly, not hidden', () {
      final s = buildPreScreen(me: me, other: sofia, blockedIds: {});
      expect(s.intentionAligned, isFalse);
      expect(s.intentionLine, contains('Hangout & Play'));
      expect(s.canChat, isTrue); // unaligned ≠ blocked; human decides
    });

    test('a blocked member cannot chat — the card closes the gate', () {
      final s =
          buildPreScreen(me: me, other: aria, blockedIds: {'m-aria'});
      expect(s.safety, PreScreenSafety.blocked);
      expect(s.canChat, isFalse);
      expect(s.safetyLine, contains('blocked'));
    });
  });

  group('A3 · Outcome Graph', () {
    test('a fresh store has four subjects awaiting check-in', () {
      final store = AppStore();
      final pending = store.pendingOutcomePrompts();
      expect(pending.length, 4);
      expect(
        pending.map((p) => p.subjectId),
        containsAll([
          'op-dev-boardgames',
          'op-me-riverwalk',
          'tn-thu-12',
          'cn-riverbend-sat',
        ]),
      );
    });

    test('recording an outcome feeds the host line math', () {
      final store = AppStore();
      expect(store.hostOutcomeLine('m-dev'),
          '3 plans hosted · no check-ins yet');
      final record = store.recordOutcome(
        kind: OutcomeSubjectKind.plan,
        subjectId: 'op-dev-boardgames',
        rating: OutcomeRating.great,
      );
      expect(record, isNotNull);
      expect(store.hostRecordedCount('m-dev'), 1);
      expect(store.hostHappenedCount('m-dev'), 1);
      expect(store.hostOutcomeLine('m-dev'), '3 plans hosted · 1 happened');
      // The prompt leaves the pending list.
      expect(
        store
            .pendingOutcomePrompts()
            .any((p) => p.subjectId == 'op-dev-boardgames'),
        isFalse,
      );
    });

    test('a duplicate check-in refuses — one record per subject', () {
      final store = AppStore();
      store.recordOutcome(
        kind: OutcomeSubjectKind.table,
        subjectId: 'tn-thu-12',
        rating: OutcomeRating.fine,
      );
      final dup = store.recordOutcome(
        kind: OutcomeSubjectKind.table,
        subjectId: 'tn-thu-12',
        rating: OutcomeRating.great,
      );
      expect(dup, isNull);
      expect(store.outcomeRecords.length, 1);
    });

    test('future plans and unknown subjects refuse', () {
      final store = AppStore();
      expect(
        store.recordOutcome(
          kind: OutcomeSubjectKind.plan,
          subjectId: 'op-sofia-arcade', // a FUTURE plan
          rating: OutcomeRating.great,
        ),
        isNull,
      );
      expect(
        store.recordOutcome(
          kind: OutcomeSubjectKind.plan,
          subjectId: 'op-does-not-exist',
          rating: OutcomeRating.great,
        ),
        isNull,
      );
      // A bookable future Table night is not an outcome subject.
      expect(
        store.recordOutcome(
          kind: OutcomeSubjectKind.table,
          subjectId: 'tn-thu-19',
          rating: OutcomeRating.great,
        ),
        isNull,
      );
    });

    test('"didn\'t happen" records but never counts as happened', () {
      final store = AppStore();
      store.recordOutcome(
        kind: OutcomeSubjectKind.plan,
        subjectId: 'op-me-riverwalk',
        rating: OutcomeRating.didntHappen,
      );
      expect(store.hostRecordedCount('me'), 1);
      expect(store.hostHappenedCount('me'), 0);
      expect(store.hostOutcomeLine('me'), '1 plan hosted · 0 happened');
    });
  });

  group('A4 · Presence Dashboard aggregation', () {
    test('fresh store: seeded phone-down record only', () {
      final store = AppStore();
      final stats = store.dashboardStats;
      expect(stats.phoneDownMinutes, 74);
      expect(stats.offlineMinutes, 74); // no attended plans yet
      expect(stats.plansAttended, 0);
      expect(stats.tablesAttended, 0);
      expect(stats.presenceScoresChronological, [73]);
      expect(stats.latestPresenceScore, 73);
      expect(stats.circleNames,
          containsAll(['Arcade Crew', 'Garden & Chai Club']));
      expect(stats.hasAnyRecords, isTrue);
    });

    test('attended plans add their full durations to offline time', () {
      final store = AppStore();
      store.recordOutcome(
        kind: OutcomeSubjectKind.plan,
        subjectId: 'op-dev-boardgames', // 150 min
        rating: OutcomeRating.great,
      );
      store.recordOutcome(
        kind: OutcomeSubjectKind.plan,
        subjectId: 'op-me-riverwalk', // 90 min
        rating: OutcomeRating.fine,
      );
      store.recordOutcome(
        kind: OutcomeSubjectKind.table,
        subjectId: 'tn-thu-12',
        rating: OutcomeRating.great,
      );
      final stats = store.dashboardStats;
      expect(stats.plansAttended, 2);
      expect(stats.tablesAttended, 1);
      // 74 phone-down + 150 + 90 attended = 314.
      expect(stats.offlineMinutes, 314);
    });

    test('empty inputs aggregate to the honest empty state', () {
      final stats = computeDashboardStats(
        presenceRecords: const [],
        outcomeRecords: const [],
        plans: const [],
        myCircles: const [],
      );
      expect(stats.hasAnyRecords, isFalse);
      expect(stats.offlineMinutes, 0);
      expect(stats.plansAttended, 0);
      expect(stats.presenceScoresChronological, isEmpty);
    });

    test('offline format reads like a duration', () {
      expect(formatOfflineMinutes(45), '45m');
      expect(formatOfflineMinutes(60), '1h');
      expect(formatOfflineMinutes(314), '5h 14m');
    });
  });

  group('Wave 4 · widget flows', () {
    // These two tests render against the Services.store singleton
    // (final, per services.dart) — the file's unit tests above all
    // use their own AppStore() instances, so the singleton is still
    // in its fresh seeded state when these run, in this order.
    testWidgets('outcome check-in lists the past subjects',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const OutcomeCheckInScreen(),
        ),
      );
      await tester.pump();
      expect(find.text('Board-game night — the rematch'), findsOneWidget);
      expect(find.text('Riverwalk + coffee crawl'), findsOneWidget);
      expect(find.text('Did it happen?'), findsWidgets);
    });

    testWidgets('concierge proposes from typed words', (tester) async {
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const ConciergeScreen(),
        ),
      );
      await tester.pump();
      await tester.enterText(
          find.byType(TextField), 'Dinner Friday, quiet, 4 of us');
      await tester.tap(find.text('Plan it'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('Short North'), findsWidgets);
      expect(find.textContaining('\$96 total'), findsWidgets);
      // The honest demo-brain label is on screen.
      expect(find.textContaining('demo brain'), findsOneWidget);
      // Flush the proposal cards' fade-in timers before teardown.
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
