import 'package:carino/models/plans.dart';
import 'package:carino/services/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day1 = DateTime(2026, 11, 15, 10);
  final day2 = day1.add(const Duration(days: 1));

  test('free likes are capped per day and reset at midnight', () {
    final p = UserPrefs();
    for (var i = 0; i < freeLikesPerDay; i++) {
      expect(p.useLike(day1, isPlus: false), isTrue);
    }
    expect(p.likesLeft(day1, isPlus: false), 0);
    expect(p.useLike(day1, isPlus: false), isFalse);
    expect(p.likesLeft(day2, isPlus: false), freeLikesPerDay);
  });

  test('Plus likes are unlimited', () {
    final p = UserPrefs();
    for (var i = 0; i < freeLikesPerDay * 3; i++) {
      expect(p.useLike(day1, isPlus: true), isTrue);
    }
    expect(p.likesLeft(day1, isPlus: true), isNull);
  });

  test('bought Super Likes are spent after the daily one and never expire', () {
    final p = UserPrefs();
    p.addSparkPack();
    expect(p.sparksLeft(day1, isPlus: false), 1 + superLikePackSize);
    for (var i = 0; i < 1 + superLikePackSize; i++) {
      expect(p.useSpark(day1, isPlus: false), isTrue);
    }
    expect(p.useSpark(day1, isPlus: false), isFalse);
    expect(p.sparksLeft(day2, isPlus: false), 1); // pack used up, daily one back
  });

  test('plan table never lists safety as a paid feature', () {
    for (final row in planRows) {
      expect(row.label.toLowerCase(), isNot(contains('report')));
      expect(row.label.toLowerCase(), isNot(contains('block')));
    }
    expect(planRows.any((r) => r.label.contains('crush on you')), isTrue);
  });
}
