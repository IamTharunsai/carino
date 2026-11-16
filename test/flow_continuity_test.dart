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
import 'package:carino/screens/connect/post_plan_feedback_screen.dart';
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

  testWidgets('verification is two steps: ID, then one selfie clip', (t) async {
    var done = false;
    await show(t, VerificationProviderScreen(onComplete: () => done = true, onCancel: () {}));
    expect(find.text('Step 1 of 2 · ID'), findsOneWidget);
    await t.tap(find.text('Take photo')); // front
    await t.pump();
    await t.tap(find.text('Take photo')); // back -> reading
    await t.pump(const Duration(seconds: 3));
    expect(find.text('Step 2 of 2 · Selfie'), findsOneWidget);
    expect(find.text('Upload a photo instead'), findsNothing); // a live selfie can't be uploaded
    expect(done, isFalse);
    await t.tap(find.text('Record selfie'));
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
    await t.pump();
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

  testWidgets('dragging shows the LIKE stamp; swipe up is a Super Like', (t) async {
    Services.prefs.liked.clear();
    await show(t, const DiscoverScreen());
    const centre = Offset(180, 380);
    final g = await t.startGesture(centre);
    Future<void> move(Offset by) async {
      for (var i = 0; i < 10; i++) {
        await g.moveBy(by / 10);
        await t.pump(const Duration(milliseconds: 16));
      }
    }
    await move(const Offset(100, 0));
    expect(find.text('LIKE'), findsOneWidget);
    await move(const Offset(-200, 0));
    expect(find.text('PASS'), findsOneWidget);
    await move(const Offset(100, -200));
    expect(find.text('SUPER LIKE'), findsOneWidget);
    await g.up();
    await settle(t);
    expect(Services.prefs.liked, hasLength(1)); // super like counts as a like
  });

  testWidgets('Daily Drop: a card I swipe leaves the Drop', (t) async {
    await show(t, const DiscoverScreen());
    await t.tap(find.textContaining('Daily Drop ·'));
    await t.pump();
    final before = int.parse(RegExp(r'Daily Drop · (\d+)')
        .firstMatch((t.widget<Text>(find.textContaining('Daily Drop ·'))).data!)!.group(1)!);
    await t.dragFrom(const Offset(180, 420), const Offset(-320, 0)); // pass
    await settle(t);
    final after = int.parse(RegExp(r'Daily Drop · (\d+)')
        .firstMatch((t.widget<Text>(find.textContaining('Daily Drop ·'))).data!)!.group(1)!);
    expect(after, before - 1);
  });

  testWidgets('view-once: I see the photo, it is spent when I close it', (t) async {
    final c = MockData.chatWith(MockData.memberById('m-elena'));
    c.messages.add(ChatMessage(id: 'vo', text: 'View-once photo', fromMe: false, timeLabel: 'now',
        mediaAsset: 'assets/images/backdrop_match.jpg', viewOnce: true));
    await show(t, ConversationScreen(conversation: c));
    expect(c.messages.last.mediaConsumed, isFalse);
    await t.tap(find.byType(Image).last);
    await t.pumpAndSettle();
    expect(c.messages.last.mediaConsumed, isFalse); // still viewing
    await t.pageBack();
    await t.pumpAndSettle();
    expect(c.messages.last.mediaConsumed, isTrue);
  });

  testWidgets('AI switched off means AI drafts stay off', (t) async {
    Services.prefs.aiConversationAssistant = false;
    addTearDown(() => Services.prefs.aiConversationAssistant = true);
    final c = MockData.conversations().firstWhere((x) => x.id == 'conv-aria');
    await show(t, ConversationScreen(conversation: c));
    await t.tap(find.byTooltip('Suggest replies (AI drafts)'));
    await t.pump();
    expect(find.textContaining('AI drafts are off'), findsOneWidget);
    expect(find.text('AI drafts — tap to edit, you send it'), findsNothing);
  });

  testWidgets('Hide this profile: they are gone and it is remembered', (t) async {
    Services.prefs.hiddenPeople.clear();
    await show(t, ProfileDetailScreen(member: MockData.memberById('m-dev')));
    await t.scrollUntilVisible(find.text('Hide this profile'), 300, scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(find.text('Hide this profile'));
    await t.pumpAndSettle();
    await t.tap(find.text('Hide this profile'));
    await t.pumpAndSettle();
    expect(Services.prefs.hiddenPeople, contains('m-dev'));
  });

  testWidgets('after-date note is saved with the check-in, once', (t) async {
    Services.prefs.reflections.clear();
    await show(t, PostPlanFeedbackScreen(member: MockData.memberById('m-aria'), placeType: 'Coffee'));
    await t.tap(find.text('Yes').first);
    await t.pump();
    await t.scrollUntilVisible(find.widgetWithText(TextField, 'Private debrief note (only you see it)'), 200,
        scrollable: find.byType(Scrollable).first);
    await t.enterText(find.widgetWithText(TextField, 'Private debrief note (only you see it)'), 'Loved the café');
    await t.scrollUntilVisible(find.text('Save feedback'), 200, scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('Save feedback'));
    await t.tap(find.text('Save feedback'), warnIfMissed: false); // impatient double tap
    await t.pumpAndSettle();
    expect(Services.prefs.reflections, hasLength(1));
    expect(Services.prefs.reflections.single.note, 'Loved the café');
  });
}
