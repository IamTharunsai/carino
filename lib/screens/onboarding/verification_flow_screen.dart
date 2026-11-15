import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/services.dart';
import '../../services/verification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';
import '../you/support_screen.dart';

/// S-005 ID Capture + S-006 Liveness / Photo Match — the PROVIDER flow.
///
/// The blueprint is explicit: never build a custom ID scanner — the real
/// vendor SDK (Persona/Veriff class, D-01 OPEN) owns this UI in production.
/// This screen is the honest scaffold of that surface: it walks the vendor
/// states (capturing -> processing -> done) for Layer 1, then the Layer 2/3
/// selfie + match, with the required controls present and functional:
/// Retake, Upload fallback (vendor-permitting), Help (S-053), Cancel, and
/// an honest progress indicator (real state changes, no fake progress bar).
class VerificationProviderScreen extends StatefulWidget {
  const VerificationProviderScreen({
    super.key,
    required this.onComplete,
    required this.onCancel,
  });

  final VoidCallback onComplete;
  final VoidCallback onCancel;

  @override
  State<VerificationProviderScreen> createState() =>
      _VerificationProviderScreenState();
}

// Three layers, three visible steps: ID -> liveness -> photo match.
enum _Phase { idFront, idBack, processing, selfie, livenessCheck, matchIntro, matching, done }

