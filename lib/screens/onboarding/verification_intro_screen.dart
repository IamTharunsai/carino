import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

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
          Text('Verify it’s you',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Takes about 2 minutes. It’s why everyone you meet here is real.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          GlassContainer(
            child: Column(
              children: [
                _step(Icons.badge_outlined, '1 · Your ID',
                    'Shows you’re 21 or older. Your birth date is never shown.'),
                _step(Icons.face_retouching_natural, '2 · A quick selfie',
                    'Shows it’s really you, live.'),
                _step(Icons.lock_outline, 'What we keep',
                    'Only the result (verified or not) and the date. Never your ID photos.'),
                _step(Icons.shield_outlined, 'Who checks it',
                    'A certified identity partner (SOC 2 Type II and ISO 27001). We’ll name them here before launch. '
                    'They delete your ID images within 30 days, and nothing is ever sold or used to train AI.'),
                _step(Icons.toggle_on_outlined, 'Optional',
                    'You can use Cariño without it — verified people just get the gold tick.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _consent,
            onChanged: (v) => setState(() => _consent = v ?? false),
            title: Text('I agree to the ID and selfie check.',
                style: Theme.of(context).textTheme.bodyMedium),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 8),
          SparkButton(
            label: 'Start',
            icon: Icons.shield_outlined,
            onPressed: _consent ? widget.onStart : null,
          ),
          TextButton(
            onPressed: widget.onExit,
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }
}
