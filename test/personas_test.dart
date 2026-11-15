// "The nth user": 10,000 seeded random people, each pairing checked against
// the rules that must hold for EVERYONE — privacy, comfort and honesty.
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

import 'package:carino/data/mock_data.dart';
import 'package:carino/models/care.dart';
import 'package:carino/models/experience.dart';
import 'package:carino/models/member.dart';
import 'package:carino/models/sync.dart';

const _pool = ['Coffee', 'Hiking', 'Ceramics', 'Jazz', 'Chess', 'Yoga', 'Kayaking', 'Exes',
  'Politics', 'Gaming', 'Cooking', 'Live music', 'Farmers markets', 'Bouldering', 'Work talk'];

T _pick<T>(Random r, List<T> xs) => xs[r.nextInt(xs.length)];
List<String> _some(Random r, int max) =>
    {for (var i = 0; i < r.nextInt(max + 1); i++) _pick(r, _pool)}.toList();
Map<String, String> _tastes(Random r) => {
      for (final q in tasteQuiz)
        if (r.nextBool()) q.id: r.nextBool() ? q.a : q.b
    };

Member _persona(Random r, int i) => Member(
      id: 'p$i',
      name: 'Person $i',
      age: 21 + r.nextInt(50),
      city: 'Columbus',
      distanceBand: '—',
      intention: _pick(r, Intention.values),
      photoAsset: '',
      headline: '',
      prompts: const [],
      interests: _some(r, 5),
      tasteAnswers: _tastes(r),
      textingStyle: TextingStyle(
        pace: r.nextBool() ? _pick(r, ReplyPace.values) : null,
        voice: r.nextBool() ? _pick(r, VoiceNotes.values) : null,
        loves: _some(r, 3),
        avoid: _some(r, 2),
      ),
      comfort: ComfortRules(
        noCallsBeforeMeet: r.nextBool(),
        photosAfterDays: _pick(r, const [0, 3, 7]),
        daytimeFirstMeet: r.nextBool(),
        opensFirst: r.nextInt(4) == 0,
      ),
    );

void main() {
  test('10,000 people: every pairing keeps privacy, comfort and honesty rules', () {
    final r = Random(2050);
    final people = [for (var i = 0; i < 10000; i++) _persona(r, i)];
    for (var i = 0; i < people.length; i++) {
      final me = people[i], them = people[(i * 7919 + 1) % people.length];
      final avoid = them.textingStyle.avoid.map((a) => a.toLowerCase());

      // You both: only real overlaps, never a topic they asked to avoid.
      final chips = commonGround(
        myInterests: me.interests,
        theirInterests: them.interests,
        myTastes: me.tasteAnswers,
        theirTastes: them.tasteAnswers,
        theirAvoid: them.textingStyle.avoid,
      );
      final mineAll = {...me.interests.map((x) => x.toLowerCase()), ...me.tasteAnswers.values.map((x) => x.toLowerCase())};
      final theirsAll = {...them.interests.map((x) => x.toLowerCase()), ...them.tasteAnswers.values.map((x) => x.toLowerCase())};
      for (final c in chips) {
        expect(mineAll.contains(c.toLowerCase()) && theirsAll.contains(c.toLowerCase()), isTrue);
        expect(avoid.any((a) => c.toLowerCase().contains(a)), isFalse);
      }
      expect(groundedOpeners(chips, them.firstName).length, lessThanOrEqualTo(3));

      // Games: personal, no repeats, never an avoided topic.
      final deck = personalDeck(myInterests: me.interests, myTastes: me.tasteAnswers, them: them);
      expect(deck.map((q) => q.prompt).toSet().length, deck.length);
      for (final q in deck) {
        expect(avoid.any((a) => q.prompt.toLowerCase().contains(a)), isFalse);
      }

      // Comfort rules: meeting in person always lifts them; otherwise they hold.
      for (final met in [true, false]) {
        final call = callBlockedReason(mine: me.comfort, theirs: them.comfort, met: met, theirName: 'x');
        final photo = photoBlockedReason(theirs: them.comfort, daysChatting: 1, met: met, theirName: 'x');
        if (met) {
          expect(call, isNull);
          expect(photo, isNull);
        } else {
          expect(call == null, !(me.comfort.noCallsBeforeMeet || them.comfort.noCallsBeforeMeet));
          expect(photo == null, them.comfort.photosAfterDays <= 1);
        }
      }
      expect(firstMessageHold(theirs: them.comfort, theyHaveWritten: false, theirName: 'x') == null,
          !them.comfort.opensFirst);
    }

    // Private reflections only reorder — never drop or invent a plan.
    final reflections = [
      for (var i = 0; i < 50; i++)
        Reflection(category: _pick(r, ['Calm', 'Walk', 'Sports', 'Café', null]), good: r.nextBool())
    ];
    final ranked = rankForMe(MockData.decompress, reflections).map((x) => x.experience.id).toSet();
    expect(ranked, MockData.decompress.map((e) => e.id).toSet());
  });
}
