import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// S-002 Age Gate — DOB entry, and S-002B the under-21 blocked notice.
/// Hard rules: under-21 can NEVER create an account or reach the tab bar;
/// on a block, no profile data is retained (attempt log only).
class AgeGateScreen extends StatefulWidget {
  const AgeGateScreen({super.key, required this.onPassed});

  /// Called only when the entered DOB proves 21+.
  final VoidCallback onPassed;

  @override
  State<AgeGateScreen> createState() => _AgeGateScreenState();
}

class _AgeGateScreenState extends State<AgeGateScreen> {
  DateTime? _dob;
  bool _blocked = false;

  int _ageOn(DateTime dob, DateTime today) {
    var age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Your date of birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _continue() {
    final dob = _dob;
    if (dob == null) return;
    if (_ageOn(dob, DateTime.now()) >= AppConfig.minimumAge) {
      widget.onPassed();
    } else {
      // NOTE: production cross-checks this DOB against the verified ID
      // (S-005/S-006). A mismatch at verification = fail + appeal path.
      setState(() => _blocked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_blocked) {
      // S-002B — clear refusal, calm tone, no account created.
      return GlassScaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_outline, size: 44),
              const SizedBox(height: 16),
              Text(
                '${AppConfig.appName} is ${AppConfig.minimumAge}+ only',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Thanks for your honesty. This isn\'t a "try again with a '
                'different date" thing — verification checks your real ID '
                'later anyway. We\'ll be here when you\'re ${AppConfig.minimumAge}.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GlassScaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text('First, the honest part.',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '${AppConfig.appName} is for adults ${AppConfig.minimumAge} and over. '
              'Enter the date of birth on your government ID — it\'s checked '
              'against the real document in the next steps.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            GlassContainer(
              onTap: _pickDob,
              child: Row(
                children: [
                  const Icon(Icons.cake_outlined),
                  const SizedBox(width: 12),
                  Text(
                    _dob == null
                        ? 'Tap to enter your date of birth'
                        : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const Spacer(),
            SparkButton(
              label: 'Continue',
              onPressed: _dob == null ? null : _continue,
            ),
          ],
        ),
      ),
    );
  }
}
