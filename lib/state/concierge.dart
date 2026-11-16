import '../data/mock_data.dart';
import '../models/agent.dart';
import '../models/member.dart';
import '../models/plan.dart';
import '../models/ticket.dart';
import 'app_store.dart';
import 'people_search.dart';

/// Wave 4 · AI Concierge (MASTER-BUILD-PLAN A1) — the DEMO BRAIN.
///
/// Honest by construction: this is rule-based matching over REAL store
/// data (the same keyword discipline as People Search / Tune My Drop),
/// not a language model, and the UI labels it that way. The live AI
/// brain plugs into this exact contract at hosting: same proposals,
/// same execution, same "price before confirm" rule.
///
/// The contract:
/// - [parseConciergeIntent] reads the member's plain words.
/// - [conciergeProposals] returns up to 3 options, each a pointer at a
///   REAL Table night / open plan / club night (or a new-plan draft),
///   each with a WHY line derived from real fields.
/// - [executeConciergeProposal] books through the store's REAL actions
///   (holdTableSeat + confirm, requestJoinPlan, claim/hold+confirm
///   ticket, createPlan) — a Concierge booking and a manual booking
///   are the same state, so they can never disagree.

/// What the member's words asked for, as far as rules can honestly
/// read them. A null/false field means "not stated" — the Concierge
/// never invents a preference the member didn't type.
class ConciergeIntent {
  const ConciergeIntent({
    this.dinner = false,
    this.calm = false,
    this.nightlife = false,
    this.tonight = false,
    this.wantsFree = false,
    this.groupSize,
  });

  final bool dinner;
  final bool calm;
  final bool nightlife;
  final bool tonight;
  final bool wantsFree;

  /// Party size from the member's own number ("4 of us", "for 2").
  /// Null when they didn't give one.
  final int? groupSize;

  bool get hasCategory => dinner || calm || nightlife;
}

bool _hasWord(String text, String word) =>
    RegExp('\\b${RegExp.escape(word)}\\b').hasMatch(text);

bool _hasAny(String text, List<String> words) =>
    words.any((w) => _hasWord(text, w));

const List<String> _dinnerWords = [
  'dinner', 'supper', 'eat', 'eating', 'food', 'restaurant', 'table',
  'meal', 'hungry', 'brunch', 'lunch', 'breakfast', 'tapas', 'sushi',
  'pizza', 'ramen',
];

const List<String> _calmWords = [
  'calm', 'quiet', 'outdoor', 'outdoors', 'relax', 'relaxing', 'chill',
  'decompress', 'walk', 'walking', 'park', 'garden', 'slow', 'peaceful',
  'yoga', 'nature', 'lake', 'sunset', 'breathe', 'low-key', 'lowkey',
];

const List<String> _nightlifeWords = [
  'club', 'dancing', 'dance', 'music', 'live', 'comedy', 'party',
  'drinks', 'bar', 'jazz', 'concert', 'show', 'nightlife',
];

/// Parses the member's plain words into a [ConciergeIntent]. Word-
/// boundary keyword rules only — a word that isn't there can't fire.
ConciergeIntent parseConciergeIntent(String raw) {
  final text = raw.toLowerCase();
  int? groupSize;
  final number = RegExp(r'\b(\d{1,2})\b').firstMatch(text);
  if (number != null) {
    final n = int.parse(number.group(1)!);
    if (n >= 2 && n <= 12) groupSize = n;
  }
  return ConciergeIntent(
    dinner: _hasAny(text, _dinnerWords),
    calm: _hasAny(text, _calmWords),
    nightlife: _hasAny(text, _nightlifeWords) || text.contains('night out'),
    tonight: _hasWord(text, 'tonight'),
    wantsFree: _hasWord(text, 'free'),
    groupSize: groupSize,
  );
}

String _hostName(String id) =>
    id == 'me' ? 'You' : MockData.memberById(id).firstName;

