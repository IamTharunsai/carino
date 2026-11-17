import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../design/icons.dart';
import '../../design/tokens.dart';
import '../../design/type.dart';
import '../../ui/button.dart';
import '../../ui/page.dart';
import '../../widgets/motion.dart' show stillBackgrounds;

/// Figma 01.01 Welcome.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onContinue, required this.onSignIn});
  final VoidCallback onContinue;
  final VoidCallback onSignIn;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  // Figma motion: photos rise 10pt → 0 in the first 22.5% of a 2s loop, ease-out.
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = stillBackgrounds || MediaQuery.of(context).disableAnimations;
    if (still) {
      _loop.value = 1; // rest on the final frame: photos settled, no offset
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  double get _rise {
    final t = (_loop.value / 0.225).clamp(0.0, 1.0);
    return 10 * (1 - Curves.easeOut.transform(t));
  }

  @override
  Widget build(BuildContext context) => CarinoPage(
        title: 'A little spark.',
        showBack: false,
        gap: CarinoSpace.lg,
        children: [
          _heroBlock(),
          const Text('Meet someone.\nMake a memory.', style: CarinoText.hero),
          const Text('Less endless swiping. More “same time\nnext week?” Your next chapter starts here.',
              style: CarinoText.body),
          CarinoButton('Create an account', onPressed: widget.onContinue),
          CarinoButton('I already have an account', onPressed: widget.onSignIn, secondary: true),
          _legalLine(context),
        ],
      );

  /// Figma "Meet in real life": blush block, two tilted photos, promise pill.
  Widget _heroBlock() => Container(
        height: 268,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: CarinoColors.blush, borderRadius: BorderRadius.circular(CarinoRadius.photoCard)),
        child: AnimatedBuilder(
          animation: _loop,
          builder: (context, _) => Stack(children: [
            Positioned(left: 28, top: 6, child: _photo('assets/images/people/aria.png', 178, 228, -7)),
            Positioned(left: 160, top: 46, child: _photo('assets/images/people/sam.png', 170, 224, 7)),
            Positioned(
              left: 85,
              top: 215,
              // Figma "Promise": 36 tall, 14pt left / 7pt top inset, 12pt gap.
              child: Container(
                height: 36,
                padding: const EdgeInsets.only(left: 14, top: 7, right: 14),
                decoration: BoxDecoration(color: CarinoColors.surface, borderRadius: BorderRadius.circular(18)),
                child: const Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CarinoIcon(CarinoIcons.heart, size: 18),
                  SizedBox(width: 12),
                  Text('Real people. Real plans.', style: CarinoText.badge),
                ]),
              ),
            ),
          ]),
        ),
      );

  Widget _photo(String asset, double w, double h, double degrees) => Transform.translate(
        offset: Offset(0, _rise),
        child: Transform.rotate(
          angle: degrees * math.pi / 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(CarinoRadius.photo),
            child: Image.asset(asset, width: w, height: h, fit: BoxFit.cover),
          ),
        ),
      );

  Widget _legalLine(BuildContext context) {
    Widget link(String label, String doc) => GestureDetector(
          onTap: () => _legalSheet(context, doc),
          child: Text(label, style: CarinoText.legal),
        );
    const dot = Text('  ·  ', style: CarinoText.legal);
    return Wrap(children: [
      const Text('21+ only', style: CarinoText.legal),
      dot,
      link('Terms', 'Terms'),
      dot,
      link('Privacy', 'Privacy'),
      dot,
      link('Community guidelines', 'Community guidelines'),
    ]);
  }

  void _legalSheet(BuildContext context, String doc) {
    final body = switch (doc) {
      'Terms' => '21+ only. Real identity, stated intentions, mutual consent for every video session. '
          'No harassment, no scams, no money requests — enforcement by people, with appeals.',
      'Privacy' => 'We keep verification results, never your ID images. Location is shown as a rough '
          'distance, never coordinates. Vanish keeps a sealed, report-only safety copy so abuse can be evidenced.',
      _ => 'Be the person your profile says you are. Consent is specific and can be taken back. '
          'Money requests end accounts. Reports are reviewed by people within 24 hours.',
    };
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CarinoColors.surface,
      showDragHandle: true,
      builder: (s) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(CarinoSpace.margin, 0, CarinoSpace.margin, CarinoSpace.xxl),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doc, style: CarinoText.topBar),
            const SizedBox(height: CarinoSpace.sm),
            Text(body, style: CarinoText.body),
          ]),
        ),
      ),
    );
  }
}
