import 'package:flutter/material.dart';
import '../design/icons.dart';
import '../design/tokens.dart';

/// Figma "Action / …" round buttons: a 22pt icon centred in a circle.
/// Sizes used in the file: 44 (top bar), 54 (deck sides), 64 (deck heart).
class CarinoIconCircle extends StatelessWidget {
  const CarinoIconCircle(
    this.icon, {
    super.key,
    required this.onTap,
    required this.label,
    this.size = 44,
    this.background = CarinoColors.soft,
    this.onLongPress,
  });
  final String icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String label;
  final double size;
  final Color background;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            onLongPress: onLongPress,
            child: SizedBox.square(dimension: size, child: Center(child: CarinoIcon(icon))),
          ),
        ),
      );
}
