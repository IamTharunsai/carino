import 'package:flutter/foundation.dart';

/// Subscriptions (blueprint S-054 / S-054B).
///
/// PRODUCTION: StoreKit / Play Billing products managed through RevenueCat
/// (entitlement: `plus`). The paywall shows the REAL price + renewal terms
/// returned by the store — never a hard-coded price in the UI.
/// Final Plus pricing is an OPEN DECISION in the blueprint (the Bible's
/// $12.99/mo figure is a test hypothesis, not a locked price).
///
/// Safety features (report, block, Safety Centre) are NEVER behind this
/// entitlement — that check must not exist anywhere in the safety flows.
class PaymentsService {
  bool _isPlus = false;
  bool get isPlus => _isPlus;

  /// INTEGRATION POINT: `Purchases.purchasePackage(...)` then verify the
  /// `plus` entitlement from the RevenueCat customer info, mirrored
  /// server-side for cross-device consistency.
  Future<bool> purchaseDemoPlus() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _isPlus = true;
    debugPrint('[PaymentsService] demo Plus entitlement granted (stub)');
    return true;
  }

  /// Restore purchases (required on the paywall, S-054).
  Future<bool> restore() async => _isPlus;
}
