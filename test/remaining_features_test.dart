import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carino/data/mock_data.dart';
import 'package:carino/models/social.dart';
import 'package:carino/screens/chats/social_screens.dart';
import 'package:carino/screens/you/facets_screen.dart';
import 'package:carino/screens/you/work_facet_screen.dart';
import 'package:carino/screens/you/trust_graph_screen.dart';
import 'package:carino/screens/connect/connect_screen.dart';
import 'package:carino/services/services.dart';
import 'package:carino/theme/app_theme.dart';
import 'package:carino/widgets/plan_split_card.dart';

void main() {
  Future<void> open(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(360, 740) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: screen));
    await tester.pumpAndSettle();
  }

  testWidgets('trust preview rejects wrong code and saves only my vouch',
      (tester) async {
    final saved = {...Services.prefs.givenVouches};
    final received = {...Services.trust.vouches};
    addTearDown(() {
      Services.prefs.givenVouches
        ..clear()
        ..addAll(saved);
    });
    await open(tester, const TrustGraphScreen());
    await tester.enterText(find.byType(TextField).first, 'wrong');
    await tester.tap(find.text('Confirm in demo'));
    await tester.pumpAndSettle();
    expect(find.text('The codes do not match.'), findsOneWidget);
    final codeText =
        tester.widget<Text>(find.textContaining('Preview code:')).data!;
    await tester.enterText(
        find.byType(TextField).first, codeText.split(': ').last);
    await tester.tap(find.text('Confirm in demo'));
    await tester.pumpAndSettle();
    expect(find.text('The codes do not match.'), findsNothing);
    await tester.scrollUntilVisible(find.text('Save my vouch in demo'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.enterText(
        find.byType(TextField).last, 'Thoughtful collaborator');
    await tester.ensureVisible(find.text('Save my vouch in demo'));
    await tester.tap(find.text('Save my vouch in demo'));
    await tester.pumpAndSettle();
    expect(Services.prefs.givenVouches[MockData.friends.first.id],
        'Thoughtful collaborator');
    expect(Services.trust.vouches, received);
    expect(tester.takeException(), isNull);
  });

  testWidgets('facet audience changes only the selected facet', (tester) async {
    final saved = {...Services.prefs.facetAudience['Photos']!};
    addTearDown(() => Services.prefs.facetAudience['Photos'] = saved);
    await open(tester, const FacetsScreen());
    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Only me').last);
    await tester.pumpAndSettle();
    expect(Services.prefs.facetAudience['Photos']!['Public'], 'hidden');
    expect(Services.prefs.facetAudience['Photos']!['Dating'], saved['Dating']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('work editor validates role and saves choices', (tester) async {
    final role = Services.prefs.workRole;
    final building = Services.prefs.workBuilding;
    final openTo = {...Services.prefs.workOpenTo};
    addTearDown(() {
      Services.prefs
        ..workRole = role
        ..workBuilding = building
        ..workOpenTo = openTo;
    });
    await open(tester, const WorkFacetScreen());
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.tap(find.text('Save work facet'));
    await tester.pumpAndSettle();
    expect(find.text('Add your role.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Designer');
    await tester.enterText(find.byType(TextFormField).last, 'Community tools');
    await tester.tap(find.text('Save work facet'));
    await tester.pumpAndSettle();
    expect(Services.prefs.workRole, 'Designer');
    expect(Services.prefs.workBuilding, 'Community tools');
  });

  testWidgets('split rejects invalid input and persists own paid mark',
      (tester) async {
    Services.prefs.planSplits.remove('test-plan');
    addTearDown(() => Services.prefs.planSplits.remove('test-plan'));
    const card = PlanSplitCard(
        planKey: 'test-plan', otherId: 'friend', otherName: 'Maya');
    await open(
        tester, const Scaffold(body: SingleChildScrollView(child: card)));
    await tester.enterText(find.byType(TextField), '1.001');
    await tester.tap(find.text('Calculate shares'));
    await tester.pumpAndSettle();
    expect(Services.prefs.planSplits['test-plan'], isNull);
    await tester.enterText(find.byType(TextField), '10.01');
    await tester.tap(find.text('Calculate shares'));
    await tester.pumpAndSettle();
    expect(find.text('\$5.01'), findsOneWidget);
    expect(find.text('\$5.00'), findsOneWidget);
    await tester.tap(find.text('Mark my share paid'));
    await tester.pumpAndSettle();
    expect(Services.prefs.planSplits['test-plan']!.mySharePaid, isTrue);
    await tester.tap(find.text('Edit total (resets paid mark)'));
    await tester.pumpAndSettle();
    expect(Services.prefs.planSplits['test-plan'], isNull);
  });

  testWidgets('group catch-up, Vanish and honest voice stub are reachable',
      (tester) async {
    final group = GroupChat(id: 'test', name: 'Friends', memberIds: [
      MockData.friends.first.id
    ], messages: [
      GroupMessage(
          senderId: MockData.friends.first.id,
          text: 'Coffee tomorrow?',
          timeLabel: 'now')
    ]);
    await open(tester, GroupChatScreen(group: group));
    await tester.tap(find.byTooltip('Chat extras'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI catch-up'));
    await tester.pumpAndSettle();
    expect(find.textContaining('talked timing:'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Back to full thread'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Chat extras'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enable Vanish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enable in demo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'See you there');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(group.messages.last.expiresAt, isNotNull);
    expect(group.messages.first.expiresAt, isNull);
    await tester.tap(find.byTooltip('Chat extras'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voice notes & translation'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nothing is being recorded'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('No-Counts removes Likes You total immediately', (tester) async {
    Services.prefs.noCounts.value = false;
    addTearDown(() => Services.prefs.noCounts.value = false);
    await open(tester, const ConnectScreen());
    await tester.scrollUntilVisible(find.textContaining('people like'), 250);
    Services.prefs.noCounts.value = true;
    await tester.pumpAndSettle();
    expect(find.text('People who like you'), findsOneWidget);
    expect(find.textContaining('people like'), findsNothing);
  });
}
