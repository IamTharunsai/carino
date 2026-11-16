import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../data/mock_data.dart';
import '../models/agent.dart';
import '../models/circle.dart';
import '../models/member.dart';
import '../models/message.dart';
import '../models/plan.dart';
import '../models/presence.dart';
import '../models/ticket.dart';
import 'drop_tuning.dart';
import 'outcomes.dart' as outcomes_logic;
import 'presence.dart' as presence_logic;

/// One recorded swipe, kept so the most recent one can be undone
/// (blueprint undo affordance on S-015/S-016 — a mis-swipe is recoverable,
/// never a dead end).
class _SwipeRecord {
  const _SwipeRecord(this.member,
      {required this.fromDrop, required this.createdMatch});

  final Member member;

  /// True when the swipe happened in the Daily Drop deck, so an undo
  /// restores the member to that deck rather than the main one.
  final bool fromDrop;

  /// True when this like created a match, so an undo removes it.
  final bool createdMatch;
}

/// Session app state: discovery decks, swipe history, matches and
/// conversations — the single source of truth screens read and mutate.
///
/// Owned by [Services.store]; screens must never keep their own copies of
/// deck/match/conversation state (two copies of a deck is how members get
/// double-swiped or matches get lost). Screens listen via [ChangeNotifier]
/// and rebuild from the store's lists.
///
/// MOCK MODE note: decks and conversations seed from [MockData]. In live
/// mode the same lists are hydrated by BackendService queries — the store's
/// mutation contract (record/undo/block/hide) stays identical.
class AppStore extends ChangeNotifier {
  /// Main discovery deck (S-015), front = next card.
  List<Member> deck = List<Member>.of(MockData.members);

  /// Daily Drop deck (S-016) — the finite curated set.
  List<Member> dropDeck = List<Member>.of(MockData.dailyDrop);

  /// Every member swiped this session (like or pass, either deck).
  final Set<String> swipedIds = <String>{};

  /// Members the signed-in user is matched with. MockData.matches is
  /// List<MatchConnection>; the store tracks the matched MEMBERS (match
  /// metadata lives on the connection models the Connect tab renders
  /// from its own source).
  List<Member> matches = MockData.matches.map((c) => c.member).toList();

  /// All conversations, built ONCE here — MockData.conversations() mints
  /// fresh objects per call, and chat state (appended messages, unread
  /// counts) must persist on the same instances for the whole session.
  List<Conversation> conversations = MockData.conversations();

  /// Blocked member ids — blocked members never resurface anywhere.
  final Set<String> blockedIds = <String>{};

  final List<_SwipeRecord> _swipeHistory = [];

  // --- Swipes ---------------------------------------------------------------

  /// Records a pass. Returns true when the pass was newly recorded
  /// (false when the member had already been swiped).
  bool recordPass(Member m, {bool fromDrop = false}) {
    if (!swipedIds.add(m.id)) return false;
    _deckFor(fromDrop).removeWhere((x) => x.id == m.id);
    _swipeHistory
        .add(_SwipeRecord(m, fromDrop: fromDrop, createdMatch: false));
    notifyListeners();
    return true;
  }

  /// Records a like. A match is created — and true returned — ONLY when
  /// [Member.likesYouBack] is true (the like was mutual). A one-sided like
  /// is recorded (the member leaves the deck) but returns false: the app
  /// never presents a one-sided like as a match.
  /// Members the user Super Liked (priority likes, S-015). In live mode
  /// this is the set the feed ranking boosts; the store keeps it truthful.
  final Set<String> superLikedIds = <String>{};

  bool recordLike(Member m, {bool fromDrop = false, bool superLike = false}) {
    if (!swipedIds.add(m.id)) {
      return matches.any((x) => x.id == m.id);
    }
    if (superLike) superLikedIds.add(m.id);
    _deckFor(fromDrop).removeWhere((x) => x.id == m.id);
    var createdMatch = false;
    if (m.likesYouBack && !matches.any((x) => x.id == m.id)) {
      matches.add(m);
      createdMatch = true;
    }
    _swipeHistory
        .add(_SwipeRecord(m, fromDrop: fromDrop, createdMatch: createdMatch));
    notifyListeners();
    return createdMatch;
  }

  /// Undoes the most recent swipe: the member returns to the FRONT of the
  /// deck they were swiped from, and a match that swipe created is
  /// removed. Returns the restored member, or null when there is nothing
  /// to undo.
  Member? undoLastSwipe() {
    if (_swipeHistory.isEmpty) return null;
    final record = _swipeHistory.removeLast();
    swipedIds.remove(record.member.id);
    superLikedIds.remove(record.member.id);
    if (record.createdMatch) {
      matches.removeWhere((x) => x.id == record.member.id);
    }
    final target = _deckFor(record.fromDrop);
    if (!target.any((x) => x.id == record.member.id)) {
      target.insert(0, record.member);
    }
    notifyListeners();
    return record.member;
  }

  List<Member> _deckFor(bool fromDrop) => fromDrop ? dropDeck : deck;

  // --- Conversations ----------------------------------------------------------

  /// Finds the conversation with [memberId], or creates an empty one and
  /// caches it so later lookups return the same instance.
  Conversation conversationFor(String memberId) {
    for (final c in conversations) {
      if (c.memberId == memberId) return c;
    }
    final created = Conversation(
      id: 'conv-$memberId',
      memberId: memberId,
      mode: ChatMode.keep,
      messages: [],
    );
    conversations.add(created);
    notifyListeners();
    return created;
  }

