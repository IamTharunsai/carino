// Experience upgrade (Nov 14): Honest Status, couples, referrals/promo,
// analytics privacy, chat composer, like options.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carino/data/mock_data.dart';
import 'package:carino/screens/chats/conversation_screen.dart';
import 'package:carino/screens/experience/experience_screens.dart';
import 'package:carino/services/analytics_service.dart';
import 'package:carino/services/services.dart';
import 'package:carino/theme/app_theme.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360, 740) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: child));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  test('Honest Status: taken statuses pause dating, open ones do not', () {
    expect(statusPausesDating('Married'), isTrue);
    expect(statusPausesDating('In a relationship'), isTrue);
    expect(statusPausesDating('Open relationship'), isFalse);
    expect(statusPausesDating('Single'), isFalse);
  });

  test('analytics counts events and respects the opt-out', () {
    final a = AnalyticsService();
    a.screen('Chats');
    a.screen('Chats');
    a.action('like');
    expect(a.screens['Chats'], 2);
    expect(a.top(a.screens).first.key, 'Chats');
    a.setEnabled(false);
    a.action('like');
    expect(a.actions['like'], 1, reason: 'opted out: nothing recorded');
  });

  testWidgets('choosing Married pauses Dates discovery', (tester) async {
    Services.prefs.visibility = 'Discovery';
    await _pump(tester, const CoupleScreen());
    await tester.tap(find.text('Married'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(Services.prefs.visibility, 'Paused');
    expect(tester.takeException(), isNull);
    Services.prefs
      ..relationshipStatus = 'Single'
      ..visibility = 'Discovery';
  });

  testWidgets('promo: valid code applies once, invalid explains', (tester) async {
    Services.prefs.redeemedPromo = null;
    await _pump(tester, const ReferralScreen());
    await tester.enterText(find.byKey(const Key('promo-code')), 'nope');
    await tester.tap(find.text('Apply'));
    await tester.pump();
    expect(find.textContaining("isn't valid"), findsOneWidget);
    await tester.enterText(find.byKey(const Key('promo-code')), 'columbus');
    await tester.tap(find.text('Apply'));
    await tester.pump();
    expect(Services.prefs.redeemedPromo, 'COLUMBUS');
    await tester.tap(find.text('Apply'));
    await tester.pump();
    expect(find.textContaining('already redeemed'), findsOneWidget);
    Services.prefs.redeemedPromo = null;
  });

  testWidgets('chat composer: one + menu, no overflow at 360px', (tester) async {
    await _pump(tester, ConversationScreen(conversation: MockData.conversations().first));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Add photo, sticker, voice, game'));
    await tester.pumpAndSettle();
    expect(find.text('Sticker'), findsOneWidget);
    expect(find.text('View-once photo'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('referral + insights + couples render cleanly', (tester) async {
    for (final w in const [ReferralScreen(), InsightsScreen(), CoupleScreen()]) {
      await _pump(tester, w);
      expect(tester.takeException(), isNull, reason: w.runtimeType.toString());
    }
  });
}
