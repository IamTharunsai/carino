// Customer-view screenshot capture (not part of the normal test run).
//
//   CAPTURE=1 flutter test test/screenshots/capture_test.dart
//
// Renders every screen + key scenarios (empty, wrong input, errors,
// success) at 390x844 with the real Roboto + Material Icons fonts, and
// writes PNGs to build/screens/. Use them for UX review and store assets.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carino/config/app_config.dart';
import 'package:carino/data/mock_data.dart';
import 'package:carino/models/message.dart';
import 'package:carino/models/social.dart';
import 'package:carino/screens/chats/chat_list_screen.dart';
import 'package:carino/screens/chats/conversation_screen.dart';
import 'package:carino/screens/chats/games_screen.dart';
import 'package:carino/screens/chats/social_screens.dart';
import 'package:carino/screens/connect/connect_screen.dart';
import 'package:carino/screens/connect/decompress_screens.dart';
import 'package:carino/screens/connect/meet_irl_screens.dart';
import 'package:carino/screens/connect/plan_detail_screen.dart';
import 'package:carino/screens/connect/post_plan_feedback_screen.dart';
import 'package:carino/screens/you/sync_settings_screen.dart';
import 'package:carino/screens/connect/spark_session_screen.dart';
import 'package:carino/screens/discover/discover_screen.dart';
import 'package:carino/screens/experience/experience_screens.dart';
import 'package:carino/screens/discover/filters_screen.dart';
import 'package:carino/screens/discover/profile_detail_screen.dart';
import 'package:carino/screens/home_shell.dart';
import 'package:carino/screens/onboarding/age_gate_screen.dart';
import 'package:carino/features/onboarding/code_screen.dart';
import 'package:carino/features/onboarding/contact_screen.dart';
import 'package:carino/features/onboarding/create_account_screen.dart';
import 'package:carino/screens/onboarding/identity_screen.dart';
import 'package:carino/screens/onboarding/intentions_screen.dart';
import 'package:carino/screens/onboarding/profile_creation_screen.dart';
import 'package:carino/screens/onboarding/sign_in_screen.dart';
import 'package:carino/screens/onboarding/taste_quiz_screen.dart';
import 'package:carino/screens/onboarding/verification_flow_screen.dart';
import 'package:carino/screens/onboarding/verification_intro_screen.dart';
import 'package:carino/screens/onboarding/waitlist_screen.dart';
import 'package:carino/features/onboarding/welcome_screen.dart';
import 'package:carino/screens/stage/stage_screen.dart';
import 'package:carino/screens/you/delete_account_screen.dart';
import 'package:carino/screens/you/notifications_screen.dart';
import 'package:carino/screens/you/paywall_screen.dart';
import 'package:carino/screens/you/privacy_centre_screen.dart';
import 'package:carino/screens/you/settings_screen.dart';
import 'package:carino/screens/you/trust_safety_screen.dart';
import 'package:carino/screens/you/my_profile_screen.dart';
import 'package:carino/theme/app_theme.dart';
import 'package:carino/widgets/glass_card.dart';
import 'package:carino/widgets/match_celebration.dart';
import '../support/real_fonts.dart';

final bool _capture = Platform.environment['CAPTURE'] == '1';
const _size = Size(390, 844);
final _outDir = Directory('build/screens');

Future<void> _loadFonts() => loadRealFonts();

typedef Scenario = Future<void> Function(WidgetTester tester);

class Shot {
  const Shot(this.name, this.build, [this.act]);
  final String name;
  final Widget Function() build;
  final Scenario? act;
}

Future<void> _snap(WidgetTester tester, Shot shot) async {
  final key = GlobalKey();
  tester.view.physicalSize = _size * 2;
  tester.view.devicePixelRatio = 2;
  await tester.pumpWidget(RepaintBoundary(
    key: key,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.light(),
      themeMode: ThemeMode.dark,
      home: shot.build(),
    ),
  ));
  // Let asset images decode, then settle a few frames.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
  await tester.pump(const Duration(milliseconds: 500));
  if (shot.act != null) await shot.act!(tester);
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pump(const Duration(milliseconds: 600));
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('${_outDir.path}/${shot.name}.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
  final err = tester.takeException(); // capture continues; logged for review
  if (err != null) {
    // ignore: avoid_print
    print('LAYOUT ISSUE in ${shot.name}: $err');
  }
}

Future<void> _tapText(WidgetTester t, String text) async {
  await t.tap(find.text(text).first, warnIfMissed: false);
  await t.pump(const Duration(milliseconds: 400));
}

/// Bottom-bar labels are the LAST match (the bar builds after the body).
Future<void> _tapTab(WidgetTester t, String label) async {
  await t.tap(find.text(label).last, warnIfMissed: false);
  await t.pump(const Duration(milliseconds: 400));
}