/// Up to 3 proposals for the member's words, best first. Real options
/// come first (one per kind, in the intent's priority order); a
/// new-plan draft fills the last slot when fewer than 3 real options
/// fit — or leads when nothing on the board matches at all.
List<ConciergeProposal> conciergeProposals(
  AppStore store,
  String rawText, {
  Member? fromMember,
}) {
  final intent = parseConciergeIntent(rawText);
  final proposals = <ConciergeProposal>[];

  ConciergeProposal? table;
  ConciergeProposal? plan;
  ConciergeProposal? ticket;

  // --- Tables: the dinner answer ---
  if (intent.dinner || !intent.hasCategory) {
    for (final night in MockData.tableNights) {
      final left = store.tableSeatsLeft(night);
      if (left <= 0) continue;
      final seats = intent.groupSize ?? 1;
      if (seats > left) continue;
      table = ConciergeProposal(
        kind: ConciergeProposalKind.table,
        refId: night.id,
        title: 'Cariño Tables — ${night.dayLabel}',
        detailLabel:
            '${night.dateLabel} · ${night.areaLabel} · table of ${TableNight.tableSize}',
        whyLine: 'A real dinner with five verified strangers'
            '${intent.groupSize != null ? ' · room for your ${intent.groupSize}' : ''}'
            ' · venue + tablemates reveal ${night.revealLabel}',
        priceLabel: '\$${night.seatPrice * seats}'
            '${seats > 1 ? ' total · $seats seats' : ' · 1 seat'}',
        actionLabel: 'Book seat${seats > 1 ? 's' : ''}',
        seats: seats,
      );
      break; // soonest night with room — one Tables option is enough
    }
  }

  // --- Open plans: the board's answer ---
  final browsable = store.openPlans
      .where((p) =>
          !p.past &&
          !p.hostedByMe &&
          p.myState == PlanJoinState.none &&
          !p.isFull)
      .toList();
  OpenPlan? picked;
  String? planWhy;
  if (intent.calm) {
    final calm = browsable.where((p) => p.decompress).toList();
    if (calm.isNotEmpty) {
      picked = calm.first;
      planWhy = 'On the Decompress shelf — calm by design';
    }
  }
  if (picked == null && browsable.isNotEmpty) {
    var pool = browsable;
    if (intent.tonight) {
      final tonightPool = pool.where((p) => p.tonight).toList();
      if (tonightPool.isNotEmpty) pool = tonightPool;
    }
    if (intent.groupSize != null) {
      final fits =
          pool.where((p) => p.spotsLeft >= intent.groupSize!).toList();
      if (fits.isNotEmpty) pool = fits;
    }
    final ranked = searchPlans(rawText, pool, _hostName);
    if (ranked.isNotEmpty) {
      picked = ranked.first;
    } else if (searchKeywords(rawText).isEmpty) {
      // No signal words at all ("surprise me") — the board's first
      // open plan is an honest answer. With real keywords that matched
      // NOTHING, proposing an arbitrary plan would be a lie: the
      // new-plan draft below leads instead.
      picked = pool.first;
    }
  }
  if (picked != null) {
    final p = picked;
    planWhy ??= p.tonight
        ? 'Happens tonight · ${p.timeLabel}'
        : intent.groupSize != null && p.spotsLeft >= intent.groupSize!
            ? 'Room for your ${intent.groupSize} · ${p.spotsLeft} spots left'
            : '${p.spotsLeft} spot${p.spotsLeft == 1 ? '' : 's'} left · '
                'hosted by ${_hostName(p.hostId)}';
    plan = ConciergeProposal(
      kind: ConciergeProposalKind.plan,
      refId: p.id,
      title: p.title,
      detailLabel: '${p.place} · ${p.timeLabel}',
      whyLine: planWhy,
      priceLabel: null,
      actionLabel: p.instantJoin ? 'Join plan' : 'Request to join',
    );
  }

  // --- Club nights: the night-out answer ---
  if (intent.nightlife || !intent.hasCategory) {
    for (final night in MockData.clubNights) {
      if (store.eventNightSoldOut(night)) continue;
      final seats = (intent.groupSize ?? 1)
          .clamp(1, AppStore.maxTicketsPerOrder);
      if (seats > store.eventSeatsLeft(night)) continue;
      if (night.offersFree && (intent.wantsFree || !night.offersPremium)) {
        ticket = ConciergeProposal(
          kind: ConciergeProposalKind.ticket,
          refId: night.id,
          title: night.title,
          detailLabel:
              '${night.venueName} · ${night.areaLabel} · ${night.dateLabel} · ${night.timeLabel}',
          whyLine: '${night.vibeLabel} · free tickets still open',
          priceLabel: 'Free',
          actionLabel: 'Claim free ticket${seats > 1 ? 's' : ''}',
          seats: seats,
        );
      } else if (night.offersPremium) {
        final quote =
            store.ticketQuote(night, TicketTier.premium, seats);
        ticket = ConciergeProposal(
          kind: ConciergeProposalKind.ticket,
          refId: night.id,
          title: night.title,
          detailLabel:
              '${night.venueName} · ${night.areaLabel} · ${night.dateLabel} · ${night.timeLabel}',
          whyLine: '${night.vibeLabel} · premium: '
              '${night.premiumPerks.join(' · ')}',
          priceLabel: '\$${quote.total} total · $seats ticket'
              '${seats > 1 ? 's' : ''}'
              '${quote.hasFeeLine ? ' (incl. \$${quote.feeTotal} service fee)' : ''}',
          actionLabel: 'Book premium ticket${seats > 1 ? 's' : ''}',
          seats: seats,
          premium: true,
        );
      }
      if (ticket != null) break;
    }
  }

  // Priority order follows the words: what they named leads.
  final ordered = <ConciergeProposal?>[
    if (intent.dinner) ...[table, plan, ticket],
    if (intent.calm) ...[plan, table, ticket],
    if (intent.nightlife) ...[ticket, plan, table],
    if (!intent.hasCategory) ...[plan, table, ticket],
  ];
  for (final p in ordered) {
    if (p != null && proposals.length < 3) proposals.add(p);
  }

  // --- New-plan draft: fills the last slot, or leads when the board
  // has nothing for those words. ---
  if (proposals.length < 3) {
    final draft = ConciergeProposal(
      kind: ConciergeProposalKind.newPlan,
      title: intent.dinner
          ? 'Dinner with new people — hosted by you'
          : intent.calm
              ? 'A calm plan — hosted by you'
              : intent.nightlife
                  ? 'A night out — hosted by you'
                  : 'Your own plan',
      detailLabel: 'New plan · you host · verified members can join',
      whyLine: proposals.isEmpty
          ? 'Nothing on the board fits those words — post it and let '
              'the group form around yours'
          : 'Or post your own and let the group come to you',
      priceLabel: null,
      actionLabel: 'Post this plan',
      newPlanTitle: intent.dinner
          ? 'Dinner with new people'
          : intent.calm
              ? 'A slow, calm get-together'
              : intent.nightlife
                  ? 'A night out with new people'
                  : 'A plan of my own',
      newPlanPlace: intent.dinner
          ? 'A restaurant in Short North'
          : intent.calm
              ? 'Scioto Mile · river path'
              : 'North Market',
      newPlanTimeLabel: intent.tonight ? 'Tonight · 19:00' : 'This week · 18:00',
      newPlanTonight: intent.tonight,
      newPlanGroupSize: (intent.groupSize ?? 4).clamp(2, 8),
      newPlanDecompress: intent.calm,
    );
    proposals.add(draft);
  }
  return proposals;
}

