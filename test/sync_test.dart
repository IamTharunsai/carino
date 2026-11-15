// Conversation Sync: "How I text", "You both" common ground + openers +
// chat→plan bridge, enforced comfort rules, tone tags, private reflections,
// honest chat pause, private notes. Written before the implementation (TDD).
import 'package:flutter_test/flutter_test.dart';

import 'package:carino/data/mock_data.dart';
import 'package:carino/models/sync.dart';

void main() {
  group('How I text', () {
    test('pace note reads kindly and names the person', () {
      const s = TextingStyle(pace: ReplyPace.evenings);
      expect(paceNote('Aria', s), 'Aria usually replies in the evening');
      expect(paceNote('Aria', const TextingStyle(pace: ReplyPace.slow)),
          contains('not uninterested'));
    });

    test('style hints flag real mismatches only', () {
      const fast = TextingStyle(pace: ReplyPace.quick, voice: VoiceNotes.textOnly);
      const slow = TextingStyle(pace: ReplyPace.evenings, voice: VoiceNotes.love);
      final hints = styleHints(mine: fast, theirs: slow, name: 'Aria');
      expect(hints.any((h) => h.contains('evening')), isTrue);
      expect(hints.any((h) => h.contains('voice notes')), isTrue);
      expect(styleHints(mine: fast, theirs: fast, name: 'Aria'), isEmpty);
    });
  });

  group('You both', () {
    test('chips are real overlaps only, tastes first, never an avoided topic', () {
      final chips = commonGround(
        myInterests: ['Coffee', 'Live music', 'Tech'],
        theirInterests: ['Ceramics', 'Live music', 'Coffee'],
        myTastes: {'t1': 'Slow brunch', 't2': 'In bed by 11'},
        theirTastes: {'t1': 'Slow brunch', 't2': 'Midnight pancakes'},
        theirAvoid: ['coffee'],
      );
      expect(chips, ['Slow brunch', 'Live music']);
    });

    test('openers are built from the shared chips and are drafts to edit', () {
      final o = groundedOpeners(['Live music', 'Slow brunch'], 'Sofia');
      expect(o, hasLength(2));
      expect(o.first, contains('live music'));
      expect(groundedOpeners(const [], 'Sofia'), isEmpty);
    });

    test('a chip mentioned in the chat bridges to a matching Decompress plan', () {
      final b = findBridge(
        chips: ['Coffee and a walk'],
        texts: ['There\'s a place on High St, a café that would pass your audit'],
        experiences: MockData.decompress,
      );
      expect(b, isNotNull);
      expect(b!.chip, 'Coffee and a walk');
      expect(b.experience.category, 'Café');
      expect(findBridge(chips: ['Coffee and a walk'], texts: ['hello'],
          experiences: MockData.decompress), isNull);
    });
  });

  group('Comfort rules (enforced, visible to both)', () {
    test('no calls before meeting blocks either side until met', () {
      const strict = ComfortRules(noCallsBeforeMeet: true);
      expect(callBlockedReason(mine: const ComfortRules(), theirs: strict, met: false, theirName: 'Aria'),
          contains('Aria'));
      expect(callBlockedReason(mine: strict, theirs: const ComfortRules(), met: false, theirName: 'Aria'),
          contains('You'));
      expect(callBlockedReason(mine: strict, theirs: strict, met: true, theirName: 'Aria'), isNull);
    });

    test('photos wait for the recipient\'s day count', () {
      const r = ComfortRules(photosAfterDays: 3);
      expect(photoBlockedReason(theirs: r, daysChatting: 1, met: false, theirName: 'Aria'),
          contains('2 more days'));
      expect(photoBlockedReason(theirs: r, daysChatting: 3, met: false, theirName: 'Aria'), isNull);
      expect(photoBlockedReason(theirs: r, daysChatting: 0, met: true, theirName: 'Aria'), isNull);
    });

    test('daytime first meet limits plan hours until you have met', () {
      const day = ComfortRules(daytimeFirstMeet: true);
      expect(firstMeetAllowed('Tonight · 20:30', mine: const ComfortRules(), theirs: day, met: false), isFalse);
      expect(firstMeetAllowed('Sat · 11:00', mine: const ComfortRules(), theirs: day, met: false), isTrue);
      expect(firstMeetAllowed('Tonight · 20:30', mine: const ComfortRules(), theirs: day, met: true), isTrue);
    });

    test('summary lists only the rules that are on', () {
      expect(comfortSummary(const ComfortRules()), isEmpty);
      expect(comfortSummary(const ComfortRules(photosAfterDays: 3, noCallsBeforeMeet: true)),
          hasLength(2));
    });
  });

  group('Private reflections', () {
    test('past check-ins reorder the shelf and explain why', () {
      final mine = [
        const Reflection(category: 'Calm', good: true, liked: {ReflectTag.quiet}),
        const Reflection(category: 'Sports', good: false, disliked: {ReflectTag.busy}),
      ];
      final ranked = rankForMe(MockData.decompress, mine);
      expect(ranked.first.experience.category, 'Calm');
      expect(ranked.first.reason, isNotNull);
      expect(ranked.last.experience.category, 'Sports');
      // No reflections: original order, no invented reasons.
      final plain = rankForMe(MockData.decompress, const []);
      expect(plain.map((r) => r.experience.id), MockData.decompress.map((e) => e.id));
      expect(plain.every((r) => r.reason == null), isTrue);
    });

    test('a plan\'s place type maps to a shelf category', () {
      expect(categoryForPlace('Coffee'), 'Café');
      expect(categoryForPlace('Gallery walk'), 'Walk');
      expect(categoryForPlace('Bowling'), isNull);
    });
  });

  group('Pause, don\'t ghost', () {
    test('pause notice is honest and kind', () {
      expect(pauseNotice(PauseLength.fewDays, name: 'You'),
          'You paused this chat — back in a few days. Not ghosting, just busy.');
    });
  });
}
