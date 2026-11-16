// Wave 3 · Weekly Drop rituals (CROWD-FEATURES #23). Pure logic, no
// Flutter imports.
//
// One themed Drop per weekday — an appointment habit, not a scroll
// habit. The theme is DETERMINISTIC from the date (same day, same
// ritual, for everyone) and it does real work: its boost terms feed
// the existing Tune My Drop matcher (drop_tuning.dart), so the Drop
// deck genuinely re-orders toward the theme. Every term below was
// checked against the seed profiles' real fields (interests,
// headlines, prompts) — a theme that matches nobody would be a lie
// printed on a banner.

/// A weekday's Drop ritual: display copy + the boost terms it tunes by.
class DropRitual {
  const DropRitual({
    required this.name,
    required this.tagline,
    required this.boostTerms,
  });

  /// 'Sunset Sunday'
  final String name;

  /// One honest line for the banner.
  final String tagline;

  /// Terms for applyTuneToDeck — matched against real profile fields.
  final List<String> boostTerms;
}

/// The seven rituals, keyed by DateTime.weekday (1 = Monday … 7 =
/// Sunday). Terms verified against MockData members + dailyDrop:
/// - Market Monday: Aria ('Farmers markets', 'market' in prompts)
/// - Trail Tuesday: Dev ('Trail running'), Priya ('Hiking')
/// - Vinyl Wednesday: Aria + Marcus ('Vinyl'), Priya ('Classical music')
/// - Game Night Thursday: Sofia ('Board games', 'Karaoke'), Dev ('Chess')
/// - Golden Hour Friday: Aria + Marcus ('Photography')
/// - Street-Food Saturday: Aria ('street-food' headline), Dev ('taco'
///   via the matcher's plural tolerance), Marcus ('Ramen tours')
/// - Sunset Sunday: Dev ('book' in 'bookstore' prompt), Priya
///   ('gardens' prompt, 'Book clubs')
const Map<int, DropRitual> _ritualsByWeekday = {
  DateTime.monday: DropRitual(
    name: 'Market Monday',
    tagline: 'Market people, cooks, and farmers-market crawls first.',
    boostTerms: ['farmers markets', 'market', 'cooking'],
  ),
  DateTime.tuesday: DropRitual(
    name: 'Trail Tuesday',
    tagline: 'Trail runners and hikers lead today\'s Drop.',
    boostTerms: ['trail', 'hiking', 'running'],
  ),
  DateTime.wednesday: DropRitual(
    name: 'Vinyl Wednesday',
    tagline: 'Vinyl collectors and live-music people up front.',
    boostTerms: ['vinyl', 'jazz', 'music'],
  ),
  DateTime.thursday: DropRitual(
    name: 'Game Night Thursday',
    tagline: 'Board games, karaoke and chess energy today.',
    boostTerms: ['board games', 'games', 'karaoke', 'chess'],
  ),
  DateTime.friday: DropRitual(
    name: 'Golden Hour Friday',
    tagline: 'Photographers and golden-hour chasers first.',
    boostTerms: ['photography', 'sunset'],
  ),
  DateTime.saturday: DropRitual(
    name: 'Street-Food Saturday',
    tagline: 'Street-food people lead — bring an appetite.',
    boostTerms: ['street-food', 'tacos', 'ramen', 'cooking'],
  ),
  DateTime.sunday: DropRitual(
    name: 'Sunset Sunday',
    tagline: 'Slow Sundays: gardens, books and nowhere to rush.',
    boostTerms: ['gardens', 'sunset', 'book'],
  ),
};

/// The ritual for a weekday number (DateTime.weekday: 1–7). Out-of-range
/// input falls back to Monday rather than crashing a header.
DropRitual ritualForWeekday(int weekday) =>
    _ritualsByWeekday[weekday] ?? _ritualsByWeekday[DateTime.monday]!;

/// The ritual for a concrete date — deterministic, no clock reads
/// inside, so tests pin exact dates.
DropRitual ritualForDate(DateTime date) => ritualForWeekday(date.weekday);
