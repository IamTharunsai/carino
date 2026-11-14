import 'package:flutter_test/flutter_test.dart';
import 'package:carino/data/mock_data.dart';
import 'package:carino/models/platform.dart';
import 'package:carino/models/social.dart';

void main() {
  test('splits preserve every cent for varied amounts and group sizes', () {
    for (final amount in [0, 1, 2, 99, 100, 1001, 9999999]) {
      for (var people = 1; people <= 30; people++) {
        final shares = splitCents(amount, people);
        expect(shares.length, people);
        expect(shares.reduce((a, b) => a + b), amount);
        expect(shares.first - shares.last, inInclusiveRange(0, 1));
      }
    }
    expect(() => splitCents(-1, 2), throwsArgumentError);
    expect(() => splitCents(1, 0), throwsArgumentError);
    expect(formatCents(101), '\$1.01');
  });
  test('cost parser preserves cents and rejects ambiguous inputs', () {
    expect(parseCostCents(' 12.3 '), 1230);
    expect(parseCostCents('0.01'), 1);
    expect(parseCostCents('24'), 2400);
    for (final input in [
      '',
      '-1',
      'NaN',
      '1.234',
      '1e3',
      '1,000',
      '99999999'
    ]) {
      expect(parseCostCents(input), isNull);
    }
    expect(() => PlanSplit(totalCents: 1, participants: ['me', 'me']),
        throwsArgumentError);
  });
  test('trust requires matching codes and a meeting before a vouch', () {
    final graph = TrustGraph(metBy: {
      'friend': {'target'}
    });
    expect(graph.addVouch('friend', 'Helpful'), isFalse);
    expect(graph.confirmMeeting('friend', myCode: '', theirCode: ''), isFalse);
    expect(
        graph.confirmMeeting('friend', myCode: '123456', theirCode: '654321'),
        isFalse);
    expect(
        graph.confirmMeeting('friend', myCode: '123456', theirCode: '123456'),
        isTrue);
    expect(graph.introducersFor('target'), ['friend']);
    expect(graph.addVouch('friend', '  '), isFalse);
    expect(graph.addVouch('friend', ' Helpful '), isTrue);
    expect(graph.vouches['friend'], 'Helpful');
  });
  test('Vanish expires on deadline and leaves normal messages intact', () {
    final now = DateTime.utc(2026, 11, 13);
    final group = GroupChat(id: 'g', name: 'Test', memberIds: [], messages: [
      GroupMessage(senderId: 'me', text: 'normal', timeLabel: 'now'),
      GroupMessage(
          senderId: 'me', text: 'expired', timeLabel: 'now', expiresAt: now),
      GroupMessage(
          senderId: 'me',
          text: 'later',
          timeLabel: 'now',
          expiresAt: now.add(const Duration(hours: 1))),
    ]);
    group.removeExpired(now);
    expect(group.messages.map((m) => m.text), ['normal', 'later']);
    group.removeExpired(now.add(const Duration(hours: 1)));
    expect(group.messages.single.text, 'normal');
  });
  test('circles separate Dates and friends', () {
    expect(circleCanSee(Circle.dates, Circle.friends), isFalse);
    expect(circleCanSee(Circle.friends, Circle.dates), isFalse);
    expect(circleCanSee(Circle.friends, Circle.inner), isTrue);
  });
  test('poll changing votes never double counts and needs strict majority', () {
    final poll = PlanPoll(placeType: 'Coffee', options: ['Friday', 'Saturday']);
    poll.vote('a', 'Friday');
    expect(poll.winner(2), isNull);
    poll.vote('a', 'Saturday');
    poll.vote('b', 'Saturday');
    expect(poll.totalVotes, 2);
    expect(poll.winner(2), 'Saturday');
  });
  test('catch-up is bounded and quotes timing and questions', () {
    expect(catchUpSummary([]), ['Nothing new.']);
    final summary =
        catchUpSummary([('Maya', 'Meet tomorrow?'), ('You', 'Coffee?')]);
    expect(summary.first, contains('2 new messages'));
    expect(summary.join(' '), contains('Meet tomorrow?'));
    expect(summary.length, lessThanOrEqualTo(4));
  });
  test('human filter and time budget constrain the finite Stage feed', () {
    final controls = parseFeedControls(
        'more friends, less viral, no diet, more music, 1 min',
        {'Diet', 'Music'});
    expect(controls.moreFriends, isTrue);
    expect(controls.lessViral, isTrue);
    expect(controls.mutedTopics, {'Diet'});
    expect(controls.boostedTopics, {'Music'});
    final feed = buildFeed(MockData.feed, controls: controls, humanOnly: true);
    expect(
        feed.every(
            (p) => !p.aiGenerated && p.verifiedHuman && p.topic != 'Diet'),
        isTrue);
    expect(feed.fold<int>(0, (sum, p) => sum + p.durationSec),
        lessThanOrEqualTo(60));
  });
  test('host tiers reset after upheld reports', () {
    expect(
        hostTier(plansHosted: 10, positive: 10, reports: 0), HostTier.partner);
    expect(
        hostTier(plansHosted: 10, positive: 10, reports: 1), HostTier.newHost);
    expect(hostShareCents(1000, HostTier.partner), 700);
    expect(hostShareCents(1000, HostTier.newHost), 0);
  });
}
