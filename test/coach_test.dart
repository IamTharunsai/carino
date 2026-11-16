import 'package:carino/models/coach.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('coach asks only about what is missing', () {
    final qs = coachQuestions(hasBio: true, interestCount: 0, promptCount: 3);
    expect(qs.map((q) => q.field), [CoachField.interests]);
    expect(coachQuestions(hasBio: true, interestCount: 5, promptCount: 3), isEmpty);
  });

  test('offline draft turns plain answers into profile fields', () {
    final d = draftFromAnswers({
      CoachField.weekend: 'hiking and then coffee with friends, some live music',
      CoachField.work: 'I design apps',
      CoachField.firstDate: 'tacos and a long walk',
    });
    expect(d.interests, containsAll(['Hiking', 'Coffee', 'Live music']));
    expect(d.bio, contains('design apps'));
    expect(d.promptAnswers['My ideal first plan is…'], 'tacos and a long walk');
  });

  test('custom interests are kept as typed, trimmed and deduped', () {
    expect(cleanInterest('  salsa dancing '), 'Salsa dancing');
    expect(cleanInterest(''), isNull);
  });
}
