import 'package:carino/models/creator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('credits: buying adds, gifting spends, never below zero', () {
    final w = CreditWallet();
    w.buy(creditPacks.first);
    expect(w.balance, creditPacks.first.credits);
    final rose = giftMenu.firstWhere((g) => g.name == 'Rose');
    expect(w.send(rose), isTrue);
    expect(w.balance, creditPacks.first.credits - rose.credits);
    final big = giftMenu.reduce((a, b) => a.credits > b.credits ? a : b);
    expect(w.send(big), isFalse); // can't afford — nothing spent
    expect(w.balance, creditPacks.first.credits - rose.credits);
  });

  test('cheapest pack is under a dollar and buys at least 2 gifts', () {
    final p = creditPacks.first;
    expect(p.priceCents, lessThan(100));
    final cheapest = giftMenu.map((g) => g.credits).reduce((a, b) => a < b ? a : b);
    expect(p.credits ~/ cheapest, greaterThanOrEqualTo(2));
  });

  test('creator subscription split: creator keeps 80%', () {
    final s = creatorSplit(999);
    expect(s.creator, 799);
    expect(s.platform, 200);
    expect(s.creator + s.platform, 999);
  });

  test('comments: Plus members or subscribers only; likes for everyone', () {
    expect(canComment(isPlus: false, subscribed: false), isFalse);
    expect(canComment(isPlus: true, subscribed: false), isTrue);
    expect(canComment(isPlus: false, subscribed: true), isTrue);
  });

  test('video and call limits', () {
    expect(maxVideoSeconds(isPlus: false), 60);
    expect(maxVideoSeconds(isPlus: true), 180);
    expect(sparkCallMinutes(isPlus: false), 15);
    expect(sparkCallMinutes(isPlus: true), isNull); // unlimited
  });
}
