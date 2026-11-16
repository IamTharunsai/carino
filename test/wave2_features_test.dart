// Wave 2 crowd features (CROWD-FEATURES #5, #6, #7, #8, #16, #21, #22):
// Private Circles + plan conversion, PrivateCircle-only Moments + Highlights,
// Smart Chat polls / Ask-me, Wingperson accept/decline, People Search
// matching, the video-reply message state, and the Finite Drop end card.
//
// Same doctrine as waves before: states are asserted against the REAL
// store and the REAL seed data — a conversion that creates no circle, a
// vote that isn't counted, or an accept that opens no chat would each
// be a shipped lie, so each is pinned here.
import 'package:carino/data/mock_data.dart';
import 'package:carino/models/circle.dart';
import 'package:carino/models/message.dart';
import 'package:carino/models/plan.dart';
import 'package:carino/screens/discover/discover_screen.dart';
import 'package:carino/state/app_store.dart';
import 'package:carino/state/people_search.dart';
import 'package:carino/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String _hostName(String id) =>
    id == 'me' ? 'You' : MockData.memberById(id).firstName;

void main() {
  group('Private Circles — seeds (Wave 2 #5)', () {
    test('two demo circles exist, both including me', () {
      final store = AppStore();
      expect(store.circles.length, 2);
      expect(store.circles.every((c) => c.includesMe), isTrue);
      expect(store.circleById('circle-arcade')!.memberCount, 4);
      expect(store.circleById('circle-garden')!.memberCount, 4);
    });

    test('seeded circles point back at the plans they formed from', () {
      final store = AppStore();
      expect(store.circleForPlan('op-sofia-arcade')!.id, 'circle-arcade');
      expect(store.circleForPlan('op-priya-gardens')!.id, 'circle-garden');
      expect(store.circleForPlan('op-dev-trail'), isNull);
    });
  });

  group('Private Circles — plan conversion (Wave 2 #5)', () {
    test('a plan I am not part of cannot convert', () {
      final store = AppStore();
      final plan = store.planById('op-aria-market')!;
      expect(plan.myState, PlanJoinState.none);
      expect(store.canConvertPlanToCircle(plan), isFalse);
      expect(store.convertPlanToCircle(plan.id), isNull);
      expect(store.circles.length, 2);
    });

    test('joining a plan makes it convertible — once', () {
      final store = AppStore();
      expect(store.requestJoinPlan('op-aria-market'), isTrue);
      final plan = store.planById('op-aria-market')!;
      expect(store.canConvertPlanToCircle(plan), isTrue);

      final circle = store.convertPlanToCircle(plan.id);
      expect(circle, isNotNull);
      expect(circle!.sourcePlanId, 'op-aria-market');
      expect(circle.upcomingPlanId, 'op-aria-market');
      // Membership is the plan's real attendee list: host + me.
      expect(circle.memberIds, ['m-aria', 'me']);
      expect(store.circles.length, 3);
      // The chat exists from birth, with the formation line.
      final chat = store.circleMessagesFor(circle.id);
      expect(chat.length, 1);
      expect(chat.single.kind, CircleMsgKind.system);

      // One plan, one circle: a second conversion refuses.
      expect(store.convertPlanToCircle(plan.id), isNull);
      expect(store.circles.length, 3);
    });

    test('a plan I host converts with me as its only seed member', () {
      final store = AppStore();
      final plan = store.createPlan(
        title: 'Rooftop cinema night',
        place: 'Rooftop · Downtown',
        timeLabel: 'Sat · 20:00',
        tonight: false,
        groupSize: 6,
      );
      final circle = store.convertPlanToCircle(plan.id);
      expect(circle, isNotNull);
      expect(circle!.memberIds, ['me']);
      expect(circle.name, 'Rooftop cinema night');
    });
  });

  group('PrivateCircle-only Moments + Highlights (Wave 2 #6)', () {
    test('circle Moments are scoped — the connections feed has none', () {
      final store = AppStore();
      final arcade = store.circleMomentsFor('circle-arcade');
      expect(arcade.length, 2);
      expect(arcade.every((m) => m.circleId == 'circle-arcade'), isTrue);
      expect(store.circleMomentsFor('circle-garden').length, 2);
      // The feed list is a different list and carries no scoped Moments.
      expect(MockData.moments.every((m) => m.circleId == null), isTrue);
    });

    test('seeded Highlights: one pinned Moment per circle', () {
      final store = AppStore();
      expect(store.isMomentHighlighted('cmom-arcade-1'), isTrue);
      expect(store.circleHighlightsFor('circle-arcade').length, 1);
      expect(store.circleHighlightsFor('circle-garden').length, 1);
    });

    test('the Highlight cap is 3 per circle — the 4th pin refuses', () {
      final store = AppStore();
      // Arcade starts with 1 highlight; pin its other Moment (2)…
      expect(store.toggleMomentHighlight('cmom-arcade-2'), isTrue);
      // …post two more Moments and pin the first (3)…
      final m1 = store.postCircleMoment(
          circleId: 'circle-arcade', caption: 'One');
      final m2 = store.postCircleMoment(
          circleId: 'circle-arcade', caption: 'Two');
      expect(store.toggleMomentHighlight(m1.id), isTrue);
      expect(store.circleHighlightsFor('circle-arcade').length, 3);
      // …the next pin refuses and changes nothing.
      expect(store.toggleMomentHighlight(m2.id), isFalse);
      expect(store.circleHighlightsFor('circle-arcade').length, 3);
      // Unpinning frees a slot again.
      expect(store.toggleMomentHighlight(m1.id), isTrue);
      expect(store.toggleMomentHighlight(m2.id), isTrue);
      // The other circle's cap is independent.
      expect(store.circleHighlightsFor('circle-garden').length, 1);
    });

    test('posting a PrivateCircle Moment scopes it to that circle only', () {
      final store = AppStore();
      final moment = store.postCircleMoment(
        circleId: 'circle-garden',
        caption: 'Greenhouse haul 🌿',
      );
      expect(moment.member.id, 'me');
      expect(moment.circleId, 'circle-garden');
      expect(store.circleMomentsFor('circle-garden').first.id, moment.id);
      expect(store.circleMomentsFor('circle-arcade').length, 2);
    });
  });

  group('Smart Chat — polls (Wave 2 #7)', () {
    test('seeded poll votes are the real lists', () {
      final store = AppStore();
      final poll = store.circleMessageById('cmsg-arcade-2')!;
      expect(poll.kind, CircleMsgKind.poll);
      expect(poll.pollTotalVotes, 3);
      expect(poll.pollOptions[1].voterIds, ['m-aria', 'm-dev']);
      expect(poll.myPollVote, isNull);
    });

    test('voting counts once, moves, and toggles off', () {
      final store = AppStore();
      final poll = store.circleMessageById('cmsg-arcade-2')!;
      expect(store.voteInCirclePoll(poll.id, 2), isTrue);
      expect(poll.myPollVote, 2);
      expect(poll.pollTotalVotes, 4);
      // Moving my vote keeps the total honest.
      expect(store.voteInCirclePoll(poll.id, 0), isTrue);
      expect(poll.myPollVote, 0);
      expect(poll.pollTotalVotes, 4);
      // Tapping my pick again takes the vote back.
      expect(store.voteInCirclePoll(poll.id, 0), isTrue);
      expect(poll.myPollVote, isNull);
      expect(poll.pollTotalVotes, 3);
    });

    test('invalid votes refuse: text message, bad index', () {
      final store = AppStore();
      expect(store.voteInCirclePoll('cmsg-arcade-1', 0), isFalse);
      expect(store.voteInCirclePoll('cmsg-arcade-2', 9), isFalse);
      expect(store.voteInCirclePoll('nope', 0), isFalse);
    });

    test('posting a poll drops blank options and starts at zero', () {
      final store = AppStore();
      final poll = store.postCirclePoll(
          'circle-garden', 'Sunday or Saturday?', ['Sunday', '', 'Saturday']);
      expect(poll.pollOptions.length, 2);
      expect(poll.pollTotalVotes, 0);
      expect(store.circleMessagesFor('circle-garden').last.id, poll.id);
    });
  });

  group('Smart Chat — Ask me (Wave 2 #7)', () {
    test('asking lands the question in chat and counts it', () {
      final store = AppStore();
      final askMe = store.circleMessageById('cmsg-arcade-3')!;
      expect(askMe.questionsAsked, 1);
      expect(
        store.askCircleQuestion(askMe.id, 'Best beginner trail nearby?'),
        isTrue,
      );
      expect(askMe.questionsAsked, 2);
      final chat = store.circleMessagesFor('circle-arcade');
      expect(chat.last.kind, CircleMsgKind.text);
      expect(chat.last.authorId, 'me');
      expect(chat.last.text, 'Best beginner trail nearby?');
    });

    test('asking refuses on non-Ask-me messages and empty questions', () {
      final store = AppStore();
      expect(store.askCircleQuestion('cmsg-arcade-2', 'Why?'), isFalse);
      expect(store.askCircleQuestion('cmsg-arcade-3', '   '), isFalse);
      expect(store.circleMessageById('cmsg-arcade-3')!.questionsAsked, 1);
    });
  });

  group('Wingperson (Wave 2 #8)', () {
    test('the seeded intro waits on me — Dev already accepted', () {
      final store = AppStore();
      final intro = store.introById('intro-sofia-1')!;
      expect(intro.byId, 'm-sofia');
      expect(intro.involvesMe, isTrue);
      expect(intro.acceptedIds, {'m-dev'});
      expect(intro.status, IntroStatus.pending);
      expect(store.introsForCircle('circle-arcade').length, 1);
      // …and its card sits in the circle chat.
      final chat = store.circleMessagesFor('circle-arcade');
      expect(
        chat.any((m) =>
            m.kind == CircleMsgKind.intro && m.introId == intro.id),
        isTrue,
      );
    });

    test('my accept connects the intro and opens the 1:1 chat', () {
      final store = AppStore();
      final chatsBefore = store.conversations.length;
      expect(store.acceptIntro('intro-sofia-1'), isTrue);
      final intro = store.introById('intro-sofia-1')!;
      expect(intro.status, IntroStatus.connected);
      // The chat exists through the existing conversationFor pattern.
      expect(store.conversations.length, chatsBefore + 1);
      expect(
        store.conversations.any((c) => c.memberId == 'm-dev'),
        isTrue,
      );
      // Accepting twice is not a thing.
      expect(store.acceptIntro('intro-sofia-1'), isFalse);
    });

    test('declining is final — a later accept refuses', () {
      final store = AppStore();
      expect(store.declineIntro('intro-sofia-1'), isTrue);
      expect(store.introById('intro-sofia-1')!.status, IntroStatus.declined);
      final before = store.conversations.length;
      expect(store.acceptIntro('intro-sofia-1'), isFalse);
      expect(store.conversations.length, before); // no chat started
    });

    test('an intro I create is not mine to accept or decline', () {
      final store = AppStore();
      final intro = store.createIntro(
        circleId: 'circle-garden',
        aId: 'm-aria',
        bId: 'm-sofia',
        note: 'You both owe the gardens a rematch.',
      );
      expect(intro.byId, 'me');
      expect(intro.involvesMe, isFalse);
      expect(intro.status, IntroStatus.pending);
      expect(store.acceptIntro(intro.id), isFalse);
      expect(store.declineIntro(intro.id), isFalse);
      // The card lands in that circle's chat.
      final chat = store.circleMessagesFor('circle-garden');
      expect(chat.last.kind, CircleMsgKind.intro);
      expect(chat.last.introId, intro.id);
    });
  });

  group('People Search (Wave 2 #21)', () {
    test('keywords drop the filler and keep the signal', () {
      expect(searchKeywords('people who hike on Sundays'),
          ['hike', 'sundays']);
      expect(searchKeywords(''), isEmpty);
      expect(searchKeywords('find me someone'), isEmpty);
    });

    test('"hiking" finds Priya — from her real interests', () {
      final hits = searchMembers('hiking', MockData.members);
      expect(hits.map((m) => m.id).toList(), ['m-priya']);
    });

    test('the example query works: "people who hike on Sundays"', () {
      final hits =
          searchMembers('people who hike on Sundays', MockData.members);
      // Merge note: our seed has 2 more members (Rowan, Elena); the logic is unchanged.
      expect(hits.first.id, 'm-priya'); // Rowan hikes too, ranked after her
    });

    test('intention search: "long-term" ranks true matches first', () {
      final hits = searchMembers('long-term', MockData.members);
      // Dev and Priya match BOTH keywords via their Long-Term intention
      // (score 2). Marcus matches only 'long' — inside "belongs" in his
      // prompt — so he ranks below them (score 1). The ranking, not a
      // hard filter, is what keeps the real matches on top.
      // Merge note: our seed has 2 more members (Rowan, Elena); the logic is unchanged.
      final ids = hits.map((m) => m.id).toList();
      expect(ids.take(2), ['m-dev', 'm-priya']);
      expect(ids.indexOf('m-marcus'), greaterThan(1)); // partial match ranks lower
    });

    test('equal scores keep the pool order (stable ranking)', () {
      final hits = searchMembers('vinyl', MockData.members);
      expect(hits.map((m) => m.id).toList(), ['m-aria', 'm-marcus']);
    });

    test('plans match on their own text — and by host', () {
      final store = AppStore();
      final arcade = searchPlans('arcade', store.openPlans, _hostName);
      expect(arcade.map((p) => p.id).toList(), ['op-sofia-arcade']);
      final trail = searchPlans('trail', store.openPlans, _hostName);
      expect(trail.map((p) => p.id).toList(), ['op-dev-trail']);
      // "Sofia" hits her hosted plans (Wave 3 added her Decompress
      // yoga; gardens is Priya's). Wave 4 seed growth: Dev's PAST
      // board-game night names Sofia in its note ("Sofia took the
      // last game…"), so the pure text matcher honestly returns it
      // too, ranked after her hosted plans. The search SCREEN
      // filters past plans out; this function stays a pure matcher.
      final sofia = searchPlans('sofia', store.openPlans, _hostName);
      expect(sofia.map((p) => p.id).toList(),
          ['op-sofia-arcade', 'op-sofia-yoga', 'op-dev-boardgames']);
    });

    test('no signal, no results — never filler people', () {
      expect(searchMembers('underwater basket weaving', MockData.members),
          isEmpty);
      final store = AppStore();
      expect(searchPlans('underwater', store.openPlans, _hostName), isEmpty);
      expect(searchMembers('', MockData.members), isEmpty);
    });
  });

  group('Video Prompt Replies — message state (Wave 2 #22)', () {
    test('a video reply carries its prompt, length and captions state', () {
      final msg = ChatMessage(
        id: 'vr-1',
        text: 'Video reply',
        fromMe: true,
        timeLabel: 'now',
        isVideoReply: true,
        videoReplyPrompt: 'My ideal first plan',
        videoReplySeconds: 7,
        videoReplyCaptions: true,
      );
      expect(msg.videoReplyLabel, '0:07');
      // A plain message is never accidentally a video reply.
      final plain = ChatMessage(
          id: 't-1', text: 'hi', fromMe: true, timeLabel: 'now');
      expect(plain.isVideoReply, isFalse);
    });

    test('a sent reply lands in the thread with that member', () {
      final store = AppStore();
      final conv = store.conversationFor('m-dev');
      store.appendMessage(
        conv.id,
        ChatMessage(
          id: 'vr-2',
          text: 'Video reply',
          fromMe: true,
          timeLabel: 'now',
          isVideoReply: true,
          videoReplyPrompt: 'Unpopular opinion',
          videoReplySeconds: 12,
          videoReplyCaptions: false,
        ),
      );
      final last = store.conversationFor('m-dev').messages.last;
      expect(last.isVideoReply, isTrue);
      expect(last.videoReplyPrompt, 'Unpopular opinion');
      expect(last.videoReplyCaptions, isFalse);
    });
  });

  // LAST in the file: this test empties the SHARED Services.store deck
  // (the singleton the screens read), so nothing after it may rely on it.
  group('Finite Drop end-state (Wave 2 #16)', () {
    testWidgets('an exhausted deck lands on "You\'re caught up"',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark(), home: const DiscoverScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Pass everyone in the finite deck.
      for (var i = 0; i < 20 && find.bySemanticsLabel('Not now').evaluate().isNotEmpty; i++) {
        await tester.tap(find.bySemanticsLabel('Not now'));
        for (var k = 0; k < 4; k++) {
          await tester.pump(const Duration(milliseconds: 120));
        }
      }
      expect(find.text('You\'re caught up'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
