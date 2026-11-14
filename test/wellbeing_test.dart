// Decompress (bookable stress-relief plans) + Phone-Down Mode presence.
// Written before the implementation (TDD).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carino/data/mock_data.dart';
import 'package:carino/models/wellbeing.dart';
import 'package:carino/screens/connect/decompress_screens.dart';
import 'package:carino/services/services.dart';
import 'package:carino/theme/app_theme.dart';

void main() {
  group('Decompress shelf', () {
    test('filters by category and mode; group mode needs a verified group', () {
      const all = MockData.decompress;
      final water = filterExperiences(all, category: 'Water');
      expect(water, isNotEmpty);
      expect(water.every((e) => e.category == 'Water'), isTrue);
      final groups = filterExperiences(all, mode: BookMode.group);
      expect(groups, isNotEmpty);
      expect(groups.every((e) => e.groupGoing > 0 && e.spotsLeft > 0), isTrue);
      final dates = filterExperiences(all, mode: BookMode.date);
      expect(dates.every((e) => e.maxPeople >= 2), isTrue);
    });

    test('commission comes from the venue; the member pays the listed price', () {
      final b = quoteBooking(priceCents: 4500, people: 2, commissionRate: 0.12);
      expect(b.memberPaysCents, 9000);
      expect(b.carinoEarnsCents, 1080);
      expect(b.venueReceivesCents, 7920);
      expect(quoteBooking(priceCents: 0, people: 3, commissionRate: 0.12).carinoEarnsCents, 0);
    });

    test('cannot book more people than spots left', () {
      expect(() => quoteBooking(priceCents: 1000, people: 0, commissionRate: 0.1),
          throwsArgumentError);
      final e = MockData.decompress.firstWhere((x) => x.spotsLeft > 0);
      expect(canBook(e, people: e.spotsLeft), isTrue);
      expect(canBook(e, people: e.spotsLeft + 1), isFalse);
    });
  });

  group('Phone-Down presence', () {
    final t0 = DateTime(2026, 11, 14, 19); // ignore: prefer_const_declarations

    test('screen locked counts as present; switching apps does not', () {
      final s = PresenceSession(startedAt: t0);
      s.away(t0.add(const Duration(minutes: 10)), screenOff: true);
      s.back(t0.add(const Duration(minutes: 70)));
      s.away(t0.add(const Duration(minutes: 80)), screenOff: false); // opened another app
      s.back(t0.add(const Duration(minutes: 85)));
      final r = s.end(t0.add(const Duration(minutes: 120)));
      expect(r.total, const Duration(minutes: 120));
      expect(r.distracted, const Duration(minutes: 5));
      expect(r.present, const Duration(minutes: 115));
      expect(r.checkIns, 1);
      expect(r.label, 'Phone down 1h 55m · 1 check-in');
    });

    test('a clean session is "fully present"', () {
      final s = PresenceSession(startedAt: t0);
      s.away(t0.add(const Duration(minutes: 1)), screenOff: true);
      final r = s.end(t0.add(const Duration(hours: 2, minutes: 14)));
      expect(r.checkIns, 0);
      expect(r.label, 'Phone down 2h 14m · fully present');
    });

    test('ending while away in another app counts that time as distracted', () {
      final s = PresenceSession(startedAt: t0);
      s.away(t0.add(const Duration(minutes: 30)), screenOff: false);
      final r = s.end(t0.add(const Duration(minutes: 40)));
      expect(r.distracted, const Duration(minutes: 10));
    });
  });

  group('screens', () {
    Future<void> phone(WidgetTester t) async {
      t.view.physicalSize = const Size(360, 740) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
    }

    testWidgets('Decompress: book a free walk end to end', (tester) async {
      await phone(tester);
      Services.prefs.bookings.clear();
      await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: const DecompressScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Sunset walk on the Scioto Mile'));
      await tester.pumpAndSettle();
      expect(find.text('Free'), findsWidgets);
      await tester.tap(find.text('Reserve my spot'));
      await tester.pumpAndSettle();
      expect(Services.prefs.bookings, hasLength(1));
      expect(find.text("You're booked"), findsOneWidget);
    });

    testWidgets('Decompress: group mode shows only groups with members going', (tester) async {
      await phone(tester);
      await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: const DecompressScreen()));
      await tester.tap(find.text('Join a group'));
      await tester.pump();
      expect(find.text('Spa hour: sauna + cold plunge'), findsNothing); // no group going
      await tester.scrollUntilVisible(find.text('Park yoga, all levels'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Park yoga, all levels'), findsOneWidget);
    });

    testWidgets('Phone-Down: run, end, see the Presence card', (tester) async {
      await phone(tester);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.dark(),
          home: const PhoneDownScreen(planTitle: 'Coffee with Aria')));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      // The breathing circle loops forever by design: step time, don't settle.
      await tester.tap(find.text('End Phone-Down'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('End and see my score'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining('Phone down'), findsOneWidget);
      expect(find.text('Presence Score · Cariño'), findsOneWidget);
    });
  });
}
