import 'package:flutter/material.dart';
import '../design/icons.dart';
import '../design/tokens.dart';
import '../design/type.dart';
import '../widgets/glass_card.dart' show OnboardingBack;
import 'icon_circle.dart';

/// Figma "Top bar" (56 tall). With back: 44pt circle, 17pt title at x58,
/// optional step counter in a 50pt box at x303. Without back (01.01): a
/// 24pt title at x0. Title text sits 10pt from the bar top.
class CarinoTopBar extends StatelessWidget {
  const CarinoTopBar(this.title, {super.key, this.step, this.onBack, this.showBack = true});
  final String title;
  final String? step;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final back = onBack ?? OnboardingBack.maybeOf(context) ?? () => Navigator.maybePop(context);
    return SizedBox(
      height: 56,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (showBack) ...[
          CarinoIconCircle(CarinoIcons.back, onTap: back, label: 'Back'),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(title,
                style: showBack ? CarinoText.barTitle : CarinoText.topBar,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ),
        if (step != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: SizedBox(width: 50, child: Text(step!, style: CarinoText.step)),
          ),
      ]),
    );
  }
}

/// Figma screen frame: canvas, top bar, then the "Reading flow" column
/// (starts 18pt under the bar, 20pt margins, [gap] between items, 28pt
/// bottom padding) that scrolls.
class CarinoPage extends StatelessWidget {
  const CarinoPage({
    super.key,
    required this.title,
    this.step,
    this.onBack,
    this.showBack = true,
    this.gap = CarinoSpace.xl,
    required this.children,
  });
  final String title;
  final String? step;
  final VoidCallback? onBack;
  final bool showBack;
  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: CarinoColors.canvas,
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(CarinoSpace.margin, 4, CarinoSpace.margin, 0),
              child: CarinoTopBar(title, step: step, onBack: onBack, showBack: showBack),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(CarinoSpace.margin, 18, CarinoSpace.margin, CarinoSpace.xxxl),
                itemCount: children.length,
                separatorBuilder: (_, __) => SizedBox(height: gap),
                itemBuilder: (_, i) => children[i],
              ),
            ),
          ]),
        ),
      );
}
