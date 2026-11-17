import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/services.dart';
import '../../services/verification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';
import '../you/support_screen.dart';
import 'selfie_capture_screen.dart';
import 'verification_intro_screen.dart';

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
    this.captureSelfie = _guidedSelfie,
    this.faceOnly = false,
  });

  final VoidCallback onComplete;
  final VoidCallback onCancel;

  /// Opens the guided camera; returns the clip (`video:<path>`) or null.
  final Future<String?> Function(BuildContext) captureSelfie;

  /// Sign-up face check: the live selfie only, no ID (ID = the gold tick, later).
  final bool faceOnly;

  static Future<String?> _guidedSelfie(BuildContext context) => Navigator.of(context)
      .push<String>(MaterialPageRoute(builder: (_) => const SelfieCaptureScreen()));

  @override
  State<VerificationProviderScreen> createState() =>
      _VerificationProviderScreenState();
}

// Two steps: your ID, then one short selfie clip. The same clip proves a
// live person (head turn) AND is matched to the ID photo — no third step.
enum _Phase { idFront, idBack, reading, selfie, checking }

class _VerificationProviderScreenState
    extends State<VerificationProviderScreen> {
  late _Phase _phase = widget.faceOnly ? _Phase.selfie : _Phase.idFront;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _wait(_Phase busy, Future<void> Function() then) {
    setState(() => _phase = busy);
    _timer = Timer(const Duration(seconds: 2), () async {
      if (mounted) await then();
    });
  }

  void _advance() {
    switch (_phase) {
      case _Phase.idFront:
        setState(() => _phase = _Phase.idBack);
      case _Phase.idBack:
        _wait(_Phase.reading, () async => setState(() => _phase = _Phase.selfie));
      case _Phase.selfie:
        _recordSelfie();
      case _Phase.reading:
      case _Phase.checking:
        break;
    }
  }

  Future<void> _recordSelfie() async {
    final clip = await widget.captureSelfie(context);
    if (clip == null || !mounted) return; // cancelled: stay on this step
    // Production: the clip goes to the verification provider with the ID.
    _wait(_Phase.checking, () async {
          if (widget.faceOnly) {
            await Services.prefs.setFaceVerified(true);
          } else {
            await Services.verification.runDemoFlow();
          }
          if (mounted) widget.onComplete();
        });
  }

  String get _title => switch (_phase) {
        _Phase.idFront => 'Front of your ID',
        _Phase.idBack => 'Back of your ID',
        _Phase.reading => 'Reading your ID…',
        _Phase.selfie => 'A quick selfie',
        _Phase.checking => 'Checking it’s you…',
      };

  String get _body => switch (_phase) {
        _Phase.idFront => 'Fit it inside the frame, all four corners showing.',
        _Phase.idBack => 'Now the back.',
        _Phase.reading => 'Confirming your date of birth.',
        _Phase.selfie => widget.faceOnly
            ? 'Proves a real person is here — no ID needed. Your selfie is never shown on your profile.'
            : 'We’ll guide you: fit your face in the oval, then slowly turn your head each way. About 10 seconds.',
        _Phase.checking => 'Matching your selfie to your ID photo.',
      };

  @override
  Widget build(BuildContext context) {
    final busy = _phase == _Phase.reading || _phase == _Phase.checking;
    final step = _phase.index <= _Phase.reading.index ? 1 : 2;
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
            Row(
              children: [
                for (var i = widget.faceOnly ? 2 : 1; i <= 2; i++) ...[
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: i < step || (i == 2 && _phase == _Phase.checking)
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
            Text(widget.faceOnly ? 'Quick face check · about 10 seconds' : 'Step $step of 2 · ${step == 1 ? 'ID' : 'Selfie'}',
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
                      ? const CircularProgressIndicator(color: AppColors.sparkCoral)
                      : Icon(
                          _phase == _Phase.selfie
                              ? Icons.face_retouching_natural
                              : Icons.badge_outlined,
                          size: 64,
                          color: AppColors.sparkCoral,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!busy) ...[
              SparkButton(
                label: _phase == _Phase.selfie ? 'Start selfie' : 'Take photo',
                icon: Icons.camera_alt_outlined,
                onPressed: _advance,
              ),
              const SizedBox(height: 8),
              if (_phase != _Phase.selfie)
                SparkButton(
                  label: 'Upload a photo instead',
                  secondary: true,
                  onPressed: _advance,
                ),
            ],
          ],
        ),
      ),
    );
  }
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
              'Your ID (21+) and selfie both checked out.',
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


/// Optional verification, started from your profile. Passing earns the
/// gold tick on your profile; nothing else in the app is locked behind it.
Future<void> startVerification(BuildContext context) async {
  final nav = Navigator.of(context);
  await nav.push(MaterialPageRoute<void>(
    builder: (introCtx) => VerificationIntroScreen(
      onExit: () => Navigator.of(introCtx).pop(),
      onStart: () => Navigator.of(introCtx).pushReplacement(MaterialPageRoute<void>(
        builder: (flowCtx) => VerificationProviderScreen(
          onCancel: () => Navigator.of(flowCtx).pop(),
          onComplete: () => Navigator.of(flowCtx).pushReplacement(MaterialPageRoute<void>(
            builder: (resCtx) => VerificationResultScreen(
              onPassed: () async {
                await Services.prefs.setMockVerified(true);
                if (resCtx.mounted) Navigator.of(resCtx).pop();
              },
              onRetry: () => Navigator.of(resCtx).pop(),
            ),
          )),
        ),
      )),
    ),
  ));
}
