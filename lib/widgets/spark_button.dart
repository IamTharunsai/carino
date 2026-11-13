import 'package:flutter/material.dart';
import '../models/member.dart';
import '../theme/app_colors.dart';

/// Primary action button — SOLID Ember Crimson, min height 50, radius 16.
/// (DESIGN SYSTEM rule: primary = solid. Glass is for surfaces, not action.)
class SparkButton extends StatelessWidget {
  const SparkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Secondary = glass style with hairline border.
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    if (secondary) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: AppColors.glassBorder(Theme.of(context).brightness)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.arrow_forward, size: 18),
      label: Text(label),
    );
  }
}

/// Intention chip — colour is never the only signal: it always carries text.
/// Selected = solid crimson; unselected = thin glass (DESIGN SYSTEM).
class IntentionChip extends StatelessWidget {
  const IntentionChip({
    super.key,
    required this.intention,
    required this.selected,
    required this.onTap,
  });

  final Intention intention;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ChoiceChip(
      label: Text(intention.label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: brightness == Brightness.dark
          ? AppColors.glassFillDark(0.6)
          : AppColors.glassFillLight(0.75),
      selectedColor: AppColors.emberCrimson,
      labelStyle: TextStyle(
        color: selected
            ? AppColors.warmIvory
            : Theme.of(context).textTheme.bodyLarge?.color,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected ? Colors.transparent : AppColors.glassBorder(brightness),
      ),
      shape: const StadiumBorder(),
      showCheckmark: false,
    );
  }
}

/// Small verified badge — ID + liveness + photo match passed (S-007).
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 16});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Verified 21+ · ID + photo matched',
      child: Icon(Icons.verified, size: size, color: AppColors.sparkCoral),
    );
  }
}

/// Round glass icon button used on cards and in-call controls.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  final bool filled; // solid crimson variant (e.g. Like)

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: filled
            ? AppColors.emberCrimson
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, color: AppColors.warmIvory, size: 24),
          ),
        ),
      ),
    );
  }
}
