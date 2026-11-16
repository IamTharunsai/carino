import 'package:carino/models/flame.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final d1 = DateTime(2026, 11, 15, 9);
  test('first heartbeat lights a 1-day flame', () {
    final f = feedFlame(null, d1);
    expect(f.days, 1);
  });
  test('same day keeps the count, next day grows it', () {
    var f = feedFlame(null, d1);
    f = feedFlame(f, d1.add(const Duration(hours: 5)));
    expect(f.days, 1);
    f = feedFlame(f, d1.add(const Duration(days: 1)));
    expect(f.days, 2);
  });
  test('a missed day is forgiven once; two missed days start over', () {
    var f = feedFlame(null, d1);
    f = feedFlame(f, d1.add(const Duration(days: 2))); // skipped one day
    expect(f.days, 2);
    f = feedFlame(f, d1.add(const Duration(days: 5))); // skipped two
    expect(f.days, 1);
  });
  test('round trip', () {
    final f = feedFlame(null, d1);
    expect(Flame.fromJson(f.toJson()).days, 1);
  });
}
