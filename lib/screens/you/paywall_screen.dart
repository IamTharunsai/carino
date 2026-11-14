import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';
import '../experience/experience_screens.dart';

/// S-054 Paywall — ${AppConfig.plusName}, and S-054B management entry.
///
/// Honesty rules (blueprint + REA §5.8 intro-pricing pattern, ethical cut):
///  - Founding-member intro pricing is ONE clear price with the renewal
///    price and terms on THIS screen — no strikethrough theatre, no fake
///    expiring coupons.
///  - The real price renders from the store via PaymentsService /
///    RevenueCat — never hard-coded (final Plus pricing is an OPEN
///    DECISION; the Bible's $12.99/mo is a test hypothesis).
///  - Safety (report, block, appeals, Safety Centre) is NOT in the Plus
///    column. It is free, forever, and not listed as a "feature" at all.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _busy = false;
  // S-054 plan selector: monthly vs annual. PRICES COME FROM THE STORE
  // (RevenueCat offerings) — the cards state the period and that the
  // store shows the price; no number is ever hard-coded here (D-04: the
  // $12.99 figure in the Bible is a test hypothesis, not a price).
  String _plan = 'monthly';

  Future<void> _subscribe() async {
    setState(() => _busy = true);
    await Services.payments.purchaseDemoPlus();
    if (!mounted) return;
    setState(() => _busy = false);
    // Success = quiet check, StoreKit system sounds (ANIMATION sheet).
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${AppConfig.plusName} active (demo entitlement)')),
    );
  }

  Widget _compareRow(String label, String free, String plus) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label)),
          Expanded(flex: 2, child: Text(free, textAlign: TextAlign.center)),
          Expanded(
            flex: 2,
            child: Text(
              plus,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.sparkCoral, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(title: Text(AppConfig.plusName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(child: Image.asset(AppConfig.assetAppIcon, height: 84)),
          const SizedBox(height: 12),
          Text(
            'Less swiping into the void. More actual plans.',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GlassContainer(
            child: Column(
              children: [
                _compareRow('', 'Free', 'Plus'),
                const Divider(),
                _compareRow('Daily Drop + nearby discovery', 'Included', 'Included'),
                _compareRow('See who liked you', 'Count only', 'Full list'),
                _compareRow('Read receipts in chat', '—', 'Included'),
                _compareRow('Spark Session invites', 'Standard queue', 'Priority windows'),
                _compareRow('Advanced reciprocal filters', 'Basic', 'Full'),
                _compareRow('Undo a pass', '—', 'Included'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Report, block, appeals and the Safety Centre are free for everyone, always — they\'re not in this table because safety isn\'t a tier.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Founding-member intro price',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'The price and renewal price are shown by the App Store / Google Play before you confirm — the same number, no surprises at renewal. Cancel anytime in store settings; access runs to the end of the paid period.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GlassContainer(
                  opacity: _plan == 'monthly' ? 0.9 : null,
                  onTap: () => setState(() => _plan = 'monthly'),
                  child: Column(
                    children: [
                      Text('Monthly',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('Price shown at checkout',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassContainer(
                  opacity: _plan == 'annual' ? 0.9 : null,
                  onTap: () => setState(() => _plan = 'annual'),
                  child: Column(
                    children: [
                      Text('Annual',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('Best value · price shown at checkout',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SparkButton(
            label: _busy ? 'Processing…' : 'Continue to store checkout',
            icon: Icons.workspace_premium_outlined,
            onPressed: _busy ? null : _subscribe,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ReferralScreen()),
            ),
            icon: const Icon(Icons.local_offer_outlined, size: 18),
            label: const Text('Have a promo code? · Invite friends for free weeks'),
          ),
          SparkButton(
            label: 'Restore purchases',
            icon: Icons.restore,
            secondary: true,
            onPressed: () async {
              final restored = await Services.payments.restore();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(restored
                      ? 'Plus restored on this device.'
                      : 'No previous purchase found for this account.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