/// The result of executing a proposal — the confirmation (or the
/// honest refusal) the Concierge screen renders.
class ConciergeExecution {
  const ConciergeExecution({
    required this.ok,
    required this.headline,
    required this.detail,
    this.priceLabel,
    this.reminderLabel,
  });

  final bool ok;
  final String headline;
  final String detail;

  /// The price the member saw before confirming — restated after.
  final String? priceLabel;

  /// Reminder state (success only), honestly labelled as local/demo.
  final String? reminderLabel;
}

String _reminder(String when) =>
    'Reminder set · $when (demo — reminders are scheduled on this '
    'device in this build)';

ConciergeExecution _fail(String headline, String detail) =>
    ConciergeExecution(ok: false, headline: headline, detail: detail);

/// Books a proposal through the store's REAL actions. Every refusal
/// the underlying action can produce is surfaced as an honest failure
/// — the Concierge never reports a booking the store didn't make.
ConciergeExecution executeConciergeProposal(
  AppStore store,
  ConciergeProposal proposal, {
  Member? fromMember,
}) {
  switch (proposal.kind) {
    case ConciergeProposalKind.table:
      final night = store.tableNightById(proposal.refId ?? '');
      if (night == null) {
        return _fail('That night is gone',
            'The Tables night no longer exists — ask me again and I\'ll re-check the board.');
      }
      if (store.tablesStanding == TablesStanding.banned) {
        return _fail('Tables is closed to you right now',
            'Two no-shows put a ban on your Tables standing, and the Concierge books by the same rules as everyone.');
      }
      if (store.tableBooking != null) {
        return _fail('You already hold a Tables booking',
            'One dinner a week is the rhythm — cancel the current booking first and I\'ll book this one instead.');
      }
      final booking = store.holdTableSeat(night, seats: proposal.seats);
      if (booking == null) {
        return _fail('No seats left',
            '${night.dateLabel} doesn\'t have ${proposal.seats} seat${proposal.seats > 1 ? 's' : ''} left — the board moved while we talked.');
      }
      store.confirmTableBooking();
      final summary =
          'Seat${proposal.seats > 1 ? 's' : ''} confirmed · table of ${TableNight.tableSize} · venue reveals ${night.revealLabel}';
      store.addConciergeBooking(ConciergeBooking(
        title: 'Cariño Tables — ${night.dateLabel}',
        actionSummary: summary,
        priceLabel: '\$${booking.totalPrice}',
        reminderLabel: _reminder(night.dayLabel),
      ));
      return ConciergeExecution(
        ok: true,
        headline: 'You\'re booked in',
        detail: 'Cariño Tables · ${night.dateLabel} · ${night.areaLabel}. '
            '$summary. The meal itself is paid at the restaurant.',
        priceLabel: '\$${booking.totalPrice} total',
        reminderLabel: _reminder(night.dayLabel),
      );

    case ConciergeProposalKind.plan:
      final plan = store.planById(proposal.refId ?? '');
      if (plan == null) {
        return _fail('That plan is gone',
            'It left the board while we talked — ask me again for a fresh pick.');
      }
      if (!store.requestJoinPlan(plan.id)) {
        return _fail(
          plan.isFull ? 'That plan just filled up' : 'Couldn\'t join',
          plan.isFull
              ? '"${plan.title}" took its last spot — the board moved while we talked.'
              : 'You\'re already on "${plan.title}", or it isn\'t joinable right now.',
        );
      }
      final summary = plan.instantJoin
          ? 'You\'re in · ${plan.timeLabel} · ${plan.place}'
          : 'Request sent · ${_hostName(plan.hostId)} approves joins';
      store.addConciergeBooking(ConciergeBooking(
        title: plan.title,
        actionSummary: summary,
        reminderLabel: _reminder(plan.timeLabel),
      ));
      return ConciergeExecution(
        ok: true,
        headline: plan.instantJoin ? 'You\'re in' : 'Request sent',
        detail: '"${plan.title}" · $summary.',
        reminderLabel: _reminder(plan.timeLabel),
      );

    case ConciergeProposalKind.ticket:
      final night = store.clubNightById(proposal.refId ?? '');
      if (night == null) {
        return _fail('That night is gone',
            'The club night left the board — ask me again for a fresh pick.');
      }
      if (!proposal.premium) {
        final ticket =
            store.claimFreeTicket(night, quantity: proposal.seats);
        if (ticket == null) {
          return _fail('No free tickets left',
              '"${night.title}" can\'t take ${proposal.seats} more — the room filled while we talked.');
        }
        final summary =
            'Free ticket${proposal.seats > 1 ? 's' : ''} claimed · ${night.dateLabel} · ${night.timeLabel} · in You → My Tickets';
        store.addConciergeBooking(ConciergeBooking(
          title: night.title,
          actionSummary: summary,
          reminderLabel: _reminder(night.dateLabel),
        ));
        return ConciergeExecution(
          ok: true,
          headline: 'Ticket${proposal.seats > 1 ? 's' : ''} claimed',
          detail: '${night.title} at ${night.venueName}. $summary.',
          priceLabel: 'Free',
          reminderLabel: _reminder(night.dateLabel),
        );
      }
      final held = store.holdPremiumTicket(night, quantity: proposal.seats);
      if (held == null) {
        return _fail('No premium tickets left',
            '"${night.title}" can\'t take ${proposal.seats} more — the room filled while we talked.');
      }
      store.confirmEventTicket(held.id);
      final summary = 'Premium confirmed · ${night.premiumPerks.join(' · ')}'
          ' · in You → My Tickets';
      store.addConciergeBooking(ConciergeBooking(
        title: night.title,
        actionSummary: summary,
        priceLabel: '\$${held.totalPrice}',
        reminderLabel: _reminder(night.dateLabel),
      ));
      return ConciergeExecution(
        ok: true,
        headline: 'Premium booked',
        detail: '${night.title} at ${night.venueName}, ${night.dateLabel} · '
            '${night.timeLabel}. $summary.',
        priceLabel: '\$${held.totalPrice} total',
        reminderLabel: _reminder(night.dateLabel),
      );

    case ConciergeProposalKind.newPlan:
      final plan = store.createPlan(
        title: proposal.newPlanTitle ?? 'A plan of my own',
        place: proposal.newPlanPlace ?? 'North Market',
        timeLabel: proposal.newPlanTimeLabel ?? 'This week · 18:00',
        tonight: proposal.newPlanTonight,
        groupSize: proposal.newPlanGroupSize,
        instantJoin: true,
        sourceLabel: fromMember != null
            ? 'From your chat with ${fromMember.firstName}'
            : 'From the Concierge',
        decompress: proposal.newPlanDecompress,
      );
      final summary =
          'Live on the board · ${plan.timeLabel} · ${plan.place} · room for ${plan.groupSize}';
      store.addConciergeBooking(ConciergeBooking(
        title: plan.title,
        actionSummary: summary,
        reminderLabel: _reminder(plan.timeLabel),
      ));
      return ConciergeExecution(
        ok: true,
        headline: 'Your plan is live',
        detail: '"${plan.title}" — $summary. Verified members can join '
            'now; you\'ll see joins in the Plans hub.',
        reminderLabel: _reminder(plan.timeLabel),
      );
  }
}
