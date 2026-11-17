import 'package:flutter/material.dart';
import '../design/tokens.dart';
import '../design/type.dart';

/// Figma "Discovery mode" chip: soft bg + secondary text; selected = blush
/// bg + primary text. Min height 44, radius 18.
class CarinoChip extends StatelessWidget {
  const CarinoChip(this.label, {super.key, required this.selected, required this.onTap, this.padX = 13});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Side padding: 13 on the Dates chips, 14 on the account-method chips.
  final double padX;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? CarinoColors.blush : CarinoColors.soft,
          borderRadius: BorderRadius.circular(CarinoRadius.chip),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(CarinoRadius.chip),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: CarinoSpace.minTarget),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padX, vertical: 8),
                child: Center(
                  widthFactor: 1,
                  child: Text(label,
                      style: CarinoText.chip.copyWith(
                          color: selected ? CarinoColors.primary : CarinoColors.secondary)),
                ),
              ),
            ),
          ),
        ),
      );
}
