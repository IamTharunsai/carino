// Mood-matched care, games made for each pair, "I'll message first".
// Written before the implementation (TDD).
import 'package:flutter_test/flutter_test.dart';

import 'package:carino/data/mock_data.dart';
import 'package:carino/models/care.dart';
import 'package:carino/models/sync.dart';

void main() {
  group('How are you, really?', () {
    test('every mood gets a human line, a one-minute step and real picks', () {
      for (final m in Mood.values) {
        final c = careFor(m);
        expect(c.line, isNotEmpty);
        expect(c.oneMinute, isNotEmpty);
        final picks = moodPicks(m, MockData.decompress);
        expect(picks, isNotEmpty, reason: m.name);
        expect(picks.every((e) => c.categories.contains(e.category)), isTrue);
      }
    });

    test('feeling low always shows the crisis line; others do not', () {
      expect(careFor(Mood.low).showCrisisLine, isTrue);
      expect(careFor(Mood.restless).showCrisisLine, isFalse);
    });

    test('lonely leads with plans where people are already going', () {
      final picks = moodPicks(Mood.lonely, MockData.decompress);
      expect(picks.first.groupGoing, greaterThan(0));
    });
  });

  group('Games made for the two of you', () {
    final aria = MockData.memberById('m-aria');

    test('deck is built from both profiles, not a fixed template', () {
      final deck = personalDeck(
        myInterests: const ['Coffee', 'Live music'],
        myTastes: const {'t1': 'Sunrise hike', 't3': 'Coffee and a walk'},
        them: aria,
      );
      final prompts = deck.map((q) => q.prompt).join(' | ');
      expect(prompts, contains('Photography'));        // their interest
      expect(prompts, contains('Film photography'));   // their "topics I love"
      expect(prompts, contains('Sunrise hike'));       // a taste you differ on
      expect(deck.map((q) => q.prompt).toSet().length, deck.length); // no repeats
      expect(deck.every((q) => q.options.length == 2), isTrue);
    });

    test('never asks about a topic they asked to avoid', () {
      final deck = personalDeck(myInterests: const ['Exes'], myTastes: const {}, them: aria);
      expect(deck.any((q) => q.prompt.toLowerCase().contains('exes')), isFalse);
    });
  });

  group("I'll message first", () {
    test('holds my first message until they write', () {
      const rule = ComfortRules(opensFirst: true);
      expect(firstMessageHold(theirs: rule, theyHaveWritten: false, theirName: 'Priya'),
          contains('Priya'));
      expect(firstMessageHold(theirs: rule, theyHaveWritten: true, theirName: 'Priya'), isNull);
      expect(firstMessageHold(theirs: const ComfortRules(), theyHaveWritten: false, theirName: 'Priya'),
          isNull);
      expect(comfortSummary(rule), contains('Sends the first message'));
    });
  });
}
