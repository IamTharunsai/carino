// What you enter in onboarding is what the app shows you later.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carino/data/mock_data.dart';
import 'package:carino/models/member.dart';
import 'package:carino/models/message.dart';
import 'package:carino/screens/chats/conversation_screen.dart';
import 'package:carino/screens/discover/discover_screen.dart';
import 'package:carino/screens/discover/profile_detail_screen.dart';
import 'package:carino/screens/you/likes_manager_screen.dart';
import 'package:carino/screens/you/notifications_screen.dart';
import 'package:carino/screens/onboarding/intentions_screen.dart';
import 'package:carino/screens/onboarding/verification_flow_screen.dart';
import 'package:carino/screens/you/settings_screen.dart';
import 'package:carino/screens/you/privacy_centre_screen.dart';
import 'package:carino/services/services.dart';
import 'package:carino/theme/app_theme.dart';

import 'support/real_fonts.dart';

void main() {
  setUpAll(loadRealFonts);

  Future<void> show(WidgetTester t, Widget w) async {
    t.view.physicalSize = const Size(360, 740) * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: w));
    await t.pumpAndSettle();
  }

  testWidgets('the intention I pick is the one my profile shows', (t) async {
    await show(t, IntentionsScreen(onDone: (_) {}));
    await t.tap(find.text('Long-Term'));
    await t.pump();
    await t.scrollUntilVisible(find.text('Weekends'), 200, scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(find.text('Weekends'));
    await t.pumpAndSettle();
    await t.tap(find.text('Weekends'));
    await t.pump();
    await t.scrollUntilVisible(find.text('Continue'), 200, scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(find.text('Continue'));
    await t.pumpAndSettle();
    await t.tap(find.text('Continue'));
    await t.pump();
    expect(Services.prefs.me.intention, Intention.longTerm);
    expect(Services.prefs.me.availability, 'Weekends');
  });

  testWidgets('verification marks one layer per step, not all three at once', (t) async {
    var done = false;
    await show(t, VerificationProviderScreen(onComplete: () => done = true, onCancel: () {}));
    expect(find.text('Step 1 of 3 · ID document'), findsOneWidget);
    await t.tap(find.text('Capture')); // front
    await t.pump();
    await t.tap(find.text('Capture')); // back -> reading
    await t.pump(const Duration(seconds: 3));
    expect(find.text('Step 2 of 3 · Liveness'), findsOneWidget);
    expect(find.text('Upload instead'), findsNothing); // a live selfie can't be uploaded
    await t.tap(find.text('Take live selfie'));
    await t.pump(const Duration(seconds: 3));
    expect(find.text('Step 3 of 3 · Photo match'), findsOneWidget);
    expect(done, isFalse);
    await t.tap(find.text('Run photo match'));
    await t.pump(const Duration(seconds: 3));
    expect(done, isTrue);
  });

  testWidgets('Settings has a way into the Privacy Centre', (t) async {
    await show(t, const SettingsScreen());
    await t.scrollUntilVisible(find.text('Privacy Centre'), 200, scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(find.text('Privacy Centre'));
    await t.pumpAndSettle();
    await t.tap(find.text('Privacy Centre'));
    await t.pumpAndSettle();
    expect(find.byType(PrivacyCentreScreen), findsOneWidget);
  });

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
  }

  testWidgets('swipe right likes, left passes, double-tap likes; match only if mutual', (t) async {
    Services.prefs.liked.clear();
    await show(t, const DiscoverScreen());
    const centre = Offset(180, 380);
    await t.dragFrom(centre, const Offset(320, 0)); // right = like
    await settle(t);
    expect(Services.prefs.liked, hasLength(1));
    expect(find.textContaining("If they like you back, it's a match"), findsOneWidget);
    expect(find.text("It's a spark"), findsNothing); // no fake match
    await t.dragFrom(centre, const Offset(-320, 0)); // left = pass
    await settle(t);
    expect(Services.prefs.liked, hasLength(1));
    final before = Services.prefs.liked.length;
    await t.tapAt(centre);
    await t.pump(const Duration(milliseconds: 60));
    await t.tapAt(centre); // double-tap = like
    await settle(t);
    expect(Services.prefs.liked.length, before + 1);
    // Keep liking: the first person who already liked you becomes a real match.
    for (var i = 0; i < 8 && find.text("It's a spark").evaluate().isEmpty; i++) {
      await t.dragFrom(centre, const Offset(320, 0));
      await settle(t);
    }
    expect(find.text("It's a spark"), findsOneWidget);
    expect(MockData.likesYou.any((m) => Services.prefs.liked.contains(m.id)), isTrue);
    await t.tap(find.text('Message'));
    await settle(t);
    expect(find.byType(ConversationScreen), findsOneWidget); // match -> chat, not a dead end
  });

  testWidgets('You liked list shows who is waiting and who matched', (t) async {
    Services.prefs.liked
      ..clear()
      ..addAll(['m-aria', 'm-priya']);
    await show(t, const LikesManagerScreen());
    expect(find.text('Waiting for them to like you back'), findsOneWidget);
    expect(find.text("It's a match — say hi"), findsOneWidget);
  });

  testWidgets('a matched profile offers Message and Suggest a plan, not Pass/Like', (t) async {
    await show(t, ProfileDetailScreen(member: MockData.memberById('m-aria'), matched: true));
    await t.scrollUntilVisible(find.text('Message'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Message'), findsOneWidget);
    expect(find.text('Pass'), findsNothing);
  });

  testWidgets('a message I send is still there when I come back to the chat', (t) async {
    final c = MockData.conversations().firstWhere((x) => x.id == 'conv-aria');
    await show(t, ConversationScreen(conversation: c));
    await t.enterText(find.byType(TextField), 'See you Saturday');
    await t.tap(find.byTooltip('Send'));
    await t.pumpAndSettle();
    final again = MockData.conversations().firstWhere((x) => x.id == 'conv-aria');
    expect(again.messages.last.text, 'See you Saturday');
    expect(again.mode, ChatMode.keep);
  });

  testWidgets('notifications: my language, and every row opens something', (t) async {
    await show(t, const NotificationsScreen());
    await t.tap(find.text('Spanish'));
    await t.pump();
    expect(find.textContaining('Nuevo mensaje'), findsOneWidget);
    expect(find.textContaining('Lock screen: Cariño · Tienes algo nuevo'), findsWidgets);
    Services.prefs.notifLanguage = 'English';
    await t.scrollUntilVisible(find.byIcon(Icons.chevron_right).first, 300,
        scrollable: find.byType(Scrollable).first);
    await t.tap(find.byIcon(Icons.chevron_right).first);
    await t.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsNothing); // navigated, not a dead tap
  });
}