void main() {
  final shots = <Shot>[
    // ---- Onboarding --------------------------------------------------------
    Shot('01_welcome', () => WelcomeScreen(onContinue: () {}, onSignIn: () {})),
    Shot('02_signin_empty', () => SignInScreen(onSignedIn: () {}, onUseCode: () {})),
    Shot('03_signin_required_errors', () => SignInScreen(onSignedIn: () {}, onUseCode: () {}),
        (t) async {
      await t.enterText(find.byKey(const Key('signin-username')), 'x');
      await t.enterText(find.byKey(const Key('signin-username')), '');
      await t.enterText(find.byKey(const Key('signin-password')), 'x');
      await t.enterText(find.byKey(const Key('signin-password')), '');
      await t.pump();
    }),
    Shot('04_signin_filled_password_shown', () => SignInScreen(onSignedIn: () {}, onUseCode: () {}),
        (t) async {
      await t.enterText(find.byKey(const Key('signin-username')), 'maya@example.com');
      await t.enterText(find.byKey(const Key('signin-password')), 'correct horse');
      await t.tap(find.byTooltip('Show password'));
      await t.pump();
    }),
    Shot('05_dob_default_today', () => OnboardingBack(onBack: () {}, child: AgeGateScreen(onPassed: () {}))),
    Shot('06_dob_scrolled_adult', () => AgeGateScreen(onPassed: () {}), (t) async {
      await t.drag(find.text('${DateTime.now().year}').first, const Offset(0, 400));
      await t.pump(const Duration(seconds: 1));
    }),
    Shot('07_dob_under21_blocked', () => AgeGateScreen(onPassed: () {}), (t) async {
      await t.drag(find.text('${DateTime.now().year}').first, const Offset(0, 120));
      await t.pump(const Duration(seconds: 1));
      await _tapText(t, 'Continue');
    }),
    Shot('07a_create_account', () => CreateAccountScreen(onAuthenticated: () {}, onUseContact: () {})),
    Shot('08_otp_contact', () => ContactScreen(onCodeSent: (_) {}, onSignIn: () {})),
    Shot('09_otp_code', () => CodeScreen(contact: 'alex@example.com', onVerified: () {}, onChangeContact: () {})),
    Shot('10_verification_intro', () => VerificationIntroScreen(onStart: () {}, onExit: () {})),
    Shot('11_verification_provider', () => VerificationProviderScreen(onComplete: () {}, onCancel: () {})),
    Shot('12_verification_result', () => VerificationResultScreen(onPassed: () {}, onRetry: () {})),
    Shot('13_intentions', () => IntentionsScreen(onDone: (_) {})),
    Shot('14_identity', () => IdentityScreen(onDone: () {})),
    Shot('15_taste_quiz', () => TasteQuizScreen(onDone: () {})),
    Shot('17_profile_creation', () => ProfileCreationScreen(onPublished: () {})),
    Shot('19_waitlist', () => WaitlistScreen(onAdmitted: () {})),
    // ---- Home tabs ---------------------------------------------------------
    Shot('20_tab_chats', () => const HomeShell()),
    Shot('21_tab_stage', () => const HomeShell(), (t) => _tapTab(t, 'Feed')),
    Shot('22_tab_dates', () => const HomeShell(), (t) => _tapTab(t, 'Dates')),
    Shot('23_tab_plans', () => const HomeShell(), (t) => _tapTab(t, 'Plans')),
    Shot('24_tab_you', () => const HomeShell(), (t) => _tapTab(t, 'You')),
    // ---- Dating flows ------------------------------------------------------
    Shot('25_profile_detail', () => ProfileDetailScreen(member: MockData.memberById('m-rowan'))),
    Shot('26_match_celebration', () => MatchCelebrationOverlay(
        member: MockData.memberById('m-aria'),
        onMessage: () {}, onSuggestPlan: () {}, onPlayGame: () {}, onClose: () {})),
    Shot('27_chat_keep', () => ConversationScreen(conversation: MockData.conversations().first)),
    Shot('28_chat_vanish', () => ConversationScreen(conversation: MockData.conversations()[1])),
    Shot('29_chat_scam_warning', () => ConversationScreen(conversation: MockData.conversations().first),
        (t) async {
      await t.enterText(find.byType(TextField).last, 'can you send me money on venmo');
      await t.tap(find.byTooltip('Send'));
      await t.pump(const Duration(milliseconds: 600));
    }),
    Shot('30_group_chat', () => GroupChatScreen(group: MockData.groups().first)),
    Shot('31_games', () => GamesScreen(member: MockData.memberById('m-sofia'))),
    Shot('32_spark_precall', () => const SparkPreCallScreen()),
    Shot('33_spark_call', () => SparkCallScreen(member: MockData.memberById('m-sofia'))),
    Shot('34_plan_detail', () => PlanDetailScreen(
        member: MockData.memberById('m-aria'), placeType: 'Coffee', timeLabel: 'Sat · 11:00', confirmed: true)),
    Shot('35_filters', () => const FiltersScreen(initial: FiltersConfig())),
    Shot('36_events', () => const EventsScreen()),
    Shot('37_friends', () => const FriendsScreen()),
    // ---- You / settings / money -------------------------------------------
    Shot('38_paywall', () => const PaywallScreen()),
    Shot('39_settings', () => const SettingsScreen()),
    Shot('40_privacy_centre', () => const PrivacyCentreScreen()),
    Shot('41_trust_safety', () => const TrustSafetyScreen()),
    Shot('42_notifications', () => const NotificationsScreen()),
    Shot('43_delete_account', () => const DeleteAccountScreen()),
    Shot('44_stage_feed', () => const StageScreen()),
    Shot('45_discover', () => const DiscoverScreen()),
    Shot('46_connect', () => const ConnectScreen()),
    Shot('47_chats', () => const ChatListScreen()),
    Shot('48_you', () => const YouScreen()),
    Shot('55_decompress', () => const DecompressScreen()),
    Shot('56_decompress_booking', () => const DecompressScreen(), (t) async {
      await t.tap(find.text('Kayak the Olentangy'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
    }),
    Shot('57_phone_down', () => const PhoneDownScreen(planTitle: 'Sunset walk on the Scioto Mile')),
    Shot('58_chat_you_both', () => ConversationScreen(conversation: MockData.conversations().first), (t) async {
      await t.drag(find.byType(Scrollable).first, const Offset(0, 600));
      await t.pumpAndSettle();
    }),
    Shot('59_their_style', () => ConversationScreen(conversation: MockData.conversations().first), (t) async {
      await t.drag(find.byType(Scrollable).first, const Offset(0, 600));
      await t.pumpAndSettle();
      await t.tap(find.text('Their style'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
    }),
    Shot('60_chat_bridge_tone', () => ConversationScreen(conversation: MockData.conversations().first), (t) async {
      await t.tap(find.byTooltip('Add photo, sticker, voice, game'));
      await t.pumpAndSettle();
      await t.tap(find.text('Add a tone tag'));
      await t.pumpAndSettle();
      await t.tap(find.text('joking'));
      await t.pumpAndSettle();
    }),
    Shot('61_comfort_hold', () => ConversationScreen(conversation: MockData.conversations()[1]), (t) async {
      await t.tap(find.byTooltip('Spark video (connections only)'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
    }),
    Shot('62_how_i_text', () => const SyncSettingsScreen()),
    Shot('63_after_date_checkin', () => PostPlanFeedbackScreen(member: MockData.memberById('m-aria'), placeType: 'Coffee'), (t) async {
      await t.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await t.pumpAndSettle();
    }),
    Shot('65_mood_low', () => const DecompressScreen(), (t) async {
      await t.tap(find.text('🌧️ Low'));
      await t.pumpAndSettle();
    }),
    Shot('66_one_minute', () => const OneMinuteScreen(step: 'Step outside for one minute of daylight.')),
    Shot('67_games_personal', () => GamesScreen(member: MockData.memberById('m-aria')), (t) async {
      await t.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await t.pumpAndSettle();
    }),
    Shot('68_opens_first', () => ConversationScreen(
        conversation: Conversation(id: 'c-p', memberId: 'm-priya', mode: ChatMode.keep, messages: []))),
    Shot('64_profile_how_they_text', () => ProfileDetailScreen(member: MockData.memberById('m-aria')), (t) async {
      await t.drag(find.byType(Scrollable).first, const Offset(0, -900));
      await t.pumpAndSettle();
    }),
    Shot('49_couples', () => const CoupleScreen()),
    Shot('50_referral', () => const ReferralScreen()),
    Shot('51_insights', () => const InsightsScreen()),
    Shot('52_like_options', () => const DiscoverScreen(), (t) async {
      await t.longPress(find.bySemanticsLabel(RegExp('Send a heart. Long-press')).first, warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 600));
    }),
    Shot('53_chat_attach_menu', () => ConversationScreen(conversation: MockData.conversations().first),
        (t) async {
      await t.tap(find.byTooltip('Add photo, sticker, voice, game'));
      await t.pump(const Duration(milliseconds: 600));
    }),
    Shot('54_settings_security', () => const SettingsScreen(), (t) async {
      await t.drag(find.byType(ListView).first, const Offset(0, -900));
      await t.pump(const Duration(milliseconds: 400));
    }),
  ];

  setUpAll(() async {
    if (!_capture) return;
    await _loadFonts();
    _outDir.createSync(recursive: true);
    // Silence the circle import (keeps analyzer quiet if unused elsewhere).
    Circle.values.length;
    AppConfig.appName.length;
  });

  for (final shot in shots) {
    testWidgets('capture ${shot.name}', (tester) async {
      await _snap(tester, shot);
      tester.view.reset();
    }, skip: !_capture);
  }
}
