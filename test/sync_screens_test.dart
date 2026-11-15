// Conversation Sync on real screens. Written before the UI (TDD).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carino/data/mock_data.dart';
import 'package:carino/models/message.dart';
import 'package:carino/models/sync.dart';
import 'package:carino/screens/chats/conversation_screen.dart';
import 'package:carino/screens/chats/conversation_settings_screen.dart';
import 'package:carino/screens/connect/decompress_screens.dart';
import 'package:carino/screens/connect/plan_composer_screen.dart';
import 'package:carino/screens/connect/post_plan_feedback_screen.dart';
import 'package:carino/screens/discover/profile_detail_screen.dart';
import 'package:carino/screens/you/sync_settings_screen.dart';
import 'package:carino/services/services.dart';
import 'package:carino/theme/app_theme.dart';

import 'support/real_fonts.dart';

void main() {
  Future<void> phone(WidgetTester t) async {
    t.view.physicalSize = const Size(360, 740) * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
  }

  Future<void> show(WidgetTester t, Widget w) async {
    await phone(t);
    await t.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: w));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  // The You-both strip sits at the top of the thread; the thread opens at
  // the newest message, so scroll up to it.
  Future<void> toStrip(WidgetTester t) async {
    await t.scrollUntilVisible(find.text('Their style'), -200,
        scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(find.text('Their style'));
    await t.pumpAndSettle();
  }

  Conversation conv(String id) =>
      MockData.conversations().firstWhere((c) => c.id == id);

  setUpAll(loadRealFonts);

  setUp(() {
    Services.prefs.myStyle = const TextingStyle();
    Services.prefs.myComfort = const ComfortRules();
    Services.prefs.reflections.clear();
    Services.prefs.matchNotes.clear();
  });

  testWidgets('chat shows pace note, You both chips and the plan bridge', (t) async {
    await show(t, ConversationScreen(conversation: conv('conv-aria')));
    await toStrip(t);
    expect(find.text('Aria usually replies in the evening'), findsOneWidget);
    expect(find.text('Coffee and a walk'), findsWidgets);
    await t.scrollUntilVisible(find.textContaining('Phone-free café hour'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('Phone-free café hour'), findsOneWidget);
  });

  testWidgets('their style sheet shows the card and comfort rules', (t) async {
    await show(t, ConversationScreen(conversation: conv('conv-aria')));
    await toStrip(t);
    await t.tap(find.text('Their style'));
    await t.pumpAndSettle();
    expect(find.text('How Aria texts'), findsOneWidget);
    expect(find.text('Love voice notes'), findsOneWidget);
    expect(find.text('Photos after 3 days of chatting'), findsOneWidget);
  });

  testWidgets('photo is held back by the recipient\'s comfort rule', (t) async {
    await show(t, ConversationScreen(conversation: conv('conv-aria')));
    final before = conv('conv-aria').messages.length;
    await t.tap(find.byTooltip('Add photo, sticker, voice, game'));
    await t.pumpAndSettle();
    await t.tap(find.text('Photo'));
    await t.pumpAndSettle();
    expect(find.textContaining('prefers photos after 3 days'), findsOneWidget);
    expect(conv('conv-aria').messages.length, before);
  });

  testWidgets('calls are held back by "no calls before we\'ve met"', (t) async {
    await show(t, ConversationScreen(conversation: conv('conv-sofia')));
    await t.tap(find.byTooltip('Spark video (connections only)'));
    await t.pumpAndSettle();
    expect(find.textContaining('Sofia asked for no calls'), findsOneWidget);
  });

  testWidgets('tone tag rides along with the message', (t) async {
    final c = conv('conv-aria');
    await show(t, ConversationScreen(conversation: c));
    await t.tap(find.byTooltip('Add photo, sticker, voice, game'));
    await t.pumpAndSettle();
    await t.tap(find.text('Add a tone tag'));
    await t.pumpAndSettle();
    await t.tap(find.text('joking'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'Your café audit is ruthless');
    await t.tap(find.byTooltip('Send'));
    await t.pumpAndSettle();
    expect(c.messages.last.toneTag, 'joking');
    expect(find.text('joking'), findsOneWidget);
  });

  testWidgets('pause, don\'t ghost: posts an honest notice', (t) async {
    final c = conv('conv-sofia');
    await show(t, ConversationScreen(conversation: c));
    await t.tap(find.byTooltip('Add photo, sticker, voice, game'));
    await t.pumpAndSettle();
    await t.tap(find.text('Pause this chat'));
    await t.pumpAndSettle();
    await t.tap(find.text('Back next week'));
    await t.pumpAndSettle();
    expect(c.pausedLabel, 'next week');
    expect(c.messages.last.isSystemNotice, isTrue);
    expect(find.textContaining('Not ghosting, just busy'), findsWidgets);
  });

  testWidgets('How I text & comfort: choices save to my prefs', (t) async {
    await show(t, const SyncSettingsScreen());
    await t.tap(find.text('Evenings only'));
    await t.pump();
    await t.scrollUntilVisible(find.text('No calls before we\'ve met'), 200,
        scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('No calls before we\'ve met'));
    await t.pump();
    await t.scrollUntilVisible(find.text('Save'), 200,
        scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(Services.prefs.myStyle.pace, ReplyPace.evenings);
    expect(Services.prefs.myComfort.noCallsBeforeMeet, isTrue);
  });

  testWidgets('daytime first meet greys out evening times', (t) async {
    Services.prefs.myComfort = const ComfortRules(daytimeFirstMeet: true);
    final dev = MockData.memberById('m-dev');
    await show(t, PlanComposerScreen(member: dev));
    final evening = find.widgetWithText(ChoiceChip, 'Tomorrow · 18:30');
    expect(t.widget<ChoiceChip>(evening).onSelected, isNull);
    expect(t.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Sat · 11:00')).onSelected, isNotNull);
    await t.scrollUntilVisible(find.textContaining('daytime first meet'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('daytime first meet'), findsOneWidget);
  });

  testWidgets('private check-in after a plan is saved for me only', (t) async {
    await show(t, PostPlanFeedbackScreen(member: MockData.memberById('m-aria'), placeType: 'Coffee'));
    for (final i in [0, 2, 4]) {
      await t.tap(find.text('Yes').at(i ~/ 2));
      await t.pump();
    }
    await t.scrollUntilVisible(find.text('The conversation').first, 200,
        scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('The conversation').first); // "What felt good?" row
    await t.pump();
    await t.scrollUntilVisible(find.text('Save feedback'), 200,
        scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('Save feedback'));
    await t.pumpAndSettle();
    expect(Services.prefs.reflections, hasLength(1));
    expect(Services.prefs.reflections.single.category, 'Café');
    expect(Services.prefs.reflections.single.liked, contains(ReflectTag.talk));
  });

  testWidgets('Decompress leads with what my check-ins liked, and says why', (t) async {
    Services.prefs.reflections.add(const Reflection(category: 'Calm', good: true));
    await show(t, const DecompressScreen());
    await t.scrollUntilVisible(find.textContaining('You enjoyed a calm plan'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('You enjoyed a calm plan'), findsOneWidget);
  });

  testWidgets('profile shows how they text', (t) async {
    await show(t, ProfileDetailScreen(member: MockData.memberById('m-aria')));
    await t.scrollUntilVisible(find.text('How Aria texts'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('How Aria texts'), findsOneWidget);
  });

  testWidgets('things to remember: a private note per match', (t) async {
    final c = conv('conv-aria');
    await show(t, ConversationSettingsScreen(conversation: c, member: MockData.memberById('m-aria')));
    await t.enterText(find.widgetWithText(TextField, 'Things to remember (only you see this)'),
        'Dog called Biscuit');
    await t.pump();
    expect(Services.prefs.matchNotes['m-aria'], 'Dog called Biscuit');
  });
}
