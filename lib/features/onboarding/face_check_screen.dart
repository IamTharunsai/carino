import 'package:flutter/material.dart';
import '../../design/tokens.dart';
import '../../design/type.dart';
import '../../screens/onboarding/selfie_capture_screen.dart';
import '../../services/services.dart';
import '../../ui/button.dart';
import '../../ui/page.dart';

/// Figma 01.06 Face check: a live selfie proves a real person — no ID
/// (ID is the optional gold tick, later). Three honest steps: get ready,
/// checking, done.
class FaceCheckScreen extends StatefulWidget {
  const FaceCheckScreen({super.key, required this.onComplete, this.captureSelfie = _guidedSelfie});
  final VoidCallback onComplete;

  /// Opens the guided camera; returns the clip (`video:<path>`) or null.
  final Future<String?> Function(BuildContext) captureSelfie;

  static Future<String?> _guidedSelfie(BuildContext context) =>
      Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const SelfieCaptureScreen()));

  @override
  State<FaceCheckScreen> createState() => _FaceCheckScreenState();
}

class _FaceCheckScreenState extends State<FaceCheckScreen> {
  int _step = 1; // 1 ready · 2 checking · 3 done

  Future<void> _start() async {
    final clip = await widget.captureSelfie(context);
    if (clip == null || !mounted) return; // cancelled: stay here
    setState(() => _step = 2);
    // Production: the clip goes to the liveness provider.
    await Future<void>.delayed(const Duration(seconds: 2));
    await Services.prefs.setFaceVerified(true);
    if (!mounted) return;
    setState(() => _step = 3);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) => CarinoPage(
        title: 'Quick face check',
        step: '4 / 5',
        gap: CarinoSpace.lg,
        children: [
          const Text('A real face. A real start.', style: CarinoText.screenTitle),
          const Text('A quick check helps keep our community authentic. About 10 seconds.', style: CarinoText.body),
          _preview(),
          Row(children: [
            for (var i = 1; i <= 3; i++) ...[
              if (i > 1) const SizedBox(width: 10),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= _step ? CarinoColors.primary : CarinoColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ]),
          Text(_step == 1 ? 'Look straight ahead, then gently turn your head.' : 'Checking it’s you…',
              style: CarinoText.small),
          CarinoButton(_step == 1 ? 'Start face check' : 'Checking…', onPressed: _step == 1 ? _start : null),
          const Text('Face checking is not identity verification or a safety guarantee.', style: CarinoText.fine),
        ],
      );

  /// Figma "Photo / Alex" with the white face oval and the guidance pill.
  Widget _preview() => ClipRRect(
        borderRadius: BorderRadius.circular(CarinoRadius.photoCard),
        child: SizedBox(
          height: 382,
          child: Stack(alignment: Alignment.topCenter, children: [
            Positioned.fill(
              child: Image.asset('assets/images/people/alex.png', fit: BoxFit.cover, semanticLabel: 'Example selfie'),
            ),
            Positioned(
              top: 28,
              child: Container(
                width: 230,
                height: 300,
                decoration: const ShapeDecoration(
                  shape: OvalBorder(side: BorderSide(color: CarinoColors.white, width: 3)),
                ),
              ),
            ),
            Positioned(
              top: 328,
              child: Container(
                width: 249,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: CarinoColors.surface, borderRadius: BorderRadius.circular(19)),
                child: const Text('Centre your face in the oval',
                    style: CarinoText.pill),
              ),
            ),
          ]),
        ),
      );
}
