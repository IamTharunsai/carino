import 'package:carino/models/booking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every booking kind builds a search link for the place and city', () {
    for (final k in BookKind.values) {
      final u = bookingUri(k, 'taco truck', 'Columbus');
      expect(u.scheme, 'https');
      expect(Uri.decodeFull(u.toString()), contains('Columbus'));
    }
  });

  test('suggests the right kinds for the plan', () {
    expect(kindsFor('Jazz bar'), contains(BookKind.table));
    expect(kindsFor('Gig tickets'), contains(BookKind.tickets));
    expect(kindsFor('Weekend in Napa'), contains(BookKind.stay));
    expect(kindsFor('National park hike'), contains(BookKind.parks));
    expect(kindsFor('anything').first, BookKind.table); // always something to book
  });
}
