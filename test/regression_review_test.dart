// Regression tests for the code-review findings on 1f128f8..HEAD (Nov 14).
// Written FIRST (TDD): each one reproduces a reported bug.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:carino/config/env.dart';
import 'package:carino/data/mock_data.dart';
import 'package:carino/screens/discover/discover_screen.dart';
import 'package:carino/screens/experience/experience_screens.dart';
import 'package:carino/screens/home_shell.dart';
import 'package:carino/screens/onboarding/age_gate_screen.dart';
import 'package:carino/screens/root_flow.dart';
import 'package:carino/services/services.dart';
import 'package:carino/theme/app_theme.dart';
import 'package:carino/widgets/app_lock_gate.dart';
import 'package:carino/widgets/secure_screen.dart';

Future<void> _phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() async {
    await Services.auth.signOut();
    SharedPreferences.setMockInitialValues({});
    await Services.prefs.load();
    Services.biometric.authenticatorOverride = null;
  });

  // 1. Biometric failures must never escape (permanent "Waiting…" lockout).
  test('biometric unlock returns false on ANY plugin error', () async {
    Services.biometric.authenticatorOverride = (_) async => throw StateError('LocalAuthException');
    expect(await Services.biometric.unlock('x'), isFalse);
  });

  // 2 + 7. Lock covers pushed routes, blocks taps, hides content from
  // screen readers, and engages on `inactive` (app-switcher snapshot).
  testWidgets('app lock covers every route, blocks taps, locks on inactive', (tester) async {
    await _phone(tester);
    Services.prefs.appLock = true;
    // The automatic unlock on open fails (e.g. user cancels the OS sheet).
    Services.biometric.authenticatorOverride = (_) async => false;
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => AppLockGate(child: child!),
      home: Scaffold(body: Center(child: ElevatedButton(onPressed: () => taps++, child: const Text('Secret chat')))),
    ));
    // Let the automatic unlock attempt on open finish (it fails: no OS here).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Cariño is locked'), findsOneWidget);
    await tester.tap(find.text('Secret chat'), warnIfMissed: false);
    expect(taps, 0, reason: 'content behind the lock must not be tappable');
    expect(find.bySemanticsLabel('Secret chat'), findsNothing);

    Services.biometric.authenticatorOverride = (_) async => true;
    await tester.tap(find.text('Unlock'));
    await tester.pump();
    expect(find.text('Cariño is locked'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.text('Cariño is locked'), findsOneWidget);
    Services.prefs.appLock = false;
  });

  // 3 + 4. Any sign-in path must route an UNVERIFIED account into the age
  // gate — never straight to Home.
  testWidgets('returning sign-in of an unverified account goes to the age gate', (tester) async {
    await _phone(tester);
    await Services.prefs.setMockVerified(false);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: const RootFlow()));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('I already have an account'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const Key('signin-username')), 'new@example.com');
    await tester.enterText(find.byKey(const Key('signin-password')), 'pw-12345');
    await tester.pump();
    await tester.tap(find.text('Sign in'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(HomeShell), findsNothing);
    expect(find.byType(AgeGateScreen), findsOneWidget);
  });

  testWidgets('returning sign-in of a verified account goes Home', (tester) async {
    await _phone(tester);
    await Services.prefs.setMockVerified(true);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: const RootFlow()));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('I already have an account'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const Key('signin-username')), 'me@example.com');
    await tester.enterText(find.byKey(const Key('signin-password')), 'pw-12345');
    await tester.pump();
    await tester.tap(find.text('Sign in'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(HomeShell), findsOneWidget);
    await Services.prefs.setMockVerified(false);
  });

  // 6. Under-21 block survives a fresh AgeGateScreen (back → create again).
  testWidgets('under-21 block persists across a new age gate', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: AgeGateScreen(onPassed: () {})));
    await tester.pump();
    await tester.drag(find.text('${DateTime.now().year}').first, const Offset(0, 120));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.textContaining('21+ only'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: AgeGateScreen(onPassed: () {})));
    await tester.pump();
    expect(find.textContaining('21+ only'), findsOneWidget,
        reason: 'a new age gate must stay blocked');
    expect(find.byType(BackButton), findsNothing);
  });

  // 8 + 9. Relationship status + couples data hygiene.
  test('status back to Single restores the previous visibility', () {
    final p = Services.prefs..visibility = 'Discovery';
    p.setRelationshipStatus('Married');
    expect(p.visibility, 'Paused');
    p.setRelationshipStatus('Single');
    expect(p.visibility, 'Discovery');
  });

  test('unlinking a partner clears shared couple data', () {
    final p = Services.prefs
      ..partnerName = 'A'
      ..coupleMemories.add('first date')
      ..coupleCalendar.add(('Fri', 'Dinner'));
    p.unlinkPartner();
    expect(p.partnerName, isNull);
    expect(p.coupleMemories, isEmpty);
    expect(p.coupleCalendar, isEmpty);
  });

  // Sparks: daily reset, Plus allowance 5.
  test('sparks reset each day and Plus gets 5', () {
    final p = Services.prefs;
    final day1 = DateTime(2026, 11, 14, 9);
    expect(p.sparksLeft(day1, isPlus: false), 1);
    expect(p.useSpark(day1, isPlus: false), isTrue);
    expect(p.useSpark(day1, isPlus: false), isFalse);
    expect(p.sparksLeft(day1.add(const Duration(days: 1)), isPlus: false), 1);
    expect(p.sparksLeft(day1.add(const Duration(days: 2)), isPlus: true), 5);
  });

  // Privacy: analytics never records the status VALUE.
  testWidgets('status change logs no personal value', (tester) async {
    await _phone(tester);
    Services.analytics.clear();
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: const CoupleScreen()));
    await tester.tap(find.text('Married'));
    await tester.pump();
    expect(Services.analytics.actions.keys.any((k) => k.contains('Married')), isFalse);
    Services.prefs.setRelationshipStatus('Single');
  });

  // Like options must not crash for people with no prompts.
  testWidgets('like options work for a member with no prompts', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: Builder(builder: (context) => TextButton(
            onPressed: () => showLikeOptions(context, MockData.friends.first),
            child: const Text('open'),
          )),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Like ${MockData.friends.first.firstName}'), findsOneWidget);
  });

  // 10. Long-press on the heart opens options (no Tooltip gesture conflict).
  testWidgets('long-press heart opens like options', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: const DiscoverScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    final heart = find.bySemanticsLabel(RegExp('Like. Long-press'));
    expect(find.ancestor(of: heart.first, matching: find.byType(Tooltip)), findsNothing);
    await tester.longPress(heart.first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Like '), findsWidgets);
    expect(find.text('Send like with note'), findsOneWidget);
  });

  // FLAG_SECURE: nested secure screens stay protected until the last closes.
  testWidgets('secure screens are reference-counted', (tester) async {
    await tester.pumpWidget(const SecureScreen(child: SecureScreen(child: SizedBox())));
    expect(SecureScreen.depth, 2);
    await tester.pumpWidget(const SecureScreen(child: SizedBox()));
    expect(SecureScreen.depth, 1);
    await tester.pumpWidget(const SecureScreen(enabled: false, child: SizedBox()));
    expect(SecureScreen.depth, 0);
  });

  // Release safety: a store build must never silently run on sample data.
  test('release build without a backend is refused; debug/demo is allowed', () {
    expect(Env.releaseMisconfigured(isRelease: true, configured: false, demoOverride: false), isTrue);
    expect(Env.releaseMisconfigured(isRelease: true, configured: true, demoOverride: false), isFalse);
    expect(Env.releaseMisconfigured(isRelease: false, configured: false, demoOverride: false), isFalse);
    expect(Env.releaseMisconfigured(isRelease: true, configured: false, demoOverride: true), isFalse,
        reason: 'explicit USE_MOCK_BACKEND=true demo/preview builds are allowed');
  });
}
