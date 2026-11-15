// What you enter in onboarding is what the app shows you later.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carino/models/member.dart';
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
}
