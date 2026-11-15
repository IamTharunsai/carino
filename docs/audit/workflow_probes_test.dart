// AUDIT CHARACTERISATION ONLY: passing tests below reproduce current gaps.
// They are not regression assertions that the desired product works.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carino/data/mock_data.dart';
import 'package:carino/models/message.dart';
import 'package:carino/screens/onboarding/profile_creation_screen.dart';
import 'package:carino/screens/discover/discover_screen.dart';
import 'package:carino/screens/discover/profile_detail_screen.dart';
import 'package:carino/screens/discover/filters_screen.dart';
import 'package:carino/screens/connect/plan_detail_screen.dart';
import 'package:carino/screens/connect/post_plan_feedback_screen.dart';
import 'package:carino/screens/chats/conversation_screen.dart';
import 'package:carino/screens/you/settings_screen.dart';
import 'package:carino/screens/you/trust_safety_screen.dart';
import 'package:carino/services/services.dart';
import 'package:carino/theme/app_theme.dart';
import 'package:carino/widgets/state_kit.dart';
import 'package:carino/screens/experience/experience_screens.dart';
import 'package:carino/widgets/app_lock_gate.dart';
import '../../test/support/real_fonts.dart';

void main() {
  setUpAll(loadRealFonts);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Services.prefs.load();
    Services.prefs.bio = 'BEFORE';
    Services.prefs.gender = [];
    Services.prefs.wantToMeet = [];
    Services.prefs.promptAnswers = {};
    Services.prefs.liked.clear();
    Services.prefs.blocked.clear();
    Services.prefs.reflections.clear();
    Services.prefs.trustedContactName = '';
  });

  Future<void> open(WidgetTester t, Widget page, {bool pushed = false}) async {
    t.view.physicalSize = const Size(390, 844) * 2;
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: pushed
      ? Builder(builder:(ctx)=>Scaffold(body:TextButton(onPressed:()=>Navigator.of(ctx).push(
        MaterialPageRoute<void>(builder:(_)=>page)),child:const Text('OPEN')))) : page));
    if (pushed) { await t.tap(find.text('OPEN')); }
    await t.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester t, String value) async {
    if (find.text(value).evaluate().isEmpty) {
      await t.scrollUntilVisible(find.text(value), 220,
          scrollable: find.byType(Scrollable).first, maxScrolls: 45);
    }
    await t.ensureVisible(find.text(value).last);
    await t.pumpAndSettle();
    await t.tap(find.text(value).last);
    await t.pumpAndSettle();
  }

  Future<void> fillProfile(WidgetTester t) async {
    for (var i=0;i<3;i++) {
      await t.ensureVisible(find.byIcon(Icons.add_a_photo_outlined).first);
      await t.tap(find.byIcon(Icons.add_a_photo_outlined).first);
      await t.pumpAndSettle();
    }
    final bio=find.byWidgetPredicate((w)=>w is TextField && w.maxLength==300);
    await t.ensureVisible(bio);
    await t.enterText(bio,'AUDIT UNIQUE BIO');
    t.testTextInput.hide();
    await t.pumpAndSettle();
  }

  testWidgets('GAP F05 main Publish advances but discards entered bio', (t) async {
    var finished=false;
    await open(t,ProfileCreationScreen(onPublished:()=>finished=true));
    await fillProfile(t);
    await tapText(t,'Publish profile');
    expect(finished,isTrue);
    expect(Services.prefs.bio,'BEFORE');
  });

  testWidgets('CONTROL F05 preview Publish saves the same entered bio', (t) async {
    var finished=false;
    await open(t,ProfileCreationScreen(onPublished:()=>finished=true));
    await fillProfile(t);
    await tapText(t,'Preview profile');
    await tapText(t,'Looks right — publish');
    expect(finished,isTrue);
    expect(Services.prefs.bio,'AUDIT UNIQUE BIO');
  });

  testWidgets('GAP F13 pass leaves first Daily Drop candidate visible', (t) async {
    await open(t,const DiscoverScreen());
    await tapText(t,'Daily Drop · ${MockData.dailyDrop.where(fitsMe).length}');
    final member=MockData.dailyDrop.where(fitsMe).first;
    expect(find.textContaining(member.firstName),findsWidgets);
    final before=Services.analytics.actions['pass'] ?? 0;
    await t.dragFrom(const Offset(195,380),const Offset(-280,0));
    for(var i=0;i<10;i++) { await t.pump(const Duration(milliseconds:150)); }
    expect(find.textContaining(member.firstName),findsWidgets);
    expect(Services.analytics.actions['pass'],before+1);
  });

  testWidgets('GAP F19 first view-once open already shows consumed placeholder', (t) async {
    final msg=ChatMessage(id:'audit-photo',text:'Photo',fromMe:false,timeLabel:'now',
      mediaAsset:'assets/images/backdrop_match.jpg',viewOnce:true);
    final c=Conversation(id:'audit-view-once',memberId:MockData.members.first.id,
      mode:ChatMode.keep,messages:[msg]);
    await open(t,ConversationScreen(conversation:c));
    await t.tap(find.byType(Image).last);
    await t.pumpAndSettle();
    expect(msg.mediaConsumed,isTrue);
    expect(find.textContaining('already opened'),findsOneWidget);
  });

  testWidgets('GAP F31 Settings profile row opens safety centre', (t) async {
    await open(t,const SettingsScreen());
    await tapText(t,'Your profile');
    expect(find.byType(TrustSafetyScreen),findsOneWidget);
    await t.pageBack(); await t.pumpAndSettle();
    expect(find.byType(SettingsScreen),findsOneWidget);
  });

  testWidgets('GAP F23 proposer confirms without another person', (t) async {
    await open(t,PlanDetailScreen(member:MockData.members.first,
      placeType:'Coffee',timeLabel:'Tomorrow · 18:30'));
    await tapText(t,'Confirm plan');
    expect(find.text('Both confirmed'),findsOneWidget);
  });

  testWidgets('GAP F24 Decline template leaves proposal waiting', (t) async {
    final member=MockData.members.first;
    await open(t,PlanDetailScreen(member:member,placeType:'Coffee',timeLabel:'Tomorrow · 18:30'));
    await tapText(t,'Decline kindly');
    await tapText(t,'Send this message');
    expect(find.text('Waiting for ${member.firstName} to confirm'),findsOneWidget);
    expect(find.text('Message sent in your chat.'),findsOneWidget);
  });

  testWidgets('GAP deep profile prompt heart closes without recording like', (t) async {
    await open(t,ProfileDetailScreen(member:MockData.members.first),pushed:true);
    if (find.byTooltip('React to this prompt').evaluate().isEmpty) {
      await t.scrollUntilVisible(find.byTooltip('React to this prompt'),220,
          scrollable:find.byType(Scrollable).first,maxScrolls:45);
    }
    final heart=find.byTooltip('React to this prompt').first;
    await t.ensureVisible(heart); await t.pumpAndSettle();
    await t.tap(heart); await t.pumpAndSettle();
    expect(find.text('OPEN'),findsOneWidget);
    expect(Services.prefs.liked,isEmpty);
  });

  testWidgets('GAP deep Hide this profile only returns without storing hidden id', (t) async {
    await open(t,ProfileDetailScreen(member:MockData.members.first),pushed:true);
    await tapText(t,'Hide this profile');
    expect(find.text('OPEN'),findsOneWidget);
    expect(Services.prefs.liked,isEmpty);
    // No hide/pass storage exists on this route; source evidence accompanies this probe.
  });

  testWidgets('GAP deep error support callback has no rendered action', (t) async {
    var support=false;
    await open(t,AppErrorState(onRetry:(){},onSupport:()=>support=true));
    expect(find.text('Retry'),findsOneWidget);
    expect(find.textContaining('Support'),findsNothing);
    expect(support,isFalse);
  });

  testWidgets('GAP deep Open Settings default does not navigate', (t) async {
    await open(t,const PermissionDeniedState(permissionLabel:'Camera',whyNeeded:'Preview requires camera'));
    await tapText(t,'Open Settings');
    expect(find.byType(PermissionDeniedState),findsOneWidget);
    expect(t.takeException(),isNull);
  });

  testWidgets('GAP deep feedback note absent from saved preferences', (t) async {
    await open(t,PostPlanFeedbackScreen(member:MockData.members.first,placeType:'Coffee'));
    await t.tap(find.text('Yes').first); await t.pumpAndSettle();
    await t.ensureVisible(find.byType(TextField));
    await t.enterText(find.byType(TextField),'AUDIT PRIVATE NOTE SHOULD SAVE');
    t.testTextInput.hide();
    await tapText(t,'Save feedback');
    // AI stub has an asynchronous delay; pump in bounded increments.
    await t.pump(const Duration(seconds:2)); await t.pumpAndSettle();
    expect(Services.prefs.reflections,hasLength(1));
    final sp=await SharedPreferences.getInstance();
    expect(sp.getString('sync'),isNot(contains('AUDIT PRIVATE NOTE SHOULD SAVE')));
  });

  testWidgets('BACK preview returns to editor retaining in-memory bio', (t) async {
    await open(t,ProfileCreationScreen(onPublished:(){}));
    await fillProfile(t);
    await tapText(t,'Preview profile');
    await tapText(t,'Back to editing');
    final bio=find.byWidgetPredicate((w)=>w is TextField && w.maxLength==300);
    await t.scrollUntilVisible(bio,-180,scrollable:find.byType(Scrollable).first,maxScrolls:45);
    expect(t.widget<TextField>(bio).controller!.text,'AUDIT UNIQUE BIO');
    expect(Services.prefs.bio,'BEFORE');
  });

  testWidgets('CANCEL system Back dismisses decline without changing plan', (t) async {
    final member=MockData.members.first;
    await open(t,PlanDetailScreen(member:member,placeType:'Coffee',timeLabel:'Tomorrow · 18:30'));
    await tapText(t,'Decline kindly');
    await t.binding.handlePopRoute(); await t.pumpAndSettle();
    expect(find.text('Waiting for ${member.firstName} to confirm'),findsOneWidget);
    expect(find.text('Send this message'),findsNothing);
  });

  testWidgets('BACK filters returns without an Apply result', (t) async {
    final config=const FiltersConfig();
    await open(t,FiltersScreen(initial:config),pushed:true);
    await tapText(t,'Long-Term');
    await t.pageBack(); await t.pumpAndSettle();
    expect(find.text('OPEN'),findsOneWidget);
    expect(config.intention,isNull);
  });

  testWidgets('CANCEL like-options system Back does not spend allowance', (t) async {
    LikeChoice? result;
    final before=Services.prefs.sparksLeft(DateTime.now(),isPlus:Services.payments.isPlus);
    await open(t,Builder(builder:(ctx)=>TextButton(onPressed:() async {
      result=await showLikeOptions(ctx,MockData.members.first);
    },child:const Text('LIKE OPTIONS'))));
    await tapText(t,'LIKE OPTIONS');
    await t.binding.handlePopRoute(); await t.pumpAndSettle();
    expect(result,isNull);
    expect(Services.prefs.sparksLeft(DateTime.now(),isPlus:Services.payments.isPlus),before);
    expect(Services.prefs.liked,isEmpty);
  });

  testWidgets('LOCK failed unlock does not expose background interaction', (t) async {
    Services.prefs.appLock=true;
    Services.biometric.authenticatorOverride=(_) async => false;
    addTearDown(() {Services.prefs.appLock=false; Services.biometric.authenticatorOverride=null;});
    var tapped=false;
    await open(t,AppLockGate(child:TextButton(onPressed:()=>tapped=true,child:const Text('PRIVATE ACTION'))));
    expect(find.textContaining('is locked'),findsOneWidget);
    final absorbing=t.widgetList<AbsorbPointer>(find.byType(AbsorbPointer)).any((w)=>w.absorbing);
    expect(absorbing,isTrue);
    expect(tapped,isFalse);
  });
}
