// Wave 1 crowd features (CROWD-FEATURES #2, #9, #10, #11, #17, #18):
// Tune My Drop parsing/matching, Cariño Tables booking state + no-show
// policy, Post→Plan join state, and Real Capture provenance gating.
//
// Same doctrine as the audit suite: the states are asserted against the
// REAL store and the REAL seed data — a booking that "succeeds" without
// state, a tune that re-orders nothing, or a tag that uploaded media can
// earn would each be a shipped lie, so each is pinned here.
import 'package:carino/data/mock_data.dart';
import 'package:carino/models/member.dart';
import 'package:carino/models/plan.dart';
import 'package:carino/state/app_store.dart';
import 'package:carino/state/drop_tuning.dart';
import 'package:flutter_test/flutter_test.dart';

Member _byId(String id) => MockData.memberById(id);

void main() {
  group('Tune My Drop — parsing (Wave 1 #17)', () {
    test('splits more/less into boost and drop terms', () {
      final tune = parseTuneText('more hiking and live music, less clubbing');
      expect(tune.boost, ['hiking', 'live music']);
      expect(tune.drop, ['clubbing']);
    });

    test('a leading "less …" boosts nothing', () {
      final tune = parseTuneText('less clubbing');
      expect(tune.boost, isEmpty);
      expect(tune.drop, ['clubbing']);
    });

    test('natural lead-ins are stripped ("show me more …")', () {
      final tune = parseTuneText('show me more hiking');
      expect(tune.boost, ['hiking']);
      expect(tune.drop, isEmpty);
    });

    test('empty input is an empty tune', () {
      expect(parseTuneText('').isEmpty, isTrue);
      expect(parseTuneText('   ').isEmpty, isTrue);
    });

    test('an explicit "less" beats a "more" for the same term', () {
      final tune = parseTuneText('more jazz, less jazz');
      expect(tune.boost, isEmpty);
      expect(tune.drop, ['jazz']);
    });
  });

  group('Tune My Drop — matching and re-ordering (Wave 1 #17)', () {
    test('boost terms pull matching members to the front, stably', () {
      final deck = [_byId('m-aria'), _byId('m-dev'), _byId('m-priya')];
      final tuned = applyTuneToDeck(deck, parseTuneText('more hiking'));
      // Priya lists Hiking; Aria and Dev do not — Priya leads, the
      // other two keep their relative order (stable, not shuffled).
      expect(tuned.map((m) => m.id).toList(),
          ['m-priya', 'm-aria', 'm-dev']);
    });

    test('drop terms remove matching members outright', () {
      final deck = [_byId('m-aria'), _byId('m-dev'), _byId('m-sofia')];
      final tuned = applyTuneToDeck(deck, parseTuneText('less chess'));
      expect(tuned.any((m) => m.id == 'm-dev'), isFalse,
          reason: 'Dev lists Chess — an explicit "less" must remove him');
      expect(tuned.length, 2);
    });

    test('an empty tune returns the deck untouched', () {
      final deck = [_byId('m-aria'), _byId('m-dev')];
      expect(applyTuneToDeck(deck, TuneParse.empty), deck);
    });

    test('matching reads real fields only (intention label counts)', () {
      final aria = _byId('m-aria'); // intention: Casual Dating
      expect(tuneTermMatches(aria, 'casual dating'), isTrue);
      expect(tuneTermMatches(aria, 'underwater basket weaving'), isFalse);
    });
  });

  group('Why you\'re seeing them (Wave 1 #18)', () {
    const me = MockData.currentUser; // Casual Dating · Tech/Coffee/Live music

    test('a shared interest is stated, from real overlap', () {
      // No seed member shares an interest with the demo user, so the
      // branch is pinned with a constructed member who shares Coffee.
      const coffeeFan = Member(
        id: 'x-coffee',
        name: 'Test',
        age: 26,
        city: 'Columbus',
        distanceBand: 'Same neighbourhood',
        intention: Intention.tonight,
        photoAsset: 'x',
        headline: 'x',
        prompts: [],
        interests: ['Coffee', 'Chess'],
        distanceMi: 1,
      );
      expect(whySeeingReason(coffeeFan, me: me), 'You both like Coffee');
    });

    test('the member\'s own tune outranks other signals', () {
      // Sofia lists Karaoke — tuning for it names the tune as the reason.
      final reason = whySeeingReason(
        _byId('m-sofia'),
        me: me,
        tune: parseTuneText('more karaoke'),
      );
      expect(reason, 'Because you tuned for karaoke');
    });

    test('same intention is the next fallback', () {
      // Aria shares no interest with the demo user but is also here for
      // Casual Dating.
      expect(whySeeingReason(_byId('m-aria'), me: me),
          'Also here for Casual Dating');
    });

    test('live availability follows, then plain proximity', () {
      // Sofia: different intention, no shared interest, online now.
      expect(whySeeingReason(_byId('m-sofia'), me: me),
          'Online now · Within a few miles in Dublin');
      // Marcus: different intention, nothing shared, offline.
      expect(whySeeingReason(_byId('m-marcus'), me: me),
          'Across town · Columbus · verified');
    });
  });

  group('Post→Plan — join state (Wave 1 #9/#10)', () {
    test('tonight feed holds exactly the tonight plans', () {
      final store = AppStore();
      // Wave 3 added a third Tonight plan (Sofia's Decompress yoga).
      expect(store.tonightPlans.length, 3);
      expect(store.tonightPlans.every((p) => p.tonight), isTrue);
    });

    test('createPlan hosts a plan I am already going to', () {
      final store = AppStore();
      final before = store.openPlans.length;
      final plan = store.createPlan(
        title: 'Gallery late opening',
        place: 'Gallery · Short North',
        timeLabel: 'Tonight · 20:30',
        tonight: true,
        groupSize: 4,
      );
      expect(store.openPlans.length, before + 1);
      expect(plan.hostedByMe, isTrue);
      expect(plan.myState, PlanJoinState.going);
      expect(plan.attendeeIds, ['me']);
      expect(store.tonightPlans.any((p) => p.id == plan.id), isTrue);
    });

    test('instant-join plan: RSVP lands me in the attendee list', () {
      final store = AppStore();
      final plan = store.planById('op-aria-market')!;
      expect(store.requestJoinPlan(plan.id), isTrue);
      expect(plan.myState, PlanJoinState.going);
      expect(plan.attendeeIds.contains('me'), isTrue);
      // Leaving releases the spot again.
      expect(store.leavePlan(plan.id), isTrue);
      expect(plan.myState, PlanJoinState.none);
      expect(plan.attendeeIds.contains('me'), isFalse);
    });

    test('host-approval plan: joining is a request, not a seat', () {
      final store = AppStore();
      final plan = store.planById('op-marcus-jazz')!;
      final attendeesBefore = plan.attendeeIds.length;
      expect(store.requestJoinPlan(plan.id), isTrue);
      expect(plan.myState, PlanJoinState.requested);
      expect(plan.attendeeIds.length, attendeesBefore,
          reason: 'a request must not consume a spot before approval');
    });

    test('a full plan refuses the join honestly', () {
      final store = AppStore();
      final plan = store.planById('op-priya-gardens')!;
      expect(plan.isFull, isTrue);
      expect(store.requestJoinPlan(plan.id), isFalse);
      expect(plan.myState, PlanJoinState.none);
    });
  });

  group('Cariño Tables — booking state (Wave 1 #11)', () {
    TableNight night(AppStore store, String id) => store.tableNightById(id)!;

    test('hold → confirm moves real state and takes the seats', () {
      final store = AppStore();
      final thu = night(store, 'tn-thu-19');
      final leftBefore = store.tableSeatsLeft(thu);

      final booking = store.holdTableSeat(thu, seats: 2);
      expect(booking, isNotNull);
      expect(booking!.status, TableBookingStatus.held);
      expect(booking.totalPrice, thu.seatPrice * 2);
      expect(store.tableSeatsLeft(thu), leftBefore - 2);

      expect(store.confirmTableBooking(), isTrue);
      expect(store.tableBooking!.status, TableBookingStatus.confirmed);
      // Confirming twice is not a thing.
      expect(store.confirmTableBooking(), isFalse);
    });

    test('one active booking at a time; cancel releases the seats', () {
      final store = AppStore();
      final thu = night(store, 'tn-thu-19');
      final sat = night(store, 'tn-sat-28');
      expect(store.holdTableSeat(thu), isNotNull);
      expect(store.holdTableSeat(sat), isNull,
          reason: 'a second hold while one is active must refuse');
      final leftBefore = store.tableSeatsLeft(thu);
      store.cancelTableBooking();
      expect(store.tableBooking, isNull);
      expect(store.tableSeatsLeft(thu), leftBefore + 1);
    });

    test('sold-out nights and over-asking refuse the hold', () {
      final store = AppStore();
      final soldOut = night(store, 'tn-fri-20');
      expect(store.tableSeatsLeft(soldOut), 0);
      expect(store.holdTableSeat(soldOut), isNull);
      final sat = night(store, 'tn-sat-28'); // 9 left
      expect(store.holdTableSeat(sat, seats: 10), isNull);
      expect(store.tableBooking, isNull);
    });

    test('no-show policy: warn, then ban — and a ban blocks booking', () {
      final store = AppStore();
      final thu = night(store, 'tn-thu-19');
      expect(store.recordTableNoShow(), TablesStanding.warned);
      // A warning does not block booking…
      expect(store.holdTableSeat(thu), isNotNull);
      // …but the second no-show bans AND cancels the active booking.
      expect(store.recordTableNoShow(), TablesStanding.banned);
      expect(store.tableBooking, isNull);
      expect(store.holdTableSeat(thu), isNull);
    });

    test('every seeded night prices inside the \$17–35 seat band', () {
      for (final n in MockData.tableNights) {
        expect(n.seatPrice, inInclusiveRange(17, 35),
            reason: '${n.id} prices outside the Tables band');
      }
    });
  });

  group('Real Capture — provenance gating (Wave 1 #2)', () {
    test('in-app captured media earns the tag state', () {
      final aria = _byId('m-aria');
      expect(aria.photoSource, MediaSource.realCapture);
      expect(aria.hasRealCaptureMedia, isTrue);
    });

    test('uploaded media does NOT earn the tag', () {
      final dev = _byId('m-dev');
      expect(dev.photoSource, MediaSource.uploaded);
      expect(dev.hasRealCaptureMedia, isFalse);
    });

    test('placeholder media does NOT earn the tag', () {
      final marcus = _byId('m-marcus');
      expect(marcus.photoSource, MediaSource.placeholder);
      expect(marcus.hasRealCaptureMedia, isFalse);
    });

    test('a Real Capture photo suffices even with an uploaded intro', () {
      final sofia = _byId('m-sofia');
      expect(sofia.photoIsRealCapture, isTrue);
      expect(sofia.videoIntroIsRealCapture, isFalse);
      expect(sofia.hasRealCaptureMedia, isTrue);
    });
  });
}
