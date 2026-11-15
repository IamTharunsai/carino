import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../config/env.dart';
import '../../services/verification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';
import '../you/support_screen.dart';

/// S-004 ID Verification — Intro & Consent.
///
/// What the member is told BEFORE anything is captured (and what must stay
/// TRUE in production):
///  - What is checked, in plain words (the three layers).
///  - Who checks it: the provider disclosure slot below — the vendor name
///    comes from config once D-01 is decided; it is never hard-coded.
///  - What is stored: the RESULT + a provider reference only — never the
///    ID images, where avoidable.
///  - Consent is a real gate: Start stays disabled until the box is ticked,
///    and the consent record + timestamp are stored server-side.
///  - An alternative route and an exit always exist. Exiting leaves the
///    account unverified — and discovery stays locked.
class VerificationIntroScreen extends StatefulWidget {
  const VerificationIntroScreen({
    super.key,
    required this.onStart,
    required this.onExit,
  });

  /// Consent given -> launch the provider flow (S-005).
  final VoidCallback onStart;

  /// Not now -> back out; account stays unverified + locked.
  final VoidCallback onExit;

  @override
  State<VerificationIntroScreen> createState() =>
      _VerificationIntroScreenState();
}

class _VerificationIntroScreenState extends State<VerificationIntroScreen> {
  bool _consent = false;

  /// Provider name slot (S-004): filled from backend config once the
  /// vendor is selected (OPEN DECISION D-01). Until then the copy stays
  /// generic — the build never invents a vendor.
  static const String _providerSlot =
      'a specialist verification provider (named here once selected)';

  Widget _step(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.sparkCoral),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Text('Everyone here is verified. Including you.',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Three checks, run by $_providerSlot — the same kind banks use.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          GlassContainer(
            child: Column(
              children: [
                for (final layer in VerificationLayer.values)
                  _step(
                    switch (layer) {
                      VerificationLayer.document => Icons.badge_outlined,
                      VerificationLayer.liveness =>
                        Icons.face_retouching_natural,
                      VerificationLayer.photoMatch => Icons.compare_outlined,
                    },
                    layer.label,
                    layer.tagline,
                  ),
                const Divider(),
                _step(Icons.storage_outlined, 'What we store',
                    'Only the result and a provider reference number. Your ID images stay with the provider and are deleted on their retention schedule — they are not kept by ${AppConfig.appName}.'),
                _step(Icons.gavel_outlined, 'If a check fails',
                    'You get the reason category, a retry, an alternative route, and a human appeal. No silent rejections.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _consent,
            onChanged: (v) => setState(() => _consent = v ?? false),
            title: Text(
              'I understand and consent to the ID, liveness, and photo-match checks described above.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 8),
          SparkButton(
            label: 'Start verification',
            icon: Icons.shield_outlined,
            // S-004 rule: enabled only after consent.
            onPressed: _consent ? widget.onStart : null,
          ),
          const SizedBox(height: 4),
          TextButton(
            // Alternative verification / accessibility route (S-004 rule:
            // it must exist) — routed via Support until the vendor's
            // alternative flow is contracted (D-01).
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SupportScreen()),
            ),
            child: const Text('Need another way? Alternative route & support'),
          ),
          TextButton(
            onPressed: widget.onExit,
            child: const Text('Not now — I\'ll stay unverified'),
          ),
          Text(
            'Unverified accounts can\'t browse or message anyone. That\'s '
            'the rule that keeps this place real.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (Env.useMockBackend)
            Text(
              'Demo build: the provider SDK is stubbed (VerificationService) '
              'and the checks pass so the flow can be walked end-to-end.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
