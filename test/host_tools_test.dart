import 'package:carino/models/host_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one link brings a whole group into a circle', () {
    expect(groupInviteLink('circle-garden'), endsWith('/#/c/circle-garden'));
  });

  test('custom check-in codes: tidy, 4–8 letters or digits', () {
    expect(cleanCheckInCode(' sun run 7 '), 'SUNRUN7');
    expect(cleanCheckInCode('abc'), isNull); // too short
    expect(cleanCheckInCode('averyveryveryLong'), isNull); // too long
    expect(cleanCheckInCode('café!!'), isNull); // only 3 usable letters
  });

  test('a default code is stable per plan', () {
    expect(defaultCheckInCode('plan-42'), defaultCheckInCode('plan-42'));
    expect(defaultCheckInCode('plan-42').length, 5);
  });
}
