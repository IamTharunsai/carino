// Onboarding UI rules requested by the founder (Nov 14):
// sign-in required fields + eye toggle, DOB wheels default to today and
// can't continue untouched, back button on onboarding pages, welcome copy.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carino/screens/onboarding/age_gate_screen.dart';
import 'package:carino/screens/onboarding/sign_in_screen.dart';
import 'package:carino/features/onboarding/welcome_screen.dart';
import 'package:carino/theme/app_theme.dart';
import 'package:carino/widgets/glass_card.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360, 740) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: child));
  await tester.pump(const Duration(milliseconds: 300));
}

ElevatedButton _button(WidgetTester tester, String label) => tester.widget<ElevatedButton>(
    find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is ElevatedButton)));

void main() {
  test('age math: 21st birthday tomorrow is still 20', () {
    expect(ageOn(DateTime(2005, 11, 15), DateTime(2026, 11, 14)), 20);
    expect(ageOn(DateTime(2005, 11, 14), DateTime(2026, 11, 14)), 21);
  });

  testWidgets('sign in: required fields block submit, eye toggles masking',
      (tester) async {
    var signedIn = false;
    await _pump(tester, SignInScreen(onSignedIn: () => signedIn = true, onUseCode: () {}));
    expect(find.text(' *', findRichText: true), findsNothing); // inside rich labels
    expect(_button(tester, 'Sign in').onPressed, isNull);

    await tester.enterText(find.byKey(const Key('signin-username')), 'maya@example.com');
    await tester.pump();
    expect(_button(tester, 'Sign in').onPressed, isNull, reason: 'password still empty');

    await tester.enterText(find.byKey(const Key('signin-password')), 'secret-pass');
    await tester.pump();
    final field = tester.widget<TextField>(find.byKey(const Key('signin-password')));
    expect(field.obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byKey(const Key('signin-password'))).obscureText, isFalse);

    expect(find.text('Forgot password?'), findsOneWidget);
    expect(_button(tester, 'Sign in').onPressed, isNotNull);
    await tester.tap(find.text('Sign in'));
    await tester.pump(const Duration(seconds: 1));
    expect(signedIn, isTrue);
  });

  testWidgets('DOB: wheels start on today, continue disabled until scrolled',
      (tester) async {
    await _pump(tester, AgeGateScreen(onPassed: () {}));
    final now = DateTime.now();
    expect(find.text('${now.year}'), findsWidgets);
    expect(find.text('Scroll to your date of birth'), findsOneWidget);
    expect(_button(tester, 'Continue').onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding pages show a back button', (tester) async {
    var back = 0;
    await _pump(
      tester,
      OnboardingBack(onBack: () => back++, child: AgeGateScreen(onPassed: () {})),
    );
    await tester.tap(find.byType(BackButton));
    expect(back, 1);
  });

  testWidgets('welcome matches Figma 01.01: copy, both buttons, legal line', (tester) async {
    var created = false, signedIn = false;
    await _pump(tester, WelcomeScreen(onContinue: () => created = true, onSignIn: () => signedIn = true));
    expect(find.text('A little spark.'), findsOneWidget);
    expect(find.text('Meet someone.\nMake a memory.'), findsOneWidget);
    expect(find.text('Real people. Real plans.'), findsOneWidget);
    // Small phone: the legal line sits below the fold.
    await tester.dragUntilVisible(find.text('21+ only'), find.byType(ListView), const Offset(0, -200));
    expect(find.text('21+ only'), findsOneWidget);
    await tester.tap(find.text('Create an account'));
    await tester.tap(find.text('I already have an account'));
    expect(created && signedIn, isTrue);
    expect(tester.takeException(), isNull);
  });
}
