// Button-by-button workflow audit. For every screen, taps EVERY tappable
// thing (one at a time, on a fresh copy of the screen) and records where it
// went. Run: AUDIT=1 flutter test test/audit/button_audit_test.dart
// Output: build/audit/buttons.csv (+ DEAD lines printed).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carino/data/mock_data.dart';
import 'package:carino/models/message.dart';
import 'package:carino/screens/chats/chat_list_screen.dart';
import 'package:carino/screens/chats/conversation_screen.dart';
import 'package:carino/screens/chats/conversation_settings_screen.dart';
import 'package:carino/screens/chats/games_screen.dart';
import 'package:carino/screens/chats/social_screens.dart';
import 'package:carino/screens/connect/connect_screen.dart';
import 'package:carino/screens/connect/decompress_screens.dart';
import 'package:carino/screens/connect/incoming_call_screen.dart';
import 'package:carino/screens/connect/meet_irl_screens.dart';
import 'package:carino/screens/connect/plan_composer_screen.dart';
import 'package:carino/screens/connect/plan_detail_screen.dart';
import 'package:carino/screens/connect/plans_hub_screens.dart';
import 'package:carino/screens/connect/plans_list_screen.dart';
import 'package:carino/screens/connect/post_plan_feedback_screen.dart';
import 'package:carino/screens/connect/spark_session_screen.dart';
import 'package:carino/screens/discover/discover_screen.dart';
import 'package:carino/screens/discover/filters_screen.dart';
import 'package:carino/screens/discover/profile_detail_screen.dart';
import 'package:carino/screens/discover/worldwide_screen.dart';
import 'package:carino/screens/experience/experience_screens.dart';
import 'package:carino/screens/moments/moments_screen.dart';
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
import 'package:carino/screens/you/facets_screen.dart';
import 'package:carino/screens/you/likes_manager_screen.dart';
import 'package:carino/screens/you/notifications_screen.dart';
import 'package:carino/screens/you/paywall_screen.dart';
import 'package:carino/screens/you/privacy_centre_screen.dart';
import 'package:carino/screens/you/settings_screen.dart';
import 'package:carino/screens/you/support_screen.dart';
import 'package:carino/screens/you/sync_settings_screen.dart';
import 'package:carino/screens/you/trust_graph_screen.dart';
import 'package:carino/screens/you/trust_safety_screen.dart';
import 'package:carino/screens/you/wingperson_screen.dart';
import 'package:carino/screens/you/work_facet_screen.dart';
import 'package:carino/screens/you/you_screen.dart';
import 'package:carino/screens/you/my_profile_screen.dart';
import 'package:carino/theme/app_theme.dart';

import '../support/real_fonts.dart';

bool _flowStep = false; // set by onboarding callbacks
void _cb([Object? _]) => _flowStep = true;

class _Obs extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];
  int popped = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) pushed.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => popped++;
}

