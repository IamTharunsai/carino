import 'package:carino/data/mock_data.dart';
import 'package:carino/models/plans.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gold-tick profiles come first, order kept within each group', () {
    final a = MockData.members[0], b = MockData.members[1], c = MockData.members[2];
    final ranked = goldFirst([a, b, c], isGold: (m) => m.id == c.id);
    expect(ranked.map((m) => m.id), [c.id, a.id, b.id]);
  });

  test('free gets 10 hearts a day, unlimited feed', () {
    expect(freeLikesPerDay, 10);
    expect(planRows.first.free, 'Included'); // the Feed row
  });
}