class _VerificationProviderScreenState
    extends State<VerificationProviderScreen> {
  _Phase _phase = _Phase.idFront;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _advance() {
    switch (_phase) {
      case _Phase.idFront:
        setState(() => _phase = _Phase.idBack);
      case _Phase.idBack:
        setState(() => _phase = _Phase.processing);
        // Provider processing state — in production this is the vendor's
        // real status polling, and the S-007 pending state handles slow
        // results. Here the walk completes so onboarding can proceed.
        _timer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _phase = _Phase.selfie);
        });
      case _Phase.processing:
        break;
      case _Phase.selfie:
        setState(() => _phase = _Phase.livenessCheck);
        _timer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _phase = _Phase.matchIntro);
        });
      case _Phase.livenessCheck:
        break;
      case _Phase.matchIntro:
        setState(() => _phase = _Phase.matching);
        _timer = Timer(const Duration(seconds: 2), () async {
          if (!mounted) return;
          await Services.verification.runDemoFlow();
          if (!mounted) return;
          setState(() => _phase = _Phase.done);
          widget.onComplete();
        });
      case _Phase.matching:
      case _Phase.done:
        break;
    }
  }

  String get _title => switch (_phase) {
        _Phase.idFront => 'Photograph your ID — front',
        _Phase.idBack => 'Photograph your ID — back',
        _Phase.processing => 'Reading your document…',
        _Phase.selfie => 'Live selfie',
        _Phase.livenessCheck => 'Checking it\'s really you…',
        _Phase.matchIntro => 'Last check: photo match',
        _Phase.matching => 'Matching your selfie…',
        _Phase.done => 'Checks complete',
      };

  String get _body => switch (_phase) {
        _Phase.idFront =>
          'Fit the front of your government ID inside the frame. Glare-free, all four corners visible.',
        _Phase.idBack =>
          'Now the back. The barcode must be readable.',
        _Phase.processing =>
          'The provider is checking the document and your date of birth against the 21+ rule.',
        _Phase.selfie =>
          'Centre your face and follow the prompt. This proves a real person is here — a photo of a photo won\'t pass.',
        _Phase.livenessCheck =>
          'The provider confirms a live person took the selfie — not a photo or a screen.',
        _Phase.matchIntro =>
          'We compare your selfie with your ID photo, and later with your main profile photo, so the face people see is yours.',
        _Phase.matching =>
          'Your selfie is being matched to your ID photo.',
        _Phase.done => 'All three layers passed.',
      };

  @override
  Widget build(BuildContext context) {
    final busy = _phase == _Phase.processing ||
        _phase == _Phase.livenessCheck ||
        _phase == _Phase.matching;
    final step = _phase.index <= _Phase.processing.index
        ? 1
        : _phase.index <= _Phase.livenessCheck.index
            ? 2
            : 3;
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Verification'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel verification',
          onPressed: widget.onCancel,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SupportScreen()),
            ),
            child: const Text('Help'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Layer progress — states are real (driven by _phase), so this
            // is an honest indicator, not a fake progress bar (S-006 rule).
            Row(
              children: [
                for (final layer in VerificationLayer.values) ...[
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: _layerDone(layer)
                            ? AppColors.emberCrimson
                            : AppColors.softRose.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text('Step $step of 3 · ${const ['ID document', 'Liveness', 'Photo match'][step - 1]}',
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 12),
            Text(_title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(_body, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            Expanded(
              child: GlassContainer(
                child: Center(
                  child: busy
                      ? const CircularProgressIndicator(
                          color: AppColors.sparkCoral)
                      : Icon(
                          switch (_phase) {
                            _Phase.selfie => Icons.face_retouching_natural,
                            _Phase.matchIntro => Icons.compare_outlined,
                            _ => Icons.badge_outlined,
                          },
                          size: 64,
                          color: AppColors.sparkCoral,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Provider SDK surface (stub) — in production this whole frame '
              'is the verification vendor\'s own UI. ${AppConfig.appName} '
              'receives only the result + a reference.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!busy) ...[
              SparkButton(
                label: switch (_phase) {
                  _Phase.selfie => 'Take live selfie',
                  _Phase.matchIntro => 'Run photo match',
                  _ => 'Capture',
                },
                icon: _phase == _Phase.matchIntro
                    ? Icons.compare_outlined
                    : Icons.camera_alt_outlined,
                onPressed: _advance,
              ),
              const SizedBox(height: 8),
              // Retake/upload only make sense for the ID photos; a liveness
              // selfie can never be uploaded.
              if (_phase == _Phase.idFront || _phase == _Phase.idBack)
              Row(
                children: [
                  Expanded(
                    child: SparkButton(
                      label: 'Retake',
                      secondary: true,
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Photo cleared — line it up and capture again.'))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SparkButton(
                      label: 'Upload instead',
                      secondary: true,
                      // Only reachable if the chosen vendor supports an
                      // upload fallback (S-005) — kept visible per spec.
                      onPressed: _advance,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _layerDone(VerificationLayer layer) => switch (layer) {
        VerificationLayer.document =>
          _phase.index >= _Phase.selfie.index,
        VerificationLayer.liveness => _phase.index >= _Phase.matchIntro.index,
        VerificationLayer.photoMatch => _phase == _Phase.done,
      };
}

/// S-007 Verification Result — Passed / Pending / Failed, each with its
/// honest next step: badge explainer (never "verified = safe"), retry with
/// the failure reason category, alternative route, and a HUMAN appeal.
class VerificationResultScreen extends StatelessWidget {
  const VerificationResultScreen({
    super.key,
    required this.onPassed,
    required this.onRetry,
    this.demoStatus = VerificationStatus.passed,
  });

  final VoidCallback onPassed;
  final VoidCallback onRetry;

  /// Scaffold: the demo flow lands on Passed. The Pending/Failed variants
  /// are fully built below and previewable from the demo links on S-004.
  final VerificationStatus demoStatus;

  @override
  Widget build(BuildContext context) {
    return switch (demoStatus) {
      VerificationStatus.passed => _passed(context),
      VerificationStatus.pending => _pending(context),
      VerificationStatus.failed => _failed(context),
      VerificationStatus.notStarted => _pending(context),
    };
  }

  Widget _passed(BuildContext context) {
    return GlassScaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.verified, size: 56, color: AppColors.sparkCoral),
            const SizedBox(height: 14),
            Text('You\'re verified.',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'All three layers passed: ID (21+), liveness, photo match.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GlassContainer(
              onTap: () => _badgeSheet(context),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined,
                      color: AppColors.sparkCoral),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'What your badge means — and what it does not guarantee. Tap to read.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            const Spacer(),
            SparkButton(label: 'Continue', onPressed: onPassed),
          ],
        ),
      ),
    );
  }

  Widget _pending(BuildContext context) {
    return GlassScaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.hourglass_top, size: 56, color: AppColors.sparkCoral),
            const SizedBox(height: 14),
            Text('Still checking.',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Some checks need a person to look. We\'ll notify you the '
              'moment there\'s a result — most finish within a few hours. '
              'Discovery stays locked until it passes; that\'s the deal '
              'that keeps everyone here real.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SparkButton(
              label: 'OK — notify me',
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SupportScreen()),
              ),
              child: const Text('Talk to support'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _failed(BuildContext context) {
    return GlassScaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.error_outline, size: 56, color: AppColors.emberCrimson),
            const SizedBox(height: 14),
            Text('That check didn\'t pass.',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Reason category: the document photo couldn\'t be read '
              'clearly. That\'s the category the provider returns — your '
              'document itself is never stored by ${AppConfig.appName}.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SparkButton(
              label: 'Try again',
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
            const SizedBox(height: 8),
            SparkButton(
              label: 'Use the alternative route',
              secondary: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SupportScreen()),
              ),
            ),
            TextButton(
              // Appeals go to a HUMAN (S-007 rule) via the case system.
              onPressed: () => _appeal(context),
              child: const Text('Appeal to a human reviewer'),
            ),
          ],
        ),
      ),
    );
  }

  void _badgeSheet(BuildContext context) {
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What “Verified” means',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Checked: a real government ID, age 21+, a live face, and that '
            'the face matches the ID and the profile photo.\n\n'
            'NOT guaranteed: that anyone is kind, honest about their life, '
            'or safe to meet. Verification proves identity — never '
            'character. Keep first plans public and trust your judgement.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _appeal(BuildContext context) async {
    final ref = await Services.backend.submitAppeal(
      subject: 'Verification result appeal',
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Appeal filed · Ref $ref · A person reviews it — usually within 48h.'),
      ),
    );
  }
}