  /// Appends a message to the conversation with [conversationId] and
  /// notifies listeners. Unknown ids are ignored (a stale UI handle must
  /// never crash the store).
  void appendMessage(String conversationId, ChatMessage msg) {
    for (final c in conversations) {
      if (c.id == conversationId) {
        c.messages.add(msg);
        notifyListeners();
        return;
      }
    }
  }

  /// Total unread messages across all conversations (tab badge source).
  int get unreadChats =>
      conversations.fold(0, (sum, c) => sum + c.unreadCount);

  // --- Safety -----------------------------------------------------------------

  /// Blocks a member: gone from both decks and from matches, and recorded
  /// in [blockedIds] so they never resurface. (BackendService.applyBlock
  /// propagates the block server-side in live mode.)
  void blockMember(String id) {
    blockedIds.add(id);
    deck.removeWhere((m) => m.id == id);
    dropDeck.removeWhere((m) => m.id == id);
    matches.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  /// Hides a member from both decks without blocking (e.g. "not
  /// interested" from a profile surface).
  void hideMember(String id) {
    deck.removeWhere((m) => m.id == id);
    dropDeck.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // --- Wave 1 · Post→Plan + Tonight Near Me (CROWD-FEATURES #9/#10) -------

  /// Open group plans (seeded + created in-session). Session state,
  /// like conversations — a plan created from a chat or a Moment must
  /// still exist when the member lands in the Plans hub.
  final List<OpenPlan> _openPlans = MockData.openPlans();
  List<OpenPlan> get openPlans => List.unmodifiable(_openPlans);

  /// Plans starting this evening (the Tonight Near Me feed).
  List<OpenPlan> get tonightPlans =>
      _openPlans.where((p) => p.tonight).toList();

  OpenPlan? planById(String id) {
    for (final p in _openPlans) {
      if (p.id == id) return p;
    }
    return null;
  }

  int _planSeq = 0;

  /// Creates a plan hosted by the signed-in member (Post→Plan). The
  /// creator is the first attendee and starts [PlanJoinState.going].
  OpenPlan createPlan({
    required String title,
    required String place,
    required String timeLabel,
    required bool tonight,
    required int groupSize,
    bool instantJoin = false,
    String? sourceLabel,
    String note = '',
    bool decompress = false,
    int durationMinutes = 120,
  }) {
    final plan = OpenPlan(
      id: 'op-mine-${++_planSeq}',
      title: title.trim(),
      place: place.trim(),
      timeLabel: timeLabel,
      tonight: tonight,
      groupSize: groupSize,
      hostId: 'me',
      attendeeIds: ['me'],
      instantJoin: instantJoin,
      sourceLabel: sourceLabel,
      note: note.trim(),
      decompress: decompress,
      durationMinutes: durationMinutes,
      myState: PlanJoinState.going,
    );
    _openPlans.insert(0, plan);
    notifyListeners();
    return plan;
  }

  /// Joins or requests to join a plan, per the host's setting. Returns
  /// false when the join is impossible (full, already involved, own
  /// plan) so the UI explains instead of pretending it worked.
  bool requestJoinPlan(String planId) {
    final plan = planById(planId);
    if (plan == null || plan.hostedByMe) return false;
    if (plan.myState != PlanJoinState.none) return false;
    if (plan.isFull) return false;
    if (plan.instantJoin) {
      plan.myState = PlanJoinState.going;
      plan.attendeeIds.add('me');
    } else {
      plan.myState = PlanJoinState.requested;
    }
    notifyListeners();
    return true;
  }

  /// Cancels a join request or leaves a plan the member had joined.
  bool leavePlan(String planId) {
    final plan = planById(planId);
    if (plan == null || plan.hostedByMe) return false;
    if (plan.myState == PlanJoinState.none) return false;
    plan.myState = PlanJoinState.none;
    plan.attendeeIds.remove('me');
    notifyListeners();
    return true;
  }

  // --- Wave 1 · Cariño Tables (CROWD-FEATURES #11) -------------------------

  /// The member's Tables standing (no-show policy state).
  TablesStanding tablesStanding = TablesStanding.good;

  /// The one active Tables booking, if any.
  TableBooking? tableBooking;

  /// Seats booked this session, per night id, on top of the seed
  /// counts in [MockData.tableNights].
  final Map<String, int> _myTableSeats = {};

  TableNight? tableNightById(String id) {
    for (final n in MockData.tableNights) {
      if (n.id == id) return n;
    }
    return null;
  }

  /// Seats still bookable on a night (seed bookings + this session's).
  int tableSeatsLeft(TableNight night) =>
      night.capacity - night.bookedSeats - (_myTableSeats[night.id] ?? 0);

  int _bookingSeq = 0;

  /// Holds seats at a Tables night; the checkout step confirms after.
  /// Refuses — returns null — when the member is banned from Tables,
  /// already holds an active booking, or asks for more seats than
  /// remain. A refusal is a real state, never a silent success.
  TableBooking? holdTableSeat(TableNight night, {int seats = 1}) {
    if (tablesStanding == TablesStanding.banned) return null;
    if (tableBooking != null) return null;
    if (seats < 1 || seats > tableSeatsLeft(night)) return null;
    final booking = TableBooking(
      id: 'tb-${++_bookingSeq}',
      nightId: night.id,
      seats: seats,
      totalPrice: night.seatPrice * seats,
    );
    tableBooking = booking;
    _myTableSeats[night.id] = (_myTableSeats[night.id] ?? 0) + seats;
    notifyListeners();
    return booking;
  }

  /// Confirms the held booking (after the demo checkout step).
  bool confirmTableBooking() {
    final booking = tableBooking;
    if (booking == null || booking.status == TableBookingStatus.confirmed) {
      return false;
    }
    booking.status = TableBookingStatus.confirmed;
    notifyListeners();
    return true;
  }

  /// Cancels the active booking and releases its seats.
  void cancelTableBooking() {
    final booking = tableBooking;
    if (booking == null) return;
    final left = (_myTableSeats[booking.nightId] ?? 0) - booking.seats;
    if (left <= 0) {
      _myTableSeats.remove(booking.nightId);
    } else {
      _myTableSeats[booking.nightId] = left;
    }
    tableBooking = null;
    notifyListeners();
  }

  /// Records a Tables no-show (host check-in, in production). Policy:
  /// the first no-show warns; the second bans — and a ban cancels any
  /// active booking. Returns the new standing.
  TablesStanding recordTableNoShow() {
    tablesStanding = switch (tablesStanding) {
      TablesStanding.good => TablesStanding.warned,
      TablesStanding.warned => TablesStanding.banned,
      TablesStanding.banned => TablesStanding.banned,
    };
    if (tablesStanding == TablesStanding.banned) {
      cancelTableBooking(); // notifies again — harmless
    }
    notifyListeners();
    return tablesStanding;
  }

  // --- Wave 1 · Tune My Drop (CROWD-FEATURES #17) --------------------------

  /// The member's current Drop tune. Session state: Discover re-orders
  /// from it and the tune sheet explains from it.
  TuneParse tune = TuneParse.empty;

  void setTune(TuneParse value) {
    tune = value;
    notifyListeners();
  }

  void clearTune() => setTune(TuneParse.empty);

  // --- Wave 2 · Private Circles (CROWD-FEATURES #5) ----------------------

  /// Persistent small groups (seeded + converted in-session). Session
  /// state, like plans — a circle created from the Plans hub must still
  /// exist when the member opens Connect.
  final List<PrivateCircle> _circles = MockData.circles();
  List<PrivateCircle> get circles => List.unmodifiable(_circles);

  PrivateCircle? circleById(String id) {
    for (final c in _circles) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// The circle a plan already became, if any — one plan, one circle.
  PrivateCircle? circleForPlan(String planId) {
    for (final c in _circles) {
      if (c.sourcePlanId == planId) return c;
    }
    return null;
  }

  /// "Keep this group as a PrivateCircle" is offered only for plans the member
  /// is actually part of (hosting or going) that haven't converted yet.
  bool canConvertPlanToCircle(OpenPlan plan) =>
      circleForPlan(plan.id) == null &&
      (plan.hostedByMe || plan.myState == PlanJoinState.going);

  int _circleSeq = 0;

  /// Converts a plan into a persistent PrivateCircle: the attendee list becomes
  /// the membership, the plan stays linked as the circle's upcoming
  /// plan. Returns null when the conversion isn't available (unknown
  /// plan, not a member of it, or already converted) — a refusal is a
  /// real state, never a silent success.
  PrivateCircle? convertPlanToCircle(String planId) {
    final plan = planById(planId);
    if (plan == null || !canConvertPlanToCircle(plan)) return null;
    final circle = PrivateCircle(
      id: 'circle-mine-${++_circleSeq}',
      name: plan.title,
      memberIds: plan.attendeeIds,
      formedFromLabel: 'From the plan "${plan.title}"',
      upcomingPlanId: plan.id,
      sourcePlanId: plan.id,
    );
    _circles.insert(0, circle);
    _circleMessages.add(CircleMessage(
      id: 'cmsg-${circle.id}-0',
      circleId: circle.id,
      authorId: 'me',
      kind: CircleMsgKind.system,
      text: 'PrivateCircle formed from "${plan.title}" — '
          'only members can see this chat.',
      timeLabel: 'now',
    ));
    notifyListeners();
    return circle;
  }

  // --- Wave 2 · PrivateCircle-only Moments + Highlights (CROWD-FEATURES #6) ----

  /// Scoped Moments: visible only inside their PrivateCircle, never in the
  /// connections feed (the feed reads MockData.moments, a separate list).
  final List<Moment> _circleMoments = MockData.circleMoments();

  List<Moment> circleMomentsFor(String circleId) =>
      _circleMoments.where((m) => m.circleId == circleId).toList();

  /// Highlight pins, by Moment id. The cap is per circle (CROWD-FEATURES
  /// #6: up to 3 pinnable) — Highlights stay a highlight reel, not a
  /// second feed.
  final Set<String> _highlightedMomentIds =
      Set<String>.of(MockData.highlightedMomentIds);

  static const int maxHighlightsPerCircle = 3;

  bool isMomentHighlighted(String momentId) =>
      _highlightedMomentIds.contains(momentId);

  List<Moment> circleHighlightsFor(String circleId) => circleMomentsFor(
      circleId)
      .where((m) => _highlightedMomentIds.contains(m.id))
      .toList();

  /// Pins/unpins a PrivateCircle Moment as a Highlight. Unpinning always works;
  /// pinning refuses (false) at the per-circle cap or for an unknown /
  /// non-circle Moment, so the UI explains instead of pretending.
  bool toggleMomentHighlight(String momentId) {
    if (_highlightedMomentIds.remove(momentId)) {
      notifyListeners();
      return true;
    }
    Moment? target;
    for (final m in _circleMoments) {
      if (m.id == momentId) target = m;
    }
    if (target == null || target.circleId == null) return false;
    if (circleHighlightsFor(target.circleId!).length >=
        maxHighlightsPerCircle) {
      return false;
    }
    _highlightedMomentIds.add(momentId);
    notifyListeners();
    return true;
  }

  int _circleMomentSeq = 0;

  /// Posts a Moment scoped to [circleId] — members only, 24h like every
  /// Moment. Demo build: sample image, like the Moments tab composer.
  Moment postCircleMoment({
    required String circleId,
    required String caption,
  }) {
    final text = caption.trim();
    final moment = Moment(
      id: 'cmom-mine-${++_circleMomentSeq}',
      member: MockData.currentUser,
      caption: text.isEmpty ? 'Out with the circle.' : text,
      imageAsset: AppConfig.assetBackdropMatch,
      expiresInLabel: '24h',
      circleId: circleId,
    );
    _circleMoments.insert(0, moment);
    notifyListeners();
    return moment;
  }

  // --- Wave 2 · PrivateCircle chat + Smart Chat (CROWD-FEATURES #7) ------------

  final List<CircleMessage> _circleMessages = MockData.circleMessages();

  List<CircleMessage> circleMessagesFor(String circleId) =>
      List.unmodifiable(
          _circleMessages.where((m) => m.circleId == circleId).toList());

  CircleMessage? circleMessageById(String id) {
    for (final m in _circleMessages) {
      if (m.id == id) return m;
    }
    return null;
  }

  int _circleMsgSeq = 0;

  CircleMessage _addCircleMessage(CircleMessage msg) {
    _circleMessages.add(msg);
    notifyListeners();
    return msg;
  }

  CircleMessage postCircleText(String circleId, String text) =>
      _addCircleMessage(CircleMessage(
        id: 'cmsg-mine-${++_circleMsgSeq}',
        circleId: circleId,
        authorId: 'me',
        kind: CircleMsgKind.text,
        text: text.trim(),
        timeLabel: 'now',
      ));

  /// Posts a poll sticker: a question + 2–4 options, zero votes. Blank
  /// options are dropped; fewer than 2 real options is a caller error
  /// the UI prevents (the composer requires two).
  CircleMessage postCirclePoll(
          String circleId, String question, List<String> options) =>
      _addCircleMessage(CircleMessage(
        id: 'cmsg-mine-${++_circleMsgSeq}',
        circleId: circleId,
        authorId: 'me',
        kind: CircleMsgKind.poll,
        text: question.trim(),
        timeLabel: 'now',
        pollOptions: [
          for (final o in options)
            if (o.trim().isNotEmpty) CirclePollOption(o.trim()),
        ],
      ));

  /// Posts an "Ask me" opener sticker: the member offers a topic, the
  /// circle asks. Questions land as normal texts via [askCircleQuestion].
  CircleMessage postCircleAskMe(String circleId, String topic) =>
      _addCircleMessage(CircleMessage(
        id: 'cmsg-mine-${++_circleMsgSeq}',
        circleId: circleId,
        authorId: 'me',
        kind: CircleMsgKind.askMe,
        askMeTopic: topic.trim(),
        timeLabel: 'now',
      ));

  /// Casts or moves the signed-in member's poll vote: one vote per
  /// member — voting another option MOVES it, tapping the current pick
  /// again takes it back. Returns false for unknown/non-poll messages
  /// and out-of-range options.
  bool voteInCirclePoll(String messageId, int optionIndex) {
    final msg = circleMessageById(messageId);
    if (msg == null || msg.kind != CircleMsgKind.poll) return false;
    if (optionIndex < 0 || optionIndex >= msg.pollOptions.length) {
      return false;
    }
    final alreadyMine =
        msg.pollOptions[optionIndex].voterIds.contains('me');
    for (final o in msg.pollOptions) {
      o.voterIds.remove('me');
    }
    if (!alreadyMine) msg.pollOptions[optionIndex].voterIds.add('me');
    notifyListeners();
    return true;
  }

  /// Asks a question on an "Ask me" sticker: the count on the sticker
  /// goes up AND the question lands in the chat as my text — both real.
  bool askCircleQuestion(String messageId, String question) {
    final msg = circleMessageById(messageId);
    if (msg == null || msg.kind != CircleMsgKind.askMe) return false;
    final text = question.trim();
    if (text.isEmpty) return false;
    msg.questionsAsked++;
    postCircleText(msg.circleId, text); // notifies
    return true;
  }

  // --- Wave 2 · Wingperson (CROWD-FEATURES #8) ---------------------------

  final List<WingIntro> _intros = MockData.wingIntros();

  List<WingIntro> introsForCircle(String circleId) =>
      List.unmodifiable(
          _intros.where((i) => i.circleId == circleId).toList());

  WingIntro? introById(String id) {
    for (final i in _intros) {
      if (i.id == id) return i;
    }
    return null;
  }

  int _introSeq = 0;

  /// Introduces two circle members (never myself — a wingperson
  /// introduces OTHER people). The intro lands in the store AND as a
  /// card in the circle chat, from the same object.
  WingIntro createIntro({
    required String circleId,
    required String aId,
    required String bId,
    required String note,
  }) {
    final intro = WingIntro(
      id: 'intro-mine-${++_introSeq}',
      circleId: circleId,
      byId: 'me',
      aId: aId,
      bId: bId,
      note: note.trim(),
    );
    _intros.add(intro);
    _circleMessages.add(CircleMessage(
      id: 'cmsg-${intro.id}',
      circleId: circleId,
      authorId: 'me',
      kind: CircleMsgKind.intro,
      introId: intro.id,
      timeLabel: 'now',
    ));
    notifyListeners();
    return intro;
  }

  /// Accepts an intro addressed to me. When the second acceptance lands,
  /// the intro connects and the 1:1 conversation with the other party
  /// opens through the EXISTING pattern (conversationFor) — the chat is
  /// a normal thread from there. Returns false when the intro isn't
  /// mine to accept, is declined/connected, or I already accepted.
  bool acceptIntro(String introId) {
    final intro = introById(introId);
    if (intro == null || intro.declined || !intro.involvesMe) return false;
    if (!intro.acceptedIds.add('me')) return false;
    if (intro.isConnected) {
      conversationFor(intro.otherPartyForMe); // notifies again — harmless
    }
    notifyListeners();
    return true;
  }

  /// Declines an intro addressed to me: quiet and final — the other
  /// party just sees "Declined", never a reason or a nudge loop.
  bool declineIntro(String introId) {
    final intro = introById(introId);
    if (intro == null || intro.declined || !intro.involvesMe) return false;
    if (intro.isConnected) return false;
    intro.declined = true;
    notifyListeners();
    return true;
  }

  // --- Wave 3 · Decompress shelf (CROWD-FEATURES #12) -------------------

  /// The calm shelf: bookable offline plans tagged decompress. They
  /// live in the same [_openPlans] list and join through the same
  /// state machine — the shelf is a view, not a second system. Past
  /// plans (Wave 4) are excluded: the shelf is for booking, and a
  /// plan that already happened can't be booked.
  List<OpenPlan> get decompressPlans =>
      _openPlans.where((p) => p.decompress && !p.past).toList();

  // --- Wave 3 · Micro-Hosts (CROWD-FEATURES #14) ------------------------

  /// Plans a member hosts, counted from the REAL plan list — created
  /// plans included the moment they exist. This count is the whole of
  /// host standing in this wave: guest outcome ratings join it in
  /// Wave 4 (A3) and are NOT faked before then.
  int hostedPlanCount(String memberId) =>
      _openPlans.where((p) => p.hostId == memberId).length;

  /// The Host badge condition: you host, you wear it.
  bool isHost(String memberId) => hostedPlanCount(memberId) > 0;

  /// Standing label derived from the count alone — honest tiers, no
  /// invented ratings.
  String hostTierLabel(String memberId) {
    final n = hostedPlanCount(memberId);
    if (n <= 0) return 'Not a host yet';
    if (n == 1) return 'New host';
    if (n <= 4) return 'Regular host';
    return 'Superhost';
  }

  // --- Wave 3 · Phone-Down Mode + Presence Score (CROWD-FEATURES #13) --

  /// Finished phone-down sessions, newest first. Seeded with one real
  /// past record — the street-food plan with Sofia (MockData plan-2,
  /// "Happened") — with its score COMPUTED by the same formula, so the
  /// You tab's Presence summary is never an empty lie on first run.
  final List<PresenceRecord> _presenceRecords = [
    PresenceRecord(
      planId: 'plan-2',
      planTitle: 'Street-food market with Sofia',
      phoneDownMinutes: 74,
      planMinutes: 90,
      groupSize: 2,
      score: presence_logic.presenceScore(
        phoneDownMinutes: 74,
        planMinutes: 90,
        groupSize: 2,
      ),
      dateLabel: 'Last Fri',
    ),
  ];

  List<PresenceRecord> get presenceRecords =>
      List.unmodifiable(_presenceRecords);

  /// The most recent record for a plan, if the member has gone
  /// phone-down at it — the plan card renders the score from this.
  PresenceRecord? presenceRecordForPlan(String planId) {
    for (final r in _presenceRecords) {
      if (r.planId == planId) return r;
    }
    return null;
  }

  int get presenceSessionCount => _presenceRecords.length;

  int get totalPhoneDownMinutes =>
      _presenceRecords.fold(0, (sum, r) => sum + r.phoneDownMinutes);

  /// Mean score across finished sessions; 0 when there are none (the
  /// UI shows "no sessions yet" from the count, never a fake average).
  int get averagePresenceScore => _presenceRecords.isEmpty
      ? 0
      : (_presenceRecords.fold(0, (sum, r) => sum + r.score) /
              _presenceRecords.length)
          .round();

  /// The one live phone-down session, if any. One at a time — you are
  /// only ever at one plan.
  PhoneDownSession? activePhoneDown;

  /// Starts phone-down for a plan the member is part of (hosting or
  /// going). Refuses — returns false — for unknown plans, plans the
  /// member isn't in, or when a session is already running: one real
  /// state, never a stacked lie.
  bool startPhoneDown(String planId, {DateTime? now}) {
    if (activePhoneDown != null) return false;
    final plan = planById(planId);
    if (plan == null) return false;
    if (!plan.hostedByMe && plan.myState != PlanJoinState.going) {
      return false;
    }
    activePhoneDown =
        PhoneDownSession(planId: planId, startedAt: now ?? DateTime.now());
    notifyListeners();
    return true;
  }

  /// Ends the live session and writes its PresenceRecord: elapsed
  /// minutes from the real session clock, plan length and group size
  /// from the real plan, score from the one formula. Returns the
  /// record, or null when no session is running.
  PresenceRecord? endPhoneDown({DateTime? now}) {
    final session = activePhoneDown;
    if (session == null) return null;
    final plan = planById(session.planId);
    activePhoneDown = null;
    if (plan == null) {
      notifyListeners();
      return null;
    }
    final minutes = session.elapsedMinutesAt(now ?? DateTime.now());
    final record = PresenceRecord(
      planId: plan.id,
      planTitle: plan.title,
      phoneDownMinutes: minutes,
      planMinutes: plan.durationMinutes,
      groupSize: plan.attendeeIds.length,
      score: presence_logic.presenceScore(
        phoneDownMinutes: minutes,
        planMinutes: plan.durationMinutes,
        groupSize: plan.attendeeIds.length,
      ),
      dateLabel: 'Today',
    );
    _presenceRecords.insert(0, record);
    notifyListeners();
    return record;
  }

  /// Discards the live session without a record (the member backed
  /// out before it counted). Honest: no score is minted for a session
  /// that didn't happen.
  void cancelPhoneDown() {
    if (activePhoneDown == null) return;
    activePhoneDown = null;
    notifyListeners();
  }

  // --- Wave 3 · Check-In Safety (CROWD-FEATURES #15) --------------------

  /// Check-ins by plan id. DEMO RAIL: the record holds the exact
  /// message the live app would send the trusted contact — nothing
  /// leaves the phone in this build.
  final Map<String, PlanCheckIn> _checkIns = {};

  PlanCheckIn? checkInFor(String planId) => _checkIns[planId];

  /// Records (or updates) my check-in for a plan I'm going to, and
  /// returns the record — its messagePreview is what the sheet shows
  /// as "would be sent". [PlanCheckInState.none] clears the check-in
  /// and returns null. Refuses (null, no state change) for unknown
  /// plans and plans I'm not part of.
  PlanCheckIn? setPlanCheckIn(
    String planId,
    PlanCheckInState state, {
    required String contactName,
  }) {
    final plan = planById(planId);
    if (plan == null) return null;
    if (!plan.hostedByMe && plan.myState != PlanJoinState.going) {
      return null;
    }
    if (state == PlanCheckInState.none) {
      if (_checkIns.remove(planId) != null) notifyListeners();
      return null;
    }
    final record = PlanCheckIn(
      planId: planId,
      state: state,
      timeLabel: 'now',
      messagePreview: presence_logic.checkInMessageText(
        contactName: contactName,
        planTitle: plan.title,
        place: plan.place,
        state: state,
      ),
    );
    _checkIns[planId] = record;
    notifyListeners();
    return record;
  }

  // --- Wave 3.5 · Club & Event Tickets (MASTER-BUILD-PLAN T1) --------

  /// Per-order quantity cap: a member can hold at most 4 tickets for
  /// one night in one order (the door list stays a list of people,
  /// not a resale channel).
  static const int maxTicketsPerOrder = 4;

  /// My tickets, in the order I got them. Session state, like the
  /// Tables booking — cancelled tickets stay in the list with their
  /// status (the record of a release is honest), they just hold no
  /// capacity.
  final List<EventTicket> _myTickets = [];

  List<EventTicket> get myTickets => List.unmodifiable(_myTickets);

  /// Tickets that still count as "going" (held, confirmed, checked
  /// in) — the You tab's My Tickets row counts these.
  List<EventTicket> get myActiveTickets =>
      _myTickets.where((t) => t.isActive).toList();

  ClubNight? clubNightById(String id) {
    for (final n in MockData.clubNights) {
      if (n.id == id) return n;
    }
    return null;
  }

  EventTicket? eventTicketById(String id) {
    for (final t in _myTickets) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// My tickets for one night (any status) — the detail screen reads
  /// its state from these, never from its own copy.
  List<EventTicket> myTicketsForNight(String nightId) =>
      _myTickets.where((t) => t.nightId == nightId).toList();

  /// Seats my live tickets hold on a night (cancelled hold none).
  int myEventSeatsFor(String nightId) => _myTickets
      .where((t) => t.nightId == nightId && t.consumesCapacity)
      .fold(0, (sum, t) => sum + t.quantity);

  /// Seats still claimable on a night: capacity minus the seed claims
  /// minus mine.
  int eventSeatsLeft(ClubNight night) =>
      night.capacity - night.claimedSeats - myEventSeatsFor(night.id);

  bool eventNightSoldOut(ClubNight night) => eventSeatsLeft(night) <= 0;

  /// The full price of an order, BEFORE anyone confirms. The fee rule
  /// lives here and nowhere else: a service fee exists only on
  /// premium tickets to OUR OWN events (partner nights are affiliate
  /// listings — no fee line, ever), and the free tier is always $0.
  TicketQuote ticketQuote(ClubNight night, TicketTier tier, int quantity) {
    if (tier == TicketTier.free) {
      return TicketQuote(
        unitPrice: 0,
        serviceFeePerTicket: 0,
        quantity: quantity,
        seller: night.seller,
      );
    }
    return TicketQuote(
      unitPrice: night.premiumPrice ?? 0,
      serviceFeePerTicket:
          night.seller == TicketSeller.carino ? night.serviceFeePerTicket : 0,
      quantity: quantity,
      seller: night.seller,
    );
  }

  int _ticketSeq = 0;

  /// Shared refusal gate for both tiers. Returns the quantity when the
  /// order may proceed, null when it must refuse: tier not offered,
  /// quantity outside 1..[maxTicketsPerOrder], or more asked than the
  /// room still holds (sold out included). A refusal is a real state —
  /// the UI explains it, never a silent success.
  bool _canOrder(ClubNight night, TicketTier tier, int quantity) {
    if (quantity < 1 || quantity > maxTicketsPerOrder) return false;
    if (tier == TicketTier.free && !night.offersFree) return false;
    if (tier == TicketTier.premium && !night.offersPremium) return false;
    if (quantity > eventSeatsLeft(night)) return false;
    return true;
  }

  /// Claims free (RSVP) tickets: straight to confirmed — there is no
  /// checkout for $0 — and the claim consumes real capacity at once.
  /// Returns null on any refusal (see [_canOrder]).
  EventTicket? claimFreeTicket(ClubNight night, {int quantity = 1}) {
    if (!_canOrder(night, TicketTier.free, quantity)) return null;
    final ticket = EventTicket(
      id: 'et-${++_ticketSeq}',
      nightId: night.id,
      tier: TicketTier.free,
      quantity: quantity,
      totalPrice: 0,
      status: EventTicketStatus.confirmed,
    );
    _myTickets.add(ticket);
    notifyListeners();
    return ticket;
  }

  /// Holds premium tickets while the (demo) checkout completes — the
  /// Tables hold pattern. The hold consumes capacity immediately, so
  /// two people can never be sold the same seat; releasing or
  /// cancelling the hold frees it. The ticket's total is the quote's
  /// total, fee included, computed NOW — never re-priced later.
  EventTicket? holdPremiumTicket(ClubNight night, {int quantity = 1}) {
    if (!_canOrder(night, TicketTier.premium, quantity)) return null;
    final quote = ticketQuote(night, TicketTier.premium, quantity);
    final ticket = EventTicket(
      id: 'et-${++_ticketSeq}',
      nightId: night.id,
      tier: TicketTier.premium,
      quantity: quantity,
      totalPrice: quote.total,
      status: EventTicketStatus.held,
    );
    _myTickets.add(ticket);
    notifyListeners();
    return ticket;
  }

  /// Confirms a held premium ticket (after the demo checkout step).
  bool confirmEventTicket(String ticketId) {
    final ticket = eventTicketById(ticketId);
    if (ticket == null || ticket.status != EventTicketStatus.held) {
      return false;
    }
    ticket.status = EventTicketStatus.confirmed;
    notifyListeners();
    return true;
  }

  /// Cancels a held or confirmed ticket and releases its seats.
  /// Refuses — returns false — for a CHECKED-IN ticket (you were in
  /// the room; the record stands) and for tickets already cancelled
  /// or unknown.
  bool cancelEventTicket(String ticketId) {
    final ticket = eventTicketById(ticketId);
    if (ticket == null) return false;
    if (ticket.status != EventTicketStatus.held &&
        ticket.status != EventTicketStatus.confirmed) {
      return false;
    }
    ticket.status = EventTicketStatus.cancelled;
    notifyListeners();
    return true;
  }

  /// Door check-in (DEMO RAIL: the live app scans the venue's door
  /// code; here the state change is the whole mechanic). Only a
  /// confirmed ticket can check in — a held one hasn't finished
  /// checkout, a cancelled one isn't a ticket anymore.
  bool checkInEventTicket(String ticketId) {
    final ticket = eventTicketById(ticketId);
    if (ticket == null || ticket.status != EventTicketStatus.confirmed) {
      return false;
    }
    ticket.status = EventTicketStatus.checkedIn;
    notifyListeners();
    return true;
  }

  // --- Wave 4 · AI Concierge bookings (MASTER-BUILD-PLAN A1) ---------

  /// Bookings the Concierge completed, in order. Written ONLY by
  /// executeConciergeProposal (state/concierge.dart) after the real
  /// store action succeeded — the Plans hub card and the confirmation
  /// render from these, never from a toast.
  final List<ConciergeBooking> _conciergeBookings = [];

  List<ConciergeBooking> get conciergeBookings =>
      List.unmodifiable(_conciergeBookings);

  ConciergeBooking? get lastConciergeBooking =>
      _conciergeBookings.isEmpty ? null : _conciergeBookings.last;

  void addConciergeBooking(ConciergeBooking booking) {
    _conciergeBookings.add(booking);
    notifyListeners();
  }

  // --- Wave 4 · Outcome Graph (MASTER-BUILD-PLAN A3) -----------------

  /// Seeded history: LAST Thursday's Tables booking — confirmed, and
  /// the table host checked the member in on the night. It is the
  /// subject the outcome prompt asks about; it is NOT the active
  /// booking ([tableBooking] stays the one-bookable-per-week slot).
  final TableBooking pastTableBooking = TableBooking(
    id: 'tb-past-1',
    nightId: MockData.pastTableNight.id,
    seats: 1,
    totalPrice: MockData.pastTableNight.seatPrice,
    status: TableBookingStatus.confirmed,
  );

  /// Seeded history: LAST Saturday's club ticket — free tier, door
  /// checked in. Deliberately NOT in [_myTickets]: My Tickets renders
  /// bookable nights from MockData.clubNights, and this night is
  /// deliberately not among them (see MockData.pastClubNight).
  final EventTicket pastEventTicket = EventTicket(
    id: 'et-past-1',
    nightId: MockData.pastClubNight.id,
    tier: TicketTier.free,
    quantity: 1,
    totalPrice: 0,
    status: EventTicketStatus.checkedIn,
  );

  /// The outcome graph itself: one record per subject, written by me.
  final List<OutcomeRecord> _outcomeRecords = [];

  List<OutcomeRecord> get outcomeRecords =>
      List.unmodifiable(_outcomeRecords);

  /// My record about a subject, if I've written one.
  OutcomeRecord? outcomeFor(OutcomeSubjectKind kind, String subjectId) {
    for (final r in _outcomeRecords) {
      if (r.subjectKind == kind && r.subjectId == subjectId) return r;
    }
    return null;
  }

  /// Past subjects awaiting my check-in: past plans I hosted or went
  /// to, last week's Table, last week's club night — minus anything
  /// already recorded. Derived fresh on every read, so a written
  /// record removes its prompt everywhere at once.
  List<OutcomePrompt> pendingOutcomePrompts() {
    final prompts = <OutcomePrompt>[];
    for (final plan in _openPlans) {
      if (!plan.past) continue;
      if (!plan.hostedByMe && plan.myState != PlanJoinState.going) {
        continue;
      }
      if (outcomeFor(OutcomeSubjectKind.plan, plan.id) != null) continue;
      prompts.add(OutcomePrompt(
        subjectKind: OutcomeSubjectKind.plan,
        subjectId: plan.id,
        title: plan.title,
        detailLabel: plan.hostedByMe
            ? 'Hosted by you · ${plan.timeLabel}'
            : 'Hosted by ${MockData.memberById(plan.hostId).firstName} '
                '· ${plan.timeLabel}',
        hostId: plan.hostId,
      ));
    }
    if (outcomeFor(OutcomeSubjectKind.table, MockData.pastTableNight.id) ==
        null) {
      const night = MockData.pastTableNight;
      prompts.add(OutcomePrompt(
        subjectKind: OutcomeSubjectKind.table,
        subjectId: night.id,
        title: 'Cariño Tables — ${night.dateLabel}',
        detailLabel: '${night.areaLabel} · table of ${TableNight.tableSize} '
            '· you were there',
      ));
    }
    if (outcomeFor(OutcomeSubjectKind.ticket, MockData.pastClubNight.id) ==
        null) {
      const night = MockData.pastClubNight;
      prompts.add(OutcomePrompt(
        subjectKind: OutcomeSubjectKind.ticket,
        subjectId: night.id,
        title: night.title,
        detailLabel: '${night.venueName} · ${night.dateLabel} · '
            'you checked in at the door',
      ));
    }
    return prompts;
  }

  int _outcomeSeq = 0;

  /// Writes my outcome for a subject. Refuses — returns null — when
  /// the subject isn't a real past subject of mine (unknown id, a
  /// FUTURE plan, a plan I wasn't part of, a bookable night instead
  /// of the past ones) or when I've already recorded one: one member,
  /// one attestation per subject, or the graph is just noise.
  OutcomeRecord? recordOutcome({
    required OutcomeSubjectKind kind,
    required String subjectId,
    required OutcomeRating rating,
  }) {
    if (outcomeFor(kind, subjectId) != null) return null;
    final String title;
    final String detail;
    final String? hostId;
    switch (kind) {
      case OutcomeSubjectKind.plan:
        final plan = planById(subjectId);
        if (plan == null || !plan.past) return null;
        if (!plan.hostedByMe && plan.myState != PlanJoinState.going) {
          return null;
        }
        title = plan.title;
        detail = plan.hostedByMe
            ? 'Hosted by you · ${plan.timeLabel} · ${plan.place}'
            : 'Hosted by ${MockData.memberById(plan.hostId).firstName} '
                '· ${plan.timeLabel} · ${plan.place}';
        hostId = plan.hostId;
      case OutcomeSubjectKind.table:
        if (subjectId != MockData.pastTableNight.id) return null;
        const night = MockData.pastTableNight;
        title = 'Cariño Tables — ${night.dateLabel}';
        detail = '${night.areaLabel} · table of ${TableNight.tableSize}';
        hostId = null;
      case OutcomeSubjectKind.ticket:
        if (subjectId != MockData.pastClubNight.id) return null;
        const night = MockData.pastClubNight;
        title = night.title;
        detail = '${night.venueName} · ${night.areaLabel} · '
            '${night.dateLabel}';
        hostId = null;
    }
    final record = OutcomeRecord(
      id: 'out-${++_outcomeSeq}',
      subjectKind: kind,
      subjectId: subjectId,
      subjectTitle: title,
      subjectDetail: detail,
      hostId: hostId,
      rating: rating,
      dateLabel: 'Today',
    );
    _outcomeRecords.add(record);
    notifyListeners();
    return record;
  }

  /// Outcome records ABOUT plans a member hosted — the only input
  /// host standing gained in this wave (Wave 3 deliberately counted
  /// plans alone; ratings were never faked before records existed).
  int hostRecordedCount(String memberId) => _outcomeRecords
      .where((r) =>
          r.subjectKind == OutcomeSubjectKind.plan && r.hostId == memberId)
      .length;

  /// Of those, how many attested "happened" (great/fine).
  int hostHappenedCount(String memberId) => _outcomeRecords
      .where((r) =>
          r.subjectKind == OutcomeSubjectKind.plan &&
          r.hostId == memberId &&
          r.rating.happened)
      .length;

  /// '3 plans hosted · 1 happened' — hosted from the real plan list,
  /// happened from the records. See outcomes.dart for the wording.
  String hostOutcomeLine(String memberId) => outcomes_logic.hostOutcomeLineText(
        hosted: hostedPlanCount(memberId),
        recorded: hostRecordedCount(memberId),
        happened: hostHappenedCount(memberId),
      );

  // --- Wave 4 · Presence Dashboard (MASTER-BUILD-PLAN A4) ------------

  /// The dashboard's numbers, aggregated from the real record lists
  /// by the pure function in state/outcomes.dart — the screen renders
  /// this and computes nothing itself.
  outcomes_logic.PresenceDashboardStats get dashboardStats =>
      outcomes_logic.computeDashboardStats(
        presenceRecords: _presenceRecords,
        outcomeRecords: _outcomeRecords,
        plans: _openPlans,
        myCircles:
            _circles.where((c) => c.memberIds.contains('me')).toList(),
      );
}
