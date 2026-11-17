import 'package:flutter/material.dart';
import '../design/icons.dart';
import '../design/tokens.dart';
import '../design/type.dart';
import '../widgets/glass_card.dart' show OnboardingBack;
import 'icon_circle.dart';

/// Figma "Top bar": 44pt back circle, 17pt title at x58, optional step
/// counter ("1 / 5") on the right. 56 tall.
class CarinoTopBar extends StatelessWidget {
  const CarinoTopBar(this.title, {super.key, this.step, this.onBack});
  final String title;
  final String? step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final back = onBack ?? OnboardingBack.maybeOf(context) ?? () => Navigator.maybePop(context);
    return SizedBox(
      height: 56,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CarinoIconCircle(CarinoIcons.back, onTap: back, label: 'Back'),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(title, style: CarinoText.barTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        if (step != null)
          Padding(padding: const EdgeInsets.only(top: 14), child: Text(step!, style: CarinoText.step)),
      ]),
    );
  }
}

/// Figma screen frame: canvas, top bar, then a "Reading flow" column
/// (20pt margins, 20pt gaps, 28pt bottom padding) that scrolls.
class CarinoPage extends StatelessWidget {
  const CarinoPage({super.key, required this.title, this.step, this.onBack, required this.children});
  final String title;
  final String? step;
  final VoidCallback? onBack;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: CarinoColors.canvas,
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(CarinoSpace.margin, 4, CarinoSpace.margin, 0),
              child: CarinoTopBar(title, step: step, onBack: onBack),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(CarinoSpace.margin, 18, CarinoSpace.margin, CarinoSpace.xxxl),
                itemCount: children.length,
                separatorBuilder: (_, __) => const SizedBox(height: CarinoSpace.xl),
                itemBuilder: (_, i) => children[i],
              ),
            ),
          ]),
        ),
      );
}