Map<String, Widget Function()> _screens() {
  final aria = MockData.memberById('m-aria');
  final sofia = MockData.memberById('m-sofia');
  Conversation conv(String id) => MockData.conversations().firstWhere((c) => c.id == id);
  return {
    'Welcome': () => WelcomeScreen(onContinue: _cb, onSignIn: _cb),
    'Sign in': () => SignInScreen(onSignedIn: _cb, onUseCode: _cb),
    'Age check': () => AgeGateScreen(onPassed: _cb),
    'Create account': () => CreateAccountScreen(onAuthenticated: _cb, onUseContact: _cb),
    'Phone or email': () => ContactScreen(onCodeSent: (_) {}, onSignIn: _cb),
    'Enter code': () => CodeScreen(contact: 'alex@example.com', onVerified: _cb, onChangeContact: _cb),
    'Verification intro': () => VerificationIntroScreen(onStart: _cb, onExit: _cb),
    'Verification steps': () => VerificationProviderScreen(onComplete: _cb, onCancel: _cb),
    'Verification result': () => VerificationResultScreen(onPassed: _cb, onRetry: _cb),
    'Waitlist': () => WaitlistScreen(onAdmitted: _cb),
    'Intentions': () => IntentionsScreen(onDone: _cb),
    'About you': () => IdentityScreen(onDone: _cb),
    'Taste quiz': () => TasteQuizScreen(onDone: _cb),
    'Profile creation': () => ProfileCreationScreen(onPublished: _cb),
    'Chats tab': () => const ChatListScreen(),
    'Chat (Aria)': () => ConversationScreen(conversation: conv('conv-aria')),
    'Chat (Sofia, Vanish)': () => ConversationScreen(conversation: conv('conv-sofia')),
    'Chat settings': () => ConversationSettingsScreen(conversation: conv('conv-aria'), member: aria),
    'Games': () => GamesScreen(member: sofia),
    'Friends & circles': () => const FriendsScreen(),
    'Group chat': () => GroupChatScreen(group: MockData.groups().first),
    'Stage tab': () => const StageScreen(),
    'Moments': () => const MomentsScreen(),
    'Dates tab': () => const DiscoverScreen(),
    'Filters': () => const FiltersScreen(initial: FiltersConfig()),
    'Profile (Dates)': () => ProfileDetailScreen(member: aria),
    'Profile (matched)': () => ProfileDetailScreen(member: aria, matched: true),
    'Worldwide': () => const WorldwideScreen(),
    'Plans tab': () => const ConnectScreen(),
    'Plans list': () => const PlansListScreen(),
    'Plan composer': () => PlanComposerScreen(member: aria),
    'Plan detail': () => PlanDetailScreen(member: aria, placeType: 'Coffee', timeLabel: 'Sat · 11:00', confirmed: true),
    'After-date check-in': () => PostPlanFeedbackScreen(member: aria, placeType: 'Coffee'),
    'Decompress': () => const DecompressScreen(),
    'Events': () => const EventsScreen(),
    'Spark Nights': () => const SparkNightsScreen(),
    'Group hangout': () => const GroupHangoutScreen(),
    'Tonight': () => const TonightScreen(),
    'Host a plan': () => const HostPlanScreen(),
    'Coffee chats': () => const CoffeeChatsScreen(),
    'Guilds': () => const GuildsScreen(),
    'Spark lobby': () => const SparkPreCallScreen(),
    'Spark call': () => SparkCallScreen(member: sofia),
    'Incoming call': () => IncomingCallScreen(member: sofia),
    'You tab': () => const YouScreen(),
    'Settings & account': () => const AccountCentreScreen(),
    'How I text & comfort': () => const SyncSettingsScreen(),
    'Settings': () => const SettingsScreen(),
    'Privacy Centre': () => const PrivacyCentreScreen(),
    'Trust & Safety': () => const TrustSafetyScreen(),
    'Support': () => const SupportScreen(),
    'Notifications': () => const NotificationsScreen(),
    'Likes & introductions': () => const LikesManagerScreen(),
    'Plus (paywall)': () => const PaywallScreen(),
    'Delete account': () => const DeleteAccountScreen(),
    'Facets': () => const FacetsScreen(),
    'Work facet': () => const WorkFacetScreen(),
    'Trust Graph': () => const TrustGraphScreen(),
    'Wingperson': () => const WingpersonScreen(),
    'Couples': () => const CoupleScreen(),
    'Invite & offers': () => const ReferralScreen(),
    'Your activity': () => const InsightsScreen(),
  };
}

// One entry per control: InkWell/InkResponse, plus bare GestureDetectors
// that aren't the inner detector of an InkResponse.
final _tappable = find.byElementPredicate((e) {
  final w = e.widget;
  if (w is InkResponse) return w.onTap != null || w.onLongPress != null;
  if (w is! GestureDetector || (w.onTap == null && w.onDoubleTap == null)) return false;
  var inner = false;
  e.visitAncestorElements((a) {
    if (a.widget is InkResponse) inner = true;
    return !inner && a.widget is! Material;
  });
  return !inner;
});

String _labelOf(WidgetTester t, Finder f) {
  final texts = find.descendant(of: f, matching: find.byType(Text));
  for (final e in texts.evaluate()) {
    final s = (e.widget as Text).data ?? (e.widget as Text).textSpan?.toPlainText();
    if (s != null && s.trim().isNotEmpty) return s.trim().replaceAll('\n', ' ');
  }
  final tip = find.ancestor(of: f, matching: find.byType(Tooltip));
  if (tip.evaluate().isNotEmpty) return 'icon: ${(tip.evaluate().first.widget as Tooltip).message}';
  final icon = find.descendant(of: f, matching: find.byType(Icon));
  if (icon.evaluate().isNotEmpty) {
    return 'icon 0x${(icon.evaluate().first.widget as Icon).icon?.codePoint.toRadixString(16)}';
  }
  return '(no label)';
}

