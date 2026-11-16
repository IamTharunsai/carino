/// Book what a plan needs: a table, tickets, a stay, park passes, a ride.
/// Opens the partner's own booking page (search pre-filled) — payment
/// and confirmation happen there. Decompress partners book in-app.
library;

enum BookKind {
  table('Book a table', '🍽️'),
  tickets('Tickets & events', '🎟️'),
  stay('Hotel or stay', '🏨'),
  parks('Parks & passes', '🌲'),
  ride('Get a ride', '🚗');

  const BookKind(this.label, this.emoji);
  final String label;
  final String emoji;
}

Uri bookingUri(BookKind k, String what, String city) {
  final q = Uri.encodeComponent('$what $city'.trim());
  final c = Uri.encodeComponent(city);
  return switch (k) {
    BookKind.table => Uri.parse('https://www.opentable.com/s?term=$q'),
    BookKind.tickets => Uri.parse('https://www.eventbrite.com/d/${c.isEmpty ? 'online' : c}/${Uri.encodeComponent(what)}/'),
    BookKind.stay => Uri.parse('https://www.booking.com/searchresults.html?ss=$c'),
    BookKind.parks => Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent('$what tickets $city')}'),
    BookKind.ride => Uri.parse('https://m.uber.com/looking?drop[0]=${Uri.encodeComponent('{"addressLine1":"$what $city"}')}'),
  };
}

/// What to offer first for this plan (everything is always available).
List<BookKind> kindsFor(String plan) {
  final p = plan.toLowerCase();
  bool any(List<String> w) => w.any(p.contains);
  final first = <BookKind>[
    if (any(['gig', 'ticket', 'concert', 'show', 'comedy', 'event', 'festival', 'movie'])) BookKind.tickets,
    if (any(['weekend', 'trip', 'stay', 'hotel', 'getaway', 'night away'])) BookKind.stay,
    if (any(['park', 'hike', 'trail', 'zoo', 'garden', 'museum'])) BookKind.parks,
  ];
  return [...first, ...BookKind.values.where((k) => !first.contains(k))];
}
