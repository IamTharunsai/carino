// Experience bundle: logic invariants + phone-size render smoke tests.
//
// The render tests pump every new screen at a small phone size (360x740)
// and fail on any layout overflow or exception — the closest automated
// stand-in for "open it as a customer and look".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carino/data/mock_data.dart';
import 'package:carino/models/experience.dart';
import 'package:carino/screens/chats/chat_list_screen.dart';
import 'package:carino/screens/chats/conversation_screen.dart';
import 'package:carino/screens/chats/games_screen.dart';
import 'package:carino/screens/connect/connect_screen.dart';
import 'package:carino/screens/connect/meet_irl_screens.dart';
import 'package:carino/screens/connect/plan_detail_screen.dart';
import 'package:carino/screens/connect/post_plan_feedback_screen.dart';
import 'package:carino/screens/discover/discover_screen.dart';
import 'package:carino/screens/discover/profile_detail_screen.dart';
import 'package:carino/screens/moments/moment_viewer_screen.dart';
import 'package:carino/screens/moments/moments_screen.dart';
import 'package:carino/screens/onboarding/identity_screen.dart';
import 'package:carino/screens/onboarding/taste_quiz_screen.dart';
import 'package:carino/screens/you/wingperson_screen.dart';
import 'package:carino/screens/you/you_screen.dart';
import 'package:carino/services/services.dart';
import 'package:carino/theme/app_theme.dart';
import 'package:carino/screens/you/facets_screen.dart';
import 'package:carino/screens/you/work_facet_screen.dart';
import 'package:carino/screens/you/trust_graph_screen.dart';
import 'package:carino/screens/chats/social_screens.dart';
import 'package:carino/screens/stage/stage_screen.dart';
import 'package:carino/screens/connect/plans_hub_screens.dart';