String _fingerprint() {
  final b = StringBuffer();
  for (final e in find.byType(Text).evaluate()) {
    b.write((e.widget as Text).data ?? '');
  }
  // Selection is often shown only by an icon, colour or border.
  for (final e in find.byWidgetPredicate((w) => w is Switch || w is Checkbox || w is ChoiceChip ||
      w is FilterChip || w is Radio || w is SegmentedButton || w is TextField || w is EditableText || w is Icon ||
      w is Container || w is AnimatedContainer || w is DecoratedBox).evaluate()) {
    final w = e.widget;
    b.write(switch (w) {
      Switch s => s.value,
      Checkbox c => c.value,
      ChoiceChip c => c.selected,
      FilterChip c => c.selected,
      Radio r => r.groupValue,
      SegmentedButton s => s.selected,
      TextField f => f.controller?.text,
      EditableText t => t.obscureText,
      Icon i => '${i.icon?.codePoint}${i.color}',
      Container c => '${c.decoration}${c.color}',
      AnimatedContainer c => '${c.decoration}',
      DecoratedBox d => '${d.decoration}',
      _ => '',
    });
  }
  return b.toString();
}

void main() {
  final run = Platform.environment['AUDIT'] == '1';
  final rows = <String>['screen,button,outcome,detail'];

  setUpAll(() async {
    await loadRealFonts();
    // Clipboard etc. answer like a phone, so "Copied" confirmations show.
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  });
  tearDownAll(() {
    if (!run) return;
    Directory('build/audit').createSync(recursive: true);
    File('build/audit/buttons.csv').writeAsStringSync(rows.join('\n'));
  });

  for (final entry in _screens().entries) {
    testWidgets('audit ${entry.key}', skip: !run, (t) async {
      // Tall canvas so lazy lists build every row (each one gets tapped).
      t.view.physicalSize = const Size(400, 4000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);

      Future<_Obs> mount(int gen) async {
        final obs = _Obs();
        _flowStep = false;
        await t.pumpWidget(MaterialApp(
          key: ValueKey(gen),
          theme: AppTheme.dark(),
          navigatorObservers: [obs],
          home: entry.value(),
        ));
        for (var i = 0; i < 4; i++) {
          await t.pump(const Duration(milliseconds: 150));
        }
        t.takeException();
        return obs;
      }

      await mount(0);
      final count = _tappable.hitTestable().evaluate().length;
      final seen = <String>{};
      for (var i = 0; i < count; i++) {
        final obs = await mount(i + 1);
        final all = _tappable.hitTestable();
        if (i >= all.evaluate().length) break;
        final f = all.at(i);
        final rect = t.getRect(f);
        final key = '${rect.left.round()},${rect.top.round()},${rect.width.round()}';
        if (!seen.add(key)) continue; // same spot = same control
        final label = _labelOf(t, f);
        final before = _fingerprint();
        await t.tap(f, warnIfMissed: false);
        for (var k = 0; k < 4; k++) {
          await t.pump(const Duration(milliseconds: 200));
        }
        final err = t.takeException();
        String outcome, detail = '';
        if (_flowStep) {
          outcome = 'next step';
        } else if (obs.pushed.isNotEmpty) {
          final r = obs.pushed.last;
          if (r is PopupRoute || r is ModalBottomSheetRoute) {
            outcome = 'opens sheet';
          } else {
            outcome = 'opens screen';
            if (r is MaterialPageRoute) {
              final ctx = t.element(find.byType(MaterialApp));
              detail = r.builder(ctx).runtimeType.toString();
            }
          }
        } else if (obs.popped > 0) {
          outcome = 'goes back';
        } else if (find.byType(SnackBar).evaluate().isNotEmpty) {
          outcome = 'shows message';
          final s = find.descendant(of: find.byType(SnackBar), matching: find.byType(Text));
          if (s.evaluate().isNotEmpty) detail = (s.evaluate().first.widget as Text).data ?? '';
        } else if (err != null && '$err'.contains('MissingPlugin')) {
          outcome = 'external (phone/browser)';
        } else if (err != null) {
          outcome = 'ERROR';
          detail = '$err'.split('\n').first;
        } else if (_fingerprint() != before) {
          outcome = 'changes on page';
        } else {
          outcome = 'DEAD — nothing happens';
        }
        String q(String s) => '"${s.replaceAll('"', "'")}"';
        rows.add([q(entry.key), q(label), q(outcome), q(detail)].join(','));
        if (outcome.startsWith('DEAD') || outcome == 'ERROR') {
          // ignore: avoid_print
          print('${outcome.startsWith('DEAD') ? 'DEAD' : 'ERROR'} | ${entry.key} | $label | $detail');
        }
      }
      // Flush timers the screen started.
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 70));
    });
  }
}
