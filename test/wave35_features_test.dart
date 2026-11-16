// Wave 3.5 · Club & Event Tickets (MASTER-BUILD-PLAN T1): free claims,
// premium quote math (service fee on OUR nights only), sold-out and
// over-ask refusals, cancel releasing capacity, and door check-in
// locking cancellation.
//
// Same doctrine as the earlier waves: states are asserted against the
// REAL store and the REAL seed data — a claim that "succeeds" without
// consuming capacity, a fee that appears on a partner night, or a
// checked-in ticket that can still be cancelled would each be a
// shipped lie, so each is pinned here.
import 'package:carino/data/mock_data.dart';
import 'package:carino/models/ticket.dart';
import 'package:carino/state/app_store.dart';
import 'package:flutter_test/flutter_test.dart';

ClubNight _night(String id) => MockData.clubNights.firstWhere(
      (n) => n.id == id,
      orElse: () => throw StateError('no seeded club night $id'),
    );

void main() {
  group('Seed sanity (Wave 3.5 · T1)', () {
    test('the board covers every club kind the plan names', () {
      final categories =
          MockData.clubNights.map((n) => n.categoryLabel).toSet();
      expect(
        categories,
        containsAll(<String>{
          'Social club social',
          'Nightlife club night',
          'Live music',
          'Comedy night',
          'Members club evening',
          'Supper club',
        }),
      );
    });

    test('one night is seeded sold out, one free-only, one premium-only',
        () {
      final store = AppStore();
      final soldOut =
          MockData.clubNights.where((n) => store.eventNightSoldOut(n));
      expect(soldOut, isNotEmpty);
      expect(
        MockData.clubNights.where((n) => !n.offersPremium),
        isNotEmpty,
        reason: 'a free-only night must exist',
      );
      expect(
        MockData.clubNights.where((n) => !n.offersFree),
        isNotEmpty,
        reason: 'a premium-only night must exist',
      );
    });

    test('partner nights exist and carry no service fee in the data',
        () {
      final partners = MockData.clubNights
          .where((n) => n.seller == TicketSeller.partner)
          .toList();
      expect(partners.length, greaterThanOrEqualTo(1));
      for (final n in partners) {
        expect(n.serviceFeePerTicket, 0,
            reason: '${n.id}: affiliate listings never carry our fee');
      }
      for (final n in MockData.clubNights.where(
          (n) => n.seller == TicketSeller.carino && n.offersPremium)) {
        expect(n.serviceFeePerTicket, greaterThan(0),
            reason: '${n.id}: our own premium nights price the fee openly');
        expect(n.premiumPrice, greaterThan(0));
      }
    });
  });

  group('Free tickets — claim and capacity (Wave 3.5 · T1)', () {
    test('a free claim is confirmed at once and consumes capacity', () {
      final store = AppStore();
      final night = _night('cn-guild-fri'); // 60 cap, 41 claimed → 19 left
      expect(store.eventSeatsLeft(night), 19);
      final ticket = store.claimFreeTicket(night, quantity: 2);
      expect(ticket, isNotNull);
      expect(ticket!.status, EventTicketStatus.confirmed);
      expect(ticket.tier, TicketTier.free);
      expect(ticket.totalPrice, 0);
      expect(store.eventSeatsLeft(night), 17);
      expect(store.myActiveTickets, contains(ticket));
    });

    test('a free claim on the sold-out night refuses', () {
      final store = AppStore();
      final night = _night('cn-bluenote-thu'); // 80 of 80 claimed
      expect(store.eventNightSoldOut(night), isTrue);
      expect(store.claimFreeTicket(night), isNull);
      expect(store.myTickets, isEmpty);
    });

    test('a free claim on a premium-only night refuses', () {
      final store = AppStore();
      final night = _night('cn-casa-sun'); // supper club: no free tier
      expect(night.offersFree, isFalse);
      expect(store.claimFreeTicket(night), isNull);
    });

    test('quantities outside 1..4 refuse on both tiers', () {
      final store = AppStore();
      final night = _night('cn-guild-fri');
      expect(store.claimFreeTicket(night, quantity: 0), isNull);
      expect(store.claimFreeTicket(night, quantity: 5), isNull);
      expect(store.holdPremiumTicket(night, quantity: 5), isNull);
      expect(store.myTickets, isEmpty);
    });

    test('my own orders can sell a night out — then orders refuse', () {
      final store = AppStore();
      final night = _night('cn-casa-sun'); // 24 cap, 15 claimed → 9 left
      expect(store.eventSeatsLeft(night), 9);
      expect(store.holdPremiumTicket(night, quantity: 4), isNotNull);
      expect(store.holdPremiumTicket(night, quantity: 4), isNotNull);
      expect(store.holdPremiumTicket(night, quantity: 1), isNotNull);
      expect(store.eventSeatsLeft(night), 0);
      expect(store.eventNightSoldOut(night), isTrue);
      expect(store.holdPremiumTicket(night, quantity: 1), isNull);
    });
  });

  group('Premium tickets — quote math and the fee rule (Wave 3.5 · T1)',
      () {
    test('our own night: total = tickets + transparent service fee', () {
      final store = AppStore();
      final night = _night('cn-guild-fri'); // $18 premium, $2 fee
      final quote = store.ticketQuote(night, TicketTier.premium, 3);
      expect(quote.unitPrice, 18);
      expect(quote.subtotal, 54);
      expect(quote.feeTotal, 6);
      expect(quote.total, 60);
      expect(quote.hasFeeLine, isTrue);
    });

    test('partner nights carry NO fee line — total is price × qty', () {
      final store = AppStore();
      final hartwell = _night('cn-hartwell-sat'); // partner, $32
      final quote = store.ticketQuote(hartwell, TicketTier.premium, 2);
      expect(quote.seller, TicketSeller.partner);
      expect(quote.feeTotal, 0);
      expect(quote.hasFeeLine, isFalse);
      expect(quote.total, 64);
      final held = store.holdPremiumTicket(hartwell, quantity: 2);
      expect(held!.totalPrice, 64);
    });

    test('the free tier quote is always zero, fee included', () {
      final store = AppStore();
      final quote =
          store.ticketQuote(_night('cn-guild-fri'), TicketTier.free, 4);
      expect(quote.total, 0);
      expect(quote.hasFeeLine, isFalse);
    });

    test('hold → confirm: the hold consumes seats, the total never moves',
        () {
      final store = AppStore();
      final night = _night('cn-velvet-sat'); // 120 cap, 86 claimed → 34
      expect(store.eventSeatsLeft(night), 34);
      final held = store.holdPremiumTicket(night, quantity: 2);
      expect(held, isNotNull);
      expect(held!.status, EventTicketStatus.held);
      expect(held.totalPrice, 54); // 2 × ($25 + $2 fee)
      expect(store.eventSeatsLeft(night), 32,
          reason: 'a hold is a real reservation, not a maybe');
      expect(store.confirmEventTicket(held.id), isTrue);
      expect(held.status, EventTicketStatus.confirmed);
      expect(held.totalPrice, 54);
      // Confirming twice is not a thing.
      expect(store.confirmEventTicket(held.id), isFalse);
    });

    test('a premium hold on the sold-out night refuses', () {
      final store = AppStore();
      expect(store.holdPremiumTicket(_night('cn-bluenote-thu')), isNull);
    });

    test('a premium hold on the free-only night refuses', () {
      final store = AppStore();
      final night = _night('cn-laugh-wed'); // comedy: no premium tier
      expect(night.offersPremium, isFalse);
      expect(store.holdPremiumTicket(night), isNull);
    });
  });

  group('Cancel and door check-in (Wave 3.5 · T1)', () {
    test('cancelling a claimed ticket releases its capacity', () {
      final store = AppStore();
      final night = _night('cn-laugh-wed'); // 70 cap, 33 claimed → 37
      final ticket = store.claimFreeTicket(night, quantity: 3)!;
      expect(store.eventSeatsLeft(night), 34);
      expect(store.cancelEventTicket(ticket.id), isTrue);
      expect(ticket.status, EventTicketStatus.cancelled);
      expect(store.eventSeatsLeft(night), 37);
      expect(store.myActiveTickets, isEmpty);
      // A second cancel is a refusal, not a no-op success.
      expect(store.cancelEventTicket(ticket.id), isFalse);
    });

    test('cancelling a held premium ticket releases the hold', () {
      final store = AppStore();
      final night = _night('cn-guild-fri');
      final held = store.holdPremiumTicket(night, quantity: 2)!;
      expect(store.eventSeatsLeft(night), 17);
      expect(store.cancelEventTicket(held.id), isTrue);
      expect(store.eventSeatsLeft(night), 19);
    });

    test('check-in moves a confirmed ticket to the door list', () {
      final store = AppStore();
      final night = _night('cn-guild-fri');
      final ticket = store.claimFreeTicket(night, quantity: 1)!;
      expect(store.checkInEventTicket(ticket.id), isTrue);
      expect(ticket.status, EventTicketStatus.checkedIn);
    });

    test('a checked-in ticket can NOT be cancelled and still holds its seat',
        () {
      final store = AppStore();
      final night = _night('cn-guild-fri');
      final ticket = store.claimFreeTicket(night, quantity: 2)!;
      expect(store.eventSeatsLeft(night), 17);
      expect(store.checkInEventTicket(ticket.id), isTrue);
      expect(store.cancelEventTicket(ticket.id), isFalse,
          reason: 'you were in the room — the record stands');
      expect(ticket.status, EventTicketStatus.checkedIn);
      expect(store.eventSeatsLeft(night), 17);
    });

    test('a held ticket cannot check in before checkout completes', () {
      final store = AppStore();
      final night = _night('cn-guild-fri');
      final held = store.holdPremiumTicket(night, quantity: 1)!;
      expect(store.checkInEventTicket(held.id), isFalse);
      expect(store.confirmEventTicket(held.id), isTrue);
      expect(store.checkInEventTicket(held.id), isTrue);
    });

    test('unknown ticket ids refuse every mutation', () {
      final store = AppStore();
      expect(store.confirmEventTicket('et-nope'), isFalse);
      expect(store.cancelEventTicket('et-nope'), isFalse);
      expect(store.checkInEventTicket('et-nope'), isFalse);
    });
  });
}
