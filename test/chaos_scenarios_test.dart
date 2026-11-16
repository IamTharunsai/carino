// Chaos-customer regression tests — added 2026-11-15 with the audit &
// enhance pass. Each test pins one blocker found by the end-to-end audit
// so the "crazy customer" flows can never silently break again:
//
//  - Daily Drop never advanced (same card forever, Drop never emptied)
//  - Likes/passes recorded nowhere; matches pre-baked and contradictory
//  - Undo missing/fragile
//  - Chat state evaporating because conversations were rebuilt per call
//  - Verification layers leaking across runs (badge unearnable on re-run)
//  - Settings living only in memory (everything reset on restart)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carino/data/mock_data.dart';
import 'package:carino/models/member.dart';
import 'package:carino/models/message.dart';
import 'package:carino/screens/discover/discover_screen.dart';
import 'package:carino/services/verification_service.dart';
import 'package:carino/state/app_store.dart';
import 'package:carino/theme/app_theme.dart';

Member _byId(String id) => MockData.memberById(id);

void main() {
  group('AppStore — Discover state (audit blockers B1/B10/B12)', () {
    test('Daily Drop advances: a pass removes the top Drop card', () {
      final store = AppStore();
      final dropBefore = store.dropDeck.length;
      expect(dropBefore, greaterThan(0));
      final top = store.dropDeck.first;
      expect(store.recordPass(top, fromDrop: true), isTrue);
      expect(store.dropDeck.length, dropBefore - 1);
      expect(store.dropDeck.contains(top), isFalse);
      expect(store.swipedIds.contains(top.id), isTrue);
    });

    test('Daily Drop can actually empty (its empty state is reachable)', () {
      final store = AppStore();
      while (store.dropDeck.isNotEmpty) {
        store.recordPass(store.dropDeck.first, fromDrop: true);
      }
      expect(store.dropDeck, isEmpty);
    });

    test('double-tap guard: swiping the same member twice records once', () {
      final store = AppStore();
      final m = store.deck.first;
      expect(store.recordPass(m), isTrue);
      expect(store.recordPass(m), isFalse);
      expect(store.swipedIds.where((id) => id == m.id).length, 1);
    });

    test('a like matches ONLY when they like you back', () {
      final store = AppStore();
      final priya = _byId('m-priya'); // likesYouBack: true, not pre-matched
      expect(priya.likesYouBack, isTrue);
      expect(store.matches.any((m) => m.id == priya.id), isFalse);
      expect(store.recordLike(priya), isTrue);
      expect(store.matches.any((m) => m.id == priya.id), isTrue);

      final oneSided = store.deck.firstWhere(
          (m) => !m.likesYouBack && !store.matches.any((x) => x.id == m.id));
      final matchCount = store.matches.length;
      expect(store.recordLike(oneSided), isFalse);
      expect(store.matches.length, matchCount);
      expect(store.matches.any((m) => m.id == oneSided.id), isFalse);
    });

    test('undo restores the last swipe — pass AND matched like', () {
      final store = AppStore();
      final deckSize = store.deck.length;
      final passed = store.deck.first;
      store.recordPass(passed);
      expect(store.deck.length, deckSize - 1);
      expect(store.undoLastSwipe()?.id, passed.id);
      expect(store.deck.first.id, passed.id);
      expect(store.swipedIds.contains(passed.id), isFalse);

      final priya = _byId('m-priya');
      store.recordLike(priya);
      expect(store.matches.any((m) => m.id == priya.id), isTrue);
      expect(store.undoLastSwipe()?.id, priya.id);
      expect(store.matches.any((m) => m.id == priya.id), isFalse);
    });

    test('block removes a member from deck, drop and matches at once', () {
      final store = AppStore();
      final priya = _byId('m-priya');
      store.recordLike(priya);
      store.blockMember(priya.id);
      expect(store.blockedIds.contains(priya.id), isTrue);
      expect(store.deck.any((m) => m.id == priya.id), isFalse);
      expect(store.dropDeck.any((m) => m.id == priya.id), isFalse);
      expect(store.matches.any((m) => m.id == priya.id), isFalse);
    });
  });

  group('AppStore — chat state persists (audit blocker Chats-B3)', () {
    test('conversationFor returns the SAME instance; sent messages stay', () {
      final store = AppStore();
      final c1 = store.conversationFor('m-aria');
      final before = c1.messages.length;
      store.appendMessage(
        c1.id,
        ChatMessage(
          id: 'chaos-1',
          text: 'this must still be here when I come back',
          fromMe: true,
          timeLabel: 'now',
        ),
      );
      final c2 = store.conversationFor('m-aria');
      expect(identical(c1, c2), isTrue);
      expect(c2.messages.length, before + 1);
      expect(c2.messages.last.text, contains('still be here'));
    });

    test('unread count is the real sum across shared conversations', () {
      final store = AppStore();
      final expected =
          store.conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
      expect(store.unreadChats, expected);
    });
  });

  group('VerificationService — no state leaks (audit blocker Onb-B3)', () {
    test('running the demo flow twice still earns the badge', () async {
      final svc = VerificationService();
      await svc.runDemoFlow();
      expect(svc.badgeEarned, isTrue);
      expect(svc.completedLayers.length, 3);
      await svc.runDemoFlow();
      expect(svc.completedLayers.length, 3,
          reason: 'a re-run must restart the layer set, not append to it');
      expect(svc.badgeEarned, isTrue);
    });

    test('reset() clears layers and badge (sign-out hygiene)', () async {
      final svc = VerificationService();
      await svc.runDemoFlow();
      svc.reset();
      expect(svc.completedLayers, isEmpty);
      expect(svc.badgeEarned, isFalse);
    });
  });


  group('Discover screen — the card actually leaves (audit M4/B1)', () {
    testWidgets('tapping Pass advances to the next person', (tester) async {
      final topName = MockData.members.first.firstName;

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark(), home: const DiscoverScreen()),
      );
      // Bounded pumps only: the aurora background animates forever, so
      // pumpAndSettle would never settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.bySemanticsLabel('Not now'), findsOneWidget);
      expect(find.textContaining(topName), findsWidgets);

      await tester.tap(find.bySemanticsLabel('Not now'));
      // Fly-off + deck swap.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      expect(tester.takeException(), isNull);
      expect(find.text(topName), findsNothing,
          reason: 'the passed card must be gone from the deck');
    });
  });
}
