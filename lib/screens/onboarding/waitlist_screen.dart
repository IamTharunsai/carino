import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../config/env.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// S-009B City Waitlist — shown when the member's city batch is full
/// (RemoteConfig `city_batch_full`, REA §5.6). A quality promise, NOT fake
/// scarcity: no invented queue positions, no countdown theatre — the copy
/// states the real reason and the real promise, and admission is driven by
/// the server flipping the batch state.
class WaitlistScreen extends StatefulWidget {
  const WaitlistScreen({super.key, required this.onAdmitted});

  /// Called when the batch opens (server push in production).
  final VoidCallback onAdmitted;

  @override
  State<WaitlistScreen> createState() => _WaitlistScreenState();
}

class _WaitlistScreenState extends State<WaitlistScreen> {
  bool _notify = true;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.location_city_outlined,
                size: 52, color: Color(0xFFFF6B6B)),
            const SizedBox(height: 14),
            Text('Your city batch is full — for now.',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              '${AppConfig.appName} opens in small city batches so every '
              'new member arrives to real, verified people — not an empty '
              'room. You\'re verified and your place is held; we\'ll let '
              'you in as soon as this batch opens.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            GlassContainer(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notify me when my batch opens'),
                subtitle: const Text(
                    'One notification. No marketing, no drip campaign.'),
                value: _notify,
                onChanged: (v) => setState(() => _notify = v),
              ),
            ),
            const Spacer(),
            // Scaffold affordance: in production the admission arrives as
            // a server push when the batch opens; this button stands in so
            // the flow can be walked end-to-end.
            if (Env.useMockBackend) ...[
            SparkButton(
              label: 'Continue',
              onPressed: widget.onAdmitted,
            ),
            const SizedBox(height: 6),
            Text(
              'Demo build: admission is server-driven in production — this '
              'button simulates the batch opening.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            ],
          ],
        ),
      ),
    );
  }
}
