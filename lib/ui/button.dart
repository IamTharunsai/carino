import 'package:flutter/material.dart';
import '../design/tokens.dart';
import '../design/type.dart';

/// Figma component "Button" — Primary (rose, white text) or Secondary
/// (white, 1pt line, secondary text). 52 tall, radius 16, full width.
class CarinoButton extends StatelessWidget {
  const CarinoButton(this.label, {super.key, required this.onPressed, this.secondary = false});
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: secondary ? CarinoColors.surface : (enabled ? CarinoColors.primary : CarinoColors.soft),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CarinoRadius.button),
          side: secondary ? const BorderSide(color: CarinoColors.line) : BorderSide.none,
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(CarinoRadius.button),
          highlightColor: secondary ? CarinoColors.soft : CarinoColors.pressed,
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: Center(
              child: Text(
                label,
                style: CarinoText.button.copyWith(
                  color: secondary || !enabled ? CarinoColors.secondary : CarinoColors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
