import 'dart:ui';
import 'package:carino/models/selfie_guide.dart';
import 'package:flutter_test/flutter_test.dart';

FaceReading face({double l = 0.3, double t = 0.25, double w = 0.45, double yaw = 0, double light = 0.6}) =>
    FaceReading(box: Rect.fromLTWH(l, t, w, w * 1.3), yaw: yaw, light: light);

void main() {
  test('no face asks them to step into the oval', () {
    expect(guide(null, SelfieStep.center).ok, isFalse);
    expect(guide(null, SelfieStep.center).text, contains('oval'));
  });

  test('framing problems come one at a time, light first', () {
    expect(guide(face(light: 0.1), SelfieStep.center).text, contains('light'));
    expect(guide(face(w: 0.2, l: 0.4), SelfieStep.center).text, contains('closer'));
    expect(guide(face(w: 0.85, l: 0.07, t: 0.0), SelfieStep.center).text, contains('back'));
    expect(guide(face(l: 0.0), SelfieStep.center).text, contains('Center'));
  });

  test('a well-framed face passes the center step', () {
    expect(guide(face(l: 0.275), SelfieStep.center).ok, isTrue);
  });

  test('steps advance: center -> turn one way -> turn the other way -> done', () {
    final good = face(l: 0.275);
    final s = SelfieSession();
    s.feed(good);
    expect(s.step, SelfieStep.left);
    s.feed(good); // hasn't turned yet
    expect(s.step, SelfieStep.left);
    s.feed(face(l: 0.275, yaw: 25));
    expect(s.step, SelfieStep.right);
    s.feed(face(l: 0.275, yaw: 30)); // same side again doesn't count
    expect(s.step, SelfieStep.right);
    s.feed(face(l: 0.275, yaw: -25));
    expect(s.step, SelfieStep.done);
  });

  test('either direction first works (cameras mirror differently)', () {
    final s = SelfieSession()..feed(face(l: 0.275));
    s.feed(face(l: 0.275, yaw: -22));
    s.feed(face(l: 0.275, yaw: 22));
    expect(s.step, SelfieStep.done);
  });

  test('a badly framed face never advances', () {
    final s = SelfieSession()..feed(face(w: 0.15));
    expect(s.step, SelfieStep.center);
    s.feed(null);
    expect(s.step, SelfieStep.center);
  });
}
