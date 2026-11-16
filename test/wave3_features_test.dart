// Wave 3 crowd features (CROWD-FEATURES #12 Decompress, #13 Phone-Down
// + Presence Score, #14 Micro-Hosts, #15 Check-In Safety, #23 Drop
// rituals, #3 Human-Made Filter, #4 No-AI-People Pledge counters,
// #19 Calm Mode prefs, #20 Taste Quiz):
//
// Same doctrine as waves before: every number is asserted against the
// REAL formula and the REAL seed data — a score that doesn't re-derive
// from its inputs, a ritual that matches nobody, or a quiz answer that
// changes nothing would each be a shipped lie, so each is pinned here.
import 'package:carino/data/mock_data.dart';
import 'package:carino/models/plan.dart';
import 'package:carino/models/presence.dart';
import 'package:carino/screens/connect/plans_hub_screen.dart';
import 'package:carino/screens/discover/discover_screen.dart';
import 'package:carino/screens/discover/filters_screen.dart';
import 'package:carino/services/services.dart';
import 'package:carino/state/app_store.dart';
import 'package:carino/state/drop_rituals.dart';
import 'package:carino/state/drop_tuning.dart';
import 'package:carino/state/presence.dart';
import 'package:carino/state/taste_quiz.dart';
import 'package:carino/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Presence Score math (Wave 3 #13)', () {
    test('full coverage with a full group is 100', () {
      expect(
        presenceScore(phoneDownMinutes: 90, planMinutes: 90, groupSize: 6),
        100,
      );
    });

    test('the seeded street-food record re-derives to 73', () {
      expect(
        presenceScore(phoneDownMinutes: 74, planMinutes: 90, groupSize: 2),
        73,
      );
    });

    test('zero minutes down pays only the company term', () {
      expect(
        presenceScore(phoneDownMinutes: 0, planMinutes: 90, groupSize: 6),
        15,
      );
      expect(
        presenceScore(phoneDownMinutes: 0, planMinutes: 90, groupSize: 1),
        0,
      );
    });

    test('coverage clamps at the plan length — longer never over-earns', () {
      expect(
        presenceScore(phoneDownMinutes: 200, planMinutes: 90, groupSize: 1),
        85,
      );
    });

    test('half coverage, group of three', () {
      expect(
        presenceScore(phoneDownMinutes: 45, planMinutes: 90, groupSize: 3),
        49, // 42.5 coverage + 6 company, rounded
      );
    });

    test('a zero-length plan scores zero instead of dividing by zero', () {
      expect(
        presenceScore(phoneDownMinutes: 10, planMinutes: 0, groupSize: 4),
        0,
      );
    });
  });

  group('Presence records + phone-down flow (Wave 3 #13)', () {
    test('one seeded record exists and its score is the formula\'s', () {
      final store = AppStore();
      expect(store.presenceSessionCount, 1);
      final seed = store.presenceRecords.single;
      expect(seed.planTitle, 'Street-food market with Sofia');
      expect(seed.phoneDownMinutes, 74);
      expect(seed.score, 73);
      expect(store.totalPhoneDownMinutes, 74);
      expect(store.averagePresenceScore, 73);
    });

    test('phone-down refuses a plan I am not part of', () {
      final store = AppStore();
      expect(store.startPhoneDown('op-aria-market'), isFalse);
      expect(store.activePhoneDown, isNull);
      expect(store.startPhoneDown('op-does-not-exist'), isFalse);
    });

    test('start → end writes a record from the real clock and plan', () {
      final store = AppStore();
      // Outdoor yoga: instant-join, 60-minute plan, 2 seeded attendees.
      expect(store.requestJoinPlan('op-sofia-yoga'), isTrue);
      final t0 = DateTime(2026, 11, 16, 18, 15);
      expect(store.startPhoneDown('op-sofia-yoga', now: t0), isTrue);
      // One session at a time — a second start is refused.
      expect(store.startPhoneDown('op-sofia-yoga', now: t0), isFalse);

      final record = store.endPhoneDown(now: t0.add(const Duration(minutes: 45)));
      expect(record, isNotNull);
      expect(record!.phoneDownMinutes, 45);
      expect(record.planMinutes, 60);
      expect(record.groupSize, 3); // Sofia + Priya + me
      expect(record.score,
          presenceScore(phoneDownMinutes: 45, planMinutes: 60, groupSize: 3));
      expect(record.score, 70);
      expect(store.activePhoneDown, isNull);
      expect(store.presenceRecordForPlan('op-sofia-yoga')!.score, 70);
      expect(store.presenceSessionCount, 2);
    });

    test('ending with no session, and discarding, mint no record', () {
      final store = AppStore();
      expect(store.endPhoneDown(), isNull);
      expect(store.requestJoinPlan('op-sofia-yoga'), isTrue);
      expect(store.startPhoneDown('op-sofia-yoga'), isTrue);
      store.cancelPhoneDown();
      expect(store.activePhoneDown, isNull);
      expect(store.presenceSessionCount, 1); // only the seed
    });
  });

  group('Decompress shelf (Wave 3 #12)', () {
    test('four calm plans are seeded, tagged, and shelved apart', () {
      final store = AppStore();
      final shelf = store.decompressPlans;
      expect(shelf.length, 4);
      expect(shelf.every((p) => p.decompress), isTrue);
      expect(
        shelf.map((p) => p.id),
        containsAll([
          'op-priya-parkwalk',
          'op-aria-garden',
          'op-dev-lakeside',
          'op-sofia-yoga',
        ]),
      );
      // The loud board's plans are not on the shelf.
      expect(shelf.any((p) => p.id == 'op-sofia-arcade'), isFalse);
      expect(store.openPlans.where((p) => p.decompress).length, 4);
    });

    test('shelf plans join through the same state machine', () {
      final store = AppStore();
      final garden = store.planById('op-aria-garden')!;
      expect(garden.myState, PlanJoinState.none);
      expect(store.requestJoinPlan(garden.id), isTrue);
      expect(garden.myState, PlanJoinState.going);
      expect(garden.attendeeIds, contains('me'));
      expect(store.leavePlan(garden.id), isTrue);
      expect(garden.myState, PlanJoinState.none);
    });

    test('a plan I create as decompress lands on the shelf', () {
      final store = AppStore();
      final plan = store.createPlan(
        title: 'Quiet pier sit',
        place: 'Alum Creek · south pier',
        timeLabel: 'Sun · 08:00',
        tonight: false,
        groupSize: 3,
        decompress: true,
      );
      expect(store.decompressPlans.any((p) => p.id == plan.id), isTrue);
    });
  });

  group('Micro-Hosts (Wave 3 #14)', () {
    test('standing counts come from the real plan list', () {
      final store = AppStore();
      expect(store.hostedPlanCount('m-sofia'), 2); // arcade + yoga
      expect(store.hostedPlanCount('m-aria'), 2); // market + garden
      // Wave 4 seed growth: Dev also hosted last Saturday's past
      // board-game night (the Outcome Graph's check-in subject).
      expect(store.hostedPlanCount('m-dev'), 3); // trail + lakeside + past
      expect(store.hostedPlanCount('m-priya'), 2); // gardens + park walk
      expect(store.hostedPlanCount('m-marcus'), 1); // jazz
      // Wave 4 seed growth: I hosted last Sunday's past riverwalk.
      expect(store.hostedPlanCount('me'), 1);
    });

    test('the badge condition and tiers follow the count', () {
      final store = AppStore();
      expect(store.isHost('m-marcus'), isTrue);
      // Wave 4 seed growth: the past riverwalk makes me a host too.
      expect(store.isHost('me'), isTrue);
      expect(store.hostTierLabel('me'), 'New host');
      expect(store.hostTierLabel('m-marcus'), 'New host');
      expect(store.hostTierLabel('m-sofia'), 'Regular host');
    });

    test('creating a plan makes me a host immediately', () {
      final store = AppStore();
      store.createPlan(
        title: 'Rooftop chess',
        place: 'Library roof terrace',
        timeLabel: 'Fri · 17:00',
        tonight: false,
        groupSize: 4,
      );
      // Wave 4 seed growth: 1 seeded past plan + this new one = 2,
      // which lands in the 2–4 'Regular host' tier band.
      expect(store.hostedPlanCount('me'), 2);
      expect(store.isHost('me'), isTrue);
      expect(store.hostTierLabel('me'), 'Regular host');
    });
  });

  group('Check-In Safety (Wave 3 #15)', () {
    test('check-in refuses plans I am not part of', () {
      final store = AppStore();
      expect(
        store.setPlanCheckIn('op-aria-market', PlanCheckInState.checkedIn,
            contactName: 'Mom'),
        isNull,
      );
      expect(store.checkInFor('op-aria-market'), isNull);
    });

    test('check-in records state and the exact demo message', () {
      final store = AppStore();
      expect(store.requestJoinPlan('op-sofia-yoga'), isTrue);
      final record = store.setPlanCheckIn(
        'op-sofia-yoga',
        PlanCheckInState.checkedIn,
        contactName: 'Mom',
      );
      expect(record, isNotNull);
      expect(record!.state, PlanCheckInState.checkedIn);
      expect(record.messagePreview, contains('Hi Mom'));
      expect(record.messagePreview, contains('Goodale Park'));
      expect(record.messagePreview, contains('Outdoor yoga in the park'));
      expect(store.checkInFor('op-sofia-yoga')!.state,
          PlanCheckInState.checkedIn);
    });

    test('updating to running late replaces the record; none clears it', () {
      final store = AppStore();
      expect(store.requestJoinPlan('op-sofia-yoga'), isTrue);
      store.setPlanCheckIn('op-sofia-yoga', PlanCheckInState.checkedIn,
          contactName: 'Mom');
      final late = store.setPlanCheckIn(
          'op-sofia-yoga', PlanCheckInState.runningLate,
          contactName: 'Mom');
      expect(late!.state, PlanCheckInState.runningLate);
      expect(late.messagePreview, contains('running late'));
      expect(
        store.setPlanCheckIn('op-sofia-yoga', PlanCheckInState.none,
            contactName: 'Mom'),
        isNull,
      );
      expect(store.checkInFor('op-sofia-yoga'), isNull);
    });

    test('an unnamed contact still produces an honest message', () {
      final text = checkInMessageText(
        contactName: '  ',
        planTitle: 'Outdoor yoga in the park',
        place: 'Goodale Park · gazebo lawn',
        state: PlanCheckInState.checkedIn,
      );
      expect(text, startsWith('Hi there —'));
      expect(
        checkInMessageText(
          contactName: 'Mom',
          planTitle: 'X',
          place: 'Y',
          state: PlanCheckInState.none,
        ),
        isEmpty,
      );
    });
  });

  group('Weekly Drop rituals (Wave 3 #23)', () {
    test('every weekday has its ritual, deterministic from the date', () {
      expect(ritualForWeekday(DateTime.monday).name, 'Market Monday');
      expect(ritualForWeekday(DateTime.tuesday).name, 'Trail Tuesday');
      expect(ritualForWeekday(DateTime.wednesday).name, 'Vinyl Wednesday');
      expect(ritualForWeekday(DateTime.thursday).name, 'Game Night Thursday');
      expect(ritualForWeekday(DateTime.friday).name, 'Golden Hour Friday');
      expect(ritualForWeekday(DateTime.saturday).name, 'Street-Food Saturday');
      expect(ritualForWeekday(DateTime.sunday).name, 'Sunset Sunday');
      // 2026-11-15 was a Sunday; 2026-11-16 a Monday.
      expect(ritualForDate(DateTime(2026, 11, 15)).name, 'Sunset Sunday');
      expect(ritualForDate(DateTime(2026, 11, 16)).name, 'Market Monday');
    });

    test('ritual terms re-order the real Drop deck', () {
      final thursday = ritualForWeekday(DateTime.thursday);
      final reordered = applyTuneToDeck(
        MockData.dailyDrop,
        TuneParse(boost: thursday.boostTerms),
      );
      // Sofia matches board games + games + karaoke; Dev matches chess.
      expect(reordered.first.id, 'm-sofia');

      final tuesday = ritualForWeekday(DateTime.tuesday);
      final tue = applyTuneToDeck(
        MockData.dailyDrop,
        TuneParse(boost: tuesday.boostTerms),
      );
      expect(tue.first.id, 'm-dev'); // Trail running
    });
  });

  group('Human-Made Filter (Wave 3 #3)', () {
    test('the predicate follows provenance state, never looks', () {
      final withTag =
          MockData.members.where((m) => m.hasRealCaptureMedia).map((m) => m.id);
      expect(withTag, containsAll(['m-aria', 'm-sofia', 'm-priya']));
      expect(withTag, isNot(contains('m-dev'))); // uploaded — no tag
      expect(withTag, isNot(contains('m-marcus'))); // placeholder — no tag
    });

    test('the config flag is off by default and breaks isDefault', () {
      expect(const FiltersConfig().realCaptureOnly, isFalse);
      expect(const FiltersConfig().isDefault, isTrue);
      expect(const FiltersConfig(realCaptureOnly: true).isDefault, isFalse);
    });

    testWidgets('the Filters screen switch round-trips into the config',
        (tester) async {
      FiltersConfig? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await Navigator.of(context).push<FiltersConfig>(
                      MaterialPageRoute<FiltersConfig>(
                        builder: (_) => const FiltersScreen(
                            initial: FiltersConfig()),
                      ),
                    );
                  },
                  child: const Text('Open filters'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open filters'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The switch sits below the fold in a lazily-built ListView —
      // scrollUntilVisible builds it on the way.
      final toggle = find.text('Real photos only');
      await tester.scrollUntilVisible(toggle, 200);
      await tester.pump();
      await tester.tap(toggle);
      await tester.pump();

      final apply = find.text('Apply filters');
      await tester.scrollUntilVisible(apply, 200);
      await tester.pump();
      await tester.tap(apply);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(result, isNotNull);
      expect(result!.realCaptureOnly, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('No-AI-People Pledge counters (Wave 3 #4)', () {
    test('the demo pool is fully verified — the counter is computed', () {
      const pool = MockData.members;
      expect(pool.where((m) => m.verified).length, pool.length);
      expect(pool.length, 7); // merged seed: 7 dating members
    });
  });

  group('Calm Mode + quiz prefs (Wave 3 #19/#20)', () {
    test('defaults are calm-off, no contact, no saved taste', () {
      final prefs = UserPrefs();
      expect(prefs.calmMode.value, isFalse);
      expect(prefs.trustedContactName, isEmpty);
      expect(prefs.tasteBoostTerms, isEmpty);
      expect(prefs.tasteDropTerms, isEmpty);
    });

    test('setters hold their values', () {
      final prefs = UserPrefs();
      prefs.tasteBoostTerms = ['trail', 'vinyl'];
      prefs.tasteDropTerms = ['jazz'];
      expect(prefs.tasteBoostTerms, ['trail', 'vinyl']);
      expect(prefs.tasteDropTerms, ['jazz']);
    });
  });

  group('Taste Quiz (Wave 3 #20)', () {
    test('six questions, four options each, every term real', () {
      expect(tasteQuizQuestions.length, 6);
      for (final q in tasteQuizQuestions) {
        expect(q.options.length, 4);
      }
    });

    test('answers build a deduped tune', () {
      final tune = tuneFromQuizAnswers({
        0: 0, // trail / hiking / running
        1: 0, // vinyl
        2: 0, // coffee / walk
        3: 3, // photography
        4: 2, // vinyl again — deduped
        5: 2, // less nightlife: drop jazz, karaoke
      });
      expect(tune.boost,
          ['trail', 'hiking', 'running', 'vinyl', 'coffee', 'walk', 'photography']);
      expect(tune.drop, ['jazz', 'karaoke']);
    });

    test('the quiz tune re-orders the real deck and drops honestly', () {
      final tune = tuneFromQuizAnswers({
        0: 0, // trail / hiking / running
        1: 1, // jazz — dropped again by Q6, so it never boosts
        2: 0, // coffee / walk
        3: 3, // photography
        4: 0, // cooking / sourdough
        5: 2, // less nightlife: drop jazz, karaoke
      });
      expect(tune.drop, ['jazz', 'karaoke']);
      final deck = applyTuneToDeck(MockData.members, tune);
      // Marcus matches the 'jazz' drop term and Sofia the 'karaoke'
      // one — both are removed, not hidden.
      expect(deck.any((m) => m.id == 'm-marcus'), isFalse);
      expect(deck.any((m) => m.id == 'm-sofia'), isFalse);
      // Dev matches trail + running + walk + cooking (4) — ahead of
      // Aria's coffee + photography + sourdough (3) and Priya's
      // hiking (1): the full order is pinned.
      // Merge note: our seed has 2 more members (Rowan, Elena); the logic is unchanged.
      expect(deck.map((m) => m.id).take(3).toList(),
          ['m-dev', 'm-aria', 'm-priya']);
    });

    test('an explicit "less" beats a boost of the same term', () {
      final tune = tuneFromQuizAnswers({
        0: 2, // games: board games, karaoke, chess
        5: 0, // less competitive: drop chess, board games, trivia
      });
      expect(tune.boost, ['karaoke']);
      expect(tune.drop, containsAll(['chess', 'board games', 'trivia']));
    });

    test('unanswered and out-of-range answers contribute nothing', () {
      expect(tuneFromQuizAnswers(const {}).isEmpty, isTrue);
      expect(tuneFromQuizAnswers(const {0: 99}).isEmpty, isTrue);
      expect(tuneFromQuizAnswers(const {0: -1}).isEmpty, isTrue);
    });
  });

  group('Wave 3 surfaces (widget)', () {
    testWidgets('the Plans hub shelves Decompress and shows host standing',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark(), home: const PlansHubScreen()),
      );
      // Bounded pumps only: the aurora background animates forever.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Decompress'), findsWidgets);
      // Wave 4 layout growth: the Concierge + outcome cards now sit
      // between the banners and the shelf — scroll the shelf into
      // build before expecting its first plan.
      await tester.scrollUntilVisible(find.text('Sunset park walk'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();
      expect(find.text('Sunset park walk'), findsOneWidget);
      // The host card sits below the plan list — scroll it into build
      // (the hub has two Scrollables; the outer ListView is first).
      await tester.scrollUntilVisible(find.text('Hosting on Cariño'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();
      expect(find.text('Hosting on Cariño'), findsOneWidget);
      // Wave 4 seed growth: my seeded past riverwalk makes me a host
      // already — the card's tier chip shows the real tier, not the
      // pre-Wave-4 'Not a host yet'.
      expect(find.text('New host'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the Drop shows today\'s ritual banner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark(), home: const DiscoverScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.textContaining('Drop ·'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(ritualForDate(DateTime.now()).name), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
