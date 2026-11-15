// Notifications: real events only, personal language + tone, caps, quiet
// hours, private lock screen. Written before the implementation (TDD).
import 'package:flutter_test/flutter_test.dart';

import 'package:carino/models/notify.dart';

void main() {
  final noon = DateTime(2026, 11, 15, 12);
  const prefs = NotifPrefs(language: 'English');

  test('every notification comes from a real event and names the real person', () {
    final n = compose(const NotifEvent(NotifKind.message, who: 'Aria'), prefs, at: noon, sentToday: 0)!;
    expect(n.body, contains('Aria'));
    expect(n.kind, NotifKind.message);
  });

  test('written in the member\'s language', () {
    final es = compose(const NotifEvent(NotifKind.match, who: 'Aria'),
        const NotifPrefs(language: 'Spanish'), at: noon, sentToday: 0)!;
    expect(es.title, isNot(contains('match')));
    expect(es.body, contains('Aria'));
    for (final lang in supportedNotifLanguages) {
      for (final k in NotifKind.values) {
        final n = compose(NotifEvent(k, who: 'Sam', detail: 'Coffee'),
            NotifPrefs(language: lang), at: noon, sentToday: 0);
        expect(n, isNotNull, reason: '$lang $k');
      }
    }
  });

  test('generic previews keep names off the lock screen', () {
    final n = compose(const NotifEvent(NotifKind.message, who: 'Aria'),
        const NotifPrefs(language: 'English', genericPreviews: true), at: noon, sentToday: 0)!;
    expect(n.lockScreen, isNot(contains('Aria')));
    expect(n.body, contains('Aria')); // inside the app it's personal
  });

  test('quiet hours hold non-urgent ones; safety always gets through', () {
    final night = DateTime(2026, 11, 15, 23, 30);
    expect(compose(const NotifEvent(NotifKind.match, who: 'Aria'), prefs, at: night, sentToday: 0), isNull);
    expect(compose(const NotifEvent(NotifKind.safetyCheckIn, who: 'Aria'), prefs, at: night, sentToday: 0),
        isNotNull);
  });

  test('a daily cap stops nagging (safety and messages exempt)', () {
    expect(compose(const NotifEvent(NotifKind.dailyDrop), prefs, at: noon, sentToday: 5), isNull);
    expect(compose(const NotifEvent(NotifKind.message, who: 'Aria'), prefs, at: noon, sentToday: 5),
        isNotNull);
  });

  test('a turned-off category stays off', () {
    expect(compose(const NotifEvent(NotifKind.dailyDrop),
        const NotifPrefs(language: 'English', off: {NotifKind.dailyDrop}), at: noon, sentToday: 0), isNull);
  });

  test('tone changes the words, never the facts', () {
    final warm = compose(const NotifEvent(NotifKind.planReminder, who: 'Aria', detail: 'Coffee'),
        const NotifPrefs(language: 'English', tone: NotifTone.playful), at: noon, sentToday: 0)!;
    final calm = compose(const NotifEvent(NotifKind.planReminder, who: 'Aria', detail: 'Coffee'),
        const NotifPrefs(language: 'English', tone: NotifTone.calm), at: noon, sentToday: 0)!;
    expect(warm.body, isNot(calm.body));
    for (final n in [warm, calm]) {
      expect(n.body, contains('Aria'));
      expect(n.body, contains('Coffee'));
    }
  });
}