void main() {
  group('Reciprocal "I want to meet"', () {
    test('empty want = open to everyone', () {
      expect(wantsToMeet(const [], const ['Man']), isTrue);
    });
    test('trans women count as women, trans men as men', () {
      expect(wantsToMeet(const ['Women'], const ['Trans woman']), isTrue);
      expect(wantsToMeet(const ['Men'], const ['Trans man']), isTrue);
    });
    test('other identities map to non-binary', () {
      expect(wantsToMeet(const ['Non-binary people'], const ['Genderfluid']),
          isTrue);
      expect(wantsToMeet(const ['Women'], const ['Non-binary']), isFalse);
    });
    test('must be mutual', () {
      expect(
        mutualFit(
            myWant: const ['Women'],
            myGender: const ['Man'],
            theirWant: const ['Women'],
            theirGender: const ['Woman']),
        isFalse,
        reason: 'she wants women, so a man is not shown to her or her to him',
      );
      expect(
        mutualFit(
            myWant: const [],
            myGender: const ['Man'],
            theirWant: const ['Men'],
            theirGender: const ['Man']),
        isTrue,
      );
    });
  });

  group('Scam Shield', () {
    test('flags money, crypto, gift cards, off-app', () {
      expect(scanForScam('can you send me money on venmo'),
          contains(ScamSignal.money));
      expect(scanForScam('I made 40% on this crypto trading platform'),
          contains(ScamSignal.crypto));
      expect(scanForScam('grab me a few gift cards?'),
          contains(ScamSignal.giftCards));
      expect(scanForScam('add me on telegram instead'),
          contains(ScamSignal.offApp));
    });
    test('ordinary chat is quiet', () {
      expect(scanForScam('Coffee on Saturday? The playlist place on High St'),
          isEmpty);
      expect(scanForScam('I loaned my bike to my sister'), isEmpty);
      for (final c in MockData.conversations()) {
        for (final m in c.messages) {
          expect(scanForScam(m.text), isEmpty, reason: m.text);
        }
      }
    });
  });

  group('Chemistry streak forgives', () {
    test('one missed day spends the freeze, keeps the count', () {
      var s = const ChemistryStreak(days: 4);
      s = s.nextDay(active: false);
      expect(s.days, 4);
      expect(s.freezeAvailable, isFalse);
      s = s.nextDay(active: false);
      expect(s.days, 0, reason: 'second miss with no freeze resets quietly');
    });
    test('weekly reset restores the freeze; a date completes it', () {
      final s = const ChemistryStreak(days: 2, freezeAvailable: false)
          .weeklyReset()
          .markDate();
      expect(s.freezeAvailable, isTrue);
      expect(s.completedByDate, isTrue);
      expect(s.nextDay(active: false).days, 2);
    });
  });

  test('taste overlaps are real only', () {
    expect(
        sharedTastes({'t1': 'Sunrise hike'}, {'t1': 'Slow brunch'}), isEmpty);
    expect(
        sharedTastes({'t1': 'Sunrise hike', 't2': 'Midnight pancakes'},
            {'t2': 'Midnight pancakes'}),
        ['Midnight pancakes']);
  });

  test('sample data includes non-binary and 40+ members, all 21+', () {
    expect(
        MockData.members.any((m) => m.gender.contains('Non-binary')), isTrue);
    expect(MockData.members.any((m) => m.age >= 40), isTrue);
    expect(MockData.members.every((m) => m.age >= 21), isTrue);
  });

  test('hidden identity fields are never shown, even to matches', () {
    final priya = MockData.memberById('m-priya');
    expect(priya.shows('orientation', matched: true), isFalse);
    final aria = MockData.memberById('m-aria');
    expect(aria.shows('orientation', matched: false), isFalse);
    expect(aria.shows('orientation', matched: true), isTrue);
  });

  group('Customer view renders at phone size', () {
    final screens = <String, Widget Function()>{
      'Identity': () => IdentityScreen(onDone: () {}),
      'Facets': () => const FacetsScreen(),
      'Work facet': () => const WorkFacetScreen(),
      'Trust Graph': () => const TrustGraphScreen(),
      'Stage': () => const StageScreen(),
      'Friends': () => const FriendsScreen(),
      'Group chat': () => GroupChatScreen(group: MockData.groups().first),
      'Tonight': () => const TonightScreen(),
      'Host plan': () => const HostPlanScreen(),
      'Coffee chats': () => const CoffeeChatsScreen(),
      'Guilds': () => const GuildsScreen(),
      'Taste quiz': () => TasteQuizScreen(onDone: () {}),
      'Discover': () => const DiscoverScreen(),
      'Profile (Sofia: highlights, soundtrack)': () =>
          ProfileDetailScreen(member: MockData.memberById('m-sofia')),
      'Profile (Rowan: they/them, access)': () => ProfileDetailScreen(
          member: MockData.memberById('m-rowan'), matched: true),
      'Moments': () => const MomentsScreen(),
      'Moment viewer w/ sticker': () =>
          MomentViewerScreen(moments: MockData.moments, initialIndex: 0),
      'Connect': () => const ConnectScreen(),
      'Events': () => const EventsScreen(),
      'Spark Nights': () => const SparkNightsScreen(),
      'Group hangout': () => const GroupHangoutScreen(),
      'Games + streak': () =>
          GamesScreen(member: MockData.memberById('m-sofia')),
      'Plan detail + check-in': () => PlanDetailScreen(
          member: MockData.memberById('m-aria'),
          placeType: 'Coffee',
          timeLabel: 'Sat · 11:00',
          confirmed: true),
      'Post-plan debrief': () => PostPlanFeedbackScreen(
          member: MockData.memberById('m-sofia'), placeType: 'Market'),
      'Chats (close the loop)': () => const ChatListScreen(),
      'Conversation': () =>
          ConversationScreen(conversation: MockData.conversations().first),
      'You (aura)': () => const AccountCentreScreen(),
      'Wingperson': () => const WingpersonScreen(),
    };

    for (final entry in screens.entries) {
      testWidgets(entry.key, (tester) async {
        tester.view.physicalSize = const Size(360, 740) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.dark(),
          home: entry.value(),
        ));
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
        // Drain any demo timers (AI drafts etc.) before teardown.
        await tester.pump(const Duration(seconds: 2));
      });
    }

    testWidgets('Scam Shield appears when money comes up', (tester) async {
      tester.view.physicalSize = const Size(360, 740) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final conv = MockData.conversations().first;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark(),
        home: ConversationScreen(conversation: conv),
      ));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Scam Shield'), findsNothing);
      await tester.enterText(find.byType(TextField).last,
          'my investment platform pays 40%, try crypto with me');
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(find.text('Before you send'), findsOneWidget);
      await tester.tap(find.text('Send anyway'));
      await tester.pumpAndSettle();
      expect(find.text('Scam Shield'), findsOneWidget);
    });

    testWidgets('Discover hides people who do not want to meet you',
        (tester) async {
      Services.prefs.gender = const ['Woman'];
      Services.prefs.wantToMeet = const ['Women'];
      addTearDown(() {
        Services.prefs.gender = const [];
        Services.prefs.wantToMeet = const [];
      });
      // Dev wants women but is a man: hidden. Elena wants men: hidden.
      expect(fitsMe(MockData.memberById('m-dev')), isFalse);
      expect(fitsMe(MockData.memberById('m-elena')), isFalse);
      // Aria (woman, open to women) fits.
      expect(fitsMe(MockData.memberById('m-aria')), isTrue);
    });
  });
}
