/// Creator money: credits for gifts, paid subscriptions to creators, and
/// who may comment. Store billing sells credits and subscriptions in the
/// apps; Stripe on the web.
library;

class CreditPack {
  const CreditPack(this.id, this.credits, this.priceCents);
  final String id; // store product id
  final int credits;
  final int priceCents;
  String get price => '\$${(priceCents / 100).toStringAsFixed(2)}';
}

const creditPacks = [
  CreditPack('carino_credits_3', 3, 99),
  CreditPack('carino_credits_10', 10, 299),
  CreditPack('carino_credits_40', 40, 999),
];

class GiftItem {
  const GiftItem(this.emoji, this.name, this.credits);
  final String emoji;
  final String name;
  final int credits;
}

const giftMenu = [
  GiftItem('🌹', 'Rose', 1),
  GiftItem('☕', 'Coffee', 1),
  GiftItem('💖', 'Heart', 2),
  GiftItem('🍫', 'Chocolates', 3),
  GiftItem('💐', 'Bouquet', 5),
  GiftItem('💎', 'Diamond', 20),
];

class CreditWallet {
  int balance = 0;
  void buy(CreditPack p) => balance += p.credits;

  /// Spends credits on a gift; false (and nothing spent) if not enough.
  bool send(GiftItem g) {
    if (balance < g.credits) return false;
    balance -= g.credits;
    return true;
  }
}

/// Creators set a monthly price; they keep 80%, Cariño 20%
/// (store fees come out of Cariño's share).
const creatorShare = 0.8;
({int creator, int platform}) creatorSplit(int priceCents) {
  final c = (priceCents * creatorShare).floor();
  return (creator: c, platform: priceCents - c);
}

const creatorPriceOptionsCents = [199, 499, 999, 1999];

/// Likes are free for everyone; comments are for Plus members or the
/// creator's subscribers (keeps comment sections kind and spam-free).
bool canComment({required bool isPlus, required bool subscribed}) => isPlus || subscribed;

int maxVideoSeconds({required bool isPlus}) => isPlus ? 180 : 60;

/// Spark call (a short video call before meeting): null = unlimited.
int? sparkCallMinutes({required bool isPlus}) => isPlus ? null : 15;
